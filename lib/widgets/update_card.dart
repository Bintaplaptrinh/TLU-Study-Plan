import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/services/update_service.dart';
import 'package:tlustudy_planner/widgets/update_dialog.dart';

/// Thẻ "Cập nhật ứng dụng" trong Cài đặt → Thông tin.
///
/// Hai việc: một nút kiểm tra ngay, và một công tắc cho lần tự kiểm tra hằng
/// ngày lúc mở app. Trên iOS và máy tính thì không có gì để làm - bản `.apk`
/// chỉ cài được trên Android - nên thẻ tự ẩn.
class UpdateCard extends StatefulWidget {
  const UpdateCard({super.key});

  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<UpdateCard> {
  bool _autoCheck = true;
  bool _checking = false;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await UpdateService.instance.isAutoCheckEnabled();
    final last = await UpdateService.instance.lastCheckedAt();
    if (!mounted) return;
    setState(() {
      _autoCheck = enabled;
      _lastChecked = last;
    });
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await runInteractiveUpdateCheck(context);
    } finally {
      if (mounted) {
        setState(() => _checking = false);
        _loadPrefs();
      }
    }
  }

  Future<void> _toggleAuto(bool value) async {
    setState(() => _autoCheck = value);
    await UpdateService.instance.setAutoCheckEnabled(value);
  }

  String get _lastCheckedLabel {
    final last = _lastChecked;
    if (last == null) return 'Chưa kiểm tra lần nào';

    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 1) return 'Vừa kiểm tra xong';
    if (diff.inHours < 1) return 'Đã kiểm tra ${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return 'Đã kiểm tra ${diff.inHours} giờ trước';
    return 'Đã kiểm tra ${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _checking ? null : _check,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Symbols.system_update_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(
                          'Kiểm tra cập nhật',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        TrText(
                          _lastCheckedLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_checking)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText(
                        'Tự động kiểm tra',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      TrText(
                        'Mỗi ngày một lần khi mở ứng dụng',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: _autoCheck, onChanged: _toggleAuto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
