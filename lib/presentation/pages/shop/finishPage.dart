import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Finishpage extends StatelessWidget {
  final int totalPrice;

  const Finishpage({
    super.key,
    required this.totalPrice,
  });

  String formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '주문완료',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              '결제가 완료되었습니다.\n이용해주셔서 감사합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                minimumSize: const Size(240, 50),
              ),
              child: const Text(
                '펫모먼트 바로가기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '결제정보',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                _buildPaymentInfoRow('결제방법', '카카오페이'),
                const Divider(height: 1),
                _buildPaymentInfoRow('상품금액', formatCurrency(totalPrice - 3000)),
                const Divider(height: 1),
                _buildPaymentInfoRow('배송비', formatCurrency(3000)),
                const Divider(height: 1),
                _buildPaymentInfoRow('결제금액', formatCurrency(totalPrice),
                    isTotal: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFFE94A39) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
