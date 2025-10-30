import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ProgressSliderWidget extends StatelessWidget {
  const ProgressSliderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final bars = appState.bars;
        if (bars.isEmpty) {
          return const SizedBox.shrink();
        }

        final qualityMap = appState.getBarQualityMap();
        final problemBars = appState.getProblemBars();
        final currentBar = appState.currentBarNumber;

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Bar ${currentBar ?? 1} of ${bars.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (problemBars.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${problemBars.length} need work',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth / bars.length;
                    return Stack(
                      children: [
                        Row(
                          children: bars.map((bar) {
                            final quality = qualityMap[bar.barNumber];
                            final isProblem = problemBars.contains(bar.barNumber);
                            final isCurrent = currentBar == bar.barNumber;

                            return GestureDetector(
                              onTap: () {
                                appState.seekToBarAndPlay(bar.barNumber);
                              },
                              child: Container(
                                width: barWidth,
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                decoration: BoxDecoration(
                                  color: quality != null
                                      ? quality.color.withValues(alpha: 0.7)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                  border: isCurrent
                                      ? Border.all(
                                          color: Colors.blue.shade700,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: isProblem && !isCurrent
                                    ? Center(
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
