import 'dart:math';
import 'package:astropc/heliocentric.dart';
import 'package:astropc/mathutils.dart';
import 'package:astropc/timeutils.dart';
import 'package:stardart/houses.dart';
import '../common.dart';
import '../../aspects.dart';
import 'positions.dart';
import '../houses.dart';

// enum ChartObjectType { luminary, planet, point }

typedef Place = ({String name, Point coords});

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

typedef ChartObjectInfo = ({
  EclipticPosition position,
  double dailyMotion,
  ChartObjectType type,
  int house
});

/// Base interface for charts
abstract class Chart {
  final String _name;

  const Chart(this._name);

  /// Name
  String get name => _name;

  /// Chart objects including the luminaries, planets and some sensitive points.
  Map<ChartObjectType, ChartObjectInfo> get objects;

  /// Aspects to given object type [id].
  List<AspectInfo> aspectsTo(ChartObjectType id);

  /// List of 12 houses cusps
  List<double> get houses;
  HouseSystem get houseSystem;
  OrbsMethod get orbsMethod;
  int get aspectTypes;
}

/// Birth Chart, Radix, Natal Chart...
class BaseChart extends Chart {
  Map<ChartObjectType, List<AspectInfo>>? _aspects;
  Map<ChartObjectType, ChartObjectInfo>? _objects;
  List<double>? _houses;
  final AspectsDetector _aspectsDetector;
  final HousesBuilder _housesBuilder;
  final CelestialPositionsBuilder _positionsBuilder;
  final double _djd;
  final Point<double> _geoCoords;

  BaseChart(super._name, this._djd, this._geoCoords, this._positionsBuilder,
      this._housesBuilder, this._aspectsDetector);

  factory BaseChart.forDJDAndPlace(
      {String? name,
      required double djd,
      required Point<double> geoCoords,
      ChartSettings settings = defaultChartSettings}) {
    name ??= 'Chart for $djd';

    HousesBuilder housesBuilder =
        HousesBuilder.getBuilder(settings.houses, djd, geoCoords);
    final orbsMethod = OrbsMethod.getInstance(settings.orbs);
    return BaseChart(
        name,
        djd,
        geoCoords,
        CelestialPositionsBuilder(djd),
        housesBuilder,
        AspectsDetector(
            orbsMethod: orbsMethod, typeFlags: settings.aspectTypes));
  }

  factory BaseChart.forNow(
      {String? name,
      required Point<double> geoCoords,
      ChartSettings settings = defaultChartSettings}) {
    final now = DateTime.now().toUtc();
    final dh =
        now.day.toDouble() + ddd(now.hour, now.minute, now.second.toDouble());
    final djd = julDay(now.year, now.month, dh);
    return BaseChart.forDJDAndPlace(
        name: name, djd: djd, geoCoords: geoCoords, settings: settings);
  }

  @override
  List<AspectInfo> aspectsTo(ChartObjectType id) {
    final obj = objects[id]!;
    _aspects ??= <ChartObjectType, List<AspectInfo>>{};
    if (_aspects!.containsKey(obj.type)) {
      return _aspects![obj.type]!;
    }

    final source = (name: obj.type.name, longitude: obj.position.lambda);
    final others = objects.keys
        .map((k) => objects[k]!)
        .map((o) => (name: o.type.name, longitude: o.position.lambda))
        .where((o) => o.name != source.name)
        .toList();
    final res = _aspectsDetector.iterAspects(source, others).toList();
    _aspects![id] = res;
    return res;
  }

  @override
  List<double> get houses {
    _houses ??= _housesBuilder.calculateCusps();
    return _houses!;
  }

  @override
  Map<ChartObjectType, ChartObjectInfo> get objects {
    _objects ??= {
      for (var id in ChartObjectType.values)
        id: _positionsBuilder.calculatePosition(id, houses)
    };
    return _objects!;
  }

  // AspectsDetector get aspectsDetector => _aspectsDetector;
  // HousesBuilder get housesBuilder => _housesBuilder;
  // CelestialPositionsBuilder get positionsBuilder => _positionsBuilder;

  @override
  HouseSystem get houseSystem => _housesBuilder.system;

  @override
  OrbsMethod get orbsMethod => _aspectsDetector.orbsMethod;
  double get djd => _djd;
  Point<double> get geoCoords => _geoCoords;

  @override
  int get aspectTypes => _aspectsDetector.typeFlags;
}
