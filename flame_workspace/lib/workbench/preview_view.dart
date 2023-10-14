import 'package:flutter/material.dart';

import 'workbench_view.dart';

class GamePreviewView extends StatelessWidget {
  const GamePreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final workbench = Workbench.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: workbench.runner.buildPreview(),
          ),
        ),
        const SizedBox(height: 8.0),
        const Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: SingleChildScrollView(
                    padding: EdgeInsetsDirectional.all(14.0),
                    child: SelectableText(
                      '''══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 243 pixels on the bottom.

The relevant error-causing widget was:
  Column
  Column:file:///C:/Users/bruno/Documents/flutter/projects/flame_workspace/lib/workbench/preview_view.dart:36:22
                  
To inspect this widget in Flutter DevTools, visit:
http://127.0.0.1:9101/#/inspector?uri=http%3A%2F%2F127.0.0.1%3A52854%2FRMcl8-DeYuA%3D%2F&inspectorRef=inspector-853
                  
The overflowing RenderFlex has an orientation of Axis.vertical.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#d3141 relayoutBoundary=up12 OVERFLOWING:
  creator: Column ← Padding ← Semantics ← DefaultTextStyle ← AnimatedDefaultTextStyle ←
    _InkFeatures-[GlobalKey#0dae2 ink renderer] ← NotificationListener<LayoutChangedNotification> ←
    CustomPaint ← _ShapeBorderPaint ← PhysicalShape ← _MaterialInterior ← Material ← ⋯
  parentData: offset=Offset(14.0, 14.0) (can use size)
  constraints: BoxConstraints(0.0<=w<=615.0, h=176.8)
  size: Size(615.0, 176.8)
  direction: vertical
  mainAxisAlignment: start
  mainAxisSize: max
  crossAxisAlignment: center
  verticalDirection: down
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
  
Performing hot reload...
Reloaded 1 of 1036 libraries in 447ms (compile: 46 ms, reload: 169 ms, reassemble: 115 ms''',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text('Output'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
