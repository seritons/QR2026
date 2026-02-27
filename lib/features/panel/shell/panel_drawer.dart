// lib/features/panel/shell/panel_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrpanel/services/app_service.dart';
import '../../../app/sessions/app_session.dart';
import '../../../app/theme/tokens.dart';
import '../../../services/auth_service.dart';

class PanelDrawer extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PanelDrawer({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTokens.primary.withOpacity(0.12),
                    child: Icon(Icons.store, color: AppTokens.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(color: AppTokens.muted, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_rounded),
                    title: const Text('Ana Sayfa'),
                    onTap: () {
                      Navigator.pop(context); // just close drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded),
                    title: const Text('Siparişler'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_rounded),
                    title: const Text('Analiz'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('İşletme Değiştir'),
                    subtitle: const Text('Çoklu işletme varsa seçime gider'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: ileride /panel/onboarding/business/select route
                      // Navigator.pushNamed(context, AppRoutes.businessSelect);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('MVP: İşletme değiştir (yakında)')),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Ayarlar'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('MVP: Ayarlar (yakında)')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Footer actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Çıkış'),
                  onPressed: () async {
                    await services.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/panel/login', (r) => false);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
