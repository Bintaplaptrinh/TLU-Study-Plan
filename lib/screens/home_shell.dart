import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/screens/calendar_screen.dart';
import 'package:tlustudy_planner/screens/exam_schedule_screen.dart';
import 'package:tlustudy_planner/screens/settings_screen.dart';
import 'package:tlustudy_planner/screens/today_screen.dart';
import 'package:tlustudy_planner/screens/utilities_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/utils/shell_scope.dart';
import 'package:tlustudy_planner/widgets/cache_progress_banner.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/tab_slide_switcher.dart';

/// Khung chính của ứng dụng: năm tab, và một thanh điều hướng nổi bên trên.
///
/// Các trang con (mục của "Tiện ích", chọn ngày, nhật ký...) được mở bằng một
/// [Navigator] lồng bên trong khung này chứ không phải Navigator gốc. Nhờ vậy
/// thanh điều hướng nằm *trên* trang con và có thể tự thu lại thành nút back,
/// thay vì bị trang con phủ mất như khi dùng `bottomNavigationBar`.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Tab đang chọn. Là [ValueNotifier] chứ không phải biến thường vì trang gốc
  /// nằm trong Navigator lồng - `setState` của khung không dựng lại nó, phải
  /// có thứ để nó tự nghe.
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);

  /// Hướng của cú trượt đổi tab: 1 là sang phải, -1 là về bên trái.
  int _tabDirection = 1;

  /// Số trang con đang chồng lên trang gốc.
  final ValueNotifier<int> _subPageDepth = ValueNotifier<int>(0);

  late final _PageDepthObserver _observer = _PageDepthObserver(
    (depth) => _subPageDepth.value = depth,
  );

  static const List<FloatingNavItem> _items = [
    FloatingNavItem(label: 'Hôm nay', icon: Symbols.home_rounded),
    FloatingNavItem(label: 'Lịch học', icon: Symbols.calendar_month_rounded),
    FloatingNavItem(label: 'Lịch thi', icon: Symbols.quiz_rounded),
    FloatingNavItem(label: 'Tiện ích', icon: Symbols.apps_rounded),
    FloatingNavItem(label: 'Cài đặt', icon: Symbols.settings_rounded),
  ];

  @override
  void dispose() {
    _tabIndex.dispose();
    _subPageDepth.dispose();
    super.dispose();
  }

  Widget _screenFor(int index) {
    switch (index) {
      case 0:
        return const TodayScreen();
      case 1:
        return const CalendarScreen();
      case 2:
        return const ExamScheduleScreen();
      case 3:
        return const UtilitiesScreen();
      default:
        return const SettingsScreen();
    }
  }

  void _onTabTapped(int index) {
    // Đang ở trang con mà bấm tab thì quay hẳn về trang gốc trước, nếu không
    // tab mới sẽ nằm khuất bên dưới trang con.
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (index == _tabIndex.value) return;

    // Tab đích nằm bên phải hay bên trái tab hiện tại - đó là hướng trượt.
    _tabDirection = index > _tabIndex.value ? 1 : -1;
    _tabIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _subPageDepth,
      builder: (context, depth, _) {
        final inSubPage = depth > 0;

        return PopScope(
          // Ở trang con thì phím back của máy đóng trang con, chứ không thoát
          // ứng dụng - Navigator gốc không biết gì về ngăn xếp lồng bên trong.
          canPop: !inSubPage,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _navigatorKey.currentState?.maybePop();
          },
          child: ShellScope(
            goToTab: _onTabTapped,
            child: Scaffold(
              backgroundColor: AppColors.bg(context),
              body: Column(
                children: [
                  const CacheProgressBanner(),
                  Expanded(
                    child: Stack(
                      children: [
                        Navigator(
                          key: _navigatorKey,
                          observers: [_observer],
                          onGenerateRoute: (settings) => PageRouteBuilder(
                            settings: settings,
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            // Trang gốc không có chuyển cảnh của riêng nó,
                            // nhưng vẫn phải lùi sang trái khi bị một trang con
                            // trượt lên phủ.
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) => buildCoveredSlide(
                                  secondaryAnimation,
                                  child,
                                ),
                            pageBuilder: (_, _, _) =>
                                ValueListenableBuilder<int>(
                                  valueListenable: _tabIndex,
                                  builder: (context, index, _) =>
                                      TabSlideSwitcher(
                                        index: index,
                                        direction: _tabDirection,
                                        child: _screenFor(index),
                                      ),
                                ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _tabIndex,
                            builder: (context, index, _) => FloatingNavBar(
                              items: _items,
                              currentIndex: index,
                              collapsed: inSubPage,
                              onTap: _onTabTapped,
                              onBack: () =>
                                  _navigatorKey.currentState?.maybePop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: Padding(
                // Nhấc lên khỏi thanh nổi.
                padding: EdgeInsets.only(
                  bottom: FloatingNavBar.bottomInset(context),
                ),
                child: const ResumeCachingButton(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Đếm số trang (chỉ [PageRoute]) đang chồng lên trang gốc của Navigator lồng.
///
/// Bỏ qua dialog và bottom sheet: chúng cũng là route, nhưng mở một hộp thoại
/// thì thanh điều hướng không có lý do gì phải biến thành nút back.
class _PageDepthObserver extends NavigatorObserver {
  _PageDepthObserver(this.onChanged);

  final ValueChanged<int> onChanged;
  int _depth = 0;

  void _bump(int delta) {
    final next = (_depth + delta).clamp(0, 1 << 20);
    if (next == _depth) return;
    _depth = next;
    // Observer chạy giữa lúc Navigator đang dựng lại; đổi ValueNotifier ngay
    // lúc đó sẽ báo lỗi "setState during build".
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(_depth));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute != null) _bump(1);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute != null) _bump(-1);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute != null) _bump(-1);
  }
}
