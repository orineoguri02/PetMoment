import 'package:flutter/material.dart';

class Agreep2Page extends StatelessWidget {
  const Agreep2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFFEA6759),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '휴대폰 통신사 이용약관 동의',
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
              '휴대폰 통신사 이용약관 동의\n\n'
              '제1조 목적\n\n'
              '본 약관은 사용자가 이동통신사를 통해 본인 인증을 진행할 때 필요한 조건과 절차를 규정합니다.\n\n'
              '제2조 정보의 제공 및 활용\n\n'
              '1. 본 서비스는 사용자의 휴대폰 번호와 이동통신사 정보를 인증 기관에 제공하여 본인 확인을 진행합니다.\n'
              '2. 인증된 정보는 인증 절차 종료 후 즉시 삭제되며, 별도의 저장이나 다른 목적으로 사용되지 않습니다.\n\n'
              '제3조 이동통신사와의 연계\n\n'
              '3. 본 서비스는 [이동통신사 목록]과 협력하여 인증 서비스를 제공합니다.\n'
              '4. 이동통신사에서 제공한 정보의 정확성에 대한 책임은 해당 통신사에 있습니다.\n\n'
              '제4조 유의사항\n\n'
              '5. 통신사 정책에 따라 추가 인증이 요구될 수 있습니다.\n'
              '6. 사용자는 통신사 변경 시 본인 인증 절차를 다시 진행해야 할 수 있습니다.',
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
