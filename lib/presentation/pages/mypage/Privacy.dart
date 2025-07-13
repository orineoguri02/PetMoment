import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '개인정보 처리방침',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: '1. 개인정보의 수집 및 이용 목적'),
            SectionContent(content: '''
'펫모먼트'는 다음과 같은 목적으로 개인정보를 수집 및 이용합니다:
- 서비스 제공: 반려동물 사진 및 기록 저장, 앨범 기능, 채팅 시뮬레이션 서비스 제공
- 사용자 인증: 계정 생성 및 로그인
- 고객 지원: 문의사항 응대 및 문제 해결
- 데이터 분석: 서비스 개선 및 개인화된 추천
'''),
            SectionTitle(title: '2. 수집하는 개인정보의 항목'),
            SectionContent(content: '''
앱 사용 중 아래의 정보를 수집할 수 있습니다:
- 필수정보: 이름, 이메일 주소, 비밀번호
- 선택정보: 반려동물 이름, 반려동물 사진
- 자동 수집 정보: 기기 정보, IP 주소, 서비스 이용 기록
'''),
            SectionTitle(title: '3. 개인정보의 보유 및 이용 기간'),
            SectionContent(content: '''
- 사용자가 서비스를 이용하는 동안 개인정보를 보유합니다.
- 회원 탈퇴 시, 또는 수집 목적이 달성된 경우 즉시 삭제합니다.
- 단, 법적 요구사항에 따라 일정 기간 보관할 수 있습니다.
'''),
            SectionTitle(title: '4. 개인정보의 제3자 제공'),
            SectionContent(content: '''
'펫모먼트'는 원칙적으로 사용자의 개인정보를 외부에 제공하지 않습니다. 
단, 법령에 따라 요구되는 경우에 한하여 제공할 수 있습니다.
'''),
            SectionTitle(title: '5. 개인정보 처리 위탁'),
            SectionContent(content: '''
서비스 운영을 위해 아래와 같은 업무를 외부 업체에 위탁할 수 있습니다:
- 데이터 저장: [firebase]
'''),
            SectionTitle(title: '6. 사용자의 권리 및 행사 방법'),
            SectionContent(content: '''
- 사용자는 언제든지 자신의 개인정보를 열람, 수정, 삭제, 처리 정지 요청할 수 있습니다.
- 앱 내 설정 메뉴 또는 고객센터를 통해 요청하실 수 있습니다.
'''),
            SectionTitle(title: '7. 개인정보의 보호 조치'),
            SectionContent(content: '''
- 데이터 암호화: 저장된 데이터를 안전하게 보호합니다.
- 접근 통제: 개인정보 접근을 최소화하고, 접근 권한이 부여된 인원에 대해 보안 교육을 실시합니다.
'''),
            SectionTitle(title: '8. 개인정보 문의처'),
            SectionContent(content: '''
개인정보와 관련된 문의사항은 아래로 연락 주십시오:
- 이메일: choegongi4@gmail.com

'''),
            SectionTitle(title: '9. 정책 변경에 따른 고지'),
            SectionContent(content: '''
개인정보처리방침이 변경되는 경우, 최소 7일 전에 앱 공지사항을 통해 알려드리겠습니다.
'''),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

class SectionContent extends StatelessWidget {
  final String content;
  const SectionContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}
