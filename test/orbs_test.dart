import 'package:stardart/aspects.dart';
import 'package:stardart/src/charts/objects.dart';
import 'package:test/test.dart';

typedef OrbsTest = ({
  ChartObjectInfo source,
  ChartObjectInfo target,
  Aspect aspect,
  AspectInfo? result
});

const commonCases = [
  (
    source: (
      type: ChartObjectType.moon,
      position: (lambda: 310.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0,
    ),
    target: (
      type: ChartObjectType.sun,
      position: (lambda: 312.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0,
    ),
    aspect: Aspect.conjunction,
    result: (aspect: Aspect.conjunction, delta: 2.0, arc: 2.0)
  ),
  (
    source: (
      type: ChartObjectType.moon,
      position: (lambda: 310.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0,
    ),
    target: (
      type: ChartObjectType.mercury,
      position: (lambda: 295.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0
    ),
    aspect: Aspect.conjunction,
    result: null
  ),
  (
    source: (
      type: ChartObjectType.moon,
      position: (lambda: 310.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0,
    ),
    target: (
      type: ChartObjectType.sun,
      position: (lambda: 312.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0,
    ),
    aspect: Aspect.opposition,
    result: null
  ),
  (
    source: (
      type: ChartObjectType.sun,
      position: (lambda: 312.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0,
    ),
    target: (
      type: ChartObjectType.jupiter,
      position: (lambda: 46.0, beta: 0.0, delta: 1.0),
      dailyMotion: 1.0,
      house: 0
    ),
    aspect: Aspect.square,
    result: (aspect: Aspect.square, delta: 4.0, arc: 94.0)
  ),
];

final edgeCase = (
  source: (
    type: ChartObjectType.mercury,
    position: (lambda: 312.0, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0,
  ),
  target: (
    type: ChartObjectType.mars,
    position: (lambda: 175.0, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  )
);

void main() {
  group('Dariot', () {
    final method = OrbsMethod.getInstance(Orbs.dariot);
    for (final c in commonCases) {
      test("${c.aspect} ${c.source.type} - ${c.target.type}", () {
        expect(
            method.isAspect(source: c.source, target: c.target, asp: c.aspect),
            equals(c.result));
      });
    }

    test('Edge case', () {
      final res = method.isAspect(
          source: edgeCase.source,
          target: edgeCase.target,
          asp: Aspect.biquintile);
      expect(res, equals((aspect: Aspect.biquintile, delta: 7.0, arc: 137.0)));
    });
  });

  group('DeVore', () {
    final method = OrbsMethod.getInstance(Orbs.deVore);
    for (final c in commonCases) {
      test("${c.aspect} ${c.source.type} - ${c.target.type}", () {
        expect(
            method.isAspect(source: c.source, target: c.target, asp: c.aspect),
            equals(c.result));
      });
    }
    test('Edge case', () {
      final res = method.isAspect(
          source: edgeCase.source,
          target: edgeCase.target,
          asp: Aspect.biquintile);
      expect(res, isNull);
    });
  });

  group('Classic with aspect ratio', () {
    final method = OrbsMethod.getInstance(Orbs.classicWithAspectRatio);
    for (final c in commonCases) {
      test("${c.aspect} ${c.source.type} - ${c.target.type}", () {
        expect(
            method.isAspect(source: c.source, target: c.target, asp: c.aspect),
            equals(c.result));
      });
    }

    test('Edge case', () {
      final res = method.isAspect(
          source: edgeCase.source,
          target: edgeCase.target,
          asp: Aspect.biquintile);
      expect(res, isNull);
    });
  });
}
