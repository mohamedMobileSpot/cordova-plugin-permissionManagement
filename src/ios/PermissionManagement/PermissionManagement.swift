import UIKit
import AVFoundation
import CoreLocation


@objc public class PermissionManagement: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CLLocationManagerDelegate {
    
    public var authorizationSuccessCallback: ((String) -> ())? = {_ in}
    public var authorizationFailureCallback: ((String) -> ())? = {_ in}
    public var AUTHORIZATION_SUCCESS = "AUTHORIZED"
    public var AUTHORIZATION_FAIL = "DENIED"
    
    func currentTopViewController() -> UIViewController {
        print("current View")
        var topVC: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
        while ((topVC?.presentedViewController) != nil) {
            topVC = topVC?.presentedViewController
        }
        return topVC!
    }
    

    @objc public func requestCapturePermission(success successCallback: @escaping (String) -> (), fail failureCallback: @escaping (String) -> (),config:[String:Any]) {
        
        authorizationSuccessCallback = successCallback
        authorizationFailureCallback = failureCallback
        
        let goSettingModalTitle = (config["goSettingModalTitle"] != nil) ? config["goSettingModalTitle"] as! String : "Camera permission denied"
        
        let goSettingModalMessage = (config["goSettingModalMessage"] != nil) ? config["goSettingModalMessage"] as! String : "Go to Settings?"
        
        let goSettingModalOk = (config["goSettingModalOk"] != nil) ? config["goSettingModalOk"] as! String : "Settings"
        
        let goSettingModalCancel = (config["goSettingModalCancel"] != nil) ? config["goSettingModalCancel"] as! String : "Cancel"
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                print("AUTHORIZED")
                if let callback = authorizationSuccessCallback {
                    callback(self.AUTHORIZATION_SUCCESS)
                }
                break;
            case .notDetermined: // The user has not yet been asked for camera access.
                print("NOT DETERMINED")
              
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        if let callback = self.authorizationSuccessCallback {
                            callback(self.AUTHORIZATION_SUCCESS)
                        }
                        print("AUTHORIZED")
                    }
                    else{
                        if let callback = self.authorizationSuccessCallback {
                            callback(self.AUTHORIZATION_FAIL)
                        }
                        print("DENIED")
                    }
                }
            
            case .denied: // The user has previously denied access.
                print("DENIED")
                let alertController = UIAlertController (title: goSettingModalTitle, message: goSettingModalMessage, preferredStyle: .alert)

                let settingsAction = UIAlertAction(title: goSettingModalOk, style: .default) { (_) -> Void in

                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }

                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                print("Settings opened: \(success)") // Prints true
                                if let callback = self.authorizationSuccessCallback {
                                    var msg = self.AUTHORIZATION_FAIL
                                    if(AVCaptureDevice.authorizationStatus(for: .video) == .authorized){
                                        msg = self.AUTHORIZATION_SUCCESS
                                    }
                                    callback(msg)
                                }
                            })
                        } else {
                            if let callback = self.authorizationFailureCallback {
                                callback("Error: need ios 10.0 or more")
                            }
                            // Fallback on earlier versions
                        }
                    }
                }
                
                let cancelAction = UIAlertAction(title: goSettingModalCancel, style: .default
                ) { (action) in
                    print(action)
                    if let callback = self.authorizationSuccessCallback {
                        callback(self.AUTHORIZATION_FAIL)
                    }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                
                let currentTopVC: UIViewController? = self.currentTopViewController()
                currentTopVC?.present(alertController, animated: true, completion: nil)
                return

            case .restricted: // The user can't grant access due to restrictions.
                print("RESTRICTED")
                if let callback = authorizationSuccessCallback {
                    callback(self.AUTHORIZATION_FAIL)
                }
                return
        }
   
    }
    var locationManager: CLLocationManager?
    

    @objc public func requestLocationPermission(success successCallback: @escaping (String) -> (), fail failureCallback: @escaping (String) -> (), config:[String:Any]) {
        authorizationSuccessCallback = successCallback
        authorizationFailureCallback = failureCallback
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        view.backgroundColor = .gray
        
        let goSettingModalTitle = (config["goSettingModalTitle"] != nil) ? config["goSettingModalTitle"] as! String : "Location permission denied"
        
        let goSettingModalMessage = (config["goSettingModalMessage"] != nil) ? config["goSettingModalMessage"] as! String : "Go to Settings?"
        
        let goSettingModalOk = (config["goSettingModalOk"] != nil) ? config["goSettingModalOk"] as! String : "Settings"
        
        let goSettingModalCancel = (config["goSettingModalCancel"] != nil) ? config["goSettingModalCancel"] as! String : "Cancel"
        
        switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    locationManager?.requestWhenInUseAuthorization();
                    break;
                case .restricted, .denied:
                    print("!! UNAUTHORIZED !!")
                    let alertController = UIAlertController (title: goSettingModalTitle, message: goSettingModalMessage, preferredStyle: .alert)

                    let settingsAction = UIAlertAction(title: goSettingModalOk, style: .default) { (_) -> Void in

                        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                            return
                        }

                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                    print("Settings opened: \(success)") // Prints true
                                    if let callback = self.authorizationSuccessCallback {
                                        var msg = self.AUTHORIZATION_FAIL
                                        if(CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse){
                                            msg = self.AUTHORIZATION_SUCCESS
                                        }
                                        callback(msg)
                                    }
                                })
                            } else {
                                if let callback = self.authorizationFailureCallback {
                                    callback("Error: need ios 10.0 or more")
                                }
                                // Fallback on earlier versions
                            }
                        }
                    }
                    let cancelAction = UIAlertAction(title: goSettingModalCancel, style: .default
                    ) { (action) in
                        print(action)
                        if let callback = self.authorizationSuccessCallback {
                            callback(AUTHORIZATION_FAIL)
                        }
                    }
                           alertController.addAction(cancelAction)
                           alertController.addAction(settingsAction)
                        
                           let currentTopVC: UIViewController? = self.currentTopViewController()
                           currentTopVC?.present(alertController, animated: true, completion: nil)

                    break;
                case .authorizedAlways:
                    if let callback = authorizationSuccessCallback {
                        print("successCallBack")
                        callback(self.AUTHORIZATION_SUCCESS)
                    }
                    break;
                case .authorizedWhenInUse:
                    if let callback = authorizationSuccessCallback {
                        print("successCallBack")
                        callback(self.AUTHORIZATION_SUCCESS)
                    }
        }
        
    }
}
