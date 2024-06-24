import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:astropc/mathutils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:astropc/timeutils.dart';
import 'package:intl/intl.dart';
import 'package:stardart/chart.dart';
import 'package:stardart/common.dart';
import 'package:stardart/houses.dart';
import 'package:stardart/utils.dart';

final dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');
final geoLatRegexp = RegExp(
    r"^((?:[0-8][0-9]|\d))\s*([N|S])\s*([0-5][0-9]|\d)$",
    caseSensitive: false);
final geoLngRegexp = RegExp(
    r"^((?:[0-1][0-7][0-9]|\d{1,2}))\s*([W|E])\s*([0-5][0-9]|\d)$",
    caseSensitive: false);

String getUsage(parser) {
  return '''
Julian Date Calculator

birthchart [OPTIONS]

OPTIONS

${parser.usage}

Example:
birthchart --datetime="1965-02-01 11:46" --lat="55N45" --lng="37E35"
''';
}

(int d, int m, int sgn) parseGeo(String input, RegExp re) {
  try {
    final match = re.firstMatch(input);
    // degrees
    final dStr = match?.group(1);
    if (dStr == null) {
      throw ();
    }
    int d = int.parse(dStr);

    // minutes
    final mStr = match?.group(3);
    if (mStr == null) {
      throw ();
    }
    int m = int.parse(mStr);

    // direction
    String? sStr = match?.group(2);
    if (sStr == null) {
      throw ();
    }
    sStr = sStr.toUpperCase();
    final sgn = sStr == 'S' || sStr == 'E' ? -1 : 1;
    return (d, m, sgn);
  } catch (_) {
    throw 'Unexpected value: "$input"';
  }
}

void displayPlanets(BaseChart chart) {
  for (final id in ChartObjectType.values) {
    final obj = chart.objects[id]!;
    final pos = obj.position;
    final rx = obj.dailyMotion < 0 ? 'r' : ' ';
    String row = sprintf("%-12s %s %s | %s | %2d", [
      obj.type.name,
      rx,
      formatLongitude(pos.lambda),
      formatLatitude(pos.beta),
      obj.house + 1
    ]);
    print(row);
  }
}

void displayAspects(BaseChart chart) {
  for (final id in ChartObjectType.values) {
    final obj = chart.objects[id]!;
    final asps = chart
        .aspectsTo(id)
        .map((a) => '${a.aspect.briefName} ${a.target.name.substring(0, 3)}')
        .toList();
    final cols = asps.isNotEmpty ? asps.join(' ') : ' - ';
    String row = sprintf('%-12s %s', [obj.type.name, cols]);
    print(row);
  }
}

void displayHouses(BaseChart chart) {
  for (var i = 0; i < 12; i++) {
    final x = chart.houses[i];
    final objs = ChartObjectType.values
        .map((id) => chart.objects[id])
        .where((o) => o!.house == i)
        .map((o) => o!.type.name.substring(0, 3))
        .join(', ');
    final row = sprintf('%2d. %s | %s', [i + 1, formatLongitude(x), objs]);
    print(row);
  }
}

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h',
        negatable: false,
        defaultsTo: false,
        help: 'Displays this help information')
    ..addOption('datetime',
        abbr: 'd',
        valueHelp: 'ISO 8601 + RFC 3339',
        defaultsTo: dateTimeFormatter.format(DateTime.now().toUtc()),
        help: 'UTC Date and time')
    ..addOption('lat',
        abbr: 'l',
        valueHelp: 'DD[N|S]MM',
        defaultsTo: '51N49',
        help: 'Geographical latitude')
    ..addOption('lng',
        abbr: 'g',
        valueHelp: 'DDD[W|E]MM',
        defaultsTo: '000W00',
        help: 'Geographical longitude')
    ..addOption('houses',
        abbr: 'o',
        allowed: [
          'Placidus',
          'Koch',
          'RegioMontanus',
          'Campanus',
          'Topocentric',
          'Morinus',
          'SignCusp',
          'EqualAsc',
          'EqualMC'
        ],
        defaultsTo: 'Placidus',
        help: 'Houses system')
    ..addOption('view',
        abbr: 'v',
        allowed: ['planets', 'aspects', 'houses', 'data'],
        defaultsTo: 'planets',
        help: 'Information to display',
        allowedHelp: {
          'planets': 'Planetary positions',
          'aspects': 'Table of aspects',
          'houses': 'Houses cusps'
        })
    ..addSeparator('-------');

  try {
    final argResults = parser.parse(arguments);
    if (argResults['help']) {
      print(getUsage(parser));
      exit(exitCode);
    }

    final civil = DateTime.parse(argResults['datetime']);
    print('UTC: ${civil.toString()}');
    final hm = civil.hour + (civil.minute + civil.second / 60) / 60;
    final djd = julDay(civil.year, civil.month, civil.day + hm / 24);
    final jd = djd + djdToJd;
    print('Julian Date: ${jd.toStringAsFixed(8)}');

    final lat = parseGeo(argResults['lat'], geoLatRegexp);
    final lng = parseGeo(argResults['lng'], geoLngRegexp);

    final latDir = lat.$3 < 0 ? 'S' : 'N';
    final lngDir = lng.$3 < 0 ? 'E' : 'E';
    print(sprintf("lat: %02d%s%02d, lng: %03d%s%02d",
        [lat.$1, latDir, lat.$2, lng.$1, lngDir, lng.$2]));
    final geoLon = ddd(lng.$1, lng.$2) * lng.$3;
    final geoLat = ddd(lat.$1, lat.$2) * lat.$3;

    final settings = (
      houses: HouseSystem.forName(argResults['houses']),
      orbs: defaultChartSettings.orbs,
      trueNode: true,
      aspectTypes: 0x1
    );

    final birthChart = BaseChart.forDJDAndPlace(
        djd: djd, geoCoords: Point(geoLon, geoLat), settings: settings);

    print('${birthChart.houseSystem} houses');
    print('Orbs: ${birthChart.orbsMethod}');
    print('\n');
    switch (argResults['view']) {
      case "planets":
        displayPlanets(birthChart);
      case "aspects":
        displayAspects(birthChart);
      case "houses":
        displayHouses(birthChart);

      default:
        throw UnsupportedError(
            'View "${argResults['view']}" is not supported yet');
    }
  } catch (e) {
    print(e);
    exitCode = 1;
  }
}
