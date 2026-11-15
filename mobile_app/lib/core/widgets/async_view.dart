import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Loads data with [load] and shows a spinner, an error with "retry",
/// an empty message, or [builder]. Pull-to-refresh reloads.
///
/// ```dart
/// AsyncView<List<ItemSummary>>(
///   load: () => repo.myReports(),
///   isEmpty: (items) => items.isEmpty,
///   builder: (context, items, reload) => ListView(...),
/// )
/// ```
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.emptyText,
    this.emptyIcon = Icons.inbox_outlined,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final bool Function(T data)? isEmpty;
  final String? emptyText;
  final IconData emptyIcon;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    final next = widget.load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // shown by the FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return MessageView(
            icon: Icons.cloud_off_outlined,
            text: errorText(snap.error),
            actionLabel: t('retry'),
            onAction: _reload,
          );
        }
        final data = snap.data as T;
        if (widget.isEmpty?.call(data) ?? false) {
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(children: [
              const SizedBox(height: 80),
              MessageView(icon: widget.emptyIcon, text: widget.emptyText ?? t('emptyList')),
            ]),
          );
        }
        return RefreshIndicator(onRefresh: _reload, child: widget.builder(context, data, _reload));
      },
    );
  }
}

/// Centered icon + text (+ optional button) for empty and error states.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// User-facing text for any error thrown by a repository.
String errorText(Object? error) =>
    error is ApiException ? error.message : t('unexpectedError');

/// Show [error] (or a success [message]) in a SnackBar.
void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.danger : AppColors.govGreen,
    ));
}
