import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductEntity>> getProductById(String id);
  Future<Either<Failure, ProductEntity?>> getProductBySku(String sku);
  Future<Either<Failure, ProductEntity?>> getProductByBarcode(String barcode);
  Future<Either<Failure, List<ProductEntity>>> getAllProducts({
    PaginationParams? params,
  });
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String categoryId, {
    PaginationParams? params,
  });
  Future<Either<Failure, ProductEntity>> createProduct(ProductEntity product);
  Future<Either<Failure, ProductEntity>> updateProduct(ProductEntity product);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    String query, {
    PaginationParams? params,
  });
  Future<Either<Failure, bool>> isSkuExists(String sku, {String? excludeId});
  Future<Either<Failure, bool>> isBarcodeExists(
    String barcode, {
    String? excludeId,
  });
  Future<Either<Failure, int>> getProductCount();
  Future<Either<Failure, List<ProductEntity>>> getActiveProducts();
  Future<Either<Failure, List<ProductEntity>>> getLowStockProducts();
  Future<Either<Failure, List<ProductEntity>>> getTopSellingProducts({
    int limit = 10,
  });
  Future<Either<Failure, void>> toggleProductStatus(
    String productId,
    bool isActive,
  );
  Future<Either<Failure, void>> bulkUpdateProducts(
    List<ProductEntity> products,
  );
  Stream<Either<Failure, List<ProductEntity>>> watchProducts();
  Stream<Either<Failure, ProductEntity?>> watchProduct(String id);
}

abstract class ProductCategoryRepository {
  Future<Either<Failure, ProductCategoryEntity>> getCategoryById(String id);
  Future<Either<Failure, List<ProductCategoryEntity>>> getAllCategories({
    PaginationParams? params,
  });
  Future<Either<Failure, List<ProductCategoryEntity>>> getRootCategories();
  Future<Either<Failure, List<ProductCategoryEntity>>> getSubCategories(
    String parentId,
  );
  Future<Either<Failure, ProductCategoryEntity>> createCategory(
    ProductCategoryEntity category,
  );
  Future<Either<Failure, ProductCategoryEntity>> updateCategory(
    ProductCategoryEntity category,
  );
  Future<Either<Failure, void>> deleteCategory(String id);
  Future<Either<Failure, List<ProductCategoryEntity>>> searchCategories(
    String query,
  );
  Future<Either<Failure, bool>> isCategoryNameExists(
    String name, {
    String? excludeId,
    String? parentId,
  });
  Future<Either<Failure, int>> getCategoryCount();
  Future<Either<Failure, int>> getProductCountByCategory(String categoryId);
  Future<Either<Failure, void>> toggleCategoryStatus(
    String categoryId,
    bool isActive,
  );
  Stream<Either<Failure, List<ProductCategoryEntity>>> watchCategories();
  Stream<Either<Failure, ProductCategoryEntity?>> watchCategory(String id);
}
