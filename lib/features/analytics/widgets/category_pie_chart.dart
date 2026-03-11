import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<int, double> expenseMap;
  final List<Category> categories;

  const CategoryPieChart({
    super.key,
    required this.expenseMap,
    required this.categories,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.expenseMap.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '本月暂无支出数据',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    final total =
        widget.expenseMap.values.fold(0.0, (sum, v) => sum + v);

    // 按金额降序排列，确保图例和切片顺序一致
    final sortedEntries = widget.expenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.asMap().entries.map((indexedEntry) {
      final i = indexedEntry.key;
      final entry = indexedEntry.value;
      final cat = widget.categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: entry.key,
          name: '未知',
          icon: '?',
          color: 0xFF9E9E9E,
          type: 'expense',
          isDefault: false,
        ),
      );
      final percent = entry.value / total * 100;
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;

      return PieChartSectionData(
        color: Color(cat.color),
        value: entry.value,
        title: '${percent.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: isTouched
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  formatAmount(entry.value),
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(cat.color),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 44,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('支出',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    formatAmount(total),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 图例
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: sortedEntries.map((entry) {
            final cat = widget.categories.firstWhere(
              (c) => c.id == entry.key,
              orElse: () => Category(
                id: entry.key,
                name: '未知',
                icon: '?',
                color: 0xFF9E9E9E,
                type: 'expense',
                isDefault: false,
              ),
            );
            final percent = entry.value / total * 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(cat.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${cat.icon} ${cat.name}  ${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
