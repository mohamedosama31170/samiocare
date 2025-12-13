import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_constants.dart';

class SamiocareWebViewApp extends StatefulWidget {
  const SamiocareWebViewApp({super.key});

  @override
  State<SamiocareWebViewApp> createState() => _SamiocareWebViewAppState();
}

class _SamiocareWebViewAppState extends State<SamiocareWebViewApp> {
  late final WebViewController _webViewController;
  int _progress = 0;
  String? lastUrl;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  Future _initWebViewController() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            final isForMainFrame = error.isForMainFrame ?? false;
            if (!isForMainFrame) return;
            final ignoredErrors = [
              'net::ERR_BLOCKED_BY_CLIENT',
              'net::ERR_BLOCKED_BY_RESPONSE',
              'net::ERR_BLOCKED_BY_ORB',
              'net::ERR_UNKNOWN_URL_SCHEME',
            ];
            if (ignoredErrors.any((msg) => error.description.contains(msg))) {
              return;
            }
            setState(() {
              errorMessage = error.description;
            });
          },
          onPageStarted: (url) {
            errorMessage = null;
            setState(() {
              _progress = 0;
              lastUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _progress = 100;
            });
          },
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConstants.initialUrl));
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) return;

    _webViewController.canGoBack().then((canGoBack) {
      if (canGoBack) {
        _webViewController.goBack();
      } else {
        if (mounted) exit(0);
      }
    });
  }

  void _reloadPage() {
    if (lastUrl != null) {
      _webViewController.loadRequest(Uri.parse(lastUrl!));
    } else {
      _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        body: SafeArea(
          child: errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: Image.asset(AppConstants.splashScreenImage),
                        ),
                        const Text(
                          'Error loading page:',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: "Cairo",
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _reloadPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              fontFamily: "Cairo",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    WebViewWidget(controller: _webViewController),
                    _progress < 100
                        ? LinearProgressIndicator(
                            color: const Color.fromARGB(255, 24, 231, 211),
                            backgroundColor: Colors.transparent,
                            minHeight: 2,
                            value: _progress / 100,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
        ),
      ),
    );
  }
}
