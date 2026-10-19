import 'package:flutter/material.dart';

/// Global toggle for the on-screen gamepad button prompts.
/// Toggled at runtime via Ctrl+G (ToggleGamepadPromptsIntent).
final ValueNotifier<bool> gamepadPromptsEnabled = ValueNotifier<bool>(true);

/// A single circular button glyph, e.g. a green circle containing "A".
class GamepadButtonGlyph extends StatelessWidget {
  const GamepadButtonGlyph({super.key, required this.label, required this.color, this.size = 18.0});

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Xbox controller glyph set. View/Menu use symbol glyphs since they have no
/// letters on the physical controller.
class XboxGlyphs {
  static Widget a({double size = 16.0}) =>
      GamepadButtonGlyph(label: 'A', color: const Color(0xFF107C10), size: size);
  static Widget b({double size = 16.0}) =>
      GamepadButtonGlyph(label: 'B', color: const Color(0xFFE4002B), size: size);
  static Widget x({double size = 16.0}) =>
      GamepadButtonGlyph(label: 'X', color: const Color(0xFF0E7A9E), size: size);
  static Widget y({double size = 16.0}) =>
      GamepadButtonGlyph(label: 'Y', color: const Color(0xFFFFB900), size: size);
  static Widget view({double size = 16.0}) =>
      GamepadButtonGlyph(label: '≡', color: const Color(0xFF5A5F6A), size: size);
  static Widget menu({double size = 16.0}) =>
      GamepadButtonGlyph(label: '☰', color: const Color(0xFF5A5F6A), size: size);
}

/// One "button + what it does" pair, e.g. [A] Select.
class GamepadPrompt extends StatelessWidget {
  const GamepadPrompt({super.key, required this.glyph, required this.label});

  final Widget glyph;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph,
        const SizedBox(width: 4.0),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// A row of contextual button prompts. Renders nothing while
/// [gamepadPromptsEnabled] is false (Ctrl+G).
class GamepadPromptRow extends StatelessWidget {
  const GamepadPromptRow({super.key, required this.prompts});

  final List<Widget> prompts;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: gamepadPromptsEnabled,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        return Wrap(
          spacing: 14.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.center,
          children: prompts,
        );
      },
    );
  }
}
