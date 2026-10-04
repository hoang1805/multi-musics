import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player slot (plan 2).
          const SizedBox.shrink(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: const [
              NavigationDestination(icon: Icon(LucideIcons.library), label: 'Thư viện'),
              NavigationDestination(icon: Icon(LucideIcons.listMusic), label: 'Playlist'),
              NavigationDestination(icon: Icon(LucideIcons.settings), label: 'Cài đặt'),
            ],
          ),
        ],
      ),
    );
  }
}
