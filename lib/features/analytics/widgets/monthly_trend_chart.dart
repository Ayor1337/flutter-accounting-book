import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';

class MonthlyTrendChart extends StatelessWidget {
  final List<String> months;
  final Map<String, ({double income, double expense})> totals;

  const MonthlyTrendChart({
    super.key,
    required this.months,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final incomeSpots = months.asMap().entries.map((e) {
      final v = totals[e.value]?.income ?? 0.0;
      return FlSpot(e.key.toDouble(), v);
    }).toList();

    final expenseSpots = months.asMap().entries.map((e) {
      final v = totals[e.value]?.expense ?? 0.0;
      return FlSpot(e.key.toDouble(), v);
    }).toList();

    // 计算 Y 轴最大值
    double maxY = 0;
    for (final m in months) {
      final t = totals[m];
      if (t != null) {
        if (t.income > maxY) maxY = t.income;
        if (t.expense > maxY) maxY = t.expense;
      }
    }
    // 预留顶部空间
    maxY = maxY <= 0 ? 100 : maxY * 1.2;

    return Column(
      children: [
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.green, label: '收入'),
            const SizedBox(width: 20),
            _LegendDot(color: Colors.red, label: '支出'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
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
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      final parts = months[idx].split('-');
                      final label = '${int.parse(parts[1])}月';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(label,
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const Text('0',
                            style: TextStyle(fontSize: 9));
                      }
                      return Text(
                        _shortAmount(value),
                        style: const TextStyle(fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) =>
                      Colors.blueGrey.withAlpha(204),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIncome ? '收入' : '支出'}: ${formatAmount(spot.y)}',
                        TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // 收入线
                LineChartBarData(
                  spots: incomeSpots,
                  color: Colors.green,
                  isCurved: true,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: Colors.green,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withAlpha(26),
                  ),
                ),
                // 支出线
                LineChartBarData(
                  spots: expenseSpots,
                  color: Colors.red,
                  isCurved: true,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: Colors.red,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withAlpha(26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 金额简化显示（如 1200 → "1.2k"）
  String _shortAmount(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}w';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
