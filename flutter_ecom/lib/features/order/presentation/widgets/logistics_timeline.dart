import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../domain/entities/logistics_entity.dart';

/// 物流时间线组件
///
/// 面试讲解点：
/// 自定义时间线 UI，使用 Column + Row 组合实现竖线 + 圆点布局。
/// 第一条（最新状态）高亮显示，其他条目灰色淡化。
class LogisticsTimeline extends StatelessWidget {
  const LogisticsTimeline({
    super.key,
    required this.updates,
  });

  final List<LogisticsUpdateEntity> updates;

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return const Text(
        '暂无物流信息',
        style: TextStyle(color: AppColors.textHint),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: updates.asMap().entries.map((entry) {
        final index = entry.key;
        final update = entry.value;
        final isFirst = index == 0;
        return _TimelineItem(
          time: update.time,
          content: update.content,
          isFirst: isFirst,
          isLast: index == updates.length - 1,
        );
      }).toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.content,
    required this.isFirst,
    required this.isLast,
  });

  final String time;
  final String content;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧时间线
        SizedBox(
          width: 24,
          child: Column(
            children: [
              // 圆点
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFirst ? AppColors.primary : AppColors.divider,
                  border: Border.all(
                    color: isFirst ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              // 竖线
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.divider,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.spacingS),
        // 右侧内容
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: AppDimens.fontXS,
                    color: isFirst
                        ? AppColors.textSecondary
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: AppDimens.fontS,
                    color: isFirst
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        isFirst ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
