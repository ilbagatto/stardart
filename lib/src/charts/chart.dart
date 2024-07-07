import 'dart:math';
import 'package:astropc/heliocentric.dart';
import 'package:astropc/mathutils.dart';
import 'package:astropc/misc.dart' as misc;
import 'package:astropc/timeutils.dart' as timeutils;
import 'package:stardart/houses.dart';
import 'package:vector_math/vector_math.dart';
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
  late AspectsDetector _aspectsDetector;
  late HousesBuilder _housesBuilder;
  late CelestialPositionsBuilder _positionsBuilder;
  final ChartSettings settings;

  /// Julian date since epoch 1900.0
  final double djd;

  /// Geographical coordinates
  final Point<double> geoCoords;
  late double _t;
  late double _deltaT;
  late misc.NutationRecord _nutation;
  late double _eps;
  late double _lst;

  BaseChart(super._name,
      {required this.djd,
      required this.geoCoords,
      this.settings = defaultChartSettings}) {
    _deltaT = timeutils.deltaT(djd);
    _t = djd / timeutils.daysPerCent;
    _nutation = misc.nutation(_t);
    _eps = misc.obliquity(djd, deps: _nutation.deltaEps);
    _lst = timeutils.djdToSidereal(djd, lng: geoCoords.x);

    _housesBuilder = HousesBuilder.getBuilder(settings.houses,
        eps: radians(eps),
        ramc: radians(lst * 15),
        theta: radians(geoCoords.y));
    _aspectsDetector = AspectsDetector(
        orbsMethod: OrbsMethod.getInstance(settings.orbs),
        typeFlags: settings.aspectTypes);
    _positionsBuilder = CelestialPositionsBuilder(djd + _deltaT / 86400.0);
  }

  factory BaseChart.forDateTime(
      {String name = 'New Chart',
      required DateTime dt,
      required Point<double> geoCoords,
      ChartSettings settings = defaultChartSettings}) {
    final ut = dt.toUtc();
    final dh = ut.day.toDouble() +
        ddd(ut.hour, ut.minute, ut.second.toDouble()) / 24.0;
    final djd = timeutils.julDay(ut.year, ut.month, dh);
    return BaseChart(name, djd: djd, geoCoords: geoCoords, settings: settings);
  }

  factory BaseChart.forNow(
      {String name = 'New Chart',
      required Point<double> geoCoords,
      ChartSettings settings = defaultChartSettings}) {
    final now = DateTime.now();
    return BaseChart.forDateTime(
        name: name, dt: now, geoCoords: geoCoords, settings: settings);
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

  /// Nutation in obliquity and longitude
  misc.NutationRecord get nutation => _nutation;

  /// Obliquity of the Ecliptic, arc-degrees
  double get eps => _eps;

  /// Local true sidereal time
  double get lst => _lst;

  /// Approximate Delta-T in seconds
  double get deltaT => _deltaT;

  /// Binary combination of aspect types flags
  @override
  int get aspectTypes => _aspectsDetector.typeFlags;
}
