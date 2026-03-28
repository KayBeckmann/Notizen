import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/drawing.dart';

/// Toolbar für Zeichenwerkzeuge
class DrawingToolbar extends StatelessWidget {
  final DrawingSettings settings;
  final Function(DrawingSettings) onSettingsChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onClear;
  final bool canUndo;
  final bool canRedo;
  final bool isVertical;

  const DrawingToolbar({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.onUndo,
    this.onRedo,
    this.onClear,
    this.canUndo = false,
    this.canRedo = false,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final children = [
      // Undo/Redo
      _ToolbarSection(
        isVertical: isVertical,
        children: [
          _ToolbarButton(
            icon: Icons.undo,
            tooltip: 'Rückgängig',
            onPressed: canUndo ? onUndo : null,
          ),
          _ToolbarButton(
            icon: Icons.redo,
            tooltip: 'Wiederholen',
            onPressed: canRedo ? onRedo : null,
          ),
        ],
      ),

      _ToolbarDivider(isVertical: isVertical),

      // Werkzeuge
      _ToolbarSection(
        isVertical: isVertical,
        children: [
          _ToolButton(
            icon: Icons.edit,
            tooltip: 'Stift',
            isSelected: settings.tool == DrawingTool.pen,
            onPressed: () => _selectTool(DrawingTool.pen),
          ),
          _ToolButton(
            icon: Icons.brush,
            tooltip: 'Marker',
            isSelected: settings.tool == DrawingTool.marker,
            onPressed: () => _selectTool(DrawingTool.marker),
          ),
          _ToolButton(
            icon: Icons.auto_fix_high,
            tooltip: 'Radierer',
            isSelected: settings.tool == DrawingTool.eraser,
            onPressed: () => _selectTool(DrawingTool.eraser),
          ),
        ],
      ),

      _ToolbarDivider(isVertical: isVertical),

      // Formen
      _ToolbarSection(
        isVertical: isVertical,
        children: [
          _ToolButton(
            icon: Icons.show_chart,
            tooltip: 'Linie',
            isSelected: settings.tool == DrawingTool.line,
            onPressed: () => _selectTool(DrawingTool.line),
          ),
          _ToolButton(
            icon: Icons.crop_square,
            tooltip: 'Rechteck',
            isSelected: settings.tool == DrawingTool.rectangle,
            onPressed: () => _selectTool(DrawingTool.rectangle),
          ),
          _ToolButton(
            icon: Icons.circle_outlined,
            tooltip: 'Kreis',
            isSelected: settings.tool == DrawingTool.circle,
            onPressed: () => _selectTool(DrawingTool.circle),
          ),
          _ToolButton(
            icon: Icons.arrow_right_alt,
            tooltip: 'Pfeil',
            isSelected: settings.tool == DrawingTool.arrow,
            onPressed: () => _selectTool(DrawingTool.arrow),
          ),
        ],
      ),

      _ToolbarDivider(isVertical: isVertical),

      // Farbe
      _ColorButton(
        color: settings.color,
        onColorChanged: _selectColor,
        recentColors: settings.recentColors,
      ),

      _ToolbarDivider(isVertical: isVertical),

      // Dicke
      _StrokeWidthButton(
        strokeWidth: settings.strokeWidth,
        color: settings.color,
        onStrokeWidthChanged: _selectStrokeWidth,
      ),

      // Gefüllt-Option für Formen
      if (_isShapeTool(settings.tool)) ...[
        _ToolbarDivider(isVertical: isVertical),
        _ToolButton(
          icon: settings.isFilled ? Icons.format_color_fill : Icons.format_color_reset,
          tooltip: settings.isFilled ? 'Gefüllt' : 'Nur Umriss',
          isSelected: settings.isFilled,
          onPressed: () {
            onSettingsChanged(settings.copyWith(isFilled: !settings.isFilled));
          },
        ),
      ],

      const Spacer(),

      // Alles löschen
      _ToolbarButton(
        icon: Icons.delete_sweep,
        tooltip: 'Alles löschen',
        onPressed: onClear,
        color: colorScheme.error,
      ),
    ];

    if (isVertical) {
      return Container(
        width: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(
            right: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: children,
          ),
        ),
      );
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: children,
        ),
      ),
    );
  }

  void _selectTool(DrawingTool tool) {
    onSettingsChanged(settings.copyWith(
      tool: tool,
      strokeWidth: settings.copyWith(tool: tool).defaultStrokeWidth,
    ));
  }

  void _selectColor(Color color) {
    onSettingsChanged(settings.copyWith(color: color).addRecentColor(color));
  }

  void _selectStrokeWidth(double width) {
    onSettingsChanged(settings.copyWith(strokeWidth: width));
  }

  bool _isShapeTool(DrawingTool tool) {
    return tool == DrawingTool.rectangle || tool == DrawingTool.circle;
  }
}

