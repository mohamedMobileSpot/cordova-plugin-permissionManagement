package cordova.plugin.permissionManagement;

import android.Manifest;
import android.util.Log;
import android.os.Environment;

import org.apache.cordova.PermissionHelper;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.LOG;
import org.apache.cordova.CordovaWebView;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.database.Cursor;
import android.graphics.BitmapFactory;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.DialogInterface;
import android.widget.EditText;
import android.widget.TextView;
import android.os.Build;
import android.content.Context;
import android.provider.Settings;


import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


/**
 * This class echoes a string called from JavaScript.
 */
public class PermissionManagement extends CordovaPlugin {
    private static String LOG_KEY = "CAPTURE";
    private static final String ACTION_CHECK_PERMISSION = "checkPermission";
    private static final String ACTION_REQUEST_CAPTURE_PERMISSION = "requestCapturePermission";
    private static final String ACTION_REQUEST_LOCATION_PERMISSION = "requestLocationPermission";
    private static final String ACTION_REQUEST_PERMISSIONS = "requestPermissions";

    private static final int REQUEST_CODE_ENABLE_PERMISSION = 59888; // random number for tacking permission

    private static final String KEY_ERROR = "error";
    private static final String KEY_MESSAGE = "message";
    private static final String KEY_RESULT_PERMISSION = "message";

    private static final String CAPTURE = android.Manifest.permission.CAMERA;
    private static final String LOCATION = android.Manifest.permission.ACCESS_FINE_LOCATION;
    private static final String LOCATION_GENERAL = android.Manifest.permission.ACCESS_COARSE_LOCATION;
    
    public static String settingPath = "";
    private static String ASK_PERMISSION_KEY = "";

    private CallbackContext permissionsCallback;

    public final String AUTHORIZATION_SUCCESS = "AUTHORIZED";
    public final String AUTHORIZATION_FAILED = "DENIED";
    
