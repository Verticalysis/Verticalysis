// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:yaml/yaml.dart';
import 'package:tabbed_view/tabbed_view.dart';

import '../domain/byteStream/ByteStream.dart';
import '../models/SchemasModel.dart';
import '../utils/FileSystem.dart';
import 'helper/LoadWithSchema.dart';
import 'shared/Clickable.dart';
import 'shared/Hoverable.dart';
import 'shared/Select.dart';
import 'MonitorMode.dart';
import 'ThemedWidgets.dart';
import 'Style.dart';

final class StartupMode extends StatelessWidget {
  final TextEditingController _editController;

  final SchemasModel schemasModel;
  final _mode = ValueNotifier(AddressFamily.file);
  final TabData container;

  final _schema = ValueNotifier<String?>(null);
  final _schemaSelectorControler = MenuController();

  static const _schemaListWidth = 420.0;

  StartupMode(Set<String> schList, this.container, {
    String src = "", super.key
  }): schemasModel = SchemasModel(schList, (schema, source) {
    schema.initialize(loadYamlNode(source), <R>(YamlNode ast) => switch(ast) {
      final YamlList list => list.nodes as R,
      final YamlMap map => map.nodes as R,
      _ => ast.value as R
    });
  }), _editController = TextEditingController(text: src) {
    if(src.isNotEmpty) WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), _schemaSelectorControler.open);
    });
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: _schemaListWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Verticalysis", style: TextStyle(
            fontSize: 48, color: ColorScheme.of(context).onPrimaryContainer
          )),
          const SizedBox(height: 30),
          AddressEditor(_mode, _editController, () {
            _schemaSelectorControler.open();
            if(_schema.value case final String schema) loadWithSchema(
              AddressFamily.file, schema
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 270,
                child: ListenableBuilder(
                  listenable: schemasModel,
                  builder: (context, _) => Select(
                    selected: _schema,
                    initialValue: null,
                    controller: _schemaSelectorControler,
                    dropdownIconColor: ColorScheme.of(context).onSurfaceVariant,
                    anchorBuilder: (context, selected, icon) => HoverEffect(
                      padding: const EdgeInsets.fromLTRB(15, 0, 6, 0),
                      hoveringCosmetic: BoxDecoration(
                        color: ColorScheme.of(context).surfaceBright,
                        borderRadius: const BorderRadius.all(Radius.circular(6))
                      ),
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if(selected case final String schema) Text(
                            schema
                          ) else Text("Select a schema", style: TextStyle(
                            fontSize: 15,
                            color: ColorScheme.of(context).onSurfaceVariant)
                          ),
                          icon
                        ],
                      )
                    ),
                    optionsBuilder: (context, onTap) => [
                      for(final schema in schemasModel.schemas) SizedBox(
                        width: 270,
                        child: MenuItemButton(
                          style: menuItemStyle,
                          onPressed: () {
                            onTap(schema);
                            loadWithSchema(_mode.value, schema);
                          },
                          child: Text(
                            schema, style: TextTheme.of(context).titleMedium
                          ),
                        )
                      ),
                      SizedBox(
                        width: 270,
                        child: MenuItemButton(
                          style: menuItemStyle,
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles();
                            if(res != null && await schemasModel.addSchemaNoThrow(res.path)) {
                              _schema.value = Path(res.path).trunk;
                            }
                          },
                          child: Text(
                            "Add schema", style: TextTheme.of(context).titleMedium
                          ),
                        )
                      )
                    ],
                  )
                )
              ),
              const Spacer(),
              Clickable(
                HoverEffect(
                  inactiveCosmetic: BoxDecoration(
                    color: ColorScheme.of(context).onPrimaryFixed,
                    borderRadius: const BorderRadius.all(Radius.circular(6))
                  ),
                  hoveringCosmetic: BoxDecoration(
                    color: ColorScheme.of(context).primary,
                    borderRadius: const BorderRadius.all(Radius.circular(6))
                  ),
                  align: const Alignment(.0, -0.1),
                  height: 36,
                  width: 108,
                  child: Text("Open", style: TextStyle(
                    fontSize: 17, color: Color(0xFFFFFFFF)
                  )),
                ),
                onClick: () {
                  if(_schema.value case final String schema) {
                    loadWithSchema(_mode.value, schema);
                  } else if(_editController.text.isNotEmpty) ByteStreamLoader.load(
                    _mode.value, _editController.text,
                    (src, strmIntr) {
                      final schema = LoadWithSchema.resolveGenericSchema(src.resourceName);
                      if(schema == null) return;
                      container.text = src.label(schema.name);
                      container.content = MonitorMode(src, schema, schemasModel, container, [ strmIntr ]);
                      discard();
                    }
                  );
                }
              ),
            ]
          ),
          const SizedBox(height: 72),
        ],
      ),
    )
  );

  bool loadWithSchema(AddressFamily type, String schema) {
    if(_editController.text.isEmpty) return false;
    return schemasModel.getSchemaNoThrow(schema, (sch, _) async {
      ByteStreamLoader.load(type, _editController.text, (src, strmIntr) {
        container.text = src.label(schema);
        container.content = MonitorMode(src, sch, schemasModel, container, [ strmIntr ]);
        discard();
      });
    });
  }

  void discard() {
    _editController.dispose();
  }
}

