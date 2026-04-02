import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/meditation_record.dart';
import '../models/meditation_type.dart';
import '../providers/meditation_provider.dart';
import '../widgets/glassmorphic_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RecordManageScreen extends StatefulWidget {
  const RecordManageScreen({Key? key}) : super(key: key);

  @override
  State<RecordManageScreen> createState() => _RecordManageScreenState();
}

class _RecordManageScreenState extends State<RecordManageScreen> {
  void _showAddEditDialog(BuildContext context, {MeditationRecord? existingRecord}) {
    final provider = context.read<MeditationProvider>();
    if (provider.types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加至少一种冥想类型')),
      );
      return;
    }

    DateTime selectedDate = existingRecord?.startTime ?? DateTime.now();
    TimeOfDay selectedTime = existingRecord != null
        ? TimeOfDay.fromDateTime(existingRecord.startTime)
        : TimeOfDay.now();
    
    final int initialMinutes = existingRecord != null
        ? existingRecord.durationSeconds ~/ 60
        : 10;
        
    final durationController = TextEditingController(text: initialMinutes.toString());
    String selectedTypeId = existingRecord?.typeId ?? provider.types.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 拖拽条
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      existingRecord == null ? '添加冥想记录' : '编辑冥想记录',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: 24),

                    // 选择日期和时间
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface2.withOpacity(0.5),
                                borderRadius: AppRadius.mdBorder,
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                style: AppTypography.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setState(() => selectedTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface2.withOpacity(0.5),
                                borderRadius: AppRadius.mdBorder,
                              ),
                              child: Text(
                                selectedTime.format(context),
                                style: AppTypography.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 输入时长
                    TextField(
                      controller: durationController,
                      style: AppTypography.bodyLarge,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: '冥想时长 (分钟)',
                        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surface2.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorder,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorder,
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 选择类型
                    Text('冥想类型', style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.types.map((type) {
                        final isSelected = selectedTypeId == type.id;
                        final color = _parseHex(type.colorCode);
                        return GestureDetector(
                          onTap: () => setState(() => selectedTypeId = type.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.2) : AppColors.surface2.withOpacity(0.5),
                              borderRadius: AppRadius.pillBorder,
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              type.name,
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected ? color : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                                side: BorderSide(
                                  color: AppColors.textTertiary.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Text(
                              '取消',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextButton(
                            onPressed: () {
                              if (durationController.text.trim().isEmpty) return;
                              final mins = int.tryParse(durationController.text.trim()) ?? 0;
                              if (mins <= 0) return;

                              final finalStartTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                              final finalEndTime = finalStartTime.add(Duration(minutes: mins));

                              if (existingRecord == null) {
                                provider.addRecord(MeditationRecord(
                                  id: const Uuid().v4(),
                                  startTime: finalStartTime,
                                  endTime: finalEndTime,
                                  durationSeconds: mins * 60,
                                  typeId: selectedTypeId,
                                ));
                              } else {
                                final oldStartTime = existingRecord.startTime;
                                provider.updateRecord(
                                  MeditationRecord(
                                    id: existingRecord.id,
                                    startTime: finalStartTime,
                                    endTime: finalEndTime,
                                    durationSeconds: mins * 60,
                                    typeId: selectedTypeId,
                                    musicUsed: existingRecord.musicUsed,
                                  ),
                                  oldStartTime: oldStartTime,
                                );
                              }
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Text(
                              '保存',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Color _parseHex(String hex) {
    try {
      if (hex.startsWith('#')) {
        return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 标题区 ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('冥想记录', style: AppTypography.headlineLarge),
                      const SizedBox(height: 4),
                      Text('管理你的历史数据', style: AppTypography.bodyMedium),
                    ],
                  ),
                  // 新增按钮
                  GestureDetector(
                    onTap: () => _showAddEditDialog(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── 记录列表 ───
            Expanded(
              child: Consumer<MeditationProvider>(
                builder: (context, provider, child) {
                  if (provider.records.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: provider.records.length,
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      MeditationType? type;
                      try {
                        type = provider.types.firstWhere((t) => t.id == record.typeId);
                      } catch (_) {}

                      return _buildRecordCard(context, record, type, provider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(
      BuildContext context, MeditationRecord record, MeditationType? type, MeditationProvider provider) {
    final color = type != null ? _parseHex(type.colorCode) : AppColors.primary;
    final mins = record.durationSeconds ~/ 60;
    
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface1,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
            title: Text('删除确认', style: AppTypography.headlineSmall),
            content: Text('确定要删除这条${mins}分钟的冥想记录吗？',
                style: AppTypography.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('取消', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('删除', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteRecord(record.id),
      child: GlassmorphicCard(
        margin: const EdgeInsets.only(bottom: 12),
        borderColor: color.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 日期/时间展示
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface2.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MM/dd').format(record.startTime),
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm').format(record.startTime),
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // 名称时长
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type?.name ?? '未知类型', style: AppTypography.titleMedium.copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(
                    '$mins 分钟',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            // 编辑按钮
            GestureDetector(
              onTap: () => _showAddEditDialog(context, existingRecord: record),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface2.withOpacity(0.5),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.list_alt_rounded,
              color: AppColors.primary.withOpacity(0.4),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text('暂无记录', style: AppTypography.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 补录或是进行一次冥想',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
