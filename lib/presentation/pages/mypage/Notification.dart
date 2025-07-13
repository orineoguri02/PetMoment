import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _pushNotification = true;
  bool _nightPushNotification = false;
  bool _postLikeCommentNotification = true;
  bool _petMessageNotification = true;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // iOS 초기화 설정
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true, // 알림 권한 요청
      requestBadgePermission: true, // 배지 권한 요청
      requestSoundPermission: true, // 사운드 권한 요청
      defaultPresentAlert: true, // 포그라운드 알림 표시
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    // 알림 초기화 및 권한 요청
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('알림 응답: ${response.payload}');
        // 알림 클릭 시 처리할 로직
      },
    );

    // iOS 권한 명시적 요청
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('iOS 알림 권한 승인 상태: $granted');
  }

  Future<void> _showTestNotification() async {
    debugPrint('iOS 테스트 알림 호출됨');

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true, // 알림 표시
      presentBadge: true, // 앱 아이콘에 배지 표시
      presentSound: true, // 알림음 재생
      sound: 'default', // 기본 알림음 사용
      badgeNumber: 1, // 배지 숫자
      threadIdentifier: 'thread_id', // 알림 그룹화를 위한 스레드 ID
      interruptionLevel: InterruptionLevel.active, // 알림 중요도
      subtitle: '알림 부제목', // 부제목 (선택사항)
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      iOS: iOSDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        0, // 알림 ID
        '테스트 알림', // 제목
        '이것은 iOS 테스트 알림입니다.', // 내용
        platformChannelSpecifics,
        payload: 'item x', // 알림과 함께 전달할 데이터
      );
      debugPrint('iOS 알림 전송 성공');
    } catch (e) {
      debugPrint('iOS 알림 전송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '알림설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
        ),
      ),
      child: ListView(
        children: [
          _buildNotificationToggle(
            title: '푸시 알림',
            value: _pushNotification,
            onChanged: (value) {
              setState(() {
                _pushNotification = value;
              });
              if (value) {
                _showTestNotification();
              }
            },
          ),
          _buildNotificationToggle(
            title: '야간 푸시 알림 (21~08시)',
            value: _nightPushNotification,
            onChanged: (value) {
              setState(() {
                _nightPushNotification = value;
              });
            },
          ),
          _buildNotificationToggle(
            title: '게시글 좋아요 댓글 알림',
            value: _postLikeCommentNotification,
            onChanged: (value) {
              setState(() {
                _postLikeCommentNotification = value;
              });
            },
          ),
          _buildNotificationToggle(
            title: '반려동물 편지 발송 알림',
            value: _petMessageNotification,
            onChanged: (value) {
              setState(() {
                _petMessageNotification = value;
              });
            },
          ),
          const SizedBox(height: 30),
          Center(
            child: CupertinoButton.filled(
              onPressed: _showTestNotification,
              child: const Text('테스트 알림 보내기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeColor: CupertinoColors.systemRed,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFECECEC)),
      ],
    );
  }
}
