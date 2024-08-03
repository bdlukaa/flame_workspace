import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/parser/writer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final scriptEditorKey = GlobalKey<ScriptEditorState>();

class ScriptEditor extends StatefulWidget {
  final String scriptPath;

  const ScriptEditor({
    super.key,
    required this.scriptPath,
  });

  @override
  State<ScriptEditor> createState() => ScriptEditorState();
}

class ScriptEditorState extends State<ScriptEditor> {
  late File file;

  String? content;
  final controller = TextEditingController();

  late StreamSubscription<FileSystemEvent> editSubscription;

  @override
  void initState() {
    super.initState();

    file = File(widget.scriptPath);
    editSubscription = file.watch().listen((event) {
      if (event is FileSystemModifyEvent && mounted) {
        setState(() {
          content = file.readAsStringSync();
          controller.text = content!;
        });
      }
    });
    content = file.readAsStringSync();
    controller.text = content!;
  }

  @override
  void dispose() {
    controller.dispose();
    editSubscription.cancel();
    super.dispose();
  }

  void save() {
    content = controller.text;
    file.writeAsStringSync(controller.text);
  }

  void format() {
    if (content != null) Writer.writeFormatted(file, content!);
  }

  bool get isSaved {
    return content == controller.text;
  }

  @override
  Widget build(BuildContext context) {
    // final workbench = Workbench.of(context);
    final theme = Theme.of(context);

    if (content == null) {
      return const CircularProgressIndicator.adaptive();
    }

    return TextField(
      controller: controller,
      style: GoogleFonts.firaCode(textStyle: theme.textTheme.bodySmall),
      decoration: const InputDecoration(border: InputBorder.none),
      maxLines: null,
      expands: true,
    );
  }
}
