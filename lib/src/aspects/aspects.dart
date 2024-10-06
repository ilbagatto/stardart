/// Astrological aspects

library;

import 'package:astropc/mathutils.dart';
import 'package:sprintf/sprintf.dart';

import '../charts/objects.dart';
import '../common.dart';
import 'orbs.dart';

/// Types of aspects.
/// May be used as flags, e.g.:
/// ```
/// m = AspectType.major.value | AspectType.minor.value;
/// if (AspectType.minor.value & m) { // returns true
///     ...
/// }
/// if (AspectType.kepler.value & m) { // returns false
///     ...
/// }
/// ```
enum AspectType {
  major(0x1),
  minor(0x2),
  kepler(0x4);

  const AspectType(this.value);
  final int value;
}

/// A combination of Major, Minor and Kepler types.
const allAspectTypes = 7;
const majorAndMinor = 3;

/// Astrologival aspects.
enum Aspect implements Comparable<Aspect> {
  conjunction('Conjunction', 'cnj', 0, Influence.neutral, AspectType.major),
  vigintile('Vigintile', 'vgt', 18, Influence.neutral, AspectType.kepler),
  quindecile('Quindecile', 'qdc', 24, Influence.neutral, AspectType.kepler),
  semisextile('Semisextile', 'ssx', 30, Influence.positive, AspectType.minor),
  decile('Decile', 'dcl', 36, Influence.neutral, AspectType.kepler),
  sextile('Sextile', 'sxt', 60, Influence.positive, AspectType.major),
  semisquare('Semisquare', 'ssq', 45, Influence.negative, AspectType.minor),
  quintile('Quintile', 'qui', 72, Influence.neutral, AspectType.kepler),
  square('Square', 'sqr', 90, Influence.negative, AspectType.major),
  tridecile('Tridecile', 'tdc', 108, Influence.positive, AspectType.minor),
  trine('Trine', 'tri', 120, Influence.positive, AspectType.major),
  sesquiquadrate(
      'Sesquiquadrate', 'sqq', 135, Influence.negative, AspectType.minor),
  biquintile('Biquintile', 'bqu', 144, Influence.neutral, AspectType.kepler),
  quincunx('Quincunx', 'qcx', 150, Influence.negative, AspectType.minor),
  opposition('Opposition', 'opp', 180, Influence.negative, AspectType.major);

  const Aspect(
      this.name, this.briefName, this.value, this.influence, this.typeFlag);

  final String name;
  final String briefName;
  final double value;
  final Influence influence;
  final AspectType typeFlag;

  @override
  int compareTo(Aspect other) => (value - other.value).toInt();

  @override
  String toString() => '$name, ${sprintf('%f', [value])}';
}

/// Aspect details.
/// [aspect]: Aspect instance
/// [arc]: angular distance between planets (degrees)
/// [delta]: difference between actual distance and exact aspect value
typedef AspectInfo = ({Aspect aspect, double delta, double arc});

/// Find closest aspect between two or null, if there are no aspects.
///
/// * [source] is the first celestial point.
/// * [target] is the second celestial point.
/// * [method] : method of calculating orbs
/// * [flags] : binary combination of aspect types
///
/// Returns [AspectInfo] instance or [null] if there is no aspect.
AspectInfo? findClosestAspect(
    {required ChartObjectInfo source,
    required ChartObjectInfo target,
    OrbsMethod? method,
    int flags = 0x1}) {
  method ??= OrbsMethod.getInstance(Orbs.classicWithAspectRatio);
  AspectInfo? closest;
  final arc = shortestArc(source.position.lambda, target.position.lambda);
  for (final asp in Aspect.values) {
    if (asp.typeFlag.value & flags != 0) {
      final info =
          method.isAspect(source: source, target: target, asp: asp, arc: arc);
      if (info == null) {
        continue;
      }
      if (closest == null || closest.delta > info.delta) {
        closest = info;
      }
    }
  }
  return closest;
}
