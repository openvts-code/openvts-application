part of '../live_map_screen.dart';

class _PersistentMapBottomDrawer extends StatefulWidget {
  const _PersistentMapBottomDrawer({
    required this.isOpen,
    required this.vehicles,
    required this.alerts,
    required this.isAlertsLoading,
    required this.onClose,
    required this.onVehicleSelected,
    required this.selectedHistorySegmentId,
    required this.onHistoryEntrySelected,
  });

  final bool isOpen;
  final List<VehicleSummary> vehicles;
  final List<AppNotification> alerts;
  final bool isAlertsLoading;
  final VoidCallback onClose;
  final ValueChanged<VehicleSummary> onVehicleSelected;
  final String? selectedHistorySegmentId;
  final ValueChanged<_HistoryTimelineEntry> onHistoryEntrySelected;

  @override
  State<_PersistentMapBottomDrawer> createState() =>
      _PersistentMapBottomDrawerState();
}

class _PersistentMapBottomDrawerState
    extends State<_PersistentMapBottomDrawer> {
  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: widget.isOpen ? Offset.zero : const Offset(0, 1.08),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              expand: false,
              initialChildSize: _mapDrawerInitialChildSize,
              minChildSize: _mapDrawerMinChildSize,
              maxChildSize: _mapDrawerMaxChildSize,
              snap: true,
              snapSizes: const [
                _mapDrawerMinChildSize,
                _mapDrawerInitialChildSize,
                _mapDrawerMaxChildSize,
              ],
              builder: (context, scrollController) {
                return _MapBottomDrawer(
                  vehicles: widget.vehicles,
                  alerts: widget.alerts,
                  isAlertsLoading: widget.isAlertsLoading,
                  onClose: widget.onClose,
                  onVehicleSelected: widget.onVehicleSelected,
                  selectedHistorySegmentId: widget.selectedHistorySegmentId,
                  onHistoryEntrySelected: widget.onHistoryEntrySelected,
                  sheetController: _sheetController,
                  minChildSize: _mapDrawerMinChildSize,
                  initialChildSize: _mapDrawerInitialChildSize,
                  maxChildSize: _mapDrawerMaxChildSize,
                  scrollController: scrollController,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableSheetDragRegion extends StatefulWidget {
  const _DraggableSheetDragRegion({
    required this.controller,
    required this.minChildSize,
    required this.initialChildSize,
    required this.maxChildSize,
    required this.child,
  });

  final DraggableScrollableController controller;
  final double minChildSize;
  final double initialChildSize;
  final double maxChildSize;
  final Widget child;

  @override
  State<_DraggableSheetDragRegion> createState() =>
      _DraggableSheetDragRegionState();
}

class _DraggableSheetDragRegionState extends State<_DraggableSheetDragRegion> {
  bool _didDrag = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) {
        _didDrag = false;
      },
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: (_) => _snapToNearestSize(),
      onVerticalDragCancel: _snapToNearestSize,
      child: widget.child,
    );
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final primaryDelta = details.primaryDelta;
    if (primaryDelta == null ||
        primaryDelta == 0 ||
        !widget.controller.isAttached) {
      return;
    }

    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) {
      return;
    }

    final nextSize = widget.controller.size - primaryDelta / height;
    widget.controller.jumpTo(
      nextSize.clamp(widget.minChildSize, widget.maxChildSize).toDouble(),
    );
    _didDrag = true;
  }

  void _snapToNearestSize() {
    if (!_didDrag || !widget.controller.isAttached) {
      _didDrag = false;
      return;
    }

    _didDrag = false;
    unawaited(
      widget.controller.animateTo(
        _nearestSnapSize(widget.controller.size),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  double _nearestSnapSize(double size) {
    final snapSizes = <double>[
      widget.minChildSize,
      widget.initialChildSize,
      widget.maxChildSize,
    ];
    var nearest = snapSizes.first;
    var nearestDistance = (size - nearest).abs();

    for (final snapSize in snapSizes.skip(1)) {
      final distance = (size - snapSize).abs();
      if (distance < nearestDistance) {
        nearest = snapSize;
        nearestDistance = distance;
      }
    }

    return nearest;
  }
}

class _MapSideActionButtons extends StatelessWidget {
  const _MapSideActionButtons({
    required this.showNorthReset,
    required this.onNorthResetTap,
    required this.onLayerTap,
    required this.onSettingsTap,
  });

  final bool showNorthReset;
  final VoidCallback onNorthResetTap;
  final VoidCallback onLayerTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNorthReset) ...[
          _MapNorthResetButton(onTap: onNorthResetTap),
          const SizedBox(height: 10),
        ],
        _MapSideIconButton(icon: Icons.layers_rounded, onTap: onLayerTap),
        const SizedBox(height: 10),
        _MapSideIconButton(icon: Icons.settings_rounded, onTap: onSettingsTap),
      ],
    );
  }
}

