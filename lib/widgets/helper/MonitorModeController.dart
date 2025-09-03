import 'package:flutter/widgets.dart';

import '../../domain/amorphous/EventManifold.dart';
import '../../domain/amorphous/Projection.dart';
import '../../domain/byteStream/ByteStream.dart';
import '../../domain/schema/AttrType.dart';
import '../../domain/schema/Schema.dart';
import '../../models/FiltersModel.dart';
import '../../models/PipelineModel.dart';
import '../../models/ProjectionsModel.dart';
import '../../models/ScrollModel.dart';
import '../../models/SelectionsModel.dart';
import '../helper/Events.dart';
import '../Verticatrix.dart';

enum Toolset {
  none(""),
  analyze("Analyze"),
  collect("Collect"),
  plotter("Visualize");

  const Toolset(this.label);
  final String label;
}

final class MonitorModeController {
  final EventDispatcher dispatcher;
  final scrollModel = ScrollModel();
  final selectionsModel = SelectionsModel();
  final vcxController = VerticatrixController();
  final PipelineModel pipelineModel;
  final ProjectionsModel projectionsModel;
  final Channel<Notifer1<int>> _entriesUpdateChannel;

  MonitorModeController(
    ByteStream stream,
    Schema schema,
    EventManifold evtManifold,
    this.dispatcher,
  ) : _entriesUpdateChannel = dispatcher.getChannel(Event.entriesUpdate),
      pipelineModel = PipelineModel(evtManifold)..connect(schema, stream),
      projectionsModel = ProjectionsModel(
      evtManifold, schema.chronologicallySortedBy
    ) {
    projectionsModel.onSizeChange = onEntriesUpdate;
    projectionsModel.preNotify = () => vcxController.syncColumns((name) {
      return projectionsModel.getColumn(name, pipelineModel.getAttrTypeByName);
    }, projectionsModel.currentLength);
    vcxController.onScroll = updateScrollModel;
    evtManifold.onNewColumns = (columns) {
      for(final column in columns) vcxController.addColumn(
        column, projectionsModel.getColumn(
          column, pipelineModel.getAttrTypeByName
        )
      );
    };
    dispatcher.listen(
      Event.projectionAppend,
      (Filter filter) {
        vcxController.regionState.regionReset();
        projectionsModel.append(filter);
        _entriesUpdateChannel.notify(projectionsModel.currentLength);
        updateScrollModel();
      }
    );
    dispatcher.listen(
      Event.projectionRemove,
      (Iterable<Filter> filter) {
        vcxController.regionState.regionReset();
        projectionsModel.splice(filter);
        _entriesUpdateChannel.notify(projectionsModel.currentLength);
        updateScrollModel();
      }
    );
    dispatcher.listen(
      Event.projectionClear,
      () {
        vcxController.regionState.regionReset();
        projectionsModel.clear();
        _entriesUpdateChannel.notify(projectionsModel.currentLength);
        updateScrollModel();
      }
    );
    dispatcher.listen(
      Event.requestTeleport,
      (String? column, int? entry) {
        if(column != null) vcxController.scroll2column(column);
        if(entry != null) vcxController.scroll2index(entry.toDouble());
      }
    );
  }

  Projection get currentProjection => projectionsModel.current;

  List<Comparable?> getTypedColumn(String name) => projectionsModel.getColumn(
    name, pipelineModel.getAttrTypeByName
  ).typedView;

  void listen<T extends Function>(
    Topic<T> topic, T listener
  ) => dispatcher.listen<T>(topic, listener);

  Channel<T> getChannel<T extends Function>(
    Topic<T> topic
  ) => dispatcher.getChannel(topic);

  void attachChannels(List<Channel> channels) {
    for(final channel in channels) dispatcher.attachChannel(channel);
  }

  void initChannels() => dispatcher.syncChannels();

  void onEntriesUpdate(
    int entries
  ) => WidgetsBinding.instance.addPostFrameCallback((_) {
    vcxController.entries = entries;
    _entriesUpdateChannel.notify(entries);
    updateScrollModel();
  });

  void updateScrollModel() => scrollModel.setBothEdges(
    vcxController.normalizedOffset,
    vcxController.normalizedLowerEdge(),
    projectionsModel.scrollReference
  );

  void onMiniMapSliderDrag(double normalizedDelta) {
    vcxController.scroll2index(
      scrollModel.updateByDelta(
        normalizedDelta,
        vcxController.normalizedHeight,
        projectionsModel.scrollReference,
      )
    );
  }

  void dispose() {
    pipelineModel.discard();
    vcxController.dispose();
  }

  AttrType? getAttrTypeByName(String name) {
    if(!vcxController.visibleColumns.contains(name)) return null;
    return pipelineModel.getAttrTypeByName(name);
  }
}
