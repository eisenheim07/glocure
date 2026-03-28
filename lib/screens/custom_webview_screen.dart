import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/size_utils.dart';

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
    javaScriptCanOpenWindowsAutomatically: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useHybridComposition: true,
    builtInZoomControls: true,
    displayZoomControls: false,
    // Add settings to handle ORB and CORS issues
    userAgent: 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    allowsLinkPreview: false,
    iframeAllow: "camera; microphone; geolocation",
    iframeAllowFullscreen: true,
    // Additional security and compatibility settings
    clearCache: false,
    clearSessionCache: false,
    hardwareAcceleration: true,
    supportMultipleWindows: true,
    allowsBackForwardNavigationGestures: true,
    // Enable popup windows and new window handling
    supportZoom: true,
    allowFileAccess: true,
    allowContentAccess: true,
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

  /// Show dialog to choose how to open new window
  void _showNewWindowDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Open New Window'),
        content: const Text(
          'A new window is trying to open. How would you like to open it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              // Open in new WebView screen
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomWebViewScreen(
                      title: 'New Window',
                      url: url,
                      showAppBar: true,
                    ),
                  ),
                );
              }
            },
            child: const Text('Open in App'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open the URL'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to open URL in external browser
  void _showOpenInBrowserDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unable to Load'),
        content: const Text(
          'This website cannot be displayed in the app. Would you like to open it in your browser instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                // Import url_launcher package if not already imported
                final Uri url = Uri.parse(widget.url);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open the URL'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
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
                  headers: {
                    'User-Agent':
                        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                    'Accept-Language': 'en-US,en;q=0.5',
                    'Accept-Encoding': 'gzip, deflate',
                    'DNT': '1',
                    'Connection': 'keep-alive',
                    'Upgrade-Insecure-Requests': '1',
                  },
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
                    // Check if it's an ORB error
                    if (error.description.contains('ERR_BLOCKED_BY_ORB') ||
                        error.description.contains('ERR_BLOCKED_BY_CLIENT') ||
                        error.description.contains('ERR_ACCESS_DENIED')) {
                      // Show dialog to open in external browser
                      _showOpenInBrowserDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.description),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onCreateWindow: (controller, createWindowAction) async {
                  // Handle new window/tab opening
                  final url = createWindowAction.request.url;
                  if (url != null) {
                    // Show dialog to let user choose how to open the new window
                    if (mounted) {
                      _showNewWindowDialog(url.toString());
                    }
                    return true; // Indicate that we handled the window creation
                  }
                  return false;
                },
                onWindowFocus: (controller) {
                  // Handle window focus events if needed
                },
                onWindowBlur: (controller) {
                  // Handle window blur events if needed
                },
                onJsAlert: (controller, jsAlertRequest) async {
                  // Handle JavaScript alert dialogs
                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Alert'),
                        content: Text(jsAlertRequest.message ?? ''),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return JsAlertResponse(handledByClient: true);
                },
                onJsConfirm: (controller, jsConfirmRequest) async {
                  // Handle JavaScript confirm dialogs
                  bool? result;
                  if (mounted) {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm'),
                        content: Text(jsConfirmRequest.message ?? ''),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return JsConfirmResponse(
                    handledByClient: true,
                    action: (result ?? false) ? JsConfirmResponseAction.CONFIRM : JsConfirmResponseAction.CANCEL,
                  );
                },
                onJsPrompt: (controller, jsPromptRequest) async {
                  // Handle JavaScript prompt dialogs
                  String? result;
                  if (mounted) {
                    final TextEditingController textController = TextEditingController(
                      text: jsPromptRequest.defaultValue ?? '',
                    );
                    result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Input'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (jsPromptRequest.message?.isNotEmpty == true) Text(jsPromptRequest.message!),
                            const SizedBox(height: 16),
                            TextField(
                              controller: textController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, textController.text),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return JsPromptResponse(
                    handledByClient: true,
                    action: result != null ? JsPromptResponseAction.CONFIRM : JsPromptResponseAction.CANCEL,
                    value: result,
                  );
                },
              ),

              // Loader
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF5C9A),
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
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5C9A)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
