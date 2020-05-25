import Foundation
import CoreLocation

@objc(PermissionManagementPlugin) class PermissionManagementPlugin: CDVPlugin {
  private let LOG_TAG = "PermissionManagementPlugin"
  private var pmanagement: PermissionManagement?
  override func pluginInitialize() {
    self.pmanagement = PermissionManagement()
    super.pluginInitialize()
  }
  @objc(requestCapturePermission:) func requestCapturePermission(_ command: CDVInvokedUrlCommand) {
    let config = command.argument(at: 0) as! [String:Any]
    self.pmanagement?.requestCapturePermission(success: {
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "AUTHORIZATION_GRANTED"), callbackId:command.callbackId)
    }, fail: {
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "AUTHORIZATION_FAILED"), callbackId:command.callbackId)
    },config:config)

  }
  @objc(requestLocationPermission:) func requestLocationPermission(_ command: CDVInvokedUrlCommand) {

    let config = command.argument(at: 0) as! [String:Any]
    self.pmanagement?.requestLocationPermission(success: {
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "AUTHORIZATION_GRANTED"), callbackId:command.callbackId)
    }, fail: {
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "AUTHORIZATION_FAILED"), callbackId:command.callbackId)
    },config:config)
  }
}
