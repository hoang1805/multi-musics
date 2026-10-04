import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_dependencies.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/library_writer.dart';
import 'data/repositories/playlist_repository.dart';
import 'data/repositories/track_repository.dart';
import 'features/library/bloc/library_bloc.dart';
import 'features/library/view/add_track_sheet.dart';
import 'features/library/view/library_page.dart';
import 'features/playlists/bloc/playlists_bloc.dart';
import 'features/playlists/view/add_to_playlist_sheet.dart';
import 'features/playlists/view/playlist_detail_page.dart';
import 'features/playlists/view/playlists_page.dart';
import 'features/settings/view/settings_page.dart';
import 'features/shell/app_shell.dart';
import 'sources/link_parser.dart';
import 'sources/metadata/metadata_fetcher.dart';

class MultiMusicsApp extends StatefulWidget {
  const MultiMusicsApp(this.deps, {super.key});

  final AppDependencies deps;

  @override
  State<MultiMusicsApp> createState() => _MultiMusicsAppState();
}

class _MultiMusicsAppState extends State<MultiMusicsApp> {
  late final GoRouter _router = _buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.deps;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppLogger>.value(value: deps.logger),
        RepositoryProvider<TrackRepository>.value(value: deps.tracks),
        RepositoryProvider<PlaylistRepository>.value(value: deps.playlists),
        RepositoryProvider<LibraryWriter>.value(value: deps.writer),
        RepositoryProvider<LinkParser>.value(value: deps.linkParser),
        RepositoryProvider<MetadataFetcher>.value(value: deps.metadata),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LibraryBloc(tracks: deps.tracks)
              ..add(const LibrarySubscriptionRequested()),
          ),
          BlocProvider(
            create: (_) => PlaylistsBloc(playlists: deps.playlists)
              ..add(const PlaylistsSubscriptionRequested()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Multi Musics',
          theme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      ),
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/library',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => LibraryPage(
                  onAddPressed: () => _addTrack(context),
                  onAddToPlaylist: (track) => showAddToPlaylistSheet(context, track),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/playlists',
                builder: (context, state) => PlaylistsPage(
                  onOpen: (id) => context.go('/playlists/$id'),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PlaylistDetailPage(
                      playlistId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  static Future<void> _addTrack(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showAddTrackSheet(
      context,
      playlists: context.read<PlaylistsBloc>().state.playlists,
    );
    if (saved != null) {
      messenger.showSnackBar(SnackBar(content: Text('Đã thêm: ${saved.title}')));
    }
  }
}
