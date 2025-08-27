// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PieChart_builder.dart';

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

class PieChartBuilder extends _PieChartBuilder {
  const PieChartBuilder({required super.args});

  static const kType = 'pie_chart';

  /// Constant that can be referenced for the builder's type.
  @override
  String get type => kType;

  /// Static function that is capable of decoding the widget from a dynamic JSON
  /// or YAML set of values.
  static PieChartBuilder fromDynamic(
    dynamic map, {
    JsonWidgetRegistry? registry,
  }) => PieChartBuilder(args: map);

  @override
  PieChartBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final model = PieChartBuilderModel.fromDynamic(
      args,
      registry: data.jsonWidgetRegistry,
    );

    return model;
  }

  @override
  _PieChart buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    final model = createModel(childBuilder: childBuilder, data: data);

    return _PieChart(
      animate: model.animate,
      colorPalette: model.colorPalette,
      data: model.data,
    );
  }
}

class JsonPieChart extends JsonWidgetData {
  JsonPieChart({
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
    this.animate = false,
    this.colorPalette = const [0xFF00DCD6, 0xFF009A9A, 0xFF0037DC, 0xFF009A00],
    this.data = const {},
  }) : super(
         jsonWidgetArgs: PieChartBuilderModel.fromDynamic(
           {
             'animate': animate,
             'colorPalette': colorPalette,
             'data': data,

             ...args,
           },
           args: args,
           registry: registry,
         ),
         jsonWidgetBuilder: () => PieChartBuilder(
           args: PieChartBuilderModel.fromDynamic(
             {
               'animate': animate,
               'colorPalette': colorPalette,
               'data': data,

               ...args,
             },
             args: args,
             registry: registry,
           ),
         ),
         jsonWidgetType: PieChartBuilder.kType,
       );

  final bool animate;

  final List<dynamic> colorPalette;

  final Map<dynamic, dynamic> data;
}

class PieChartBuilderModel extends JsonWidgetBuilderModel {
  const PieChartBuilderModel(
    super.args, {
    this.animate = false,
    this.colorPalette = const [0xFF00DCD6, 0xFF009A9A, 0xFF0037DC, 0xFF009A00],
    this.data = const {},
  });

  final bool animate;

  final List<dynamic> colorPalette;

  final Map<dynamic, dynamic> data;

  static PieChartBuilderModel fromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    final result = maybeFromDynamic(map, args: args, registry: registry);

    if (result == null) {
      throw Exception(
        '[PieChartBuilder]: requested to parse from dynamic, but the input is null.',
      );
    }

    return result;
  }

  static PieChartBuilderModel? maybeFromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    PieChartBuilderModel? result;

    if (map != null) {
      if (map is String) {
        map = yaon.parse(map, normalize: true);
      }

      if (map is PieChartBuilderModel) {
        result = map;
      } else {
        registry ??= JsonWidgetRegistry.instance;
        map = registry.processArgs(map, <String>{}).value;
        result = PieChartBuilderModel(
          args,
          animate: JsonClass.parseBool(map['animate'], whenNull: false),
          colorPalette:
              map['colorPalette'] ??
              const [0xFF00DCD6, 0xFF009A9A, 0xFF0037DC, 0xFF009A00],
          data: map['data'] ?? const {},
        );
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return JsonClass.removeNull({
      'animate': false == animate ? null : animate,
      'colorPalette':
          const [0xFF00DCD6, 0xFF009A9A, 0xFF0037DC, 0xFF009A00] == colorPalette
          ? null
          : colorPalette,
      'data': const {} == data ? null : data,

      ...args,
    });
  }
}

class PieChartSchema {
  static const id =
      'https://peiffer-innovations.github.io/flutter_json_schemas/schemas/verticalysis/pie_chart.json';

  static final schema = <String, Object>{
    r'$schema': 'http://json-schema.org/draft-07/schema#',
    r'$id': id,
    'title': '_PieChart',
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'animate': SchemaHelper.boolSchema,
      'colorPalette': SchemaHelper.anySchema,
      'data': SchemaHelper.anySchema,
    },
    'required': [],
  };
}
