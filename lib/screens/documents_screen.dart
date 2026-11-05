import 'package:flutter/material.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';

/// The school replaced its form process. Keep old submission routes closed.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          PageHeader(title: 'Đơn từ'),
          Expanded(
            child: EmptyStateWidget(
              icon: Icons.lock_rounded,
              title: 'Đơn từ tạm khóa',
              description:
                  'Nhà trường đã thay đổi quy trình làm đơn. Vui lòng thực hiện theo hướng dẫn mới của nhà trường.',
            ),
          ),
        ],
      ),
    ),
  );
}
