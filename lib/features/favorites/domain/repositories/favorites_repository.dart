import '../../../contacts/domain/entities/contact_entity.dart';

abstract class FavoritesRepository {
  Future<List<ContactEntity>> getFavorites({bool forceRefresh = false});
}
