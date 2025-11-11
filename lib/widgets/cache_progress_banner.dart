import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';

/// Banner widget that shows pre-caching progress
/// Displayed at the top of the screen when caching is in progress
class CacheProgressBanner extends StatefulWidget {
  const CacheProgressBanner({Key? key}) : super(key: key);

  @override
  State<CacheProgressBanner> createState() => _CacheProgressBannerState();
}

class _CacheProgressBannerState extends State<CacheProgressBanner> {
  bool _wasCompleted = false;
  bool _shouldHide = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        // Check if caching just completed
        if (!examProvider.isPreCaching && examProvider.preCacheProgress == 100 && !_wasCompleted) {
          _wasCompleted = true;
          // Auto-hide after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _shouldHide = true;
              });
            }
          });
        }

        // Reset if caching starts again
        if (examProvider.isPreCaching && _wasCompleted) {
          _wasCompleted = false;
          _shouldHide = false;
        }

        // Don't show if not currently pre-caching and not showing completion message
        if (!examProvider.isPreCaching && (examProvider.preCacheProgress != 100 || _shouldHide)) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 4,
          color: Theme.of(context).primaryColor.withOpacity(0.95),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (examProvider.isPreCaching)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const AppIcon(
                          symbol: AppIcons.checkCircle,
                          color: Colors.white,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              examProvider.isPreCaching 
                                  ? 'Đang tải dữ liệu offline...'
                                  : 'Hoàn tất!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              examProvider.preCacheStatus,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${examProvider.preCacheProgress}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: examProvider.preCacheProgress / 100,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  if (examProvider.preCacheTotalSemesters > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Học kỳ: ${examProvider.preCacheCurrentSemester}/${examProvider.preCacheTotalSemesters}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!examProvider.isPreCaching && examProvider.preCacheProgress == 100) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '✓ Ứng dụng có thể hoạt động hoàn toàn offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Floating action button to resume caching if interrupted
class ResumeCachingButton extends StatelessWidget {
  const ResumeCachingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        // Only show if NOT currently caching AND cache is incomplete
        if (examProvider.isPreCaching || examProvider.preCacheProgress >= 100) {
          return const SizedBox.shrink();
        }

        // Check if there's incomplete cache
        return FutureBuilder<bool>(
          future: examProvider.checkIncompletCache(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!) {
              return const SizedBox.shrink();
            }

            return AppFloatingButton(
              label: 'Tiếp tục tải dữ liệu',
              icon: AppIcons.downloadCloud,
              color: Colors.orange,
              onPressed: () async {
                // Resume caching
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                if (userProvider.accessToken != null && 
                    userProvider.selectedSemester != null) {
                  await examProvider.preCacheAllExamData(
                    userProvider.accessToken!,
                    userProvider.selectedSemester!.id,
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
