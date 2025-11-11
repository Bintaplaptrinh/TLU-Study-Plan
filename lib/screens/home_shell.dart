import 'package:flutter/material.dart';
import 'package:tlustudy_planner/screens/today_screen.dart';
import 'package:tlustudy_planner/screens/calendar_screen.dart';
import 'package:tlustudy_planner/screens/exam_schedule_screen.dart';
import 'package:tlustudy_planner/screens/settings_screen.dart';
import 'package:tlustudy_planner/widgets/cache_progress_banner.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TodayScreen(),
    const CalendarScreen(),
    const ExamScheduleScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to preserve state of each tab so screens aren't
      // recreated when switching tabs. This prevents re-running initState
      // (and thus avoids unnecessary API calls) when returning to a tab.
      body: Column(
        children: [
          // Cache progress banner at the top
          const CacheProgressBanner(),
          
          // Main content with tab screens
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        items: const [
          AppTabItem(label: 'Hôm nay', symbol: AppIcons.today),
          AppTabItem(label: 'Lịch học', symbol: AppIcons.calendar),
          AppTabItem(label: 'Lịch thi', symbol: AppIcons.exams),
          AppTabItem(label: 'Cài đặt', symbol: AppIcons.settings),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: const ResumeCachingButton(),
    );
  }
}
