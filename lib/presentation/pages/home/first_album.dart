import 'package:flutter/material.dart';
import 'package:pet_moment/presentation/pages/home/create_album.dart';

class FirstAlbum extends StatelessWidget {
  const FirstAlbum({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAlbumPage(),
            ),
          );
        },
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('앨범 생성하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 14),
                const Text('기록할 앨범을 생성해주세요!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 4,
                          offset: const Offset(-5, 0),
                        )
                      ]),
                  child: Image.asset('assets/firstAlbum.png'),
                ),
                const SizedBox(height: 34),
                const Text('앨범 추가하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
