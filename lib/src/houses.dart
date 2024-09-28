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

/// Calculate house cusps using **Placidus** method.
///
/// * [ramc] is right ascension of the Meridian, radians.
/// * [eps] is obliquity of the ecliptic in radians.
/// * [theta] is geographic latitude in radians, positive northwards.
///
/// Yields  longitude of the base cusps (11, 12, 2, 3), in radians.
Iterable<double> placidusCusps(
    {required double ramc, required double eps, required double theta}) sync* {
  const args = [
    (i: 10, f: 3.0, r: r30),
    (i: 11, f: 1.5, r: r60),
    (i: 1, f: 1.5, r: r120),
    (i: 2, f: 3.0, r: r150)
  ];
  const delta = 1e-4;
  final tt = tan(theta) * tan(eps);
  final csEps = cos(eps);

  for (final arg in args) {
    final [k, r] = (arg.i == 10 || arg.i == 11) ? [-1, ramc] : [1, ramc + pi];
    double lastX = arg.r + ramc;
    for (int i = 0; i < 30; i++) {
      double nextX = r - k * (acos(k * sin(lastX) * tt)) / arg.f;
      if (shortestArcRad(nextX, lastX).abs() < delta) {
        break;
      }
      lastX = nextX;
    }
    yield reduceRad(atan2(sin(lastX), csEps * cos(lastX)));
  }
}

/// Calculate house cusps using **Koch** method.
///
/// * [ramc] is right ascension of the Meridian, radians.
/// * [eps] is obliquity of the ecliptic in radians.
/// * [theta] is geographic latitude in radians, positive northwards.
/// * [mc] is Midheaven in radians.
///
/// Yields  longitude of the base cusps (11, 12, 2, 3), in radians.
Iterable<double> kochCusps(
    {required double ramc,
    required double eps,
    required double theta,
    required double mc}) sync* {
  final tnThe = tan(theta);
  final snEps = sin(eps);
  final snMc = sin(mc);
  final k = asin(tnThe * tan(asin(snMc * snEps)));
  final k1 = k / 3;
  final k2 = k1 * 2;
  final offsets = [-r60 - k2, -r30 - k1, r30 + k1, r60 + k2];

  for (final x in offsets) {
    yield ascendant(ramc + x, eps, theta);
  }
}

/// Calculate house cusps using **Regio-Montanus** method.
///
/// * [ramc] is right ascension of the Meridian, radians.
/// * [eps] is obliquity of the ecliptic in radians.
/// * [theta] is geographic latitude in radians, positive northwards.
///
/// Yields  longitude of the base cusps (11, 12, 2, 3), in radians.
Iterable<double> regioMontanusCusps(
    {required double ramc, required double eps, required double theta}) sync* {
  final tnThe = tan(theta);
  const offsets = [r30, r60, r120, r150];
  for (final x in offsets) {
    final rh = ramc + x;
    final r = atan2(sin(x) * tnThe, cos(rh));
    yield reduceRad(atan2(cos(r) * tan(rh), cos(r + eps)));
  }
}

/// Calculate house cusps using **Campanus** method.
///
/// * [ramc] is right ascension of the Meridian, radians.
/// * [eps] is obliquity of the ecliptic in radians.
/// * [theta] is geographic latitude in radians, positive northwards.
///
/// Yields  longitude of the base cusps (11, 12, 2, 3), in radians.
Iterable<double> campanusCusps(
    {required double ramc, required double eps, required double theta}) sync* {
  final snThe = sin(theta);
  final csThe = cos(theta);
  final rm90 = ramc + r90;
  const offsets = [r30, r60, r120, r150];

  for (final x in offsets) {
    final snH = sin(x);
    final d = rm90 - atan2(cos(x), snH * csThe);
    final c = atan2(tan(asin(snThe * snH)), cos(d));
    yield reduceRad(atan2(tan(d) * cos(c), cos(c + eps)));
  }
}

