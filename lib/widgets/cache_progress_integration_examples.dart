import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/cache_progress_banner.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';

/// Example of how to integrate the cache progress banner
/// into your main screen or home screen

class ExampleIntegration extends StatelessWidget {
  const ExampleIntegration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TrText('TLU Study Planner'),
      ),
      body: Column(
        children: [
          const CacheProgressBanner(),
          
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const TrText('Thời khóa biểu'),
                  onTap: () {
                    // Navigate to schedule screen
                  },
                ),
                ListTile(
                  title: const TrText('Lịch thi'),
                  onTap: () {
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      
      floatingActionButton: const ResumeCachingButton(),
    );
  }
}

class ExampleWithOverlay extends StatelessWidget {
  const ExampleWithOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TrText('TLU Study Planner'),
      ),
      body: Stack(
        children: [
          YourMainContent(),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const CacheProgressBanner(),
          ),
        ],
      ),
      floatingActionButton: const ResumeCachingButton(),
    );
  }
}

class YourMainContent extends StatelessWidget {
  const YourMainContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.calendar_today, size: 64),
          SizedBox(height: 16),
          TrText('Your App Content Here'),
        ],
      ),
    );
  }
}

class ManualCacheButton extends StatelessWidget {
  const ManualCacheButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        if (examProvider.isPreCaching) {
          return const SizedBox.shrink();
        }

        return ElevatedButton.icon(
          onPressed: () async {
            // Get user provider
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            
            if (userProvider.accessToken != null && 
                userProvider.selectedSemester != null) {
              // Start caching
              await examProvider.preCacheAllExamData(
                userProvider.accessToken!,
                userProvider.selectedSemester!.id,
              );
              
              // Show success message
              if (context.mounted) {
                showAppSnackBar(
                  context,
                  'Đã tải xong dữ liệu offline',
                  tone: SnackTone.success,
                );
              }
            } else {
              // No token - show login required
              showAppSnackBar(
                context,
                'Vui lòng đăng nhập để tải dữ liệu',
                tone: SnackTone.warning,
              );
            }
          },
          icon: const Icon(Icons.cloud_download),
          label: const TrText('Tải dữ liệu offline'),
        );
      },
    );
  }
}

/// Example: Show cache status in a settings screen
class CacheStatusWidget extends StatelessWidget {
  const CacheStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TrText(
                  'Trạng thái dữ liệu offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status
                Row(
                  children: [
                    Icon(
                      examProvider.preCacheProgress == 100
                          ? Icons.check_circle
                          : examProvider.isPreCaching
                              ? Icons.hourglass_empty
                              : Icons.warning,
                      color: examProvider.preCacheProgress == 100
                          ? Colors.green
                          : examProvider.isPreCaching
                              ? Colors.blue
                              : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    TrText(
                      examProvider.preCacheProgress == 100
                          ? 'Đã sẵn sàng'
                          : examProvider.isPreCaching
                              ? 'Đang tải...'
                              : 'Chưa hoàn tất',
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: examProvider.preCacheProgress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      examProvider.preCacheProgress == 100
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Progress text
                TrText(
                  '${examProvider.preCacheProgress}% hoàn thành',
                  style: const TextStyle(fontSize: 12),
                ),
                
                if (examProvider.preCacheTotalSemesters > 0) ...[
                  const SizedBox(height: 4),
                  TrText(
                    'Học kỳ: ${examProvider.preCacheCurrentSemester}/${examProvider.preCacheTotalSemesters}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                
                if (examProvider.isPreCaching) ...[
                  const SizedBox(height: 8),
                  TrText(
                    examProvider.preCacheStatus,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
