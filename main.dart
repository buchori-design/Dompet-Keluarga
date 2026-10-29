import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// GANTI dengan URL Web App Apps Script kamu (Deploy > Manage deployments)
const String appUrl = 'https://script.google.com/macros/s/AKfycbztB2AvFNFgvDyhVI-410J_mAhsy5Vt5PIlAbzPpQ7116lAG2Ck9yDX1aK5EdwE0to_/exec';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _error = false),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _error = true);
          },
          onNavigationRequest: (req) {
            final url = req.url;
            // Biarkan domain Google/Apps Script tetap di dalam app
            if (url.contains('script.google.com') ||
                url.contains('googleusercontent.com') ||
                url.contains('google.com')) {
              return NavigationDecision.navigate;
            }
            // Link lain (WA, telp, email, web luar) dibuka di aplikasi eksternal
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(appUrl));
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _handleBack() && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (_error)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48),
                      const SizedBox(height: 12),
                      const Text('Gagal memuat. Cek koneksi internet.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _controller.reload(),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              else
                WebViewWidget(controller: _controller),
              if (_progress < 100 && !_error)
                LinearProgressIndicator(value: _progress / 100),
            ],
          ),
        ),
      ),
    );
  }
}
