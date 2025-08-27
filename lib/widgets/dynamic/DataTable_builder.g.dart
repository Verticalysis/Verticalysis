// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DataTable_builder.dart';

// **************************************************************************
// Generator: JsonWidgetLibraryBuilder
// **************************************************************************

// ignore_for_file: avoid_init_to_null
// ignore_for_file: deprecated_member_use
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_constructors_in_immutables
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_if_null_operators
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unused_local_variable

class DataTableBuilder extends _DataTableBuilder {
  const DataTableBuilder({required super.args});

  static const kType = 'data_table';

  /// Constant that can be referenced for the builder's type.
  @override
  String get type => kType;

  /// Static function that is capable of decoding the widget from a dynamic JSON
  /// or YAML set of values.
  static DataTableBuilder fromDynamic(
    dynamic map, {
    JsonWidgetRegistry? registry,
  }) => DataTableBuilder(args: map);

  @override
  DataTableBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final model = DataTableBuilderModel.fromDynamic(
      args,
      registry: data.jsonWidgetRegistry,
    );

    return model;
  }

  @override
  _DataTable buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    final model = createModel(childBuilder: childBuilder, data: data);

    return _DataTable(
      checkboxHorizontalMargin: model.checkboxHorizontalMargin,
      columnSpacing: model.columnSpacing,
      columns: model.columns,
      dataRowMaxHeight: model.dataRowMaxHeight,
      dataRowMinHeight: model.dataRowMinHeight,
      dataTextStyle: model.dataTextStyle,
      dividerThickness: model.dividerThickness,
      headingRowHeight: model.headingRowHeight,
      headingTextStyle: model.headingTextStyle,
      horizontalMargin: model.horizontalMargin,
      rows: model.rows,
      showBottomBorder: model.showBottomBorder,
      showCheckboxColumn: model.showCheckboxColumn,
    );
  }
}

class JsonDataTable extends JsonWidgetData {
  JsonDataTable({
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
    this.checkboxHorizontalMargin,
    this.columnSpacing,
    this.columns = const [],
    this.dataRowMaxHeight,
    this.dataRowMinHeight,
    this.dataTextStyle,
    this.dividerThickness,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.rows = const [],
    this.showBottomBorder = false,
    this.showCheckboxColumn = true,
  }) : super(
         jsonWidgetArgs: DataTableBuilderModel.fromDynamic(
           {
             'checkboxHorizontalMargin': checkboxHorizontalMargin,
             'columnSpacing': columnSpacing,
             'columns': columns,
             'dataRowMaxHeight': dataRowMaxHeight,
             'dataRowMinHeight': dataRowMinHeight,
             'dataTextStyle': dataTextStyle,
             'dividerThickness': dividerThickness,
             'headingRowHeight': headingRowHeight,
             'headingTextStyle': headingTextStyle,
             'horizontalMargin': horizontalMargin,
             'rows': rows,
             'showBottomBorder': showBottomBorder,
             'showCheckboxColumn': showCheckboxColumn,

             ...args,
           },
           args: args,
           registry: registry,
         ),
         jsonWidgetBuilder: () => DataTableBuilder(
           args: DataTableBuilderModel.fromDynamic(
             {
               'checkboxHorizontalMargin': checkboxHorizontalMargin,
               'columnSpacing': columnSpacing,
               'columns': columns,
               'dataRowMaxHeight': dataRowMaxHeight,
               'dataRowMinHeight': dataRowMinHeight,
               'dataTextStyle': dataTextStyle,
               'dividerThickness': dividerThickness,
               'headingRowHeight': headingRowHeight,
               'headingTextStyle': headingTextStyle,
               'horizontalMargin': horizontalMargin,
               'rows': rows,
               'showBottomBorder': showBottomBorder,
               'showCheckboxColumn': showCheckboxColumn,

               ...args,
             },
             args: args,
             registry: registry,
           ),
         ),
         jsonWidgetType: DataTableBuilder.kType,
       );

  final double? checkboxHorizontalMargin;

  final double? columnSpacing;

  final List<dynamic> columns;

  final double? dataRowMaxHeight;

  final double? dataRowMinHeight;

  final Map<dynamic, dynamic>? dataTextStyle;

  final double? dividerThickness;

  final double? headingRowHeight;

  final Map<dynamic, dynamic>? headingTextStyle;

  final double? horizontalMargin;

  final List<dynamic> rows;

  final bool showBottomBorder;

  final bool showCheckboxColumn;
}

class DataTableBuilderModel extends JsonWidgetBuilderModel {
  const DataTableBuilderModel(
    super.args, {
    this.checkboxHorizontalMargin,
    this.columnSpacing,
    this.columns = const [],
    this.dataRowMaxHeight,
    this.dataRowMinHeight,
    this.dataTextStyle,
    this.dividerThickness,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.rows = const [],
    this.showBottomBorder = false,
    this.showCheckboxColumn = true,
  });

