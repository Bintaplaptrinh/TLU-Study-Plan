import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/cache_progress_banner.dart';

/// Example of how to integrate the cache progress banner
/// into your main screen or home screen

class ExampleIntegration extends StatelessWidget {
  const ExampleIntegration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TLU Study Planner'),
      ),
      body: Column(
        children: [
          // ✅ ADD THIS: Cache progress banner at the top
          const CacheProgressBanner(),
          
          // Your existing screen content
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Thời khóa biểu'),
                  onTap: () {
                    // Navigate to schedule screen
                  },
                ),
                ListTile(
                  title: const Text('Lịch thi'),
                  onTap: () {
                    // Navigate to exam screen
                  },
                ),
                // ... more menu items
              ],
            ),
          ),
        ],
      ),
      
      // ✅ ADD THIS: Resume button (shows only if caching incomplete)
      floatingActionButton: const ResumeCachingButton(),
    );
  }
}

/// Alternative: Banner can also be placed in a Stack for overlay effect
class ExampleWithOverlay extends StatelessWidget {
  const ExampleWithOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TLU Study Planner'),
      ),
      body: Stack(
        children: [
          // Your main content
          YourMainContent(),
          
          // ✅ Floating banner at the top
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
          Text('Your App Content Here'),
        ],
      ),
    );
  }
}

/// Example: Manually trigger caching with a button
class ManualCacheButton extends StatelessWidget {
  const ManualCacheButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        // Don't show if already caching
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã tải xong dữ liệu offline!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              // No token - show login required
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng đăng nhập để tải dữ liệu'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          icon: const Icon(Icons.cloud_download),
          label: const Text('Tải dữ liệu offline'),
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
                const Text(
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
                    Text(
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
                Text(
                  '${examProvider.preCacheProgress}% hoàn thành',
                  style: const TextStyle(fontSize: 12),
                ),
                
                if (examProvider.preCacheTotalSemesters > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Học kỳ: ${examProvider.preCacheCurrentSemester}/${examProvider.preCacheTotalSemesters}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                
                if (examProvider.isPreCaching) ...[
                  const SizedBox(height: 8),
                  Text(
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
