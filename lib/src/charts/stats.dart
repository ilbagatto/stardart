import 'package:astropc/mathutils.dart';
import 'package:stardart/charts.dart';
import 'package:stardart/common.dart';

class ChartStats {
  final Map<Triplicity, List<ChartObjectType>> _triplicities = {
    Triplicity.fire: [],
    Triplicity.earth: [],
    Triplicity.air: [],
    Triplicity.water: []
  };
  final Map<Quadruplicity, List<ChartObjectType>> _quadruplicities = {
    Quadruplicity.cardinal: [],
    Quadruplicity.fixed: [],
    Quadruplicity.mutable: []
  };

  void visit(BaseChart chart) {
    final planets = chart.objects.values.where((obj) =>
        obj.type.index >= 0 && obj.type.index <= ChartObjectType.pluto.index);
    for (final obj in planets) {
      final id = obj.type;
      final (z, _, _, _) = zdms(obj.position.lambda);
      final tripl = Triplicity.values[z % 4];
      _triplicities[tripl]!.add(id);
      final quadr = Quadruplicity.values[z % 3];
      _quadruplicities[quadr]!.add(id);
    }
  }

  Map<Triplicity, List<ChartObjectType>> get triplicities => _triplicities;
  Map<Quadruplicity, List<ChartObjectType>> get quadruplicities =>
      _quadruplicities;
}
