// 폴라로이드 미리보기 화면

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// MARK: - Album Model
struct Album: Identifiable {
    let id: String
    let albumName: String
}

//struct KeyboardAdaptive: ViewModifier {
//    @State private var keyboardHeight: CGFloat = 100
//    
//    private let keyboardWillShow = NotificationCenter.default
//        .publisher(for: UIResponder.keyboardWillShowNotification)
//        .compactMap { notification in
//            notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
//        }
//        .map { rect in
//            rect.height
//        }
//    
//    private let keyboardWillHide = NotificationCenter.default
//        .publisher(for: UIResponder.keyboardWillHideNotification)
//        .map { _ in CGFloat(0) }
//    
//    func body(content: Content) -> some View {
//        content
//            .padding(.bottom, keyboardHeight)
//            .onReceive(
//                Publishers.Merge(keyboardWillShow, keyboardWillHide)
//            ) { height in
//                withAnimation(.easeInOut) {
//                    self.keyboardHeight = height
//                }
//            }
//    }
//}
//
//extension View {
//    func keyboardAdaptive() -> some View {
//        ModifiedContent(content: self, modifier: KeyboardAdaptive())
//    }
//}

// MARK: - PhotoPreviewView
struct PhotoPreviewView: View {
    // MARK: - Properties (Props)
    @Environment(\.dismiss) var dismiss
    let image: UIImage
    @Binding var isPresented: Bool      // 미리보기 화면의 표시 여부 (바인딩)
    let onSave: (UIImage, Bool) -> Void         // 사진 저장 시 호출되는 클로저
    @Binding var showCamera: Bool         // 카메라 화면 표시 여부 (바인딩)
    
    // MARK: - State Variables
    @State private var albums: [Album] = []          // Firestore에서 가져온 앨범 목록
    @State private var selectedAlbumId: String?      // 선택된 앨범의 ID
    @State private var inputText = ""                // 사용자가 입력한 텍스트
    @State private var isUploading = false           // 업로드 진행 여부
    @FocusState private var isFocused: Bool         // 키보드 내려가게
    
    @State private var selectedDate: Date = Date()
    @State private var finalSelectedDate: Date = Date() // 최종 확정 날짜
    @State private var backupDate: Date = Date() // 데이트피커 열 때 백업용
    @State private var showDatePicker: Bool = false
    
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .center) {
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .center) {
                    topBar
                    Spacer(minLength: 20)
                    polaroidCard
                    Spacer(minLength: 20)
                    bottomBar
                } // VStack
                .padding(.horizontal, 20)
                .onAppear {
                    fetchAlbums() // 뷰가 나타날 때 앨범을 Firestore에서 가져옵니다.
                }
                //.keyboardAdaptive()
                
            }
        } // ZStack
        .overlay(
            Group {
                if showDatePicker {
                    VStack(spacing: 0) {
                        // 배경 영역 (탭 가능)
                        Spacer()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                            .onTapGesture {
                                showDatePicker = false
                            }
                        
                        // 데이트피커 컨테이너
                        VStack(spacing: 0) {
                            HStack {
                                Button(action: {
                                    selectedDate = backupDate
                                    showDatePicker = false
                                }) {
                                    Text("취소")
                                        .foregroundColor(Color(hex: "E94A39"))
                                }
                                .padding()
                                
                                Spacer()
                                
                                Button(action: {
                                    finalSelectedDate = selectedDate
                                    showDatePicker = false
                                }) {
                                    Text("완료")
                                        .foregroundColor(Color(hex: "E94A39"))
                                }
                                .padding()
                            }
                            .frame(height: 40)
                            .background(Color(hex: "F8F8F8"))
                            
                            // 날짜 선택기
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1))!...Date(),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                        }
                        .background(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.25)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
    }
}

