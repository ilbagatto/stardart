import 'package:stardart/aspects.dart';
import 'package:stardart/src/charts/objects.dart';
import 'package:test/test.dart';

const objects = [
  (
    type: ChartObjectType.moon,
    position: (lambda: 310.2111, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0,
  ),
  (
    type: ChartObjectType.sun,
    position: (lambda: 312.4308, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0,
  ),
  (
    type: ChartObjectType.mercury,
    position: (lambda: 297.0784, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.venus,
    position: (lambda: 295.2094, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.mars,
    position: (lambda: 177.9662, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.jupiter,
    position: (lambda: 46.9290, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.saturn,
    position: (lambda: 334.602, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.uranus,
    position: (lambda: 164.032, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.neptune,
    position: (lambda: 229.9224, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
  (
    type: ChartObjectType.pluto,
    position: (lambda: 165.8254, beta: 0.0, delta: 1.0),
    dailyMotion: 1.0,
    house: 0
  ),
];

void main() {
  group('Closest Aspect', () {
    final info = findClosestAspect(source: objects[0], target: objects[1]);
    test('Sun-Moon conjunction with default orbs method',
        () => expect(info!.aspect, equals(Aspect.conjunction)));

    test('Sun-Moon conjunction with default orbs method',
        () => expect(info!.aspect, equals(Aspect.conjunction)));
  });

  group('Stelliums', () {
    test('Defaut gap', () {
      final groups = iterStelliums(objects).toList();
      expect(groups.length, 7);
    });
    test('Large gap', () {
      final groups = iterStelliums(objects, 15.0);
      expect(groups.length, 5);
    });
    test('Zero gap', () {
      final groups = iterStelliums(objects, 0.0);
      expect(groups.length, objects.length);
    });

    test('Around zero', () {
      List<ChartObjectInfo> objs = List.from(objects);

      objs[5] = (
        type: ChartObjectType.jupiter,
        position: (lambda: 6.0, beta: 0.0, delta: 1.0),
        dailyMotion: 1.0,
        house: 0
      );
      objs[6] = (
        type: ChartObjectType.saturn,
        position: (lambda: 358.602, beta: 0.0, delta: 1.0),
        dailyMotion: 1.0,
        house: 0
      );
      final groups = iterStelliums(objs);
      expect(groups.length, 6);
    });
  });
}
