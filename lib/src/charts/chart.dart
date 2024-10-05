import 'dart:math';
import 'package:stardart/points.dart';
import '../houses.dart';
import '../../aspects.dart';
import 'objects.dart';

typedef Place = ({String name, Point<double> coords});

enum ChartType {
  radix,
  transits,
  directions,
  solarReturn,
  lunarReturn,
  relocation,
  synastry,
  composite,
  relationship
}

typedef ChartSettings = ({
  HouseSystem houses,
  bool trueNode,
  Orbs orbs,
  int aspectTypes
});

const defaultChartSettings = (
  houses: HouseSystem.placidus,
  trueNode: true,
  orbs: Orbs.dariot,
  aspectTypes: 0x1 // AspectType.major.value
);

abstract class BaseChart {
  /// Chart name
  final String name;

  /// Chart type
  final ChartType type;

  /// Constructor.
  const BaseChart(this.name, this.type);

  @override
  String toString() => name;

  /// Chart objects.
  Map<ChartObjectType, ChartObjectInfo> get objects;

  /// Aspects table
  Map<ChartObjectType, Map<ChartObjectType, AspectInfo>> get aspects;

  /// Aspects to given object type [id].
  Iterable<(ChartObjectType, AspectInfo)> aspectsTo(ChartObjectType id);

  /// Houses
  List<double> get houses;

  /// Settings
  ChartSettings get settings;

  /// Sensitive points
  SensitivePoints get points;
}
