library;

import 'package:astropc/mathutils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:stardart/src/common.dart';

String formatLongitude(double x) {
  final vals = zdms(x);
  final sgn = ZodiacSign.values[vals.$1].name.substring(0, 3);
  return sprintf('%02d:%02d %s', [vals.$2, vals.$3, sgn]);
}

String formatLatitude(double x) {
  final vals = dms(x.abs());
  final sgn = x < 0 ? 'N' : 'S';
  return sprintf('%02d:%02d %s', [vals.$1, vals.$2, sgn]);
}

String formatGeoLat(double x) {
  final dir = x < 0 ? 'S' : 'N';
  final sexadecimal = dms(x.abs());
  return sprintf('%02d%s%02d', [sexadecimal.$1, dir, sexadecimal.$2]);
}

String formatGeoLon(double x) {
  final dir = x < 0 ? 'E' : 'W';
  final sexadecimal = dms(x.abs());
  return sprintf('%03d%s%02d', [sexadecimal.$1, dir, sexadecimal.$2]);
}
