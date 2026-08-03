import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MediSimpleApp());
}

class MediSimpleApp extends StatelessWidget {
  const MediSimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediSimple',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xffF4F8FB),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xff0F766E),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: const CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xff0F766E), width: 2),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

class MedicalReport {
  final String id;
  final String filename;
  final DateTime uploadedAt;
  final Map<String, dynamic> data;
  final String? pdfPath;

  MedicalReport({
    required this.id,
    required this.filename,
    required this.uploadedAt,
    required this.data,
    this.pdfPath,
  });
}

// ─────────────────────────────────────────────────────────────
// SERVICES
// ─────────────────────────────────────────────────────────────

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  Future<void> init() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() => _isSpeaking = false);
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
      return;
    }
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _flutterTts.stop();
  }

  bool get isSpeaking => _isSpeaking;
}

class ReportService {
  static const String _baseUrl = 'https://your-api-domain.com';

  Future<Map<String, dynamic>> uploadAndAnalyze(File file) async {
    // Simulate network delay for demo
    await Future.delayed(const Duration(seconds: 3));

    // In production:
    // var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/reports/analyze'));
    // request.files.add(await http.MultipartFile.fromPath('file', file.path));
    // var response = await request.send();
    // var body = await response.stream.bytesToString();
    // return jsonDecode(body);

    return _mockReportData();
  }

  Map<String, dynamic> _mockReportData() {
    return {
      "patient_info": {
        "name": "[NAME-REDACTED]",
        "age": 45,
        "gender": "Female",
        "id": "[MRN-REDACTED]"
      },
      "simple_explanation":
          "Your blood test shows slightly high cholesterol. This means there is more fat in your blood than ideal. It is not an emergency, but you should eat less fried food and exercise more. Your doctor may suggest medicine if it does not improve in 3 months.",
      "medical_summary":
          "Total cholesterol: 240 mg/dL (elevated). LDL: 160 mg/dL (high). HDL: 50 mg/dL (normal). Triglycerides: 180 mg/dL (borderline). Liver enzymes mildly elevated.",
      "key_findings": [
        {
          "title": "High Cholesterol",
          "value": "240 mg/dL",
          "status": "elevated",
          "normal_range": "< 200 mg/dL",
          "explanation": "Your total cholesterol is higher than the healthy limit."
        },
        {
          "title": "LDL (Bad Cholesterol)",
          "value": "160 mg/dL",
          "status": "high",
          "normal_range": "< 100 mg/dL",
          "explanation": "This is the 'bad' cholesterol that can clog arteries."
        },
        {
          "title": "HDL (Good Cholesterol)",
          "value": "50 mg/dL",
          "status": "normal",
          "normal_range": "> 40 mg/dL",
          "explanation": "Your good cholesterol is in the healthy range."
        },
        {
          "title": "Blood Sugar",
          "value": "105 mg/dL",
          "status": "normal",
          "normal_range": "70-100 mg/dL",
          "explanation": "Slightly above ideal but not diabetic."
        }
      ],
      "temporal_analysis": [
        {
          "date": "2024-01-15",
          "event": "Cholesterol: 220 mg/dL",
          "trend": "up"
        },
        {
          "date": "2024-06-20",
          "event": "Cholesterol: 230 mg/dL",
          "trend": "up"
        },
        {
          "date": "2024-12-10",
          "event": "Cholesterol: 240 mg/dL",
          "trend": "up"
        }
      ],
      "risk_assessment": {
        "overall_risk": "MEDIUM",
        "cardiovascular_risk": "Elevated due to high LDL and family history.",
        "diabetes_risk": "Low. Blood sugar is borderline but manageable.",
        "recommendations": [
          "Reduce saturated fat intake (less red meat, butter, cheese)",
          "Exercise 30 minutes daily (brisk walking, swimming)",
          "Recheck lipid panel in 3 months",
          "Consider statin therapy if no improvement with lifestyle changes",
          "Increase fiber intake (oats, beans, vegetables)"
        ]
      },
      "causal_analysis": [
        {
          "cause": "Diet high in saturated fats",
          "effect": "Elevated LDL cholesterol",
          "confidence": 0.85,
          "evidence": "Patient reported daily consumption of red meat and processed foods."
        },
        {
          "cause": "Sedentary lifestyle",
          "effect": "Low HDL and weight gain",
          "confidence": 0.78,
          "evidence": "Patient reports < 2 hours physical activity per week."
        },
        {
          "cause": "Family history of hyperlipidemia",
          "effect": "Genetic predisposition to high cholesterol",
          "confidence": 0.72,
          "evidence": "Father and paternal uncle both diagnosed with high cholesterol before age 50."
        }
      ],
      "medications": [
        {
          "name": "Atorvastatin",
          "dosage": "20 mg",
          "frequency": "Once daily at bedtime",
          "purpose": "Lower LDL cholesterol",
          "side_effects": ["Muscle aches", "Headache", "Nausea"]
        }
      ],
      "follow_up": {
        "next_appointment": "2025-03-15",
        "tests_needed": ["Lipid panel", "Liver function tests"],
        "urgency": "Non-urgent. Schedule within 3 months."
      }
    };
  }
}

