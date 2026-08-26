import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

class AppSymbol {
	const AppSymbol(this.cupertinoName, this.materialIcon);

	final String cupertinoName;
	final IconData materialIcon;
}

class AppIcons {
	// Google Material Symbols (rounded) — https://fonts.google.com/icons
	static const calendarToday = AppSymbol('calendar', Symbols.calendar_today_rounded);
	static const calendarMonth = AppSymbol('calendar.badge.clock', Symbols.calendar_month_rounded);
	static const exams = AppSymbol('doc.text.magnifyingglass', Symbols.quiz_rounded);
	static const settings = AppSymbol('gearshape', Symbols.settings_rounded);
	static const checkCircle = AppSymbol('checkmark.circle.fill', Symbols.check_circle_rounded);
	static const downloadCloud = AppSymbol('icloud.and.arrow.down', Symbols.cloud_download_rounded);
	static const check = AppSymbol('checkmark', Symbols.check_rounded);
	static const lock = AppSymbol('lock', Symbols.lock_rounded);
	static const notificationsOn = AppSymbol('bell.fill', Symbols.notifications_active_rounded);
	static const notificationsOff = AppSymbol('bell.slash', Symbols.notifications_off_rounded);
	static const warning = AppSymbol('exclamationmark.triangle.fill', Symbols.warning_rounded);
	static const error = AppSymbol('xmark.circle.fill', Symbols.error_rounded);
	static const info = AppSymbol('info.circle', Symbols.info_rounded);
	static const add = AppSymbol('plus', Symbols.add_rounded);
	static const close = AppSymbol('xmark', Symbols.close_rounded);
	static const refresh = AppSymbol('arrow.clockwise', Symbols.refresh_rounded);
	static const schedule = AppSymbol('calendar.badge.clock', Symbols.schedule_rounded);
	static const sync = AppSymbol('arrow.triangle.2.circlepath', Symbols.sync_rounded);
	static const today = AppSymbol('calendar.today', Symbols.home_rounded);
	static const calendar = AppSymbol('calendar', Symbols.calendar_month_rounded);
	static const sun = AppSymbol('sun.max', Symbols.sunny_rounded);
	static const utilities = AppSymbol('square.grid.2x2', Symbols.apps_rounded);
}

class AppIcon extends StatelessWidget {
	const AppIcon({
		super.key,
		required this.symbol,
		this.color,
		this.size,
		this.mode,
	});

	final AppSymbol symbol;
	final Color? color;
	final double? size;
	final dynamic mode; // Placeholder for compatibility

	@override
	Widget build(BuildContext context) {
		return Icon(
			symbol.materialIcon,
			color: color,
			size: size,
			weight: 500,
			opticalSize: size ?? 24,
		);
	}
}

class AppSwitch extends StatelessWidget {
	const AppSwitch({
		super.key,
		required this.value,
		required this.onChanged,
		this.enabled = true,
		this.color,
	});

	final bool value;
	final ValueChanged<bool> onChanged;
	final bool enabled;
	final Color? color;

