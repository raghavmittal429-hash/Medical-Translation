import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'theme/medisimple_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  runApp(const MedicalCDSSApp());
}

class MedicalCDSSApp extends StatelessWidget {
  const MedicalCDSSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediSimple',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const AppColors.navy800,
    brightness: Brightness.light,
  ),

  scaffoldBackgroundColor: const Color(0xFFF5F7FA),

  fontFamily: 'Roboto',

  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),

  cardTheme: CardThemeData(
    elevation: 3,
    shadowColor: Colors.black12,
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const AppColors.navy800,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  ),
),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // FIX 1: unified index for both IndexedStack and NavigationBar
  int _currentIndex = 0;
  int get _selectedIndex => _currentIndex;

  // FIX 2: added missing _loadingMessage variable
  String _loadingMessage = '';

  FlutterTts _tts = FlutterTts();

  // Data state
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  bool _isTranslating = false;
  bool _isDownloadingPdf = false;
  String _selectedLanguage = 'English';
  bool _ttsEnabled = true;
  String? _selectedVoiceName;
  List<dynamic> _availableVoices = [];
  String? _currentJobId;
  Timer? _pollingTimer;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  bool _voiceExplicitlyPinned = false;

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _loadAvailableVoices();
    await _applyVoiceForLanguage(_selectedLanguage);
  }

  Future<void> _loadAvailableVoices({int retries = 4}) async {
    try {
      for (var attempt = 0; attempt <= retries; attempt++) {
        final voices = await _tts.getVoices;
        if (voices is List && voices.isNotEmpty) {
          _availableVoices = voices;
          return;
        }
        if (attempt < retries) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      _availableVoices = [];
    } catch (_) {
      _availableVoices = [];
    }
  }

  String _languageCodeOf(String locale) {
    final parts = locale.split(RegExp(r'[-_]'));
    return parts.isNotEmpty ? parts.first.toLowerCase() : locale.toLowerCase();
  }

  String _languageCodeFor(String language) {
    for (final entry in _languages) {
      if (entry['name'] == language) {
        return entry['code'] ?? _languageCodeOf(_ttsLocalesFor(language).first);
      }
    }
    return _languageCodeOf(_ttsLocalesFor(language).first);
  }

  bool _hasMatchingDeviceVoice(String language) {
    if (_availableVoices.isEmpty) return false;

    final targetLocales = _ttsLocalesFor(language);
    final targetLangCode = _languageCodeOf(targetLocales.first);

    return _availableVoices.any((voice) {
      final voiceLocale = _voiceLocaleOf(voice).toLowerCase();
      return targetLocales.map((e) => e.toLowerCase()).contains(voiceLocale) ||
          _languageCodeOf(voiceLocale) == targetLangCode;
    });
  }

  Future<void> _applyVoiceForLanguage(String language) async {
    final targetLocales = _ttsLocalesFor(language);
    final targetLocale = targetLocales.first;
    final targetLangCode = _languageCodeOf(targetLocale);

    if (_availableVoices.isEmpty) {
      await _loadAvailableVoices();
    }

    final localeMatches = _availableVoices.where((voice) {
      final voiceLocale = _voiceLocaleOf(voice).toLowerCase();
      return targetLocales.map((e) => e.toLowerCase()).contains(voiceLocale) ||
          _languageCodeOf(voiceLocale) == targetLangCode;
    }).toList();

    await _trySetLanguage(targetLocales);

    if (localeMatches.isNotEmpty) {
      final bestVoice = _preferredVoice(localeMatches);
      _selectedVoiceName = _voiceNameOf(bestVoice);
      await _setTtsVoice(bestVoice);
      _voiceExplicitlyPinned = true;
    } else if (_voiceExplicitlyPinned) {
      await _clearTtsVoice();
      _selectedVoiceName = null;
      _voiceExplicitlyPinned = false;
    } else {
      _selectedVoiceName = null;
    }

    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  String _voiceLocaleOf(dynamic voice) {
    if (voice is Map) {
      final locale = voice['locale'] ?? voice['language'] ?? voice['name'];
      return locale?.toString() ?? '';
    }
    return voice.toString();
  }

  String _voiceNameOf(dynamic voice) {
    if (voice is Map) {
      return voice['name']?.toString() ?? _voiceLocaleOf(voice);
    }
    return voice.toString();
  }

  int _voiceQualityScore(dynamic voice) {
    final name = _voiceNameOf(voice).toLowerCase();
    var score = 0;
    if (name.contains('neural')) score += 100;
    if (name.contains('natural')) score += 90;
    if (name.contains('online')) score += 80;
    if (name.contains('premium') || name.contains('enhanced')) score += 60;
    if (name.contains('wavenet')) score += 60;
    if (name.contains('google')) score += 30;
    if (name.contains('female')) score += 15;
    if (name.contains('smooth') || name.contains('soft')) score += 10;
    if (name.contains('compact') ||
        name.contains('espeak') ||
        name.contains('festival')) {
      score -= 50;
    }
    return score;
  }

  dynamic _preferredVoice(List<dynamic> voices) {
    final sorted = [...voices]
      ..sort((a, b) => _voiceQualityScore(b).compareTo(_voiceQualityScore(a)));
    return sorted.first;
  }

  Future<void> _setTtsVoice(dynamic voice) async {
    try {
      if (voice is Map) {
        final settings = <String, String>{};
        if (voice.containsKey('name'))
          settings['name'] = voice['name'].toString();
        if (voice.containsKey('locale'))
          settings['locale'] = voice['locale'].toString();
        if (settings.isNotEmpty) {
          await _tts.setVoice(settings);
        }
      }
    } catch (_) {}
  }

  Future<void> _clearTtsVoice() async {
    try {
      await _tts.setVoice({'name': '', 'locale': ''});
    } catch (_) {}
  }

  Future<void> _setTtsLanguage(String locale) async {
    try {
      await _tts.setLanguage(locale);
    } catch (_) {
      if (locale != 'en-US') {
        await _tts.setLanguage('en-US');
      }
    }
  }

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://medical-translation-5.onrender.com',
  );

  Uri _buildApiUrl(String path) {
    return Uri.parse('$_baseUrl$path');
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processFileBytes(file.bytes!, file.name);
        } else {
          _showError('Unable to read file data. Please try again.');
        }
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _processFileBytes(Uint8List bytes, String fileName) async {
    setState(() {
      _isLoading = true;
      _reportData = null;
      _loadingMessage = '';
    });

    final apiUrl = _buildApiUrl('/upload');

    try {
      final request = http.MultipartRequest('POST', apiUrl);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));
      request.fields['language'] = _selectedLanguage;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final jobId = responseData['job_id'];

        if (jobId != null) {
          _startJobPolling(jobId);
        } else {
          setState(() {
            _reportData = responseData;
            _isLoading = false;
          });
        }
      } else {
        _showError('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection error: $e\nMake sure backend is running');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _startJobPolling(String jobId) {
    if (_currentJobId != null) {
      _pollingTimer?.cancel();
    }
    _currentJobId = jobId;

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final statusUrl = _buildApiUrl('/job/$jobId');
        final response = await http.get(statusUrl);

        if (response.statusCode == 200) {
          final statusData = json.decode(response.body);

          if (statusData['status'] == 'completed') {
            setState(() {
              _reportData = statusData['result'];
              _isLoading = false;
            });
            _pollingTimer?.cancel();
            _currentJobId = null;
          } else if (statusData['status'] == 'failed') {
            _showError('Processing failed: ${statusData['error']}');
            setState(() {
              _isLoading = false;
            });
            _pollingTimer?.cancel();
            _currentJobId = null;
          } else if (statusData['message'] != null) {
            // FIX 3: update loading message from polling status
            setState(() {
              _loadingMessage = statusData['message'].toString();
            });
          }
        } else {
          _showError('Error checking job status');
          setState(() {
            _isLoading = false;
          });
          _pollingTimer?.cancel();
          _currentJobId = null;
        }
      } catch (e) {
        _showError('Connection error while checking status: $e');
        setState(() {
          _isLoading = false;
        });
        _pollingTimer?.cancel();
        _currentJobId = null;
      }
    });
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty || !_ttsEnabled) return;

    await _tts.stop();
    await _applyVoiceForLanguage(_selectedLanguage);

    if (_selectedLanguage != 'English' &&
        !_hasMatchingDeviceVoice(_selectedLanguage)) {
      try {
        await _speakViaBackend(text, _selectedLanguage);
        return;
      } catch (_) {}
    }

    try {
      await _tts.speak(text).timeout(const Duration(seconds: 90));
    } catch (e) {
      if (_selectedLanguage != 'English') {
        try {
          await _speakViaBackend(text, _selectedLanguage);
        } catch (_) {}
      }
    }
  }

  Future<void> _speakViaBackend(String text, String language) async {
    try {
      final langCode = _languageCodeFor(language);
      final ttsUrl = _buildApiUrl('/synthesize');

      final response = await http
          .post(
            ttsUrl,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'text': text, 'language': langCode}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final base64Audio = base64Encode(response.bodyBytes);
        final audioUrl = 'data:audio/mpeg;base64,$base64Audio';
        html.AudioElement audio = html.AudioElement(audioUrl);
        await audio.play().catchError((_) {});
      } else {
        throw Exception('Backend TTS failed with status ${response.statusCode}');
      }
    } catch (_) {
      rethrow;
    }
  }

  List<String> _ttsLocalesFor(String language) {
    const localeMap = {
      'English': ['en-US', 'en-GB', 'en'],
      'Hindi': ['hi-IN', 'hi'],
      'Bengali': ['bn-IN', 'bn-BD', 'bn'],
      'Tamil': ['ta-IN', 'ta-LK', 'ta'],
      'Telugu': ['te-IN', 'te'],
      'Marathi': ['mr-IN', 'mr'],
      'Gujarati': ['gu-IN', 'gu'],
      'Kannada': ['kn-IN', 'kn'],
      'Malayalam': ['ml-IN', 'ml'],
    };
    return List<String>.from(localeMap[language] ?? ['en-US']);
  }

  Future<void> _trySetLanguage(List<String> locales) async {
    for (final locale in locales) {
      try {
        await _tts.setLanguage(locale);
        return;
      } catch (_) {}
    }
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {}
  }

  void _showFilePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Choose PDF'),
              subtitle: const Text('Upload PDF medical report'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_reportData == null) return;
    setState(() => _isDownloadingPdf = true);
    try {
      final pdf = pw.Document();
      final data = _reportData!;
      final risk = ((data['risk_probability'] ?? 0) as num).toDouble();
      final riskPct = '${(risk * 100).toStringAsFixed(1)}%';
      final lang = _selectedLanguage;
      final isEnglish = lang == 'English';

      String fontAssetRegular = 'assets/fonts/NotoSans-Regular.ttf';
      String fontAssetBold = 'assets/fonts/NotoSans-Bold.ttf';
      if (['Hindi', 'Marathi', 'Nepali'].contains(lang)) {
        fontAssetRegular = 'assets/fonts/NotoSansDevanagari-Regular.ttf';
        fontAssetBold = 'assets/fonts/NotoSansDevanagari-Bold.ttf';
      } else if (lang == 'Tamil') {
        fontAssetRegular = 'assets/fonts/NotoSansTamil-Regular.ttf';
        fontAssetBold = 'assets/fonts/NotoSansTamil-Regular.ttf';
      } else if (['Bengali', 'Assamese'].contains(lang)) {
        fontAssetRegular = 'assets/fonts/NotoSansBengali-Regular.ttf';
        fontAssetBold = 'assets/fonts/NotoSansBengali-Regular.ttf';
      } else if (['Arabic', 'Urdu', 'Persian'].contains(lang)) {
        fontAssetRegular = 'assets/fonts/NotoSansArabic-Regular.ttf';
        fontAssetBold = 'assets/fonts/NotoSansArabic-Regular.ttf';
      }

      final fontDataRegular = await rootBundle.load(fontAssetRegular);
      final fontDataBold = await rootBundle.load(fontAssetBold);
      final ttfRegular = pw.Font.ttf(fontDataRegular);
      final ttfBold = pw.Font.ttf(fontDataBold);

      final fontDataFallback =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final ttfFallback = pw.Font.ttf(fontDataFallback);

      final suggestions = (data['suggestions'] as List? ?? [])
          .map((s) => s.toString())
          .toList();
      final translatedSuggestions =
          (data['translated_suggestions'] as List? ?? [])
              .map((s) => s.toString())
              .toList();
      final translatedExplanation =
          (data['translated_explanation'] ?? '').toString();
      final diseaseEn = (data['disease_explanation_en'] ?? '').toString();
      final solutionEn = (data['solution_plan_en'] ?? '').toString();
      final diseaseLang = (data['disease_explanation_lang'] ??
              data['disease_explanation_hi'] ??
              '')
          .toString();
      final solutionLang =
          (data['solution_plan_lang'] ?? data['solution_plan_hi'] ?? '')
              .toString();
      final medicalSummary = (data['medical_summary'] ?? '').toString();
      final simpleExplanation = (data['simple_explanation'] ?? '').toString();

      final List<pw.Widget> items = [];
      final _bodyStyle = pw.TextStyle(
          font: ttfRegular,
          fontFallback: [ttfFallback],
          fontSize: 10,
          lineSpacing: 5);
      final _titleStyle = pw.TextStyle(
          font: ttfBold,
          fontFallback: [ttfFallback],
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.red900);
      final _headerStyle = pw.TextStyle(
          font: ttfBold,
          fontFallback: [ttfFallback],
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.red900);
      final _subHeaderStyle = pw.TextStyle(
          font: ttfRegular,
          fontFallback: [ttfFallback],
          fontSize: 9,
          color: PdfColors.grey600);
      final _riskStyle = pw.TextStyle(
          font: ttfBold,
          fontFallback: [ttfFallback],
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: risk > 0.6
              ? PdfColors.red800
              : risk > 0.3
                  ? PdfColors.orange800
                  : PdfColors.green800);
      final _footerStyle = pw.TextStyle(
          font: ttfRegular,
          fontFallback: [ttfFallback],
          fontSize: 8,
          color: PdfColors.grey500);

      List<String> _splitBody(String body) {
        final raw = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        final List<String> parts = [];
        for (final para in raw.split('\n')) {
          final p = para.trim();
          if (p.isEmpty) continue;
          if (p.length <= 150) {
            parts.add(p);
          } else {
            final sentences = p.split(RegExp(r'(?<=[.!?])\s+'));
            for (final s in sentences) {
              final t = s.trim();
              if (t.isNotEmpty) parts.add(t);
            }
          }
        }
        return parts.isEmpty ? [body.trim()] : parts;
      }

      void addSection(String title, String body) {
        if (body.trim().isEmpty) return;
        items.add(pw.SizedBox(height: 10));
        items.add(pw.Text(title, style: _titleStyle));
        items.add(pw.SizedBox(height: 3));
        for (final chunk in _splitBody(body)) {
          items.add(pw.Text(chunk, style: _bodyStyle));
          items.add(pw.SizedBox(height: 2));
        }
        items.add(pw.SizedBox(height: 2));
        items.add(pw.Divider(color: PdfColors.grey300, thickness: 0.5));
      }

      void addBullets(String title, List<String> bullets) {
        if (bullets.isEmpty) return;
        items.add(pw.SizedBox(height: 10));
        items.add(pw.Text(title, style: _titleStyle));
        items.add(pw.SizedBox(height: 3));
        for (final b in bullets) {
          final chunks = _splitBody(b);
          items.add(pw.Text('  \u2022  ${chunks.first}', style: _bodyStyle));
          for (final extra in chunks.skip(1)) {
            items.add(pw.Text('     $extra', style: _bodyStyle));
          }
          items.add(pw.SizedBox(height: 2));
        }
        items.add(pw.SizedBox(height: 2));
        items.add(pw.Divider(color: PdfColors.grey300, thickness: 0.5));
      }

      addSection('Medical Summary', medicalSummary);
      addSection('Simple Explanation', simpleExplanation);
      if (!isEnglish && translatedExplanation.isNotEmpty)
        addSection('$lang Explanation', translatedExplanation);
      addSection('Disease Explanation', diseaseEn);
      addSection('Solutions to Improve', solutionEn);
      if (!isEnglish && diseaseLang.isNotEmpty)
        addSection('Disease Explanation ($lang)', diseaseLang);
      if (!isEnglish && solutionLang.isNotEmpty)
        addSection('Solutions ($lang)', solutionLang);
      addBullets('AI Suggestions', suggestions);
      if (!isEnglish && translatedSuggestions.isNotEmpty)
        addBullets('$lang Suggestions', translatedSuggestions);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          maxPages: 100,
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Medical Report Summary', style: _headerStyle),
                        pw.Text(
                            'Generated by MediSimple  \u2022  ${data['report_date'] ?? ""}',
                            style: _subHeaderStyle),
                      ]),
                  pw.Text('Risk: $riskPct', style: _riskStyle),
                ],
              ),
              pw.Divider(color: PdfColors.red300, thickness: 1),
              pw.SizedBox(height: 2),
            ],
          ),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('MediSimple \u2014 Confidential', style: _footerStyle),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: _footerStyle),
            ],
          ),
          build: (ctx) => items,
        ),
      );
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'medical_report_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PDF downloaded successfully'),
          backgroundColor: AppColors.navy600,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  Future<void> _retranslate(String langName) async {
    if (_reportData == null) return;
    setState(() => _isTranslating = true);

    try {
      final url = _buildApiUrl('/retranslate');
      final body = json.encode({
        'parsed_data': _reportData!['parsed_data'] ?? '',
        'language': langName,
        'suggestions': _reportData!['suggestions'] ?? [],
        'medical_summary': _reportData!['medical_summary'] ?? '',
        'simplified_explanation': _reportData!['simple_explanation'] ?? '',
        'temporal_analysis': _reportData!['temporal_analysis'] ?? '',
        'causal_analysis': _reportData!['causal_analysis'] ?? '',
        'risk_probability': _reportData!['risk_probability'] ?? 0.0,
        'patient_id': _reportData!['patient_id'],
        'report_date': _reportData!['report_date'] ?? '',
        'disease_explanation_en': _reportData!['disease_explanation_en'] ?? '',
        'solution_plan_en': _reportData!['solution_plan_en'] ?? '',
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () =>
                throw Exception('Translation timed out. Please try again.'),
          );

      if (response.statusCode == 200) {
        final newData = json.decode(response.body);
        setState(() {
          _reportData = {
            ..._reportData!,
            'translated_explanation': newData['translated_explanation'] ?? '',
            'translated_suggestions': newData['translated_suggestions'] ?? [],
            'disease_explanation_lang': newData['disease_explanation_hi'] ??
                newData['disease_explanation_lang'] ??
                '',
            'solution_plan_lang': newData['solution_plan_hi'] ??
                newData['solution_plan_lang'] ??
                '',
            'disease_explanation_hi': newData['disease_explanation_hi'] ?? '',
            'solution_plan_hi': newData['solution_plan_hi'] ?? '',
            'target_language': langName,
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Translated to $langName'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        _showError(
            'Translation failed (${response.statusCode}). Please try again.');
        setState(() => _selectedLanguage = 'English');
      }
    } catch (e) {
      if (mounted) _showError('Translation error: $e');
      setState(() => _selectedLanguage = 'English');
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _showTranslationErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.translate, color: AppColors.navy800),
            SizedBox(width: 8),
            Text('Translation Unavailable'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEDCCCC)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To enable translation:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('1. Make sure the backend server is running',
                      style: TextStyle(fontSize: 12)),
                  Text('2. Set ANTHROPIC_API_KEY in your backend .env file',
                      style: TextStyle(fontSize: 12)),
                  Text('3. Run: uvicorn main:app --port 8000',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.navy800)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language,
                            color: AppColors.navy800, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Language',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          Text('Report will be retranslated automatically',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _languages.map((lang) {
                        final isSelected = _selectedLanguage == lang['name'];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFDF0F0)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(lang['native']![0],
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isSelected
                                      ? const AppColors.navy800
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                          title: Text(lang['name']!,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color:
                                    isSelected ? const AppColors.navy800 : null,
                              )),
                          subtitle: Text(lang['native']!,
                              style: const TextStyle(fontSize: 12)),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.navy800, size: 22)
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          tileColor:
                              isSelected ? const Color(0xFFFDF0F0) : null,
                          onTap: () {
                            final newLang = lang['name']!;
                            Navigator.pop(context);
                            if (newLang != _selectedLanguage) {
                              setState(() {
                                _selectedLanguage = newLang;
                                if (_reportData != null) {
                                  _reportData = {
                                    ..._reportData!,
                                    'translated_explanation': '',
                                    'translated_suggestions': [],
                                    'disease_explanation_lang': '',
                                    'solution_plan_lang': '',
                                  };
                                }
                              });
                              _applyVoiceForLanguage(newLang);
                              if (_reportData != null) {
                                _retranslate(newLang);
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVoiceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hearing,
                          color: AppColors.navy800, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Voice Model',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        Text('Choose a smoother voice for playback',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 4),
                if (_availableVoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No available voices detected on this device.',
                        style: TextStyle(fontSize: 14)),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: Builder(builder: (context) {
                      final targetLangCode = _languageCodeOf(
                          _ttsLocalesFor(_selectedLanguage).first);
                      final sortedVoices = [..._availableVoices]..sort((a, b) {
                          final aMatches = _languageCodeOf(_voiceLocaleOf(a)) ==
                              targetLangCode;
                          final bMatches = _languageCodeOf(_voiceLocaleOf(b)) ==
                              targetLangCode;
                          if (aMatches != bMatches) return aMatches ? -1 : 1;
                          return _voiceQualityScore(b)
                              .compareTo(_voiceQualityScore(a));
                        });
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedVoices.length,
                        itemBuilder: (context, index) {
                          final voice = sortedVoices[index];
                          final voiceName = _voiceNameOf(voice);
                          final voiceLocale = _voiceLocaleOf(voice);
                          final isSelected = _selectedVoiceName == voiceName;
                          final isRecommended =
                              _languageCodeOf(voiceLocale) == targetLangCode &&
                                  _voiceQualityScore(voice) > 0;
                          return ListTile(
                            title: Text(voiceName),
                            subtitle: Text(
                              isRecommended
                                  ? '$voiceLocale · Recommended for $_selectedLanguage'
                                  : voiceLocale,
                              style: isRecommended
                                  ? const TextStyle(
                                      color: AppColors.navy800,
                                      fontWeight: FontWeight.w600)
                                  : null,
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.navy800)
                                : null,
                            onTap: () async {
                              Navigator.pop(context);
                              setState(() {
                                _selectedVoiceName = voiceName;
                              });
                              await _trySetLanguage(
                                  _ttsLocalesFor(_selectedLanguage));
                              await _setTtsVoice(voice);
                              _voiceExplicitlyPinned = true;
                            },
                          );
                        },
                      );
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 84,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy800, AppColors.navy600],
            ),
          ),
        ),
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MediSimple",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text("AI Medical Report Assistant",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isTranslating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextButton.icon(
                  onPressed: _showLanguageSelector,
                  icon: const Icon(Icons.language, color: Colors.white, size: 18),
                  label: Text(_selectedLanguage,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8)),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildUploadTab(),
              _buildExplainTab(),
              _buildSuggestionsTab(),
              _buildSettingsTab(),
            ],
          ),
          if (_isTranslating)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: AppColors.navy700),
                      ),
                      const SizedBox(height: 20),
                      Text('Translating to $_selectedLanguage',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B))),
                      const SizedBox(height: 6),
                      const Text(
                          'Explanation, suggestions, disease\nand solution are being translated…',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // FIX 4: NavigationBar onDestinationSelected now updates _currentIndex
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const AppColors.navy50,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: "Explain"),
          NavigationDestination(
              icon: Icon(Icons.lightbulb_outline),
              selectedIcon: Icon(Icons.lightbulb),
              label: "Suggestions"),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: "Settings"),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy800, AppColors.navy700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.navy900.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MediSimple',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4)),
                  SizedBox(height: 4),
                  Text('AI Medical Report Assistant',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isLoading ? null : _pickFile,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isLoading ? AppColors.navy200 : AppColors.navy800,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.navy800.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: _isLoading
                  ? Column(children: [
                      const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: AppColors.navy800)),
                      const SizedBox(height: 14),
                      const Text('Analysing your report…',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy800)),
                      const SizedBox(height: 6),
                      Text(
                        _loadingMessage.isNotEmpty
                            ? _loadingMessage
                            : 'This usually takes 20–40 seconds',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ])
                  : Column(children: [
                      Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                              color: AppColors.navy50, shape: BoxShape.circle),
                          child: const Icon(Icons.cloud_upload_rounded,
                              color: AppColors.navy800, size: 30)),
                      const SizedBox(height: 14),
                      const Text('Upload PDF Report',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Lab reports · Prescriptions · Clinical notes',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 11),
                        decoration: BoxDecoration(
                            color: AppColors.navy800,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Choose File',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ]),
            ),
          ),
          const SizedBox(height: 20),
          if (_reportData != null) ...[
            _buildResultOverview(),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: _isDownloadingPdf ? null : _downloadPdf,
                icon: _isDownloadingPdf
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.navy800))
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_isDownloadingPdf ? 'Generating…' : 'Download PDF'),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () => setState(() => _currentIndex = 2),
                icon: const Icon(Icons.tips_and_updates_rounded, size: 18),
                label: const Text('Suggestions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold600,
                  foregroundColor: Colors.white,
                ),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const AppColors.navy800, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildResultOverview() {
    final suggestions = _asStringList(_reportData!['translated_suggestions']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const AppColors.navy50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCFBF1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.navy800, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report processed',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Your report summary and guidance are ready.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestions.isNotEmpty)
            const Text('Ready for review',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const AppColors.navy800),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }

  Widget _buildExplainTab() {
    if (_reportData == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const AppColors.navy50,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFCCFBF1), width: 1.5),
                        ),
                        child: Icon(Icons.description_outlined,
                            size: 64, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 24),
                      const Text('Upload a medical report to get started',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text('Upload a PDF report to get started',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'MediSimple',
            icon: Icons.medical_information,
            content: _reportData!['medical_summary'] ?? 'N/A',
            canSpeak: true,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Simple Explanation',
            icon: Icons.lightbulb_outline,
            content: _reportData!['simple_explanation'] ?? 'N/A',
            canSpeak: true,
            isHighlighted: true,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '$_selectedLanguage Explanation',
            icon: Icons.translate,
            content: _isTranslating
                ? 'Translating to $_selectedLanguage...'
                : (_reportData!['translated_explanation']
                                ?.toString()
                                .isNotEmpty ==
                            true
                        ? _reportData!['translated_explanation']
                        : 'Translation not available. Tap the language button above to retranslate.'),
            canSpeak: !_isTranslating,
            extraAction: _reportData != null && !_isTranslating
                ? IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Retranslate',
                    color: const AppColors.navy800,
                    onPressed: () => _retranslate(_selectedLanguage),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          if (_reportData!['suggestions'] != null &&
              (_reportData!['suggestions'] as List).isNotEmpty) ...[
            Builder(builder: (context) {
              final isEnglish = _selectedLanguage == 'English';
              final translatedSuggestions =
                  _asStringList(_reportData!['translated_suggestions']);
              final showTranslated =
                  !isEnglish && translatedSuggestions.isNotEmpty;
              final displayList = showTranslated
                  ? translatedSuggestions
                  : (_reportData!['suggestions'] as List)
                      .map((s) => s.toString())
                      .toList();
              final title =
                  showTranslated ? '$_selectedLanguage Suggestions' : 'AI Suggestions';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_isTranslating)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.navy800)),
                            const SizedBox(width: 12),
                            Text('Translating to $_selectedLanguage...',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...displayList.map(
                              (s) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right,
                                        color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(s)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    if (_reportData == null) {
      return _buildEmptyState(
        icon: Icons.tips_and_updates_outlined,
        title: 'Upload a report for suggestions',
        subtitle:
            'After processing, this tab will show disease explanation and improvement steps in your selected language.',
      );
    }

    const Map<String, Map<String, String>> langLabels = {
      'Hindi': {'disease': 'बीमारी की जानकारी', 'solution': 'सुधार के उपाय'},
      'Bengali': {'disease': 'রোগের তথ্য', 'solution': 'উন্নতির উপায়'},
      'Tamil': {'disease': 'நோய் தகவல்', 'solution': 'மேம்பாட்டு வழிகள்'},
      'Telugu': {'disease': 'వ్యాధి సమాచారం', 'solution': 'మెరుగుదల మార్గాలు'},
      'Marathi': {'disease': 'आजाराची माहिती', 'solution': 'सुधारणेचे उपाय'},
      'Gujarati': {'disease': 'રોગની માહિતી', 'solution': 'સુધારાના ઉપાય'},
      'Kannada': {'disease': 'ರೋಗದ ಮಾಹಿತಿ', 'solution': 'ಸುಧಾರಣೆಯ ಮಾರ್ಗಗಳು'},
      'Malayalam': {'disease': 'രോഗ വിവരം', 'solution': 'മെച്ചപ്പെടുത്തൽ വഴികൾ'},
    };

    final labels = langLabels[_selectedLanguage];
    final isEnglish = _selectedLanguage == 'English';

    final diseaseExplanationEn =
        (_reportData!['disease_explanation_en'] ?? '').toString();
    final solutionPlanEn = (_reportData!['solution_plan_en'] ?? '').toString();
    final diseaseExplanationLang = (_reportData!['disease_explanation_lang'] ??
            _reportData!['disease_explanation_hi'] ??
            '')
        .toString();
    final solutionPlanLang = (_reportData!['solution_plan_lang'] ??
            _reportData!['solution_plan_hi'] ??
            '')
        .toString();
    final translatedSuggestions =
        _asStringList(_reportData!['translated_suggestions']);
    final englishSuggestions = _asStringList(_reportData!['suggestions']);
    final translatingText = 'Translating to $_selectedLanguage...';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Disease Explanation',
            icon: Icons.medical_information,
            content: diseaseExplanationEn.isNotEmpty
                ? diseaseExplanationEn
                : 'Disease explanation could not be generated. Please review the PDF with your doctor.',
            canSpeak: true,
            isHighlighted: true,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Solutions to Improve',
            icon: Icons.healing,
            content: solutionPlanEn.isNotEmpty
                ? solutionPlanEn
                : 'Follow a balanced diet, regular activity, sleep, hydration, stress control, and your doctor advice.',
            canSpeak: true,
          ),
          const SizedBox(height: 16),
          if (!isEnglish) ...[
            _buildSectionCard(
              title: labels != null
                  ? '${labels['disease']} ($_selectedLanguage)'
                  : 'Disease Explanation ($_selectedLanguage)',
              icon: Icons.menu_book,
              content: _isTranslating
                  ? translatingText
                  : diseaseExplanationLang.isNotEmpty
                      ? diseaseExplanationLang
                      : 'Translation not available. Tap refresh to retry.',
              canSpeak: !_isTranslating,
              extraAction: !_isTranslating
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Retranslate',
                      color: const AppColors.navy800,
                      onPressed: () => _retranslate(_selectedLanguage),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: labels != null
                  ? '${labels['solution']} ($_selectedLanguage)'
                  : 'Solutions ($_selectedLanguage)',
              icon: Icons.spa,
              content: _isTranslating
                  ? translatingText
                  : solutionPlanLang.isNotEmpty
                      ? solutionPlanLang
                      : 'Translation not available. Tap refresh to retry.',
              canSpeak: !_isTranslating,
              extraAction: !_isTranslating
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Retranslate',
                      color: const AppColors.navy800,
                      onPressed: () => _retranslate(_selectedLanguage),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          if (_isTranslating)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.navy800)),
                    const SizedBox(width: 12),
                    Text('Translating checklist to $_selectedLanguage...',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (translatedSuggestions.isNotEmpty && !isEnglish) ...[
            Text('$_selectedLanguage Action Checklist',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...translatedSuggestions.asMap().entries.map(
                  (entry) => _buildSuggestionTile(
                    index: entry.key + 1,
                    text: entry.value,
                    color: const AppColors.navy800,
                  ),
                ),
          ],
          if (englishSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              leading:
                  const Icon(Icons.translate, color: AppColors.navy800),
              title: const Text('Original AI Suggestions (English)'),
              children: englishSuggestions
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: _buildSuggestionTile(
                        index: englishSuggestions.indexOf(item) + 1,
                        text: item,
                        color: Colors.blueGrey,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required int index,
    required String text,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.14),
              child: Text('$index',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 14, height: 1.35))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFEBF2F0), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDFA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            size: 56, color: const AppColors.navy800),
                      ),
                      const SizedBox(height: 18),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String content,
    bool canSpeak = false,
    bool isHighlighted = false,
    Widget? extraAction,
  }) {
    final paragraphs = content.trim().isEmpty
        ? <String>[]
        : content
            .split(RegExp(r'\n\s*\n+'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .take(6)
            .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isHighlighted ? AppColors.gold600 : AppColors.navy800,
            width: 3,
          ),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.navy800.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isHighlighted ? AppColors.gold100 : AppColors.navy50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: isHighlighted
                        ? AppColors.gold600
                        : AppColors.navy800,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary))),
              if (extraAction != null) extraAction,
              if (canSpeak)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _speak(content),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.navy50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.volume_up_rounded,
                          color: AppColors.navy800, size: 18),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            const Divider(height: 16),
            if (paragraphs.isEmpty)
              const Text('No content available yet.',
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary))
            else
              ...paragraphs.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(p,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: AppColors.textPrimary)),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/medisimple_logo.jpg',
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  const Text('MediSimple',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Your Personal Health Expert',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Version 2.0.0',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.navy800),
              title: const Text('Output Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguageSelector,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.record_voice_over,
                  color: AppColors.navy800),
              title: const Text('Text-to-Speech'),
              subtitle: Text(_ttsEnabled ? 'Enabled' : 'Disabled'),
              trailing: Switch(
                value: _ttsEnabled,
                onChanged: (value) async {
                  setState(() {
                    _ttsEnabled = value;
                  });
                  if (value) {
                    await _applyVoiceForLanguage(_selectedLanguage);
                  } else {
                    await _tts.stop();
                  }
                },
                activeThumbColor: const AppColors.navy800,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.headphones, color: AppColors.navy800),
              title: const Text('Voice Model'),
              subtitle: Text(_selectedVoiceName ?? 'Default'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showVoiceSelector,
            ),
          ),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.info_outline, color: AppColors.navy800),
              title: const Text('About'),
              subtitle: const Text('System information'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'MediSimple',
                  applicationVersion: '2.0.0',
                  applicationLegalese: '© 2026 MediSimple',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
