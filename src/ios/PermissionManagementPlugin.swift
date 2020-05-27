import Foundation
import CoreLocation

@objc(PermissionManagementPlugin) class PermissionManagementPlugin: CDVPlugin, CLLocationManagerDelegate {
  private let LOG_TAG = "PermissionManagementPlugin"
  private var pmanagement: PermissionManagement?
  private var locationManager: CLLocationManager?
  var callBackContext: String?
  override func pluginInitialize() {
    self.pmanagement = PermissionManagement()
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    super.pluginInitialize()
  }

  @objc(requestCapturePermission:) func requestCapturePermission(_ command: CDVInvokedUrlCommand) {
    let config = command.argument(at: 0) as! [String:Any]
    self.pmanagement?.requestCapturePermission(success: { msg in
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg), callbackId:command.callbackId)
    }, fail: {msg in
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId:command.callbackId)
    },config:config)

  }
  @objc(requestLocationPermission:) func requestLocationPermission(_ command: CDVInvokedUrlCommand) {
    self.callBackContext = command.callbackId
    let config = command.argument(at: 0) as! [String:Any]
    self.pmanagement?.requestLocationPermission(success: { msg in
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate!.send(pluginResult, callbackId:self.callBackContext)
    }
    , fail: { msg in
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId:self.callBackContext)
    },config:config)
  }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var msg = ""
        switch status {
        case .authorizedAlways:
            msg = "AUTHORIZED_ALWAYS"
            break
        case .notDetermined:
             msg = "NOT_DETERMINED"
            break
        case .restricted:
             msg = "UNAUTHORIZED"
            break
        case .denied:
             msg = "UNAUTHORIZED"
            break
        case .authorizedWhenInUse:
             msg = "AUTHORIZED_WHEN_IN_USE"
            break
        }
            
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: self.callBackContext)
    }
     
    
}
