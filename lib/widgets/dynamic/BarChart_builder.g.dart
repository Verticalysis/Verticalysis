// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BarChart_builder.dart';

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

class BarChartBuilder extends _BarChartBuilder {
  const BarChartBuilder({required super.args});

  static const kType = 'bar_chart';

  /// Constant that can be referenced for the builder's type.
  @override
  String get type => kType;

  /// Static function that is capable of decoding the widget from a dynamic JSON
  /// or YAML set of values.
  static BarChartBuilder fromDynamic(
    dynamic map, {
    JsonWidgetRegistry? registry,
  }) => BarChartBuilder(args: map);

  @override
  BarChartBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final model = BarChartBuilderModel.fromDynamic(
      args,
      registry: data.jsonWidgetRegistry,
    );

    return model;
  }

  @override
  _BarChart buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    final model = createModel(childBuilder: childBuilder, data: data);

    return _BarChart(
      animate: model.animate,
      color: model.color,
      data: model.data,
    );
  }
}

class JsonBarChart extends JsonWidgetData {
  JsonBarChart({
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
    this.animate = false,
    this.color = 0xFF00DCD6,
    this.data = const {},
  }) : super(
         jsonWidgetArgs: BarChartBuilderModel.fromDynamic(
           {'animate': animate, 'color': color, 'data': data, ...args},
           args: args,
           registry: registry,
         ),
         jsonWidgetBuilder: () => BarChartBuilder(
           args: BarChartBuilderModel.fromDynamic(
             {'animate': animate, 'color': color, 'data': data, ...args},
             args: args,
             registry: registry,
           ),
         ),
         jsonWidgetType: BarChartBuilder.kType,
       );

  final bool animate;

  final int color;

  final Map<dynamic, dynamic> data;
}

class BarChartBuilderModel extends JsonWidgetBuilderModel {
  const BarChartBuilderModel(
    super.args, {
    this.animate = false,
    this.color = 0xFF00DCD6,
    this.data = const {},
  });

  final bool animate;

  final int color;

  final Map<dynamic, dynamic> data;

  static BarChartBuilderModel fromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    final result = maybeFromDynamic(map, args: args, registry: registry);

    if (result == null) {
      throw Exception(
        '[BarChartBuilder]: requested to parse from dynamic, but the input is null.',
      );
    }

    return result;
  }

  static BarChartBuilderModel? maybeFromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    BarChartBuilderModel? result;

    if (map != null) {
      if (map is String) {
        map = yaon.parse(map, normalize: true);
      }

      if (map is BarChartBuilderModel) {
        result = map;
      } else {
        registry ??= JsonWidgetRegistry.instance;
        map = registry.processArgs(map, <String>{}).value;
        result = BarChartBuilderModel(
          args,
          animate: JsonClass.parseBool(map['animate'], whenNull: false),
          color: () {
            dynamic parsed = JsonClass.maybeParseInt(map['color']);

            parsed ??= 0xFF00DCD6;

            return parsed;
          }(),
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
      'color': 0xFF00DCD6 == color ? null : color,
      'data': const {} == data ? null : data,

      ...args,
    });
  }
}

class BarChartSchema {
  static const id =
      'https://peiffer-innovations.github.io/flutter_json_schemas/schemas/verticalysis/bar_chart.json';

  static final schema = <String, Object>{
    r'$schema': 'http://json-schema.org/draft-07/schema#',
    r'$id': id,
    'title': '_BarChart',
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'animate': SchemaHelper.boolSchema,
      'color': SchemaHelper.numberSchema,
      'data': SchemaHelper.anySchema,
    },
    'required': [],
  };
}