class _ToolbarSection extends StatelessWidget {
  final List<Widget> children;
  final bool isVertical;

  const _ToolbarSection({
    required this.children,
    required this.isVertical,
  });

  @override
  Widget build(BuildContext context) {
    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  final bool isVertical;

  const _ToolbarDivider({required this.isVertical});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;

    if (isVertical) {
      return Container(
        height: 1,
        width: 32,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: color,
      );
    }

    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      color: color,
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
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
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final Function(Color) onColorChanged;
  final List<Color> recentColors;

  const _ColorButton({
    required this.color,
    required this.onColorChanged,
    required this.recentColors,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      tooltip: 'Farbe wählen',
      offset: const Offset(0, -200),
      onSelected: onColorChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: _ColorPalette(
            selectedColor: color,
            recentColors: recentColors,
            onColorSelected: (c) {
              Navigator.pop(context);
              onColorChanged(c);
            },
            onCustomColor: () async {
              Navigator.pop(context);
              final newColor = await _showColorPicker(context);
              if (newColor != null) {
                onColorChanged(newColor);
              }
            },
          ),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Future<Color?> _showColorPicker(BuildContext context) async {
    Color selectedColor = color;

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (c) => selectedColor = c,
            enableAlpha: false,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selectedColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  final Color selectedColor;
  final List<Color> recentColors;
  final Function(Color) onColorSelected;
  final VoidCallback onCustomColor;

  const _ColorPalette({
    required this.selectedColor,
    required this.recentColors,
    required this.onColorSelected,
    required this.onCustomColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standard-Farben
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DrawingColors.palette.map((c) {
              return _ColorDot(
                color: c,
                isSelected: c == selectedColor,
                onTap: () => onColorSelected(c),
              );
            }).toList(),
          ),

          // Letzte Farben
          if (recentColors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Zuletzt verwendet',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentColors.map((c) {
                return _ColorDot(
                  color: c,
                  isSelected: c == selectedColor,
                  onTap: () => onColorSelected(c),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCustomColor,
            icon: const Icon(Icons.colorize, size: 16),
            label: const Text('Eigene Farbe'),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _StrokeWidthButton extends StatelessWidget {
  final double strokeWidth;
  final Color color;
  final Function(double) onStrokeWidthChanged;

  const _StrokeWidthButton({
    required this.strokeWidth,
    required this.color,
    required this.onStrokeWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Stiftdicke',
      offset: const Offset(0, -150),
      onSelected: onStrokeWidthChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: _StrokeWidthPicker(
            currentWidth: strokeWidth,
            color: color,
            onWidthSelected: (w) {
              Navigator.pop(context);
              onStrokeWidthChanged(w);
            },
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Container(
          width: strokeWidth.clamp(4, 24),
          height: strokeWidth.clamp(4, 24),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _StrokeWidthPicker extends StatefulWidget {
  final double currentWidth;
  final Color color;
  final Function(double) onWidthSelected;

  const _StrokeWidthPicker({
    required this.currentWidth,
    required this.color,
    required this.onWidthSelected,
  });

  @override
  State<_StrokeWidthPicker> createState() => _StrokeWidthPickerState();
}

class _StrokeWidthPickerState extends State<_StrokeWidthPicker> {
  late double _width;

  @override
  void initState() {
    super.initState();
    _width = widget.currentWidth;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vorschau
          Container(
            height: 40,
            alignment: Alignment.center,
            child: Container(
              width: 100,
              height: _width,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(_width / 2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Slider
          Slider(
            value: _width,
            min: 1,
            max: 50,
            onChanged: (v) {
              setState(() {
                _width = v;
              });
            },
            onChangeEnd: widget.onWidthSelected,
          ),

          // Preset-Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PresetButton(
                label: 'Fein',
                width: 2,
                isSelected: _width <= 3,
                onTap: () {
                  setState(() => _width = 2);
                  widget.onWidthSelected(2);
                },
              ),
              _PresetButton(
                label: 'Normal',
                width: 5,
                isSelected: _width > 3 && _width <= 10,
                onTap: () {
                  setState(() => _width = 5);
                  widget.onWidthSelected(5);
                },
              ),
              _PresetButton(
                label: 'Dick',
                width: 15,
                isSelected: _width > 10,
                onTap: () {
                  setState(() => _width = 15);
                  widget.onWidthSelected(15);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
