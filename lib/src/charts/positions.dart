import 'package:astropc/mathutils.dart';
import 'package:astropc/planets.dart';
import 'package:astropc/sun.dart' as sun;
import 'package:astropc/moon.dart' as moon;
import 'package:stardart/src/charts/objects.dart';
import '../houses.dart';

class CelestialPositionsBuilder {
  final double _djd;
  final bool _trueNode;
  late CelestialSphera _sphera;
  late CelestialSphera _spheraTomorrow;

  CelestialPositionsBuilder(this._djd, [this._trueNode = true]) {
    _sphera = CelestialSphera(_djd);
    _spheraTomorrow = CelestialSphera(_djd + 1);
  }

  double get djd => _djd;

  ChartObjectInfo calculateSun(List<double> cusps) {
    final sunToday = sun.apparent(_djd,
        dpsi: _sphera.nutation.deltaPsi, ignoreLightTravel: false);
    final sunTomorrow = sun.apparent(_djd + 1,
        dpsi: _spheraTomorrow.nutation.deltaPsi, ignoreLightTravel: false);

    return (
      type: ChartObjectType.sun,
      dailyMotion: diffAngle(sunToday.phi, sunTomorrow.phi),
      house: inHouse(sunToday.phi, cusps),
      position: (lambda: sunToday.phi, beta: 0.0, delta: sunToday.rho)
    );
  }

  ChartObjectInfo calculateMoon(List<double> cusps) {
    final moo = moon.apparent(_djd, dpsi: _sphera.nutation.deltaPsi);
    return (
      type: ChartObjectType.moon,
      dailyMotion: moo.motion,
      house: inHouse(moo.lambda, cusps),
      position: (lambda: moo.lambda, beta: moo.beta, delta: moo.delta)
    );
  }

  ChartObjectInfo calculateLunarNode(List<double> cusps) {
    final lngToday = moon.lunarNode(_djd, trueNode: _trueNode);
    final lngTomorrow = moon.lunarNode(_djd + 1, trueNode: _trueNode);
    return (
      type: ChartObjectType.node,
      dailyMotion: diffAngle(lngToday, lngTomorrow),
      house: inHouse(lngToday, cusps),
      position: (lambda: lngToday, beta: 0.0, delta: 0.0)
    );
  }

  ChartObjectInfo calculatePlanet(
      PlanetId id, ChartObjectType type, List<double> cusps) {
    final pla = Planet.forId(id);
    final posToday = pla.geocentricPosition(_sphera);
    final posTomorrow = pla.geocentricPosition(_spheraTomorrow);
    return (
      type: type,
      dailyMotion: diffAngle(posToday.lambda, posTomorrow.lambda),
      house: inHouse(posToday.lambda, cusps),
      position: (
        lambda: posToday.lambda,
        beta: posToday.beta,
        delta: posToday.delta
      )
    );
  }

  ChartObjectInfo calculatePosition(ChartObjectType obj, List<double> cusps) {
    switch (obj) {
      case ChartObjectType.sun:
        return calculateSun(cusps);
      case ChartObjectType.moon:
        return calculateMoon(cusps);
      case ChartObjectType.mercury:
        return calculatePlanet(PlanetId.Mercury, obj, cusps);
      case ChartObjectType.venus:
        return calculatePlanet(PlanetId.Venus, obj, cusps);
      case ChartObjectType.mars:
        return calculatePlanet(PlanetId.Mars, obj, cusps);
      case ChartObjectType.jupiter:
        return calculatePlanet(PlanetId.Jupiter, obj, cusps);
      case ChartObjectType.saturn:
        return calculatePlanet(PlanetId.Saturn, obj, cusps);
      case ChartObjectType.uranus:
        return calculatePlanet(PlanetId.Uranus, obj, cusps);
      case ChartObjectType.neptune:
        return calculatePlanet(PlanetId.Neptune, obj, cusps);
      case ChartObjectType.pluto:
        return calculatePlanet(PlanetId.Pluto, obj, cusps);
      case ChartObjectType.node:
        return calculateLunarNode(cusps);
      default:
        throw UnsupportedError('$obj is not supported');
    }
  }
}
