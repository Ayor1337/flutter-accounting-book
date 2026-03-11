const _weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

// 'YYYY-MM' → '2024年1月'
String formatMonth(String month) {
  final parts = month.split('-');
  return '${parts[0]}年${int.parse(parts[1])}月';
}

// DateTime → '3月11日 周三'
String formatDate(DateTime date) {
  return '${date.month}月${date.day}日 ${_weekdays[date.weekday]}';
}

// 月份第一天 00:00:00
DateTime monthStart(String month) {
  final parts = month.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
}

// 月份最后一天（下月第一天减1毫秒）
DateTime monthEnd(String month) {
  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final mon = int.parse(parts[1]);
  return DateTime(year, mon + 1, 1).subtract(const Duration(milliseconds: 1));
}

// 当前月份 'YYYY-MM'
String currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

// 上个月
String previousMonth(String month) {
  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final mon = int.parse(parts[1]);
  final prev = DateTime(year, mon - 1, 1);
  return '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
}

// 下个月
String nextMonth(String month) {
  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final mon = int.parse(parts[1]);
  final next = DateTime(year, mon + 1, 1);
  return '${next.year}-${next.month.toString().padLeft(2, '0')}';
}
