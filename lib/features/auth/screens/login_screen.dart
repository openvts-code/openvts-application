import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/open_vts_colors.dart';
import '../../../core/theme/open_vts_radius.dart';
import '../../../core/theme/open_vts_spacing.dart';
import '../../../core/theme/open_vts_typography.dart';
import '../../../shared/helpers/toast_helper.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.authenticated) {
        ToastHelper.showSuccess('Login successful');
      }

      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.unauthenticated &&
          next.errorMessage != null &&
          next.errorMessage!.trim().isNotEmpty) {
        ToastHelper.showError(
          next.errorMessage!.replaceFirst(
            RegExp(r'^ApiException\(\d+\):\s*'),
            '',
          ),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideLayout = screenWidth >= 980;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F4F1),
              OpenVtsColors.white,
              Color(0xFFF7F6F4),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  'assets/images/background-full.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.12, -0.28),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      OpenVtsColors.white.withValues(alpha: 0.78),
                      OpenVtsColors.white.withValues(alpha: 0.9),
                      OpenVtsColors.white,
                    ],
                    stops: const [0, 0.38, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.lg,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideLayout ? 1040 : 360,
                    ),
                    child: isWideLayout
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: _LoginHero(compact: false),
                              ),
                              const SizedBox(width: OpenVtsSpacing.xl),
                              SizedBox(
                                width: 420,
                                child: _LoginPanel(
                                  isLoading: isLoading,
                                  errorMessage: authState.errorMessage,
                                  onSubmit: (identifier, password) {
                                    ref
                                        .read(authControllerProvider.notifier)
                                        .login(
                                          identifier: identifier,
                                          password: password,
                                        );
                                  },
                                ),
                              ),
                            ],
                          )
                        : _LoginPanelLayout(
                            isLoading: isLoading,
                            errorMessage: authState.errorMessage,
                            onSubmit: (identifier, password) {
                              ref.read(authControllerProvider.notifier).login(
                                    identifier: identifier,
                                    password: password,
                                  );
                            },
                          ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: OpenVtsSpacing.md,
              bottom: OpenVtsSpacing.lg,
              child: SafeArea(
                minimum: const EdgeInsets.only(
                  right: OpenVtsSpacing.md,
                  bottom: OpenVtsSpacing.md,
                ),
                child: _LoginSettingsButton(
                  onPressed: () => context.push(RoutePaths.apiBaseUrlSettings),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginSettingsButton extends StatelessWidget {
  const _LoginSettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: OpenVtsColors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: OpenVtsColors.border),
            boxShadow: [
              BoxShadow(
                color: OpenVtsColors.brandInk.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: OpenVtsColors.brandInk,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _LoginPanelLayout extends StatelessWidget {
  const _LoginPanelLayout({
    required this.isLoading,
    required this.onSubmit,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final void Function(String email, String password) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LoginHero(compact: true),
        const SizedBox(height: OpenVtsSpacing.lg),
        _LoginPanel(
          isLoading: isLoading,
          errorMessage: errorMessage,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.isLoading,
    required this.onSubmit,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final void Function(String email, String password) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/logo.png',
          height: 48,
          errorBuilder: (_, __, ___) {
            return Text(
              'Open VTS',
              style: OpenVtsTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const SizedBox(height: OpenVtsSpacing.lg),
        LoginForm(
          isLoading: isLoading,
          onSubmit: onSubmit,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              border: Border.all(
                color: OpenVtsColors.error.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              errorMessage!,
              style: OpenVtsTypography.body.copyWith(
                color: OpenVtsColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LoginHero extends StatefulWidget {
  const _LoginHero({required this.compact});

  final bool compact;

  @override
  State<_LoginHero> createState() => _LoginHeroState();
}

class _LoginHeroState extends State<_LoginHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final globeSize = compact ? 238.0 : 340.0;
    final heroWidth = compact ? 320.0 : 560.0;
    final heroHeight = compact ? 268.0 : 430.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final phase = progress * math.pi * 2;
        final imageX = math.sin(phase * 0.5) * 0.24;
        final imageY = -0.18 + math.cos(phase * 0.4) * 0.03;
        final globeFloat = math.sin(phase) * 5;
        final locatorScale = 0.96 + (math.sin(phase * 2.2) * 0.06);

        return SizedBox(
          width: heroWidth,
          height: heroHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitPainter(
                    strokeColor: OpenVtsColors.border.withValues(alpha: 0.72),
                    progress: progress,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, globeFloat),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: globeSize + 64,
                      height: globeSize + 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            OpenVtsColors.white.withValues(alpha: 0.96),
                            OpenVtsColors.surface.withValues(alpha: 0.56),
                            Colors.transparent,
                          ],
                          stops: const [0.18, 0.62, 1],
                        ),
                      ),
                    ),
                    Container(
                      width: globeSize,
                      height: globeSize,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OpenVtsColors.white.withValues(alpha: 0.84),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                OpenVtsColors.brandInk.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/background-full.png',
                              fit: BoxFit.cover,
                              alignment: Alignment(imageX, imageY),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    OpenVtsColors.white.withValues(alpha: 0.1),
                                    Colors.transparent,
                                    OpenVtsColors.brandInk
                                        .withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(-0.18, -0.16),
                                  colors: [
                                    Colors.transparent,
                                    OpenVtsColors.white.withValues(alpha: 0.18),
                                    OpenVtsColors.white.withValues(alpha: 0.72),
                                  ],
                                  stops: const [0.38, 0.7, 1],
                                ),
                              ),
                            ),
                            CustomPaint(
                              painter: _RoutePainter(progress: progress),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: OpenVtsColors.white
                                      .withValues(alpha: 0.52),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0.16, 0.12),
                              child: Transform.scale(
                                scale: locatorScale,
                                child: const _HeroLocator(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _HeroOrbitalChip(
                alignment: const Alignment(-0.18, -0.94),
                icon: Icons.compare_arrows_rounded,
                progress: progress,
                phaseOffset: 0.1,
              ),
              _HeroOrbitalChip(
                alignment: const Alignment(0.82, -0.82),
                icon: Icons.settings_rounded,
                progress: progress,
                phaseOffset: 0.22,
              ),
              _HeroOrbitalChip(
                alignment: const Alignment(-0.9, -0.02),
                icon: Icons.route_rounded,
                progress: progress,
                phaseOffset: 0.38,
              ),
              _HeroOrbitalChip(
                alignment: const Alignment(0.88, 0.1),
                icon: Icons.near_me_rounded,
                progress: progress,
                phaseOffset: 0.56,
              ),
              _HeroOrbitalChip(
                alignment: const Alignment(0.28, 0.92),
                icon: Icons.hub_rounded,
                progress: progress,
                phaseOffset: 0.74,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroOrbitalChip extends StatelessWidget {
  const _HeroOrbitalChip({
    required this.alignment,
    required this.icon,
    required this.progress,
    required this.phaseOffset,
  });

  final Alignment alignment;
  final IconData icon;
  final double progress;
  final double phaseOffset;

  @override
  Widget build(BuildContext context) {
    final phase = ((progress + phaseOffset) % 1) * math.pi * 2;
    final offset = Offset(
      math.cos(phase) * 4,
      math.sin(phase * 1.2) * 6,
    );

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: OpenVtsColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: OpenVtsColors.border),
            boxShadow: [
              BoxShadow(
                color: OpenVtsColors.brandInk.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: OpenVtsColors.brandInkSoft,
          ),
        ),
      ),
    );
  }
}

class _HeroLocator extends StatelessWidget {
  const _HeroLocator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: OpenVtsColors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(color: OpenVtsColors.border),
        boxShadow: [
          BoxShadow(
            color: OpenVtsColors.brandInk.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.gps_fixed_rounded,
        size: 12,
        color: OpenVtsColors.brandInk,
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.strokeColor,
    required this.progress,
  });

  final Color strokeColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final nodeFill = Paint()
      ..color = OpenVtsColors.white.withValues(alpha: 0.96);
    final nodeRing = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2 - 8);

    void drawOrbit(
      double width,
      double height,
      double angle,
      double dashOffset,
    ) {
      final orbitPath = Path();
      orbitPath.addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawPath(
        _buildDashedPath(
          orbitPath,
          dashLength: 4,
          gapLength: 6,
          dashOffset: dashOffset,
        ),
        stroke,
      );
      canvas.restore();
    }

    final dashShift = progress * 84;

    drawOrbit(size.width * 0.94, size.height * 0.34, 0.08, dashShift);
    drawOrbit(size.width * 0.86, size.height * 0.54, -0.26, dashShift * 0.82);
    drawOrbit(size.width * 0.72, size.height * 0.7, 0.34, dashShift * 0.66);
    drawOrbit(size.width * 0.58, size.height * 0.88, -0.46, dashShift * 0.48);

    final nodes = <Offset>[
      Offset(size.width * 0.26, size.height * 0.22),
      Offset(size.width * 0.74, size.height * 0.18),
      Offset(size.width * 0.86, size.height * 0.54),
      Offset(size.width * 0.36, size.height * 0.84),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 3.4, nodeFill);
      canvas.drawCircle(node, 5.2, nodeRing);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.progress != progress;
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.52,
        size.width * 0.5,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.74,
        size.width * 0.78,
        size.height * 0.64,
      );

    final routePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          OpenVtsColors.white,
          OpenVtsColors.white,
          Colors.transparent,
        ],
        stops: [0, 0.22, 0.78, 1],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = OpenVtsColors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(
      metric.length * (0.18 + (progress * 0.54)),
    );

    if (tangent != null) {
      final haloPaint = Paint()
        ..color = OpenVtsColors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final dotPaint = Paint()..color = OpenVtsColors.white;

      canvas.drawCircle(tangent.position, 9, haloPaint);
      canvas.drawCircle(tangent.position, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

Path _buildDashedPath(
  Path source, {
  required double dashLength,
  required double gapLength,
  required double dashOffset,
}) {
  final dashedPath = Path();
  final step = dashLength + gapLength;

  for (final metric in source.computeMetrics()) {
    final length = metric.length;
    var distance = -(dashOffset % step);

    while (distance < length) {
      final start = distance < 0 ? 0.0 : distance;
      final end = math.min(distance + dashLength, length);

      if (end > 0) {
        dashedPath.addPath(metric.extractPath(start, end), Offset.zero);
      }

      distance += step;
    }
  }

  return dashedPath;
}
