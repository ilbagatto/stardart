# StarDart

Library of astronomical calculations specific to astrology. Aimed at
astrological software and services.

- [StarDart](#stardart)
  - [Features](#features)
  - [Getting started](#getting-started)
  - [Usage](#usage)
  - [Additional information](#additional-information)


## Features

* Accurate positions of **Sun**, **Moon** and the **10 planets**.
* Sensitive points: **Ascendant**, **Midheaven**, **Vertex**, **East Point**, **Lunar Node**.
* Houses:
  * *Placidus*
  * *Koch*
  * *Regio-Montanus*
  * *Campanus*
  * *Topocentric*
  * *Morinus*
  * *Equal* systems
* Aspects, calculated using flexible orbs options.
* Astrological Chart, based on all of the above. 

## Getting started

Add to pubspec.yaml of your project

```yaml
dependencies:
  stardart:
    git:
      url: https://github.com/ilbagatto/stardart.git
      ref: master
```

Then run:

```console
$ dart pub update
```


## Usage

```dart
import 'package:astropc/timeutils.dart';
import 'package:stardart/charts.dart';



final birthChart = BirthChart(
    name: 'Birth Chart',
    djd: julDay(2024, 5, 9.5); // Julian date for epoch 1900.0,
    place: (name: 'Sofia, Bulgaria', coords: Point(-23.32, 42.698)));

final sun = chart.objects[ChartObjectType.sun]; // Sun
final lng = sun.position.lambda; // longitude
final motion = sun.dailyMotion; // mean daily 
final house = sun.house; // in which house, Placidus system by default
```

For more detailed example see `example` directory.

## Additional information

All the calculations are based on [AstroPC](https://github.com/ilbagatto/astropc) library of astronomical calculations.
