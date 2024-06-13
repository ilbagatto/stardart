library;

/// Astrological influence.
enum Influence { neutral, negative, positive }

enum ZodiacSign {
  ari(0, 'Aries'),
  tau(1, 'Taurus'),
  gem(2, 'Gemini'),
  can(3, 'Cancer'),
  leo(4, 'Leo'),
  vir(5, 'Virgo'),
  lib(6, 'Libra'),
  sco(7, 'Scorpio'),
  sag(8, 'Sagittarius'),
  cap(9, 'Capricornus'),
  aqu(10, 'Aquarius'),
  pis(11, 'Pisces');

  const ZodiacSign(this.idx, this.name);

  @override
  String toString() {
    return name;
  }

  final String name;
  final int idx;
}

enum Triplicities { fire, earth, air, water }

enum Quadruplicities { cardinal, fixed, mutable }
