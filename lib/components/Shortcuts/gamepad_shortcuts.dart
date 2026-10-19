import 'dart:async';

import 'package:finamp/components/Shortcuts/gamepad_prompts.dart';
import 'package:finamp/components/Shortcuts/music_control_shortcuts.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/components/now_playing_bar.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Gamepad-oriented intents
// ---------------------------------------------------------------------------

/// Invoked by the controller's View (≡) button (bound to Ctrl+B by default).
class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}

/// Invoked by the controller's Menu (☰) button (bound to Ctrl+M by default).
class OpenNowPlayingIntent extends Intent {
  const OpenNowPlayingIntent();
}

/// Toggles the on-screen gamepad button prompts (bound to Ctrl+G by default).
class ToggleGamepadPromptsIntent extends Intent {
  const ToggleGamepadPromptsIntent();
}

// ---------------------------------------------------------------------------
// MusicScreen drawer registry
// ---------------------------------------------------------------------------

/// The drawer lives inside MusicScreen's Scaffold, but gamepad actions are
/// registered globally on the MaterialApp. This registry lets those global
/// actions reach the MusicScreen's Scaffold without holding a BuildContext.
class MusicScreenScaffoldRegistry {
  static ScaffoldState? _scaffoldState;
  static VoidCallback? _focusDrawerFirstItem;
  static FocusNode? _focusBeforeDrawerOpened;

  static void register(ScaffoldState state) => _scaffoldState = state;

  static void unregister(ScaffoldState state) {
    if (_scaffoldState == state) {
      _scaffoldState = null;
      _focusDrawerFirstItem = null;
      _focusBeforeDrawerOpened = null;
    }
  }

  static void registerDrawerFocus(VoidCallback callback) => _focusDrawerFirstItem = callback;

  static void unregisterDrawerFocus(VoidCallback callback) {
    if (_focusDrawerFirstItem == callback) _focusDrawerFirstItem = null;
  }

  /// The drawer should only be driven while MusicScreen is the visible route.
  static bool get _isMusicScreenCurrent {
    final context = _scaffoldState?.context;
    if (context == null) return false;
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  static bool get isDrawerOpen => _scaffoldState?.isDrawerOpen ?? false;

  /// Opens the drawer and transfers focus to its first interactive item.
  static void openDrawerWithFocus() {
    final state = _scaffoldState;
    if (state == null || !state.hasDrawer || !_isMusicScreenCurrent) return;

    _focusBeforeDrawerOpened = FocusManager.instance.primaryFocus;
    state.openDrawer();

    final focusFirstItem = _focusDrawerFirstItem;
    if (focusFirstItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => focusFirstItem());
    }
  }

  /// Closes the drawer and restores focus to whatever was focused before it
  /// was opened.
  static void closeDrawerAndRestoreFocus() {
    final state = _scaffoldState;
    if (state == null) return;

    state.closeDrawer();

    final previousFocus = _focusBeforeDrawerOpened;
    _focusBeforeDrawerOpened = null;
    if (previousFocus != null && previousFocus.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previousFocus.requestFocus());
    }
  }

  static void toggleDrawer() {
    if (isDrawerOpen) {
      closeDrawerAndRestoreFocus();
    } else {
      openDrawerWithFocus();
    }
  }
}

// ---------------------------------------------------------------------------
// Gamepad-oriented actions
// ---------------------------------------------------------------------------

/// Merged into GlobalShortcuts.actionMap *after* the music control actions so
/// that the BackIntent here overrides the stock one with drawer-aware
/// behaviour (B closes the drawer before popping routes).
Map<Type, Action<Intent>> getGamepadActions() {
  return {
    ToggleSidebarIntent: CallbackAction<ToggleSidebarIntent>(
      onInvoke: (_) {
        MusicScreenScaffoldRegistry.toggleDrawer();
        return null;
      },
    ),
    OpenNowPlayingIntent: CallbackAction<OpenNowPlayingIntent>(
      onInvoke: (_) {
        unawaited(NowPlayingBar.openPlayerScreen());
        return null;
      },
    ),
    BackIntent: CallbackAction<BackIntent>(
      onInvoke: (_) {
        // B button: dismiss the topmost layer first — an open drawer takes
        // priority over popping the navigation stack.
        if (MusicScreenScaffoldRegistry.isDrawerOpen) {
          MusicScreenScaffoldRegistry.closeDrawerAndRestoreFocus();
        } else {
          GlobalSnackbar.navigatorState?.maybePop();
        }
        return null;
      },
    ),
    ToggleGamepadPromptsIntent: CallbackAction<ToggleGamepadPromptsIntent>(
      onInvoke: (_) {
        gamepadPromptsEnabled.value = !gamepadPromptsEnabled.value;
        return null;
      },
    ),
  };
}
