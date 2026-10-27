import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../account/account_screen.dart';
import '../calendar/calendar_tab.dart';
import '../notebook/notebook_tab.dart';
import '../ai/ai_insights_screen.dart';
import '../settings/notifications_screen.dart';
import 'app_drawer.dart';
import 'home_tab.dart';

class HomeShell extends StatefulWidget {
  HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        title: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AccountScreen())),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 26),
              SizedBox(width: 8),
              Flexible(
                child: Text(app.currentAccount.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'AI Insights',
            icon: Icon(Icons.auto_awesome, color: AppColors.textPrimary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AiInsightsScreen())),
          ),
          IconButton(
            tooltip: 'Notifications and balance alerts',
            icon: Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'HOME'),
            Tab(text: 'CALENDAR'),
            Tab(text: 'NOTEBOOK'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeTab(),
          CalendarTab(),
          NotebookTab(),
        ],
      ),
    );
  }
}
