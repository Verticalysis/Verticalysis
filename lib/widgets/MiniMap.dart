// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math' show min;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../domain/amorphous/Projection.dart';
import '../models/ProjectionsModel.dart';
import '../models/ScrollModel.dart';
import '../models/SelectionsModel.dart';
import 'helper/Events.dart';
import 'helper/MonitorModeController.dart';
import 'shared/Hoverable.dart';

enum Mode {
  scalemark(Icons.view_array, Scaling.linear, scalemarkVisualBuilder),
  histogram(Icons.equalizer,  Scaling.chrono, histogramVisualBuilder);
//waterfall(Icons.clear_all) TODO: implement waterfall mode

  const Mode(
    this.icon, this.scaling, this.visualBuilder
  );

  final IconData icon;

  final Scaling scaling;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    ProjectionsModel projections,
    SelectionsModel selections
  ) visualBuilder;

  static Widget scalemarkVisualBuilder(
    BuildContext context,
    BoxConstraints bc,
    ProjectionsModel projections,
    SelectionsModel selections
  ) => ListenableBuilder(
    listenable: selections,
    builder: (_, _) => CustomPaint(
      size: Size(bc.maxWidth, bc.maxHeight),
      painter: ScrollbarMarksPainter(
        itemCount: projections.currentLength,
        minSpace: 120,
        markColor: ColorScheme.of(context).surface,
        textStyle: TextTheme.of(context).labelSmall!
      ),
      foregroundPainter: SelectionsPainter(
        selections,
        projections,
        ColorScheme.of(context).secondary
      ),
      //child: Listener(onPointerMove: )
    )
  );


  static Widget histogramVisualBuilder(
    BuildContext context,
    BoxConstraints bc,
    ProjectionsModel projections,
    SelectionsModel selections
  ) => SizedBox(height: 180, width: bc.minWidth);/*CustomPaint(
    painter: ,
    child: Listener(onPointerMove: )
  );*/
}

// Interaction between Minimap and Verticatrix:
//
// Verticatrix srcoll => Minimap slider update
// 1. VerticatrixController notifies ScrollModel offset changed by onScroll
// 2. ScrollModel.setUpperEdge calculates and updates normalized offset
// 3. silder is updated as a listener of ScrollModel
//
// Minimap slider drag => Verticatrix srcoll => Minimap slider update
// 1. Minimap notifies VerticatrixController slider moved by onDrag
// 2.
final class MiniMap extends StatelessWidget {
  final _mode = ValueNotifier(Mode.scalemark);
  final ValueNotifier<int> _entries;

  final void Function(double normalizedDelta) onDrag;

  final ProjectionsModel _projections;
  final ScrollModel _scroll;
  final SelectionsModel _selections;

  final double height;

  static const _minSliderWidth = 15.0;

  MiniMap(
    MonitorModeController mmc, this.onDrag, this.height
  ) : _projections = mmc.projectionsModel,
      _selections = mmc.selectionsModel,
      _scroll = mmc.scrollModel,
      _entries = ValueNotifier(mmc.projectionsModel.currentLength) {
    mmc.dispatcher.listen(
      Event.entriesUpdate, (entries) => _entries.value = entries
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: height,
      width: constraints.maxWidth,
      child: ValueListenableBuilder(
        valueListenable: _mode,
        builder: (context, mode, _) => Stack(children: [
          ValueListenableBuilder(
            valueListenable: _entries,
            builder: (
              context, entries, _
            ) => entries > 0 ? mode.visualBuilder(
              context, constraints, _projections, _selections
            ) : const SizedBox.shrink()
          ),
          ListenableBuilder( // slider
            listenable: _scroll,
            builder: (context, _) => Positioned(
              top: 0,
              left: constraints.maxWidth * _scroll.offset,
              width: _fadeSlider(constraints) ?
                _minSliderWidth + 30 :
                constraints.maxWidth * _scroll.window,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) => onDrag(
                  details.delta.dx / constraints.maxWidth
                ),
                child: HoverEffect(
                  inactiveCosmetic: _paintSlider(
                    ColorScheme.of(context).primary.withAlpha(96),
                    _fadeSlider(constraints)
                  ),
                  hoveringCosmetic: _paintSlider(
                    ColorScheme.of(context).primary.withAlpha(96),
                    _fadeSlider(constraints),
                    Border.all(color: ColorScheme.of(context).primary)
                  )
                )
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _mode,
            builder: (context, mode, _) => Positioned(
              bottom: 15,
              right: 15,
              child: CupertinoSlidingSegmentedControl<Mode>(
                padding: const EdgeInsets.all(1.2),
                groupValue: mode,
                onValueChanged: (mode) {
                  if(mode != Mode.scalemark) {
                    if(!_projections.chronologicallySorted) {
                      _mode.value = Mode.scalemark;
                    } else _mode.value = mode!;
                  } else _mode.value = Mode.scalemark;
                },
                children: Map.fromIterable(
                  Mode.values,
                  value: (mode) => Icon(
                    mode.icon,
                    color: ColorScheme.of(context).onSurfaceVariant,
                    size: 15,
                  )
                )
              )
            )
          )
        ])
      )
    )
  );

