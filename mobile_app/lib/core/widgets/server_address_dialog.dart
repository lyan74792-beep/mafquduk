import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../l10n/l10n.dart';
import '../network/api_client.dart';
import 'async_view.dart';

/// Lets the presenter point the app at another server (e.g. the laptop's
/// Wi-Fi address) without rebuilding. Opened by long-pressing the login logo.
Future<void> showServerAddressDialog(BuildContext context) async {
  final controller = TextEditingController(text: ApiConfig.baseUrl);
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t('serverAddressTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t('serverAddressHelp'), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(hintText: ApiConfig.defaultBaseUrl),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.text = '';
            Navigator.pop(dialogContext, true);
          },
          child: Text(t('serverAddressReset')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t('serverAddressSave')),
        ),
      ],
    ),
  );
  if (saved != true) return;
  await ApiConfig.save(controller.text);
  if (!context.mounted) return;
  try {
    await ApiClient.instance.get('health');
    if (context.mounted) showSnack(context, '${t('serverAddressOk')}  ${ApiConfig.baseUrl}');
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(e), isError: true);
  }
}
