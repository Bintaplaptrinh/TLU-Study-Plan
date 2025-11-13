import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';

/// Example screen showing how to use the new real-time API functions
/// This screen demonstrates fetching marks, behavior marks, and tuition data
class MarksScreenExample extends StatefulWidget {
  const MarksScreenExample({super.key});

  @override
  State<MarksScreenExample> createState() => _MarksScreenExampleState();
}

class _MarksScreenExampleState extends State<MarksScreenExample> {
  List<StudentSubjectMark> _marks = [];
  List<StudentBehaviorMark> _behaviorMarks = [];
  List<StudentTuition> _tuitionData = [];
  bool _isLoadingMarks = false;
  bool _isLoadingBehavior = false;
  bool _isLoadingTuition = false;

  @override
  void initState() {
    super.initState();
    // Load data when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  /// Load all real-time data from API
  /// This will be called every time the user navigates to this screen
  Future<void> _loadAllData() async {
    final userProvider = context.read<UserProvider>();
    final selectedSemester = userProvider.selectedSemester;

    if (selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn học kỳ')),
      );
      return;
    }

    // Load marks for selected semester
    setState(() => _isLoadingMarks = true);
    final marks = await userProvider.fetchStudentMarks(selectedSemester.id);
    setState(() {
      _marks = marks;
      _isLoadingMarks = false;
    });

    // Load behavior marks (all semesters)
    setState(() => _isLoadingBehavior = true);
    final behaviorMarks = await userProvider.fetchBehaviorMarks();
    setState(() {
      _behaviorMarks = behaviorMarks;
      _isLoadingBehavior = false;
    });

    // Load tuition data
    setState(() => _isLoadingTuition = true);
    final tuitionData = await userProvider.fetchStudentPayable();
    setState(() {
      _tuitionData = tuitionData;
      _isLoadingTuition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm & Học phí'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Student Marks Section
            _buildSectionTitle('Điểm học phần', theme),
            const SizedBox(height: 8),
            if (_isLoadingMarks)
              const Center(child: CircularProgressIndicator())
            else if (_marks.isEmpty)
              _buildEmptyState('Chưa có điểm')
            else
              ..._marks.map((mark) => _buildMarkCard(mark, theme)),
            
            const SizedBox(height: 24),

            // Behavior Marks Section
            _buildSectionTitle('Điểm rèn luyện', theme),
            const SizedBox(height: 8),
            if (_isLoadingBehavior)
              const Center(child: CircularProgressIndicator())
            else if (_behaviorMarks.isEmpty)
              _buildEmptyState('Chưa có điểm rèn luyện')
            else
              ..._behaviorMarks.map((mark) => _buildBehaviorCard(mark, theme)),

            const SizedBox(height: 24),

            // Tuition Section
            _buildSectionTitle('Học phí', theme),
            const SizedBox(height: 8),
            if (_isLoadingTuition)
              const Center(child: CircularProgressIndicator())
            else if (_tuitionData.isEmpty)
              _buildEmptyState('Chưa có thông tin học phí')
            else
              ..._tuitionData.map((tuition) => _buildTuitionCard(tuition, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkCard(StudentSubjectMark mark, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          mark.subjectName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${mark.subjectCode} • ${mark.credits} tín chỉ'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (mark.mark10 != null)
              Text(
                mark.mark10!.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mark.isPassed ? Colors.green : Colors.red,
                ),
              ),
            if (mark.markLetter != null)
              Text(
                mark.markLetter!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorCard(StudentBehaviorMark mark, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          mark.semesterName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(mark.classification),
        trailing: Text(
          '${mark.mark} điểm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: mark.mark >= 80
                ? Colors.green
                : mark.mark >= 65
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildTuitionCard(StudentTuition tuition, ThemeData theme) {
    final isPaid = tuition.remainingAmount <= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tuition.semesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tuition.paymentStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTuitionRow('Tổng học phí', tuition.tuitionFee, theme),
            _buildTuitionRow('Đã đóng', tuition.paidAmount, theme, color: Colors.green),
            _buildTuitionRow('Còn lại', tuition.remainingAmount, theme, color: Colors.red),
            if (tuition.paymentDeadline != null) ...[
              const SizedBox(height: 8),
              Text(
                'Hạn nộp: ${tuition.paymentDeadline}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTuitionRow(
    String label,
    double amount,
    ThemeData theme, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} đ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
