import 'dart:math';

import 'package:test/test.dart';
import 'package:stardart/common.dart';
import 'package:stardart/chart.dart';

const delta = 1e-6;

void main() {
  group('Chart Stats', () {
    final chart = BaseChart('Test Chart',
        djd: 23772.990277, geoCoords: Point(-37.58, 55.75));
    final stats = ChartStats();
    stats.visit(chart);
    group('Quadruplicities', () {
      final quadr = stats.quadruplicities;
      test('Cardinal',
          () => expect(quadr[Quadruplicity.cardinal]!.length, equals(2)));
      test(
          'Fixed', () => expect(quadr[Quadruplicity.fixed]!.length, equals(4)));
      test('Mutable',
          () => expect(quadr[Quadruplicity.fixed]!.length, equals(4)));
    });

    group('Triplicities', () {
      final tripl = stats.triplicities;
      test('Fire', () => expect(tripl[Triplicity.fire]!.length, equals(0)));
      test('Earth', () => expect(tripl[Triplicity.earth]!.length, equals(6)));
      test('Air', () => expect(tripl[Triplicity.air]!.length, equals(2)));
      test('Water', () => expect(tripl[Triplicity.water]!.length, equals(2)));
    });
  });
}
