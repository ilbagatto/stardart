import 'package:astropc/planets.dart';
import 'package:stardart/common.dart';

/// Chart objects.
enum ChartObjectType {
  moon('Moon', Influence.positive),
  sun('Sun', Influence.positive),
  mercury('Mercury', Influence.neutral),
  venus('Venus', Influence.positive),
  mars('Mars', Influence.negative),
  jupiter('Jupiter', Influence.positive),
  saturn('Saturn', Influence.negative),
  uranus('Uranus', Influence.negative),
  neptune('Neptune', Influence.neutral),
  pluto('Pluto', Influence.neutral),
  node('Lunar Nde', Influence.neutral);

  const ChartObjectType(this.name, this.influence);

  final String name;
  final Influence influence;

  @override
  String toString() => name;
}

/// bject position in the chart.
typedef ChartObjectInfo = ({
  /// Object type.
  ChartObjectType type,

  /// Ecliptical coordinates.
  EclipticPosition position,

  /// Mean daily motion.
  double dailyMotion,

  /// House occupied by the object.
  int house
});

/// Mapping of planets from astropc library to chart objects.
final Map<PlanetId, ChartObjectType> planetToObject = {
  PlanetId.Mercury: ChartObjectType.mercury,
  PlanetId.Venus: ChartObjectType.venus,
  PlanetId.Mars: ChartObjectType.mars,
  PlanetId.Jupiter: ChartObjectType.jupiter,
  PlanetId.Saturn: ChartObjectType.saturn,
  PlanetId.Uranus: ChartObjectType.uranus,
  PlanetId.Neptune: ChartObjectType.neptune,
  PlanetId.Pluto: ChartObjectType.pluto
};
