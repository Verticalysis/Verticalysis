// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';
import 'package:tabbed_view/tabbed_view.dart';

import '../domain/frontend/adapter/AnnotatedCSVadapter.dart';
import '../domain/amorphous/EventManifold.dart';
import '../domain/byteStream/ByteStream.dart';
import '../domain/schema/Schema.dart';
import '../models/ProjectionsModel.dart';
import '../models/SchemasModel.dart';
import 'helper/Events.dart';
import 'helper/Formatter.dart';
import 'helper/LoadWithSchema.dart';
import 'helper/MonitorModeController.dart';
import 'shared/Latch.dart';
import 'shared/NestedMenu.dart';
import 'toolPanes/Analyze.dart';
import 'toolPanes/Collect.dart';
import 'toolPanes/Plotter.dart';
import 'MiniMap.dart';
import 'Style.dart';
import 'ThemedWidgets.dart';
import 'Unifinder.dart';
import 'Verticell.dart';

final class ResizeState {
  double prevCursorY = 0;
  double startHeight = 0;
}

final class MonitorMode extends StatelessWidget {
  final TabData container;
  final SchemasModel schemasModel;

  final _toolHeight = ValueNotifier(.0);
  final _toolView = ValueNotifier(Toolset.none);
  final resizeState = ResizeState();

  final _toolset = <Widget>[];

  static const minToolHeight = 60;

  bool get toolVisible => _toolView.value != Toolset.none;

  final MonitorModeController _controller;
  final UnifinderController _unifinderController;

  final Channel<Notifer3<int, int, Iterable<(
    String, List<String?>
  )>>> _selectRegionUpdateCh;

  MonitorMode(
    ByteStream stream, Schema schema, SchemasModel schemas, TabData container
  ): this._(MonitorModeController(
    stream,
    schema,
    EventManifold(onStreamError),
    EventDispatcher(Event.values),
  ), schemas, container);

  MonitorMode._(
    MonitorModeController controller, this.schemasModel, TabData container
  ): _selectRegionUpdateCh = controller.getChannel(Event.selectRegionUpdate),
   _controller = controller,
   _unifinderController = UnifinderController(controller),
   container = container {
    container.value = dispose;
    _toolset.add(Analyze(_controller));
    _toolset.add(Collect(_controller, ProjectionsModel.single(
      controller.projectionsModel.current.cleared
    ), controller.vcxController));
    _toolset.add(Plotter(
      controller, controller.projectionsModel, controller.pipelineModel
    ));

    controller.vcxController.onRegionSelect = onRegionUpdate;

    WidgetsBinding.instance.addObserver(
      WindowSizeObserver(controller.updateScrollModel, this)
    );

    controller.listen(
      Event.expandToolView,
      (Toolset tool) => expandToolView(tool)
    );
    controller.initChannels();
  }


  void onRegionUpdate(
    int startRow, int endRow, Iterable<(String, List<String?>)> columns
  ) {
    _selectRegionUpdateCh.notify(startRow, endRow, columns);
    expandToolView(Toolset.analyze);
  }


