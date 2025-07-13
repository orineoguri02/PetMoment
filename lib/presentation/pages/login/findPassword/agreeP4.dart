import 'package:flutter/material.dart';

class Agreep4Page extends StatelessWidget {
  const Agreep4Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFFEA6759),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '고유식별정보 처리 동의',
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
              '고유식별정보 처리 동의\n\n'
              '제1조 목적\n\n'
              '본 약관은 사용자의 고유식별정보를 처리하는 목적과 방법, 보호 조치에 대해 규정합니다.\n\n'
              '제2조 수집 항목\n\n'
              '1.주민등록번호, 여권번호, 운전면허번호 등 법적으로 고유하게 부여된 식별 정보\n\n'
              '제3조 처리 목적\n\n'
              '2. 본인 확인 및 인증 절차 수행\n'
              '3. 법적 요구사항 준수\n\n'
              '제4조 보유 및 이용 기간\n\n'
              '4. 수집된 고유식별정보는 본 목적이 달성되거나 법적 보존 기간이 경과한 후 즉시 파기됩니다.\n'
              '5. 정보 파기 시 안전한 절차를 통해 삭제되며, 재생이 불가능하도록 처리됩니다.\n\n'
              '제5조 보호 조치\n\n'
              '6. 고유식별정보는 암호화 및 접근 통제를 통해 안전하게 관리됩니다.\n'
              '7. 정보 유출 또는 오용 방지를 위한 기술적, 관리적 보호 조치를 시행합니다.',
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
