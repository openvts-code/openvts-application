import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_search_field.dart';
import '../../controllers/user_providers.dart';
import '../../models/user_share_track_link_model.dart';
import 'widgets/user_share_track_link_card.dart';
import 'widgets/user_share_track_link_delete_sheet.dart';
import 'widgets/user_share_track_link_form_sheet.dart';
import 'widgets/user_share_track_link_qr_sheet.dart';

class UserShareTrackLinksScreen extends ConsumerStatefulWidget {
  const UserShareTrackLinksScreen({super.key});

  @override
  ConsumerState<UserShareTrackLinksScreen> createState() =>
      _UserShareTrackLinksScreenState();
}

class _UserShareTrackLinksScreenState
    extends ConsumerState<UserShareTrackLinksScreen> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userShareTrackLinkControllerProvider);
    final controller = ref.read(userShareTrackLinkControllerProvider.notifier);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return OpenVtsPageScaffold(
      title: 'Track Links',
      headerMode: OpenVtsPageHeaderMode.closeable,
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (state.isLoading && state.links.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: OpenVtsLoader(),
              )
            else if (state.errorMessage != null && state.links.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: OpenVtsErrorView(
                  message: state.errorMessage!,
                  onRetry: controller.load,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: _HeaderCard(
                  visibleCount: state.visibleCount,
                  totalCount: state.totalCount,
                  isRefreshing: state.isRefreshing,
                  onNew: () => _openFormSheet(context),
                  onRefresh: state.isRefreshing ? null : controller.refresh,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: OpenVtsSpacing.sm),
              ),
              SliverToBoxAdapter(
                child: _SearchCard(
                  onChanged: _setSearchQueryDebounced,
                ),
              ),
              if (state.errorMessage != null) ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: OpenVtsSpacing.sm),
                ),
                SliverToBoxAdapter(
                  child: _InlineError(message: state.errorMessage!),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: OpenVtsSpacing.sm),
              ),
              if (state.links.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: OpenVtsEmptyState(
                    title: 'No share links',
                    message:
                        'Create a public track link to share live vehicle tracking.',
                  ),
                )
              else
                SliverList.separated(
                  itemCount: state.links.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: OpenVtsSpacing.sm),
                  itemBuilder: (context, index) {
                    final link = state.links[index];
                    final publicUrl = resolveShareTrackPublicUrl(
                      link: link,
                      apiBaseUrl: apiBaseUrl,
                    );
                    final hasUrl = publicUrl.trim().isNotEmpty;
                    return UserShareTrackLinkCard(
                      link: link,
                      publicUrl: hasUrl ? publicUrl : null,
                      isBusy: state.isUpdating(link.endpointId) ||
                          state.isDeleting(link.endpointId),
                      onCopy:
                          hasUrl ? () => _copyUrl(context, publicUrl) : null,
                      onOpen:
                          hasUrl ? () => _openUrl(context, publicUrl) : null,
                      onQr: hasUrl
                          ? () => _openQrSheet(context, publicUrl)
                          : null,
                      onEdit: () => _openFormSheet(context, link: link),
                      onDelete: () => _confirmDelete(context, link),
                    );
                  },
                ),
              if (state.hasMore) ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: OpenVtsSpacing.sm),
                ),
                SliverToBoxAdapter(
                  child: _LoadMoreButton(
                    isLoading: state.isLoadingMore,
                    onPressed: state.isLoadingMore ? null : controller.loadMore,
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: OpenVtsSpacing.lg),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setSearchQueryDebounced(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      unawaited(
        ref
            .read(userShareTrackLinkControllerProvider.notifier)
            .setSearchQuery(query),
      );
    });
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ToastHelper.showSuccess('Link copied.', context: context);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ToastHelper.showError('Public URL is not available.', context: context);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) return;
      if (!launched) {
        ToastHelper.showError('Could not open link.', context: context);
      }
    } catch (_) {
      if (context.mounted) {
        ToastHelper.showError('Could not open link.', context: context);
      }
    }
  }

  Future<void> _openFormSheet(
    BuildContext context, {
    UserShareTrackLink? link,
  }) {
    return UserShareTrackLinkFormSheet.show<void>(
      context: context,
      link: link,
    );
  }

  Future<void> _openQrSheet(BuildContext context, String url) {
    return UserShareTrackLinkQrSheet.show<void>(
      context: context,
      publicUrl: url,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserShareTrackLink link,
  ) async {
    final deleted = await UserShareTrackLinkDeleteSheet.show<bool>(
      context: context,
      link: link,
    );

    if (deleted == true && context.mounted) {
      ToastHelper.showSuccess('Track link deleted.', context: context);
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.visibleCount,
    required this.totalCount,
    required this.isRefreshing,
    required this.onNew,
    required this.onRefresh,
  });

  final int visibleCount;
  final int totalCount;
  final bool isRefreshing;
  final VoidCallback onNew;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.share_location_rounded,
                  size: 20,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Track Links',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.titleSmall.copyWith(
                        fontSize: 17,
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Create secure public links for live vehicle tracking.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        fontSize: 12,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: onNew,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'New Link',
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: OpenVtsColors.brandInk,
                      foregroundColor: OpenVtsColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(OpenVtsRadius.button),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              SizedBox.square(
                dimension: 36,
                child: IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  color: OpenVtsColors.textSecondary,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                      side: const BorderSide(color: OpenVtsColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              '$visibleCount of $totalCount links',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: OpenVtsSearchField(
        hintText: 'Search by code...',
        onChanged: onChanged,
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OpenVtsButton(
      label: isLoading ? 'Loading...' : 'Load more',
      onPressed: onPressed,
      isLoading: isLoading,
      variant: OpenVtsButtonVariant.secondary,
      height: 40,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: OpenVtsColors.error,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
