import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        content = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
        file.writeAsStringSync(content);
      }
    }
  }
}
