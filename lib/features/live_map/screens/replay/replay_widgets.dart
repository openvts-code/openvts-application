part of '../live_map_screen.dart';

class _ReplayEndpointMarker extends StatelessWidget {
  const _ReplayEndpointMarker({required this.isStart});

  final bool isStart;

  @override
  Widget build(BuildContext context) {
    final fill = isStart ? const Color(0xFF111827) : const Color(0xFF27272A);

    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isStart ? Icons.trip_origin_rounded : Icons.flag_rounded,
          size: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ReplayStopMarkerWidget extends StatelessWidget {
  const _ReplayStopMarkerWidget({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? Colors.white : const Color(0xFF4B5563);
    final innerFill = isSelected ? const Color(0xFF111827) : Colors.white;
    final borderColor =
        isSelected ? const Color(0xFF111827) : const Color(0xFFC0CBD3);

    return Semantics(
      button: true,
      label: 'Stoppage marker',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF111827) : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: innerFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    Icons.pause_rounded,
                    size: 12,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplayStopPopup extends StatelessWidget {
  const _ReplayStopPopup({required this.stop, required this.onClose});

  final SuperadminReplayStopMarker stop;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final latLngText =
        '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}';

    return SizedBox(
      width: 220,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 30, 9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stoppage',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ReplayStopPopupRow(
                    label: 'Duration',
                    value: _formatReplayStopDuration(stop.duration),
                  ),
                  const SizedBox(height: 3),
                  _ReplayStopPopupRow(
                    label: 'Start',
                    value: _formatReplayControlTime(stop.startTime),
                  ),
                  const SizedBox(height: 3),
                  _ReplayStopPopupRow(
                    label: 'End',
                    value: _formatReplayControlTime(stop.endTime),
                  ),
                  const SizedBox(height: 3),
                  _ReplayStopPopupRow(label: 'Lat/Lng', value: latLngText),
                ],
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF374151),
                ),
                tooltip: 'Close',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayStopPopupRow extends StatelessWidget {
  const _ReplayStopPopupRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplayMovingMarker extends StatelessWidget {
  const _ReplayMovingMarker({required this.courseDegrees});

  final double? courseDegrees;

  @override
  Widget build(BuildContext context) {
    final angle = ((courseDegrees ?? 0) % 360) * math.pi / 180;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: angle,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.navigation_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayInfoHud extends StatelessWidget {
  const _ReplayInfoHud({
    required this.vehicleName,
    required this.point,
    required this.tripDistanceKm,
    required this.engineHours,
  });

  final String? vehicleName;
  final SuperadminReplayPoint point;
  final double? tripDistanceKm;
  final double? engineHours;

  @override
  Widget build(BuildContext context) {
    final displayName =
        vehicleName?.trim().isNotEmpty == true ? vehicleName!.trim() : 'Replay';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 236),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6E8EC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReplayMiniSpeedometer(speedKph: point.speedKph),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF141118),
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatReplayControlTime(point.effectiveTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 1),
                              child: Text(
                                'Trip',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8B919C),
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _formatReplayDistanceKm(tripDistanceKm),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Container(height: 1, color: const Color(0xFFEDEFF3)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _ReplayHudStat(
                      label: 'Odometer',
                      value: _formatReplayOdometer(point.odometer),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    flex: 5,
                    child: _ReplayHudStat(
                      label: 'Engine Hours',
                      value: _formatReplayHours(engineHours),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayHudStat extends StatelessWidget {
  const _ReplayHudStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B919C),
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplayMiniSpeedometer extends StatelessWidget {
  const _ReplayMiniSpeedometer({required this.speedKph});

  final double? speedKph;

  @override
  Widget build(BuildContext context) {
    final speed = (speedKph ?? 0).clamp(0, 120).toDouble();

    return SizedBox(
      width: 64,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 3,
            top: 0,
            right: 3,
            height: 38,
            child: CustomPaint(
              painter: _ReplayMiniSpeedometerPainter(speedKph: speed),
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Text(
              _formatReplayNumber(speed, speed >= 10 ? 0 : 1),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                height: 1,
              ),
            ),
          ),
          const Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Text(
              'km/h',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayMiniSpeedometerPainter extends CustomPainter {
  const _ReplayMiniSpeedometerPainter({required this.speedKph});

  final double speedKph;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = (speedKph / 120).clamp(0.0, 1.0).toDouble();
    final arcRect = Rect.fromLTWH(7, 6, size.width - 14, size.width - 14);
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final center = arcRect.center;
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tickPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final radius = arcRect.width / 2;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, backgroundPaint);
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    for (final tickProgress in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final tickAngle = startAngle + (sweepAngle * tickProgress);
      final outer = Offset(
        center.dx + math.cos(tickAngle) * (radius - 5),
        center.dy + math.sin(tickAngle) * (radius - 5),
      );
      final inner = Offset(
        center.dx + math.cos(tickAngle) * (radius - 8),
        center.dy + math.sin(tickAngle) * (radius - 8),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final indicatorAngle = startAngle + (sweepAngle * progress);
    final indicatorCenter = Offset(
      center.dx + math.cos(indicatorAngle) * radius,
      center.dy + math.sin(indicatorAngle) * radius,
    );
    canvas.drawCircle(
      indicatorCenter,
      3.5,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      indicatorCenter,
      2.2,
      Paint()..color = const Color(0xFF111827),
    );
  }

  @override
  bool shouldRepaint(covariant _ReplayMiniSpeedometerPainter oldDelegate) {
    return oldDelegate.speedKph != speedKph;
  }
}

class _ReplayControlDrawer extends StatelessWidget {
  const _ReplayControlDrawer({
    required this.points,
    required this.index,
    required this.isPlaying,
    required this.speed,
    required this.onSeek,
    required this.onSkipStart,
    required this.onTogglePlayback,
    required this.onSkipEnd,
    required this.onSpeedChanged,
    required this.onClear,
  });

  final List<SuperadminReplayPoint> points;
  final int index;
  final bool isPlaying;
  final double speed;
  final ValueChanged<int> onSeek;
  final VoidCallback onSkipStart;
  final VoidCallback onTogglePlayback;
  final VoidCallback onSkipEnd;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final maxIndex = points.isEmpty ? 0 : points.length - 1;
    final clampedIndex = index < 0
        ? 0
        : index > maxIndex
            ? maxIndex
            : index;
    final sliderMax = math.max(1, maxIndex).toDouble();
    final canPlay = points.length > 1;

    return IgnorePointer(
      ignoring: points.isEmpty,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF111827),
                      inactiveTrackColor: const Color(0xFFD6DEE5),
                      thumbColor: const Color(0xFF111827),
                      overlayColor:
                          const Color(0xFF111827).withValues(alpha: 0.12),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 0,
                      max: sliderMax,
                      divisions: maxIndex > 0 ? maxIndex : null,
                      value: clampedIndex.toDouble(),
                      onChanged:
                          canPlay ? (value) => onSeek(value.round()) : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            points.isEmpty
                                ? '--'
                                : _formatReplayControlTime(
                                    points.first.effectiveTime,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _replayControlMetaStyle(),
                          ),
                        ),
                        Text(
                          points.isEmpty
                              ? '0 / 0'
                              : '${clampedIndex + 1} / ${points.length}',
                          style: _replayControlMetaStyle(
                            weight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            points.isEmpty
                                ? '--'
                                : _formatReplayControlTime(
                                    points.last.effectiveTime,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: _replayControlMetaStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ReplayControlIconButton(
                        icon: Icons.skip_previous_rounded,
                        tooltip: 'Skip start',
                        onTap: canPlay ? onSkipStart : null,
                      ),
                      const SizedBox(width: 8),
                      _ReplayControlIconButton(
                        icon: isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        filled: true,
                        onTap: canPlay ? onTogglePlayback : null,
                      ),
                      const SizedBox(width: 8),
                      _ReplayControlIconButton(
                        icon: Icons.skip_next_rounded,
                        tooltip: 'Skip end',
                        onTap: canPlay ? onSkipEnd : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _ReplaySpeedSelector(
                            speed: speed,
                            onChanged: onSpeedChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ReplayControlIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Clear replay',
                        onTap: onClear,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplayControlIconButton extends StatelessWidget {
  const _ReplayControlIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: filled ? _mapActionInkColor : const Color(0xFFFFFFFF),
              shape: BoxShape.circle,
              border: Border.all(
                color: filled
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: filled
                  ? Colors.white
                  : isEnabled
                      ? _mapActionInkColor
                      : const Color(0xFF9EA7B0),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplaySpeedSelector extends StatelessWidget {
  const _ReplaySpeedSelector({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Replay speed',
      onSelected: onChanged,
      color: Colors.white,
      itemBuilder: (context) => _replaySpeedOptions
          .map(
            (option) => PopupMenuItem<double>(
              value: option.value,
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: option.value == speed
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF111827),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${option.label} ${option.value.toInt()}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.speed_rounded,
              size: 15,
              color: Color(0xFF4B5563),
            ),
            const SizedBox(width: 6),
            Text(
              _replaySpeedLabel(speed),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 16,
              color: Color(0xFF4B5563),
            ),
          ],
        ),
      ),
    );
  }
}

