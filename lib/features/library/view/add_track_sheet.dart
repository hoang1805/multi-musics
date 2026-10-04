import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/artwork_image.dart';
import '../../../core/widgets/source_badge.dart';
import '../../../data/db/database.dart';
import '../../../data/models/playlist_models.dart';
import '../../../data/repositories/library_writer.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../sources/link_parser.dart';
import '../../../sources/metadata/metadata_fetcher.dart';
import '../bloc/add_track_bloc.dart';

/// Returns the saved track, or `null` when the sheet is dismissed.
Future<Track?> showAddTrackSheet(
  BuildContext context, {
  required List<PlaylistSummary> playlists,
}) {
  return showModalBottomSheet<Track>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider(
      create: (_) => AddTrackBloc(
        parser: context.read<LinkParser>(),
        metadata: context.read<MetadataFetcher>(),
        tracks: context.read<TrackRepository>(),
        writer: context.read<LibraryWriter>(),
        playlists: context.read<PlaylistRepository>(),
        logger: context.read<AppLogger>(),
      ),
      child: SingleChildScrollView(child: AddTrackSheetView(playlists: playlists)),
    ),
  );
}

class AddTrackSheetView extends StatelessWidget {
  const AddTrackSheetView({super.key, required this.playlists});

  final List<PlaylistSummary> playlists;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = Theme.of(context).textTheme;

    return BlocConsumer<AddTrackBloc, AddTrackState>(
      listenWhen: (prev, next) => next.status == AddTrackStatus.done,
      listener: (context, state) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(state.saved);
      },
      builder: (context, state) {
        final bloc = context.read<AddTrackBloc>();
        final busy = state.status == AddTrackStatus.resolving ||
            state.status == AddTrackStatus.saving;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Thêm bài', style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: FilledButton.tonalIcon(
                  icon: const Icon(LucideIcons.clipboardPaste),
                  label: const Text('Dán link'),
                  onPressed: busy ? null : () => _paste(bloc),
                ),
              ),
              if (state.failure case final failure?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  failure.message,
                  style: text.bodyMedium?.copyWith(color: colors.destructive),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lần đầu iOS sẽ hỏi quyền dán. Để không bị hỏi lại: Cài đặt iOS → '
                'Multi Musics → Dán từ app khác → Cho phép.',
                style: text.labelSmall?.copyWith(color: colors.mutedForeground),
              ),
              if (state.status == AddTrackStatus.resolving) ...[
                const SizedBox(height: AppSpacing.lg),
                const _PreviewSkeleton(),
              ],
              if (state.draft != null &&
                  (state.status == AddTrackStatus.preview ||
                      state.status == AddTrackStatus.saving)) ...[
                const SizedBox(height: AppSpacing.lg),
                _Preview(state: state),
                if (playlists.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Thêm vào playlist', style: text.titleMedium),
                  for (final summary in playlists)
                    CheckboxListTile(
                      key: ValueKey(summary.playlist.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(summary.playlist.name),
                      value: state.selectedPlaylistIds.contains(summary.playlist.id),
                      onChanged: busy
                          ? null
                          : (_) => bloc.add(AddTrackPlaylistToggled(summary.playlist.id)),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: busy ? null : () => _confirm(context, state),
                    child: Text(_confirmLabel(state)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _confirmLabel(AddTrackState state) {
    if (state.existing == null) return 'Thêm';
    return state.selectedPlaylistIds.isEmpty ? 'Đóng' : 'Lưu';
  }

  static void _confirm(BuildContext context, AddTrackState state) {
    if (state.existing != null && state.selectedPlaylistIds.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    context.read<AddTrackBloc>().add(const AddTrackConfirmed());
  }

  static Future<void> _paste(AddTrackBloc bloc) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    bloc.add(AddTrackLinkSubmitted(data?.text ?? ''));
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final AddTrackState state;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft!;
    final colors = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        ArtworkImage(url: draft.artworkUrl, size: 64),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(draft.title, style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (draft.artist case final artist?)
                Text(
                  artist,
                  style: text.bodyMedium?.copyWith(color: colors.mutedForeground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SourceBadge(source: draft.source, showLabel: true),
                  if (state.existing != null)
                    Chip(
                      label: const Text('Đã có trong thư viện'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: text.labelSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).muted;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
        );
    return Row(
      children: [
        bar(64, 64),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bar(180, 14), const SizedBox(height: AppSpacing.sm), bar(100, 12)],
        ),
      ],
    );
  }
}
