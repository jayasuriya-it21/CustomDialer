import 'package:equatable/equatable.dart';

class CallLogEntity extends Equatable {
  const CallLogEntity({required this.id, required this.name, required this.number, required this.type, required this.date, required this.duration});

  final String id;
  final String name;
  final String number;
  final int type;
  final int date;
  final int duration;

  bool get isMissed => type == 3 || type == 5;
  String get displayName => name.isNotEmpty ? name : number;

  @override
  List<Object?> get props => [id, name, number, type, date, duration];
}
