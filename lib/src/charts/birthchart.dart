import 'package:astropc/mathutils.dart';
import 'package:astropc/moon.dart' as moon;
import 'package:astropc/planets.dart';
import 'package:astropc/sun.dart' as sun;
import 'package:astropc/timeutils.dart' as timeutils;
import 'package:stardart/aspects.dart';
import 'package:stardart/points.dart';
import 'package:stardart/src/charts/chart.dart';
import 'package:stardart/src/charts/objects.dart';
import 'package:stardart/src/houses.dart';
import 'package:vector_math/vector_math.dart';

class BirthChart extends BaseChart {
  final double djd;
  final Place place;
  @override
  final ChartSettings settings;

  Map<ChartObjectType, ChartObjectInfo>? _objects;
  Map<ChartObjectType, Map<ChartObjectType, AspectInfo>>? _aspects;
  List<double>? _houses;
  SensitivePoints? _points;
  CelestialSphera? _sphera;
  double? _lst;

  BirthChart(
      {required name,
      required this.djd,
      required this.place,
      this.settings = defaultChartSettings})
      : super(name, ChartType.radix);

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

  @override
  Map<ChartObjectType, Map<ChartObjectType, AspectInfo>> get aspects {
    _aspects ??= _calculateAspects();
    return _aspects!;
  }

  @override
  Iterable<(ChartObjectType, AspectInfo)> aspectsTo(ChartObjectType id) {
    final aspectedObjects = aspects[id];
    if (aspectedObjects == null) {
      return [];
    }
    return ChartObjectType.values.map((id) => (id, aspectedObjects[id]!));
  }

  CelestialSphera get sphera {
    _sphera ??= CelestialSphera(djd);
    return _sphera!;
  }

  /// Local true Sidereal Time
  double get siderealTime {
    _lst = timeutils.djdToSidereal(djd, lng: place.coords.x);
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

  @override
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

  @override
  Map<ChartObjectType, ChartObjectInfo> get objects {
    _objects ??= _calculateObjects();
    return _objects!;
  }

  @override
  SensitivePoints get points {
    final ramc = radians(siderealTime + 15);
    final eps = radians(sphera.obliquity);
    final theta = radians(place.coords.y);
    _points ??= (
      asc: degrees(ascendant(ramc, eps, theta)),
      mc: degrees(midheaven(ramc, eps)),
      vtx: degrees(vertex(ramc, eps, theta)),
      ep: degrees(eastpoint(ramc, eps))
    );
    return _points!;
  }
}
