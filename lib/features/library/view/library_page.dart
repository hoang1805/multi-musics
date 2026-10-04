import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_list.dart';
import '../../../core/widgets/source_badge.dart';
import '../../../core/widgets/track_tile.dart';
import '../../../data/db/database.dart';
import '../../../sources/source_type.dart';
import '../bloc/library_bloc.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({
    super.key,
    required this.onAddPressed,
    required this.onAddToPlaylist,
  });

  final VoidCallback onAddPressed;
  final ValueChanged<Track> onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện'),
        actions: [
          IconButton(
            tooltip: 'Thêm bài',
            icon: const Icon(LucideIcons.plus),
            onPressed: onAddPressed,
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.loading) return const SkeletonList();
          if (state.all.isEmpty) {
            return const EmptyState(
              icon: LucideIcons.music,
              title: 'Chưa có bài nào',
              message: 'Bấm + để dán link từ Spotify, YouTube hoặc SoundCloud',
            );
          }
          final visible = state.visible;
          return Column(
            children: [
              _FilterBar(state: state),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('Không có bài nào khớp'))
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, i) => _SwipeableTrack(
                          key: ValueKey(visible[i].id),
                          track: visible[i],
                          onAddToPlaylist: onAddToPlaylist,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LibraryBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (q) => bloc.add(LibraryQueryChanged(q)),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Lọc theo tên bài, nghệ sĩ',
              prefixIcon: Icon(LucideIcons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final source in SourceType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      avatar: SourceBadge(source: source),
                      label: Text(source.displayName),
                      selected: state.sources.contains(source),
                      onSelected: (_) => bloc.add(LibrarySourceToggled(source)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableTrack extends StatelessWidget {
  const _SwipeableTrack({
    super.key,
    required this.track,
    required this.onAddToPlaylist,
  });

  final Track track;
  final ValueChanged<Track> onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Dismissible(
      key: ValueKey('dismiss-${track.id}'),
      background: _SwipeBackground(
        color: colors.accent,
        icon: LucideIcons.listPlus,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        color: colors.destructive,
        icon: LucideIcons.trash2,
        alignment: Alignment.centerRight,
      ),
      // Always returns false: the row disappears when the library stream
      // updates, never by Dismissible itself.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAddToPlaylist(track);
        } else if (await _confirmDelete(context)) {
          if (context.mounted) {
            context.read<LibraryBloc>().add(LibraryTrackDeleted(track.id));
          }
        }
        return false;
      },
      child: TrackTile(track: track),
    );
  }

  static Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài này?'),
        content: const Text('Bài sẽ bị gỡ khỏi mọi playlist.'),
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
    return confirmed ?? false;
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Icon(icon, color: AppColors.of(context).onAccent),
        ),
      ),
    );
  }
}
