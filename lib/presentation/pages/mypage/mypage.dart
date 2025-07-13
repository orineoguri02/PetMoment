import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:pet_moment/presentation/pages/login/SNSLogin/login.dart';
import 'package:pet_moment/presentation/pages/mypage/Privacy.dart';
import 'package:pet_moment/presentation/pages/mypage/account/Myaccount.dart';
import 'package:pet_moment/presentation/pages/shop/shoppingPage.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? name;
  String? email;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            name = userDoc.data()?['nickname'] ?? 'Anonymous';
            email = userDoc.data()?['email'] ?? 'Anonymous';
            imageUrl = userDoc.data()?['profileImageUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Failed to fetch user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildProfileCard(context),
            const SizedBox(height: 10),
            _buildMenuList(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // 프로필 이미지
              _buildProfileImage(),
              const SizedBox(width: 10),
              // 이름, 이메일 텍스트를 Flexible로 감싸서 공간 내에서 표시
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Loading...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17.34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email ?? 'Loading...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17.34,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Divider(
          color: Color(0XFFBEBEBE),
          thickness: 1,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return ClipOval(
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => Image.asset(
                'assets/default_profile.jpg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
            )
          : Image.asset(
              'assets/PetMoment.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Column(
      children: [
        _MenuItem(
          icon: Icons.person_outline,
          text: '계정설정',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Myaccount(),
              ),
            );

            if (result == true) {
              _fetchUserData();
            }
          },
        ),
        _MenuItem(
          icon: Icons.photo_album_outlined,
          text: '포토북 주문하기',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShoppingPage(),
              ),
            );
          },
        ),
        // _MenuItem(
        //   icon: Icons.notifications_none,
        //   text: '알림설정',
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => const NotificationPage(),
        //       ),
        //     );
        //   },
        // ),
        _MenuItem(
          icon: Icons.security,
          text: '개인정보 보호',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyPage(),
              ),
            );
          },
        ),
        // _MenuItem(
        //   icon: Icons.headset_mic_outlined,
        //   text: '문의하기',
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => const SupportPage(),
        //       ),
        //     );
        //   },
        // ),
        const SizedBox(height: 10),
        const Divider(
          color: Color(0XFFBEBEBE),
          thickness: 1,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  /// 푸터 영역 (버전 정보 및 로그아웃)
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('버전', style: TextStyle(color: Colors.grey)),
              Text('1.0.1', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            showCustomSnackbar(context, "로그아웃되었습니다!");
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(width: 8),
                Text(
                  "로그아웃",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Pretendard Variable",
                    color: Color(0XFF5E5E5E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      trailing: trailing,
      onTap: onTap ?? () {},
    );
  }
}
