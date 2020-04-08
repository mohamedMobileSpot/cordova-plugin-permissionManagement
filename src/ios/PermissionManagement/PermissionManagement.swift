import UIKit
import AVFoundation



@objc public class PermissionManagement: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    func currentTopViewController() -> UIViewController {
        var topVC: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
        while ((topVC?.presentedViewController) != nil) {
            topVC = topVC?.presentedViewController
        }
        return topVC!
    }
    @objc public func requestCapturePermission(config:[String:Any]) {
        
        let goSettingModalTitle = (config["goSettingModalTitle"] != nil) ? config["goSettingModalTitle"] as! String : "Camera permission denied"
        
        let goSettingModalMessage = (config["goSettingModalMessage"] != nil) ? config["goSettingModalMessage"] as! String : "Go to Settings?"
        
        let goSettingModalOk = (config["goSettingModalOk"] != nil) ? config["goSettingModalOk"] as! String : "Settings"
        
        let goSettingModalCancel = (config["goSettingModalCancel"] != nil) ? config["goSettingModalCancel"] as! String : "Cancel"
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                print("AUTHORIZED")
            
            case .notDetermined: // The user has not yet been asked for camera access.
                print("NOT DETERMINED")
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        print("AUTHORIZED")
                    }
                    else{
                        print("UNAUTHORISED")
                    }
                }
            
            case .denied: // The user has previously denied access.
                print("UNAUTHORISED")
                let alertController = UIAlertController (title: goSettingModalTitle, message: goSettingModalMessage, preferredStyle: .alert)

                let settingsAction = UIAlertAction(title: goSettingModalOk, style: .default) { (_) -> Void in

                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }

                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
                }
                
                let cancelAction = UIAlertAction(title: goSettingModalCancel, style: .default, handler: nil)
                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                
                let currentTopVC: UIViewController? = self.currentTopViewController()
                currentTopVC?.present(alertController, animated: true, completion: nil)
                return

            case .restricted: // The user can't grant access due to restrictions.
                print("RESTRICTED")
                return
        }
        
        
    }
}