// ─────────────────────────────────────────────────────────────
// HOME SCREEN (3-TAB ARCHITECTURE)
// ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  MedicalReport? _currentReport;
  final TTSService _tts = TTSService();
  final ReportService _reportService = ReportService();
  bool _isAnalyzing = false;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pdfPath = result.files.single.path;
          _isAnalyzing = true;
        });

        final file = File(result.files.single.path!);
        final data = await _reportService.uploadAndAnalyze(file);

        setState(() {
          _currentReport = MedicalReport(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            filename: result.files.single.name,
            uploadedAt: DateTime.now(),
            data: data,
            pdfPath: _pdfPath,
          );
          _isAnalyzing = false;
          _selectedIndex = 1; // Auto-switch to Report tab
        });
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showError('Failed to upload: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      _buildReportTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MediSimple",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff0F766E),
                Color(0xff14B8A6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_currentReport != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareReport(),
            ),
        ],
      ),
      floatingActionButton: _currentReport != null && _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                final text = _currentReport!.data['simple_explanation'] ?? '';
                if (text.isNotEmpty) _tts.speak(text);
              },
              icon: const Icon(Icons.volume_up),
              label: const Text("Listen"),
              backgroundColor: const Color(0xff0F766E),
              foregroundColor: Colors.white,
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isAnalyzing ? _buildAnalyzingScreen() : tabs[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavTapped,
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: "Report",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: HOME / UPLOAD ───
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff0F766E), Color(0xff14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0F766E).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome to MediSimple",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Upload your medical report and get a simple, easy-to-understand explanation powered by AI.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildFeatureChip(Icons.security, "HIPAA Safe"),
                    const SizedBox(width: 8),
                    _buildFeatureChip(Icons.speed, "Instant"),
                    const SizedBox(width: 8),
                    _buildFeatureChip(Icons.translate, "Simple"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Upload Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.teal.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff0F766E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    size: 60,
                    color: Color(0xff0F766E),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Upload Medical Report",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Supports PDF, JPG, PNG",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text(
                    "Choose File",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff0F766E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 52),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Recent Reports
          if (_currentReport != null) ...[
            _buildSectionHeader(Icons.history, "Recent Report"),
            const SizedBox(height: 12),
            _buildReportCard(_currentReport!),
          ],

          const SizedBox(height: 20),

          // How It Works
          _buildSectionHeader(Icons.help_outline, "How It Works"),
          const SizedBox(height: 12),
          _buildHowItWorksStep("1", "Upload", "Select your medical report PDF or image."),
          _buildHowItWorksStep("2", "Analyze", "AI reads and understands your report."),
          _buildHowItWorksStep("3", "Simplify", "Get a clear, simple explanation."),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(String number, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xff0F766E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: REPORT ───
  Widget _buildReportTab() {
    if (_currentReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No report yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Upload a medical report to see it here.",
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Report"),
            ),
          ],
        ),
      );
    }

    final data = _currentReport!.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff0F766E), Color(0xff14B8A6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentReport!.filename,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Uploaded: ${_formatDate(_currentReport!.uploadedAt)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Simple Explanation
          _buildSectionHeader(Icons.chat_bubble_outline, "Simple Explanation"),
          const SizedBox(height: 12),
          _buildContentCard(
            child: Text(
              data['simple_explanation'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xff374151),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Risk Assessment Badge
          _buildRiskBadge(data['risk_assessment']?['overall_risk'] ?? 'LOW'),

          const SizedBox(height: 24),

          // Key Findings
          _buildSectionHeader(Icons.fact_check, "Key Findings"),
          const SizedBox(height: 12),
          ..._buildKeyFindings(data['key_findings'] ?? []),

          const SizedBox(height: 24),

          // Temporal Analysis
          _buildSectionHeader(Icons.timeline, "Trend Over Time"),
          const SizedBox(height: 12),
          _buildTemporalAnalysis(data['temporal_analysis'] ?? []),

          const SizedBox(height: 24),

          // Causal Analysis
          _buildSectionHeader(Icons.account_tree, "Why This Happened"),
          const SizedBox(height: 12),
          ..._buildCausalAnalysis(data['causal_analysis'] ?? []),

          const SizedBox(height: 24),

          // Recommendations
          _buildSectionHeader(Icons.lightbulb_outline, "Recommendations"),
          const SizedBox(height: 12),
          _buildRecommendations(data['risk_assessment']?['recommendations'] ?? []),

          const SizedBox(height: 24),

          // Medications
          if ((data['medications'] ?? []).isNotEmpty) ...[
            _buildSectionHeader(Icons.medication, "Medications"),
            const SizedBox(height: 12),
            ..._buildMedications(data['medications']),
            const SizedBox(height: 24),
          ],

          // Follow Up
          _buildSectionHeader(Icons.calendar_today, "Follow Up"),
          const SizedBox(height: 12),
          _buildFollowUp(data['follow_up'] ?? {}),

          const SizedBox(height: 24),

          // Medical Summary (Raw)
          _buildSectionHeader(Icons.summarize, "Medical Summary"),
          const SizedBox(height: 12),
          _buildContentCard(
            child: Text(
              data['medical_summary'] ?? '',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String risk) {
    final colors = {
      'EMERGENCY': Colors.red.shade700,
      'HIGH': Colors.orange.shade700,
      'MEDIUM': Colors.amber.shade700,
      'LOW': Colors.green.shade700,
    };
    final bgColors = {
      'EMERGENCY': Colors.red.shade50,
      'HIGH': Colors.orange.shade50,
      'MEDIUM': Colors.amber.shade50,
      'LOW': Colors.green.shade50,
    };
    final icons = {
      'EMERGENCY': Icons.warning_amber,
      'HIGH': Icons.priority_high,
      'MEDIUM': Icons.info_outline,
      'LOW': Icons.check_circle_outline,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColors[risk.toUpperCase()] ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors[risk.toUpperCase()] ?? Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icons[risk.toUpperCase()] ?? Icons.info,
            color: colors[risk.toUpperCase()] ?? Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Overall Risk: ${risk.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors[risk.toUpperCase()] ?? Colors.grey,
                  ),
                ),
                Text(
                  risk == 'LOW'
                      ? "Your results look good. Keep maintaining your health."
                      : "Please follow the recommendations and consult your doctor.",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKeyFindings(List findings) {
    return findings.map<Widget>((f) {
      final status = f['status'];
      final statusColor = {
        'normal': Colors.green,
        'elevated': Colors.orange,
        'high': Colors.red,
        'borderline': Colors.amber,
      }[status] ?? Colors.grey;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  f['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  f['value'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0F766E),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "(Normal: ${f['normal_range']})",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              f['explanation'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTemporalAnalysis(List timeline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: timeline.map<Widget>((item) {
          final isUp = item['trend'] == 'up';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isUp ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['event'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatDateString(item['date']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? Colors.red : Colors.green,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildCausalAnalysis(List causes) {
    return causes.map<Widget>((c) {
      final confidence = (c['confidence'] as double? ?? 0.0);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_forward, color: Color(0xff0F766E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${c['cause']} → ${c['effect']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  confidence > 0.8
                      ? Colors.green
                      : confidence > 0.6
                          ? Colors.amber
                          : Colors.orange,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Confidence: ${(confidence * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              c['evidence'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecommendations(List recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff0F766E).withOpacity(0.3)),
      ),
      child: Column(
        children: recommendations.map<Widget>((rec) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xff0F766E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildMedications(List meds) {
    return meds.map<Widget>((med) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: Color(0xff0F766E)),
                const SizedBox(width: 10),
                Text(
                  med['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMedDetail("Dosage", med['dosage']),
            _buildMedDetail("Frequency", med['frequency']),
            _buildMedDetail("Purpose", med['purpose']),
            if ((med['side_effects'] ?? []).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Possible side effects:",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Wrap(
                spacing: 6,
                children: (med['side_effects'] as List).map<Widget>((se) {
                  return Chip(
                    label: Text(
                      se,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.amber.shade50,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMedDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUp(Map followUp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedDetail("Next Appointment", followUp['next_appointment'] ?? 'TBD'),
          const SizedBox(height: 8),
          Text(
            "Tests needed:",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Wrap(
            spacing: 8,
            children: (followUp['tests_needed'] ?? []).map<Widget>((test) {
              return Chip(
                avatar: const Icon(Icons.science, size: 16, color: Color(0xff0F766E)),
                label: Text(test),
                backgroundColor: const Color(0xffF0FDFA),
                side: BorderSide(color: Colors.teal.shade200),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Color(0xffD97706), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    followUp['urgency'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: SETTINGS ───
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.person_outline, "Account"),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.person,
              title: "Profile",
              subtitle: "Manage your personal information",
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: "Notifications",
              subtitle: "Appointment and health reminders",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.security, "Privacy & Security"),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: "Biometric Lock",
              subtitle: "Use fingerprint or face ID",
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: const Color(0xff0F766E),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.delete_outline,
              title: "Clear All Data",
              subtitle: "Remove all reports from this device",
              onTap: () => _confirmClearData(),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.help_outline, "Support"),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.help_center_outlined,
              title: "Help Center",
              subtitle: "FAQs and troubleshooting",
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              subtitle: "How we protect your data",
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: "About MediSimple",
              subtitle: "Version 1.0.0",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 40),
          Center(
            child: Text(
              "MediSimple v1.0.0\n© 2026 MediSimple Health",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xff0F766E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xff0F766E)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ─── SHARED WIDGETS ───
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff0F766E), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReportCard(MedicalReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff0F766E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xff0F766E),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.filename,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(report.uploadedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // ─── ANALYZING SCREEN ───
  Widget _buildAnalyzingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: const Color(0xff0F766E),
            highlightColor: const Color(0xff14B8A6),
            child: const Icon(
              Icons.health_and_safety,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Analyzing your report...",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Our AI is reading your medical report and generating\na simple explanation. This may take a few seconds.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xffE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff0F766E)),
              minHeight: 6,
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day} ${_monthName(date.month)} ${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }

  void _shareReport() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Share functionality coming soon!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text(
          "This will permanently delete all your medical reports from this device. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _currentReport = null;
                _pdfPath = null;
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
