import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/customer_model.dart';
import '../../services/api_service.dart';
import '../../utils/auth_storage.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  CustomerCubit() : super(CustomerInitial());

  /// Fetch customer data from API
  Future<void> fetchCustomer() async {
    emit(CustomerLoading());

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        emit(CustomerError('No authentication token found'));
        return;
      }

      final customer = await ApiService().getCustomer(token);

      if (customer == null) {
        emit(CustomerError('Failed to load customer data'));
        return;
      }

      emit(CustomerSuccess(customer));
    } catch (e) {
      emit(CustomerError('Error: ${e.toString()}'));
    }
  }

  /// Refresh customer data
  Future<void> refreshCustomer() async {
    await fetchCustomer();
  }

  /// Update customer in state (after address update from another screen)
  void updateCustomer(Customer customer) {
    emit(CustomerSuccess(customer));
  }
}
