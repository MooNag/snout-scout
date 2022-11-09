// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FRCMatch _$FRCMatchFromJson(Map<String, dynamic> json) => FRCMatch(
      level: $enumDecodeNullable(_$TournamentLevelEnumMap, json['level']),
      description: json['description'] as String,
      number: json['number'] as int,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      blue: (json['blue'] as List<dynamic>).map((e) => e as int).toList(),
      red: (json['red'] as List<dynamic>).map((e) => e as int).toList(),
      results: json['results'] == null
          ? null
          : MatchResults.fromJson(json['results'] as Map<String, dynamic>),
      robot: (json['robot'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RobotMatchResults.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$FRCMatchToJson(FRCMatch instance) => <String, dynamic>{
      'number': instance.number,
      'level': _$TournamentLevelEnumMap[instance.level],
      'description': instance.description,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'blue': instance.blue,
      'red': instance.red,
      'results': instance.results,
      'robot': instance.robot,
    };

const _$TournamentLevelEnumMap = {
  TournamentLevel.None: 'None',
  TournamentLevel.Practice: 'Practice',
  TournamentLevel.Qualification: 'Qualification',
  TournamentLevel.Playoff: 'Playoff',
};