/// Calculate house cusps using **Topocentric** method.
///
/// * [ramc] is right ascension of the Meridian, radians.
/// * [eps] is obliquity of the ecliptic in radians.
/// * [theta] is geographic latitude in radians, positive northwards.
///
/// Yields  longitude of the base cusps (11, 12, 2, 3), in radians.
Iterable<double> topocentricCusps(
    {required double ramc, required double eps, required double theta}) sync* {
  final tnThe = tan(theta);
  const args = [(-r60, 1.0), (-r30, 2.0), (r30, 2), (r60, 1.0)];

  for (final arg in args) {
    yield ascendant(ramc + arg.$1, eps, atan2(arg.$2 * tnThe, 3));
  }
}

///  Calculate cusps using one of **quadrant-based** system:
///
///  * Placidus
///  * Koch
///  * Regiomontanus
///  * Campanus
///  * Topocentric
///
///   Arguments:
///  * [system] : a system
///  * [ramc] : Right ascension of the Meridian, radians.
///  * [eps] : Obliquity of the ecliptic in radians.
///  * [theta] : Geographic latitude in radians, positive northwards.
///  * [asc] (optional): Ascendant, radians
///  * [mc] (optional): Midheaven, radians
///
///   Raises exception:
///  * if the function is called for a high latitude where quadrant systems fail.
///  * if given system is not a quadrant system (e.g. Morinus or Equal).
///
///   Returns longitudes of cusps 1-12 in arc-degrees.

List<double> quadrantCusps(
    {required HouseSystem system,
    required double ramc,
    required double eps,
    required double theta,
    double? asc,
    double? mc}) {
  if (theta.abs() > r90 - eps.abs()) {
    throw 'This system fails at high latitudes';
  }

  asc ??= ascendant(ramc, eps, theta);
  mc ??= midheaven(ramc, eps);

  Iterable<double> iter;
  switch (system) {
    case HouseSystem.placidus:
      iter = placidusCusps(ramc: ramc, eps: eps, theta: theta);
    case HouseSystem.koch:
      iter = kochCusps(ramc: ramc, eps: eps, theta: theta, mc: mc);
    case HouseSystem.regioMontanus:
      iter = regioMontanusCusps(ramc: ramc, eps: eps, theta: theta);
    case HouseSystem.campanus:
      iter = campanusCusps(ramc: ramc, eps: eps, theta: theta);
    case HouseSystem.topocentric:
      iter = topocentricCusps(ramc: ramc, eps: eps, theta: theta);
    default:
      throw '$system is not a quadrant system';
  }

  // longitudes of cusps 11, 12, 2, 3, in radians
  final base = iter.toList();

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

/// Calculate house cusps using **Topocentric** method.
///
/// * [ramc] is right ascension of the Meridian, radians.
/// * [eps] is obliquity of the ecliptic in radians.
///
/// Returns longitude of the base cusps (11, 12, 2, 3), in radians.
List<double> morinusCusps({required double ramc, required double eps}) {
  final csEps = cos(eps);

  final cusps = List<double>.filled(12, 0);
  for (int i = 0; i < 12; i++) {
    final r = ramc + r60 + r30 * (i + 1);
    final y = sin(r) * csEps;
    final x = cos(r);
    cusps[i] = reduceRad(atan2(y, x));
  }
  return cusps.map((e) => degrees(e)).toList();
}

/// Base routine for equal systems.
///
/// * startN (optional): index of the base cusp. Defaults to 0.
/// * startX (optional): longitude of starting point. Defaults to 0.0.
///
/// Returns longitudes of cusps 1-12 in arc-degrees.
List<double> equalCusps({double startX = 0, int startN = 0}) {
  final cusps = List<double>.filled(12, 0);
  for (int i = 0; i < 12; i++) {
    final n = (startN + i) % 12;
    cusps[n] = reduceRad(startX + r30 * i);
  }
  return cusps.map((e) => degrees(e)).toList();
}

/// Calculate cusps using of Sign-Cusp system.
/// Returns longitudes of cusps 1-12 in arc-degrees.
List<double> signCuspCusps() => equalCusps();

/// Calculate cusps using Equal from Ascendant system.
/// [asc] is Ascendant, radians.
/// Returns longitudes of cusps 1-12 in arc-degrees.
List<double> equalAscCusps(double asc) => equalCusps(startX: asc);

/// Calculate cusps using Equal from Midheaven system.
/// [mc] is Midheaven, radians.
/// Returns longitudes of cusps 1-12 in arc-degrees.
List<double> equalMCCusps(double mc) => equalCusps(startX: mc, startN: 9);

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
