import 'package:flutter/services.dart';
import '../models/bar_timestamp.dart';

/// Simplified MIDI parser for extracting timing information
/// Supports Standard MIDI File (SMF) format
class MIDIParserService {
  /// Parse a MIDI file from assets and extract bar timestamps
  Future<List<BarTimestamp>> parseMIDIFile(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      final midiData = _parseMIDI(bytes);
      return _extractBarTimestamps(midiData);
    } catch (e) {
      // Return empty list on error - caller will fall back to JSON timestamps
      return [];
    }
  }

  /// Parse MIDI bytes and extract relevant data
  MIDIData _parseMIDI(Uint8List bytes) {
    if (bytes.length < 14) {
      throw Exception('Invalid MIDI file: too short');
    }

    // Parse header chunk
    final headerType = String.fromCharCodes(bytes.sublist(0, 4));
    if (headerType != 'MThd') {
      throw Exception('Invalid MIDI file: missing MThd header');
    }

    final headerLength = _readInt32(bytes, 4);
    final format = _readInt16(bytes, 8);
    final numTracks = _readInt16(bytes, 10);
    final division = _readInt16(bytes, 12);

    int ticksPerQuarterNote;
    if (division & 0x8000 == 0) {
      // Positive SMPTE format
      ticksPerQuarterNote = division;
    } else {
      // Negative SMPTE format (frames per second)
      ticksPerQuarterNote = 480; // Default fallback
    }

    // Parse tracks
    int offset = 8 + headerLength;
    final tracks = <List<MIDIEvent>>[];

    for (int i = 0; i < numTracks; i++) {
      if (offset + 8 > bytes.length) break;

      final trackType = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      if (trackType != 'MTrk') {
        break;
      }

      final trackLength = _readInt32(bytes, offset + 4);
      offset += 8;

      final trackEvents = _parseTrack(bytes, offset, trackLength);
      tracks.add(trackEvents);

      offset += trackLength;
    }

    return MIDIData(
      format: format,
      numTracks: numTracks,
      ticksPerQuarterNote: ticksPerQuarterNote,
      tracks: tracks,
    );
  }

  /// Parse a single MIDI track
  List<MIDIEvent> _parseTrack(Uint8List bytes, int start, int length) {
    final events = <MIDIEvent>[];
    int offset = start;
    final end = start + length;
    int runningStatus = 0;

    while (offset < end) {
      // Read variable length delta time
      final deltaResult = _readVariableLength(bytes, offset);
      final deltaTime = deltaResult.value;
      offset = deltaResult.nextOffset;

      if (offset >= end) break;

      // Read event type
      int eventType = bytes[offset];

      // Handle running status
      if (eventType < 0x80) {
        eventType = runningStatus;
      } else {
        offset++;
        runningStatus = eventType;
      }

      final statusByte = eventType & 0xF0;

      MIDIEvent? event;

      if (statusByte == 0x90) {
        // Note On
        if (offset + 1 >= end) break;
        final note = bytes[offset];
        final velocity = bytes[offset + 1];
        offset += 2;
        event = MIDIEvent(
          deltaTime: deltaTime,
          type: MIDIEventType.noteOn,
          channel: eventType & 0x0F,
          note: note,
          velocity: velocity,
        );
      } else if (statusByte == 0x80) {
        // Note Off
        if (offset + 1 >= end) break;
        final note = bytes[offset];
        final velocity = bytes[offset + 1];
        offset += 2;
        event = MIDIEvent(
          deltaTime: deltaTime,
          type: MIDIEventType.noteOff,
          channel: eventType & 0x0F,
          note: note,
          velocity: velocity,
        );
      } else if (statusByte == 0xFF) {
        // Meta event
        if (offset >= end) break;
        final metaType = bytes[offset];
        offset++;

        final lengthResult = _readVariableLength(bytes, offset);
        final dataLength = lengthResult.value;
        offset = lengthResult.nextOffset;

        if (offset + dataLength > end) break;
        final data = bytes.sublist(offset, offset + dataLength);
        offset += dataLength;

        event = _parseMetaEvent(deltaTime, metaType, data);
      } else {
        // Skip other events
        if (statusByte >= 0xC0 && statusByte <= 0xDF) {
          // Program change, channel pressure (1 byte)
          offset += 1;
        } else if (statusByte >= 0x80 && statusByte <= 0xBF) {
          // Note events, control change (2 bytes)
          offset += 2;
        } else if (statusByte == 0xF0 || statusByte == 0xF7) {
          // SysEx
          final lengthResult = _readVariableLength(bytes, offset);
          offset = lengthResult.nextOffset + lengthResult.value;
        }
      }

      if (event != null) {
        events.add(event);
      }
    }

    return events;
  }

  /// Parse meta events (tempo, time signature, etc.)
  MIDIEvent? _parseMetaEvent(int deltaTime, int metaType, Uint8List data) {
    switch (metaType) {
      case 0x51: // Set Tempo
        if (data.length == 3) {
          final microsecondsPerQuarter = (data[0] << 16) | (data[1] << 8) | data[2];
          final bpm = 60000000 / microsecondsPerQuarter;
          return MIDIEvent(
            deltaTime: deltaTime,
            type: MIDIEventType.setTempo,
            tempoMicrosecondsPerQuarter: microsecondsPerQuarter,
            tempoBPM: bpm,
          );
        }
        break;

      case 0x58: // Time Signature
        if (data.length >= 4) {
          return MIDIEvent(
            deltaTime: deltaTime,
            type: MIDIEventType.timeSignature,
            timeSignatureNumerator: data[0],
            timeSignatureDenominator: 1 << data[1],
          );
        }
        break;
    }

    return null;
  }

  /// Extract bar timestamps from MIDI data
  List<BarTimestamp> _extractBarTimestamps(MIDIData midiData) {
    final timestamps = <BarTimestamp>[];

    // Default values
    int beatsPerMeasure = 4;
    int beatUnit = 4;
    double microsecondsPerQuarter = 500000; // 120 BPM

    // Current time in various units
    int currentTick = 0;
    double currentTimeSeconds = 0.0;

    // Track bar numbers
    int currentBar = 1;
    int ticksInCurrentMeasure = 0;

    // Process all events from all tracks in chronological order
    final allEvents = <_TimedEvent>[];
    for (final track in midiData.tracks) {
      int trackTick = 0;
      for (final event in track) {
        trackTick += event.deltaTime;
        allEvents.add(_TimedEvent(trackTick, event));
      }
    }

    // Sort by tick
    allEvents.sort((a, b) => a.tick.compareTo(b.tick));

    // Add bar 1 at time 0
    timestamps.add(BarTimestamp(barNumber: 1, timestamp: 0.0));

    for (final timedEvent in allEvents) {
      final event = timedEvent.event;
      final tickDelta = timedEvent.tick - currentTick;

      // Calculate time advance
      final quartersElapsed = tickDelta / midiData.ticksPerQuarterNote;
      final secondsElapsed = (quartersElapsed * microsecondsPerQuarter) / 1000000;
      currentTimeSeconds += secondsElapsed;
      currentTick = timedEvent.tick;
      ticksInCurrentMeasure += tickDelta;

      // Update tempo or time signature
      if (event.type == MIDIEventType.setTempo) {
        microsecondsPerQuarter = event.tempoMicrosecondsPerQuarter?.toDouble() ?? 500000;
      } else if (event.type == MIDIEventType.timeSignature) {
        beatsPerMeasure = event.timeSignatureNumerator ?? 4;
        beatUnit = event.timeSignatureDenominator ?? 4;
      }

      // Check if we've crossed into a new measure
      final updatedTicksPerMeasure =
          (midiData.ticksPerQuarterNote * beatsPerMeasure * 4) ~/ beatUnit;

      while (ticksInCurrentMeasure >= updatedTicksPerMeasure) {
        currentBar++;
        ticksInCurrentMeasure -= updatedTicksPerMeasure;

        timestamps.add(BarTimestamp(
          barNumber: currentBar,
          timestamp: currentTimeSeconds,
        ));
      }
    }

    return timestamps;
  }

  /// Read a 32-bit integer (big-endian)
  int _readInt32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  /// Read a 16-bit integer (big-endian)
  int _readInt16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  /// Read a variable-length quantity
  _VariableLengthResult _readVariableLength(Uint8List bytes, int offset) {
    int value = 0;
    int currentOffset = offset;

    while (currentOffset < bytes.length) {
      final byte = bytes[currentOffset];
      value = (value << 7) | (byte & 0x7F);
      currentOffset++;

      if (byte & 0x80 == 0) {
        break;
      }
    }

    return _VariableLengthResult(value, currentOffset);
  }
}

