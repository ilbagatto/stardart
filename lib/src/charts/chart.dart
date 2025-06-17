import 'dart:math';
import 'package:astropc/mathutils.dart';
import 'package:astropc/moon.dart' as moon;
import 'package:astropc/planets.dart';
import 'package:astropc/sun.dart' as sun;
import 'package:astropc/timeutils.dart' as timeutils;
import 'package:astropc/timeutils.dart';
import 'package:stardart/aspects.dart';
import 'package:stardart/points.dart';
import 'objects.dart';
import 'package:stardart/src/houses.dart';
import 'package:vector_math/vector_math.dart';

/// Record for a geographic location.
typedef Place = ({String name, Point<double> coords});

/// Settings & rules that affect the chart calculation.
typedef ChartSettings = ({
  HouseSystem houses,
  bool trueNode,
  Orbs orbs,
  int aspectTypes
});

/// Default settings.
const defaultChartSettings = (
  houses: HouseSystem.placidus,
  trueNode: true,
  orbs: Orbs.dariot,
  aspectTypes: 0x1 // AspectType.major.value
);

/// Base class for misc. types of charts.
class BaseChart {
  final double djd;
  final Place place;
  final ChartSettings settings;
  final String name;

  Map<ChartObjectType, ChartObjectInfo>? _objects;
  Map<ChartObjectType, Map<ChartObjectType, AspectInfo>>? _aspects;
  List<double>? _houses;
  SensitivePoints? _points;
  CelestialSphera? _sphera;
  double? _lst;

  BaseChart(
      {required this.name,
      required this.djd,
      required this.place,
      this.settings = defaultChartSettings});

  Map<ChartObjectType, Map<ChartObjectType, AspectInfo>> _calculateAspects() {
    Map<ChartObjectType, Map<ChartObjectType, AspectInfo>> res = {};
    final method = OrbsMethod.getInstance(settings.orbs);
    final keys = objects.keys.toList();
    for (int i = 0; i < keys.length - 1; i++) {
      final src = objects[keys[i]];
      for (int j = i + 1; j < keys.length; j++) {
        final dst = objects[keys[j]];
        final asp = findClosestAspect(
            source: src!,
            target: dst!,
            method: method,
            flags: settings.aspectTypes);
        if (asp != null) {
          res.putIfAbsent(src.type, () => {});
          res[src.type]![dst.type] = asp;
          res.putIfAbsent(dst.type, () => {});
          res[dst.type]![src.type] = asp;
        }
      }
    }
    return res;
  }

  /// Lazily calculated aspects.
  Map<ChartObjectType, Map<ChartObjectType, AspectInfo>> get aspects {
    _aspects ??= _calculateAspects();
    return _aspects!;
  }

  /// Aspects to given chart object.
  Iterable<(ChartObjectType, AspectInfo)> aspectsTo(ChartObjectType id) {
    if (aspects.containsKey(id)) {
      return aspects[id]!.entries.map((e) => (e.key, e.value));
    }
    return Iterable.empty();
  }

  /// Lazily calculated CelestialSphera object.
  CelestialSphera get sphera {
    _sphera ??= CelestialSphera(djd);
    return _sphera!;
  }

  /// Local true Sidereal Time, calculated lazily.
  double get siderealTime {
    _lst ??= timeutils.djdToSidereal(djd, lng: place.coords.x);
    return _lst!;
  }

  List<double> _calculateHouses() {
    final hsys = settings.houses;
    switch (hsys) {
      case HouseSystem.placidus:
      case HouseSystem.koch:
      case HouseSystem.regioMontanus:
      case HouseSystem.campanus:
      case HouseSystem.topocentric:
        return quadrantCusps(
            system: hsys,
            ramc: radians(siderealTime * 15),
            eps: radians(sphera.obliquity),
            theta: radians(place.coords.y));
      case HouseSystem.morinus:
        return morinusCusps(
            ramc: radians(siderealTime * 15), eps: radians(sphera.obliquity));
      case HouseSystem.equalAsc:
        return equalAscCusps(radians(points.asc));
      case HouseSystem.equalMC:
        return equalMCCusps(radians(points.mc));
      default:
        return signCuspCusps();
    }
  }

