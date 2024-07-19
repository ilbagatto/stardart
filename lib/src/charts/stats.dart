import 'package:astropc/mathutils.dart';
import 'package:stardart/chart.dart';
import 'package:stardart/common.dart';
import 'package:stardart/src/charts/chart.dart';

class ChartStats implements ChartVisitor {
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

  @override
  void visit(BaseChart chart) {
    final planets = chart.objects.values.where((obj) =>
        obj.type.index >= 0 && obj.type.index <= ChartObjectType.plu.index);
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
