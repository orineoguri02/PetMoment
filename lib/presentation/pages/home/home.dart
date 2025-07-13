import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_moment/presentation/pages/home/album.dart';
import 'package:pet_moment/presentation/pages/home/create_album.dart';
import 'package:pet_moment/presentation/pages/home/first_album.dart';
import 'package:pet_moment/presentation/pages/mypage/mypage.dart';

class HomePage extends StatefulWidget {
  final bool isFromProfileCreation;
  final Map<String, dynamic>? newAlbumData;
  const HomePage(
      {super.key, this.isFromProfileCreation = false, this.newAlbumData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _imagePath;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  int _currentIndex = 0;
  final CarouselSliderController _carouselSliderController =
      CarouselSliderController();
  // 카메라 컨트롤러 관련 변수들은 필요에 따라 사용하세요.
  late CameraController _controller;
  bool _isRearCamera = true;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> _cameras = [];

  // 앨범 데이터를 위한 스트림
  Stream<QuerySnapshot>? _albumsStream;

  @override
  void initState() {
    super.initState();
    // 스트림 초기화
    _albumsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .snapshots();

    // 이미지 프리캐싱
    _precacheAlbumImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromProfileCreation) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const FirstAlbum(),
        );
      }
    });
  }

  /// 네이티브 카메라를 실행하여 촬영한 이미지 파일 경로를 반환합니다.
  Future<String?> openNativeCamera() async {
    const MethodChannel _channel = MethodChannel('com.example.camera');
    try {
      final String? filePath = await _channel.invokeMethod('openCamera');
      return filePath;
    } on PlatformException catch (e) {
      print("네이티브 카메라 실행 오류: ${e.message}");
      return null;
    }
  }

  Future<void> _openCamera() async {
    String? path = await openNativeCamera();
    if (path != null) {
      setState(() {
        _imagePath = path;
      });
    }
  }

  Future<void> _precacheAlbumImages() async {
    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('albums')
          .get();

      for (var doc in querySnapshot.docs) {
        final coverUrl = doc['coverImageUrl'] as String?;
        if (coverUrl != null &&
            coverUrl.isNotEmpty &&
            coverUrl.startsWith('http')) {
          precacheImage(NetworkImage(coverUrl), context);
        }
      }
    }
  }

  void _editAlbum(DocumentSnapshot album) {
    final albumData = album.data() as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateAlbumPage(isEditMode: true),
        settings: RouteSettings(
          arguments: {
            'albumId': album.id, // 문서 ID
            'animalName': albumData['animalName'] ?? '',
            'albumName': albumData['albumName'] ?? '',
            'birthDate': albumData['birthDate'] ?? '',
            'coverImageUrl': albumData['coverImageUrl'] ?? '',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/gradient.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _albumsStream,
              builder: (context, snapshot) {
                final albums = snapshot.data?.docs ?? [];

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildGuidebook(),
                      const SizedBox(height: 30),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        _buildLoadingIndicator()
                      else
                        _buildAlbumSection(albums),
                      const SizedBox(height: 26),
                      _buildRecordButton(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Row(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Pet Moment',
                style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0XFFE94A39)),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person,
                    color: Color(0XFFE94A39), size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidebook() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "가이드북",
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold),
          ),
          const Text(
            "소중한 반려동물의 순간들을 사진과 함께 기록하고,\n추억이 가득한 앨범으로 간직하세요!",
            style: TextStyle(
                fontSize: 13,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
                color: Color(0XFF8D8D8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.8,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAlbumSection(List<QueryDocumentSnapshot> albums) {
    return Column(
      children: [
        SizedBox(height: 15),
        _buildAlbumCarousel(albums),
        SizedBox(height: 18),
        _buildCarouselIndicator(albums.length + 1),
        SizedBox(height: 24),
        if (albums.isNotEmpty && _currentIndex < albums.length)
          _buildAlbumInfo(albums[_currentIndex])
        else
          _buildEmptyAlbumInfo(),
      ],
    );
  }

  Widget _buildAlbumCarousel(List<QueryDocumentSnapshot> albums) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth * 0.6;
    double itemHeight = itemWidth * (4 / 3);

    final items = [
      ...albums.map((album) => _buildAlbumItem(album)),
      _buildAddAlbumPage(),
    ];

    final itemCount = items.length;
    if (itemCount == 0) return const SizedBox();

    return Stack(
      alignment: Alignment.center,
      children: [
        CarouselSlider(
          key: const PageStorageKey('carousel-slider'),
          items: items,
          carouselController: _carouselSliderController,
          options: CarouselOptions(
            height: itemHeight,
            initialPage: _currentIndex.clamp(0, itemCount - 1),
            viewportFraction: 0.75,
            enlargeCenterPage: true,
            scrollPhysics: const PageScrollPhysics(),
            pageSnapping: true,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        if (_currentIndex > 0)
          Positioned(
            left: 6,
            child: IconButton(
              onPressed: () {
                _carouselSliderController.previousPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0XFFE94A39), width: 2),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0XFFE94A39),
                  size: 26,
                ),
              ),
            ),
          ),
        if (_currentIndex < itemCount - 1)
          Positioned(
            right: 6,
            child: IconButton(
              onPressed: () {
                _carouselSliderController.nextPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0XFFE94A39), width: 2),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0XFFE94A39),
                  size: 26,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselIndicator(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumItem(QueryDocumentSnapshot album) {
    final coverUrl = album['coverImageUrl'] as String?;
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                AlbumScreen(userId: uid, albumId: album.id),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/albumshadow.png',
                fit: BoxFit.cover,
              ),
            ),
            if (coverUrl != null &&
                coverUrl.isNotEmpty &&
                coverUrl.startsWith('http'))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(34),
                      bottomRight: Radius.circular(38),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(-3, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 0, 12, 6),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(8),
                          topRight: Radius.circular(34),
                          bottomRight: Radius.circular(38)),
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        placeholder: (context, url) => Image.asset(
                          'assets/defaultAlbumCover.png',
                          fit: BoxFit.cover,
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/defaultAlbumCover.png',
                          fit: BoxFit.cover,
                        ),
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              )
            else
              Image.asset(
                'assets/defaultAlbumCover.png',
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAlbumPage() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CreateAlbumPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: ClipRRect(
        //borderRadius: BorderRadius.circular(30),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Image.asset(
            'assets/Album_de.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(QueryDocumentSnapshot album) {
    final albumData = album.data() as Map<String, dynamic>;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateAlbumPage(isEditMode: true),
                settings: RouteSettings(
                  arguments: {
                    'albumId': album.id,
                    'animalName': albumData['animalName'] ?? '',
                    'albumName': albumData['albumName'] ?? '',
                    'birthDate': albumData['birthDate'] ?? '',
                    'coverImageUrl': albumData['coverImageUrl'] ?? '',
                  },
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                albumData['albumName'] ?? "새 앨범",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.border_color_outlined,
                size: 26,
                color: Color(0XFFE94A39),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Text(
          albumData['createdAt'] != null
              ? albumData['createdAt'].toDate().toString().substring(0, 10)
              : "날짜 없음",
          style: TextStyle(
              fontSize: 14, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildEmptyAlbumInfo() {
    return Column(
      children: [
        Text(
          "앨범을 추가해보세요",
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 9),
        Text(
          "날짜를 추가해보세요",
          style: TextStyle(
              fontSize: 14, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(5),
        width: 137,
        child: ElevatedButton.icon(
          // 기록하기 버튼을 누르면 바로 _openCamera 함수를 호출합니다.
          onPressed: _openCamera,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
          label: const Text(
            "기록하기",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
