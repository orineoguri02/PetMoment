import 'package:flutter/material.dart';

class Agreep1Page extends StatelessWidget {
  const Agreep1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFFEA6759),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '휴대폰 본인 인증 서비스 이용약관 동의',
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
        child: const Column(
          children: [
            Text(
              '휴대폰 본인 인증 서비스 이용약관 동의\n\n'
              '제1조 목적\n\n'
              '본 약관은 펫모먼트의 휴대폰 본인 인증 서비스를 이용함에 있어 필요한 조건과 절차 및 권리와 의무에 대해 규정함을 목적으로 합니다.\n\n'
              '제2조 본인 인증 서비스의 제공\n\n'
              '1. 본 서비스는 [인증 기관명]의 본인 인증 시스템을 통해 제공됩니다.\n'
              '2. 사용자의 신원을 확인하기 위해 이름, 생년월일, 휴대폰 번호, 이동통신사 정보가 수집 및 인증기관으로 전달됩니다.\n'
              '3. 본 서비스는 신원 확인 외의 다른 목적으로 사용자의 정보를 이용하거나 저장하지 않습니다.\n\n'
              '제3조 개인정보 보호 및 이용\n\n'
              '4. 본인 인증 과정에서 제공된 개인정보는 펫모먼트의 개인정보 처리방침에 따라 안전하게 관리됩니다.\n'
              '5. 인증기관으로 제공된 개인정보는 법적 근거가 있는 경우를 제외하고 제3자에게 제공되지 않습니다.\n\n'
              '제4조 책임 제한\n\n'
              '6. 본인 인증 절차 도중 발생하는 기술적 오류는 펫모먼트 또는 인증기관의 정책에 따라 처리됩니다.\n'
              '7, 사용자의 부주의로 인해 발생한 손해는 서비스 제공자가 책임지지 않습니다.',
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
