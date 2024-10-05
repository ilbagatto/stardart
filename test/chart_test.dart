import 'dart:math';

import 'package:test/test.dart';
import 'package:stardart/charts.dart';

const delta = 1e-6;

void main() {
  final Place place = (name: 'Moscow', coords: Point(-37.58, 55.75));
  group('Birth Chart', () {
    final chart =
        BirthChart(name: 'Test Chart', djd: 23772.990277, place: place);
    group('Smoke test', () {
      test('Houses', () => expect(chart.houses, isNotEmpty));
      test('Objects', () => expect(chart.objects, isNotEmpty));
      test('Aspects', () {
        expect(chart.aspects, isNotEmpty);
      });
    });
  });
}
