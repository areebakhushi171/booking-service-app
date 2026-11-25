import 'package:bookease/features/customer/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:bookease/features/customer/favorites/data/repositories/favorites_repository.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remote;

  FavoritesRepositoryImpl(this._remote);

  @override
  Future<List<ServiceModel>> getFavoriteServices() async {
    return await _remote.fetchFavoriteServices();
  }

  @override
  Future<void> addFavorite(String serviceId) async {
    await _remote.addFavorite(serviceId);
  }

  @override
  Future<void> removeFavorite(String serviceId) async {
    await _remote.removeFavorite(serviceId);
  }
}
