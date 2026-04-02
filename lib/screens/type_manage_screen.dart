import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/meditation_type.dart';
import '../providers/meditation_provider.dart';
import '../widgets/glassmorphic_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TypeManageScreen extends StatelessWidget {
  const TypeManageScreen({Key? key}) : super(key: key);

  void _showAddEditDialog(BuildContext context, {MeditationType? existingType}) {
    final nameController = TextEditingController(text: existingType?.name ?? '');
    String selectedColor = existingType?.colorCode ?? '#00FFC8';

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
                      existingType == null ? '新建冥想类型' : '编辑冥想类型',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    // 名称输入
                    TextField(
                      controller: nameController,
                      style: AppTypography.bodyLarge,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '输入类型名称',
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textTertiary,
                        ),
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
                    const SizedBox(height: 24),
                    Text('选择颜色', style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    // 颜色选择网格
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: AppColors.typePalette.map((hex) {
                        final color = _parseHex(hex);
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20)
                                : null,
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
                              if (nameController.text.trim().isEmpty) return;
                              final provider =
                                  context.read<MeditationProvider>();
                              if (existingType == null) {
                                provider.addType(MeditationType(
                                  id: const Uuid().v4(),
                                  name: nameController.text.trim(),
                                  colorCode: selectedColor,
                                ));
                              } else {
                                existingType.name = nameController.text.trim();
                                existingType.colorCode = selectedColor;
                                provider.updateType(existingType);
                              }
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
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
                      Text('冥想类型', style: AppTypography.headlineLarge),
                      const SizedBox(height: 4),
                      Text('管理你的冥想方式', style: AppTypography.bodyMedium),
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

            // ─── 类型列表 ───
            Expanded(
              child: Consumer<MeditationProvider>(
                builder: (context, provider, child) {
                  if (provider.types.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: provider.types.length,
                    itemBuilder: (context, index) {
                      final type = provider.types[index];
                      return _buildTypeCard(context, type, provider);
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

  Widget _buildTypeCard(
      BuildContext context, MeditationType type, MeditationProvider provider) {
    final color = _parseHex(type.colorCode);

    return Dismissible(
      key: ValueKey(type.id),
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
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface1,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
            title: Text('删除确认', style: AppTypography.headlineSmall),
            content: Text('确定要删除 "${type.name}" 吗？',
                style: AppTypography.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('取消',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('删除',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteType(type.id),
      child: GlassmorphicCard(
        margin: const EdgeInsets.only(bottom: 12),
        borderColor: color.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 色块圆形
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.self_improvement_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // 名称
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.name, style: AppTypography.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    '左滑删除',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // 编辑按钮
            GestureDetector(
              onTap: () => _showAddEditDialog(context, existingType: type),
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
              Icons.palette_outlined,
              color: AppColors.primary.withOpacity(0.4),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text('还没有冥想类型', style: AppTypography.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 创建你的第一个冥想类型',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