	@override
	Widget build(BuildContext context) {
		return Switch.adaptive(
			value: value,
			onChanged: enabled ? onChanged : null,
			activeColor: color,
		);
	}
}

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
	const AppButton({
		super.key,
		required this.label,
		required this.variant,
		this.onPressed,
		this.expand = false,
		this.leadingIcon,
		this.isLoading = false,
		this.padding,
	});

	final String label;
	final AppButtonVariant variant;
	final VoidCallback? onPressed;
	final bool expand;
	final AppSymbol? leadingIcon;
	final bool isLoading;
	final EdgeInsetsGeometry? padding;

	@override
	Widget build(BuildContext context) {
		Widget button;
		final icon = leadingIcon;
		
		switch (variant) {
			case AppButtonVariant.primary:
				if (icon != null) {
					button = FilledButton.icon(
						onPressed: isLoading ? null : onPressed,
						icon: Icon(icon.materialIcon),
						label: TrText(label),
					);
				} else {
					button = FilledButton(
						onPressed: isLoading ? null : onPressed,
						child: isLoading
							? const SizedBox(
									height: 20,
									width: 20,
									child: CircularProgressIndicator(strokeWidth: 2),
								)
							: TrText(label),
					);
				}
				break;
			case AppButtonVariant.secondary:
				if (icon != null) {
					button = OutlinedButton.icon(
						onPressed: isLoading ? null : onPressed,
						icon: Icon(icon.materialIcon),
						label: TrText(label),
					);
				} else {
					button = OutlinedButton(
						onPressed: isLoading ? null : onPressed,
						child: TrText(label),
					);
				}
				break;
			case AppButtonVariant.text:
				button = TextButton(
					onPressed: isLoading ? null : onPressed,
					child: TrText(label),
				);
				break;
		}

		if (expand) {
			button = SizedBox(width: double.infinity, child: button);
		}

		return Padding(
			padding: padding ?? EdgeInsets.zero,
			child: button,
		);
	}
}

class AppIconButton extends StatelessWidget {
	const AppIconButton({
		super.key,
		required this.symbol,
		required this.onPressed,
		this.tooltip,
		this.variant = AppButtonVariant.text,
	});

	final AppSymbol symbol;
	final VoidCallback? onPressed;
	final String? tooltip;
	final AppButtonVariant variant;

	@override
	Widget build(BuildContext context) {
		final button = IconButton(
			icon: Icon(symbol.materialIcon),
			onPressed: onPressed,
			tooltip: tooltip,
		);

		if (tooltip != null) {
			return Tooltip(
				message: tooltip!,
				child: button,
			);
		}

		return button;
	}
}

class AppFab extends StatelessWidget {
	const AppFab({
		super.key,
		required this.label,
		required this.onPressed,
		this.icon,
		this.color,
	});

	final String label;
	final VoidCallback? onPressed;
	final AppSymbol? icon;
	final Color? color;

	@override
	Widget build(BuildContext context) {
		if (icon != null) {
			return FloatingActionButton.extended(
				onPressed: onPressed,
				icon: Icon(icon!.materialIcon),
				label: TrText(label),
				backgroundColor: color,
			);
		}

		return FloatingActionButton(
			onPressed: onPressed,
			backgroundColor: color,
			child: const Icon(Icons.add),
		);
	}
}

// Alias for compatibility
typedef AppFloatingButton = AppFab;

class AppTabItem {
	const AppTabItem({required this.label, required this.symbol});

	final String label;
	final AppSymbol symbol;
}

class AppTabBar extends StatelessWidget {
	const AppTabBar({
		super.key,
		required this.items,
		required this.currentIndex,
		required this.onTap,
	});

	final List<AppTabItem> items;
	final int currentIndex;
	final ValueChanged<int> onTap;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: AppColors.surface(context),
				border: Border(
					top: BorderSide(color: AppColors.border(context)),
				),
			),
			child: SafeArea(
				top: false,
				child: NavigationBar(
					selectedIndex: currentIndex,
					onDestinationSelected: onTap,
					backgroundColor: Colors.transparent,
					surfaceTintColor: Colors.transparent,
					elevation: 0,
					destinations: [
						for (final item in items)
							NavigationDestination(
								icon: Icon(item.symbol.materialIcon,
										weight: 400, opticalSize: 24),
								selectedIcon: Icon(item.symbol.materialIcon,
										fill: 1, weight: 600, opticalSize: 24),
								label: context.tr(item.label),
							),
					],
				),
			),
		);
	}
}

class AppEmptyStateIcon extends StatelessWidget {
	const AppEmptyStateIcon({
		super.key,
		required this.symbol,
		this.size = 64,
		this.color,
	});

	final AppSymbol symbol;
	final double size;
	final Color? color;

	@override
	Widget build(BuildContext context) {
		return AppIcon(
			symbol: symbol,
			size: size,
			color: color ?? Theme.of(context).colorScheme.outlineVariant,
		);
	}
}
