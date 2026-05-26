import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';

/// Isolated optional service: searches places via Nominatim and generates a
/// driving route via the public OSRM demo server. Both are best-effort and
/// safe to fail — the panel only surfaces success or a quiet error and never
/// blocks manual drawing in the editor.
class _RouteGenerationService {
  _RouteGenerationService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 8),
            headers: const <String, String>{
              'User-Agent': 'OpenVTS-Mobile/1.0 (route-search)',
            },
          ),
        );

  final Dio _dio;

  Future<List<_GeoSuggestion>> search(String query) async {
    if (query.trim().length < 3) return const <_GeoSuggestion>[];
    final res = await _dio.get<dynamic>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: <String, dynamic>{
        'q': query.trim(),
        'format': 'json',
        'limit': 6,
        'addressdetails': 0,
      },
    );
    final data = res.data;
    if (data is! List) return const <_GeoSuggestion>[];
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((m) {
          final lat = double.tryParse('${m['lat']}');
          final lon = double.tryParse('${m['lon']}');
          final label = '${m['display_name'] ?? ''}';
          if (lat == null || lon == null) return null;
          return _GeoSuggestion(label: label, point: LatLng(lat, lon));
        })
        .whereType<_GeoSuggestion>()
        .toList(growable: false);
  }

  Future<List<LatLng>> route(LatLng source, LatLng destination) async {
    final coords =
        '${source.longitude},${source.latitude};${destination.longitude},${destination.latitude}';
    final res = await _dio.get<dynamic>(
      'https://router.project-osrm.org/route/v1/driving/$coords',
      queryParameters: const <String, dynamic>{
        'overview': 'full',
        'geometries': 'geojson',
      },
    );
    final data = res.data;
    if (data is! Map) return const <LatLng>[];
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return const <LatLng>[];
    final first = routes.first;
    if (first is! Map) return const <LatLng>[];
    final geometry = first['geometry'];
    if (geometry is! Map) return const <LatLng>[];
    final coordsList = geometry['coordinates'];
    if (coordsList is! List) return const <LatLng>[];
    return coordsList
        .whereType<List>()
        .map((pair) {
          if (pair.length < 2) return null;
          final lon = (pair[0] as num?)?.toDouble();
          final lat = (pair[1] as num?)?.toDouble();
          if (lat == null || lon == null) return null;
          return LatLng(lat, lon);
        })
        .whereType<LatLng>()
        .toList(growable: false);
  }
}

class _GeoSuggestion {
  const _GeoSuggestion({required this.label, required this.point});
  final String label;
  final LatLng point;
}

/// Side panel for source/destination search + OSRM route generation. Emits
/// `onRouteGenerated` with the polyline points when the user accepts a
/// generated geometry. Failures are surfaced inline and never thrown out.
class UserRouteSearchPanel extends StatefulWidget {
  const UserRouteSearchPanel({
    super.key,
    required this.onRouteGenerated,
    this.onClose,
  });

  final void Function(List<LatLng> points) onRouteGenerated;
  final VoidCallback? onClose;

  @override
  State<UserRouteSearchPanel> createState() => _UserRouteSearchPanelState();
}

class _UserRouteSearchPanelState extends State<UserRouteSearchPanel> {
  final _service = _RouteGenerationService();
  final _sourceController = TextEditingController();
  final _destController = TextEditingController();

  _GeoSuggestion? _source;
  _GeoSuggestion? _dest;

  List<_GeoSuggestion> _sourceSuggestions = const <_GeoSuggestion>[];
  List<_GeoSuggestion> _destSuggestions = const <_GeoSuggestion>[];

  bool _loadingSource = false;
  bool _loadingDest = false;
  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _sourceController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(
      {required bool isSource, required String query}) async {
    setState(() {
      if (isSource) {
        _loadingSource = true;
      } else {
        _loadingDest = true;
      }
      _error = null;
    });
    try {
      final results = await _service.search(query);
      if (!mounted) return;
      setState(() {
        if (isSource) {
          _sourceSuggestions = results;
        } else {
          _destSuggestions = results;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Search unavailable. Draw the route manually.');
    } finally {
      if (mounted) {
        setState(() {
          if (isSource) {
            _loadingSource = false;
          } else {
            _loadingDest = false;
          }
        });
      }
    }
  }

  Future<void> _generate() async {
    if (_source == null || _dest == null || _generating) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final points = await _service.route(_source!.point, _dest!.point);
      if (!mounted) return;
      if (points.length < 2) {
        setState(() => _error = 'No route returned. Draw manually instead.');
        return;
      }
      widget.onRouteGenerated(points);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Route service unavailable. Draw manually.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route,
                size: 16,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Generate from search',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onClose != null)
                InkResponse(
                  onTap: widget.onClose,
                  radius: 18,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _SearchInput(
            controller: _sourceController,
            label: 'From',
            picked: _source,
            loading: _loadingSource,
            suggestions: _sourceSuggestions,
            onChanged: (q) => _runSearch(isSource: true, query: q),
            onPick: (s) => setState(() {
              _source = s;
              _sourceController.text = s.label;
              _sourceSuggestions = const <_GeoSuggestion>[];
            }),
            onClear: () => setState(() {
              _source = null;
              _sourceController.clear();
              _sourceSuggestions = const <_GeoSuggestion>[];
            }),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _SearchInput(
            controller: _destController,
            label: 'To',
            picked: _dest,
            loading: _loadingDest,
            suggestions: _destSuggestions,
            onChanged: (q) => _runSearch(isSource: false, query: q),
            onPick: (s) => setState(() {
              _dest = s;
              _destController.text = s.label;
              _destSuggestions = const <_GeoSuggestion>[];
            }),
            onClear: () => setState(() {
              _dest = null;
              _destController.clear();
              _destSuggestions = const <_GeoSuggestion>[];
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              _error!,
              style:
                  OpenVtsTypography.meta.copyWith(color: OpenVtsColors.error),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Generate route',
            onPressed: (_source != null && _dest != null) ? _generate : null,
            isLoading: _generating,
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.label,
    required this.picked,
    required this.loading,
    required this.suggestions,
    required this.onChanged,
    required this.onPick,
    required this.onClear,
  });

  final TextEditingController controller;
  final String label;
  final _GeoSuggestion? picked;
  final bool loading;
  final List<_GeoSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<_GeoSuggestion> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: OpenVtsTypography.body,
            decoration: InputDecoration(
              isDense: true,
              hintText: label,
              hintStyle: OpenVtsTypography.body
                  .copyWith(color: OpenVtsColors.textTertiary),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  label,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (picked != null
                      ? IconButton(
                          iconSize: 16,
                          splashRadius: 18,
                          onPressed: onClear,
                          icon: const Icon(
                            Icons.close,
                            color: OpenVtsColors.textSecondary,
                          ),
                        )
                      : null),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                borderSide: const BorderSide(color: OpenVtsColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                borderSide: const BorderSide(color: OpenVtsColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                borderSide: const BorderSide(
                  color: OpenVtsColors.brandInk,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.button),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: OpenVtsColors.divider,
              ),
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return InkWell(
                  onTap: () => onPick(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OpenVtsSpacing.sm,
                      vertical: 8,
                    ),
                    child: Text(
                      s.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
