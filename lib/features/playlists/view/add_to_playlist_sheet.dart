import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/db/database.dart';
import '../bloc/playlists_bloc.dart';
import 'playlists_page.dart';

Future<void> showAddToPlaylistSheet(BuildContext context, Track track) async {
  final bloc = context.read<PlaylistsBloc>();
  final messenger = ScaffoldMessenger.of(context);
  final selected = await showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(value: bloc, child: const _AddToPlaylistSheet()),
  );
  if (selected == null || selected.isEmpty) return;
  bloc.add(PlaylistsTrackAdded(track.id, selected));
  HapticFeedback.lightImpact();
  messenger.showSnackBar(
    SnackBar(content: Text('Đã thêm vào ${selected.length} playlist')),
  );
}

class _AddToPlaylistSheet extends StatefulWidget {
  const _AddToPlaylistSheet();

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  final _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Thêm vào playlist', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.plus),
              title: const Text('Tạo playlist mới'),
              onTap: () => PlaylistsPage.createPlaylist(context),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final summary in state.playlists)
                    CheckboxListTile(
                      key: ValueKey(summary.playlist.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(summary.playlist.name),
                      subtitle: Text('${summary.trackCount} bài'),
                      value: _selected.contains(summary.playlist.id),
                      onChanged: (_) => setState(() {
                        if (!_selected.remove(summary.playlist.id)) {
                          _selected.add(summary.playlist.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected.toList()),
                child: const Text('Thêm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
