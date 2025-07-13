import UIKit
import Flutter
import Firebase
import UserNotifications
import SwiftUI
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // FlutterAppDelegate에 이미 window가 선언되어 있으므로 다시 선언하지 않습니다.
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        GeneratedPluginRegistrant.register(with: self)
        
        // self.window를 사용하여 rootViewController에 접근합니다.
        guard let controller = self.window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController가 FlutterViewController가 아닙니다.")
        }
        
        let cameraChannel = FlutterMethodChannel(name: "com.example.camera",
                                                 binaryMessenger: controller.binaryMessenger)
        
        cameraChannel.setMethodCallHandler { [weak controller] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let controller = controller else {
                result(FlutterError(code: "UNAVAILABLE",
                                    message: "FlutterViewController를 찾을 수 없습니다.",
                                    details: nil))
                return
            }
            
            switch call.method {
            case "openCamera":
                DispatchQueue.main.async {
                    // CustomCameraView가 동일 타겟에 포함되어 있어야 합니다.
                    let customCameraView = CustomCameraView(
                        image: .constant(nil as UIImage?),
                        showingCamera: .constant(true),
                        onPhotoCaptured: { filePath in
                            result(filePath)
                        }
                    )
                    .environmentObject(CubeManager.shared)
                    
                    let hostingController = UIHostingController(rootView: customCameraView)
                    hostingController.modalPresentationStyle = .fullScreen
                    
                    if let navController = controller.navigationController {
                        navController.pushViewController(hostingController, animated: true)
                    } else {
                        controller.present(hostingController, animated: true, completion: nil)
                    }
                }
                
            case "openFilterEditor":
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String,
                      let image = UIImage(contentsOfFile: imagePath) else {
                    result(FlutterError(code: "INVALID_ARGUMENT",
                                          message: "이미지 경로가 없거나 잘못되었습니다.",
                                          details: nil))
                    return
                }
                DispatchQueue.main.async {
                    let filterVC = ImageEditViewController()
                    filterVC.originalImage = image
                    filterVC.modalPresentationStyle = .fullScreen
                    filterVC.onEditingCompleted = { editedImagePath in
                        result(editedImagePath)
                    }
                    
                    if let navController = controller.navigationController {
                        navController.pushViewController(filterVC, animated: true)
                    } else {
                        controller.present(filterVC, animated: true, completion: nil)
                    }
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    } // application(_:didFinishLaunchingWithOptions:) 끝
    
} // AppDelegate 클래스 끝