/// Result of reading a variable-length value
class _VariableLengthResult {
  final int value;
  final int nextOffset;

  _VariableLengthResult(this.value, this.nextOffset);
}

/// Timed event (absolute tick time)
class _TimedEvent {
  final int tick;
  final MIDIEvent event;

  _TimedEvent(this.tick, this.event);
}

/// MIDI file data structure
class MIDIData {
  final int format;
  final int numTracks;
  final int ticksPerQuarterNote;
  final List<List<MIDIEvent>> tracks;

  MIDIData({
    required this.format,
    required this.numTracks,
    required this.ticksPerQuarterNote,
    required this.tracks,
  });
}

/// MIDI event types
enum MIDIEventType {
  noteOn,
  noteOff,
  setTempo,
  timeSignature,
  other,
}

/// MIDI event
class MIDIEvent {
  final int deltaTime;
  final MIDIEventType type;
  final int? channel;
  final int? note;
  final int? velocity;
  final int? tempoMicrosecondsPerQuarter;
  final double? tempoBPM;
  final int? timeSignatureNumerator;
  final int? timeSignatureDenominator;

  MIDIEvent({
    required this.deltaTime,
    required this.type,
    this.channel,
    this.note,
    this.velocity,
    this.tempoMicrosecondsPerQuarter,
    this.tempoBPM,
    this.timeSignatureNumerator,
    this.timeSignatureDenominator,
  });

  @override
  String toString() {
    switch (type) {
      case MIDIEventType.noteOn:
        return 'NoteOn(ch=$channel, note=$note, vel=$velocity, delta=$deltaTime)';
      case MIDIEventType.setTempo:
        return 'SetTempo(bpm=$tempoBPM, delta=$deltaTime)';
      case MIDIEventType.timeSignature:
        return 'TimeSig($timeSignatureNumerator/$timeSignatureDenominator, delta=$deltaTime)';
      default:
        return 'MIDIEvent(type=$type, delta=$deltaTime)';
    }
  }
}
