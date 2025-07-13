import UIKit

class ImageEditViewController: UIViewController {
    // 원본 이미지를 전달받을 변수
    var originalImage: UIImage?
    // 편집 완료 후 결과 이미지의 파일 경로를 반환하는 클로저
    var onEditingCompleted: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 원본 이미지를 보여주는 UIImageView 생성
        if let image = originalImage {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(imageView)
        }
        
        // 완료 버튼 추가 (편집 완료를 시뮬레이션)
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("완료", for: .normal)
        doneButton.addTarget(self, action: #selector(doneEditing), for: .touchUpInside)
        doneButton.frame = CGRect(x: 20, y: 40, width: 80, height: 44)
        view.addSubview(doneButton)
    }
    
    @objc func doneEditing() {
        // 여기서는 단순히 원본 이미지를 저장하는 예제입니다.
        // 실제 편집 결과 이미지가 있다면 그 이미지로 대체하세요.
        guard let image = originalImage, let data = image.jpegData(compressionQuality: 1.0) else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        let tempDirectory = NSTemporaryDirectory()
        let fileName = "edited_\(Date().timeIntervalSince1970).jpg"
        let filePath = (tempDirectory as NSString).appendingPathComponent(fileName)
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            try data.write(to: fileURL)
            onEditingCompleted?(filePath)
            dismiss(animated: true, completion: nil)
        } catch {
            print("Error saving edited image: \(error)")
            dismiss(animated: true, completion: nil)
        }
    }
}