    @Override
    public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
      if (ACTION_REQUEST_CAPTURE_PERMISSION.equals(action) || ACTION_REQUEST_PERMISSIONS.equals(action)) {
            ASK_PERMISSION_KEY = CAPTURE;
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        requestCapturePermission(callbackContext, args);
                    } catch (Exception e) {
                       
                        e.printStackTrace();
                        JSONObject returnObj = new JSONObject();
                        addProperty(returnObj, KEY_ERROR, ACTION_REQUEST_CAPTURE_PERMISSION);
                        addProperty(returnObj, KEY_MESSAGE, "Request permission has been denied.");
                        addProperty(returnObj, "exception", e);
                        callbackContext.error(returnObj);
                        permissionsCallback = null;
                    }
                }
            });
            return true;
        } else if (ACTION_REQUEST_LOCATION_PERMISSION.equals(action) || ACTION_REQUEST_PERMISSIONS.equals(action)) {
            ASK_PERMISSION_KEY = LOCATION;
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        requestLocationPermission(callbackContext, args);
                    } catch (Exception e) {
                        e.printStackTrace();
                        JSONObject returnObj = new JSONObject();
                        addProperty(returnObj, KEY_ERROR, ACTION_REQUEST_LOCATION_PERMISSION);
                        addProperty(returnObj, KEY_MESSAGE, "Request permission has been denied.");
                        addProperty(returnObj, "exception", e);
                        callbackContext.error(returnObj);
                        permissionsCallback = null;
                    }
                }
            });
            return true;
        }
        return false;
    }
    // onActivityResult is result after the request AlertDialog
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if(requestCode == REQUEST_CODE_ENABLE_PERMISSION ) {
            JSONObject returnObj = new JSONObject();
            LOG.d(LOG_KEY, String.valueOf(this.cordova.getActivity().RESULT_OK));
            if(requestCode == this.cordova.getActivity().RESULT_OK){
                LOG.d(LOG_KEY, data.getStringExtra("permission"));
            }
            
            String resultMessage = checkPermission(ASK_PERMISSION_KEY) ? AUTHORIZATION_SUCCESS : AUTHORIZATION_FAILED;
            LOG.d(LOG_KEY, resultMessage);
            addProperty(returnObj, KEY_MESSAGE, resultMessage);
            addProperty(returnObj, KEY_RESULT_PERMISSION, checkPermission(ASK_PERMISSION_KEY));
            permissionsCallback.success(returnObj);
        }
         
    }
    
    private Boolean isLocationServicesAvailable(Context context){
        LocationManager lm = (LocationManager)context.getSystemService(Context.LOCATION_SERVICE);
        boolean gps_enabled = false;
        try {
            gps_enabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER);
        } catch(Exception ex) {}
        return gps_enabled;
    }   

    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        final CordovaInterface cordova = this.cordova;
        if (permissionsCallback == null) {
            return;
        }
        JSONObject returnObj = new JSONObject();
        // LOG.d(LOG_KEY, String.valueOf(requestCode));
        if (permissions != null && permissions.length > 0) {
            //Call checkPermission again to verify
            boolean hasAllPermissions = hasAllPermissions(permissions);
            addProperty(returnObj, KEY_RESULT_PERMISSION, checkPermission(ASK_PERMISSION_KEY));
            String message = hasAllPermissions ? AUTHORIZATION_SUCCESS : AUTHORIZATION_FAILED;
            addProperty(returnObj, KEY_MESSAGE, message);
            
            // LOG.d(LOG_KEY, message);
            permissionsCallback.success(returnObj);
        } else {
            addProperty(returnObj, KEY_ERROR, ACTION_REQUEST_PERMISSIONS);
            addProperty(returnObj, KEY_MESSAGE, "Unknown error.");
            permissionsCallback.error(returnObj);
        }
        permissionsCallback = null;
    }
    private String getValueFromKey(JSONArray config, String key, String defaultValue) throws Exception { // getValue of JSONArray if null take default
        String result = "";
        for (int i = 0; i < config.length(); ++i) {
            try {
                JSONObject jsn = config.getJSONObject(i);
                result = jsn.getString(key);
            }
            catch (Exception error) {
                result = defaultValue;
            }
        }
        return result;
    }

    private void requestCapturePermission(CallbackContext callbackContext, JSONArray config) throws Exception {
        permissionsCallback = callbackContext;
        Context context = this.cordova.getActivity().getApplicationContext();
        boolean showRationaleRequest = this.cordova.getActivity().shouldShowRequestPermissionRationale( CAPTURE );
        
        String goSettingModalTitle = (String) getValueFromKey(config, "goSettingModalTitle", "Camera permission denied"); // getValueFromKey get the value defined on config or a defaultvalue
        String goSettingModalMessage = (String) getValueFromKey(config, "goSettingModalMessage", "Go to Settings?"); // getValueFromKey get the value defined on config or a defaultvalue
        String goSettingModalOk = (String) getValueFromKey(config, "goSettingModalOk", "Settings"); // getValueFromKey get the value defined on config or a defaultvalue
        String goSettingModalCancel = (String) getValueFromKey(config, "goSettingModalCancel", "Cancel"); // getValueFromKey get the value defined on config or a defaultvalue
        JSONObject returnObj = new JSONObject();    
        if(context.checkSelfPermission(CAPTURE) == PackageManager.PERMISSION_DENIED){
            if(showRationaleRequest){
                settingPath = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS;
                alert(goSettingModalMessage, goSettingModalTitle ,goSettingModalOk, goSettingModalCancel, permissionsCallback);
            }else {
                cordova.requestPermission(this, REQUEST_CODE_ENABLE_PERMISSION, CAPTURE);
            }
        } else{
            addProperty(returnObj, KEY_MESSAGE, AUTHORIZATION_SUCCESS);
            addProperty(returnObj, KEY_RESULT_PERMISSION, true);
            permissionsCallback.success(returnObj);
        }
    }
    private void requestLocationPermission(CallbackContext callbackContext, JSONArray config) throws Exception {
        permissionsCallback = callbackContext;
        Context context = this.cordova.getActivity().getApplicationContext();
        boolean showRationaleRequest = this.cordova.getActivity().shouldShowRequestPermissionRationale( LOCATION );

        String goSettingModalTitle = (String) getValueFromKey(config, "goSettingModalTitle", "Location permission denied"); // getValueFromKey get the value defined on config or a defaultvalue
        String goSettingModalMessage = (String) getValueFromKey(config, "goSettingModalMessage", "Go to Settings?"); // getValueFromKey get the value defined on config or a defaultvalue
        String goSettingModalOk = (String) getValueFromKey(config, "goSettingModalOk", "Settings"); // getValueFromKey get the value defined on config or a defaultvalue
        String goSettingModalCancel = (String) getValueFromKey(config, "goSettingModalCancel", "Cancel"); // getValueFromKey get the value defined on config or a defaultvalue
        JSONObject returnObj = new JSONObject();
        if (isLocationServicesAvailable) {
            if(context.checkSelfPermission(LOCATION) == PackageManager.PERMISSION_DENIED && context.checkSelfPermission(LOCATION_GENERAL) == PackageManager.PERMISSION_DENIED){
                if(showRationaleRequest){
                    settingPath = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS;
                    alert(goSettingModalMessage, goSettingModalTitle ,goSettingModalOk, goSettingModalCancel, permissionsCallback);
                }else {
                    cordova.requestPermission(this, REQUEST_CODE_ENABLE_PERMISSION, LOCATION);
                }
            }else {
                addProperty(returnObj, KEY_MESSAGE, AUTHORIZATION_SUCCESS);
                permissionsCallback.success(returnObj);
            }
        }else {
            addProperty(returnObj, KEY_MESSAGE, "Your location Service is not available");
            permissionsCallback.success(returnObj);
        }
        
          
    }

    /**
     * Builds and shows a native Android alert with given Strings
     * @param message           The message the alert should display
     * @param title             The title of the alert
     * @param buttonLabel       The label of the button
     * @param callbackContext   The callback context
     */
    public synchronized void alert(final String message, final String title, final String buttonLabel, final String cancelLabel, final CallbackContext callbackContext) {
    	final CordovaInterface cordova = this.cordova;
        final Context context = this.cordova.getActivity().getApplicationContext();
        final CordovaPlugin _this = this;
        Runnable runnable = new Runnable() {
            public void run() {
                JSONObject returnObj = new JSONObject();
                AlertDialog.Builder dlg = new AlertDialog.Builder(cordova.getActivity(), AlertDialog.THEME_DEVICE_DEFAULT_LIGHT); // new AlertDialog.Builder(cordova.getActivity(), AlertDialog.THEME_DEVICE_DEFAULT_LIGHT);
                dlg.setMessage(message);
                dlg.setTitle(title);
                dlg.setCancelable(true);
                dlg.setPositiveButton(buttonLabel,
                        new AlertDialog.OnClickListener() {
                            public void onClick(DialogInterface dialog, int which) {
                                permissionsCallback = callbackContext;
                                Intent mySetting = new Intent(settingPath, Uri.parse("package:" + cordova.getActivity().getPackageName()));
                                mySetting.putExtra("permission", ASK_PERMISSION_KEY);
                                cordova.setActivityResultCallback(_this);
                                cordova.getActivity().startActivityForResult( mySetting, REQUEST_CODE_ENABLE_PERMISSION );
                                dialog.dismiss();
                            }
                        });
                dlg.setNeutralButton(cancelLabel,
                        new AlertDialog.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                // TODO Auto-generated method stub
                                dialog.cancel();
                            }
                    });
                dlg.setOnCancelListener(new AlertDialog.OnCancelListener() {
                    public void onCancel(DialogInterface dialog)
                    {
                        dialog.dismiss();
                        String resultMessage = checkPermission(ASK_PERMISSION_KEY) ? AUTHORIZATION_SUCCESS : AUTHORIZATION_FAILED;
                        addProperty(returnObj, KEY_MESSAGE, resultMessage);
                        addProperty(returnObj, KEY_RESULT_PERMISSION, checkPermission(ASK_PERMISSION_KEY));
                        callbackContext.success(returnObj);
                    }
                });
                dlg.show();
            }
        };
        this.cordova.getActivity().runOnUiThread(runnable);
    }
    private boolean checkPermission(String key) {
        return this.cordova.getActivity().getApplicationContext().checkSelfPermission(key) == PackageManager.PERMISSION_GRANTED;
    }

    private String[] getPermissions(JSONArray permissions) {
        String[] stringArray = new String[permissions.length()];
        for (int i = 0; i < permissions.length(); i++) {
            try {
                stringArray[i] = permissions.getString(i);
            } catch (JSONException ignored) {
                //Believe exception only occurs when adding duplicate keys, so just ignore it
            }
        }
        return stringArray;
    }

    private boolean hasAllPermissions(JSONArray permissions) throws JSONException {
        return hasAllPermissions(getPermissions(permissions));
    }

    private boolean hasAllPermissions(String[] permissions) throws JSONException {
        for (String permission : permissions) {
            if(!cordova.hasPermission(permission)) {
                return false;
            }
        }
        return true;
    }

    private void addProperty(JSONObject obj, String key, Object value) {
        try {
            if (value == null) {
                obj.put(key, JSONObject.NULL);
            } else {
                obj.put(key, value);
            }
        } catch (JSONException ignored) {
            //Believe exception only occurs when adding duplicate keys, so just ignore it
        }
    }
}