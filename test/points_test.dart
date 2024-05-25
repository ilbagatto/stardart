import 'package:astropc/mathutils.dart';
import 'package:stardart/src/points.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  group('Sensitive points', () {
    final theta = radians(55.75);
    final eps = radians(ddd(23, 26, 39.3202));
    final ramc = radians(ddd(345, 33, 19.2045));
    test('Midheaven', () {
      final got = degrees(midheaven(ramc, eps));
      expect(got, closeTo(ddd(344, 19, 2), 1e-3));
    });
    test('Ascendant', () {
      final got = degrees(ascendant(ramc, eps, theta));
      expect(got, closeTo(ddd(110, 9, 26), 1e-4));
    });
    test('Vertex', () {
      final got = degrees(vertex(ramc, eps, theta));
      expect(got, closeTo(ddd(242, 42, 13), 1e-4));
    });
    test('East Point', () {
      final got = degrees(eastpoint(ramc, eps));
      expect(got, closeTo(76.70363, 1e-4));
    });
  });
}
