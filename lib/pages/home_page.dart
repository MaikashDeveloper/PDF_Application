import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pages/home_drawer.dart';
import 'package:pdf/pages/pdf_view_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
//import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<File> pdfFiles = [];
  bool _hasPermission = false;
  final bool _isDarkMode = false;
  final bool _isVerticalSwipe = true;
  int _currentPdfIndex = 0;
  final _noMorePdfSnackBar = const SnackBar(
    backgroundColor: Color.fromARGB(255, 253, 2, 2),
    content: Text(
      'There are no more PDFs to display',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    showCloseIcon: true,
    duration: Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  );

  @override
  void initState() {
    super.initState();
    // _loadTheme();
    _loadPdfFiles();
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.request();

    if (status == PermissionStatus.granted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status == PermissionStatus.permanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog();
    }
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
              'Please enable storage permission in settings to access files.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _displayPDFDetails() async {
    if (_hasPermission) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        pdfFiles += result.files.map((file) => File(file.path!)).toList();
        _savePdfFiles(pdfFiles);
        _loadPdfFiles(); // Reload the PDF files
        _currentPdfIndex = 0; // Reset the index to the first PDF

        setState(() {}); // Update the UI to reflect the selected files
      }
    } else {
      await _requestStoragePermission();
    }
  }

  void _openPdfViewer(String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          filePath: filePath,
          isDarkMode: _isDarkMode,
          isVerticalSwipe: _isVerticalSwipe,
          onNextPdf: _loadNextPdf,
        ),
      ),
    );
  }

  Future<void> _savePdfFiles(List<File> pdfFiles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> filePaths = pdfFiles.map((file) => file.path).toList();
    await prefs.setStringList('pdfFiles', filePaths);
  }

  Future<void> _loadPdfFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? filePaths = prefs.getStringList('pdfFiles');
    if (filePaths != null) {
      pdfFiles = filePaths.map((path) => File(path)).toList();
    }
  }

  void _loadNextPdf() {
    if (_currentPdfIndex < pdfFiles.length - 1) {
      _currentPdfIndex++;
      _openPdfViewer(pdfFiles[_currentPdfIndex].path);
    } else {
      // You can handle the case when there are no more PDFs to display
      _noMorePdfSnackBar;
    }
  }

  void _deletePdfFile(int index) {
    // Implement the logic to delete the PDF file
    if (index >= 0 && index < pdfFiles.length) {
      File pdfFile = pdfFiles[index];
      pdfFile.deleteSync(); // Delete the file from storage
      setState(() {
        pdfFiles.removeAt(index);
        _savePdfFiles(pdfFiles);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 17, 0),
        title: const Text("ASinfo PDF Reader"),
      ),
      drawer: const HomeDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recent Document",
                style: GoogleFonts.roboto(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Display the selected PDF files in a vertical list
              if (pdfFiles.isNotEmpty)
                Column(
                  children: [
                    for (int index = 0; index < pdfFiles.length; index++)
                      Card(
                        child: InkWell(
                          onTap: () => _openPdfViewer(pdfFiles[index].path),
                          child: Row(
                            children: [
                              // Image/Icon for PDF file
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  size: 24.0,
                                  color: Colors.red,
                                ),
                              ),
                              // PDF details
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pdfFiles[index].path.split('/').last,
                                      textAlign: TextAlign.left,
                                      style: GoogleFonts.roboto(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(
                                          pdfFiles[index].lastModifiedSync()),
                                      textAlign: TextAlign.left,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Menu button
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  // Handle menu item selection here
                                  if (value == 'delete') {
                                    // Implement the logic to delete the PDF file
                                    _deletePdfFile(index);
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return ['Delete'].map(
                                    (String choice) {
                                      return PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text(choice),
                                      );
                                    },
                                  ).toList();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 247, 17, 0),
        onPressed: _displayPDFDetails,
        //shape:
        child: const Icon(Icons.note_add),
      ),
    );
  }
}
