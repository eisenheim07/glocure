import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/connectivity_service.dart';

/// Cubit to manage connectivity state across the app
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(true);

  /// Check current connectivity status
  void checkConnectivity() {
    final isConnected = ConnectivityService().isConnected;
    emit(isConnected);
  }

  /// Update connectivity status
  void updateConnectivity(bool isConnected) {
    emit(isConnected);
  }

  /// Manual connectivity check
  Future<bool> verifyConnection() async {
    final isConnected = await ConnectivityService().checkConnectivity();
    emit(isConnected);
    return isConnected;
  }
}