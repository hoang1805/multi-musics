import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return ListTile(
                title: const Text('Phiên bản'),
                subtitle: Text(
                  info == null ? '…' : '${info.version} (${info.buildNumber})',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
