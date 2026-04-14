import 'package:get_it/get_it.dart';

import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/domain/usecases/get_contacts_usecase.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/call/presentation/bloc/in_call_cubit.dart';
import '../../features/call/presentation/bloc/incoming_call_cubit.dart';
import '../../features/dialer/data/repositories/dialer_repository_impl.dart';
import '../../features/dialer/domain/repositories/dialer_repository.dart';
import '../../features/dialer/domain/usecases/load_dialer_data_usecase.dart';
import '../../features/dialer/presentation/bloc/dialpad_cubit.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/get_favorites_usecase.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/recents/data/repositories/recents_repository_impl.dart';
import '../../features/recents/domain/repositories/recents_repository.dart';
import '../../features/recents/domain/usecases/delete_call_log_usecase.dart';
import '../../features/recents/domain/usecases/get_recents_usecase.dart';
import '../../features/recents/presentation/bloc/recents_bloc.dart';
import '../../features/recordings/presentation/bloc/recordings_cubit.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/search_contacts_and_logs_usecase.dart';
import '../../features/search/presentation/bloc/search_cubit.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';
import '../../services/call_service.dart';
import '../../services/contact_service.dart';
import '../../services/favorites_service.dart';
import '../../services/recording_service.dart';
import '../../theme/theme_provider.dart';

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
  if (!getIt.isRegistered<ThemeProvider>()) {
    getIt.registerLazySingleton<ThemeProvider>(ThemeProvider.new);
  }

  if (!getIt.isRegistered<ContactsRepository>()) {
    getIt.registerLazySingleton<ContactsRepository>(() => ContactsRepositoryImpl(getIt<ContactService>()));
  }
  if (!getIt.isRegistered<GetContactsUseCase>()) {
    getIt.registerLazySingleton<GetContactsUseCase>(() => GetContactsUseCase(getIt<ContactsRepository>()));
  }
  if (!getIt.isRegistered<ContactsBloc>()) {
    getIt.registerFactory<ContactsBloc>(() => ContactsBloc(getIt<GetContactsUseCase>()));
  }

  if (!getIt.isRegistered<FavoritesRepository>()) {
    getIt.registerLazySingleton<FavoritesRepository>(() => FavoritesRepositoryImpl(getIt<ContactsRepository>(), getIt<FavoritesService>()));
  }
  if (!getIt.isRegistered<GetFavoritesUseCase>()) {
    getIt.registerLazySingleton<GetFavoritesUseCase>(() => GetFavoritesUseCase(getIt<FavoritesRepository>()));
  }
  if (!getIt.isRegistered<FavoritesBloc>()) {
    getIt.registerFactory<FavoritesBloc>(() => FavoritesBloc(getIt<GetFavoritesUseCase>()));
  }

  if (!getIt.isRegistered<RecentsRepository>()) {
    getIt.registerLazySingleton<RecentsRepository>(() => RecentsRepositoryImpl(getIt<CallService>(), getIt<ContactsRepository>(), getIt<FavoritesService>()));
  }
  if (!getIt.isRegistered<GetRecentsUseCase>()) {
    getIt.registerLazySingleton<GetRecentsUseCase>(() => GetRecentsUseCase(getIt<RecentsRepository>()));
  }
  if (!getIt.isRegistered<DeleteCallLogUseCase>()) {
    getIt.registerLazySingleton<DeleteCallLogUseCase>(() => DeleteCallLogUseCase(getIt<RecentsRepository>()));
  }
  if (!getIt.isRegistered<RecentsBloc>()) {
    getIt.registerFactory<RecentsBloc>(() => RecentsBloc(getIt<GetRecentsUseCase>(), getIt<DeleteCallLogUseCase>()));
  }

  if (!getIt.isRegistered<DialerRepository>()) {
    getIt.registerLazySingleton<DialerRepository>(() => DialerRepositoryImpl(getIt<ContactsRepository>(), getIt<CallService>(), getIt<ContactService>()));
  }
  if (!getIt.isRegistered<LoadDialerDataUseCase>()) {
    getIt.registerLazySingleton<LoadDialerDataUseCase>(() => LoadDialerDataUseCase(getIt<DialerRepository>()));
  }
  if (!getIt.isRegistered<DialpadCubit>()) {
    getIt.registerFactory<DialpadCubit>(() => DialpadCubit(getIt<LoadDialerDataUseCase>(), getIt<DialerRepository>()));
  }

  if (!getIt.isRegistered<SearchRepository>()) {
    getIt.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(getIt<ContactsRepository>(), getIt<CallService>(), getIt<ContactService>()));
  }
  if (!getIt.isRegistered<SearchContactsAndLogsUseCase>()) {
    getIt.registerLazySingleton<SearchContactsAndLogsUseCase>(() => SearchContactsAndLogsUseCase(getIt<SearchRepository>()));
  }
  if (!getIt.isRegistered<SearchCubit>()) {
    getIt.registerFactory<SearchCubit>(() => SearchCubit(getIt<SearchContactsAndLogsUseCase>(), getIt<SearchRepository>()));
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
    getIt.registerFactory<SettingsCubit>(() => SettingsCubit(getIt<ThemeProvider>(), getIt<CallService>(), getIt<RecordingService>()));
  }
}
