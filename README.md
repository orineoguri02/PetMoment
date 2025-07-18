# 🐾 Pet Moment

**반려동물과의 소중한 순간을 폴라로이드로 담아내는 모바일 앱**

## 📱 프로젝트 소개

Pet Moment는 반려동물과의 특별한 순간들을 폴라로이드 형태로 저장하고 관리할 수 있는 Flutter 기반의 모바일 애플리케이션입니다. 사용자들은 반려동물의 일상을 기록하고, 앨범을 만들어 추억을 정리하며, 실물 앨범으로 제작 주문까지 할 수 있습니다.

## ✨ 주요 기능

### 📷 사진 및 앨범 관리
- **폴라로이드 형태 사진 저장**: 반려동물 사진을 감성적인 폴라로이드 스타일로 저장
- **앨범 생성 및 관리**: 테마별, 날짜별로 앨범을 생성하고 관리
- **실시간 카메라 필터**: 다양한 필터 효과를 적용하여 사진 촬영
- **이미지 편집 기능**: 필터, 밝기, 대비 등 다양한 편집 옵션

### 🔐 다중 로그인 지원
- **카카오 로그인**: 카카오 계정으로 간편 로그인
- **구글 로그인**: 구글 계정 연동
- **애플 로그인**: Apple ID를 통한 로그인 (iOS)
- **이메일 로그인**: 전통적인 이메일/비밀번호 로그인

### 📅 일정 관리
- **캘린더 뷰**: 날짜별로 추억을 확인
- **추억 타임라인**: 시간순으로 정리된 반려동물 기록

### 🛍️ 쇼핑몰 기능
- **앨범 제작 주문**: 디지털 앨범을 실물 앨범으로 제작 주문
- **배송 주소 관리**: 여러 배송지 등록 및 관리
- **주문 내역 확인**: 주문 상태 및 배송 추적

### 👤 사용자 관리
- **프로필 관리**: 닉네임, 프로필 사진 변경
- **계정 설정**: 비밀번호 변경, 계정 정보 수정
- **회원 탈퇴**: 계정 및 모든 데이터 삭제

## 🛠️ 기술 스택

### Frontend
- **Flutter**: 크로스 플랫폼 모바일 앱 개발
- **Dart**: 주요 프로그래밍 언어

### Backend & Database
- **Firebase Auth**: 사용자 인증 관리
- **Cloud Firestore**: NoSQL 데이터베이스
- **Firebase Storage**: 이미지 파일 저장

### 주요 패키지
- `firebase_core`: Firebase 초기화
- `firebase_auth`: 사용자 인증
- `cloud_firestore`: 데이터베이스 연동
- `firebase_storage`: 파일 업로드/다운로드
- `kakao_flutter_sdk`: 카카오 로그인
- `google_sign_in`: 구글 로그인
- `the_apple_sign_in`: 애플 로그인
- `camera`: 카메라 기능
- `image_picker`: 갤러리 접근
- `cached_network_image`: 이미지 캐싱
- `carousel_slider`: 이미지 슬라이더
- `table_calendar`: 캘린더 UI
- `pdf`: PDF 생성

## 📁 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── index.dart                   # 중앙 export 파일
├── firebase_options.dart        # Firebase 설정
├── core/                        # 핵심 설정
│   ├── constants/               # 앱 전체 상수
│   │   ├── app_colors.dart      # 색상 정의
│   │   ├── app_constants.dart   # 기본 상수
│   │   └── app_text_styles.dart # 텍스트 스타일
│   └── utils/                   # 공통 유틸리티
│       ├── image_utils.dart     # 이미지 처리
│       ├── validation_utils.dart # 입력 검증
│       ├── date_utils.dart      # 날짜 처리
│       └── snackbar_utils.dart  # 메시지 표시
├── data/                        # 데이터 계층
│   ├── models/                  # 데이터 모델
│   │   ├── user_model.dart      # 사용자 모델
│   │   ├── album_model.dart     # 앨범 모델
│   │   ├── polaroid_model.dart  # 폴라로이드 모델
│   │   └── product.dart         # 상품 모델
│   └── services/                # 외부 서비스
│       ├── auth_service.dart    # 인증 서비스
│       ├── database_service.dart # 데이터베이스 서비스
│       └── storage_service.dart # 파일 저장 서비스
├── presentation/                # UI 계층
│   └── pages/                   # 화면 구성
│       ├── home/                # 홈 화면
│       │   ├── home.dart        # 메인 화면
│       │   ├── album.dart       # 앨범 상세
│       │   ├── create_album.dart # 앨범 생성
│       │   ├── polaroid_add_screen.dart # 사진 추가
│       │   ├── polaroid_detail.dart # 사진 상세
│       │   ├── calendar.dart    # 캘린더
│       │   └── pdf_dialog.dart  # PDF 생성
│       ├── login/               # 로그인 관련
│       │   ├── SNSLogin/        # SNS 로그인
│       │   ├── findPassword/    # 비밀번호 찾기
│       │   ├── signup.dart      # 회원가입
│       │   └── create_profile.dart # 프로필 생성
│       ├── shop/                # 쇼핑몰
│       │   ├── shoppingPage.dart # 상품 목록
│       │   ├── shopDetail.dart  # 상품 상세
│       │   ├── PayPage.dart     # 결제
│       │   └── Address.dart     # 주소 관리
│       └── mypage/              # 마이페이지
│           ├── mypage.dart      # 마이페이지 메인
│           └── account/         # 계정 관리
└── shared/                      # 공통 컴포넌트
    └── widgets/                 # 공통 위젯
```
## 🎨 주요 화면

### 홈 화면
- 앨범 목록을 카드 형태로 표시
- 새 앨범 생성 버튼
- 하단 네비게이션 바

### 앨범 상세
- 폴라로이드 그리드 뷰
- 사진 추가 버튼
- 캘린더 보기 전환

### 카메라 화면
- 실시간 필터 적용
- 전면/후면 카메라 전환
- 갤러리 접근
