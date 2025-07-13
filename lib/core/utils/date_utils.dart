import 'package:intl/intl.dart';

class DateUtils {
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultTimeFormat = 'HH:mm:ss';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String koreanDateFormat = 'yyyy년 MM월 dd일';
  static const String koreanDateTimeFormat = 'yyyy년 MM월 dd일 HH시 mm분';
  
  // 날짜 포맷팅
  static String formatDate(DateTime date, {String format = defaultDateFormat}) {
    return DateFormat(format).format(date);
  }
  
  static String formatTime(DateTime date, {String format = defaultTimeFormat}) {
    return DateFormat(format).format(date);
  }
  
  static String formatDateTime(DateTime date, {String format = defaultDateTimeFormat}) {
    return DateFormat(format).format(date);
  }
  
  // 한국어 날짜 포맷팅
  static String formatKoreanDate(DateTime date) {
    return DateFormat(koreanDateFormat).format(date);
  }
  
  static String formatKoreanDateTime(DateTime date) {
    return DateFormat(koreanDateTimeFormat).format(date);
  }
  
  // 상대적 시간 표시
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
  
  // 날짜 범위 검증
  static bool isDateInRange(DateTime date, DateTime startDate, DateTime endDate) {
    return date.isAfter(startDate) && date.isBefore(endDate);
  }
  
  // 나이 계산
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  // 날짜 문자열 파싱
  static DateTime? parseDate(String dateString, {String format = defaultDateFormat}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  // 오늘 날짜 확인
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // 어제 날짜 확인
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }
  
  // 이번 주 확인
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  // 이번 달 확인
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  // 날짜 차이 계산
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
} 