class _MapNorthResetButton extends StatelessWidget {
  const _MapNorthResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Reset north',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF141118),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapSideIconButton extends StatelessWidget {
  const _MapSideIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: Colors.black.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }
}

class _MapActionDrawer extends StatelessWidget {
  const _MapActionDrawer({
    required this.child,
    required this.backgroundColor,
    required this.handleColor,
    required this.maxHeightFactor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color handleColor;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * maxHeightFactor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Align(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLayerDrawer extends StatefulWidget {
  const _MapLayerDrawer({
    required this.initialLayerId,
    required this.onLayerSelected,
  });

  final String initialLayerId;
  final ValueChanged<_MapLayerOption> onLayerSelected;

  @override
  State<_MapLayerDrawer> createState() => _MapLayerDrawerState();
}

class _MapLayerDrawerState extends State<_MapLayerDrawer> {
  late String _selectedLayerId;

  @override
  void initState() {
    super.initState();
    _selectedLayerId = widget.initialLayerId;
  }

  void _selectLayer(_MapLayerOption layer) {
    setState(() {
      _selectedLayerId = layer.id;
    });
    widget.onLayerSelected(layer);
  }

  @override
  Widget build(BuildContext context) {
    final primaryOptions = _primaryMapLayerOptions;
    final detailOptions = _detailMapLayerOptions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Map type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141118),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var index = 0; index < primaryOptions.length; index++) ...[
                Expanded(
                  child: _MapLayerCard(
                    option: primaryOptions[index],
                    isSelected: _selectedLayerId == primaryOptions[index].id,
                    onTap: () => _selectLayer(primaryOptions[index]),
                    large: true,
                  ),
                ),
                if (index != primaryOptions.length - 1)
                  const SizedBox(width: 14),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.black.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 16),
          const Text(
            'Map details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF141118),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detailOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final option = detailOptions[index];
              return _MapLayerCard(
                option: option,
                isSelected: _selectedLayerId == option.id,
                onTap: () => _selectLayer(option),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapLayerCard extends StatelessWidget {
  const _MapLayerCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.large = false,
  });

  final _MapLayerOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected
        ? const Color(0xFF1293A6)
        : Colors.black.withValues(alpha: 0.78);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Tooltip(
        message: option.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1293A6)
                      : Colors.black.withValues(alpha: 0.08),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: large ? 58 : 52,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MapLayerPreview(option: option),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1293A6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.shortLabel,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: large ? 12 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: labelColor,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLayerPreview extends StatelessWidget {
  const _MapLayerPreview({required this.option});

  final _MapLayerOption option;

  @override
  Widget build(BuildContext context) {
    switch (option.previewStyle) {
      case _LayerPreviewStyle.road:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD6F1E4), Color(0xFFB8E3E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: -8,
              bottom: -6,
              child: Transform.rotate(
                angle: -0.28,
                child: Container(
                  width: 70,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EFE0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: -4,
              child: Transform.rotate(
                angle: 0.8,
                child: Container(
                  width: 56,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7EC6DF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 10,
              child: Transform.rotate(
                angle: -0.75,
                child: Container(
                  width: 60,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.satellite:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A7266), Color(0xFF444A42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: -8,
              top: 22,
              child: Transform.rotate(
                angle: 0.64,
                child: Container(
                  width: 92,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3D1CB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -6,
              top: 24,
              child: Transform.rotate(
                angle: 0.64,
                child: Container(
                  width: 92,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D8378),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.terrain:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD6E0D0), Color(0xFFA9BC9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -6,
              child: Transform.rotate(
                angle: 0.42,
                child: Container(
                  width: 50,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0E6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 4,
              child: Transform.rotate(
                angle: 0.38,
                child: Container(
                  width: 7,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7BB9A8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.hybrid:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF49514A), Color(0xFF313731)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: -8,
              top: 22,
              child: Transform.rotate(
                angle: 0.58,
                child: Container(
                  width: 96,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -6,
              top: 24,
              child: Transform.rotate(
                angle: 0.58,
                child: Container(
                  width: 96,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF879180),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.osm:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F5EC), Color(0xFFD6E7F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: -4,
              bottom: 10,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 86,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F1E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: -10,
              child: Transform.rotate(
                angle: 0.8,
                child: Container(
                  width: 54,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.dark:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF22272E), Color(0xFF111419)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 10,
              child: Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 12,
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.light:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F8F8), Color(0xFFE8ECEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: -2,
              bottom: 12,
              child: Container(
                width: 88,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFC7CDD3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: -8,
              child: Transform.rotate(
                angle: 0.84,
                child: Container(
                  width: 54,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D8DE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.voyager:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE5F6F1), Color(0xFFF4F3E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF87C8B4), width: 7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -10,
              top: 22,
              child: Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFB7D9E7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.esriSatellite:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4E5C58), Color(0xFF29322F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -12,
              top: 8,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF6F8D86).withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                width: 36,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.toner:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFF4F4F4)),
            ),
            Positioned(
              left: -10,
              top: 20,
              child: Transform.rotate(
                angle: 0.55,
                child: Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 14,
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      case _LayerPreviewStyle.watercolor:
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8E2D0), Color(0xFFD6ECF2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: -8,
              top: 4,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3C8A5).withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF8EC3D9).withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _MapSettingsDrawer extends StatefulWidget {
  const _MapSettingsDrawer({
    required this.initialSettings,
    required this.config,
    required this.onChanged,
  });

  final _MapVisualSettings initialSettings;
  final LiveMapRoleConfig config;
  final ValueChanged<_MapVisualSettings> onChanged;

  @override
  State<_MapSettingsDrawer> createState() => _MapSettingsDrawerState();
}

class _MapSettingsDrawerState extends State<_MapSettingsDrawer> {
  late _MapVisualSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _update(_MapVisualSettings next) {
    setState(() {
      _settings = next;
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_SettingTileData>[
      _SettingTileData(
        icon: Icons.label_outline_rounded,
        title: 'Vehicle Label',
        subtitle: 'Show vehicle name next to the icon on the map',
        value: _settings.vehicleLabel,
        onChanged: (value) => _update(_settings.copyWith(vehicleLabel: value)),
      ),
      _SettingTileData(
        icon: Icons.layers_outlined,
        title: 'Cluster',
        subtitle: 'Group nearby vehicles into clusters at lower zoom',
        value: _settings.cluster,
        onChanged: (value) => _update(_settings.copyWith(cluster: value)),
      ),
      _SettingTileData(
        icon: Icons.waves_rounded,
        title: 'Ripple',
        subtitle: 'Show animated pulse around running vehicles',
        value: _settings.ripple,
        onChanged: (value) => _update(_settings.copyWith(ripple: value)),
      ),
      if (widget.config.supportsGeofence)
        _SettingTileData(
          icon: Icons.hexagon_outlined,
          title: 'Geofence',
          subtitle: 'Display geofence boundaries on the map',
          value: _settings.geofence,
          onChanged: (value) => _update(_settings.copyWith(geofence: value)),
        ),
      if (widget.config.supportsPoi)
        _SettingTileData(
          icon: Icons.place_outlined,
          title: 'POI',
          subtitle: 'Show points of interest markers',
          value: _settings.poi,
          onChanged: (value) => _update(_settings.copyWith(poi: value)),
        ),
      if (widget.config.supportsRoute)
        _SettingTileData(
          icon: Icons.route_outlined,
          title: 'Route',
          subtitle: 'Display saved routes on the map',
          value: _settings.route,
          onChanged: (value) => _update(_settings.copyWith(route: value)),
        ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        return _MapSettingTile(data: item);
      },
    );
  }
}

class _MapSettingTile extends StatelessWidget {
  const _MapSettingTile({required this.data});

  final _SettingTileData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF141118),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(data.icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141118),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.48),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Transform.scale(
          scale: 0.86,
          child: Switch(
            value: data.value,
            onChanged: data.onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF141118),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD6D8DE),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

class _SettingTileData {
  const _SettingTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _MapBottomDrawer extends StatefulWidget {
  const _MapBottomDrawer({
    required this.vehicles,
    required this.alerts,
    required this.isAlertsLoading,
    required this.onVehicleSelected,
    required this.selectedHistorySegmentId,
    required this.onHistoryEntrySelected,
    required this.onClose,
    required this.sheetController,
    required this.minChildSize,
    required this.initialChildSize,
    required this.maxChildSize,
    required this.scrollController,
  });

  final List<VehicleSummary> vehicles;
  final List<AppNotification> alerts;
  final bool isAlertsLoading;
  final ValueChanged<VehicleSummary> onVehicleSelected;
  final String? selectedHistorySegmentId;
  final ValueChanged<_HistoryTimelineEntry> onHistoryEntrySelected;
  final VoidCallback onClose;
  final DraggableScrollableController sheetController;
  final double minChildSize;
  final double initialChildSize;
  final double maxChildSize;
  final ScrollController scrollController;

  @override
  State<_MapBottomDrawer> createState() => _MapBottomDrawerState();
}

class _MapBottomDrawerState extends State<_MapBottomDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _vehicleSearchController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _vehicleSearchController = TextEditingController()
      ..addListener(_handleVehicleSearchChanged);
  }

  @override
  void dispose() {
    _vehicleSearchController
      ..removeListener(_handleVehicleSearchChanged)
      ..dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleVehicleSearchChanged() {
    if (!mounted || _selectedTabIndex != 0) {
      return;
    }

    setState(() {});
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) {
      return;
    }

    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DraggableSheetDragRegion(
            controller: widget.sheetController,
            minChildSize: widget.minChildSize,
            initialChildSize: widget.initialChildSize,
            maxChildSize: widget.maxChildSize,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _MapDrawerCloseButton(onPressed: widget.onClose),
                  ),
                ],
              ),
            ),
          ),
          _DraggableSheetDragRegion(
            controller: widget.sheetController,
            minChildSize: widget.minChildSize,
            initialChildSize: widget.initialChildSize,
            maxChildSize: widget.maxChildSize,
            child: TabBar(
              controller: _tabController,
              onTap: _selectTab,
              isScrollable: false,
              labelColor: const Color(0xFF141118),
              unselectedLabelColor: Colors.black.withValues(alpha: 0.5),
              indicatorColor: const Color(0xFF141118),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2,
              dividerColor: Colors.black.withValues(alpha: 0.06),
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(height: 40, text: 'Vehicles'),
                Tab(height: 40, text: 'History'),
                Tab(height: 40, text: 'Alerts'),
              ],
            ),
          ),
          Expanded(child: _buildActiveTabBody()),
        ],
      ),
    );
  }

  Widget _buildActiveTabBody() {
    return switch (_selectedTabIndex) {
      0 => _VehiclesTab(
          vehicles: widget.vehicles,
          onVehicleSelected: widget.onVehicleSelected,
          searchController: _vehicleSearchController,
          scrollController: widget.scrollController,
        ),
      1 => _HistoryTab(
          vehicles: widget.vehicles,
          selectedHistorySegmentId: widget.selectedHistorySegmentId,
          onEntrySelected: widget.onHistoryEntrySelected,
          scrollController: widget.scrollController,
        ),
      _ => _AlertsTab(
          alerts: widget.alerts,
          isLoading: widget.isAlertsLoading,
          scrollController: widget.scrollController,
        ),
    };
  }
}

