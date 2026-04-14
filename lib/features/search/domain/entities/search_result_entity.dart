import 'package:equatable/equatable.dart';

class SearchResultEntity extends Equatable {
  const SearchResultEntity({required this.name, required this.number, required this.source});

  final String name;
  final String number;
  final String source;

  bool get isContact => source == 'contact';
  String get displayName => name.isNotEmpty ? name : number;

  @override
  List<Object?> get props => [name, number, source];
}
