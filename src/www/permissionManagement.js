import exec from "cordova/exec";

exports.requestPermission = (key = "CAPTURE", config, success, error) => {
  exec(success, error, "PermissionManagement", "coolMethod", [
    config,
  ]);
};
