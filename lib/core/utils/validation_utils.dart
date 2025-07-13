class ValidationUtils {
  // 이메일 형식 검증
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
  
  // 패스워드 강도 검증
  static bool isValidPassword(String password) {
    // 최소 8자, 대문자, 소문자, 숫자, 특수문자 포함
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }
  
  // 간단한 패스워드 검증 (기존 앱 호환성)
  static bool isSimpleValidPassword(String password) {
    return password.length >= 6;
  }
  
  // 휴대폰 번호 검증
  static bool isValidPhoneNumber(String phone) {
    // 한국 휴대폰 번호 형식
    return RegExp(r'^010-?[0-9]{4}-?[0-9]{4}$').hasMatch(phone);
  }
  
  // 닉네임 검증
  static bool isValidNickname(String nickname) {
    // 2-20자, 한글, 영문, 숫자만 허용
    return RegExp(r'^[가-힣a-zA-Z0-9]{2,20}$').hasMatch(nickname);
  }
  
  // 빈 문자열 검증
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
  
  // 문자열 길이 검증
  static bool isLengthValid(String value, int minLength, int maxLength) {
    return value.length >= minLength && value.length <= maxLength;
  }
  
  // 숫자만 포함하는지 검증
  static bool isNumericOnly(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value);
  }
  
  // 영문자만 포함하는지 검증
  static bool isAlphabetOnly(String value) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(value);
  }
  
  // 한글만 포함하는지 검증
  static bool isKoreanOnly(String value) {
    return RegExp(r'^[가-힣]+$').hasMatch(value);
  }
  
  // URL 형식 검증
  static bool isValidUrl(String url) {
    return RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$')
        .hasMatch(url);
  }
  
  // 생년월일 검증
  static bool isValidBirthDate(String birthDate) {
    try {
      final date = DateTime.parse(birthDate);
      final now = DateTime.now();
      
      // 미래 날짜 불가, 150세 이상 불가
      return date.isBefore(now) && 
             date.isAfter(now.subtract(const Duration(days: 365 * 150)));
    } catch (e) {
      return false;
    }
  }
  
  // 특수문자 포함 검증
  static bool containsSpecialCharacters(String value) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
  }
  
  // 공백 포함 검증
  static bool containsWhitespace(String value) {
    return RegExp(r'\s').hasMatch(value);
  }
  
  // 패스워드 확인 검증
  static bool isPasswordMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
  
  // 이메일 도메인 검증
  static bool isValidEmailDomain(String email, List<String> allowedDomains) {
    if (!isValidEmail(email)) return false;
    
    final domain = email.split('@').last;
    return allowedDomains.contains(domain);
  }
  
  // 파일 확장자 검증
  static bool isValidFileExtension(String filename, List<String> allowedExtensions) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }
  
  // 이미지 파일 검증
  static bool isValidImageFile(String filename) {
    return isValidFileExtension(filename, ['jpg', 'jpeg', 'png', 'gif', 'webp']);
  }
  
  // 동영상 파일 검증
  static bool isValidVideoFile(String filename) {
    return isValidFileExtension(filename, ['mp4', 'avi', 'mov', 'mkv', 'wmv']);
  }
  
  // 파일 크기 검증 (바이트 단위)
  static bool isValidFileSize(int fileSize, int maxSizeInBytes) {
    return fileSize <= maxSizeInBytes;
  }
  
  // 나이 범위 검증
  static bool isValidAge(int age, int minAge, int maxAge) {
    return age >= minAge && age <= maxAge;
  }
} 