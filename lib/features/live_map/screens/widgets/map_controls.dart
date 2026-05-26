part of '../live_map_screen.dart';

class _MapTelemetryFilters extends StatelessWidget {
  const _MapTelemetryFilters({
    required this.selectedFilter,
    required this.allCount,
    required this.runningCount,
    required this.stopCount,
    required this.inactiveCount,
    required this.onSelected,
  });

  final _MapFilter selectedFilter;
  final int allCount;
  final int runningCount;
  final int stopCount;
  final int inactiveCount;
  final ValueChanged<_MapFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TelemetryCircleButton(
          label: 'All',
          count: allCount,
          isSelected: selectedFilter == _MapFilter.all,
          onTap: () => onSelected(_MapFilter.all),
        ),
        const SizedBox(width: 6),
        _TelemetryCircleButton(
          label: 'Running',
          count: runningCount,
          isSelected: selectedFilter == _MapFilter.running,
          onTap: () => onSelected(_MapFilter.running),
        ),
        const SizedBox(width: 6),
        _TelemetryCircleButton(
          label: 'Stop',
          count: stopCount,
          isSelected: selectedFilter == _MapFilter.stop,
          onTap: () => onSelected(_MapFilter.stop),
        ),
        const SizedBox(width: 6),
        _TelemetryCircleButton(
          label: 'Inactive',
          count: inactiveCount,
          isSelected: selectedFilter == _MapFilter.inactive,
          onTap: () => onSelected(_MapFilter.inactive),
        ),
      ],
    );
  }
}

class _TelemetryCircleButton extends StatelessWidget {
  const _TelemetryCircleButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF141118) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF141118)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF141118),
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.92)
                      : Colors.black.withValues(alpha: 0.7),
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomDrawerButton extends StatelessWidget {
  const _BottomDrawerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 22,
            color: Color(0xFF141118),
          ),
        ),
      ),
    );
  }
}

