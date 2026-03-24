import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback für Formatierungs-Aktionen
typedef FormatCallback = void Function(String prefix, String suffix, {String? placeholder});

/// Toolbar für Markdown-Formatierung
class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Undo/Redo
            if (onUndo != null || onRedo != null) ...[
              _ToolbarButton(
                icon: Icons.undo,
                tooltip: 'Rückgängig (Ctrl+Z)',
                onPressed: canUndo ? onUndo : null,
              ),
              _ToolbarButton(
                icon: Icons.redo,
                tooltip: 'Wiederholen (Ctrl+Y)',
                onPressed: canRedo ? onRedo : null,
              ),
              const _ToolbarDivider(),
            ],

            // Text-Formatierung
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Fett (Ctrl+B)',
              onPressed: () => _wrapSelection('**', '**', placeholder: 'fett'),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Kursiv (Ctrl+I)',
              onPressed: () => _wrapSelection('*', '*', placeholder: 'kursiv'),
            ),
            _ToolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Durchgestrichen',
              onPressed: () => _wrapSelection('~~', '~~', placeholder: 'durchgestrichen'),
            ),
            _ToolbarButton(
              icon: Icons.code,
              tooltip: 'Code inline',
              onPressed: () => _wrapSelection('`', '`', placeholder: 'code'),
            ),

            const _ToolbarDivider(),

            // Überschriften
            _ToolbarButton(
              icon: Icons.title,
              tooltip: 'Überschrift 1 (Ctrl+1)',
              label: 'H1',
              onPressed: () => _insertAtLineStart('# '),
            ),
            _ToolbarButton(
              icon: Icons.title,
              tooltip: 'Überschrift 2 (Ctrl+2)',
              label: 'H2',
              smaller: true,
              onPressed: () => _insertAtLineStart('## '),
            ),
            _ToolbarButton(
              icon: Icons.title,
              tooltip: 'Überschrift 3 (Ctrl+3)',
              label: 'H3',
              smaller: true,
              onPressed: () => _insertAtLineStart('### '),
            ),

            const _ToolbarDivider(),

            // Listen
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Aufzählung',
              onPressed: () => _insertAtLineStart('- '),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Nummerierung',
              onPressed: () => _insertAtLineStart('1. '),
            ),
            _ToolbarButton(
              icon: Icons.check_box_outlined,
              tooltip: 'Checkbox',
              onPressed: () => _insertAtLineStart('- [ ] '),
            ),

            const _ToolbarDivider(),

            // Blöcke
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: 'Zitat',
              onPressed: () => _insertAtLineStart('> '),
            ),
            _ToolbarButton(
              icon: Icons.data_object,
              tooltip: 'Code-Block',
              onPressed: () => _insertCodeBlock(),
            ),
            _ToolbarButton(
              icon: Icons.link,
              tooltip: 'Link',
              onPressed: () => _insertLink(),
            ),
            _ToolbarButton(
              icon: Icons.horizontal_rule,
              tooltip: 'Trennlinie',
              onPressed: () => _insertText('\n---\n'),
            ),
          ],
        ),
      ),
    );
  }

  /// Umschließt die Selektion oder fügt Platzhalter ein
  void _wrapSelection(String prefix, String suffix, {String? placeholder}) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      // Keine gültige Selektion - am Ende einfügen
      final newText = '$prefix${placeholder ?? ''}$suffix';
      controller.text = text + newText;
      controller.selection = TextSelection.collapsed(
        offset: text.length + prefix.length + (placeholder?.length ?? 0),
      );
      return;
    }

    final selectedText = selection.textInside(text);

    if (selectedText.isEmpty) {
      // Keine Selektion - Platzhalter einfügen
      final newText = '$prefix${placeholder ?? ''}$suffix';
      final newSelection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
      controller.text = text.replaceRange(selection.start, selection.end, newText);
      controller.selection = TextSelection(
        baseOffset: newSelection.baseOffset,
        extentOffset: newSelection.baseOffset + (placeholder?.length ?? 0),
      );
    } else {
      // Selektion umschließen
      final newText = '$prefix$selectedText$suffix';
      controller.text = text.replaceRange(selection.start, selection.end, newText);
      controller.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + selectedText.length,
      );
    }

    focusNode?.requestFocus();
  }

  /// Fügt Text am Zeilenanfang ein
  void _insertAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    // Finde den Zeilenanfang
    int lineStart = selection.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Prüfe ob Prefix bereits vorhanden
    if (text.substring(lineStart).startsWith(prefix)) {
      // Prefix entfernen (Toggle)
      controller.text = text.replaceRange(lineStart, lineStart + prefix.length, '');
      controller.selection = TextSelection.collapsed(
        offset: selection.start - prefix.length,
      );
    } else {
      // Prefix einfügen
      controller.text = text.replaceRange(lineStart, lineStart, prefix);
      controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    }

    focusNode?.requestFocus();
  }

  /// Fügt einen Code-Block ein
  void _insertCodeBlock() {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);
    final codeBlock = selectedText.isEmpty
        ? '```\ncode\n```'
        : '```\n$selectedText\n```';

    controller.text = text.replaceRange(selection.start, selection.end, codeBlock);

    // Cursor in den Block setzen
    final cursorPos = selection.start + 4; // Nach ```\n
    controller.selection = TextSelection.collapsed(offset: cursorPos);

    focusNode?.requestFocus();
  }

  /// Fügt einen Link ein
  void _insertLink() {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);
    final linkText = selectedText.isEmpty ? 'Link-Text' : selectedText;
    final link = '[$linkText](url)';

    controller.text = text.replaceRange(selection.start, selection.end, link);

    // URL-Platzhalter selektieren
    final urlStart = selection.start + linkText.length + 3; // Nach [text](
    controller.selection = TextSelection(
      baseOffset: urlStart,
      extentOffset: urlStart + 3, // "url"
    );

    focusNode?.requestFocus();
  }

  /// Fügt Text an der aktuellen Position ein
  void _insertText(String insertText) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      controller.text = text + insertText;
      controller.selection = TextSelection.collapsed(
        offset: text.length + insertText.length,
      );
    } else {
      controller.text = text.replaceRange(selection.start, selection.end, insertText);
      controller.selection = TextSelection.collapsed(
        offset: selection.start + insertText.length,
      );
    }

    focusNode?.requestFocus();
  }
}

