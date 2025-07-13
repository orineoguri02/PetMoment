import 'package:flutter/material.dart';

import 'signup.dart';

class AgreeScreen extends StatefulWidget {
  const AgreeScreen({super.key});

  @override
  State<AgreeScreen> createState() => _AgreeScreenState();
}

class _AgreeScreenState extends State<AgreeScreen> {
  List<bool> _isChecked = List.generate(5, (_) => false);

  bool get _buttonActive => _isChecked[1] && _isChecked[2] && _isChecked[3];

  void _updateCheckState(int index) {
    setState(() {
      // 모두 동의 체크박스일 경우
      if (index == 0) {
        bool isAllChecked = !_isChecked.every((element) => element);
        _isChecked = List.generate(5, (index) => isAllChecked);
      } else {
        _isChecked[index] = !_isChecked[index];
        _isChecked[0] = _isChecked.getRange(1, 5).every((element) => element);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        title: const Text('계정 만들기',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이용약관에 \n동의해 주세요',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFFE94A39))),
            const SizedBox(height: 30),
            ..._renderCheckList(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonActive
                              ? Color(0XFFE94A39)
                              : Color(0XFFEC766A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        onPressed: _buttonActive
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpPage(),
                                  ),
                                );
                              }
                            : null,
                        child: const Text(
                          '다음으로',
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _renderCheckList() {
    List<String> labels = [
      '전체 약관 동의(선택항목 포함)',
      '[필수] 이용약관 동의',
      '[필수] 개인정보처리방침 동의',
      '[필수] 만 14세 이상입니다.',
      '[선택] 마케팅 활용 동의',
    ];

    List<Widget> list = [
      renderContainer(_isChecked[0], labels[0], () => _updateCheckState(0)),
      const Divider(
        thickness: 1.0,
        color: Colors.black,
      ),
    ];

    list.addAll(List.generate(
        4,
        (index) => renderContainer(_isChecked[index + 1], labels[index + 1],
            () => _updateCheckState(index + 1))));

    return list;
  }

  Widget renderContainer(bool checked, String text, VoidCallback onTap) {
    bool isAllAgree = text == '전체 약관 동의(선택항목 포함)';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: checked ? Color(0XFFE94A39) : Colors.grey,
                    width: 2.0),
                color: checked ? Color(0XFFE94A39) : Colors.white,
              ),
              child: Icon(Icons.check,
                  color: checked ? Colors.white : Colors.grey, size: 18),
            ),
            const SizedBox(width: 15),
            Text(text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isAllAgree ? 20 : 18,
                  fontWeight: isAllAgree ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
