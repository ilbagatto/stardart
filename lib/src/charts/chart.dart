import 'dart:math';
import 'package:astropc/mathutils.dart';
import 'package:stardart/points.dart';
import 'package:vector_math/vector_math.dart';

import 'package:astropc/timeutils.dart' as timeutils;
import 'package:astropc/planets.dart';
import 'package:astropc/sphera.dart' as sphera;
import '../houses.dart';
import '../common.dart';
import '../../aspects.dart';
import 'positions.dart';

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

abstract class ChartVisitor {
  void visit(BaseChart baseChart);
}

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

  void accept(ChartVisitor visitor);
}

/// Birth Chart, Radix, Natal Chart...
class BaseChart extends Chart {
  Map<ChartObjectType, List<AspectInfo>>? _aspects;
  Map<ChartObjectType, ChartObjectInfo>? _objects;
  List<double>? _houses;
  late AspectsDetector _aspectsDetector;
  late CelestialPositionsBuilder _positionsBuilder;
  final ChartSettings settings;
  SensitivePoints? _points;

  /// Julian date since epoch 1900.0
  final double djd;

  /// Geographical coordinates
  final Point<double> geoCoords;
  late double _t;
  late double _deltaT;
  late sphera.NutationRecord _nutation;
  late double _eps;
  late double _lst;

  BaseChart(super._name,
      {required this.djd,
      required this.geoCoords,
      this.settings = defaultChartSettings}) {
    _deltaT = timeutils.deltaT(djd);
    _t = djd / timeutils.daysPerCent;
    _nutation = sphera.nutation(_t);
    _eps = sphera.obliquity(djd, deps: _nutation.deltaEps);
    _lst = timeutils.djdToSidereal(djd, lng: geoCoords.x);

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

  List<double> _calculateCusps() {
    final sys = settings.houses;
    switch (sys) {
      case HouseSystem.placidus:
      case HouseSystem.koch:
      case HouseSystem.regioMontanus:
      case HouseSystem.campanus:
      case HouseSystem.topocentric:
        return quadrantCusps(
            system: sys,
            ramc: radians(lst * 15),
            eps: radians(eps),
            theta: radians(geoCoords.y));
      case HouseSystem.morinus:
        return morinusCusps(ramc: radians(lst * 15), eps: radians(eps));
      case HouseSystem.equalAsc:
        return equalAscCusps(radians(points.asc));
      case HouseSystem.equalMC:
        return equalMCCusps(radians(points.mc));
      default:
        return signCuspCusps();
    }
  }

  @override
  List<double> get houses {
    _houses ??= _calculateCusps();
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
  HouseSystem get houseSystem => settings.houses;

  @override
  OrbsMethod get orbsMethod => _aspectsDetector.orbsMethod;

  /// Nutation in obliquity and longitude
  sphera.NutationRecord get nutation => _nutation;

  /// Obliquity of the Ecliptic, arc-degrees
  double get eps => _eps;

  /// Local true sidereal time
  double get lst => _lst;

  /// Approximate Delta-T in seconds
  double get deltaT => _deltaT;

  /// Binary combination of aspect types flags
  @override
  int get aspectTypes => _aspectsDetector.typeFlags;

  SensitivePoints _calculatePoints() {
    final ramc = radians(lst * 15);
    final reps = radians(eps);
    final theta = radians(geoCoords.y);
    return (
      asc: degrees(ascendant(ramc, reps, theta)),
      mc: degrees(midheaven(ramc, reps)),
      vtx: degrees(vertex(ramc, reps, theta)),
      ep: eastpoint(ramc, reps)
    );
  }

  /// sensitive points
  SensitivePoints get points {
    _points ??= _calculatePoints();
    return _points!;
  }

  @override
  void accept(ChartVisitor visitor) {
    visitor.visit(this);
  }
}
