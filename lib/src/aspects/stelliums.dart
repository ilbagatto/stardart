library;

import 'dart:collection';

import 'package:astropc/mathutils.dart';
import 'package:stardart/src/charts/objects.dart';

/// Given chart objects, yield each stellium
/// or a single planet in case there are no other other closer than the gap
/// (**10°** by default).
///
/// Technicaly, that means partitioning of ecliptic positions with regard to
/// their angular distances.
Iterable<List<ChartObjectInfo>> iterStelliums(Iterable<ChartObjectInfo> objects,
    [double gap = 10]) sync* {
  // sort the ojects by longitude
  final sorted = List<ChartObjectInfo>.from(objects);
  sorted.sort((a, b) => a.position.lambda.compareTo(b.position.lambda));

  /// if there is no gap before the first element(s), adjust the starting point.
  final deq = Queue<ChartObjectInfo>.from(sorted);
  for (var i = 0; i < sorted.length; i++) {
    final first = deq.removeFirst();
    final last = deq.removeLast();
    if (shortestArc(first.position.lambda, last.position.lambda) <= gap) {
      deq.addFirst(first);
      deq.addFirst(last);
    } else {
      deq.addFirst(first);
      deq.add(last);
      break;
    }
  }

  final orderedObjs = List.from(deq);
  final lastIndex = orderedObjs.length - 1;
  List<ChartObjectInfo>? group;

  for (int i = 0; i <= lastIndex; i++) {
    final curr = orderedObjs[i];
    group ??= List.empty(growable: true);
    group.add(curr);
    if (i < lastIndex) {
      final next = orderedObjs[i + 1];
      if (diffAngle(curr.position.lambda, next.position.lambda) > gap) {
        yield group;
        group = null;
      }
    } else {
      yield group;
      group = null;
    }
  }
}