final class AddressEditor extends StatelessWidget {
  AddressEditor(this._mode, this._editController, this.onFilePicked);

  final VoidCallback onFilePicked;

  final TextEditingController _editController;
  final ValueNotifier<AddressFamily> _mode;
  final _hovering = ValueNotifier(false);


  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: MouseRegion(
    onEnter: (_) => _hovering.value = true,
    onExit: (_) => _hovering.value = false,
      child: ValueListenableBuilder(
        valueListenable: _mode,
        builder: (
          context, mode, _
        ) => TextField(
          maxLines: null,
          controller: _editController,
          style: TextTheme.of(context).bodyLarge,
          cursorHeight: 18,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 6),
            hintText: _mode.value.hint,
            isDense: false,
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12.0),
              child: Select<AddressFamily>(
                selected: _mode,
                alignmentOffset: const Offset(-16, 0),
                initialValue: AddressFamily.file,
                anchorBuilder: (context, selected, icon) => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 3),
                    Icon(selected.icon, size: 18),
                    const SizedBox(width: 3),
                    icon
                  ],
                ),
                optionsBuilder: (context, onTap) => [ for(
                  final mode in AddressFamily.values
                ) MenuItemButton(
                  style: menuIconStyle,
                  child: Icon(mode.icon, size: 18),
                  onPressed: () => onTap(mode),
                ) ],
              )
            ),
            suffixIcon: ValueListenableBuilder(
              valueListenable: _hovering,
              builder: (context, hovering, _) => Opacity(
                opacity: hovering ? 1 : 0.6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(mode == AddressFamily.file) Clickable(
                      Hoverable().build((
                        context, hovering, _
                      ) => buildIcon(Icons.folder, ColorScheme.of(context), hovering, size: 18)),
                      onClick: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if(result != null && result.files.single.path != null) {
                          _editController.text = result.files.single.path!;
                          onFilePicked();
                        }
                      },
                    ),
                    const SizedBox(width: 15),
                    Clickable( // clear keyword
                      onClick: _editController.clear,
                      Hoverable().build((
                        context, hovering, _
                      ) => buildClearIcon(
                        ColorScheme.of(context), hovering, size: 18)
                      ),
                    ),
                    const SizedBox(width: 12),
                  ]
                )
              )
            )
          ),
        )
      )
    )
  );
}

extension on AddressFamily {
  String get hint => _hints[this.index];

  IconData get icon => _icons[this.index];

  static const _hints = [
    "Type in or pick a path", "tcp://...", "command [args ...]"
  ];

  static const _icons = [
    Icons.laptop_windows, Icons.language, Icons.terminal
  ];
}
