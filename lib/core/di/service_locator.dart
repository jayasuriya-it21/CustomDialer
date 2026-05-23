import 'package:get_it/get_it.dart';

import '../../features/contacts/bloc/contacts_bloc.dart';
import '../../features/call/bloc/in_call_cubit.dart';
import '../../features/call/bloc/incoming_call_cubit.dart';
import '../../features/dialer/bloc/dialpad_cubit.dart';
import '../../features/recents/bloc/recents_bloc.dart';
import '../../features/recordings/bloc/recordings_cubit.dart';
import '../../features/search/bloc/search_cubit.dart';
import '../../features/settings/bloc/settings_cubit.dart';
import '../services/call_service.dart';
import '../services/contact_service.dart';
import '../services/contacts_repository.dart';
import '../services/dialer_repository.dart';
import '../services/favorites_service.dart';
import '../services/recording_service.dart';
import '../services/recents_repository.dart';
import '../services/search_repository.dart';
import '../theme/theme_cubit.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  if (!getIt.isRegistered<CallService>()) {
    getIt.registerLazySingleton<CallService>(CallService.new);
  }
  if (!getIt.isRegistered<ContactService>()) {
    getIt.registerLazySingleton<ContactService>(ContactService.new);
  }
  if (!getIt.isRegistered<FavoritesService>()) {
    getIt.registerLazySingleton<FavoritesService>(FavoritesService.new);
  }
  if (!getIt.isRegistered<RecordingService>()) {
    getIt.registerLazySingleton<RecordingService>(RecordingService.new);
  }
  if (!getIt.isRegistered<ThemeCubit>()) {
    getIt.registerLazySingleton<ThemeCubit>(ThemeCubit.new);
  }

  if (!getIt.isRegistered<ContactsRepository>()) {
    getIt.registerLazySingleton<ContactsRepository>(() => ContactsRepository(getIt<ContactService>()));
  }
  if (!getIt.isRegistered<ContactsBloc>()) {
    getIt.registerFactory<ContactsBloc>(() => ContactsBloc(getIt<ContactsRepository>()));
  }

  if (!getIt.isRegistered<RecentsRepository>()) {
    getIt.registerLazySingleton<RecentsRepository>(() => RecentsRepository(getIt<CallService>(), getIt<ContactsRepository>(), getIt<FavoritesService>()));
  }
  if (!getIt.isRegistered<RecentsBloc>()) {
    getIt.registerFactory<RecentsBloc>(() => RecentsBloc(getIt<RecentsRepository>()));
  }

  if (!getIt.isRegistered<DialerRepository>()) {
    getIt.registerLazySingleton<DialerRepository>(() => DialerRepository(getIt<ContactsRepository>(), getIt<CallService>(), getIt<ContactService>()));
  }
  if (!getIt.isRegistered<DialpadCubit>()) {
    getIt.registerFactory<DialpadCubit>(() => DialpadCubit(getIt<DialerRepository>()));
  }

  if (!getIt.isRegistered<SearchRepository>()) {
    getIt.registerLazySingleton<SearchRepository>(() => SearchRepository(getIt<ContactsRepository>(), getIt<CallService>(), getIt<ContactService>()));
  }
  if (!getIt.isRegistered<SearchCubit>()) {
    getIt.registerFactory<SearchCubit>(() => SearchCubit(getIt<SearchRepository>()));
  }

  if (!getIt.isRegistered<InCallCubit>()) {
    getIt.registerFactory<InCallCubit>(() => InCallCubit(getIt<CallService>(), getIt<RecordingService>()));
  }
  if (!getIt.isRegistered<IncomingCallCubit>()) {
    getIt.registerFactory<IncomingCallCubit>(() => IncomingCallCubit(getIt<CallService>(), getIt<ContactService>()));
  }

  if (!getIt.isRegistered<RecordingsCubit>()) {
    getIt.registerFactory<RecordingsCubit>(() => RecordingsCubit(getIt<RecordingService>()));
  }
  if (!getIt.isRegistered<SettingsCubit>()) {
    getIt.registerFactory<SettingsCubit>(() => SettingsCubit(getIt<ThemeCubit>(), getIt<CallService>(), getIt<RecordingService>()));
  }
}
