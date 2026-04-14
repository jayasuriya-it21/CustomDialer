import 'package:flutter_bloc/flutter_bloc.dart';

class HomeNavCubit extends Cubit<int> {
  HomeNavCubit() : super(1);

  void changeTab(int index) {
    if (index == state) {
      return;
    }
    emit(index);
  }
}
