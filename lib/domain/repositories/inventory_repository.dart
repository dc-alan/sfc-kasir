import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/inventory_entity.dart';

abstract class InventoryRepository {
  Future<Either<Failure, InventoryEntity>> getInventoryById(String id);
  Future<Either<Failure, InventoryEntity?>> getInventoryByProductId(
    String productId,
  );
  Future<Either<Failure, List<InventoryEntity>>> getAllInventory({
    PaginationParams? params,
  });
  Future<Either<Failure, List<InventoryEntity>>> getLowStockItems();
  Future<Either<Failure, List<InventoryEntity>>> getOutOfStockItems();
  Future<Either<Failure, List<InventoryEntity>>> getOverStockItems();
  Future<Either<Failure, InventoryEntity>> createInventory(
    InventoryEntity inventory,
  );
  Future<Either<Failure, InventoryEntity>> updateInventory(
    InventoryEntity inventory,
  );
  Future<Either<Failure, void>> deleteInventory(String id);
  Future<Either<Failure, List<InventoryEntity>>> searchInventory(
    String query, {
    PaginationParams? params,
  });
  Future<Either<Failure, void>> adjustStock(
    String productId,
    int quantity,
    String reason,
    String userId,
  );
  Future<Either<Failure, void>> updateStock(
    String productId,
    int newStock,
    String userId, {
    String? reason,
  });
  Future<Either<Failure, bool>> checkStockAvailability(
    String productId,
    int requiredQuantity,
  );
  Future<Either<Failure, void>> reserveStock(
    String productId,
    int quantity,
    String referenceId,
  );
  Future<Either<Failure, void>> releaseStock(
    String productId,
    int quantity,
    String referenceId,
  );
  Future<Either<Failure, double>> getTotalInventoryValue();
  Future<Either<Failure, int>> getTotalItemCount();
  Future<Either<Failure, Map<String, int>>> getStockStatusCounts();
  Stream<Either<Failure, List<InventoryEntity>>> watchInventory();
  Stream<Either<Failure, InventoryEntity?>> watchInventoryByProductId(
    String productId,
  );
}

abstract class StockMovementRepository {
  Future<Either<Failure, StockMovementEntity>> getMovementById(String id);
  Future<Either<Failure, List<StockMovementEntity>>> getAllMovements({
    PaginationParams? params,
  });
  Future<Either<Failure, List<StockMovementEntity>>> getMovementsByProductId(
    String productId, {
    PaginationParams? params,
  });
  Future<Either<Failure, List<StockMovementEntity>>> getMovementsByType(
    StockMovementType type, {
    PaginationParams? params,
  });
  Future<Either<Failure, List<StockMovementEntity>>> getMovementsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    PaginationParams? params,
  });
  Future<Either<Failure, StockMovementEntity>> createMovement(
    StockMovementEntity movement,
  );
  Future<Either<Failure, void>> deleteMovement(String id);
  Future<Either<Failure, List<StockMovementEntity>>> searchMovements(
    String query, {
    PaginationParams? params,
  });
  Future<Either<Failure, Map<StockMovementType, int>>> getMovementCountsByType(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, double>> getTotalMovementValue(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<StockMovementEntity>>> getRecentMovements({
    int limit = 10,
  });
  Stream<Either<Failure, List<StockMovementEntity>>> watchMovements();
  Stream<Either<Failure, List<StockMovementEntity>>> watchMovementsByProductId(
    String productId,
  );
}

abstract class LocationRepository {
  Future<Either<Failure, LocationEntity>> getLocationById(String id);
  Future<Either<Failure, List<LocationEntity>>> getAllLocations({
    PaginationParams? params,
  });
  Future<Either<Failure, List<LocationEntity>>> getActiveLocations();
  Future<Either<Failure, LocationEntity>> createLocation(
    LocationEntity location,
  );
  Future<Either<Failure, LocationEntity>> updateLocation(
    LocationEntity location,
  );
  Future<Either<Failure, void>> deleteLocation(String id);
  Future<Either<Failure, List<LocationEntity>>> searchLocations(String query);
  Future<Either<Failure, bool>> isLocationNameExists(
    String name, {
    String? excludeId,
  });
  Future<Either<Failure, int>> getLocationCount();
  Future<Either<Failure, void>> toggleLocationStatus(
    String locationId,
    bool isActive,
  );
  Future<Either<Failure, List<InventoryEntity>>> getInventoryByLocation(
    String locationId,
  );
  Stream<Either<Failure, List<LocationEntity>>> watchLocations();
  Stream<Either<Failure, LocationEntity?>> watchLocation(String id);
}
