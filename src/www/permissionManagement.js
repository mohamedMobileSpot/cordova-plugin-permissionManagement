import exec from "cordova/exec";

exports.requestCapturePermission = (config, success, error) => {
	exec(success, error, "PermissionManagement", "requestCapturePermission", [
		config,
	]);
};
