import 'dart:math';

import 'package:astropc/planets.dart';
import 'package:stardart/aspects.dart';
import 'package:stardart/houses.dart';
import 'package:test/test.dart';
import 'package:stardart/charts.dart';

const delta = 1e-6;

void main() {
  final Place place = (name: 'Moscow', coords: Point(-37.58, 55.75));
  final settings = (
    houses: HouseSystem.placidus,
    trueNode: true,
    orbs: Orbs.dariot,
    aspectTypes: 0x1 // AspectType.major.value
  );
  group('Birth Chart', () {
    final chart = BirthChart(
        name: 'Test Chart',
        djd: 23772.990277,
        place: place,
        settings: settings);
    group('Smoke test', () {
      test('Houses', () => expect(chart.houses.length, equals(12)));
      test('Objects', () => expect(chart.objects.length, equals(11)));
      test('Aspects', () => expect(chart.aspects, isNotEmpty));
      test('AspectsTo', () {
        final aspects = chart.aspectsTo(ChartObjectType.jupiter);
        expect(aspects.length, equals(5));
      });
      test('Sphera', () => expect(chart.sphera, isNotNull));
      test('Points', () => expect(chart.points, isNotNull));
      test('Sidereal Time',
          () => expect(chart.siderealTime, closeTo(23.03702536997929, 1e-6)));
    });
  });
}
