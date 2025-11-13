import 'package:flutter/material.dart';
import 'package:tlustudy_planner/screens/today_screen.dart';
import 'package:tlustudy_planner/screens/calendar_screen.dart';
import 'package:tlustudy_planner/screens/exam_schedule_screen.dart';
// import 'package:tlustudy_planner/screens/utilities_screen.dart'; // Hidden in this version
import 'package:tlustudy_planner/screens/settings_screen.dart';
import 'package:tlustudy_planner/widgets/cache_progress_banner.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TodayScreen(),
    const CalendarScreen(),
    const ExamScheduleScreen(),
    // const UtilitiesScreen(), // Hidden in this version
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use AnimatedSwitcher with slide transition for smooth screen switching
      body: Column(
        children: [
          // Cache progress banner at the top
          const CacheProgressBanner(),
          
          // Main content with tab screens and slide animation
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Slide transition from right to left or left to right based on direction
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.15, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ));
                
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        items: const [
          AppTabItem(label: 'Hôm nay', symbol: AppIcons.today),
          AppTabItem(label: 'Lịch học', symbol: AppIcons.calendar),
          AppTabItem(label: 'Lịch thi', symbol: AppIcons.exams),
          // AppTabItem(label: 'Tiện ích', symbol: AppIcons.utilities), // Hidden in this version
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
