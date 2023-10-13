import 'package:flame_workspace/project/project.dart';
import 'package:flutter/material.dart';

import 'structure_view.dart';

class WorkbenchView extends StatelessWidget {
  final FlameProject project;

  const WorkbenchView({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Workbench(
      project: project,
      child: Scaffold(
        body: Column(children: [
          Container(
            height: 38.0,
            color: Colors.blueGrey,
          ),
          Expanded(
            flex: 2,
            child: Row(children: [
              const Expanded(flex: 1, child: ProjectStructureView()),
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.blue,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.amber,
                ),
              ),
            ]),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.green,
            ),
          ),
        ]),
      ),
    );
  }
}

class Workbench extends InheritedWidget {
  final FlameProject project;

  const Workbench({
    super.key,
    required this.project,
    required super.child,
  });

  static Workbench of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Workbench>()!;
  }

  @override
  bool updateShouldNotify(Workbench oldWidget) {
    return true;
  }
}
