import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import 'order_summary_state.dart';

class OrderSummaryCubit extends Cubit<OrderSummaryState> {
  OrderSummaryCubit() : super(OrderSummaryInitial());

  /// Initialize the screen
  void initialize() {
    emit(OrderSummaryLoading());
    // After initialization, emit loaded state
    emit(const OrderSummaryLoaded());
  }

  /// Toggle showing all products
  void toggleShowAllProducts() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(
        showAllProducts: !currentState.showAllProducts,
      ));
    }
  }

  /// Start refresh
  void startRefresh() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(isRefreshing: true));
    }
  }

  /// End refresh
  void endRefresh() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(isRefreshing: false));
    }
  }

  /// Fetch related products
  Future<void> fetchRelatedProducts(String productId) async {
    if (state is! OrderSummaryLoaded) return;
    
    final currentState = state as OrderSummaryLoaded;
    
    // Don't fetch if already loading
    if (currentState.isLoadingRelatedProducts) return;

    // Start loading
    emit(currentState.copyWith(isLoadingRelatedProducts: true));

    try {
      final products = await ApiService().getRelatedProducts(
        productId: productId,
        limit: 4,
      );

      emit(currentState.copyWith(
        isLoadingRelatedProducts: false,
        relatedProducts: products,
      ));
    } catch (e) {
      AppLogger.error('Error fetching related products: $e');
      emit(currentState.copyWith(isLoadingRelatedProducts: false));
    }
  }

  /// Clear related products
  void clearRelatedProducts() {
    if (state is OrderSummaryLoaded) {
      final currentState = state as OrderSummaryLoaded;
      emit(currentState.copyWith(relatedProducts: []));
    }
  }

  /// Reset to initial loaded state
  void reset() {
    emit(const OrderSummaryLoaded());
  }
}