import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/product_entity.dart';
import '../../repositories/product_repository.dart';

class GetAllProducts implements UseCase<List<ProductEntity>, PaginationParams> {
  final ProductRepository repository;

  GetAllProducts(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
    PaginationParams params,
  ) async {
    return await repository.getAllProducts(params: params);
  }
}
