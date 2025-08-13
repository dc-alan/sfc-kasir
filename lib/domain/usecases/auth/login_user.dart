import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_entity.dart';
import '../../repositories/user_repository.dart';

class LoginUser implements UseCase<UserEntity?, LoginParams> {
  final UserRepository repository;

  LoginUser(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(LoginParams params) async {
    // Validate input
    if (params.username.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Username tidak boleh kosong'),
      );
    }

    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Password tidak boleh kosong'),
      );
    }

    // Authenticate user
    final result = await repository.authenticateUser(
      params.username.trim(),
      params.password,
    );

    return result.fold((failure) => Left(failure), (user) async {
      if (user == null) {
        return const Left(InvalidCredentialsFailure());
      }

      if (!user.isActive) {
        return const Left(UnauthorizedFailure(message: 'Akun tidak aktif'));
      }

      // Update last login
      await repository.updateLastLogin(user.id, DateTime.now());

      return Right(user);
    });
  }
}

class LoginParams extends Equatable {
  final String username;
  final String password;

  const LoginParams({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}