  /// Lazily calculated houses cusps, [0..11].
  List<double> get houses {
    _houses ??= _calculateHouses();
    return _houses!;
  }

  Iterable<ChartObjectInfo> _nextObject() sync* {
    final currDjd =
        (djd + sphera.deltaT / 86400.0); // Julian day corrected for Delta-T
    final nextDjd = currDjd + 1;
    final nextSphera =
        CelestialSphera(djd + 1); // applies Delta-T correction automatically

    // Moon
    final mo = moon.apparent(currDjd);
    yield (
      type: ChartObjectType.moon,
      position: (lambda: mo.lambda, beta: mo.beta, delta: mo.delta),
      house: inHouse(mo.lambda, houses),
      dailyMotion: mo.motion
    );
    // Sun
    final su = sun.apparent(currDjd,
        dpsi: sphera.nutation.deltaPsi, ignoreLightTravel: false);
    final suNext = sun.apparent(nextDjd,
        dpsi: nextSphera.nutation.deltaPsi, ignoreLightTravel: false);

    yield (
      type: ChartObjectType.sun,
      position: (lambda: su.phi, beta: 0.0, delta: su.rho),
      house: inHouse(su.phi, houses),
      dailyMotion: diffAngle(su.phi, suNext.phi)
    );
    // Planets
    for (final id in PlanetId.values) {
      final pla = Planet.forId(id);
      final pos = pla.geocentricPosition(sphera);
      final nextPos = pla.geocentricPosition(nextSphera);
      yield (
        type: planetToObject[id]!,
        position: (lambda: pos.lambda, beta: pos.beta, delta: pos.delta),
        house: inHouse(pos.lambda, houses),
        dailyMotion: diffAngle(pos.lambda, nextPos.lambda)
      );
    }
    // Lunar Node
    final node = moon.lunarNode(currDjd, trueNode: settings.trueNode);
    final nodeNext = moon.lunarNode(nextDjd, trueNode: settings.trueNode);
    yield (
      type: ChartObjectType.node,
      position: (lambda: node, beta: 0.0, delta: 0.0),
      house: inHouse(node, houses),
      dailyMotion: diffAngle(node, nodeNext)
    );
  }

  Map<ChartObjectType, ChartObjectInfo> _calculateObjects() {
    Map<ChartObjectType, ChartObjectInfo> objs = {};
    for (final obj in _nextObject()) {
      objs[obj.type] = obj;
    }
    return objs;
  }

  /// Lazily calculated chart objects, defined in ChartObjectType enumeration.
  /// Currently, these are  Sun, Moon, the 10 planets and Ascending Lunar Node.
  Map<ChartObjectType, ChartObjectInfo> get objects {
    _objects ??= _calculateObjects();
    return _objects!;
  }

  /// Lazily calculated chart sensitive points:
  ///
  /// * Ascendant
  /// * Midheaven
  /// * Vertex
  /// * East Point
  ///
  SensitivePoints get points {
    if (_points == null) {
      final ramc = radians(siderealTime + 15);
      final eps = radians(sphera.obliquity);
      final theta = radians(place.coords.y);
      _points = (
        asc: degrees(ascendant(ramc, eps, theta)),
        mc: degrees(midheaven(ramc, eps)),
        vtx: degrees(vertex(ramc, eps, theta)),
        ep: degrees(eastpoint(ramc, eps))
      );
    }

    return _points!;
  }
}

/// Birth Chart, Natal Chart, Radix.
class BirthChart extends BaseChart {
  final DateTime birthTime;
  final String firstName;
  final String lastName;
  BirthChart(
      {required this.firstName,
      required this.lastName,
      required this.birthTime,
      required super.place,
      required super.settings})
      : super(
            djd: dateTimeToDjd(birthTime),
            name: 'Birth Chart for $firstName $lastName');
}

/// Generic chart for events.
class EventChart extends BaseChart {
  final DateTime eventTime;
  EventChart(
      {required super.name, required this.eventTime, required super.place})
      : super(djd: dateTimeToDjd(eventTime));
}
