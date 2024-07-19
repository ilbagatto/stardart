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

enum ChartObjectType {
  moo("Moon"),
  sun("Sun"),
  mer("Mercury"),
  ven("Venus"),
  mar("Mars"),
  jup("Jupiter"),
  sat("Saturn"),
  ura("Uranus"),
  nep("Neptune"),
  plu("Pluto"),
  nnd("Lunar Node");

  const ChartObjectType(this.name);

  @override
  String toString() => name;

  static ChartObjectType forName(String name) {
    switch (name.toLowerCase()) {
      case 'moon':
        return moo;
      case 'sun':
        return sun;
      case 'mercury':
        return mer;
      case 'venus':
        return ven;
      case 'mars':
        return mar;
      case 'jupiter':
        return jup;
      case 'saturn':
        return sat;
      case 'uranus':
        return ura;
      case 'neptune':
        return nep;
      case 'pluto':
        return plu;
      case 'lunar node':
        return nnd;
      default:
        throw ('Unknown object: $name');
    }
  }

  final String name;
}
