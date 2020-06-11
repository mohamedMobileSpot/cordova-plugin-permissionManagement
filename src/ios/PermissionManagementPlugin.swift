import Foundation
import CoreLocation

@objc(PermissionManagementPlugin) class PermissionManagementPlugin: CDVPlugin, CLLocationManagerDelegate {
  private let LOG_TAG = "PermissionManagementPlugin"
  private var pmanagement: PermissionManagement?
  private var locationManager: CLLocationManager?
  var callBackContext: String?
  private var AUTHORIZATION_SUCCESS = "AUTHORIZED"
  private var AUTHORIZATION_FAIL = "DENIED"
  override func pluginInitialize() {
    self.pmanagement = PermissionManagement()
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    super.pluginInitialize()
  }

  @objc(requestCapturePermission:) func requestCapturePermission(_ command: CDVInvokedUrlCommand) {
    let config = command.argument(at: 0) as! [String:Any]
    self.pmanagement?.requestCapturePermission(success: { msg in
        let arrayObject = ["message":msg] as [AnyHashable : Any]
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: arrayObject), callbackId:command.callbackId)
    }, fail: {msg in
        let arrayObject = ["message":msg] as [AnyHashable : Any]
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: arrayObject), callbackId:command.callbackId)
    },config:config)
  }
  @objc(requestLocationPermission:) func requestLocationPermission(_ command: CDVInvokedUrlCommand) {
    self.callBackContext = command.callbackId
    let config = command.argument(at: 0) as! [String:Any]
    self.pmanagement?.requestLocationPermission(success: { msg in
        let arrayObject = ["message":msg] as [AnyHashable : Any]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: arrayObject)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate!.send(pluginResult, callbackId:self.callBackContext)
    }
    , fail: { msg in
        let arrayObject = ["message":msg] as [AnyHashable : Any]
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: arrayObject), callbackId:self.callBackContext)
    },config:config)
  }
  // function from CLLocationManagerDelegate to listen location authorization change status
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var msg = ""
        switch status {
        case .authorizedAlways:
            msg = AUTHORIZATION_SUCCESS
            break
        case .notDetermined:
             msg = "NOT_DETERMINED"
            break
        case .restricted:
             msg = AUTHORIZATION_FAIL
            break
        case .denied:
             msg = AUTHORIZATION_FAIL
            break
        case .authorizedWhenInUse:
             msg = AUTHORIZATION_SUCCESS
            break
        }
        let arrayObject = ["message":msg] as [AnyHashable : Any]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: arrayObject )
        pluginResult?.setKeepCallbackAs(true) // keep callback
        self.commandDelegate.send(pluginResult, callbackId: self.callBackContext)
    }
     
    
}
