import 'dart:math';

import 'package:test/test.dart';
import 'package:stardart/chart.dart';

const delta = 1e-6;

void main() {
  final geoCoords = Point(-37.58, 55.75);
  group('Base Chart', () {
    final chart =
        BaseChart('Test Chart', djd: 23772.990277, geoCoords: geoCoords);
    group('Smoke test', () {
      test('Houses', () => expect(chart.houses, isNotEmpty));
      test('Objects', () => expect(chart.objects, isNotEmpty));
/*       test('Aspects', () {
        final aspects = chart.aspectsTo(ChartObjectType.sun);
        expect(aspects, isNotEmpty);
      }); */
    });
  });
}
