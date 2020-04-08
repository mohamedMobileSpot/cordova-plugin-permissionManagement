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
    self.pmanagement?.requestCapturePermission(config:config)
    let warnings = [String]()
    let result: CDVPluginResult
    result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: warnings.joined(separator: "\n"))
    commandDelegate!.send(result, callbackId: command.callbackId)
  }
}