library;

import 'package:astropc/mathutils.dart';
import 'package:stardart/aspects.dart';

import '../charts/objects.dart';
import 'aspects.dart';

enum Orbs { dariot, deVore, classicWithAspectRatio }

/// Base class for detecting an amount of leeway allowed in the measurement
/// of a given aspect or angle.pac
///
/// There are different ways to determine, whether two planets are in
/// aspect. Subclasses implement [is_aspect] method which detects aspect
/// using specific rules.
abstract class OrbsMethod {
  final String _name;

  const OrbsMethod(this._name);

  String get name => _name;

  @override
  String toString() => _name;

  /// Check, if two objects are in aspect
  ///
  /// * [source] : source object
  /// * [target] : target object
  /// * [aspect] : aspect to check
  /// * [arc] (optional) : arc between the objects. May be reused in repeating chects.
  /// Returns aspect details if there is an aspect, otherwise `null`.
  AspectInfo? isAspect(
      {required ChartObjectInfo source,
      required ChartObjectInfo target,
      required Aspect asp,
      double? arc});

  /// Return object by [id].
  static OrbsMethod getInstance(Orbs id) {
    switch (id) {
      case Orbs.dariot:
        return Dariot();
      case Orbs.deVore:
        return DeVore();
      case Orbs.classicWithAspectRatio:
        return ClassicWithAspectRatio();
    }
  }
}

/// _Claude Dariot_ (1533-1594), introduced the so called _'moieties'_
/// (mean-values) when calculating orbs. According to Dariot, Mercury and the
/// Moon enter completion (application) of any aspect at a  distance of
/// **9½°** — the total of their respective moieties:
/// `(Mercury = 3½° + Moon = 6°)`.
///
/// This method became the standard for European Renaissance astrologers.
/// I does not take into account the nature of aspects.
class Dariot extends OrbsMethod {
  static Dariot? _instance;

  static const defaultMoiety = 4.0;
  static const Map<ChartObjectType, double> moieties = {
    ChartObjectType.moon: 12.0,
    ChartObjectType.sun: 15.0,
    ChartObjectType.mercury: 7.0,
    ChartObjectType.venus: 7.0,
    ChartObjectType.mars: 8.0,
    ChartObjectType.jupiter: 9.0,
    ChartObjectType.saturn: 9.0,
    ChartObjectType.uranus: 6.0,
    ChartObjectType.neptune: 6.0,
    ChartObjectType.pluto: 5.0
  };

  const Dariot._() : super('Classic (Claude Dariot)');

  factory Dariot() => _instance ??= Dariot._();

  double getMoiety(ChartObjectType type) =>
      moieties.containsKey(type) ? moieties[type]! : defaultMoiety;

  /// Given two chart objects, [srcType] and [dstType], calculate orb between them.
  double calculateOrb(ChartObjectType srcType, ChartObjectType dstType) {
    // Calculate mean orb for planets src and dst,
    final a = getMoiety(srcType);
    final b = getMoiety(dstType);
    return (a + b) / 2.0;
  }

  /// Check aspect using calculated orb.
  ///
  /// * [asp] : aspect to check
  /// * [orb] : orb in arc-degrees.
  /// * [arc] : angular distance in arc-degrees
  ///
  /// Returns aspect details if there is an aspect, otherwise `null`.
  AspectInfo? checkAspect(Aspect asp, double orb, double arc) {
    final delta = (arc - asp.value).abs();
    if (delta <= orb) {
      return (aspect: asp, arc: arc, delta: delta);
    }
    return null;
  }

  @override
  AspectInfo? isAspect(
      {required ChartObjectInfo source,
      required ChartObjectInfo target,
      required Aspect asp,
      double? arc}) {
    arc ??= shortestArc(source.position.lambda, target.position.lambda);
    return checkAspect(asp, calculateOrb(source.type, target.type), arc);
  }
}

/// Some modern astrologers believe that orbs are based on aspects.
/// The values are from _"Encyclopaedia of Astrology"_ by _Nicholas deVore_.
///
/// /// The class is a Singleton.
class DeVore extends OrbsMethod {
  static DeVore? _instance;

  static const Map<Aspect, (double, double)> ranges = {
    Aspect.conjunction: (-10.0, 6.0),
    Aspect.vigintile: (17.5, 18.5),
    Aspect.quindecile: (23.5, 24.5),
    Aspect.semisextile: (28.0, 31.0),
    Aspect.decile: (35.5, 36.5),
    Aspect.sextile: (56, 63),
    Aspect.semisquare: (42.0, 49.0),
    Aspect.quintile: (71.5, 72.5),
    Aspect.square: (84.0, 96.0),
    Aspect.tridecile: (107.5, 108.5),
    Aspect.trine: (113.0, 125.0),
    Aspect.sesquiquadrate: (132.0, 137.0),
    Aspect.biquintile: (143.5, 144.5),
    Aspect.quincunx: (148.0, 151.0),
    Aspect.opposition: (174, 186)
  };

  const DeVore._() : super('By Aspect (Nicholas deVore)');

  factory DeVore() => _instance ??= DeVore._();

  @override
  AspectInfo? isAspect(
      {required ChartObjectInfo source,
      required ChartObjectInfo target,
      required Aspect asp,
      double? arc}) {
    arc ??= shortestArc(source.position.lambda, target.position.lambda);
    final range = ranges[asp]!;
    if (range.$1 <= arc && range.$2 >= arc) {
      return (aspect: asp, arc: arc, delta: (arc - asp.value).abs());
    }
    return null;
  }
}

/// Combined approach. For major aspects the classic Dariot method is applied.
/// For minor and kepler aspects we apply to the classic orb value a
/// special coefficient: by default, **0.6 (60%)** for minor and
/// **0.4 (40%)** for keplerian.
class ClassicWithAspectRatio extends OrbsMethod {
  final double minorCoeff;
  final double keplerCoeff;
  late Dariot _classic;

  ClassicWithAspectRatio({this.minorCoeff = 0.6, this.keplerCoeff = 0.6})
      : super('Classic with regard to Aspect type') {
    _classic = Dariot();
  }

  @override
  AspectInfo? isAspect(
      {required ChartObjectInfo source,
      required ChartObjectInfo target,
      required Aspect asp,
      double? arc}) {
    arc ??= shortestArc(source.position.lambda, target.position.lambda);
    double orb = _classic.calculateOrb(source.type, target.type);
    if (asp.typeFlag == AspectType.minor) {
      orb *= minorCoeff;
    } else if (asp.typeFlag == AspectType.kepler) {
      orb *= keplerCoeff;
    }
    return _classic.checkAspect(asp, orb, arc);
  }
}
