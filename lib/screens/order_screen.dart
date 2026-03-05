import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'package:glocure/cubits/orders/orders_cubit.dart';
import 'package:glocure/cubits/orders/orders_state.dart';
import 'package:glocure/models/shopify_order_model.dart';
import 'main_navigation_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
    
    // Initialize orders when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersCubit>().initializeOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _fetchDataForTab(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
    _fetchDataForTab(index);
  }

  void _fetchDataForTab(int index) {
    final cubit = context.read<OrdersCubit>();
    switch (index) {
      case 0:
        cubit.showAllTab();
        break;
      case 1:
        cubit.showPendingTab();
        break;
      case 2:
        cubit.showClosedTab();
        break;
      case 3:
        cubit.showCancelledTab();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: CustomAppBar(
        type: AppBarType.full,
        showBackButton: true,
        onBackPressed: () {
          MainNavigationScreen.navigateToHome(context);
        },
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF5C9A),
              unselectedLabelColor: const Color(0xFF777777),
              indicatorColor: const Color(0xFFFF5C9A),
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              isScrollable: false,
              onTap: _onTabTapped,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Closed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          
          // Orders Content with PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                _OrdersTabContent(tabName: 'All'),
                _OrdersTabContent(tabName: 'Pending'),
                _OrdersTabContent(tabName: 'Closed'),
                _OrdersTabContent(tabName: 'Cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Single content widget that always shows current state
class _OrdersTabContent extends StatelessWidget {
  final String tabName;

  const _OrdersTabContent({required this.tabName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return _buildShimmerEffect();
        } else if (state is OrdersError) {
          return _buildErrorState(context, state.message);
        } else if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return _buildEmptyState(state.currentTab);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<OrdersCubit>().refreshOrders(),
            color: const Color(0xFFFF5C9A),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                return _OrderCard(order: state.orders[index]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          period: const Duration(milliseconds: 1200),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),
            const Text(
              'Error loading orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF777777),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<OrdersCubit>().refreshOrders(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String currentTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),
            Text(
              'No ${currentTab.toLowerCase()} orders',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${currentTab.toLowerCase()} orders will appear here',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF777777),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Order card widget
class _OrderCard extends StatelessWidget {
  final ShopifyOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE5E5E5).withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  order.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(order),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    const Text(
                      'Placed on',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Items
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF777777),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5C9A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF5C9A).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${order.lineItems.length} ${order.lineItems.length == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF5C9A),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Product items
                      ...order.lineItems.take(2).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5C9A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Qty: ${item.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF777777),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      )),
                      
                      if (order.lineItems.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${order.lineItems.length - 2} more ${order.lineItems.length - 2 == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF777777),
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Total
                Row(
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF777777),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${order.totalPrice}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(ShopifyOrder order) {
    final financial = order.financialStatus.toLowerCase();
    final fulfillment = order.fulfillmentStatus.toLowerCase();
    
    if (financial == 'paid' && fulfillment == 'fulfilled') {
      return const Color(0xFF4CAF50);
    } else if (financial == 'pending' || fulfillment == 'unfulfilled') {
      return const Color(0xFFFF9800);
    } else if (financial == 'refunded' || fulfillment == 'cancelled') {
      return const Color(0xFFF44336);
    } else {
      return const Color(0xFF2196F3);
    }
  }

  String _getStatusText(ShopifyOrder order) {
    final financial = order.financialStatus.toLowerCase();
    final fulfillment = order.fulfillmentStatus.toLowerCase();
    
    if (financial == 'paid' && fulfillment == 'fulfilled') {
      return 'Delivered';
    } else if (financial == 'pending' || fulfillment == 'unfulfilled') {
      return 'Pending';
    } else if (financial == 'refunded' || fulfillment == 'cancelled') {
      return 'Cancelled';
    } else {
      return 'Processing';
    }
  }
}
