import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/constants/permissions.dart';
import '../../entities/user_entity.dart';
import '../../repositories/user_repository.dart';

class CreateUser implements UseCase<UserEntity, CreateUserParams> {
  final UserRepository repository;

  CreateUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(CreateUserParams params) async {
    // Validate input
    final validationResult = _validateInput(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Check if username already exists
    final usernameExistsResult = await repository.isUsernameExists(
      params.username,
    );
    return usernameExistsResult.fold((failure) => Left(failure), (
      usernameExists,
    ) async {
      if (usernameExists) {
        return const Left(
          DuplicateEntryFailure(message: 'Username sudah digunakan'),
        );
      }

      // Check if email already exists
      final emailExistsResult = await repository.isEmailExists(params.email);
      return emailExistsResult.fold((failure) => Left(failure), (
        emailExists,
      ) async {
        if (emailExists) {
          return const Left(
            DuplicateEntryFailure(message: 'Email sudah digunakan'),
          );
        }

        // Create user entity
        final now = DateTime.now();
        final permissions = PermissionGroups.getPermissionsForRole(
          params.role.name,
        );

        final user = UserEntity(
          id: params.id,
          username: params.username.trim(),
          password: params.password,
          name: params.name.trim(),
          email: params.email.trim(),
          phone: params.phone?.trim(),
          avatarUrl: params.avatarUrl,
          role: params.role,
          isActive: params.isActive,
          createdAt: now,
          updatedAt: now,
          permissions: permissions,
        );

        // Create user in repository
        return await repository.createUser(user);
      });
    });
  }

  ValidationFailure? _validateInput(CreateUserParams params) {
    if (params.username.trim().isEmpty) {
      return const ValidationFailure(message: 'Username tidak boleh kosong');
    }

    if (params.username.trim().length > 50) {
      return const ValidationFailure(message: 'Username maksimal 50 karakter');
    }

    if (params.password.isEmpty) {
      return const ValidationFailure(message: 'Password tidak boleh kosong');
    }

    if (params.password.length < 6) {
      return const ValidationFailure(message: 'Password minimal 6 karakter');
    }

    if (params.name.trim().isEmpty) {
      return const ValidationFailure(message: 'Nama tidak boleh kosong');
    }

    if (params.name.trim().length > 100) {
      return const ValidationFailure(message: 'Nama maksimal 100 karakter');
    }

    if (params.email.trim().isEmpty) {
      return const ValidationFailure(message: 'Email tidak boleh kosong');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(params.email.trim())) {
      return const ValidationFailure(message: 'Format email tidak valid');
    }

    if (params.phone != null && params.phone!.isNotEmpty) {
      final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,13}$');
      if (!phoneRegex.hasMatch(
        params.phone!.replaceAll(RegExp(r'[\s-]'), ''),
      )) {
        return const ValidationFailure(
          message: 'Format nomor telepon tidak valid',
        );
      }
    }

    return null;
  }
}

class CreateUserParams extends Equatable {
  final String id;
  final String username;
  final String password;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;

  const CreateUserParams({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    password,
    name,
    email,
    phone,
    avatarUrl,
    role,
    isActive,
  ];
}
