import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrpanel/app/sessions/app_session.dart';
import 'package:qrpanel/features/panel/menu/menu_viewmodel.dart';
import 'package:qrpanel/services/app_service.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/appetite_theme.dart';
import '../../../app/theme/tokens.dart';
import '../analytics/analytics_view.dart';
import '../live/live_view.dart';
import '../menu/menu_view.dart';
import '../orders/orders_view.dart';
import 'panel_drawer.dart';

class PanelShellView extends StatefulWidget {
  const PanelShellView({super.key});

  @override
  State<PanelShellView> createState() => _PanelShellViewState();
}

class _PanelShellViewState extends State<PanelShellView> {
  /// 0: Orders
  /// 1: Tables
  /// 2: Live
  /// 3: Insights
  /// 4: Community
  int _index = 2;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final appSession = context.read<AppSession>();
    final appService = context.read<AppServices>();

    final businessId = appSession.business.business?.id;
    final menuSession = appSession.menu;

    final menuVm = MenuViewModel(
      businessId: businessId ?? '',
      session: menuSession,
      service: appService.menu,
    );

    _pages = [
      const PanelOrdersView(),
      const _PanelTablesPlaceholderView(),
      const LiveView(),
      const PanelAnalyticsView(),
      _PanelCommunityPlaceholderView(menuVm: menuVm),
    ];
  }

  String _titleOfIndex(int i) {
    switch (i) {
      case 0:
        return 'Siparişler';
      case 1:
        return 'Masalar';
      case 2:
        return 'Canlı Akış';
      case 3:
        return 'Analiz';
      case 4:
        return 'Sosyal';
      default:
        return 'Panel';
    }
  }

  IconData _iconOfIndex(int i) {
    switch (i) {
      case 0:
        return Icons.receipt_long_rounded;
      case 1:
        return Icons.table_restaurant_rounded;
      case 2:
        return Icons.bolt_rounded;
      case 3:
        return Icons.insights_rounded;
      case 4:
        return Icons.forum_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    if (_index >= _pages.length) {
      debugPrint(
        '[PanelShell] index out of range: $_index len=${_pages.length} -> reset 2',
      );
      _index = 2;
    }

    return Scaffold(
      drawer: const PanelDrawer(
        title: 'İz • Panel',
        subtitle: 'MVP işletme yönetimi',
      ),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconOfIndex(_index),
              size: 20,
              color: tokens.text,
            ),
            const SizedBox(width: 8),
            Text(
              _titleOfIndex(_index),
              style: AppTypography.title.copyWith(
                color: tokens.text,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: tokens.text,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'MVP: Bildirimler (yakında)',
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.notifications_none_rounded,
              color: tokens.text,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: AppetiteTheme.background(context),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: AppetiteTheme.background2(context),
            ),
          ),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: PanelBottomNav(
          currentIndex: _index,
          onChanged: (i) {
            debugPrint('[PanelShell] tab=$i');
            setState(() => _index = i);
          },
          items: const [
            PanelBottomNavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Siparişler',
            ),
            PanelBottomNavItem(
              icon: Icons.table_restaurant_rounded,
              label: 'Işletme',
            ),
            PanelBottomNavItem(
              icon: Icons.bolt_rounded,
              label: 'Canlı',
              isCenter: true,
            ),
            PanelBottomNavItem(
              icon: Icons.insights_rounded,
              label: 'Analiz',
            ),
            PanelBottomNavItem(
              icon: Icons.forum_rounded,
              label: 'Sosyal',
            ),
          ],
        ),
      ),
    );
  }
}

class PanelBottomNavItem {
  final IconData icon;
  final String label;
  final bool isCenter;

  const PanelBottomNavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}

class PanelBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<PanelBottomNavItem> items;

  const PanelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return SafeArea(
      top: false,
      child: Container(
        height: 83,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.rLg + 10),
          border: Border.all(color: tokens.border),
          boxShadow: tokens.shadow2,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            final isCenter = item.isCenter;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(horizontal: isCenter ? 2 : 4),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCenter ? 8 : 10,
                    vertical: isCenter ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tokens.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      isCenter ? tokens.rLg + 4 : tokens.rLg,
                    ),
                    border: selected
                        ? Border.all(
                      color: tokens.primary.withValues(alpha: 0.20),
                    )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: isCenter ? 24 : 22,
                        color: selected ? tokens.primary : tokens.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: selected ? tokens.text : tokens.muted,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PanelTablesPlaceholderView extends StatelessWidget {
  const _PanelTablesPlaceholderView();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_restaurant_rounded,
                size: 42,
                color: tokens.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Masalar',
                style: AppTypography.title.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                'MVP: Masa düzeni, QR oluşturma ve session yönetimi bu ekrana gelecek.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: tokens.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelCommunityPlaceholderView extends StatelessWidget {
  final MenuViewModel menuVm;

  const _PanelCommunityPlaceholderView({
    required this.menuVm,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_rounded,
                size: 42,
                color: tokens.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Sosyal / Feedback',
                style: AppTypography.title.copyWith(color: tokens.text),
              ),
              const SizedBox(height: 8),
              Text(
                'MVP: Müşteri feedback, yorumlar ve sosyal etkileşim bu ekrana gelecek.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: tokens.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MenuCreateView(vm: menuVm),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Menü Yönetimine Git'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}