import 'package:equatable/equatable.dart';

class SimInfoEntity extends Equatable {
  const SimInfoEntity({required this.slot, required this.carrier, required this.number});

  final int slot;
  final String carrier;
  final String number;

  @override
  List<Object?> get props => [slot, carrier, number];
}
