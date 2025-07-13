import 'package:flutter/material.dart';

class Agreep3Page extends StatelessWidget {
  const Agreep3Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFFEA6759),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '개인정보 제공 및 이용동의',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '개인정보 제공 및 이용동의\n\n'
              '제1조 목적\n\n'
              '본 약관은 사용자의 고유식별정보를 처리하는 목적과 방법, 보호 조치에 대해 규정합니다.\n\n'
              '제2조 수집 항목\n\n'
              '1. 이름, 생년월일, 휴대폰 번호, 통신사 정보\n'
              '2. 본 서비스 이용과 관련된 로그 및 IP 정보\n\n'
              '제3조 수집 목적\n\n'
              '3. 본인 확인 및 계정 생성\n'
              '4. 비밀번호 설정 및 서비스 제공\n'
              '5. 고객 상담 및 불만 처리\n'
              '6. 법적 의무 이행\n\n'
              '제4조 보유 기간\n\n'
              '7. 개인정보는 수집 및 이용 목적 달성 후 즉시 파기됩니다.\n'
              '8. 법령에 따라 보존해야 하는 경우, 해당 기간 동안 안전하게 저장됩니다.\n\n'
              '제5조 동의 철회\n\n'
              '사용자는 개인정보 제공 동의를 철회할 수 있으며, 철회 시 펫모먼트 서비스 이용이 일부 제한될 수 있습니다.',
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
