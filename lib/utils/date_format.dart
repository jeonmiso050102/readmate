/// 11월 16일 (월)
String formatKoreanDate(DateTime d) {
  const week = ['월', '화', '수', '목', '금', '토', '일'];
  return '${d.month}월 ${d.day}일 (${week[d.weekday - 1]})';
}
