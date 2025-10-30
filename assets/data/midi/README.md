# MIDI Files Directory

This directory should contain MIDI files for each piece in the video library.

## Required MIDI Files

The following MIDI files are referenced in `video_library.json`:

1. `unsospiro.mid` - Un Sospiro by Franz Liszt
2. `moonlight_sonata_3rd.mid` - Moonlight Sonata 3rd Movement by Beethoven
3. `nocturne_op9_no2.mid` - Nocturne Op. 9 No. 2 by Chopin
4. `clair_de_lune.mid` - Clair de Lune by Debussy
5. `la_campanella.mid` - La Campanella by Liszt
6. `fantaisie_impromptu.mid` - Fantaisie-Impromptu by Chopin
7. `hungarian_rhapsody_2.mid` - Hungarian Rhapsody No. 2 by Liszt
8. `prelude_csharp_minor.mid` - Prelude in C Sharp Minor by Rachmaninoff

## Where to Find MIDI Files

You can find free MIDI files for classical music at:

- **MuseScore**: https://musescore.com/ (search for the piece, download as MIDI)
- **Classical Archives**: https://www.classicalarchives.com/
- **IMSLP**: https://imslp.org/ (some scores have MIDI files)
- **Music21 Corpus**: Various classical pieces

## MIDI File Requirements

- Standard MIDI File (SMF) format (.mid or .midi extension)
- Should match the structure of the PDF score (same number of bars)
- Tempo and time signatures should be accurate
- Preferably from a high-quality source

## How the MIDI Parser Works

The app's MIDI parser (`lib/services/midi_parser_service.dart`) will:

1. Read tempo changes and time signatures from the MIDI file
2. Calculate bar boundaries based on time signatures
3. Generate timestamps for each bar/measure
4. Map these timestamps to the video timeline

This enables automatic synchronization between the score, video, and bar highlights.

## Manual Timestamp Fallback

If MIDI files are not available, the app will fall back to the manual `timestamps.json` file for the piece.
