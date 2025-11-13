import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen>
    with AutomaticKeepAliveClientMixin {
  // Map of semester ID -> marks for that semester
  Map<int, List<StudentSubjectMark>> _marksBySemester = {};
  List<StudentBehaviorMark> _behaviorMarks = [];
  List<StudentTuition> _tuitionData = [];
  bool _isLoadingMarks = false;
  bool _isLoadingBehavior = false;
  bool _isLoadingTuition = false;
  int _selectedTab = 0; // 0: Điểm, 1: Rèn luyện, 2: Học phí
  String? _marksError;
  String? _behaviorError;
  String? _tuitionError;
  
  // Expanded state for each semester
  Set<int> _expandedSemesters = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  /// Load all real-time data from API
  Future<void> _loadAllData() async {
    final userProvider = context.read<UserProvider>();

    if (!mounted) return;

    // Load marks for ALL semesters
    setState(() {
      _isLoadingMarks = true;
      _marksError = null;
    });
    
    try {
      // Get all available semesters
      final schoolYears = userProvider.schoolYears;
      if (schoolYears == null || schoolYears.content.isEmpty) {
        if (mounted) {
          setState(() {
            _marksBySemester = {};
            _isLoadingMarks = false;
            _marksError = 'Không tìm thấy học kỳ';
          });
        }
      } else {
        // Get all semesters from school years
        final allSemesters = schoolYears.content
            .expand((year) => year.semesters)
            .toList();
        
        // Fetch marks for each semester
        final Map<int, List<StudentSubjectMark>> marksBySemester = {};
        
        for (final semester in allSemesters) {
          try {
            final marks = await userProvider.fetchStudentMarks(semester.id);
            if (marks.isNotEmpty) {
              marksBySemester[semester.id] = marks;
            }
          } catch (e) {
            // Skip semesters with errors, continue fetching others
            print('Error fetching marks for semester ${semester.id}: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _marksBySemester = marksBySemester;
            _isLoadingMarks = false;
            _marksError = marksBySemester.isEmpty ? 'no_data' : null;
            // Expand the most recent semester by default
            if (marksBySemester.isNotEmpty) {
              _expandedSemesters = {marksBySemester.keys.reduce((a, b) => a > b ? a : b)};
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _marksBySemester = {};
          _isLoadingMarks = false;
          _marksError = e.toString();
        });
      }
    }

    // Load behavior marks (all semesters)
    setState(() {
      _isLoadingBehavior = true;
      _behaviorError = null;
    });
    try {
      final behaviorMarks = await userProvider.fetchBehaviorMarks();
      if (mounted) {
        setState(() {
          _behaviorMarks = behaviorMarks;
          _isLoadingBehavior = false;
          _behaviorError = behaviorMarks.isEmpty ? 'no_data' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _behaviorMarks = [];
          _isLoadingBehavior = false;
          _behaviorError = e.toString();
        });
      }
    }

    // Load tuition data
    setState(() {
      _isLoadingTuition = true;
      _tuitionError = null;
    });
    try {
      final tuitionData = await userProvider.fetchStudentPayable();
      if (mounted) {
        setState(() {
          _tuitionData = tuitionData;
          _isLoadingTuition = false;
          _tuitionError = tuitionData.isEmpty ? 'no_data' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tuitionData = [];
          _isLoadingTuition = false;
          _tuitionError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Tiện ích',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAllData,
                tooltip: 'Tải lại',
              ),
            ],
          ),

          // User info
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProvider.tluUser?.displayName ?? 'Sinh viên',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTab == 0
                              ? '${_marksBySemester.length} học kỳ có điểm'
                              : _selectedTab == 1
                                  ? '${_behaviorMarks.length} bản ghi rèn luyện'
                                  : '${_tuitionData.length} bản ghi học phí',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab selector
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(0, 'Điểm số', Icons.grade, theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      1,
                      'Rèn luyện',
                      Icons.emoji_events,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      2,
                      'Học phí',
                      Icons.payment,
                      theme,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Content based on selected tab
          if (_selectedTab == 0) _buildMarksContent(theme),
          if (_selectedTab == 1) _buildBehaviorMarksContent(theme),
          if (_selectedTab == 2) _buildTuitionContent(theme),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, ThemeData theme) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksContent(ThemeData theme) {
    if (_isLoadingMarks) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_marksBySemester.isEmpty) {
      final isError = _marksError != null && _marksError != 'no_data';
      return SliverFillRemaining(
        child: _buildEmptyState(
          isError ? 'Không thể tải điểm số' : 'Chưa có điểm số',
          isError
              ? 'API endpoint chưa được hỗ trợ hoặc chưa có dữ liệu.\nVui lòng thử lại sau.'
              : 'Điểm số sẽ hiển thị sau khi giảng viên chấm điểm',
          Icons.grade,
        ),
      );
    }

    // Calculate overall GPA across all semesters
    double totalMark4 = 0;
    double totalCredits = 0;
    _marksBySemester.forEach((semesterId, marks) {
      for (var mark in marks) {
        if (mark.mark4 != null) {
          totalMark4 += mark.mark4! * mark.credits;
          totalCredits += mark.credits;
        }
      }
    });
    final overallGpa = totalCredits > 0 ? totalMark4 / totalCredits : 0.0;

    // Get all semester IDs sorted in descending order (newest first)
    final sortedSemesterIds = _marksBySemester.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildListDelegate([
        // Overall GPA Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPA Tích lũy (Hệ 4)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overallGpa.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '${totalCredits.toInt()} TC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Semester sections
        ...sortedSemesterIds.map((semesterId) {
          final marks = _marksBySemester[semesterId]!;
          final isExpanded = _expandedSemesters.contains(semesterId);
          
          // Find semester name
          final userProvider = context.read<UserProvider>();
          String semesterName = 'Học kỳ $semesterId';
          if (userProvider.schoolYears != null) {
            for (final year in userProvider.schoolYears!.content) {
              final semester = year.semesters.firstWhere(
                (s) => s.id == semesterId,
                orElse: () => year.semesters.first,
              );
              if (semester.id == semesterId) {
                semesterName = semester.semesterName;
                break;
              }
            }
          }
          
          // Calculate semester GPA
          double semesterMark4 = 0;
          double semesterCredits = 0;
          for (var mark in marks) {
            if (mark.mark4 != null) {
              semesterMark4 += mark.mark4! * mark.credits;
              semesterCredits += mark.credits;
            }
          }
          final semesterGpa = semesterCredits > 0 ? semesterMark4 / semesterCredits : 0.0;
          
          return Column(
            children: [
              _buildSemesterHeader(
                semesterName,
                semesterGpa,
                semesterCredits.toInt(),
                marks.length,
                isExpanded,
                () {
                  setState(() {
                    if (isExpanded) {
                      _expandedSemesters.remove(semesterId);
                    } else {
                      _expandedSemesters.add(semesterId);
                    }
                  });
                },
                theme,
              ),
              if (isExpanded) ...marks.map((mark) => _buildMarkCard(mark, theme)),
            ],
          );
        }).toList(),
      ]),
    );
  }

  Widget _buildBehaviorMarksContent(ThemeData theme) {
    if (_isLoadingBehavior) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_behaviorMarks.isEmpty) {
      final isError = _behaviorError != null && _behaviorError != 'no_data';
      return SliverFillRemaining(
        child: _buildEmptyState(
          isError ? 'Không thể tải điểm rèn luyện' : 'Chưa có điểm rèn luyện',
          isError
              ? 'API endpoint chưa được hỗ trợ hoặc chưa có dữ liệu.\nVui lòng thử lại sau.'
              : 'Điểm rèn luyện sẽ được cập nhật sau mỗi học kỳ',
          Icons.emoji_events,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final mark = _behaviorMarks[index];
          return _buildBehaviorCard(mark, theme);
        },
        childCount: _behaviorMarks.length,
      ),
    );
  }

  Widget _buildTuitionContent(ThemeData theme) {
    if (_isLoadingTuition) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tuitionData.isEmpty) {
      final isError = _tuitionError != null && _tuitionError != 'no_data';
      return SliverFillRemaining(
        child: _buildEmptyState(
          isError ? 'Không thể tải thông tin học phí' : 'Chưa có thông tin học phí',
          isError
              ? 'API endpoint chưa được hỗ trợ hoặc chưa có dữ liệu.\nVui lòng thử lại sau.'
              : 'Thông tin học phí sẽ được cập nhật',
          Icons.payment,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tuition = _tuitionData[index];
          return _buildTuitionCard(tuition, theme);
        },
        childCount: _tuitionData.length,
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterHeader(
    String semesterName,
    double gpa,
    int credits,
    int subjectCount,
    bool isExpanded,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.school,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semesterName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subjectCount môn • $credits TC • GPA: ${gpa.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkCard(StudentSubjectMark mark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          mark.subjectName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mark.subjectCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.credit_card, size: 14, color: AppTheme.accentColor),
              const SizedBox(width: 4),
              Text(
                '${mark.credits.toStringAsFixed(1)} TC',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: mark.isPassed
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mark.mark10 != null)
                Text(
                  mark.mark10!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mark.isPassed ? Colors.green : Colors.red,
                  ),
                ),
              if (mark.markLetter != null)
                Text(
                  mark.markLetter!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mark.isPassed ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBehaviorCard(StudentBehaviorMark mark, ThemeData theme) {
    Color getMarkColor(int markValue) {
      if (markValue >= 90) return Colors.green;
      if (markValue >= 80) return Colors.blue;
      if (markValue >= 65) return Colors.orange;
      if (markValue >= 50) return Colors.deepOrange;
      return Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: getMarkColor(mark.mark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events,
              color: getMarkColor(mark.mark),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mark.semesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mark.classification,
                  style: TextStyle(
                    fontSize: 13,
                    color: getMarkColor(mark.mark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: getMarkColor(mark.mark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${mark.mark}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getMarkColor(mark.mark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionCard(StudentTuition tuition, ThemeData theme) {
    final isPaid = tuition.remainingAmount <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tuition.semesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tuition.paymentStatus,
                  style: TextStyle(
                    color: isPaid ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTuitionRow(
            'Tổng học phí',
            tuition.tuitionFee,
            theme,
            icon: Icons.attach_money,
          ),
          const Divider(height: 24),
          _buildTuitionRow(
            'Đã đóng',
            tuition.paidAmount,
            theme,
            color: Colors.green,
            icon: Icons.check_circle,
          ),
          const SizedBox(height: 8),
          _buildTuitionRow(
            'Còn lại',
            tuition.remainingAmount,
            theme,
            color: isPaid ? Colors.green : Colors.red,
            icon: Icons.pending,
            isBold: true,
          ),
          if (tuition.paymentDeadline != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Hạn nộp: ${tuition.paymentDeadline}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTuitionRow(
    String label,
    double amount,
    ThemeData theme, {
    Color? color,
    IconData? icon,
    bool isBold = false,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${_formatCurrency(amount)} đ',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