  final double? checkboxHorizontalMargin;

  final double? columnSpacing;

  final List<dynamic> columns;

  final double? dataRowMaxHeight;

  final double? dataRowMinHeight;

  final Map<dynamic, dynamic>? dataTextStyle;

  final double? dividerThickness;

  final double? headingRowHeight;

  final Map<dynamic, dynamic>? headingTextStyle;

  final double? horizontalMargin;

  final List<dynamic> rows;

  final bool showBottomBorder;

  final bool showCheckboxColumn;

  static DataTableBuilderModel fromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    final result = maybeFromDynamic(map, args: args, registry: registry);

    if (result == null) {
      throw Exception(
        '[DataTableBuilder]: requested to parse from dynamic, but the input is null.',
      );
    }

    return result;
  }

  static DataTableBuilderModel? maybeFromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    DataTableBuilderModel? result;

    if (map != null) {
      if (map is String) {
        map = yaon.parse(map, normalize: true);
      }

      if (map is DataTableBuilderModel) {
        result = map;
      } else {
        registry ??= JsonWidgetRegistry.instance;
        map = registry.processArgs(map, <String>{}).value;
        result = DataTableBuilderModel(
          args,
          checkboxHorizontalMargin: () {
            dynamic parsed = JsonClass.maybeParseDouble(
              map['checkboxHorizontalMargin'],
            );

            return parsed;
          }(),
          columnSpacing: () {
            dynamic parsed = JsonClass.maybeParseDouble(map['columnSpacing']);

            return parsed;
          }(),
          columns: map['columns'] ?? const [],
          dataRowMaxHeight: () {
            dynamic parsed = JsonClass.maybeParseDouble(
              map['dataRowMaxHeight'],
            );

            return parsed;
          }(),
          dataRowMinHeight: () {
            dynamic parsed = JsonClass.maybeParseDouble(
              map['dataRowMinHeight'],
            );

            return parsed;
          }(),
          dataTextStyle: map['dataTextStyle'],
          dividerThickness: () {
            dynamic parsed = JsonClass.maybeParseDouble(
              map['dividerThickness'],
            );

            return parsed;
          }(),
          headingRowHeight: () {
            dynamic parsed = JsonClass.maybeParseDouble(
              map['headingRowHeight'],
            );

            return parsed;
          }(),
          headingTextStyle: map['headingTextStyle'],
          horizontalMargin: () {
            dynamic parsed = JsonClass.maybeParseDouble(
              map['horizontalMargin'],
            );

            return parsed;
          }(),
          rows: map['rows'] ?? const [],
          showBottomBorder: JsonClass.parseBool(
            map['showBottomBorder'],
            whenNull: false,
          ),
          showCheckboxColumn: JsonClass.parseBool(
            map['showCheckboxColumn'],
            whenNull: true,
          ),
        );
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return JsonClass.removeNull({
      'checkboxHorizontalMargin': checkboxHorizontalMargin,
      'columnSpacing': columnSpacing,
      'columns': const [] == columns ? null : columns,
      'dataRowMaxHeight': dataRowMaxHeight,
      'dataRowMinHeight': dataRowMinHeight,
      'dataTextStyle': dataTextStyle,
      'dividerThickness': dividerThickness,
      'headingRowHeight': headingRowHeight,
      'headingTextStyle': headingTextStyle,
      'horizontalMargin': horizontalMargin,
      'rows': const [] == rows ? null : rows,
      'showBottomBorder': false == showBottomBorder ? null : showBottomBorder,
      'showCheckboxColumn': true == showCheckboxColumn
          ? null
          : showCheckboxColumn,

      ...args,
    });
  }
}

class DataTableSchema {
  static const id =
      'https://peiffer-innovations.github.io/flutter_json_schemas/schemas/verticalysis/data_table.json';

  static final schema = <String, Object>{
    r'$schema': 'http://json-schema.org/draft-07/schema#',
    r'$id': id,
    'title': '_DataTable',
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'checkboxHorizontalMargin': SchemaHelper.numberSchema,
      'columnSpacing': SchemaHelper.numberSchema,
      'columns': SchemaHelper.anySchema,
      'dataRowMaxHeight': SchemaHelper.numberSchema,
      'dataRowMinHeight': SchemaHelper.numberSchema,
      'dataTextStyle': SchemaHelper.anySchema,
      'dividerThickness': SchemaHelper.numberSchema,
      'headingRowHeight': SchemaHelper.numberSchema,
      'headingTextStyle': SchemaHelper.anySchema,
      'horizontalMargin': SchemaHelper.numberSchema,
      'rows': SchemaHelper.anySchema,
      'showBottomBorder': SchemaHelper.boolSchema,
      'showCheckboxColumn': SchemaHelper.boolSchema,
    },
    'required': [],
  };
}
