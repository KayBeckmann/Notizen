import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../services/storage_service.dart';

/// Widget für Audio-Aufnahme
class AudioRecorderWidget extends StatefulWidget {
  final Function(String path) onRecordingComplete;
  final VoidCallback? onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();

  RecordingState _state = RecordingState.idle;
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _recordingPath;
  List<double> _amplitudes = [];

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wellenform-Visualisierung
          SizedBox(
            height: 80,
            child: _buildWaveform(colorScheme),
          ),
          const SizedBox(height: 16),

          // Timer
          Text(
            _formatDuration(_duration),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w300,
                ),
          ),
          const SizedBox(height: 8),

          // Status-Text
          Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Steuerung
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Abbrechen
              if (_state != RecordingState.idle)
                IconButton.outlined(
                  onPressed: _cancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'Abbrechen',
                ),
              const SizedBox(width: 16),

              // Haupt-Button
              _buildMainButton(colorScheme),
              const SizedBox(width: 16),

              // Pause/Fortsetzen oder Speichern
              if (_state == RecordingState.recording)
                IconButton.outlined(
                  onPressed: _pause,
                  icon: const Icon(Icons.pause),
                  tooltip: 'Pausieren',
                )
              else if (_state == RecordingState.paused)
                IconButton.outlined(
                  onPressed: _resume,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Fortsetzen',
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(ColorScheme colorScheme) {
    if (_amplitudes.isEmpty) {
      return Center(
        child: Icon(
          Icons.mic,
          size: 48,
          color: colorScheme.outline,
        ),
      );
    }

    return CustomPaint(
      painter: WaveformPainter(
        amplitudes: _amplitudes,
        color: _state == RecordingState.recording
            ? colorScheme.primary
            : colorScheme.outline,
        isRecording: _state == RecordingState.recording,
      ),
      size: const Size(double.infinity, 80),
    );
  }

  Widget _buildMainButton(ColorScheme colorScheme) {
    switch (_state) {
      case RecordingState.idle:
        return FloatingActionButton.large(
          onPressed: _startRecording,
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          child: const Icon(Icons.mic, size: 32),
        );
      case RecordingState.recording:
        return FloatingActionButton.large(
          onPressed: _stopRecording,
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          child: const Icon(Icons.stop, size: 32),
        );
      case RecordingState.paused:
        return FloatingActionButton.large(
          onPressed: _stopRecording,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: const Icon(Icons.check, size: 32),
        );
    }
  }

  String _getStatusText() {
    switch (_state) {
      case RecordingState.idle:
        return 'Tippe zum Starten';
      case RecordingState.recording:
        return 'Aufnahme läuft...';
      case RecordingState.paused:
        return 'Pausiert';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    // Berechtigung prüfen
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon-Berechtigung erforderlich')),
        );
      }
      return;
    }

    // Auf Web: Pfad wird vom Browser ignoriert; auf Native: temp-Pfad verwenden
    final String recordPath;
    if (kIsWeb) {
      recordPath = 'recording.webm'; // Wird ignoriert, aber Parameter ist required
      _recordingPath = null;
    } else {
      recordPath = '${StorageService.instance.tempPath}/${StorageService.instance.generateFilename('m4a')}';
      _recordingPath = recordPath;
    }

    await _recorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: recordPath,
    );

    setState(() {
      _state = RecordingState.recording;
      _duration = Duration.zero;
      _amplitudes = [];
    });

    _startTimer();
    _startAmplitudeMonitoring();
  }

  Future<void> _pause() async {
    await _recorder.pause();
    _timer?.cancel();

    setState(() {
      _state = RecordingState.paused;
    });
  }

  Future<void> _resume() async {
    await _recorder.resume();
    _startTimer();

    setState(() {
      _state = RecordingState.recording;
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();

    if (path != null && mounted) {
      if (kIsWeb) {
        // Auf Web gibt stop() eine blob-URL zurück — direkt verwenden
        widget.onRecordingComplete(path);
      } else {
        // Auf Native: Datei in das Audio-Verzeichnis verschieben
        final file = File(path);
        final finalPath = await StorageService.instance.saveAudioFile(file);
        await file.delete();
        widget.onRecordingComplete(finalPath);
      }
    }

    setState(() {
      _state = RecordingState.idle;
      _duration = Duration.zero;
      _amplitudes = [];
    });
  }

  void _cancel() async {
    _timer?.cancel();
    await _recorder.stop();

    // Temporäre Datei löschen falls vorhanden (nur auf Native)
    if (!kIsWeb && _recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _state = RecordingState.idle;
      _duration = Duration.zero;
      _amplitudes = [];
    });

    widget.onCancel?.call();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_state != RecordingState.recording) {
        timer.cancel();
        return;
      }

      final amplitude = await _recorder.getAmplitude();
      setState(() {
        _amplitudes.add(amplitude.current);
        // Nur die letzten 50 Amplituden behalten
        if (_amplitudes.length > 50) {
          _amplitudes.removeAt(0);
        }
      });
    });
  }
}

/// Aufnahme-Zustand
enum RecordingState { idle, recording, paused }

/// Wellenform-Painter
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final bool isRecording;

  WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / 50;
    final centerY = size.height / 2;
    final maxAmplitude = size.height / 2 - 4;

    for (int i = 0; i < amplitudes.length; i++) {
      // Amplitude normalisieren (dB-Wert, typischerweise -160 bis 0)
      final normalizedAmp = ((amplitudes[i] + 160) / 160).clamp(0.0, 1.0);
      final barHeight = normalizedAmp * maxAmplitude;

      final x = i * barWidth + barWidth / 2;

      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return amplitudes != oldDelegate.amplitudes ||
        color != oldDelegate.color ||
        isRecording != oldDelegate.isRecording;
  }
}
