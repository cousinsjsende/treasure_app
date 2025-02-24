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
              // Save the HTML content locally
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
      // Load cached HTML if offline
      String? cachedHtml = webCacheBox?.get(url);
      if (cachedHtml != null) {
        controller.loadHtmlString(cachedHtml);
      } else {
        // Show offline message if no cache is available
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
            // Go back in web history instead of exiting the app
            controller.goBack();
            return false; // Prevent default back button behavior
          }
          return true; // Exit the app if there's no web history
        },
        child: GestureDetector(
          onTap: () async {
            // Reload the current page when tapped
            if (isOnline) {
              controller.reload();
            } else {
              setState(() {
                isOnline = false;
              });
            }
          },
          onHorizontalDragEnd: (details) async {
            // Swipe left or right to go back or forward
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              // Swiped Left: Go forward if possible
              if (await controller.canGoForward()) {
                controller.goForward();
              }
            } else if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
              // Swiped Right: Go back if possible
              if (await controller.canGoBack()) {
                controller.goBack();
              }
            }
          },
          child: isOnline
              ? WebViewWidget(controller: controller)
              : Center(child: Text('You are offline. No cached data available.')),
        ),
      ),
    ),
  );
}


}
