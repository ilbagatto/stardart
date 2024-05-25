/// Astrological Houses.
///
/// Available house systems are:
///
/// 1. Quadrant-based systems:
///    * Placidus
///    * Koch
///    * Regiomontanus
///    * Campanus
///    * Topocentric
/// 2. Morinus System.
/// 3. Equal Systems.
///
library;

import 'dart:math';
import 'package:astropc/mathutils.dart';
import 'package:astropc/misc.dart';
import 'package:astropc/timeutils.dart';
import 'package:vector_math/vector_math.dart';

import 'points.dart';

enum HouseSystem {
  placidus('Placidus', true),
  koch('Koch', true),
  regioMontanus('Regio-Montanus', true),
  campanus('Campanus', true),
  topocentric('Topocentric', true),
  morinus('Morinus', false),
  equalSignCusp('Equal (Sign-Cusp)', false),
  equalAsc('Equal from Asc', false),
  equalMC('Equal from MC', false);

  const HouseSystem(this.name, this.isQuadrant);

  final String name;
  final bool isQuadrant;

  @override
  String toString() {
    return name;
  }

  /// Return a system with the given [name]. If no such name exists, the method
  /// throws a [StateError].
  ///
  /// For some systems brief names are also allowed:
  /// `SignCusp`, `EqualAsc`, `EqualMC`, `RegioMontanus`
  ///
  /// The names are case-insensitive
  static HouseSystem forName(String name) {
    String s = name.toLowerCase();
    if (s == 'equalasc') {
      s = 'equal from asc';
    } else if (s == 'equalmc') {
      s = 'equal from mc';
    } else if (s == 'signcusp') {
      s = 'equal (sign-cusp)';
    } else if (s == 'regiomontanus') {
      s = 'regio-montanus';
    }
    return HouseSystem.values.firstWhere((e) => e.name.toLowerCase() == s);
  }
}

const halfSecond = 0.5 / 3600;
const r30 = 0.5235987755982988;
const r60 = 1.0471975511965976;
const r90 = 1.5707963267948966;
const r120 = 2.0943951023931953;
const r150 = 2.6179938779914944;

/// Base class for all the systems.
abstract class HousesBuilder {
  final HouseSystem _system;

  /// Returns cusps 0..11, in arc-degrees
  List<double> calculateCusps();

  HousesBuilder(this._system);

  static HousesBuilder getBuilder(
      HouseSystem system, double djd, Point<double> geoCoords) {
    if (system.isQuadrant) {
      return QuadrantSystem.forTimeAndPlace(system, djd, geoCoords);
    }

    switch (system) {
      case HouseSystem.morinus:
        return Morinus.fromTimeAndLongitude(djd, geoCoords.x);
      case HouseSystem.equalSignCusp:
        return Equal.signCusp();
      case HouseSystem.equalAsc:
        return Equal.fromAsc(djd, geoCoords);
      case HouseSystem.equalMC:
        return Equal.fromMC(djd, geoCoords);
      default:
        throw UnsupportedError("Unknown houses system: $system");
    }
  }

  /// System identifier
  HouseSystem get system => _system;
}

/// Base class for  Quadrant-based systems.
/// Most of them fail at high geographical latitudes.
/// In such cases cusps function will raise runtime error.
abstract class QuadrantSystem extends HousesBuilder {
  final double _ramc;
  final double _eps;
  final double _theta;
  final double _asc;
  final double _mc;

  // List<double> _cusps = List.empty(growable: true);
  // final List<double> _cusps = List.filled(12, 0);

  QuadrantSystem(
      super._system, this._ramc, this._eps, this._theta, this._asc, this._mc) {
    if (_theta.abs() > r90 - _eps.abs()) {
      throw 'This system fails at high latitudes';
    }
  }

