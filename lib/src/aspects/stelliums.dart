library;

import 'angles.dart';
import 'aspects.dart';

/// Given array of celestial points, yield each stellium
/// or a single planet in case there are no other other closer than the gap
/// (**10°** by default).
///
/// Technicaly that means partitioning of ecliptic positions with regard to
/// their angular distances.
Iterable<List<AspectedPoint>> iterStelliums(Iterable<AspectedPoint> positions,
    [double gap = 10]) sync* {
  final sorted = List<AspectedPoint>.from(positions);
  sorted.sort((a, b) => a.longitude.compareTo(b.longitude));

  final lastIndex = sorted.length - 1;
  List<AspectedPoint>? group;
  int index = 0;

  while (index <= lastIndex) {
    final curr = sorted[index];
    group ??= List.empty(growable: true);
    group.add(curr);
    if (index < lastIndex) {
      final next = sorted[index + 1];
      if (diffAngle(curr.longitude, next.longitude) > gap) {
        yield group;
        group = null;
      }
    } else {
      yield group;
      group = null;
    }
    index++;
  }
}
