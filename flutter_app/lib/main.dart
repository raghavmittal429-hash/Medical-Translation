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
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:typed_data';
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
      theme: MediSimpleTheme.light,
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
  int _currentIndex = 0;
  FlutterTts _tts = FlutterTts();

  // Speech playback state. _activeSpeechKey stores the *raw* (un-
  // sanitized) text passed to _speak(), so each section card's speak
  // button can check "is this card the one currently playing?" by
  // comparing against its own `content` string directly, without having
  // to re-run sanitization just to compare.
  String? _activeSpeechKey;
  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _audioUnlocked = false;
  // Web Audio API context -- unlocked once on first button tap and stays
  // unlocked for the entire session. This is the correct way to play audio
  // after async gaps (Sarvam fetch takes 1-5s, which expires Chrome's
  // HTMLAudioElement autoplay user-gesture context, causing silent failures).
  html.AudioContext? _audioContext;
  html.AudioBufferSourceNode? _currentSource;

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

  // Tracks whether the underlying engine currently has an explicit voice
  // pinned via setVoice(), purely so we can skip redundant clear calls.
  bool _voiceExplicitlyPinned = false;

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    // Keep _isSpeaking/_isPaused truthful for the device-voice path by
    // reacting to the engine's own lifecycle events, instead of guessing
    // from whether an awaited Future has returned yet.
    _tts.setStartHandler(() {
      if (mounted) setState(() { _isSpeaking = true; _isPaused = false; });
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() { _isSpeaking = false; _isPaused = false; _activeSpeechKey = null; });
    });
    _tts.setPauseHandler(() {
      if (mounted) setState(() { _isSpeaking = false; _isPaused = true; });
    });
    _tts.setContinueHandler(() {
      if (mounted) setState(() { _isSpeaking = true; _isPaused = false; });
    });
    _tts.setErrorHandler((dynamic msg) {
      if (mounted) setState(() { _isSpeaking = false; _isPaused = false; _activeSpeechKey = null; });
    });

    await _loadAvailableVoices();
    await _applyVoiceForLanguage(_selectedLanguage);
  }

  // Browsers (Chrome in particular) load the speechSynthesis voice list
  // asynchronously, so a getVoices() call made too early can return an
  // empty list even though voices are available a moment later. Retry a
  // few times before giving up.
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

  // Returns just the language portion of a locale, e.g. "hi-IN" -> "hi".
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

    // Re-check available voices every time: some platforms finish loading
    // them after first launch, and we want the freshest list when the
    // user switches languages.
    if (_availableVoices.isEmpty) {
      await _loadAvailableVoices();
    }

    final localeMatches = _availableVoices.where((voice) {
      final voiceLocale = _voiceLocaleOf(voice).toLowerCase();
      // match any of the candidate locales or the base language code
      return targetLocales.map((e) => e.toLowerCase()).contains(voiceLocale) ||
          _languageCodeOf(voiceLocale) == targetLangCode;
    }).toList();

    await _trySetLanguage(targetLocales);

    if (localeMatches.isNotEmpty) {
      // A genuine voice exists for this language: pick the smoothest
      // sounding one and pin it explicitly.
      final bestVoice = _preferredVoice(localeMatches);
      _selectedVoiceName = _voiceNameOf(bestVoice);
      await _setTtsVoice(bestVoice);
      _voiceExplicitlyPinned = true;
    } else if (_voiceExplicitlyPinned) {
      // No voice exists for this language, but a voice IS currently
      // pinned from a previous language. On the stock flutter_tts web
      // engine there was no way to unpin it, so the engine kept speaking
      // every new language in the *old* voice — usually mispronouncing
      // it or producing no audible sound at all for scripts that voice
      // can't read, no matter what setLanguage() was called with
      // afterwards. We use the patched vendor/flutter_tts package (see
      // pubspec.yaml dependency_overrides) which clears the pinned voice
      // when given empty name/locale, letting setLanguage() actually
      // take effect again.
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

  // Scores a voice by how natural/smooth it's likely to sound, based on
  // common naming conventions used by OS and browser TTS engines. Higher
  // is smoother. This lets us automatically prefer modern neural/online
  // voices over old robotic "compact"/eSpeak-style ones whenever both are
  // available for the same language.
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
    if (name.contains('compact') || name.contains('espeak') || name.contains('festival')) {
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
        if (voice.containsKey('name')) settings['name'] = voice['name'].toString();
        if (voice.containsKey('locale')) settings['locale'] = voice['locale'].toString();
        if (settings.isNotEmpty) {
          await _tts.setVoice(settings);
        }
      }
    } catch (_) {
      // Ignore voice selection failure; fallback to language-only mode.
    }
  }

  // Explicitly unpins any previously selected voice. Relies on the patch
  // in vendor/flutter_tts/lib/flutter_tts_web.dart that treats empty
  // name/locale as "clear the pinned voice" instead of a no-op.
  Future<void> _clearTtsVoice() async {
    try {
      await _tts.setVoice({'name': '', 'locale': ''});
    } catch (_) {
      // Ignore; worst case the previous voice stays pinned.
    }
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

  // Base URL is injected at build time via --dart-define=API_BASE_URL=https://your-app.up.railway.app
  // Falls back to localhost for local development
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

    // Poll every 2 seconds for job status
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
            setState(() { _isLoading = false; });
            _pollingTimer?.cancel();
            _currentJobId = null;
          }
        } else {
          _showError('Error checking job status');
          setState(() { _isLoading = false; });
          _pollingTimer?.cancel();
          _currentJobId = null;
        }
      } catch (e) {
        _showError('Connection error while checking status: $e');
        setState(() { _isLoading = false; });
        _pollingTimer?.cancel();
        _currentJobId = null;
      }
    });
  
  }

  // Report text often carries markdown-style formatting (headings, bold
  // markers, horizontal-rule separators like "======" or "------") that
  // displays/reads fine as raw markdown but looks/sounds wrong once it's
  // dropped into plain text -- "======" gets read aloud as "equal equal
  // equal..." by TTS, and shows up literally as "======" in the PDF
  // export. This is the shared cleanup used by both: it strips that kind
  // of decoration while leaving normal punctuation (the single "-" in
  // "13.0-17.0", "%", etc.) completely untouched, since those only
  // trigger on 3+ repeats. Newlines are preserved here so callers that
  // care about paragraph/line structure (the PDF builder) still can.
  String _stripDecorativeSymbols(String input) {
    var text = input;

    // Markdown emphasis/code markers: keep the inner words, drop the
    // symbols, e.g. "**important**" -> "important", "`eGFR`" -> "eGFR".
    text = text.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'__(.*?)__'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m.group(1) ?? '');

    // Markdown headings ("## Summary" -> "Summary") and bullet markers
    // ("- item" / "* item" -> "item") at the start of a line.
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '');

    // Decorative separator lines/runs: any non-word, non-space character
    // repeated 3+ times in a row ("======", "------", "******", "~~~~").
    // \w already excludes most of these, but underscores count as word
    // characters in regex, so handle "___" runs explicitly too.
    text = text.replaceAll(RegExp(r'([^\w\s])\1{2,}'), ' ');
    text = text.replaceAll(RegExp(r'_{3,}'), ' ');

    // Leftover table pipes and stray backticks/asterisks/underscores that
    // weren't part of a matched pair above.
    text = text.replaceAll(RegExp(r'[|`*_#]'), ' ');

    // Emoji and pictographic symbols (warning signs, checkmarks, arrows,
    // etc.). Some TTS engines vocalize these literally by name -- a "⚠️"
    // gets read aloud as "warning" -- which is meaningless and jarring in
    // a medical report. Covers the common emoji/symbol Unicode blocks:
    // Miscellaneous Symbols & Dingbats, Misc Symbols and Arrows, and the
    // full modern emoji range (U+1F000-U+1FFFF), plus the variation
    // selector and zero-width joiner used to combine emoji.
    text = text.replaceAll(
      RegExp(r'[\u2600-\u27BF\u2B00-\u2BFF\u{1F000}-\u{1FFFF}\uFE0E\uFE0F\u200D]', unicode: true),
      ' ',
    );

    // Collapse runs of spaces/tabs the above left behind, but keep
    // newlines intact for callers that rely on line/paragraph structure.
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'[ \t]*\n[ \t]*'), '\n');

    return text.trim();
  }

  // TTS-specific wrapper: speech doesn't care about line breaks, only
  // about natural pauses, so this additionally folds newlines into ". "
  // after the shared symbol-stripping above.
  String _sanitizeForSpeech(String input) {
    var text = _stripDecorativeSymbols(input);
    text = text.replaceAll(RegExp(r'\n\s*\n+'), '. ');
    text = text.replaceAll('\n', '. ');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    return text.trim();
  }

  // Creates and unlocks the Web Audio API context synchronously within a
  // user gesture handler. Called at the very top of _speak() before any
  // await. Once the AudioContext is in "running" state it stays running
  // for the whole page session -- audio decoded and played through it
  // never needs another user gesture, even after a 5-second async fetch.
  void _ensureAudioContextUnlocked() {
    if (_audioContext != null) return;
    try {
      _audioContext = html.AudioContext();
      // Play a 1-sample silent buffer immediately to transition the context
      // from "suspended" to "running" within the synchronous gesture handler.
      final buf = _audioContext!.createBuffer(1, 1, 22050.0);
      final src = _audioContext!.createBufferSource();
      src.buffer = buf;
      src.connectNode(_audioContext!.destination!);
      src.start(0);
    } catch (_) {
      // AudioContext unavailable -- _playAudioBytes will fall back to
      // HTMLAudioElement which may or may not work depending on the browser.
      _audioContext = null;
    }
  }

  Future<void> _speak(String rawText) async {
    final text = _sanitizeForSpeech(rawText);
    if (text.isEmpty || !_ttsEnabled) return;

    // Unlock the Web Audio API context SYNCHRONOUSLY before any await.
    // This must happen in the same call stack as the button tap so Chrome
    // considers it a genuine user gesture. After this point, audio can
    // play even after a 5-second async Sarvam fetch.
    _ensureAudioContextUnlocked();

    // Stop everything currently playing BEFORE starting anything new.
    await _stopSpeaking();

    setState(() {
      _activeSpeechKey = rawText;
      _isSpeaking = true;
      _isPaused = false;
    });

    // Always try the backend (Sarvam AI) first for every language.
    try {
      await _speakViaBackend(text, _selectedLanguage, speechKey: rawText);
      return;
    } catch (e) {
      debugPrint('Backend TTS failed, falling back to device voice: $e');
    }

    // Last resort: device voice (flutter_tts / Edge TTS).
    await _tts.stop();
    await _applyVoiceForLanguage(_selectedLanguage);
    try {
      await _tts.speak(text).timeout(const Duration(seconds: 90));
    } catch (_) {
      // Nothing more to try.
    } finally {
      if (mounted && _activeSpeechKey == rawText) {
        setState(() { _isSpeaking = false; _isPaused = false; _activeSpeechKey = null; });
      }
    }
  }

  Future<void> _pauseSpeaking() async {
    // AudioContext path: suspend the context (pauses all audio)
    if (_audioContext != null && _audioContext!.state == 'running') {
      await _audioContext!.suspend();
      if (mounted) setState(() { _isSpeaking = false; _isPaused = true; });
    } else {
      // flutter_tts fallback path
      await _tts.pause();
    }
  }

  Future<void> _resumeSpeaking() async {
    if (_audioContext != null && _audioContext!.state == 'suspended') {
      await _audioContext!.resume();
      if (mounted) setState(() { _isSpeaking = true; _isPaused = false; });
    } else {
      await _tts.resume();
    }
  }

  Future<void> _stopSpeaking() async {
    // Stop AudioContext source
    try { _currentSource?.stop(); } catch (_) {}
    _currentSource = null;
    // Resume context so it's ready for next play (stop ≠ suspend)
    if (_audioContext != null && _audioContext!.state == 'suspended') {
      try { await _audioContext!.resume(); } catch (_) {}
    }
    // Stop flutter_tts fallback too
    await _tts.stop();
    if (mounted) {
      setState(() { _isSpeaking = false; _isPaused = false; _activeSpeechKey = null; });
    }
  }

  // Splits text into sentence-sized chunks for progressive playback.
  // Smaller chunks = faster first-audio, at the cost of a tiny gap between
  // sentences. 350 chars gives roughly 2-3 sentences per chunk which
  // Sarvam can synthesize in ~0.5-1 second.
  // Splits text into chunks optimised for low-latency progressive playback.
  // The FIRST chunk is tiny (≤50 chars, ~1 short sentence) so it arrives from
  // Sarvam in ~1-2 seconds. Subsequent chunks are larger (≤300 chars) for
  // efficiency. Both sizes prefer sentence boundaries over hard cuts.
  List<String> _splitIntoSpeechChunks(String text) {
    text = text.trim();
    if (text.isEmpty) return [];

    final result = <String>[];
    // First chunk: very short for fast first-audio latency
    final first = _cutChunk(text, 50);
    result.add(first);
    text = text.substring(first.length).trim();

    // Remaining chunks: larger for efficiency
    while (text.isNotEmpty) {
      final chunk = _cutChunk(text, 300);
      result.add(chunk);
      text = text.substring(chunk.length).trim();
    }
    return result.where((c) => c.isNotEmpty).toList();
  }

  // Returns the longest prefix of [text] up to [maxLen] that ends at a
  // sentence boundary. Falls back to a hard cut if no boundary is found.
  String _cutChunk(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    final slice = text.substring(0, maxLen);
    final cut = [
      slice.lastIndexOf('. '),
      slice.lastIndexOf('। '),
      slice.lastIndexOf('? '),
      slice.lastIndexOf('! '),
      slice.lastIndexOf('\n'),
      slice.lastIndexOf(', '),
    ].where((i) => i > 20).fold(-1, (best, i) => i > best ? i : best);
    return cut < 0 ? slice : text.substring(0, cut + 1);
  }

  // Fetches audio for a single text chunk from the backend.
  Future<Uint8List> _fetchChunkAudio(String chunk, String langCode) async {
    final ttsUrl = _buildApiUrl('/synthesize');
    final response = await http.post(
      ttsUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': chunk, 'language': langCode}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Backend TTS failed (${response.statusCode}): ${response.body}');
    }
    return response.bodyBytes;
  }

  // Plays audio bytes and waits until playback finishes.
  // Uses Web Audio API (AudioContext) as primary path -- this works
  // regardless of how long ago the user tapped the button, because the
  // AudioContext was unlocked synchronously in _speak() and stays running.
  // Falls back to HTMLAudioElement if AudioContext is unavailable.
  Future<bool> _playAudioBytes(Uint8List bytes, String speechKey) async {
    if (_audioContext != null) {
      return _playViAudioContext(bytes);
    }
    return _playViaAudioElement(bytes);
  }

  Future<bool> _playViAudioContext(Uint8List bytes) async {
    try {
      // Resume context if the browser suspended it during inactivity
      if (_audioContext!.state == 'suspended') {
        await _audioContext!.resume();
      }

      // Decode the MP3 bytes into a PCM AudioBuffer
      final audioBuffer = await _audioContext!.decodeAudioData(bytes.buffer);

      final source = _audioContext!.createBufferSource();
      source.buffer = audioBuffer;
      source.connectNode(_audioContext!.destination!);
      _currentSource = source;

      final completer = Completer<bool>();
      source.onEnded.listen((_) {
        _currentSource = null;
        if (!completer.isCompleted) completer.complete(true);
      });

      source.start(0);
      return completer.future;
    } catch (e) {
      _currentSource = null;
      debugPrint('[audio] AudioContext playback failed: $e, trying AudioElement');
      return _playViaAudioElement(bytes);
    }
  }

  Future<bool> _playViaAudioElement(Uint8List bytes) async {
    final blob = html.Blob([bytes], 'audio/mpeg');
    final audioUrl = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(audioUrl);

    final completer = Completer<bool>();
    audio.onEnded.listen((_) {
      html.Url.revokeObjectUrl(audioUrl);
      if (!completer.isCompleted) completer.complete(true);
    });
    audio.onError.listen((_) {
      html.Url.revokeObjectUrl(audioUrl);
      if (!completer.isCompleted) completer.complete(false);
    });

    try {
      await audio.play();
    } catch (e) {
      html.Url.revokeObjectUrl(audioUrl);
      throw Exception('Audio blocked by browser: $e. Tap again.');
    }

    return completer.future;
  }

  // Backend TTS with fully parallel chunk fetching.
  // ALL chunks are fetched from Sarvam simultaneously the moment the
  // button is tapped. Chunk 0 (50 chars, ~1 short sentence) is tiny so
  // it arrives from Sarvam in ~1-2 seconds and starts playing immediately.
  // Chunks 1-N arrive during that playback -- when chunk 0 ends, chunk 1
  // is already in memory and starts instantly with zero gap.
  Future<void> _speakViaBackend(String text, String language, {String? speechKey}) async {
    final langCode = _languageCodeFor(language);
    final key = speechKey ?? text;
    final chunks = _splitIntoSpeechChunks(text);
    if (chunks.isEmpty) return;

    // Launch ALL fetches in parallel immediately. Don't await anything yet --
    // just fire every request at once so Sarvam can work on all of them
    // simultaneously while we await them in order below.
    final futures = chunks.map((c) => _fetchChunkAudio(c, langCode)).toList();

    for (var i = 0; i < chunks.length; i++) {
      if (_activeSpeechKey != key || !_isSpeaking) {
        // User stopped -- cancel remaining fetches by letting them complete
        // and discarding the result (HTTP doesn't have cancellation in Dart)
        return;
      }

      // Await this chunk's fetch (may already be done if Sarvam was fast)
      final Uint8List bytes;
      try {
        bytes = await futures[i];
      } catch (e) {
        // One chunk failed -- stop rather than playing corrupted audio
        debugPrint('[tts] chunk $i fetch failed: $e');
        break;
      }

      if (_activeSpeechKey != key || !_isSpeaking) return;

      final completed = await _playAudioBytes(bytes, key);

      if (!completed || _activeSpeechKey != key || !_isSpeaking) return;
    }

    if (mounted && _activeSpeechKey == key) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _activeSpeechKey = null;
      });
    }
  }

  // Returns an ordered list of locale candidates (best -> fallback).
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

  // Try setting the TTS language from a list of candidates until one succeeds.
  Future<void> _trySetLanguage(List<String> locales) async {
    for (final locale in locales) {
      try {
        await _tts.setLanguage(locale);
        return;
      } catch (_) {
        // try next
      }
    }
    // fallback
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

      // Pick the right Noto font based on the selected language script
      String fontAssetRegular = 'assets/fonts/NotoSans-Regular.ttf';
      String fontAssetBold    = 'assets/fonts/NotoSans-Bold.ttf';
      if (['Hindi', 'Marathi', 'Nepali'].contains(lang)) {
        fontAssetRegular = 'assets/fonts/NotoSansDevanagari-Regular.ttf';
        fontAssetBold    = 'assets/fonts/NotoSansDevanagari-Bold.ttf';
      } else if (lang == 'Tamil') {
        fontAssetRegular = 'assets/fonts/NotoSansTamil-Regular.ttf';
        fontAssetBold    = 'assets/fonts/NotoSansTamil-Regular.ttf';
      } else if (['Bengali', 'Assamese'].contains(lang)) {
        fontAssetRegular = 'assets/fonts/NotoSansBengali-Regular.ttf';
        fontAssetBold    = 'assets/fonts/NotoSansBengali-Regular.ttf';
      } else if (['Arabic', 'Urdu', 'Persian'].contains(lang)) {
        fontAssetRegular = 'assets/fonts/NotoSansArabic-Regular.ttf';
        fontAssetBold    = 'assets/fonts/NotoSansArabic-Regular.ttf';
      }

      final fontDataRegular = await rootBundle.load(fontAssetRegular);
      final fontDataBold    = await rootBundle.load(fontAssetBold);
      final ttfRegular = pw.Font.ttf(fontDataRegular);
      final ttfBold    = pw.Font.ttf(fontDataBold);

      // Also load NotoSans as fallback for Latin characters in mixed content
      final fontDataFallback = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final ttfFallback = pw.Font.ttf(fontDataFallback);

      final suggestions = (data['suggestions'] as List? ?? []).map((s) => s.toString()).toList();
      final translatedSuggestions = (data['translated_suggestions'] as List? ?? []).map((s) => s.toString()).toList();
      final translatedExplanation = (data['translated_explanation'] ?? '').toString();
      final diseaseEn    = (data['disease_explanation_en'] ?? '').toString();
      final solutionEn   = (data['solution_plan_en'] ?? '').toString();
      final diseaseLang  = (data['disease_explanation_lang'] ?? data['disease_explanation_hi'] ?? '').toString();
      final solutionLang = (data['solution_plan_lang'] ?? data['solution_plan_hi'] ?? '').toString();
      final medicalSummary    = (data['medical_summary'] ?? '').toString();
      final simpleExplanation = (data['simple_explanation'] ?? '').toString();

      // Each pw.Text must fit in one page — split long body into sentences so
      // MultiPage can break between them. Never wrap text in Container/Padding/Column.
      final List<pw.Widget> items = [];
      final _bodyStyle  = pw.TextStyle(font: ttfRegular, fontFallback: [ttfFallback], fontSize: 10, lineSpacing: 5);
      final _titleStyle = pw.TextStyle(font: ttfBold, fontFallback: [ttfFallback], fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900);
      final _headerStyle = pw.TextStyle(font: ttfBold, fontFallback: [ttfFallback], fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900);
      final _subHeaderStyle = pw.TextStyle(font: ttfRegular, fontFallback: [ttfFallback], fontSize: 9, color: PdfColors.grey600);
      final _riskStyle = pw.TextStyle(font: ttfBold, fontFallback: [ttfFallback], fontSize: 10, fontWeight: pw.FontWeight.bold,
          color: risk > 0.6 ? PdfColors.red800 : risk > 0.3 ? PdfColors.orange800 : PdfColors.green800);
      final _footerStyle = pw.TextStyle(font: ttfRegular, fontFallback: [ttfFallback], fontSize: 8, color: PdfColors.grey500);

      // Split on sentence endings or newlines so each chunk is small
      List<String> _splitBody(String body) {
        final raw = _stripDecorativeSymbols(body).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        final List<String> parts = [];
        for (final para in raw.split('\n')) {
          final p = para.trim();
          // A line that was purely a decorative separator ("======",
          // "------", etc.) becomes empty after stripping above -- skip
          // it entirely instead of adding a blank paragraph/bullet.
          if (p.isEmpty) continue;
          // Further split long paragraphs on '. ' boundaries (~150 chars max each)
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
        return parts.isEmpty ? [] : parts;
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
          // Each bullet may itself be long — split it too
          final chunks = _splitBody(b);
          if (chunks.isEmpty) continue; // bullet was purely decorative symbols
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
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('Medical Report Summary', style: _headerStyle),
                    pw.Text('Generated by MediSimple  \u2022  ${data['report_date'] ?? ""}', style: _subHeaderStyle),
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
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: _footerStyle),
            ],
          ),
          build: (ctx) => items,
        ),
      );
      final bytes = await pdf.save();
      // ignore: avoid_web_libraries_in_flutter
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'medical_report_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ PDF downloaded successfully'),
          backgroundColor: Color(0xFF1565C0),
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
      final url  = _buildApiUrl('/retranslate');
      final body = json.encode({
        'parsed_data':            _reportData!['parsed_data'] ?? '',
        'language':               langName,
        'suggestions':            _reportData!['suggestions'] ?? [],
        'medical_summary':        _reportData!['medical_summary'] ?? '',
        'simplified_explanation': _reportData!['simple_explanation'] ?? '',
        'temporal_analysis':      _reportData!['temporal_analysis'] ?? '',
        'causal_analysis':        _reportData!['causal_analysis'] ?? '',
        'risk_probability':       _reportData!['risk_probability'] ?? 0.0,
        'patient_id':             _reportData!['patient_id'],
        'report_date':            _reportData!['report_date'] ?? '',
        'disease_explanation_en': _reportData!['disease_explanation_en'] ?? '',
        'solution_plan_en':       _reportData!['solution_plan_en'] ?? '',
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('Translation timed out. Please try again.'),
      );

      if (response.statusCode == 200) {
        final newData = json.decode(response.body);
        setState(() {
          _reportData = {
            ..._reportData!,
            'translated_explanation':   newData['translated_explanation'] ?? '',
            'translated_suggestions':   newData['translated_suggestions'] ?? [],
            'disease_explanation_lang': newData['disease_explanation_hi'] ?? newData['disease_explanation_lang'] ?? '',
            'solution_plan_lang':       newData['solution_plan_hi'] ?? newData['solution_plan_lang'] ?? '',
            'disease_explanation_hi':   newData['disease_explanation_hi'] ?? '',
            'solution_plan_hi':         newData['solution_plan_hi'] ?? '',
            'target_language':          langName,
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✓ Translated to $langName'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        _showError('Translation failed (${response.statusCode}). Please try again.');
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
            Icon(Icons.translate, color: Color(0xFFA01A1A)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            child: const Text('OK', style: TextStyle(color: Color(0xFFA01A1A))),
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
              padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language, color: Color(0xFFA01A1A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Language',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          Text('Report will be retranslated automatically',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  // Scrollable language list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _languages.map((lang) {
                        final isSelected = _selectedLanguage == lang['name'];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFDF0F0) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(lang['native']![0],
                              style: TextStyle(
                                fontSize: 18,
                                color: isSelected ? const Color(0xFFA01A1A) : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              )),
                          ),
                          title: Text(lang['name']!,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFFA01A1A) : null,
                            )),
                          subtitle: Text(lang['native']!,
                            style: const TextStyle(fontSize: 12)),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFFA01A1A), size: 22)
                              : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isSelected ? const Color(0xFFFDF0F0) : null,
                          onTap: () {
                            final newLang = lang['name']!;
                            Navigator.pop(context);
                            if (newLang != _selectedLanguage) {
                              setState(() {
                                _selectedLanguage = newLang;
                                // Clear stale translated content so old language doesn't show
                                if (_reportData != null) {
                                  _reportData = {
                                    ..._reportData!,
                                    'translated_explanation':   '',
                                    'translated_suggestions':   [],
                                    'disease_explanation_lang': '',
                                    'solution_plan_lang':       '',
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
            padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hearing, color: Color(0xFFA01A1A), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Voice Model',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                    child: Text('No available voices detected on this device.', style: TextStyle(fontSize: 14)),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: Builder(builder: (context) {
                      final targetLangCode = _languageCodeOf(_ttsLocalesFor(_selectedLanguage).first);
                      final sortedVoices = [..._availableVoices]..sort((a, b) {
                        final aMatches = _languageCodeOf(_voiceLocaleOf(a)) == targetLangCode;
                        final bMatches = _languageCodeOf(_voiceLocaleOf(b)) == targetLangCode;
                        if (aMatches != bMatches) return aMatches ? -1 : 1;
                        return _voiceQualityScore(b).compareTo(_voiceQualityScore(a));
                      });
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedVoices.length,
                        itemBuilder: (context, index) {
                          final voice = sortedVoices[index];
                          final voiceName = _voiceNameOf(voice);
                          final voiceLocale = _voiceLocaleOf(voice);
                          final isSelected = _selectedVoiceName == voiceName;
                          final isRecommended = _languageCodeOf(voiceLocale) == targetLangCode &&
                              _voiceQualityScore(voice) > 0;
                          return ListTile(
                            title: Text(voiceName),
                            subtitle: Text(
                              isRecommended ? '$voiceLocale · Recommended for $_selectedLanguage' : voiceLocale,
                              style: isRecommended
                                  ? const TextStyle(color: Color(0xFFA01A1A), fontWeight: FontWeight.w600)
                                  : null,
                            ),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFA01A1A)) : null,
                            onTap: () async {
                              Navigator.pop(context);
                              setState(() {
                                _selectedVoiceName = voiceName;
                              });
                              await _trySetLanguage(_ttsLocalesFor(_selectedLanguage));
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
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/medisimple_logo.jpg',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'MediSimple',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFA01A1A),
        actions: [
          if (_isTranslating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _showLanguageSelector,
                icon: const Icon(Icons.language, color: Colors.white, size: 18),
                label: Text(
                  _selectedLanguage,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          // Full-screen translating overlay — covers ALL tabs
          if (_isTranslating)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48, height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFA01A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Translating to $_selectedLanguage',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Explanation, suggestions, disease\nand solution are being translated…',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFA01A1A).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_file, color: Colors.grey),
            selectedIcon: Icon(Icons.upload_file, color: Color(0xFFA01A1A)),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.description, color: Color(0xFFA01A1A)),
            label: 'Explain',
          ),
          NavigationDestination(
            icon: Icon(Icons.tips_and_updates_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.tips_and_updates, color: Color(0xFFA01A1A)),
            label: 'Suggestions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFA01A1A)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAEAEA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8BEBE)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety, color: Color(0xFFA01A1A), size: 36),
                SizedBox(height: 12),
                Text(
                  'Medical Report Assistant',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                const Text(
                  '📋 We provide your report in any language that is easy to understand.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildFeatureBadge(Icons.description, 'Explain')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureBadge(Icons.lightbulb_outline, 'Suggestions')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureBadge(Icons.show_chart, 'Risk')),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload PDF Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA01A1A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (_reportData == null || _isDownloadingPdf) ? null : _downloadPdf,
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(_isDownloadingPdf ? 'Generating PDF...' : 'Download PDF Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Only PDF files are supported. Tap the button above to select and upload your report.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFA01A1A),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing Report...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (_reportData != null) ...[
            const SizedBox(height: 24),
            _buildResultOverview(),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => setState(() => _currentIndex = 2),
              icon: const Icon(Icons.tips_and_updates),
              label: const Text('Open Suggestions'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA01A1A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8BEBE)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFA01A1A), size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverview() {
    final risk = ((_reportData!['risk_probability'] ?? 0) as num).toDouble();
    final factors = _causalFactors();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Report Processed Successfully',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusPill(_riskLabel(risk), _riskColor(risk)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: risk.clamp(0, 1).toDouble(),
              color: _riskColor(risk),
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 10),
            Text(
              'Risk probability: ${(risk * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.analytics, '${factors.length} risk factors'),
                _buildInfoChip(Icons.volume_up, 'Voice support'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFFA01A1A)),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: const Color(0xFFE8BEBE)),
      backgroundColor: const Color(0xFFFAEAEA),
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic> _causalAnalysis() {
    final report = _reportData;
    if (report == null) return {};
    final value = report['causal_analysis'];
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = json.decode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  List<Map<String, dynamic>> _causalFactors() {
    final factors = _causalAnalysis()['causal_factors'];
    if (factors is List) {
      return factors
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
    }
    return const [];
  }

  String _riskExplanation() {
    final analysis = _causalAnalysis();
    final explanation = analysis['causal_explanation']?.toString();
    if (explanation != null && explanation.trim().isNotEmpty) return explanation;
    return 'Upload a report to see why this risk level was calculated.';
  }

  Color _riskColor(double risk) {
    if (risk < 0.35) return Colors.green;
    if (risk < 0.75) return Colors.orange;
    return Colors.red;
  }

  String _riskLabel(double risk) {
    if (risk < 0.35) return 'Low';
    if (risk < 0.75) return 'Medium';
    return 'High';
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
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Upload a medical report to get started',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a PDF report to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
          // Medical Summary Card
          _buildSectionCard(
            title: 'MediSimple',
            icon: Icons.medical_information,
            content: _reportData!['medical_summary'] ?? 'N/A',
            canSpeak: true,
          ),
          const SizedBox(height: 16),
          
          // Simple Explanation Card
          _buildSectionCard(
            title: 'Simple Explanation',
            icon: Icons.lightbulb_outline,
            content: _reportData!['simple_explanation'] ?? 'N/A',
            canSpeak: true,
            isHighlighted: true,
          ),
          const SizedBox(height: 16),
          
          // Translated Card -- only shown for a non-English language,
          // since for English this duplicated the Simple Explanation
          // card above with identical content.
          if (_selectedLanguage != 'English') ...[
            _buildSectionCard(
              title: '$_selectedLanguage Explanation',
              icon: Icons.translate,
              content: _isTranslating
                  ? '⏳ Translating to $_selectedLanguage...'
                  : (_reportData!['translated_explanation']?.toString().isNotEmpty == true
                      ? _reportData!['translated_explanation']
                      : 'Translation not available. Tap the language button above to retranslate.'),
              canSpeak: !_isTranslating,
              extraAction: _reportData != null && !_isTranslating
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Retranslate',
                      color: const Color(0xFFA01A1A),
                      onPressed: () => _retranslate(_selectedLanguage),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          
          // Suggestions Card
          if (_reportData!['suggestions'] != null &&
              (_reportData!['suggestions'] as List).isNotEmpty) ...[
            Builder(builder: (context) {
              final isEnglish = _selectedLanguage == 'English';
              final translatedSuggestions = _asStringList(_reportData!['translated_suggestions']);
              final showTranslated = !isEnglish && translatedSuggestions.isNotEmpty;
              final displayList = showTranslated
                  ? translatedSuggestions
                  : (_reportData!['suggestions'] as List).map((s) => s.toString()).toList();
              final title = showTranslated
                  ? '$_selectedLanguage Suggestions'
                  : 'AI Suggestions';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isTranslating)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA01A1A)),
                            ),
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
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right, color: Colors.orange),
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
        subtitle: 'After processing, this tab will show disease explanation and improvement steps in your selected language.',
      );
    }

    const Map<String, Map<String, String>> langLabels = {
      'Hindi':     {'disease': 'बीमारी की जानकारी',   'solution': 'सुधार के उपाय'},
      'Bengali':   {'disease': 'রোগের তথ্য',           'solution': 'উন্নতির উপায়'},
      'Tamil':     {'disease': 'நோய் தகவல்',           'solution': 'மேம்பாட்டு வழிகள்'},
      'Telugu':    {'disease': 'వ్యాధి సమాచారం',       'solution': 'మెరుగుదల మార్గాలు'},
      'Marathi':   {'disease': 'आजाराची माहिती',       'solution': 'सुधारणेचे उपाय'},
      'Gujarati':  {'disease': 'રોગની માહિતી',         'solution': 'સુધારાના ઉપાય'},
      'Kannada':   {'disease': 'ರೋಗದ ಮಾಹಿತಿ',         'solution': 'ಸುಧಾರಣೆಯ ಮಾರ್ಗಗಳು'},
      'Malayalam': {'disease': 'രോഗ വിവരം',            'solution': 'മെച്ചപ്പെടുത്തൽ വഴികൾ'},
    };

    final labels = langLabels[_selectedLanguage];
    final isEnglish = _selectedLanguage == 'English';

    final diseaseExplanationEn   = (_reportData!['disease_explanation_en'] ?? '').toString();
    final solutionPlanEn         = (_reportData!['solution_plan_en'] ?? '').toString();
    final diseaseExplanationLang = (_reportData!['disease_explanation_lang'] ?? _reportData!['disease_explanation_hi'] ?? '').toString();
    final solutionPlanLang       = (_reportData!['solution_plan_lang'] ?? _reportData!['solution_plan_hi'] ?? '').toString();
    final translatedSuggestions  = _asStringList(_reportData!['translated_suggestions']);
    final englishSuggestions     = _asStringList(_reportData!['suggestions']);

    final translatingText = '⏳ Translating to $_selectedLanguage...';

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
                      color: const Color(0xFFA01A1A),
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
                      color: const Color(0xFFA01A1A),
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
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA01A1A)),
                    ),
                    const SizedBox(width: 12),
                    Text('Translating checklist to $_selectedLanguage...',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (translatedSuggestions.isNotEmpty && !isEnglish) ...[
            Text(
              '$_selectedLanguage Action Checklist',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...translatedSuggestions.asMap().entries.map(
              (entry) => _buildSuggestionTile(
                index: entry.key + 1,
                text: entry.value,
                color: const Color(0xFFA01A1A),
              ),
            ),
          ],

          if (englishSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: const Icon(Icons.translate, color: Color(0xFFA01A1A)),
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
              backgroundColor: color.withValues(alpha: 0.14),
              child: Text(
                '$index',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 64, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
    return Card(
      color: isHighlighted ? const Color(0xFFFAEAEA) : null,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEAEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFA01A1A), size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (extraAction != null) extraAction,
                if (canSpeak) ...[
                  IconButton(
                    icon: Icon(
                      _activeSpeechKey == content && _isSpeaking
                          ? Icons.pause_circle_filled
                          : _activeSpeechKey == content && _isPaused
                              ? Icons.play_circle_filled
                              : Icons.volume_up,
                      color: const Color(0xFFA01A1A),
                    ),
                    onPressed: () {
                      if (_activeSpeechKey == content && _isSpeaking) {
                        _pauseSpeaking();
                      } else if (_activeSpeechKey == content && _isPaused) {
                        _resumeSpeaking();
                      } else {
                        _speak(content);
                      }
                    },
                    tooltip: _activeSpeechKey == content
                        ? (_isSpeaking ? 'Pause' : (_isPaused ? 'Resume' : 'Speak'))
                        : 'Speak',
                  ),
                  if (_activeSpeechKey == content && (_isSpeaking || _isPaused))
                    IconButton(
                      icon: const Icon(Icons.stop_circle, color: Color(0xFFA01A1A)),
                      onPressed: _stopSpeaking,
                      tooltip: 'Stop',
                    ),
                ],
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
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
          // Company Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Company Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/medisimple_logo.jpg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MediSimple',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Your Personal Health Expert',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 2.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: Color(0xFFA01A1A)),
              title: const Text('Output Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguageSelector,
            ),
          ),
          
          // TTS Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.record_voice_over, color: Color(0xFFA01A1A)),
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
                activeThumbColor: const Color(0xFFA01A1A),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.headphones, color: Color(0xFFA01A1A)),
              title: const Text('Voice Model'),
              subtitle: Text(_selectedVoiceName ?? 'Default'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showVoiceSelector,
            ),
          ),
          
          // About
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFA01A1A)),
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
    try { _currentSource?.stop(); } catch (_) {}
    try { _audioContext?.close(); } catch (_) {}
    _pollingTimer?.cancel();
    super.dispose();
  }
}
