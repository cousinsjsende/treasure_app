// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebViewController controller;
  bool isOnline = true;
  Box? webCacheBox;

  @override
  void initState() {
    super.initState();
    checkConnectivity();
    webCacheBox = Hive.box('webCache');
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            if (isOnline) {
              String? htmlContent = await controller.runJavaScriptReturningResult("document.documentElement.outerHTML") as String?;
              if (htmlContent != null) {
                webCacheBox?.put(url, htmlContent);
              }
            }
          },
        ),
      );
    loadUrl();
  }

  Future<void> loadUrl() async {
    String url = 'https://rockandrobot.com/financeApp/';
    if (isOnline) {
      controller.loadRequest(Uri.parse(url));
    } else {
      String? cachedHtml = webCacheBox?.get(url);
      if (cachedHtml != null) {
        controller.loadHtmlString(cachedHtml);
      } else {
        setState(() {
          isOnline = false;
        });
      }
    }
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: WillPopScope(
          onWillPop: () async {
            if (await controller.canGoBack()) {
              controller.goBack();
              return false;
            }
            return true;
          },
          child: GestureDetector(
            onTap: () async {
              if (isOnline) {
                controller.reload();
              }
            },
            onHorizontalDragEnd: (details) async {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                if (await controller.canGoForward()) {
                  controller.goForward();
                }
              } else if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                if (await controller.canGoBack()) {
                  controller.goBack();
                }
              }
            },
            onVerticalDragUpdate: (_) {}, // Prevent back action on vertical swipe
            child: isOnline
                ? WebViewWidget(controller: controller)
                : Center(child: Text('You are offline. No cached data available.')),
          ),
        ),
      ),
    );
  }
}
