import 'package:flame_workspace/project/project.dart';
import 'package:flame_workspace/workbench/preview_view.dart';
import 'package:flutter/material.dart';

import 'component_view.dart';
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
            child: Row(children: [
              Expanded(
                flex: 4,
                child: Column(children: [
                  const Expanded(
                    flex: 2,
                    child: Row(children: [
                      Expanded(flex: 1, child: ProjectStructureView()),
                      Expanded(flex: 2, child: GamePreviewView()),
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
              const Expanded(flex: 1, child: ComponentView()),
            ]),
          )
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
