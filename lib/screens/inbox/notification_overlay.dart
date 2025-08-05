import 'package:flutter/material.dart';
import 'package:fishkart_vendor/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:ui';

class OrderNotificationOverlay extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final Map<String, dynamic>? productData;
  final Map<String, dynamic>? userData;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const OrderNotificationOverlay({
    super.key,
    required this.orderData,
    this.productData,
    this.userData,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<OrderNotificationOverlay> createState() =>
      _OrderNotificationOverlayState();
}

class _OrderNotificationOverlayState extends State<OrderNotificationOverlay>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  Map<String, dynamic>? _fetchedProductData;
  bool _loadingProduct = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // If productData is not provided, fetch from Firestore
    if (widget.productData == null && widget.orderData['product_uid'] != null) {
      _loadingProduct = true;
      FirebaseFirestore.instance
          .collection('products')
          .doc(widget.orderData['product_uid'])
          .get()
          .then((doc) {
            if (doc.exists) {
              if (mounted) {
                setState(() {
                  _fetchedProductData = doc.data();
                  _loadingProduct = false;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  _loadingProduct = false;
                });
              }
            }
          });
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // If productData is not provided, fetch from Firestore
    if (widget.productData == null && widget.orderData['product_uid'] != null) {
      _loadingProduct = true;
      FirebaseFirestore.instance
          .collection('products')
          .doc(widget.orderData['product_uid'])
          .get()
          .then((doc) {
            if (doc.exists) {
              if (mounted) {
                setState(() {
                  _fetchedProductData = doc.data();
                  _loadingProduct = false;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  _loadingProduct = false;
                });
              }
            }
          });
    }

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _animationController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
      // Remove by unique id if present
      try {
        final notification = NotificationOverlayManager.notifications.firstWhere(
          (n) => n.orderData == widget.orderData &&
                  n.productData == widget.productData &&
                  n.userData == widget.userData,
        );
        NotificationOverlayManager.hideNotificationById(notification.id);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final quantity = widget.orderData['quantity'] ?? 1;
    final productData = widget.productData ?? _fetchedProductData;
    final productTitle = productData?['title'] ?? '';
    final productWeight = productData?['weight'] ?? '500 gms';
    // Fallback to orderData if productData doesn't have weight
    final orderWeight = widget.orderData['weight'] ?? productWeight;
    // Time string (current time, as in screenshot)
    final now = TimeOfDay.now();
    final timeString = now.format(context);

    if (_loadingProduct) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(18),
              vertical: getProportionateScreenWidth(14),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(18),
                vertical: getProportionateScreenWidth(14),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'New order received!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              productTitle.isNotEmpty
                                  ? productTitle
                                  : 'Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            flex: 1,
                            child: Text(
                              '$orderWeight',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            flex: 1,
                            child: Text(
                              'x${quantity.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class to show the notification overlay

class NotificationOverlayManager {
  static final List<_NotificationData> _notifications = [];
  static OverlayEntry? _overlayEntry;
  static final Random _random = Random();

  static void showOrderNotification({
    required BuildContext context,
    required Map<String, dynamic> orderData,
    Map<String, dynamic>? productData,
    Map<String, dynamic>? userData,
    VoidCallback? onTap,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString() + '_' + _random.nextInt(100000).toString();
    _notifications.add(
      _NotificationData(
        id: id,
        orderData: orderData,
        productData: productData,
        userData: userData,
        onTap: onTap,
      ),
    );
    _showOverlay(context);
  }

  static void _showOverlay(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _NotificationStackWidget(),
      );
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  static void hideNotificationById(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications.removeAt(index);
      _overlayEntry?.markNeedsBuild();
      if (_notifications.isEmpty) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    }
  }

  static void hideAllNotifications() {
    _notifications.clear();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static List<_NotificationData> get notifications => _notifications;
}

class _NotificationData {
  final String id;
  final Map<String, dynamic> orderData;
  final Map<String, dynamic>? productData;
  final Map<String, dynamic>? userData;
  final VoidCallback? onTap;
  _NotificationData({
    required this.id,
    required this.orderData,
    this.productData,
    this.userData,
    this.onTap,
  });
}

class _NotificationStackWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifications = NotificationOverlayManager.notifications;
    if (notifications.isEmpty) return const SizedBox.shrink();
    double baseTop = MediaQuery.of(context).padding.top + 10;
    double stackOffset = 80.0;
    return Stack(
      children: [
        // Blurred background (only one)
        Positioned.fill(
          child: GestureDetector(
            onTap: () => NotificationOverlayManager.hideAllNotifications(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
          ),
        ),
        // Stacked notifications
        ...List.generate(notifications.length, (i) {
          final n = notifications[i];
          return Positioned(
            top: baseTop + (i * stackOffset),
            left: 16,
            right: 16,
            child: OrderNotificationOverlay(
              key: ValueKey(n.id),
              orderData: n.orderData,
              productData: n.productData,
              userData: n.userData,
              onTap: () {
                NotificationOverlayManager.hideNotificationById(n.id);
                if (n.onTap != null) n.onTap!();
              },
              onDismiss: () => NotificationOverlayManager.hideNotificationById(n.id),
            ),
          );
        }),
      ],
    );
  }
}
