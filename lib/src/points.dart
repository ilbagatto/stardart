/// Sensitive points
library;

import 'dart:math';
import 'package:astropc/mathutils.dart';

const r90 = 1.5707963267948966; // 90 deg in radians

typedef ChartAngles = ({double asc, double mc, double vtx, double ep});

/// Midheaven, or The Medium Coeli is the highest point of intersection between
/// the meridian and the ecliptic.
///
/// Arguments:
/// ramc : right ascension of the meridian, in radians
/// eps  : Ecliptic obliquity, in radians
///
/// Returns:
/// MC, in radians
double midheaven(double ramc, double eps) {
  var x = atan2(tan(ramc), cos(eps));
  if (x < 0) {
    x += pi;
  }
  if (sin(ramc) < 0) {
    x += pi;
  }
  return reduceRad(x);
}

/// Ascendant -- the point of the zodiac rising on the Eastern horizon.
///
/// Arguments:
/// ramc : right ascension of the meridian, in radians
/// eps  : Ecliptic obliquity, in radians
/// theta: geographical latitude, in radians, positive northwards
///
/// Returns:
/// Ascendant, in radians
double ascendant(double ramc, double eps, double theta) =>
    reduceRad(atan2(cos(ramc), -sin(ramc) * cos(eps) - tan(theta) * sin(eps)));

/// Vertex -- the westernmost point on the Ecliptic where it intersects
/// the Prime Vertical.
///
/// Arguments:
/// ramc : right ascension of the meridian, in radians
/// eps  : Ecliptic obliquity, in radians
/// theta: geographical latitude, in radians, positive northwards
///
/// Returns:
/// Vertex longitude, in radians
double vertex(double ramc, double eps, double theta) =>
    ascendant(ramc + pi, eps, r90 - theta);

/// East Point (aka Equatorial Ascendant)  is the sign and degree rising over
/// the Eastern Horizon at the Earth's equator at any given time.
///
/// Arguments:
/// ramc : right ascension of the meridian, in radians
/// eps  : Ecliptic obliquity, in radians
///
/// Returns:
/// East Point longitude, in radians
double eastpoint(double ramc, double eps) =>
    reduceRad(atan2(cos(ramc), -sin(ramc) * cos(eps)));
