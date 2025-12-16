// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:reputation_guardian/core/network/network_module.dart' as _i197;
import 'package:reputation_guardian/features/auth/data/datasources/auth_local_datasource.dart'
    as _i995;
import 'package:reputation_guardian/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i332;
import 'package:reputation_guardian/features/auth/data/repositories/auth_repository_impl.dart'
    as _i17;
import 'package:reputation_guardian/features/auth/domain/repositories/auth_repository.dart'
    as _i877;
import 'package:reputation_guardian/features/auth/domain/usecases/login_usecase.dart'
    as _i98;
import 'package:reputation_guardian/features/auth/domain/usecases/logout_usecase.dart'
    as _i891;
import 'package:reputation_guardian/features/auth/domain/usecases/register_usecase.dart'
    as _i111;
import 'package:reputation_guardian/features/auth/presentation/bloc/auth_bloc.dart'
    as _i665;
import 'package:reputation_guardian/features/dashboard/data/datasources/dashboard_local_datasource.dart'
    as _i853;
import 'package:reputation_guardian/features/dashboard/data/datasources/dashboard_remote_datasource.dart'
    as _i200;
import 'package:reputation_guardian/features/dashboard/data/repositories/dashboard_repository_impl.dart'
    as _i870;
import 'package:reputation_guardian/features/dashboard/domain/repositories/dashboard_repository.dart'
    as _i381;
import 'package:reputation_guardian/features/dashboard/domain/usecases/get_dashboard_usecase.dart'
    as _i487;
import 'package:reputation_guardian/features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i704;
import 'package:reputation_guardian/features/qr/data/datasources/qr_local_datasource.dart'
    as _i1068;
import 'package:reputation_guardian/features/qr/data/datasources/qr_remote_datasource.dart'
    as _i122;
import 'package:reputation_guardian/features/qr/data/repositories/qr_repository_impl.dart'
    as _i571;
import 'package:reputation_guardian/features/qr/domain/repositories/qr_repository.dart'
    as _i388;
import 'package:reputation_guardian/features/qr/domain/usecases/generate_qr_usecase.dart'
    as _i495;
import 'package:reputation_guardian/features/qr/presentation/bloc/qr_bloc.dart'
    as _i591;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => networkModule.secureStorage,
    );
    gh.factory<_i122.QRRemoteDataSource>(
      () => _i122.QRRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i200.DashboardRemoteDataSource>(
      () => _i200.DashboardRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i995.AuthLocalDataSource>(
      () => _i995.AuthLocalDataSourceImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i332.AuthRemoteDataSource>(
      () => _i332.AuthRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i853.DashboardLocalDataSource>(
      () => _i853.DashboardLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i381.DashboardRepository>(
      () => _i870.DashboardRepositoryImpl(
        remoteDataSource: gh<_i200.DashboardRemoteDataSource>(),
        localDataSource: gh<_i853.DashboardLocalDataSource>(),
      ),
    );
    gh.factory<_i1068.QRLocalDataSource>(
      () => _i1068.QRLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i877.AuthRepository>(
      () => _i17.AuthRepositoryImpl(
        remoteDataSource: gh<_i332.AuthRemoteDataSource>(),
        localDataSource: gh<_i995.AuthLocalDataSource>(),
      ),
    );
    gh.factory<_i487.GetDashboardUseCase>(
      () => _i487.GetDashboardUseCase(gh<_i381.DashboardRepository>()),
    );
    gh.factory<_i98.LoginUseCase>(
      () => _i98.LoginUseCase(gh<_i877.AuthRepository>()),
    );
    gh.factory<_i891.LogoutUseCase>(
      () => _i891.LogoutUseCase(gh<_i877.AuthRepository>()),
    );
    gh.factory<_i111.RegisterUseCase>(
      () => _i111.RegisterUseCase(gh<_i877.AuthRepository>()),
    );
    gh.factory<_i665.AuthBloc>(
      () => _i665.AuthBloc(
        loginUseCase: gh<_i98.LoginUseCase>(),
        registerUseCase: gh<_i111.RegisterUseCase>(),
        logoutUseCase: gh<_i891.LogoutUseCase>(),
      ),
    );
    gh.factory<_i388.QRRepository>(
      () => _i571.QRRepositoryImpl(
        gh<_i122.QRRemoteDataSource>(),
        gh<_i1068.QRLocalDataSource>(),
      ),
    );
    gh.factory<_i495.GenerateQRUseCase>(
      () => _i495.GenerateQRUseCase(gh<_i388.QRRepository>()),
    );
    gh.factory<_i704.DashboardBloc>(
      () => _i704.DashboardBloc(
        gh<_i487.GetDashboardUseCase>(),
        gh<_i853.DashboardLocalDataSource>(),
      ),
    );
    gh.factory<_i591.QRBloc>(() => _i591.QRBloc(gh<_i495.GenerateQRUseCase>()));
    return this;
  }
}

class _$NetworkModule extends _i197.NetworkModule {}
