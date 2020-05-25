import exec from "cordova/exec";
const FUNCTION_PERMISSION_KEY = {
  CAPTURE: "requestCapturePermission",
  LOCATION: "requestLocationPermission",
};
exports.requestPermission = (key = "CAPTURE", config, success, error) => {
  exec(success, error, "PermissionManagement", FUNCTION_PERMISSION_KEY[key], [
    config,
  ]);
};