  void expandToolView(Toolset tool) {
    _toolHeight.value = _toolHeight.value == 0 ? 180 : _toolHeight.value.abs();
    _toolView.value = tool;
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ColorScheme.of(context).surfaceContainer,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surface,
            boxShadow: [BoxShadow(
            offset: const Offset(.0, 0.6),
            color: ColorScheme.of(context).onSurface,
            blurRadius: 0.6
          )]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 9,
          children: [
            NestedMenu(
              buildActions(TextTheme.of(context).titleMedium)
            ).withIcon(
              Icon(
                Icons.auto_awesome_mosaic_outlined,
                color: ColorScheme.of(context).onSurface,
              ),
              cursor: SystemMouseCursors.basic,
              iconSize: 27,
            ),
            Expanded(child: SizedBox(
              height: 40,
              child: ClipRect( // https://github.com/flutter/flutter/issues/153240
                child: Unifinder(_unifinderController)
              )
            ))
          ]
        ),
      ),
      MiniMap(
        _controller.projectionsModel,
        _controller.scrollModel,
        _controller.selectionsModel,
        _controller.onMiniMapSliderDrag,
        108
      ),
      Expanded(child: Container(
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: ColorScheme.of(context).primary.withAlpha(60)
          ),
          child: ListenableBuilder( // Verticatrix
            listenable: _controller.projectionsModel,
            builder: (context, _) => buildVerticatrix(
              ColorScheme.of(context),
              TextTheme.of(context),
              _controller.vcxController,
              PrimaryHeaderBuilder(_controller).build,
              PrimaryRowHeaderBuilder(_controller).build,
              _controller.selectionsModel,
              Formatter.formatters,
            )
          ),
        ),
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surfaceContainer,
          boxShadow: [BoxShadow(
            offset: const Offset(.0, -0.6),
            color: ColorScheme.of(context).onSurface,
            blurRadius: 0.6
          )]
        ),
      )),
      Stack(children: [
        ValueListenableBuilder( // tool view
          valueListenable: _toolView,
          builder: (context, toolView, _) => IndexedStack(
            index: toolView.index - 1,
            children: [ for(
              final tool in Toolset.values.skip(1)
            ) ValueListenableBuilder( // tool view
              valueListenable: _toolHeight,
              child: _toolset[tool.index - 1],
              builder: (context, height, childTool) => SizedBox(
                height: toolView == tool ? _toolHeight.value : 0,
                // width: MediaQuery.of(context).size.width,
                child: childTool
              )
            )],
          )
        ),
        ValueListenableBuilder( // resizer at the top of the tool view
          valueListenable: _toolView, // No resizer when no tool is shown
          builder: (context, toolMode, _) => Positioned( // resizer
            top: 0,
            left: 0,
            right: 0,
            child: toolMode == Toolset.none ? _void : MouseRegion(
              opaque: false,  // pass through scroll event
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  resizeState.prevCursorY = details.globalPosition.dy;
                  resizeState.startHeight = _toolHeight.value;
                },
                onPanUpdate: (details) {
                  final newHeight = resizeState.startHeight - (
                    details.globalPosition.dy
                    - resizeState.prevCursorY
                  );
                  if(newHeight >= minToolHeight) {
                    _toolHeight.value = newHeight;
                  }
                },
                onPanEnd: (_) {
                  _controller.scrollModel.setLowerEdge(
                    _controller.vcxController.normalizedLowerEdge(),
                    _controller.projectionsModel.scrollReference
                  );
                },
                child: const SizedBox(height: 8,),
              ),
            ),
          ),
        )
      ]),//),
      Container( // footer
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surface,
          boxShadow: [BoxShadow(
            color: ColorScheme.of(context).onSurface,
            blurRadius: 0.6
          )]
        ),
        child: ValueListenableBuilder(
          valueListenable: _toolView,
          builder: (context, toolView, _) => Row(children: [
            for(final tool in Toolset.values.skip(1)) Latch(
              tool.label,
              _toolView.value == tool ?
                ColorScheme.of(context).primary :
                ColorScheme.of(context).onSurface,
              textStyle: TextTheme.of(context).bodyMedium!,
              hoveringColor: ColorScheme.of(context).surfaceBright,
              onClick: () {
                if(_toolView.value == tool) {
                  _toolHeight.value = -_toolHeight.value;
                  _toolView.value = Toolset.none;
                } else expandToolView(tool);
              }
            ),
            const Spacer(),
            Container(
              /*child: ValueListenableBuilder(
                valueListenable: ,
                builder: (context, , _) => Text(),
              )*/
            )
          ])
        )
      )
      //)
    ])
  );

  List<Widget> buildActions(TextStyle? itemStyle) => [
    SubmenuButton(
      style: menuItemStyle,
      child: Text("Interleave", style: itemStyle),
      menuChildren: [ for(final sch in Iterable.generate(
        schemasModel.length, schemasModel.enumSchema
      )) MenuItemButton(
        style: menuItemStyle,
        child: Text(sch, style: itemStyle),
        onPressed: () {
          schemasModel.getSchemaNoThrow(sch, (schema, _) async {
            final result = await FilePicker.platform.pickFiles();
            if(result != null) {
              ByteStreamLoader.load(
                AddressFamily.file,
                result.path,
                (stream) => _controller.pipelineModel.connect(schema, stream)
              );
              // TODO: notify plotter for potential new reference columns
            }
          });
        },
      )],
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Hide entry numbers", style: itemStyle),
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Select all entries", style: itemStyle),
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Unselect all entries", style: itemStyle),
    ),
    SubmenuButton(
      style: menuItemStyle,
      child: Text(
        "Export as ...",
        style: itemStyle
      ),
      menuChildren: [
        for(final (name, formatter) in Formatter.formatters) MenuItemButton(
          style: menuItemStyle,
          child: Text(name, style: itemStyle),
          onPressed: () {}
        )
      ],
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Scroll to bottom on update", style: itemStyle)
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("About", style: itemStyle)
    )
  ];

  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(WindowSizeObserver(() {}, this));
    _unifinderController.discard();
  }

  static const _void = SizedBox.shrink();

  static void onStreamError(Object? error, StackTrace t) => switch(error) {
    final MissingAttributeException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Missing Attribute in Source',
      text: "${except.attribute} is declared in the schema but not found.",
      iconStyle: IconStyle.warning,
    ),
    final FormatException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Source Format Error',
      text: "${except.message} ${except.source}line: ${except.offset}\n $t",
      iconStyle: IconStyle.warning,
    ),
    final FileSystemException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'File System Error',
      text: "An error occurred when reading ${except.path}: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final SocketException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Socket Error',
      text: "${except.address} connection lost: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final ProcessException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Subprocess Error',
      text: "${except.executable} reported an error: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final StdoutException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Subprocess stdout Error',
      text: "An error occurred when reading from stdout: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final IOException _ => FlutterPlatformAlert.showAlert(
      windowTitle: 'Unknown IO Error',
      text: "An error occurred when reading from stream.",
      iconStyle: IconStyle.warning,
    ),
    _ => FlutterPlatformAlert.showAlert(
      windowTitle: 'Unknown Error',
      text: error.toString(),
      iconStyle: IconStyle.warning,
    ),
  };
}

final class WindowSizeObserver with WidgetsBindingObserver {
  WindowSizeObserver(this.onWindowSizeChange, this.toplevel);
  VoidCallback onWindowSizeChange;
  MonitorMode toplevel;

  @override
  void didChangeMetrics() => WidgetsBinding.instance.addPostFrameCallback((_) {
    onWindowSizeChange();
  });

  @override
  bool operator ==(Object rhs) => switch(rhs) {
    final WindowSizeObserver rhs => rhs.toplevel == toplevel,
    _ => false
  };
}
