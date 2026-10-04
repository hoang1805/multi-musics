import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/duration_format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/track_tile.dart';
import '../../../data/models/playlist_models.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../bloc/playlist_detail_bloc.dart';
import '../widgets/playlist_cover.dart';
import 'playlist_name_dialog.dart';

class PlaylistDetailPage extends StatelessWidget {
  const PlaylistDetailPage({super.key, required this.playlistId});

  final int playlistId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistDetailBloc(playlists: context.read<PlaylistRepository>())
        ..add(PlaylistDetailSubscriptionRequested(playlistId)),
      child: const PlaylistDetailView(),
    );
  }
}

class PlaylistDetailView extends StatelessWidget {
  const PlaylistDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaylistDetailBloc, PlaylistDetailState>(
      listenWhen: (prev, next) =>
          prev.status != next.status &&
          (next.status == PlaylistDetailStatus.deleted ||
              next.status == PlaylistDetailStatus.notFound),
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(
            actions: [if (detail != null) _Menu(detail: detail)],
          ),
          body: switch ((state.status, detail)) {
            (PlaylistDetailStatus.ready, final detail?) => _Body(detail: detail),
            (PlaylistDetailStatus.loading, _) =>
              const Center(child: CircularProgressIndicator()),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final PlaylistDetail detail;

  @override
  Widget build(BuildContext context) {
    final header = _Header(detail: detail);
    if (detail.items.isEmpty) {
      return Column(
        children: [
          header,
          const Expanded(
            child: EmptyState(
              icon: LucideIcons.listMusic,
              title: 'Playlist trống',
              message: 'Thêm bài từ tab Thư viện',
            ),
          ),
        ],
      );
    }

    final bloc = context.read<PlaylistDetailBloc>();
    final colors = AppColors.of(context);
    return ReorderableListView.builder(
      header: header,
      buildDefaultDragHandles: false,
      itemCount: detail.items.length,
      onReorderStart: (_) => HapticFeedback.selectionClick(),
      onReorderItem: (from, to) => bloc.add(PlaylistDetailEntryMoved(from, to)),
      itemBuilder: (context, i) {
        final item = detail.items[i];
        return Dismissible(
          key: ValueKey(item.entryId),
          direction: DismissDirection.endToStart,
          background: ColoredBox(
            color: colors.destructive,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Icon(LucideIcons.trash2, color: colors.onAccent),
              ),
            ),
          ),
          // The bloc removes the row optimistically; Dismissible never does.
          confirmDismiss: (_) async {
            bloc.add(PlaylistDetailEntryRemoved(item.entryId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã gỡ khỏi playlist')),
            );
            return false;
          },
          child: ReorderableDelayedDragStartListener(
            index: i,
            child: TrackTile(
              track: item.track,
              trailing: ReorderableDragStartListener(
                index: i,
                child: const SizedBox.square(
                  dimension: AppSpacing.minTouch,
                  child: Icon(LucideIcons.gripVertical, size: 20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final PlaylistDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final covers = [
      for (final item in detail.items)
        ?item.track.artworkUrl,
    ].take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          PlaylistCover(artworks: covers, size: 160),
          const SizedBox(height: AppSpacing.md),
          Text(
            detail.playlist.name,
            style: text.displaySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${detail.items.length} bài · ${formatTotalDuration(detail.knownDuration)}',
            style: text.bodyMedium?.copyWith(color: AppColors.of(context).mutedForeground),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { rename, delete }

class _Menu extends StatelessWidget {
  const _Menu({required this.detail});

  final PlaylistDetail detail;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'Tùy chọn',
      icon: const Icon(LucideIcons.ellipsis),
      onSelected: (action) => switch (action) {
        _MenuAction.rename => _rename(context),
        _MenuAction.delete => _delete(context),
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: _MenuAction.rename, child: Text('Đổi tên')),
        PopupMenuItem(value: _MenuAction.delete, child: Text('Xóa playlist')),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final bloc = context.read<PlaylistDetailBloc>();
    final name = await showPlaylistNameDialog(
      context,
      title: 'Đổi tên playlist',
      initial: detail.playlist.name,
      confirmLabel: 'Lưu',
    );
    if (name != null) bloc.add(PlaylistDetailRenamed(name));
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<PlaylistDetailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa playlist "${detail.playlist.name}"?'),
        content: const Text('Các bài vẫn còn trong thư viện.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const PlaylistDetailDeleted());
  }
}
