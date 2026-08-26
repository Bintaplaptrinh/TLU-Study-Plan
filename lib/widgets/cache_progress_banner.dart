import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

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
        if (!examProvider.isPreCaching && examProvider.preCacheProgress == 100 && !_wasCompleted) {
          _wasCompleted = true;
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
                            TrText(
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
                            TrText(
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
                      TrText(
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
                    TrText(
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
                    const TrText(
                      'Ứng dụng có thể hoạt động hoàn toàn offline',
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

class ResumeCachingButton extends StatelessWidget {
  const ResumeCachingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        if (examProvider.isPreCaching || examProvider.preCacheProgress >= 100) {
          return const SizedBox.shrink();
        }

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
