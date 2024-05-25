import 'package:stardart/houses.dart';
import 'package:stardart/src/houses.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

const delta = 1e-6;

void main() {
  final ramc = radians(45.0);
  final mc = radians(47.47);
  final asc = radians(144.92);
  final theta = radians(42.0);
  final eps = radians(23.4523);
  group('Quadrant Systems', () {
    const base = [10, 11, 1, 2];

    compareBaseCusps(List<double> got, List<double> exp,
        {double delta = 1e-4}) {
      for (int i = 0; i < 4; i++) {
        final n = base[i];
        expect(got[n], closeTo(exp[i], delta));
      }
    }

    calculateAndCheck(HousesBuilder sys, List<double> exp,
        {double delta = 1e-4}) {
      final got = sys.calculateCusps();
      compareBaseCusps(got, exp, delta: 0.1);
    }

    test('Placidus', () {
      const exp = [83.21, 116.42, 167.08, 194.39];
      final sys =
          Placidus(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      calculateAndCheck(sys, exp, delta: 0.1);
    });

    test('Koch', () {
      const exp = [87.50, 117.46, 172.43, 200.09];
      final sys = Koch(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      calculateAndCheck(sys, exp);
    });

    test('Regiomontanus', () {
      const exp = [86.55, 119.56, 167.79, 193.66];
      final sys =
          Regiomontanus(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      calculateAndCheck(sys, exp);
    });
    test('Campanus', () {
      const exp = [77.90, 111.82, 174.04, 200.48];
      final sys =
          Campanus(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      calculateAndCheck(sys, exp);
    });
    test('Topocentric', () {
      const exp = [83.04, 116.25, 167.04, 194.43];
      final sys =
          Topocentric(ramc: ramc, eps: eps, theta: theta, asc: asc, mc: mc);
      calculateAndCheck(sys, exp);
    });
  });

  test('Morinus', () {
    final exp = [
      74.321,
      106.882,
      138.021,
      166.707,
      194.330,
      223.092,
      254.321,
      286.882,
      318.022,
      346.707,
      14.330,
      43.092
    ];
    final sys = Morinus(radians(345.559001), radians(23.430827));
    final got = sys.calculateCusps();
    for (int i = 0; i < 12; i++) {
      expect(got[i], closeTo(exp[i], 1e-2));
    }
  });

  group('Equal Systems', () {
    void compareResults(Equal sys, List<double> exp) {
      final got = sys.calculateCusps();
      for (int i = 0; i < 12; i++) {
        expect(got[i], closeTo(exp[i], delta));
      }
    }

    test('Sign-Cusp', () {
      final exp = List<double>.from([
        0.0,
        30.0,
        60.0,
        90.0,
        120.0,
        150.0,
        180.0,
        210.0,
        240.0,
        270.0,
        300.0,
        330.0
      ]);
      compareResults(Equal.signCusp(), exp);
    });

    test('Equal from Asc', () {
      final exp = List<double>.from([
        110.0,
        140.0,
        170.0,
        200.0,
        230.0,
        260.0,
        290.0,
        320.0,
        350.0,
        20.0,
        50.0,
        80.0
      ]);
      compareResults(Equal(HouseSystem.equalAsc, radians(110)), exp);
    });
    test('Equal from MC', () {
      final exp = List<double>.from([
        110.0,
        140.0,
        170.0,
        200.0,
        230.0,
        260.0,
        290.0,
        320.0,
        350.0,
        20.0,
        50.0,
        80.0
      ]);
      compareResults(Equal(HouseSystem.equalMC, radians(20), 9), exp);
    });
  });

  group('In house', () {
    test('Valid cusps', () {
      final cusps = [
        110.1572788,
        123.8606431,
        140.6604438,
        164.3171029,
        201.3030337,
        251.6072499,
        290.1572788,
        303.8606431,
        320.6604438,
        344.3171029,
        21.3030337,
        71.6072499
      ];
      const positions = [
        (312.4208864, 7),
        (310.2063276, 7),
        (297.0782202, 6),
        (295.2089981, 6),
        (177.9665740, 3),
        (46.9285345, 10),
        (334.6014315, 8),
        (164.0317672, 2),
        (229.9100725, 4),
        (165.8252621, 3)
      ];
      for (final p in positions) {
        expect(inHouse(p.$1, cusps), equals(p.$2));
      }
    });

    test('Inalid cusps', () {
      final cusps = [
        40.0,
        0.0,
        10.0,
        1.0,
        3.5,
        123.123,
        13.0,
        1.1,
        0.1,
        0.0,
        0.1,
        0.0
      ];
      expect(inHouse(180, cusps), equals(0));
    });
  });

  group('Factory', () {
    final names = [
      'Placidus',
      'Koch',
      'RegioMontanus',
      'Campanus',
      'Topocentric',
      'Morinus',
      'SignCusp',
      'EqualAsc',
      'EqualMC'
    ];

    for (final name in names) {
      test(
          name, () => expect(() => HouseSystem.forName(name), returnsNormally));
    }

    test('Throw StareError on invalid name', () {
      expect(() => HouseSystem.forName('The Best System Ever!'),
          throwsA(isStateError));
    });
  });
}
