import 'package:flutter/material.dart';

class EnhancedDownloadProgressDialog extends StatefulWidget {
  final int totalFiles;
  final VoidCallback onCancel;

  const EnhancedDownloadProgressDialog({
    super.key,
    required this.totalFiles,
    required this.onCancel,
  });

  @override
  EnhancedDownloadProgressDialogState createState() =>
      EnhancedDownloadProgressDialogState();
}

class EnhancedDownloadProgressDialogState
    extends State<EnhancedDownloadProgressDialog> {
  int _currentFile = 0;
  int _overallProgress = 0;
  String _currentFileName = '';
  double _singleFileProgress = 0.0;
  bool _isSingleFileProgressVisible = false;

  void updateProgress(int current, int total, String fileName, int progress) {
    if (mounted) {
      setState(() {
        _currentFile = current;
        _currentFileName = fileName;
        _overallProgress = progress;
      });
    }
  }

  void updateSingleFileProgress(double progress) {
    if (mounted) {
      setState(() {
        _singleFileProgress = progress;
        _isSingleFileProgressVisible = true;
      });
    }
  }

  void hideSingleFileProgress() {
    if (mounted) {
      setState(() {
        _isSingleFileProgressVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.download, color: Colors.blue),
          SizedBox(width: 8),
          Text('Downloading Files'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overall Progress
          LinearProgressIndicator(
            value: _overallProgress / 100,
            backgroundColor: Colors.grey,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text('Overall: $_overallProgress% complete'),
          const SizedBox(height: 8),
          Text('$_currentFile/${widget.totalFiles} files'),
          const SizedBox(height: 8),
          if (_isSingleFileProgressVisible) ...[
            Text(
              'Current: $_currentFileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _singleFileProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text('${(_singleFileProgress * 100).toInt()}%'),
          ] else ...[
            Text(
              _currentFileName.isNotEmpty ? _currentFileName : 'Preparing...',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('CANCEL')),
      ],
    );
  }
}