  bool _fadeSlider(
    BoxConstraints constraints
  ) => _minSliderWidth > constraints.maxWidth * _scroll.window;

  BoxDecoration _paintSlider(
    Color color, bool fade, [ Border? border ]
  ) => BoxDecoration(
    border: border,
    color: fade ? null : color,
    gradient: fade ? LinearGradient(
      colors: [ color, Color(0x00FFFFFF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ) : null
  );
}

typedef ScaleMark = (int, double);

final class ScrollbarMarksPainter extends CustomPainter {
  final int itemCount;        // Total number of items (N)
  final double minSpace;      // Minimum space between marks
  final Color markColor;      // Color of the scale marks
  final double markThickness; // Thickness of the scale marks
  final TextStyle textStyle;  // Style for the index numbers

  ScrollbarMarksPainter({
    required this.itemCount,
    required this.minSpace,
    required this.markColor,
    required this.textStyle,
    this.markThickness = 2,
  });

  Iterable<ScaleMark> _layoutMarks(int N, double S, double minSpace) sync* {
    if(N == 0) return;

    final maxM = ((S - minSpace) / minSpace).floor();
    final M = min(N, maxM < 0 ? 0 : maxM);
    if(M == 0)  return;

    for (int m = 1; m <= M; m++) {
      final int index = ((m * N) / (M + 1)).floor();
      final double position = m * S / (M + 1);
      yield (index, position);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final markPaint = Paint()
      ..color = markColor
      ..strokeWidth = markThickness
      ..style = PaintingStyle.stroke;

    final marks = _layoutMarks(itemCount, size.width, minSpace);

    for(final (index, position) in marks) {
      canvas.drawLine(
        Offset(position, 0),
        Offset(position, size.height),
        markPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: index.toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final textX = position - textPainter.width - 4; // padding
      textPainter.paint(canvas, Offset(textX, 4));
    }
  }

  @override
  bool shouldRepaint(covariant ScrollbarMarksPainter oldDelegate) {
    return itemCount != oldDelegate.itemCount;/*marks != oldDelegate.marks ||
        markColor != oldDelegate.markColor ||
        markLength != oldDelegate.markLength ||
        markThickness != oldDelegate.markThickness ||
        textStyle != oldDelegate.textStyle;*/
  }
}

final class SelectionsPainter extends CustomPainter {
  SelectionsPainter(
    SelectionsModel selections, ProjectionsModel projections, this._fill
  ): _selections = selections,
    _projection = projections.current,
    _selectionsHash = selections.hashCode;

  final SelectionsModel _selections;
  final Projection _projection;
  final Color _fill;

  final int _selectionsHash;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = _fill.withAlpha(127)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final length = _projection.length;
    final width = size.width.floor();

    final endpoints = Float32List(4);

    int partIndex = 0; // Current part
    int error = 0;

    for(int pixel = 0; pixel < width; pixel++) {
      if(_selections.isSelected(_projection.indexAt(partIndex))) {
        final (x, y) = (pixel.toDouble(), size.height);
        endpoints[0] = x;
        endpoints[1] = .0;
        endpoints[2] = x;
        endpoints[3] = y;
        canvas.drawRawPoints(PointMode.lines, endpoints, fill);
      }

      error += length;
      // If error >= m, we've crossed into the next part
      while (error >= width && partIndex < length - 1) {
        partIndex++;
        error -= width; // Adjust error for the next part
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant SelectionsPainter oldDelegate
  ) => _selectionsHash != oldDelegate._selectionsHash;
}
