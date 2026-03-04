import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'package:glocure/cubits/orders/orders_cubit.dart';
import 'package:glocure/cubits/orders/orders_state.dart';
import 'package:glocure/models/shopify_order_model.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:glocure/utils/app_logger.dart';
import 'ordered_items_details.dart';
import 'main_navigation_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize orders when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        context.read<OrdersCubit>().initializeOrders();
        _hasInitialized = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Reset to "All" tab when navigating from bottom nav
    if (_tabController.index != 0) {
      AppLogger.info('OrderScreen: Resetting to All tab from navigation');
      _resetToAllTab();
    }
  }

  void _resetToAllTab() {
    _tabController.animateTo(0);
    context.read<OrdersCubit>().showAllTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Custom back navigation logic
        if (_tabController.index == 0) {
          // If on "All" tab, navigate to home
          MainNavigationScreen.navigateToHome(context);
          return false;
        } else {
          // If on other tabs, switch to "All" tab first
          _resetToAllTab();
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          type: AppBarType.full,
          showBackButton: true,
          onBackPressed: () {
            // Same logic as WillPopScope
            if (_tabController.index == 0) {
              MainNavigationScreen.navigateToHome(context);
            } else {
              _resetToAllTab();
            }
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
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF5C9A),
                indicatorWeight: 2,
                labelStyle: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w400,
                ),
                onTap: (index) {
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
                },
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Closed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            
            // Orders Content
            Expanded(
              child: BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) {
                  if (state is OrdersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5C9A),
                      ),
                    );
                  } else if (state is OrdersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Error loading orders',
                            style: TextStyle(
                              fontSize: 18.fSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 14.fSize,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: () {
                              context.read<OrdersCubit>().refreshOrders();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5C9A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is OrdersLoaded) {
                    if (state.orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No ${state.currentTab.toLowerCase()} orders',
                              style: TextStyle(
                                fontSize: 18.fSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Your ${state.currentTab.toLowerCase()} orders will appear here',
                              style: TextStyle(
                                fontSize: 14.fSize,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => context.read<OrdersCubit>().refreshOrders(),
                      color: const Color(0xFFFF5C9A),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.h),
                        itemCount: state.orders.length,
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    );
                  }

                  return const Center(
                    child: Text('Loading orders...'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(ShopifyOrder order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with order number and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.name}',
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.h,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(int.parse(order.statusColor.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.displayStatus,
                        style: TextStyle(
                          fontSize: 10.fSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.h),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'view_details') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderedItemsDetails(order: order),
                            ),
                          );
                        } else if (value == 'track_order') {
                          // TODO: Implement order tracking
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order tracking coming soon'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view_details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'track_order',
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, size: 18),
                              SizedBox(width: 8),
                              Text('Track Order'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Order items preview
            Text(
              '${order.lineItems.length} item${order.lineItems.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 14.fSize,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '₹${order.totalPrice}',
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF5C9A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}