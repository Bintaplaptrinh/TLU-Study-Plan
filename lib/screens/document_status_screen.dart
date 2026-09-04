import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/models/document_request.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/services/document_request_service.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/widgets/detail_sheet.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';

/// "Kiểm tra tình trạng đơn" - các đơn của chính sinh viên đang đăng nhập.
///
/// Bảng gốc của Phân hiệu là một Google Sheet mười bốn cột; nhúng thẳng vào
/// ứng dụng thì sinh viên phải cuộn ngang qua cả những cột không liên quan để
/// tìm dòng của mình. Ở đây mỗi lần nộp đơn là một thẻ - tên đơn, trạng thái,
/// ngày gửi - và chi tiết đầy đủ nằm trong popup khi chạm vào.
class DocumentStatusScreen extends StatefulWidget {
  const DocumentStatusScreen({super.key});

  @override
  State<DocumentStatusScreen> createState() => _DocumentStatusScreenState();
}

class _DocumentStatusScreenState extends State<DocumentStatusScreen> {
  List<DocumentRequest> _requests = const [];
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final user = context.read<UserProvider>().currentUser;

    if (user.studentId.trim().isEmpty && user.fullName.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = 'not_signed_in';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await DocumentRequestService.instance.fetchForStudent(
        studentCode: user.studentId,
        fullName: user.fullName,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
        _fetchedAt = DocumentRequestService.instance.lastFetchedAt;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is DocumentRequestException ? e.message : e.toString();
      });
    }
  }

  String get _subtitle {
    if (_loading) return 'Đang tra cứu...';
    if (_error != null) return 'Không tra cứu được';
    if (_requests.isEmpty) return 'Chưa tìm thấy đơn nào';
    final at = _fetchedAt;
    final stamp = at == null ? '' : ' · cập nhật ${_clock(at)}';
    return '${_requests.length} đơn$stamp';
  }

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: 'Kiểm tra tình trạng đơn',
                  subtitle: _subtitle,
                  actions: [
                    HeaderIconButton(
                      icon: Symbols.refresh_rounded,
                      tooltip: 'Tải lại',
                      onTap: _loading ? null : () => _load(forceRefresh: true),
                    ),
                  ],
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _error == 'not_signed_in'
                      ? const EmptyStateWidget(
                          icon: Symbols.person_off_rounded,
                          title: 'Chưa đăng nhập',
                          description:
                              'Đăng nhập để ứng dụng biết mã số sinh viên và họ tên cần tra cứu.',
                        )
                      : EmptyStateWidget(
                          icon: Symbols.cloud_off_rounded,
                          title: 'Không tra cứu được',
                          description:
                              'Bảng theo dõi đơn không phản hồi.\n$_error',
                        ),
                )
              else if (_requests.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Symbols.inbox_rounded,
                    title: 'Chưa tìm thấy đơn nào',
                    description:
                        'Đơn chỉ xuất hiện ở đây sau khi bạn đã "Ghi danh nộp đơn". '
                        'Nếu vừa ghi danh xong, hãy chờ Phân hiệu nhập vào bảng rồi kéo xuống để tải lại.',
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _summaryStrip(_requests)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverList.separated(
                    itemCount: _requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _RequestCard(request: _requests[index]),
                  ),
                ),
              ],

              SliverToBoxAdapter(
                child: SizedBox(height: FloatingNavBar.bottomInset(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hàng đếm nhanh theo trạng thái, để không phải lướt hết danh sách mới biết
  /// còn đơn nào đang treo.
  Widget _summaryStrip(List<DocumentRequest> requests) {
    final counts = <DocumentRequestStatus, int>{};
    for (final r in requests) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }

    final order = [
      DocumentRequestStatus.completed,
      DocumentRequestStatus.processing,
      DocumentRequestStatus.pending,
      DocumentRequestStatus.notCompleted,
    ].where((s) => (counts[s] ?? 0) > 0).toList();

    if (order.length < 2) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final status in order)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor(context, status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon(status),
                    size: 15,
                    color: statusColor(context, status),
                  ),
                  const SizedBox(width: 6),
                  TrText(
                    '${counts[status]} ${status.label.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor(context, status),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Màu của một trạng thái - dùng chung cho thẻ, popup và hàng đếm.
Color statusColor(BuildContext context, DocumentRequestStatus status) {
  switch (status) {
    case DocumentRequestStatus.completed:
      return AppColors.success(context);
    case DocumentRequestStatus.notCompleted:
      return AppColors.danger(context);
    case DocumentRequestStatus.processing:
      return AppColors.warning(context);
    case DocumentRequestStatus.pending:
      return AppColors.textMuted(context);
  }
}

IconData statusIcon(DocumentRequestStatus status) {
  switch (status) {
    case DocumentRequestStatus.completed:
      return Symbols.check_circle_rounded;
    case DocumentRequestStatus.notCompleted:
      return Symbols.cancel_rounded;
    case DocumentRequestStatus.processing:
      return Symbols.hourglass_top_rounded;
    case DocumentRequestStatus.pending:
      return Symbols.schedule_rounded;
  }
}

/// Một lần nộp đơn: tên đơn, họ tên, trạng thái. Chạm để mở chi tiết.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final DocumentRequest request;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, request.status);
    final submitted = request.submittedAt;

    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _showDetail(context, request),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border(context)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(statusIcon(request.status), size: 21, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.type.isEmpty ? 'Đơn không rõ loại' : request.type,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (request.fullName.isNotEmpty) request.fullName,
                        if (submitted != null) _dayMonthYear(submitted),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        DetailChip(label: request.status.label, color: color),
                        if (request.condition.isNotEmpty) ...[
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              request.condition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSoft(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 11, left: 4),
                child: Icon(
                  Symbols.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dayMonthYear(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

String _fullStamp(DateTime t) =>
    '${_dayMonthYear(t)} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void _showDetail(BuildContext context, DocumentRequest request) {
  final color = statusColor(context, request.status);

  showDetailSheet(
    context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSheetHeader(
          icon: statusIcon(request.status),
          color: color,
          title: request.type.isEmpty ? 'Đơn không rõ loại' : request.type,
          subtitle: request.submittedAt == null
              ? (request.submittedAtRaw.isEmpty
                    ? 'Không có dấu thời gian'
                    : request.submittedAtRaw)
              : 'Gửi lúc ${_fullStamp(request.submittedAt!)}',
          translateTitle: false,
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: DetailChip(label: request.status.label, color: color),
        ),
        const DetailDivider(),

        DetailRow(
          icon: Symbols.person_rounded,
          label: 'Họ và tên',
          value: request.fullName.isEmpty ? '—' : request.fullName,
        ),
        DetailRow(
          icon: Symbols.badge_rounded,
          label: 'Mã sinh viên',
          value: request.studentCode.isEmpty ? '—' : request.studentCode,
        ),
        DetailRow(
          icon: Symbols.groups_rounded,
          label: 'Lớp',
          value: request.className.isEmpty ? '—' : request.className,
        ),
        DetailRow(
          icon: Symbols.send_rounded,
          label: 'Nguồn gửi',
          value: request.source.isEmpty ? '—' : request.source,
          translateValue: true,
        ),

        const DetailDivider(),

        DetailRow(
          icon: Symbols.fact_check_rounded,
          label: 'Trạng thái',
          value: request.statusRaw.isEmpty
              ? request.status.label
              : request.statusRaw,
          valueColor: color,
          translateValue: true,
          strong: true,
        ),
        DetailRow(
          icon: Symbols.assignment_turned_in_rounded,
          label: 'Tình trạng',
          value: request.condition.isEmpty ? '—' : request.condition,
          translateValue: true,
        ),

        if (request.notice.isNotEmpty) ...[
          const DetailDivider(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentTint(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Symbols.campaign_rounded,
                      size: 18,
                      color: AppColors.accent(context),
                    ),
                    const SizedBox(width: 8),
                    TrText(
                      'Thông báo',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        color: AppColors.accent(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TrText(
                  request.notice,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
