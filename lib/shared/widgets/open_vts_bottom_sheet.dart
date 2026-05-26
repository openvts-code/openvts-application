import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';

typedef OpenVtsBottomSheetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

class OpenVtsBottomSheet {
  static const List<double> _defaultSnapSizes = <double>[
    0.28,
    0.48,
    0.72,
    0.92
  ];

  static Future<T?> show<T>({
    required BuildContext context,
    Widget? child,
    OpenVtsBottomSheetBuilder? draggableChildBuilder,
    String? title,
    double initialChildSize = 0.48,
    double minChildSize = 0.28,
    double maxChildSize = 0.92,
    bool snap = true,
    List<double>? snapSizes,
  }) {
    assert(
      child != null || draggableChildBuilder != null,
      'Provide either child or draggableChildBuilder.',
    );

    final resolvedMinChildSize = minChildSize.clamp(0.0, 1.0).toDouble();
    final resolvedMaxChildSize =
        maxChildSize.clamp(resolvedMinChildSize, 1.0).toDouble();
    final resolvedInitialChildSize = initialChildSize
        .clamp(resolvedMinChildSize, resolvedMaxChildSize)
        .toDouble();
    final resolvedSnapSizes = _resolveSnapSizes(
      snapSizes: snapSizes ?? _defaultSnapSizes,
      minChildSize: resolvedMinChildSize,
      maxChildSize: resolvedMaxChildSize,
    );
    final draggableController = DraggableScrollableController();

    final sheetFuture = showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: DraggableScrollableSheet(
              controller: draggableController,
              expand: false,
              initialChildSize: resolvedInitialChildSize,
              minChildSize: resolvedMinChildSize,
              maxChildSize: resolvedMaxChildSize,
              snap: snap,
              snapSizes: snap ? resolvedSnapSizes : null,
              builder: (context, scrollController) {
                final sheetChild = draggableChildBuilder != null
                    ? draggableChildBuilder(context, scrollController)
                    : PrimaryScrollController(
                        controller: scrollController,
                        child: child!,
                      );

                return _OpenVtsBottomSheetDragScope(
                  controller: draggableController,
                  minChildSize: resolvedMinChildSize,
                  maxChildSize: resolvedMaxChildSize,
                  snap: snap,
                  snapSizes: resolvedSnapSizes,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: OpenVtsColors.surfaceElevated,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(OpenVtsRadius.lg),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OpenVtsSheetDragHandleRegion(
                          controller: draggableController,
                          minChildSize: resolvedMinChildSize,
                          maxChildSize: resolvedMaxChildSize,
                          snap: snap,
                          snapSizes: resolvedSnapSizes,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: OpenVtsSpacing.sm),
                              Align(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: OpenVtsColors.border,
                                    borderRadius: BorderRadius.circular(
                                      OpenVtsRadius.sm,
                                    ),
                                  ),
                                ),
                              ),
                              if (title != null) ...[
                                const SizedBox(height: OpenVtsSpacing.md),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OpenVtsSpacing.md,
                                  ),
                                  child: Text(
                                    title,
                                    style:
                                        OpenVtsTypography.titleSmall.copyWith(
                                      color: OpenVtsColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: OpenVtsSpacing.sm),
                                const Divider(
                                  height: 1,
                                  color: OpenVtsColors.divider,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(child: sheetChild),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    return sheetFuture.whenComplete(draggableController.dispose);
  }

  static Widget dragRegion({
    required BuildContext context,
    required Widget child,
  }) {
    final scope = _OpenVtsBottomSheetDragScope.maybeOf(context);
    if (scope == null) {
      return child;
    }

    return _OpenVtsSheetDragHandleRegion(
      controller: scope.controller,
      minChildSize: scope.minChildSize,
      maxChildSize: scope.maxChildSize,
      snap: scope.snap,
      snapSizes: scope.snapSizes,
      child: child,
    );
  }

  static List<double> _resolveSnapSizes({
    required List<double> snapSizes,
    required double minChildSize,
    required double maxChildSize,
  }) {
    final resolved = <double>{
      for (final size in snapSizes)
        size.clamp(minChildSize, maxChildSize).toDouble(),
    }.toList()
      ..sort();

    if (resolved.isEmpty) {
      return <double>[minChildSize, maxChildSize];
    }

    return resolved;
  }
}

class _OpenVtsBottomSheetDragScope extends InheritedWidget {
  const _OpenVtsBottomSheetDragScope({
    required this.controller,
    required this.minChildSize,
    required this.maxChildSize,
    required this.snap,
    required this.snapSizes,
    required super.child,
  });

  final DraggableScrollableController controller;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;
  final List<double> snapSizes;

  static _OpenVtsBottomSheetDragScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_OpenVtsBottomSheetDragScope>();
  }

  @override
  bool updateShouldNotify(_OpenVtsBottomSheetDragScope oldWidget) {
    return controller != oldWidget.controller ||
        minChildSize != oldWidget.minChildSize ||
        maxChildSize != oldWidget.maxChildSize ||
        snap != oldWidget.snap ||
        snapSizes != oldWidget.snapSizes;
  }
}

class _OpenVtsSheetDragHandleRegion extends StatefulWidget {
  const _OpenVtsSheetDragHandleRegion({
    required this.controller,
    required this.minChildSize,
    required this.maxChildSize,
    required this.snap,
    required this.snapSizes,
    required this.child,
  });

  final DraggableScrollableController controller;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;
  final List<double> snapSizes;
  final Widget child;

  @override
  State<_OpenVtsSheetDragHandleRegion> createState() =>
      _OpenVtsSheetDragHandleRegionState();
}

class _OpenVtsSheetDragHandleRegionState
    extends State<_OpenVtsSheetDragHandleRegion> {
  bool _didDrag = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) {
        _didDrag = false;
      },
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: (_) => _handleVerticalDragEnd(),
      onVerticalDragCancel: _handleVerticalDragEnd,
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

  void _handleVerticalDragEnd() {
    if (!_didDrag || !widget.snap || !widget.controller.isAttached) {
      _didDrag = false;
      return;
    }

    _didDrag = false;
    unawaited(
      widget.controller
          .animateTo(
            _nearestSnapSize(widget.controller.size),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
          )
          .catchError((_) {}),
    );
  }

  double _nearestSnapSize(double size) {
    var nearest = widget.snapSizes.first;
    var nearestDistance = (size - nearest).abs();

    for (final snapSize in widget.snapSizes.skip(1)) {
      final distance = (size - snapSize).abs();
      if (distance < nearestDistance) {
        nearest = snapSize;
        nearestDistance = distance;
      }
    }

    return nearest;
  }
}
