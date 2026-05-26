part of '../live_map_screen.dart';

enum _HistoryMapMarkerKind { start, stop, end }

class _HistoryMapMarker extends StatelessWidget {
  const _HistoryMapMarker({
    required this.kind,
    required this.isSelected,
    required this.onTap,
  });

  final _HistoryMapMarkerKind kind;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = _historyMapMarkerVisuals(kind);

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: visuals.ringColor.withValues(alpha: 0.42),
                      width: 2,
                    ),
                    color: visuals.ringColor.withValues(alpha: 0.08),
                  ),
                ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: visuals.outerFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: kind == _HistoryMapMarkerKind.stop ? 22 : 16,
                    height: kind == _HistoryMapMarkerKind.stop ? 22 : 16,
                    decoration: BoxDecoration(
                      color: visuals.innerFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: visuals.innerBorder),
                    ),
                    child: Icon(
                      visuals.icon,
                      size: kind == _HistoryMapMarkerKind.stop ? 12 : 10,
                      color: visuals.iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryMapMarkerVisuals {
  const _HistoryMapMarkerVisuals({
    required this.outerFill,
    required this.innerFill,
    required this.innerBorder,
    required this.iconColor,
    required this.ringColor,
    required this.icon,
  });

  final Color outerFill;
  final Color innerFill;
  final Color innerBorder;
  final Color iconColor;
  final Color ringColor;
  final IconData icon;
}

_HistoryMapMarkerVisuals _historyMapMarkerVisuals(
  _HistoryMapMarkerKind kind,
) {
  return switch (kind) {
    _HistoryMapMarkerKind.start => const _HistoryMapMarkerVisuals(
        outerFill: Color(0xFF111827),
        innerFill: Color(0xFF111827),
        innerBorder: Color(0xFFFFFFFF),
        iconColor: Color(0xFFFFFFFF),
        ringColor: Color(0xFF111827),
        icon: Icons.trip_origin_rounded,
      ),
    _HistoryMapMarkerKind.stop => const _HistoryMapMarkerVisuals(
        outerFill: Color(0xFFF7F7F8),
        innerFill: Color(0xFFFFFFFF),
        innerBorder: Color(0xFF9EA7B0),
        iconColor: Color(0xFF4B5563),
        ringColor: Color(0xFF3F3F46),
        icon: Icons.pause_rounded,
      ),
    _HistoryMapMarkerKind.end => const _HistoryMapMarkerVisuals(
        outerFill: Color(0xFF27272A),
        innerFill: Color(0xFF27272A),
        innerBorder: Color(0xFFFFFFFF),
        iconColor: Color(0xFFFFFFFF),
        ringColor: Color(0xFF27272A),
        icon: Icons.flag_rounded,
      ),
  };
}

