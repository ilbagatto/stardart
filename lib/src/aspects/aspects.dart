/// Astrological aspects

library;

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
}

/// Aspect and diviation from its exact value.
typedef AspectAndDelta = ({Aspect aspect, double delta});

/// Aspected celestial point
typedef AspectedPoint = ({String name, double longitude});

/// [source]: the first aspected point
/// [target]: the second aspected point
/// [aspect]: Aspect instance
/// [arc]: angular distance between planets (degrees)
/// [delta]: difference between actual distance and exact aspect value
typedef AspectInfo = ({
  AspectedPoint target,
  Aspect aspect,
  double delta,
  double arc
});

class AspectsDetector {
  /// indicates, which method to use for detecting an aspect.
  final OrbsMethod orbsMethod;

  /// binary combination of aspect types to be taken into account.
  final int typeFlags;

  const AspectsDetector(
      {required this.orbsMethod, this.typeFlags = allAspectTypes});

  /// Find closest aspect between two or null, if there are no aspects.
  ///
  /// [source] is the first celestial point.
  /// [target] is the second celestial point.
  /// [arc] angular distance between the objects, in arc-degrees.
  AspectAndDelta? findClosest(
      AspectedPoint source, AspectedPoint target, double arc) {
    AspectAndDelta? closest;
    for (final asp in Aspect.values) {
      if (asp.typeFlag.value & typeFlags != 0) {
        if (orbsMethod.isAspect(source.name, target.name, asp, arc)) {
          final delta = (asp.value - arc).abs();
          if (closest == null || closest.delta > delta) {
            closest = (aspect: asp, delta: delta);
          }
        }
      }
    }
    return closest;
  }

  /// Search aspects from a celestial point [source] to range of points, [targets].
  /// When aspect is found, the result is yielded.
  Iterable<AspectInfo> iterAspects(
      AspectedPoint source, List<AspectedPoint> targets) sync* {
    for (final target in targets) {
      double arc = (source.longitude - target.longitude).abs();
      if (arc > 180) {
        arc = 360 - arc;
      }
      final closest = findClosest(source, target, arc);
      if (closest != null) {
        yield (
          target: target,
          aspect: closest.aspect,
          delta: closest.delta,
          arc: arc
        );
      }
    }
  }
}