// MARK: - Subviews for PhotoPreviewView
extension PhotoPreviewView {
    /// 상단 바: 앨범 선택 드롭다운 및 닫기 버튼
    private var topBar: some View {
        HStack {
            // 드롭다운 메뉴: 앨범 목록을 보여주고 선택하면 selectedAlbumId를 갱신
            Menu {
                ForEach(albums) { album in
                    Button(album.albumName) {
                        selectedAlbumId = album.id
                    }
                }
            } label: {
                HStack {
                    // 선택된 앨범 이름이 없으면 "앨범 선택"으로 표시
                    Text(albums.first(where: { $0.id == selectedAlbumId })?.albumName ?? "앨범 선택")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                )
            }
            
            Spacer()
            
            // 닫기 버튼: xmark 아이콘을 누르면 미리보기 화면을 닫고 카메라 화면을 보여줌
            Button {
                showCamera = true
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .padding(.top, 40) // 상단에서 40 포인트 아래로 이동
    }
    
    /// 폴라로이드 카드: 사진과 텍스트 입력 영역
    private var polaroidCard: some View {
        ZStack {
            // 바깥쪽 컨테이너 (흰색 배경, 그림자 효과 포함)
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 0) {
                // 상단 이미지 영역 - 흰색 여백이 있는 폴라로이드 스타일
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .padding(.top, 10)    // 위쪽 여백
                    .padding(.horizontal, 10) // 좌우 여백
                
                
                // 하단 텍스트
                ZStack(alignment: .topLeading) {
                    if inputText.isEmpty {
                        Text("텍스트를 입력하세요")
                            .font(.custom("HSYuji-Regular", size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                            .padding(.leading, 20)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.custom("HSYuji-Regular", size: 16))
                        .focused($isFocused)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 20)
                        .frame(height: 60)
                        .onChange(of: inputText) { newValue in
                            let lines = newValue.components(separatedBy: .newlines)
                            if lines.count > 2 {
                                // 2줄까지만 유지
                                inputText = lines.prefix(2).joined(separator: "\n")
                                // 키보드 내리기
                                isFocused = false
                            }
                        } // onChange
                        .scrollContentBackground(.hidden) // 배경 투명 (iOS 16+)
                    //.ignoresSafeArea(.keyboard, edges: .bottom)
                } // ZStack
                Button(action: {
                    backupDate = finalSelectedDate // 열기 전에 백업
                    selectedDate = finalSelectedDate // 데이트피커에 현재 날짜 반영
                    showDatePicker = true
                }) {
                    HStack {
                        Spacer()
                        Text(dateString(from: finalSelectedDate))
                            .font(.custom("HSYuji-Regular", size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
            } // VStack
        }
        // aspectRatio 0.76 적용 (width:height = 3:4 비율과 유사)
        .aspectRatio(0.8, contentMode: .fit)
        //.frame(maxWidth: 300) // 최대 너비 제한
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd" // 원하는 날짜 형식
        return formatter.string(from: date)
    }
    /// 하단 영역: "작성 완료" 버튼
    private var bottomBar: some View {
        HStack {
            Spacer()
            Button {
                // 작성 완료 버튼 클릭 시 uploadPhoto() 호출
                Task {
                    await uploadPhoto()
                }
            } label: {
                if isUploading {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Text("작성 완료")
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(10)
            .disabled(isUploading)
        } // HStack
    }
}

// MARK: - Firebase Methods for PhotoPreviewView
extension PhotoPreviewView {
    
    /// Firestore에서 앨범들을 가져옵니다.
    private func fetchAlbums() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("albums")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching albums: \(error)")
                    return
                }
                if let documents = snapshot?.documents {
                    // 문서를 Album 모델 배열로 매핑
                    self.albums = documents.compactMap { doc -> Album? in
                        let data = doc.data()
                        guard let id = data["id"] as? String,
                              let albumName = data["albumName"] as? String else {
                            return nil
                        }
                        return Album(id: id, albumName: albumName)
                    }
                    // 앨범이 존재하면 첫 번째 앨범을 기본 선택
                    if let firstAlbum = self.albums.first {
                        self.selectedAlbumId = firstAlbum.id
                    }
                }
            }
    }
    
    // 이미지 압축 함수
    private func compressImage(_ image: UIImage, quality: CGFloat = 0.9, maxSizeKB: Int = 500) -> Data? {
        // 1. 먼저 설정된 품질로 압축 시도
        guard var imageData = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        // 2. 목표 크기보다 크면 점진적으로 품질 낮추기
        var currentQuality = quality
        while imageData.count > maxSizeKB * 1024 && currentQuality > 0.1 {
            currentQuality -= 0.1
            if let newData = image.jpegData(compressionQuality: currentQuality) {
                imageData = newData
            } else {
                break
            }
        }
        
        return imageData
    }
    
    // Firebase에 사진과 텍스트 업로드
    private func uploadPhoto() async {
        guard !isUploading else { return }
        isUploading = true
        defer { isUploading = false }
        
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }
        
        guard let albumId = selectedAlbumId else {
            print("앨범이 선택되지 않았습니다.")
            return
        }
        
        // 압축 함수 사용
        guard let compressedImageData = compressImage(image) else {
            print("이미지 압축에 실패했습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let userId = user.uid
        let email = user.email ?? userId  // 이메일 없으면 userId 사용
        let timestamp = Timestamp(date: selectedDate) // 선택된 날짜 사용
        
        let colRef = db.collection("users").document(userId)
            .collection("albums").document(albumId)
            .collection("polaroid")
        
        do {
            // 1) Firestore에 먼저 빈 문서 생성
            let docRef = try await colRef.addDocument(data: [
                "imageUrl": "",
                "imageStoragePath": "",
                "text": inputText.replacingOccurrences(of: "\n", with: "\\n"),
                "timestamp": timestamp
            ])
            
            // 2) Storage 경로 설정 (Album/이메일/앨범이름/파일명)
            let fileName = "camera_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
            let path = "Album/\(email)/\(albums.first(where: { $0.id == albumId })?.albumName ?? "Unknown")/\(fileName)"
            let storageRef = storage.reference().child(path)
            
            // 3) Storage에 압축된 이미지 업로드
            _ = try await storageRef.putDataAsync(compressedImageData, metadata: nil)
            
            // 4) 다운로드 URL 얻기
            let downloadURL = try await storageRef.downloadURL()
            
            // 5) Firestore 문서 업데이트
            try await docRef.updateData([
                "imageUrl": downloadURL.absoluteString,
                "imageStoragePath": path
            ])
            
            print("사진 업로드 성공")
            // 이미지와 uploadSuccess를 true로 하여 onSave 호출
            onSave(image, true)
            
            // 업로드 완료 후 닫기
            await MainActor.run {
                isPresented = false
                showCamera = false
            }
            
        } catch {
            print("업로드 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
}
