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
  String toString() => name;

  final String name;
  final int idx;
}

/// Triplicities
enum Triplicity {
  fire('Fire'),
  earth('Earth'),
  air('Air'),
  water('Water');

  const Triplicity(this.name);

  @override
  String toString() => name;

  final String name;
}

/// Quadruplicities
enum Quadruplicity {
  cardinal('Cardinal'),
  fixed('Fixed'),
  mutable('Mutable');

  const Quadruplicity(this.name);

  @override
  String toString() => name;

  final String name;
}