/// Einzelner Toolbar-Button
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? label;
  final bool smaller;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.label,
    this.smaller = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: smaller ? 12 : 14,
                    color: onPressed != null
                        ? colorScheme.onSurface
                        : colorScheme.outline,
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: onPressed != null
                      ? colorScheme.onSurface
                      : colorScheme.outline,
                ),
        ),
      ),
    );
  }
}

/// Vertikale Trennlinie
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Keyboard-Shortcuts für den Editor
class EditorKeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onEscape;

  const EditorKeyboardShortcuts({
    super.key,
    required this.child,
    required this.controller,
    required this.focusNode,
    this.onSave,
    this.onUndo,
    this.onRedo,
    this.onEscape,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          onSave?.call();
        },
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
          _wrapSelection('**', '**');
        },
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () {
          _wrapSelection('*', '*');
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          onUndo?.call();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          onRedo?.call();
        },
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          _insertAtLineStart('# ');
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          _insertAtLineStart('## ');
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          _insertAtLineStart('### ');
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          onEscape?.call();
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);

    if (selectedText.isEmpty) {
      final newText = '$prefix$suffix';
      controller.text = text.replaceRange(selection.start, selection.end, newText);
      controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      final newText = '$prefix$selectedText$suffix';
      controller.text = text.replaceRange(selection.start, selection.end, newText);
      controller.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + selectedText.length,
      );
    }
  }

  void _insertAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    int lineStart = selection.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    controller.text = text.replaceRange(lineStart, lineStart, prefix);
    controller.selection = TextSelection.collapsed(
      offset: selection.start + prefix.length,
    );
  }
}
