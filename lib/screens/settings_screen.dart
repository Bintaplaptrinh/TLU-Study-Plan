import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:tlustudy_planner/providers/theme_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/login_screen.dart';
import 'package:tlustudy_planner/services/log_service.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';
// import 'package:tlustudy_planner/services/daily_notification_service.dart'; // Commented out with test button

import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Modern gradient header
        SliverAppBar(
          expandedHeight: 200,
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
                            Text(
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
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
                          Text(
                            user.fullName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.studentId,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            title: Text(
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
            child: Text(
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
                                  Text(
                                    'Đã đăng nhập',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
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
                          onPressed: () {
                            userProvider.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã đăng xuất'),
                                duration: const Duration(seconds: 2),
                              ),
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
                                  Text(
                                    'Chưa đăng nhập',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
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
                            Navigator.of(context).push(
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
            child: Text(
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
                                Text(
                                  'Cập nhật dữ liệu',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
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
                      Text(
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
                                child: Text(
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
                          final messenger = ScaffoldMessenger.of(context);
                          
                          try {
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => WillPopScope(
                                onWillPop: () async => false,
                                child: Consumer<UserProvider>(
                                  builder: (context, provider, _) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text(
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

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật dữ liệu thành công'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('❌ Lỗi: ${e.toString()}'),
                                  duration: const Duration(seconds: 3),
                                ),
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
            child: Text(
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
                                    Text(
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
                                  child: Text(
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
                              // ✅ ALWAYS check current permission status before toggling
                              // This handles the case where user granted permission in settings
                              await userProvider.checkNotificationPermission();

                              // Try to toggle
                              bool success = await userProvider
                                  .toggleNotifications(value);

                              if (context.mounted) {
                                if (value && !success) {
                                  // User tried to enable but permission denied
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '⚠️ Không thể bật thông báo - cần cấp quyền',
                                      ),
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Cài đặt',
                                        onPressed: () async {
                                          try {
                                            if (Platform.isAndroid) {
                                              final PackageInfo packageInfo =
                                                  await PackageInfo.fromPlatform();
                                              final String packageName =
                                                  packageInfo.packageName;

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
                                    ),
                                  );
                                } else if (success) {
                                  // Only show success message if toggle actually changed
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? 'Đã bật thông báo'
                                            : 'Đã tắt thông báo',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
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
                          title: Text(
                            'Cần cấp quyền thông báo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
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
                                final PackageInfo packageInfo =
                                    await PackageInfo.fromPlatform();
                                final String packageName =
                                    packageInfo.packageName;

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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã mở cài đặt - Vui lòng bật Thông báo',
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    duration: const Duration(seconds: 3),
                                  ),
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
                                      Text(
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
                                    child: Text(
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? 'Đã bật nhắc nhở hàng ngày'
                                            : 'Đã tắt nhắc nhở hàng ngày',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
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
                        //               content: Text('🧪 Đã kích hoạt kiểm tra thủ công - Xem log để biết kết quả'),
                        //               duration: Duration(seconds: 3),
                        //             ),
                        //           );
                        //         }
                        //       },
                        //       icon: const Icon(Icons.bug_report, size: 18),
                        //       label: const Text('Test ngay bây giờ'),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
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
                          Text(
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
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
                  _buildInfoRowNoneIcon(
                    context,
                    'Phiên bản',
                    '1.0.1',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRowNoneIcon(
                    context,
                    'Ngày phát hành',
                    '11-11-2025',
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
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
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
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
}