  factory QuadrantSystem.forTimeAndPlace(
      HouseSystem system, djd, Point<double> geoCoords) {
    final theta = radians(geoCoords.y);
    final lst = djdToSidereal(djd, lng: geoCoords.x);
    final ramc = radians(lst * 15);
    final t = djd / daysPerCent;
    final nu = nutation(t);
    final eps = radians(obliquity(djd, deps: nu.deltaEps));
    final asc = ascendant(ramc, eps, theta);
    final mc = midheaven(ramc, eps);

    switch (system) {
      case HouseSystem.placidus:
        return Placidus(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      case HouseSystem.koch:
        return Koch(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      case HouseSystem.regioMontanus:
        return Regiomontanus(
            ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      case HouseSystem.campanus:
        return Campanus(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      case HouseSystem.topocentric:
        return Topocentric(
            ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      default:
        throw UnsupportedError("'$system' is not a Quadrant system");
    }
  }

  /// Medium Coeli in radians
  double get mc => _mc;

  /// Ascendant in radians
  double get asc => _asc;

  /// Right Ascension of the Meridian, radians
  double get ramc => _ramc;

  /// Obliquity of the eclipic
  double get eps => _eps;

  /// Geographical latitude, radians
  double get theta => _theta;

  List<double> buildCusps(List<double> base) {
    /// base are longitudes of cusps 11, 12, 2, 3, in radians
    return [
      asc,
      base[2],
      base[3],
      reduceRad(mc + pi),
      reduceRad(base[0] + pi),
      reduceRad(base[1] + pi),
      reduceRad(asc + pi),
      reduceRad(base[2] + pi),
      reduceRad(base[3] + pi),
      mc,
      base[0],
      base[1]
    ].map((e) => degrees(e)).toList();
  }
}

class Koch extends QuadrantSystem {
  List<double> _offsets = [];

  Koch(
      {required double ramc,
      required double eps,
      required double theta,
      required double asc,
      required double mc})
      : super(HouseSystem.koch, ramc, eps, theta, asc, mc) {
    final tnThe = tan(theta);
    final snEps = sin(eps);
    final snMc = sin(mc);
    final k = asin(tnThe * tan(asin(snMc * snEps)));
    final k1 = k / 3;
    final k2 = k1 * 2;
    _offsets = [-r60 - k2, -r30 - k1, r30 + k1, r60 + k2];
  }

  @override
  List<double> calculateCusps() {
    final base = _offsets.map((x) => ascendant(ramc + x, eps, theta));
    return buildCusps(base.toList());
  }
}

class Placidus extends QuadrantSystem {
  static const _delta = 1e-4;
  static const _args = [
    (10, 3.0, r30),
    (11, 1.5, r60),
    (1, 1.5, r120),
    (2, 3.0, r150)
  ];

  late double _csEps;
  late double _tt;

  Placidus(
      {required double ramc,
      required double eps,
      required double theta,
      required double asc,
      required double mc})
      : super(HouseSystem.placidus, ramc, eps, theta, asc, mc) {
    _csEps = cos(eps);
    _tt = tan(theta) * tan(eps);
  }

  double calcCusp(int i, double f, double x0) {
    final [k, r] = (i == 10 || i == 11) ? [-1, ramc] : [1, ramc + pi];

    nextX(double lastX) {
      var x = r - k * (acos(k * sin(lastX) * _tt)) / f;
      if ((shortestArcRad(x, lastX).abs()) > _delta) {
        return nextX(x);
      } else {
        return x;
      }
    }

    final l = nextX(x0 + ramc);
    return reduceRad(atan2(sin(l), _csEps * cos(l)));
  }

  @override
  List<double> calculateCusps() {
    final base = _args.map((arg) => calcCusp(arg.$1, arg.$2, arg.$3));
    return buildCusps(base.toList());
  }
}

class Regiomontanus extends QuadrantSystem {
  late double _tnThe;

  Regiomontanus(
      {required double ramc,
      required double eps,
      required double theta,
      required double asc,
      required double mc})
      : super(HouseSystem.regioMontanus, ramc, eps, theta, asc, mc) {
    _tnThe = tan(theta);
  }

  double calcCusp(h) {
    final rh = _ramc + h;
    final r = atan2(sin(h) * _tnThe, cos(rh));
    return reduceRad(atan2(cos(r) * tan(rh), cos(r + eps)));
  }

  @override
  List<double> calculateCusps() {
    final base = [r30, r60, r120, r150].map((x) => calcCusp(x));
    return buildCusps(base.toList());
  }
}

class Campanus extends QuadrantSystem {
  late double _snThe;
  late double _csThe;
  late double _rm90;

  Campanus(
      {required double ramc,
      required double eps,
      required double theta,
      required double asc,
      required double mc})
      : super(HouseSystem.campanus, ramc, eps, theta, asc, mc) {
    _snThe = sin(theta);
    _csThe = cos(theta);
    _rm90 = ramc + r90;
  }

  double calcCusp(h) {
    final snH = sin(h);
    final d = _rm90 - atan2(cos(h), snH * _csThe);
    final c = atan2(tan(asin(_snThe * snH)), cos(d));
    return reduceRad(atan2(tan(d) * cos(c), cos(c + _eps)));
  }

  @override
  List<double> calculateCusps() {
    final base = [r30, r60, r120, r150].map((x) => calcCusp(x));
    return buildCusps(base.toList());
  }
}

class Topocentric extends QuadrantSystem {
  static const _args = [(-r60, 1), (-r30, 2), (r30, 2), (r60, 1)];
  late double _tnThe;

  Topocentric(
      {required double ramc,
      required double eps,
      required double theta,
      required double asc,
      required double mc})
      : super(HouseSystem.topocentric, ramc, eps, theta, asc, mc) {
    _tnThe = tan(theta);
  }

  @override
  List<double> calculateCusps() {
    final base = _args.map(
        (arg) => ascendant(_ramc + arg.$1, _eps, atan2(arg.$2 * _tnThe, 3)));
    return buildCusps(base.toList());
  }
}

class Morinus extends HousesBuilder {
  final double _ramc;
  late double _csEps;

  Morinus(this._ramc, eps) : super(HouseSystem.morinus) {
    _csEps = cos(eps);
  }

  factory Morinus.fromTimeAndLongitude(double djd, double lng) {
    final lst = djdToSidereal(djd, lng: lng);
    final ramc = radians(lst * 15);
    final nu = nutation(djd / daysPerCent);
    final eps = radians(obliquity(djd, deps: nu.deltaEps));
    return Morinus(ramc, eps);
  }

  @override
  List<double> calculateCusps() {
    final cusps = List<double>.filled(12, 0);
    for (int i = 0; i < 12; i++) {
      final r = _ramc + r60 + r30 * (i + 1);
      final y = sin(r) * _csEps;
      final x = cos(r);
      cusps[i] = reduceRad(atan2(y, x));
    }
    return cusps.map((e) => degrees(e)).toList();
  }
}

class Equal extends HousesBuilder {
  final double _startX;
  final int _startN;

  Equal(super._type, [this._startX = 0, this._startN = 0]);

  /// Factory method for the 'Sign=Cusp' system
  factory Equal.signCusp() => Equal(HouseSystem.equalSignCusp);

  /// Factory method for Equal from the Ascendant system
  /// Starting point is the Ascendant, in radians.
  /// [djd] is Julian Day for epoch 1900.0
  /// [geoCoords] is geographical coordinates.
  factory Equal.fromAsc(double djd, Point<double> geoCoords) {
    final lst = djdToSidereal(djd, lng: geoCoords.x);
    final ramc = radians(lst * 15);
    final theta = radians(geoCoords.y);
    final t = djd / daysPerCent;
    final nu = nutation(t);
    final eps = radians(obliquity(djd, deps: nu.deltaEps));
    final asc = ascendant(ramc, eps, theta);
    return Equal(HouseSystem.equalAsc, asc);
  }

  /// Factory method for Equal from the MC system
  /// Starting point is the Midheaven.
  /// [djd] is Julian Day for epoch 1900.0
  /// [geoCoords] is geographical coordinates.
  factory Equal.fromMC(double djd, Point<double> geoCoords) {
    final t = djd / daysPerCent;
    final nu = nutation(t);
    final eps = radians(obliquity(djd, deps: nu.deltaEps));
    final lst = djdToSidereal(djd, lng: geoCoords.x);
    final ramc = radians(lst * 15);
    final mc = midheaven(ramc, eps);
    return Equal(HouseSystem.equalMC, mc, 9);
  }
  //Equal(HouseSystem.equalMC, mc, 9);

  @override
  List<double> calculateCusps() {
    final cusps = List<double>.filled(12, 0);
    for (int i = 0; i < 12; i++) {
      final n = (_startN + i) % 12;
      cusps[n] = reduceRad(_startX + r30 * i);
    }
    return cusps.map((e) => degrees(e)).toList();
  }
}

/// Given [x], a longitude in arc-degrees, and list of [cusps] in arc-degrees,
/// return index of a house it falls in.
///
/// Remember that a special check has to be done for the house that spans
/// 0 degrees Aries.
/// Returns house number (zero-based).
/// If [cusps] list contains invaid data,the result is undefined.
int inHouse(double x, List<double> cusps) {
  final r = reduceDeg(x + halfSecond);
  int result = 0;
  for (int i = 0; i < 12; i++) {
    final a = cusps[i];
    final b = cusps[(i + 1) % 12];
    if (((a <= r) && (r < b)) || (a > b && (r >= a || r < b))) {
      result = i;
      break;
    }
  }
  return result;
}
