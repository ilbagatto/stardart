import 'package:stardart/aspects.dart';
import 'package:test/test.dart';

const objects = [
  (name: 'Moon', longitude: 310.211118039121),
  (name: 'Sun', longitude: 312.430798112358),
  (name: 'Mercury', longitude: 297.078430402921),
  (name: 'Venus', longitude: 295.209360003483),
  (name: 'Mars', longitude: 177.966202541024),
  (name: 'Jupiter', longitude: 46.9290328362618),
  (name: 'Saturn', longitude: 334.601965217279),
  (name: 'Uranus', longitude: 164.031950787664),
  (name: 'Neptune', longitude: 229.922411342362),
  (name: 'Pluto', longitude: 165.825418322174)
];

final objNames = objects.map((e) => e.name).toList();

void testMethod(OrbsMethod method, Map<String, int> stats) {
  AspectsDetector aspd =
      AspectsDetector(orbsMethod: method, typeFlags: AspectType.major.value);

  for (final name in objNames) {
    final source = objects.firstWhere((e) => e.name == name);
    final targets = objects.where((e) => e.name != name).toList();
    final aspects = aspd.iterAspects(source, targets).toList();
    test('$name aspects with ${method.name}',
        () => expect(aspects.length, equals(stats[name]!)));
  }
}

void main() {
  group('Methods', () {
    group('Dariot', () {
      const Map<String, int> stats = {
        'Moon': 2,
        'Sun': 3,
        'Mercury': 2,
        'Venus': 3,
        'Mars': 2,
        'Jupiter': 5,
        'Saturn': 0,
        'Uranus': 3,
        'Neptune': 5,
        'Pluto': 3
      };
      testMethod(Dariot(), stats);
    });
    group('DeVore', () {
      const Map<String, int> stats = {
        'Moon': 1,
        'Sun': 2,
        'Mercury': 2,
        'Venus': 2,
        'Mars': 2,
        'Jupiter': 4,
        'Saturn': 0,
        'Uranus': 2,
        'Neptune': 1,
        'Pluto': 2
      };
      testMethod(DeVore(), stats);
    });
    group('ClassicWithAspectRatio', () {
      const Map<String, int> stats = {
        'Moon': 2,
        'Sun': 3,
        'Mercury': 2,
        'Venus': 3,
        'Mars': 2,
        'Jupiter': 5,
        'Saturn': 0,
        'Uranus': 3,
        'Neptune': 5,
        'Pluto': 3
      };
      testMethod(ClassicWithAspectRatio(), stats);
    });
  });

  group('Test Stelliums', () {
    test('Default gap', () {
      final groups = iterStelliums(objects).toList();
      expect(groups.length, equals(7));
    });
    test('Large gap', () {
      final groups = iterStelliums(objects, 15).toList();
      expect(groups.length, equals(5));
    });

    test('Zero gap', () {
      final groups = iterStelliums(objects, 0).toList();
      expect(groups.length, objects.length);
    });
  });
}
