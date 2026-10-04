import 'package:flutter/material.dart';

/// Returns the trimmed name, or `null` when cancelled.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  String title = 'Playlist mới',
  String initial = '',
  String confirmLabel = 'Tạo',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PlaylistNameDialog(
      title: title,
      initial: initial,
      confirmLabel: confirmLabel,
    ),
  );
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.initial,
    required this.confirmLabel,
  });

  final String title;
  final String initial;
  final String confirmLabel;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  String get _name => _controller.text.trim();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.isNotEmpty) Navigator.pop(context, _name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Tên playlist'),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: _name.isEmpty ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
