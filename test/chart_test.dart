import 'dart:math';

import 'package:test/test.dart';
import 'package:stardart/chart.dart';

void main() {
  final chart = BaseChart.forDJDAndPlace(
      djd: 23772.990277, geoCoords: Point(-37.58, 55.75));

  group('Base Chart', () {
    group('Smoke test', () {
      test('Houses', () => expect(chart.houses, isNotEmpty));
      test('Objects', () => expect(chart.objects, isNotEmpty));
      test('Aspects', () {
        final aspects = chart.aspectsTo(ChartObjectType.sun);
        expect(aspects, isNotEmpty);
      });
    });
  });
}
