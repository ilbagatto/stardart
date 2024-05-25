library;

/// Angle `b - a`, accounting for circular values.
/// Parameters a and b should be in the range `0..360`. The
/// result will be in the range `-180..180`.
///
/// This allows us to directly compare angles which cross through 0:
/// `359 degrees... 0 degrees... 1 degree...` etc.
///
/// [a] is the first angle, in arc-degrees
/// [b] is the second angle, in arc-degrees
double diffAngle(double a, double b) {
  final x = (b < a) ? b + 360 - a : b - a;
  return x > 180 ? x - 360 : x;
}
