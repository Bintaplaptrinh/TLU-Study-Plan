import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:tlustudy_planner/config/app_info.dart';
import 'package:tlustudy_planner/providers/theme_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/login_screen.dart';
import 'package:tlustudy_planner/services/log_service.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';
// import 'package:tlustudy_planner/services/daily_notification_service.dart'; // Commented out with test button

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/widgets/calendar_widgets.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/mail_connection_card.dart';
import 'package:tlustudy_planner/widgets/student_barcode.dart';
import 'package:tlustudy_planner/widgets/update_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Modern gradient header
        SliverAppBar(
          // Cao hơn bản cũ để chứa mã vạch mã số sinh viên.
          expandedHeight: 296,
          pinned: true,
          backgroundColor: colorScheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              // Khi cuộn lên, thanh co lại nhưng khối bên trong vẫn dựng ở
              // chiều cao đầy đủ rồi bị cắt bớt - không thì Column sẽ báo tràn
              // giữa chừng lúc thu.
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 296,
                  maxHeight: 296,
                  child: SafeArea(
                    child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                    if (!userProvider.isLoggedIn) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle_rounded,
                              size: 80,
                              color: colorScheme.onPrimary.withOpacity(0.7),
                            ),
                            const SizedBox(height: 12),
                            TrText(
                              'Chưa đăng nhập',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    final user = userProvider.currentUser;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surface,
                            ),
                            child: Center(
                              child: TrText(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TrText(
                            user.fullName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Mã vạch mã số sinh viên: quét thẳng từ điện thoại
                          // ở thư viện, phòng thi, quầy một cửa - khỏi phải
                          // mang theo thẻ cứng.
                          if (user.studentId.isNotEmpty)
                            SizedBox(
                              width: 246,
                              child: StudentBarcode(data: user.studentId),
                            ),
                          const SizedBox(height: 10),
                          TrText(
                            user.studentId,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                ),
                          ),
                        ],
                      ),
                    );
                      },
                    ),
                  ),
                ),
              ),
            ),
            title: TrText(
              '',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: TrText(
              'Tài khoản',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (userProvider.isLoggedIn) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TrText(
                                    'Đã đăng nhập',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  TrText(
                                    userProvider.currentUser.studentId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Đăng xuất',
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            // Chờ đăng xuất xong rồi mới báo: việc xóa token,
                            // keystore và toàn bộ cache đều là bất đồng bộ, báo
                            // sớm thì lần đăng nhập ngay sau đó có thể chạy đè
                            // lên phần dọn dẹp còn dở.
                            await userProvider.logout();
                            if (!context.mounted) return;
                            showAppSnackBar(
                              context,
                              'Đã đăng xuất',
                              tone: SnackTone.success,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          expand: true,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                color: colorScheme.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TrText(
                                    'Chưa đăng nhập',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  TrText(
                                    'Đăng nhập để xem lịch học',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Đăng nhập',
                          variant: AppButtonVariant.primary,
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          expand: true,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Data Reload Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: TrText(
              'Dữ liệu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (!userProvider.isLoggedIn) {
                return const SizedBox.shrink();
              }

              final lastReload = userProvider.lastDataReload;
              final shouldAutoReload = userProvider.shouldAutoReload;
              final daysSinceReload = lastReload != null
                  ? DateTime.now().difference(lastReload).inDays
                  : null;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: shouldAutoReload
                                  ? colorScheme.errorContainer
                                  : colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              shouldAutoReload
                                  ? Icons.sync_problem_rounded
                                  : Icons.sync_rounded,
                              color: shouldAutoReload
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TrText(
                                  'Cập nhật dữ liệu',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                TrText(
                                  lastReload != null
                                      ? daysSinceReload! == 0
                                          ? 'Cập nhật hôm nay'
                                          : daysSinceReload == 1
                                              ? 'Cập nhật 1 ngày trước'
                                              : 'Cập nhật $daysSinceReload ngày trước'
                                      : 'Chưa cập nhật',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: shouldAutoReload
                                            ? colorScheme.error
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TrText(
                        'Cập nhật dữ liệu',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (shouldAutoReload) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TrText(
                                  'Đã quá 30 ngày kể từ lần cập nhật cuối. Nên cập nhật dữ liệu mới',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.error,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Cập nhật ngay',
                        variant: shouldAutoReload
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        onPressed: () async {
                          // Hộp thoại chờ nằm trên Navigator gốc, nên phải
                          // đóng bằng đúng Navigator gốc. `Navigator.of(context)`
                          // ở đây lại trỏ vào Navigator lồng của khung tab -
                          // pop nhầm chỗ đó sẽ làm rỗng ngăn xếp của khung và
                          // ném '_history.isNotEmpty': is not true.
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          var dialogOpen = false;

                          void closeLoadingDialog() {
                            if (!dialogOpen) return;
                            dialogOpen = false;
                            if (rootNavigator.canPop()) rootNavigator.pop();
                          }

                          try {
                            // Show loading dialog
                            dialogOpen = true;
                            showDialog(
                              context: context,
                              useRootNavigator: true,
                              barrierDismissible: false,
                              builder: (context) => PopScope(
                                // Không cho phím back đóng hộp thoại giữa
                                // chừng: đóng sớm là cờ dialogOpen sai và lần
                                // đóng sau sẽ pop nhầm một trang thật.
                                canPop: false,
                                child: Consumer<UserProvider>(
                                  builder: (context, provider, _) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          TrText(
                                            provider.loginProgress.isNotEmpty
                                                ? provider.loginProgress
                                                : 'Đang cập nhật...',
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: provider.loginProgressPercent,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );

                            await userProvider.reloadAllData();

                            closeLoadingDialog();
                            if (context.mounted) {
                              showAppSnackBar(
                                context,
                                'Đã cập nhật dữ liệu thành công',
                                tone: SnackTone.success,
                                duration: const Duration(seconds: 2),
                              );
                            }
                          } catch (e) {
                            closeLoadingDialog();
                            if (context.mounted) {
                              showAppSnackBar(
                                context,
                                'Lỗi: ${e.toString()}',
                                tone: SnackTone.error,
                              );
                            }
                          }
                        },
                        leadingIcon: AppIcons.refresh,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: TrText(
              'Thông báo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppIcon(
                                      symbol: userProvider.notificationsEnabled
                                          ? AppIcons.notificationsOn
                                          : AppIcons.notificationsOff,
                                    ),
                                    const SizedBox(width: 16),
                                    TrText(
                                      'Thông báo lịch học',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: TrText(
                                    'Nhận thông báo trước giờ học và thi',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSwitch(
                            value: userProvider.notificationsEnabled,
                            onChanged: (value) async {
                              await userProvider.checkNotificationPermission();

                              // Try to toggle
                              bool success = await userProvider
                                  .toggleNotifications(value);

                              if (context.mounted) {
                                if (value && !success) {
                                  // User tried to enable but permission denied
                                  showAppSnackBar(
                                    context,
                                    'Không thể bật thông báo - cần cấp quyền',
                                    tone: SnackTone.warning,
                                    action: SnackBarAction(
                                        label: 'Cài đặt',
                                        onPressed: () async {
                                          try {
                                            if (Platform.isAndroid) {
                                              final String packageName =
                                                  AppInfo.packageName;

                                              final AndroidIntent
                                              intent = AndroidIntent(
                                                action:
                                                    'android.settings.APP_NOTIFICATION_SETTINGS',
                                                arguments: <String, dynamic>{
                                                  'android.provider.extra.APP_PACKAGE':
                                                      packageName,
                                                },
                                              );

                                              await intent.launch();
                                            } else if (Platform.isIOS) {
                                              final Uri settingsUri = Uri.parse(
                                                'app-settings:',
                                              );
                                              await launchUrl(settingsUri);
                                            }
                                          } catch (e) {
                                            LogService().log(
                                              'Error opening settings: $e',
                                              level: LogLevel.error,
                                            );
                                          }
                                        },
                                    ),
                                  );
                                } else if (success) {
                                  // Only show success message if toggle actually changed
                                  showAppSnackBar(
                                    context,
                                    value
                                        ? 'Đã bật thông báo'
                                        : 'Đã tắt thông báo',
                                    tone: SnackTone.success,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      // Show warning ONLY when toggle is OFF but permission is denied
                      // (so user knows they need to grant permission before enabling)
                      if (!userProvider.notificationsEnabled &&
                          !userProvider.hasNotificationPermission) ...[
                        const Divider(height: 16),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const AppIcon(
                            symbol: AppIcons.warning,
                            color: Colors.orange,
                          ),
                          title: TrText(
                            'Cần cấp quyền thông báo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: TrText(
                            'Vui lòng cấp quyền thông báo trong cài đặt hệ thống để nhận thông báo',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Mở cài đặt hệ thống',
                          variant: AppButtonVariant.primary,
                          onPressed: () async {
                            try {
                              if (Platform.isAndroid) {
                                // Android: Open app notification settings using AndroidIntent
                                final String packageName =
                                    AppInfo.packageName;

                                final AndroidIntent intent = AndroidIntent(
                                  action:
                                      'android.settings.APP_NOTIFICATION_SETTINGS',
                                  arguments: <String, dynamic>{
                                    'android.provider.extra.APP_PACKAGE':
                                        packageName,
                                  },
                                );

                                await intent.launch();
                              } else if (Platform.isIOS) {
                                // iOS: Open app settings
                                final Uri settingsUri = Uri.parse(
                                  'app-settings:',
                                );
                                await launchUrl(settingsUri);
                              }

                              if (context.mounted) {
                                showAppSnackBar(
                                  context,
                                  'Đã mở cài đặt - Vui lòng bật Thông báo',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showAppSnackBar(
                                  context,
                                  'Lỗi: $e',
                                  tone: SnackTone.error,
                                );
                              }
                            }
                          },
                          leadingIcon: AppIcons.settings,
                          expand: true,
                        ),
                      ],
                      // Daily notification toggle
                      if (userProvider.notificationsEnabled) ...[
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const AppIcon(symbol: AppIcons.sun),
                                      const SizedBox(width: 16),
                                      TrText(
                                        'Nhắc nhở hàng ngày',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40),
                                    child: TrText(
                                      'Nhận thông báo tóm tắt lịch học và thi mỗi sáng (7:00 AM)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSwitch(
                              value: userProvider.dailyNotificationsEnabled,
                              onChanged: (value) async {
                                await userProvider.toggleDailyNotifications(
                                  value,
                                );

                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    value
                                        ? 'Đã bật nhắc nhở hàng ngày'
                                        : 'Đã tắt nhắc nhở hàng ngày',
                                    tone: SnackTone.success,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                            ),
                          ],
                        ),

                        // DEBUG: Test button for daily notification
                        // if (userProvider.dailyNotificationsEnabled)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 8),
                        //     child: OutlinedButton.icon(
                        //       onPressed: () async {
                        //         await DailyNotificationService.triggerManualCheck();
                        //         if (context.mounted) {
                        //           ScaffoldMessenger.of(context).showSnackBar(
                        //             const SnackBar(
                        //               content: TrText('Đã kích hoạt kiểm tra thủ công - Xem log để biết kết quả'),
                        //               duration: Duration(seconds: 3),
                        //             ),
                        //           );
                        //         }
                        //       },
                        //       icon: const Icon(Icons.bug_report, size: 18),
                        //       label: const TrText('Test ngay bây giờ'),
                        //       style: OutlinedButton.styleFrom(
                        //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // ── Kết nối ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: TrText(
              'Kết nối',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: MailConnectionCard()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: TrText(
              'Hiển thị',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? colorScheme.primaryContainer
                                  : colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: themeProvider.isDarkMode
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          TrText(
                            themeProvider.isDarkMode
                                ? 'Chế độ tối'
                                : 'Chế độ sáng',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _buildLanguageCard(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: TrText(
              'Thông tin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Số phiên bản và ngày phát hành đều lấy từ AppInfo, nên
                  // chỉ cần sửa `version:` trong pubspec.yaml (và
                  // AppInfo.releaseDate) là mọi nơi trong app đổi theo.
                  _buildInfoRowNoneIcon(
                    context,
                    'Phiên bản',
                    AppInfo.version,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRowNoneIcon(
                    context,
                    'Ngày phát hành',
                    AppInfo.releaseDate,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Cập nhật ứng dụng: đọc tag mới nhất trên GitHub Releases, tải và
        // cài ngay trong app. Thẻ tự ẩn trên iOS.
        const SliverToBoxAdapter(child: UpdateCard()),

        SliverToBoxAdapter(
          child: SizedBox(height: FloatingNavBar.bottomInset(context)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TrText(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TrText(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowNoneIcon(
    BuildContext context,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TrText(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TrText(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Vietnamese / English switch. Text written in either language is
  /// translated on the fly, so this only changes which one wins.
  Widget _buildLanguageCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Symbols.translate_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                      weight: 600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(
                          'Ngôn ngữ',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        TrText(
                          localeProvider.followSystem
                              ? 'Theo ngôn ngữ của thiết bị'
                              : 'Đã chọn thủ công',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedPill<AppLanguage>(
                value: localeProvider.language,
                onChanged: localeProvider.setLanguage,
                segments: const [
                  SegmentItem(
                    value: AppLanguage.vietnamese,
                    label: 'Tiếng Việt',
                  ),
                  SegmentItem(
                    value: AppLanguage.english,
                    label: 'English',
                  ),
                ],
              ),
              if (!localeProvider.followSystem) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: localeProvider.useSystemLanguage,
                    child: const TrText('Dùng ngôn ngữ thiết bị'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

}
