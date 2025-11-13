import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppSymbol {
	const AppSymbol(this.cupertinoName, this.materialIcon);

	final String cupertinoName;
	final IconData materialIcon;
}

class AppIcons {
	static const calendarToday = AppSymbol('calendar', Icons.calendar_today_outlined);
	static const calendarMonth = AppSymbol('calendar.badge.clock', Icons.calendar_month);
	static const exams = AppSymbol('doc.text.magnifyingglass', Icons.quiz);
	static const settings = AppSymbol('gearshape', Icons.settings);
	static const checkCircle = AppSymbol('checkmark.circle.fill', Icons.check_circle);
	static const downloadCloud = AppSymbol('icloud.and.arrow.down', Icons.cloud_download);
	static const check = AppSymbol('checkmark', Icons.check);
	static const lock = AppSymbol('lock', Icons.lock_outlined);
	static const notificationsOn = AppSymbol('bell.fill', Icons.notifications);
	static const notificationsOff = AppSymbol('bell.slash', Icons.notifications_off);
	static const warning = AppSymbol('exclamationmark.triangle.fill', Icons.warning_amber);
	static const error = AppSymbol('xmark.circle.fill', Icons.error);
	static const info = AppSymbol('info.circle', Icons.info);
	static const add = AppSymbol('plus', Icons.add);
	static const close = AppSymbol('xmark', Icons.close);
	static const refresh = AppSymbol('arrow.clockwise', Icons.refresh);
	static const schedule = AppSymbol('calendar.badge.clock', Icons.schedule);
	static const sync = AppSymbol('arrow.triangle.2.circlepath', Icons.sync);
	static const today = AppSymbol('calendar.today', Icons.today);
	static const calendar = AppSymbol('calendar', Icons.calendar_month);
	static const sun = AppSymbol('sun.max', Icons.wb_sunny);
	static const utilities = AppSymbol('square.grid.2x2', Icons.apps);
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
		return AdaptiveSwitch(
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
						label: Text(label),
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
							: Text(label),
					);
				}
				break;
			case AppButtonVariant.secondary:
				if (icon != null) {
					button = OutlinedButton.icon(
						onPressed: isLoading ? null : onPressed,
						icon: Icon(icon.materialIcon),
						label: Text(label),
					);
				} else {
					button = OutlinedButton(
						onPressed: isLoading ? null : onPressed,
						child: Text(label),
					);
				}
				break;
			case AppButtonVariant.text:
				button = TextButton(
					onPressed: isLoading ? null : onPressed,
					child: Text(label),
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
				label: Text(label),
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
		// Use Flutter's built-in adaptive navigation
		final isCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
				Theme.of(context).platform == TargetPlatform.macOS;
		
		if (isCupertino) {
			return CupertinoTabBar(
				currentIndex: currentIndex,
				onTap: onTap,
				items: [
					for (final item in items)
						BottomNavigationBarItem(
							icon: Icon(item.symbol.materialIcon),
							label: item.label,
						),
				],
			);
		}
		
		return NavigationBar(
			selectedIndex: currentIndex,
			onDestinationSelected: onTap,
			destinations: [
				for (final item in items)
					NavigationDestination(
						icon: Icon(item.symbol.materialIcon),
						label: item.label,
					),
			],
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
