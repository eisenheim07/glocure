import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glocure/widgets/custom_app_bar.dart';
import 'package:glocure/cubits/orders/orders_cubit.dart';
import 'package:glocure/cubits/orders/orders_state.dart';
import 'package:glocure/models/shopify_order_model.dart';
import 'package:glocure/utils/format_utils.dart';
import 'package:glocure/utils/size_utils.dart';
import 'package:glocure/widgets/common_bottom_sheet.dart';
import 'main_navigation_screen.dart';
import 'ordered_items_details.dart';

class OrderScreen extends StatefulWidget {
  final bool isVisible;

  const OrderScreen({super.key, this.isVisible = false});

  @override
  State<OrderScreen> createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();

    print('OrderScreen: initState called');
  }

  @override
  void didUpdateWidget(OrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if screen just became visible
    if (widget.isVisible && !oldWidget.isVisible && !_hasLoadedData) {
      _hasLoadedData = true;
      print('OrderScreen: Screen became visible - loading data');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<OrdersCubit>().showAllTab();
        }
      });
    }
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

  Future<bool> _onWillPop() async {
    // If not on "All" tab, go to "All" tab first
    if (_currentIndex != 0) {
      _onTabTapped(0);
      return false; // Don't pop the route
    }
    // If on "All" tab, allow back navigation
    return true;
  }

  @override
  Widget build(BuildContext context) {
    print('OrderScreen: build() called, _currentIndex=$_currentIndex, isVisible=${widget.isVisible}');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          type: AppBarType.full,
          showBackButton: true,
          onBackPressed: () {
            // Handle back button press
            if (_currentIndex != 0) {
              // If not on "All" tab, go to "All" tab
              _onTabTapped(0);
            } else {
              // If on "All" tab, go back to home
              MainNavigationScreen.navigateToHome(context);
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
                unselectedLabelColor: const Color(0xFF777777),
                indicatorColor: const Color(0xFFFF5C9A),
                indicatorWeight: 2.h,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: TextStyle(
                  fontSize: 13.fSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 13.fSize,
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
        } else if (state is OrdersNoCustomer) {
          return _buildNoCustomerState(context);
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
              padding: EdgeInsets.all(14.w),
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
      padding: EdgeInsets.all(14.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          period: const Duration(milliseconds: 1200),
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            height: 150.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56.h, color: const Color(0xFFE0E0E0)),
            SizedBox(height: 14.h),
            Text(
              'Error loading orders',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.fSize,
                color: const Color(0xFF777777),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context.read<OrdersCubit>().refreshOrders(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.fSize, fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCustomerState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56.h, color: const Color(0xFFE0E0E0)),
            SizedBox(height: 14.h),
            Text(
              'No orders available',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Start shopping to see your orders here',
              style: TextStyle(
                fontSize: 13.fSize,
                color: const Color(0xFF777777),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                MainNavigationScreen.navigateToHome(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                'Start Shopping',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.fSize, fontFamily: 'Inter'),
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
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56.h, color: const Color(0xFFE0E0E0)),
            SizedBox(height: 14.h),
            Text(
              'No ${currentTab.toLowerCase()} orders',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Your ${currentTab.toLowerCase()} orders will appear here',
              style: TextStyle(
                fontSize: 13.fSize,
                color: const Color(0xFF777777),
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
class _OrderCard extends StatefulWidget {
  final ShopifyOrder order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _showAllItems = false;

  @override
  Widget build(BuildContext context) {
    final itemsToShow = _showAllItems ? widget.order.lineItems : widget.order.lineItems.take(2).toList();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number and status row
          Row(
            children: [
              Text(
                widget.order.name,
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: const Color(0xFFFFE0B2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(widget.order),
                  style: TextStyle(
                    fontSize: 11.fSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9800),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  color: const Color(0xFF666666),
                  size: 18.h,
                ),
                offset: Offset(0, 36.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                onSelected: (value) {
                  if (value == 'view_details') {
                    _onViewDetails(context, widget.order);
                  } else if (value == 'track_order') {
                    _onTrackOrder(context, widget.order);
                  } else if (value == 'delete_order') {
                    _onDeleteOrder(context, widget.order);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'view_details',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: const Color(0xFFFF5C9A),
                          size: 18.h,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13.fSize,
                            fontFamily: 'Inter',
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'track_order',
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: const Color(0xFFFF5C9A),
                          size: 18.h,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Track Order',
                          style: TextStyle(
                            fontSize: 13.fSize,
                            fontFamily: 'Inter',
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete_order',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: const Color(0xFFF44336),
                          size: 18.h,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Delete Order',
                          style: TextStyle(
                            fontSize: 13.fSize,
                            fontFamily: 'Inter',
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Placed on date
          Text(
            'Placed on ${_formatDate(widget.order.createdAt)}',
            style: TextStyle(
              fontSize: 11.fSize,
              color: const Color(0xFF777777),
              fontFamily: 'Inter',
            ),
          ),

          SizedBox(height: 8.h),

          // Divider before amount section
          Divider(
            color: const Color(0xFFE5E5E5).withOpacity(0.5),
            thickness: 1,
            height: 1,
          ),

          SizedBox(height: 8.h),

          // Total Amount and Items row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: const Color(0xFF777777),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    formatIndianCurrency(widget.order.totalPrice),
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: const Color(0xFF777777),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${widget.order.lineItems.length} ${widget.order.lineItems.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 14.fSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Divider before items list
          Divider(
            color: const Color(0xFFE5E5E5).withOpacity(0.5),
            thickness: 1,
            height: 1,
          ),

          SizedBox(height: 8.h),

          // Product items list
          ...itemsToShow.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 5.h),
                      width: 3.5.w,
                      height: 3.5.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFF333333),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: const Color(0xFF333333),
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Text(
                      '... Qty: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: const Color(0xFF333333),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              )),

          // View More/Less button if more than 2 items
          if (widget.order.lineItems.length > 2)
            Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAllItems = !_showAllItems;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAllItems ? 'View Less' : 'View More',
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: const Color(0xFFFF5C9A),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        _showAllItems ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFFFF5C9A),
                        size: 16.h,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onViewDetails(BuildContext context, ShopifyOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderedItemsDetails(order: order),
      ),
    );
  }

  void _onTrackOrder(BuildContext context, ShopifyOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Track order ${order.name}'),
        backgroundColor: const Color(0xFFFF5C9A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _onDeleteOrder(BuildContext context, ShopifyOrder order) {
    // Show confirmation bottom sheet using common widget
    CommonBottomSheet.show(
      context: context,
      title: 'Delete Order',
      message: 'Are you sure you want to delete order ${order.name}? This action cannot be undone.',
      icon: Icon(
        Icons.delete_outline,
        size: 44.h,
        color: const Color(0xFFFF5C9A),
      ),
      isIconEnabled: false,
      primaryButtonText: 'Delete',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () async {
        Navigator.pop(context);

        try {
          // Call cubit to delete order (this will show loading state and refresh)
          await context.read<OrdersCubit>().deleteOrder(order.id);

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order ${order.name} deleted successfully'),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            );
          }
        } catch (e) {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete order: ${e.toString()}'),
                backgroundColor: const Color(0xFFF44336),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            );
          }
        }
      },
      onSecondaryPressed: () => Navigator.pop(context),
    );
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
