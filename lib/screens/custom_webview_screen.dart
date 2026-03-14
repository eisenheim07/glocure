import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';

/// Custom WebView Screen
/// Displays web content with optional camera permission handling
class CustomWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final bool requestCameraPermission;
  final bool showAppBar;

  const CustomWebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.requestCameraPermission = false,
    this.showAppBar = true,
  });

  @override
  State<CustomWebViewScreen> createState() => _CustomWebViewScreenState();
}

class _CustomWebViewScreenState extends State<CustomWebViewScreen> {
  InAppWebViewController? _controller;

  double _progress = 0;
  bool _isLoading = true;

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useHybridComposition: true,
    builtInZoomControls: true,
    displayZoomControls: false,
  );

  @override
  void initState() {
    super.initState();
    _handlePermissions();
  }

  Future<void> _handlePermissions() async {
    if (!widget.requestCameraPermission) return;

    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog('Camera');
      }
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Please grant $permissionName permission from settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Handles Android system back button
  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return false; // prevent screen pop
    }
    return true; // close screen
  }

  /// Handles AppBar back button
  Future<void> _handleAppBarBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: widget.showAppBar
            ? CustomAppBar(
                type: AppBarType.simple,
                title: widget.title,
                onBackPressed: _handleAppBarBack,
              )
            : null,
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.url),
              ),
              initialSettings: _settings,
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (_, __) {
                setState(() => _isLoading = true);
              },
              onLoadStop: (_, __) {
                setState(() => _isLoading = false);
              },
              onProgressChanged: (_, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onPermissionRequest: (_, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onReceivedError: (_, __, error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.description),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),

            // Loader
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),

            // Progress bar
            if (_progress < 1.0 && !_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.gray200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
