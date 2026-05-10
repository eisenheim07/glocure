import 'dart:async';
import 'package:flutter/material.dart';
import '../cubits/payment_flow/payment_flow_cubit.dart';
import '../cubits/payment_flow/payment_flow_state.dart';
import '../models/cart_model.dart' as cart_model;
import '../models/customer_model.dart';
import '../models/top_products_model.dart';
import '../screens/payu_webview/payu_webview_screen.dart';
import '../screens/payment_status_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_logger.dart';
import 'payment_selection_bottom_sheet.dart';

/// Common Payment Flow Widget
/// Handles the complete payment flow for both cart and single product purchases
class CommonPaymentFlow extends StatelessWidget {
  final Customer customer;
  final cart_model.Cart? cart; // For cart-based purchases
  final TopProduct? product; // For single product purchases
  final ProductVariant? selectedVariant; // For single product purchases
  final int quantity; // For single product purchases
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const CommonPaymentFlow({
    super.key,
    required this.customer,
    this.cart,
    this.product,
    this.selectedVariant,
    this.quantity = 1,
    this.onSuccess,
    this.onError,
  }) : assert(
          (cart != null) || (product != null && selectedVariant != null),
          'Either cart or (product + selectedVariant) must be provided',
        );

  /// Start the payment flow
  static Future<void> startPaymentFlow({
    required BuildContext context,
    required Customer customer,
    cart_model.Cart? cart,
    TopProduct? product,
    ProductVariant? selectedVariant,
    int quantity = 1,
    VoidCallback? onSuccess,
    VoidCallback? onError,
    VoidCallback? onLoadingStart, // New callback for loading start
    VoidCallback? onLoadingEnd, // New callback for loading end
  }) async {
    // Validate customer and address
    final defaultAddress = customer.defaultAddress;
    if (defaultAddress == null || defaultAddress.zip == null || defaultAddress.zip!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address with pincode'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate cart or product
    if (cart != null && cart.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (product == null && cart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No product selected'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // For single product purchases, create a temporary cart for the bottom sheet
    cart_model.Cart? effectiveCart = cart;
    double? calculatedTotalWithShipping;

    if (cart == null && product != null && selectedVariant != null) {
      // Calculate item price and shipping charges for single product
      final itemPrice = double.parse(selectedVariant.priceV2.amount) * quantity;
      const shippingCharges = 99.0;
      final needsShipping = itemPrice < 1000;
      final totalPrice = needsShipping ? itemPrice + shippingCharges : itemPrice;
      calculatedTotalWithShipping = totalPrice;

      AppLogger.info(
          'Single product calculation: Item price: ₹$itemPrice, Shipping: ${needsShipping ? '₹$shippingCharges' : 'FREE'}, Total: ₹$totalPrice');

      effectiveCart = cart_model.Cart(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        discountCodes: [],
        lines: [
          cart_model.CartLine(
            id: 'temp-line-${DateTime.now().millisecondsSinceEpoch}',
            quantity: quantity,
            attributes: [],
            merchandise: cart_model.CartMerchandise(
              id: selectedVariant.id,
              title: selectedVariant.title,
              availableForSale: selectedVariant.availableForSale,
              priceV2: cart_model.Money(
                amount: selectedVariant.priceV2.amount,
                currencyCode: selectedVariant.priceV2.currencyCode,
              ),
              compareAtPriceV2: selectedVariant.compareAtPriceV2 != null
                  ? cart_model.Money(
                      amount: selectedVariant.compareAtPriceV2!.amount,
                      currencyCode: selectedVariant.compareAtPriceV2!.currencyCode,
                    )
                  : null,
              product: cart_model.CartProduct(
                id: product.id,
                title: product.title,
                handle: product.handle,
                imageUrl: product.images.isNotEmpty ? product.images.first.originalSrc : null,
              ),
            ),
          ),
        ],
        cost: cart_model.CartCost(
          subtotalAmount: cart_model.Money(
            amount: itemPrice.toString(),
            currencyCode: selectedVariant.priceV2.currencyCode,
          ),
          totalAmount: cart_model.Money(
            amount: totalPrice.toString(), // Include shipping charges in total
            currencyCode: selectedVariant.priceV2.currencyCode,
          ),
        ),
      );
    } else if (cart != null) {
      // Calculate shipping charges for cart-based orders
      final subtotal = double.tryParse(cart.cost?.subtotalAmount.amount ?? '0') ?? 0;
      const shippingCharges = 99.0;
      final needsShipping = subtotal < 1000;
      calculatedTotalWithShipping = needsShipping ? subtotal + shippingCharges : subtotal;

      AppLogger.info(
          'Cart calculation: Subtotal: ₹$subtotal, Shipping: ${needsShipping ? '₹$shippingCharges' : 'FREE'}, Total: ₹$calculatedTotalWithShipping');
    }

    if (effectiveCart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items to purchase'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show payment selection bottom sheet
    PaymentSelectionBottomSheet.show(
      context,
      pincode: defaultAddress.zip!,
      cart: effectiveCart,
      customer: customer,
      onPaymentSelected: (paymentMethod) async {
        AppLogger.info('Payment method selected: $paymentMethod');
        AppLogger.info('Starting payment flow with method: $paymentMethod');

        // Create PaymentFlowCubit for this flow
        final paymentFlowCubit = PaymentFlowCubit();

        // Store the calculated total for PayU
        final totalForPayU = calculatedTotalWithShipping;

        // Trigger loading start callback
        onLoadingStart?.call();

        // Set up a stream subscription to listen for state changes
        late StreamSubscription subscription;
        subscription = paymentFlowCubit.stream.listen((state) async {
          if (state is PaymentFlowOrderCreated) {
            // Cancel subscription
            subscription.cancel();

            // Trigger loading end callback
            onLoadingEnd?.call();

            AppLogger.success('Order created: ${state.order.id}');

            // Handle based on payment method
            if (state.paymentMethod == 'Pre-paid') {
              // Navigate to PayU WebView with push (not pushReplacement) to receive result
              AppLogger.info('Navigating to PayU WebView for order: ${state.order.id} with total: ₹${state.totalAmountWithShipping}');
              AppLogger.info('Payment method confirmed as Pre-paid, proceeding to PayU WebView');

              // For cart purchases, use first product from cart
              // For single product purchases, use the provided product
              TopProduct paymentProduct;
              ProductVariant paymentVariant;
              int paymentQuantity;

              if (product != null && selectedVariant != null) {
                // Single product purchase
                paymentProduct = product;
                paymentVariant = selectedVariant;
                paymentQuantity = quantity;
              } else if (effectiveCart != null && effectiveCart.lines.isNotEmpty) {
                // Cart purchase - convert first cart item to TopProduct and ProductVariant
                final firstLine = effectiveCart.lines.first;
                final merchandise = firstLine.merchandise;
                
                if (merchandise == null) {
                  AppLogger.error('Cart merchandise is null');
                  onError?.call();
                  return;
                }
                
                // Convert CartMerchandise to ProductVariant
                // Note: Money types are different between cart_model and top_products_model
                paymentVariant = ProductVariant(
                  id: merchandise.id,
                  title: merchandise.title,
                  sku: merchandise.sku,
                  priceV2: Money(
                    amount: merchandise.priceV2.amount,
                    currencyCode: merchandise.priceV2.currencyCode,
                  ),
                  compareAtPriceV2: merchandise.compareAtPriceV2 != null
                      ? Money(
                          amount: merchandise.compareAtPriceV2!.amount,
                          currencyCode: merchandise.compareAtPriceV2!.currencyCode,
                        )
                      : null,
                  availableForSale: merchandise.availableForSale,
                );
                
                // Create minimal TopProduct for payment
                paymentProduct = TopProduct(
                  id: merchandise.product.id,
                  title: merchandise.product.title,
                  description: '',
                  handle: merchandise.product.handle,
                  images: merchandise.product.imageUrl != null
                      ? [
                          ProductImage(
                            originalSrc: merchandise.product.imageUrl!,
                            altText: merchandise.product.imageAlt,
                          )
                        ]
                      : [],
                  variants: [paymentVariant],
                  productType: '',
                  vendor: '',
                  tags: [],
                  createdAt: '',
                  updatedAt: '',
                  onlineStoreUrl: null,
                );
                
                paymentQuantity = firstLine.quantity;
              } else {
                AppLogger.error('No product or cart available for payment');
                onError?.call();
                return;
              }

              // Use push to receive the result from PayU WebView
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PayUWebViewScreen(
                    customer: customer,
                    product: paymentProduct,
                    selectedVariant: paymentVariant,
                    quantity: paymentQuantity,
                    onSuccess: (data) {
                      AppLogger.success('✅ Payment successful from WebView: $data');
                      // Return success result
                      Navigator.pop(context, {
                        'status': 'success',
                        'payuData': data,
                      });
                    },
                    onFailure: (data) {
                      AppLogger.error('❌ Payment failed/cancelled from WebView: $data');
                      // Return failure/cancelled result - preserve the actual status
                      final actualStatus = data['status'] ?? 'failed';
                      Navigator.pop(context, {
                        'status': actualStatus, // Could be 'failed' or 'cancelled'
                        'payuData': data,
                      });
                    },
                  ),
                ),
              );

              // Handle PayU result
              if (result != null && context.mounted) {
                AppLogger.info('PayU WebView returned result: $result');

                // Log PayU data if available
                if (result['payuData'] != null) {
                  AppLogger.info('PayU Data: ${result['payuData']}');
                }

                _handlePaymentResult(context, result, state.order, paymentFlowCubit, onSuccess, onLoadingStart, onLoadingEnd, product != null);
              } else if (context.mounted) {
                // User cancelled or closed PayU screen without triggering callbacks
                AppLogger.info('PayU WebView screen closed without result');
                
                // Stop loading
                onLoadingEnd?.call();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment was cancelled'),
                    backgroundColor: AppColors.warning,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              // COD success - navigate to payment status screen
              AppLogger.info('COD order successful, navigating to payment status');
              AppLogger.info('Payment method confirmed as COD: ${state.paymentMethod}');
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentStatusScreen(
                      status: 'success',
                      order: state.order,
                      payuData: null, // No PayU data for COD
                      isFromSingleProduct: product != null, // Pass the flag
                    ),
                  ),
                );
                onSuccess?.call();
              }
            }
          } else if (state is PaymentFlowError) {
            // Cancel subscription
            subscription.cancel();

            // Trigger loading end callback
            onLoadingEnd?.call();

            AppLogger.error('Payment flow error: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create order: ${state.message}'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
            onError?.call();
          }
        });

        try {
          if (cart != null) {
            // Cart-based order
            await paymentFlowCubit.createOrder(
              cart: cart!,
              customer: customer,
              paymentMethod: paymentMethod,
            );
          } else if (product != null && selectedVariant != null) {
            // Single product order
            await paymentFlowCubit.createSingleProductOrder(
              product: product,
              selectedVariant: selectedVariant,
              customer: customer,
              paymentMethod: paymentMethod,
              quantity: quantity,
            );
          }
        } catch (e) {
          // Cancel subscription
          subscription.cancel();

          // Trigger loading end callback
          onLoadingEnd?.call();

          AppLogger.error('Payment flow exception: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create order: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
          onError?.call();
        }
      },
    );
  }

  /// Handle payment result from PayU
  static void _handlePaymentResult(
    BuildContext context,
    dynamic result,
    order,
    PaymentFlowCubit paymentFlowCubit,
    VoidCallback? onSuccess,
    VoidCallback? onLoadingStart, // Add loading callbacks
    VoidCallback? onLoadingEnd,
    bool isFromSingleProduct, // Add flag to indicate single product purchase
  ) async {
    if (result == null) return;

    final status = result['status']?.toString().toLowerCase() ?? 'cancelled';

    AppLogger.info('PayU payment result received: $status');

    // Check if context is still mounted before proceeding
    if (!context.mounted) {
      AppLogger.warning('Context no longer mounted, skipping payment result handling');
      return;
    }

    // Show shimmer on the original screen while processing result
    onLoadingStart?.call();

    if (status == 'success') {
      // Payment successful - update order status
      AppLogger.success('Payment successful!');
      try {
        await paymentFlowCubit.updateOrderStatus(
          orderId: order.id!,
          financialStatus: 'paid',
        );
      } catch (e) {
        AppLogger.error('Failed to update order status: $e');
      }
    }

    // Add a delay to show the shimmer effect on the original screen
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if context is still mounted before navigation
    if (!context.mounted) {
      AppLogger.warning('Context no longer mounted, skipping navigation');
      return;
    }

    // Navigate to payment status screen (shimmer continues in background)
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusScreen(
            status: status,
            order: order,
            payuData: result, // Pass the complete PayU result data
            isFromSingleProduct: isFromSingleProduct, // Pass the flag
          ),
        ),
      );

      // Stop shimmer in background after navigation (user won't see this)
      Future.delayed(const Duration(milliseconds: 500), () {
        onLoadingEnd?.call();
      });

      if (status == 'success') {
        onSuccess?.call();
      }
    } catch (e) {
      AppLogger.error('Failed to navigate to payment status screen: $e');
      // Fallback: stop shimmer and try to pop back
      onLoadingEnd?.call();
      if (context.mounted) {
        try {
          Navigator.pop(context);
        } catch (popError) {
          AppLogger.error('Failed to pop back: $popError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is primarily used for static methods
    // The actual UI is handled by the static methods
    return const SizedBox.shrink();
  }
}
