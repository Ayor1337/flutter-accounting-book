import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';

class DailyExpenseChart extends StatelessWidget {
  final String month;
  final Map<String, double> dailyData;

  const DailyExpenseChart({
    super.key,
    required this.month,
    required this.dailyData,
  });

  @override
  Widget build(BuildContext context) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final mon = int.parse(parts[1]);
    final daysInMonth = DateTime(year, mon + 1, 0).day;

    final hasData = dailyData.values.any((v) => v > 0);

    if (!hasData) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            '本月暂无支出数据',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    double maxY = 0;
    for (var i = 1; i <= daysInMonth; i++) {
      final dateStr = '$month-${i.toString().padLeft(2, '0')}';
      final v = dailyData[dateStr] ?? 0.0;
      if (v > maxY) maxY = v;
    }
    maxY = maxY * 1.2;

    final primaryColor = Theme.of(context).colorScheme.primary;

    final barGroups = List.generate(daysInMonth, (i) {
      final day = i + 1;
      final dateStr = '$month-${day.toString().padLeft(2, '0')}';
      final amount = dailyData[dateStr] ?? 0.0;
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: amount > 0 ? primaryColor : Colors.grey.withAlpha(51),
            width: daysInMonth > 28 ? 5 : 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    });

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withAlpha(51),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  // 每5天一个标签：1, 5, 10, 15, 20, 25
                  if (day == 1 || day % 5 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$day',
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const Text('0', style: TextStyle(fontSize: 9));
                  }
                  return Text(
                    _shortAmount(value),
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey.withAlpha(204),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rod.toY <= 0) return null;
                return BarTooltipItem(
                  '${group.x}日\n${formatAmount(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _shortAmount(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}w';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
