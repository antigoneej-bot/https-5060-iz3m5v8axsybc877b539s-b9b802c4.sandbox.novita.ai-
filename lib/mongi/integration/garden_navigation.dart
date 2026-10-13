import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

/// Capture the app shell before replacing a route or opening nested sheets.
/// A garden can be entered from either navigator, but its cat collection always
/// returns to the main app's emotion cats, not the runner's emotion lobby.
VoidCallback gardenCatSelectionReturn(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final app = context.read<AppStateProvider>();
  return () {
    if (!navigator.mounted) return;
    app.requestHomeTab(1);
    navigator.popUntil((route) => route.isFirst);
  };
}
