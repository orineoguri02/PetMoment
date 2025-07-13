import 'package:flutter/material.dart';

class PdfDialog extends StatefulWidget {
  final Future<String> Function() generatePdf;
  const PdfDialog({Key? key, required this.generatePdf}) : super(key: key);

  @override
  _PdfDialogState createState() => _PdfDialogState();
}

class _PdfDialogState extends State<PdfDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/real.png'),
          Positioned(
            bottom: -4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Color(0XFFE94A39),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 100),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final url = await widget.generatePdf();
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset('assets/ready.png'),
                                      Positioned(
                                        bottom: -4,
                                        child: TextButton(
                                          child: const Text(
                                            '닫기',
                                            style: TextStyle(
                                              color: Color(0XFFE94A39),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('PDF 생성 실패: ${e.toString()}')),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0XFFE94A39)),
                          ),
                        )
                      : const Text(
                          '확인',
                          style: TextStyle(
                            color: Color(0XFFE94A39),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
