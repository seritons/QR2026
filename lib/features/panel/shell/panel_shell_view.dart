// lib/features/panel/shell/panel_shell_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrpanel/app/sessions/app_session.dart';
import 'package:qrpanel/features/panel/menu/menu_viewmodel.dart';
import 'package:qrpanel/services/app_service.dart';
import '../../../app/theme/appetite_theme.dart';
import '../dashboard/dashboard_view.dart';
import '../menu/menu_view.dart';
import '../orders/orders_view.dart';
import '../analytics/analytics_view.dart';
import 'panel_drawer.dart';

class PanelShellView extends StatefulWidget {
  const PanelShellView({super.key});

  @override
  State<PanelShellView> createState() => _PanelShellViewState();
}

class _PanelShellViewState extends State<PanelShellView> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // AppSession'ı al
    final appSession = context.read<AppSession>();
    final appService = context.read<AppServices>();

    // Session içinden gerekli alanlar (senin isimlerin farklıysa uyarlarsın)
    final businessId = appSession.business.business?.id;               // örn: app.activeBusinessId
    final menuService = appService.menu;             // örn: app.services.menuService
    final menuSession = appSession.menu;             // örn: app.sessions.menuSession

    // VM oluştur
    final menuVm = MenuViewModel(
      menuService: menuService,
      menuSession: menuSession,
      businessId: businessId ?? '',
    );

    // (Opsiyonel) Boot zaten doldurmadıysa burada başlat
    // WidgetsBinding.instance.addPostFrameCallback((_) => menuVm.init());

    _pages = [
      const PanelDashboardView(),
      const PanelOrdersView(),
      const PanelAnalyticsView(),
      MenuCreateView(vm: menuVm), // ✅ parametreli
    ];
  }

  @override
  void dispose() {
    // VM ChangeNotifier ise kapat
    // (Eğer MenuViewModel içinde stream/subscription varsa burada kesin kapatılmalı)
    // ignore: unused_local_variable
    // menuVm.dispose(); // menuVm'i field olarak saklıyorsan burada çağır

    super.dispose();
  }

  String _titleOfIndex(int i) {
    switch (i) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Siparişler';
      case 2:
        return 'Analiz';
      case 3:
        return 'Menü';
      default:
        return 'Panel';
    }
  }

  IconData _iconOfIndex(int i) {
    switch (i) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.receipt_long_rounded;
      case 2:
        return Icons.insights_rounded;
      case 3:
        return Icons.menu_book_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _pages.length) {
      debugPrint('[PanelShell] index out of range: $_index len=${_pages.length} -> reset 0');
      _index = 0;
    }

    return Theme(
      data: AppetiteTheme.light(),
      child: Scaffold(
        drawer: const PanelDrawer(
          title: 'İz • Panel',
          subtitle: 'MVP işletme yönetimi',
        ),
        appBar: AppBar(
          title: Text(
            _titleOfIndex(_index),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Bildirimler',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('MVP: Bildirimler (yakında)')),
                );
              },
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(decoration: AppetiteTheme.background()),
            Container(decoration: AppetiteTheme.background2()),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _pages[_index],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            debugPrint('[PanelShell] tab=$i');
            setState(() => _index = i);
          },
          destinations: [
            NavigationDestination(icon: Icon(_iconOfIndex(0)), label: 'Ana'),
            NavigationDestination(icon: Icon(_iconOfIndex(1)), label: 'Siparişler'),
            NavigationDestination(icon: Icon(_iconOfIndex(2)), label: 'Analiz'),
            NavigationDestination(icon: Icon(_iconOfIndex(3)), label: 'Menü'),
          ],
        ),
      ),
    );
  }
}
