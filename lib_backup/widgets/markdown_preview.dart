import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'syntax_highlighter.dart';

/// Markdown-Preview Widget mit Theme-Integration
class MarkdownPreview extends StatelessWidget {
  final String data;
  final ScrollController? scrollController;
  final Function(bool, String)? onCheckboxChanged;
  final bool enableSyntaxHighlighting;

  const MarkdownPreview({
    super.key,
    required this.data,
    this.scrollController,
    this.onCheckboxChanged,
    this.enableSyntaxHighlighting = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Markdown(
      data: data.isEmpty ? '_Keine Vorschau verfügbar_' : data,
      controller: scrollController,
      selectable: true,
      onTapLink: (text, href, title) => _onTapLink(context, href),
      styleSheet: MarkdownStyleSheet(
        // Überschriften
        h1: theme.textTheme.headlineLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        h2: theme.textTheme.headlineMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        h3: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        h4: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        h5: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        h6: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),

        // Absätze
        p: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),

        // Links
        a: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary,
        ),

        // Code
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: colorScheme.onSecondaryContainer,
          backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),

        // Zitate
        blockquote: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),

        // Listen
        listBullet: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.primary,
        ),

        // Horizontale Linie
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),

        // Tabellen
        tableHead: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        tableBody: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        tableBorder: TableBorder.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        tableHeadAlign: TextAlign.center,
        tableCellsPadding: const EdgeInsets.all(8),
      ),
      builders: {
        'input': CheckboxBuilder(onCheckboxChanged: onCheckboxChanged),
        if (enableSyntaxHighlighting) 'pre': CodeBlockBuilder(),
      },
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
  }

  void _onTapLink(BuildContext context, String? href) async {
    if (href == null) return;

    final uri = Uri.tryParse(href);
    if (uri == null) return;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Konnte Link nicht öffnen: $href')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Öffnen: $e')),
        );
      }
    }
  }
}

/// Builder für Checkbox-Elemente in Markdown
class CheckboxBuilder extends MarkdownElementBuilder {
  final Function(bool, String)? onCheckboxChanged;

  CheckboxBuilder({this.onCheckboxChanged});

  @override
  Widget? visitElementAfter(element, preferredStyle) {
    // Checkbox-Status aus dem Markdown parsen
    final isChecked = element.attributes['checked'] == 'true';
    final taskText = element.textContent;

    return GestureDetector(
      onTap: onCheckboxChanged != null
          ? () => onCheckboxChanged!(!isChecked, taskText)
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isChecked,
            onChanged: onCheckboxChanged != null
                ? (value) => onCheckboxChanged!(value ?? false, taskText)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Leere Markdown-Preview für leeren Zustand
class EmptyMarkdownPreview extends StatelessWidget {
  const EmptyMarkdownPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Vorschau',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beginne mit dem Schreiben,\num die Vorschau zu sehen',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
