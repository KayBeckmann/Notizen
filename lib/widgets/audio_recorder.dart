import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/storage_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path) onStop;

  const AudioRecorderWidget({super.key, required this.onStop});

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late AudioRecorder _recorder;
  bool _isRecording = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (await _recorder.hasPermission()) {
        _path = await StorageService.getAudioPath();
        await _recorder.start(const RecordConfig(), path: _path!);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      widget.onStop(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording)
          const Text('Aufnahme läuft...')
        else
          const Text('Bereit zur Aufnahme'),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _isRecording ? _stop : _start,
          child: Icon(_isRecording ? Icons.stop : Icons.mic),
        ),
      ],
    );
  }
}
