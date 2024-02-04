import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class PdfViewerPage extends StatelessWidget {
  final String filePath;
  final bool isDarkMode;
  final bool isVerticalSwipe;
  final VoidCallback onNextPdf;

  const PdfViewerPage({
    required this.filePath,
    required this.isDarkMode,
    required this.isVerticalSwipe,
    required this.onNextPdf,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: !isVerticalSwipe,
        autoSpacing: true,
        pageSnap: true,
        nightMode: isDarkMode,
        onError: (error) {
          print(error);
        },
        onRender: (pages) {
          print('Pages: $pages');
        },
        onPageError: (page, error) {
          print('Error on page $page: $error');
        },
        onViewCreated: (PDFViewController viewController) {
          // You can use the controller to interact with the PDF view
        },
        onPageChanged: (int? page, int? total) {
          print('Page change: $page/$total');
          if (page == total) {
            onNextPdf(); // Notify parent page when reaching the last page
          }
        },
      ),
    );
  }
}
