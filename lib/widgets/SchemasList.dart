// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../domain/schema/Schema.dart';
import '../models/SchemasModel.dart';
import 'shared/Hoverable.dart';
import 'helper/LoadWithSchema.dart';

/// A ListView for selecting schemas and addingn new ones
final class SchemasList extends StatelessWidget {
  final SchemasModel schemasModel;
  final void Function(Schema schema, String schemaName) onSelect;
  // final void Function(String schema, String reason) loadSchemaFailureHandler;
  // final void Function(String reason, Exception raw) addSchemaFailureHandler;
  final double itemHeight;
  final int visibleItemCount;

  SchemasList(this.schemasModel, {
    required this.onSelect,
    // required this.addSchemaFailureHandler,
    // required this.loadSchemaFailureHandler,
    this.visibleItemCount = 6,
    this.itemHeight = 30.0,
    super.key
  });

  Widget build(BuildContext context) => ListenableBuilder(
    listenable: schemasModel,
    builder: (context, widget) => Container(
      height: visibleItemCount * itemHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surfaceContainer,
        border: Border.all(width: 1, color: ColorScheme.of(context).onSurface),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: schemasModel.length + 1,
        itemBuilder: (context, index) => (
          index == schemasModel.length
        ) ? GestureDetector(
          onTap: () async {
            final res = await FilePicker.platform.pickFiles();
            if(res != null) schemasModel.addSchemaNoThrow(res.path);
          },
          child: HoverEffect(
            height: itemHeight,
            align: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              'Add New Schema', style: TextTheme.of(context).bodyLarge!
            ),
            inactiveCosmetic: BoxDecoration(
              color: schemasModel.length & 1 == 0 ?
                ColorScheme.of(context).surfaceContainer :
                ColorScheme.of(context).surfaceContainerHigh
            ),
            hoveringCosmetic: BoxDecoration(
              color: ColorScheme.of(context).primary.withAlpha(30)
            ),
          ),
        ) : GestureDetector(
          onTap: () => schemasModel.getSchemaNoThrow(
            schemasModel.enumSchema(index), onSelect
          ),
          child: HoverEffect(
            height: itemHeight,
            align: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              schemasModel.enumSchema(index),
              style: TextTheme.of(context).bodyLarge!
            ),
            inactiveCosmetic: BoxDecoration(color: index & 1 == 0 ?
              ColorScheme.of(context).surfaceContainer :
              ColorScheme.of(context).surfaceContainerHigh),
            hoveringCosmetic: BoxDecoration(
              color: ColorScheme.of(context).primary.withAlpha(60)
            ),
          ),
        )
      )
    )
  );
}
