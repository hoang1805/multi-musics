import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/playlist_models.dart';
import '../bloc/playlists_bloc.dart';
import '../widgets/playlist_cover.dart';
import 'playlist_name_dialog.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key, required this.onOpen});

  final ValueChanged<int> onOpen;

  static Future<void> createPlaylist(BuildContext context) async {
    final bloc = context.read<PlaylistsBloc>();
    final name = await showPlaylistNameDialog(context);
    if (name != null) bloc.add(PlaylistsCreated(name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
        actions: [
          IconButton(
            tooltip: 'Tạo playlist',
            icon: const Icon(LucideIcons.plus),
            onPressed: () => createPlaylist(context),
          ),
        ],
      ),
      body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        builder: (context, state) {
          if (state.status == PlaylistsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.playlists.isEmpty) {
            return EmptyState(
              icon: LucideIcons.listMusic,
              title: 'Chưa có playlist',
              message: 'Tạo playlist để gom bài từ nhiều nguồn',
              action: FilledButton(
                onPressed: () => createPlaylist(context),
                child: const Text('Tạo playlist'),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.78,
            ),
            itemCount: state.playlists.length,
            itemBuilder: (context, i) {
              final summary = state.playlists[i];
              return _PlaylistCell(
                key: ValueKey(summary.playlist.id),
                summary: summary,
                onTap: () => onOpen(summary.playlist.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlaylistCell extends StatelessWidget {
  const _PlaylistCell({super.key, required this.summary, required this.onTap});

  final PlaylistSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The cover takes whatever the text leaves, so larger text sizes
          // shrink the artwork instead of overflowing the cell.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.topLeft,
                child: PlaylistCover(
                  artworks: summary.coverArtworks,
                  size: constraints.biggest.shortestSide,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary.playlist.name,
            style: text.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${summary.trackCount} bài',
            style: text.bodyMedium?.copyWith(color: AppColors.of(context).mutedForeground),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
