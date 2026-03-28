import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Theme-aware Syntax Highlighter Themes
Map<String, TextStyle> getLightTheme(ColorScheme colorScheme) {
  return {
    ...atomOneLightTheme,
    'root': TextStyle(
      backgroundColor: colorScheme.surfaceContainerHighest,
      color: colorScheme.onSurface,
    ),
  };
}

Map<String, TextStyle> getDarkTheme(ColorScheme colorScheme) {
  return {
    ...atomOneDarkTheme,
    'root': TextStyle(
      backgroundColor: colorScheme.surfaceContainerHighest,
      color: colorScheme.onSurface,
    ),
  };
}

/// Widget für Syntax-Highlighting von Code-Blöcken
class SyntaxHighlightedCode extends StatelessWidget {
  final String code;
  final String? language;

  const SyntaxHighlightedCode({
    super.key,
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = isDark ? getDarkTheme(colorScheme) : getLightTheme(colorScheme);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Code mit Highlighting
          Padding(
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: _normalizeLanguage(language),
              theme: theme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          // Sprach-Badge
          if (language != null && language!.isNotEmpty)
            Positioned(
              top: 4,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  language!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Normalisiert Sprach-Bezeichnungen für das Highlighting
  String _normalizeLanguage(String? lang) {
    if (lang == null || lang.isEmpty) return 'plaintext';

    final normalized = lang.toLowerCase().trim();

    // Mapping gängiger Aliase
    const aliases = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'shell': 'bash',
      'zsh': 'bash',
      'yml': 'yaml',
      'md': 'markdown',
      'kt': 'kotlin',
      'cs': 'csharp',
      'c++': 'cpp',
      'h': 'c',
      'hpp': 'cpp',
      'jsx': 'javascript',
      'tsx': 'typescript',
    };

    return aliases[normalized] ?? normalized;
  }
}

/// Builder für Code-Blöcke im Markdown mit Syntax-Highlighting
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Sprache aus dem element extrahieren
    String? language;
    final className = element.attributes['class'];
    if (className != null && className.startsWith('language-')) {
      language = className.substring('language-'.length);
    }

    final code = element.textContent.trimRight();

    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SyntaxHighlightedCode(
          code: code,
          language: language,
        ),
      ),
    );
  }
}

/// Copy-Button für Code-Blöcke (optional)
class CodeBlockWithCopy extends StatefulWidget {
  final String code;
  final String? language;

  const CodeBlockWithCopy({
    super.key,
    required this.code,
    this.language,
  });

  @override
  State<CodeBlockWithCopy> createState() => _CodeBlockWithCopyState();
}

class _CodeBlockWithCopyState extends State<CodeBlockWithCopy> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = isDark ? getDarkTheme(colorScheme) : getLightTheme(colorScheme);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Code mit Highlighting
          Padding(
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              widget.code,
              language: widget.language ?? 'plaintext',
              theme: theme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          // Kopieren-Button
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sprach-Badge
                if (widget.language != null && widget.language!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.language!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Copy-Button
                IconButton(
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 16,
                    color: _copied
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _copyCode,
                  tooltip: 'Code kopieren',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyCode() async {
    // TODO: Implementierung erfordert Clipboard-Zugriff
    // import 'package:flutter/services.dart';
    // await Clipboard.setData(ClipboardData(text: widget.code));

    setState(() {
      _copied = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _copied = false;
      });
    }
  }
}
