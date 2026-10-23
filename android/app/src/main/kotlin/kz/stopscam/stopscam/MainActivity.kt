package kz.stopscam.stopscam

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.role.RoleManager
import android.app.NotificationManager
import android.os.Build
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var listening: CallListeningChannel? = null
    private var numbers: NumberChannel?=null
    private var pending: MethodChannel.Result? = null
    private fun role() = if (Build.VERSION.SDK_INT >= 29) getSystemService(RoleManager::class.java) else null
    private fun status(): Map<String, Any> = mapOf(
        "available" to (role()?.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) == true),
        "held" to (role()?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true),
        "autoBlock" to CallStore(this).prefs.getBoolean("autoBlock", false),
        "notifications" to getSystemService(NotificationManager::class.java).areNotificationsEnabled())
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        listening=CallListeningChannel(this,flutterEngine.dartExecutor.binaryMessenger)
        listening?.open(intent)
        numbers=NumberChannel(this,flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kz.stopscam/calls").setMethodCallHandler { call, result ->
            try {
                val store = CallStore(this)
                when (call.method) {
                    "status" -> result.success(status())
                    "openUrl" -> {
                        val uri = Uri.parse(call.argument<String>("url") ?: "")
                        if (uri.scheme !in listOf("https", "http") || uri.host.isNullOrEmpty()) result.error("url", "Invalid web URL", null)
                        else { startActivity(Intent(Intent.ACTION_VIEW, uri)); result.success(null) }
                    }
                    "requestRole" -> {
                        val manager = role()
                        if (manager == null || !manager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) result.success(false)
                        else if (manager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) result.success(true)
                        else if (pending != null) result.error("busy", "Role request pending", null)
                        else { pending = result; startActivityForResult(manager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING), 602) }
                    }
                    "notifications" -> {
                        if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf("android.permission.POST_NOTIFICATIONS"), 603)
                        else startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        result.success(null)
                    }
                    "settings" -> { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))); result.success(null) }
                    "defaultApps" -> { startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)); result.success(null) }
                    "language" -> { store.prefs.edit().putString("language", call.argument<String>("language") ?: "ru").apply(); result.success(null) }
                    "autoBlock" -> { store.prefs.edit().putBoolean("autoBlock", call.argument<Boolean>("enabled") == true).apply(); result.success(null) }
                    "cache" -> { store.cache(call.argument<String>("number") ?: "", JSONObject(call.argument<Map<String, Any?>>("reputation") ?: emptyMap<String, Any?>())); result.success(null) }
                    "events" -> result.success(store.events().toString())
                    "ack" -> { store.ack((call.argument<List<String>>("ids") ?: emptyList()).toSet()); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("native", "System operation failed", null) }
        }
    }
    @Deprecated("Uses stable Activity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if(numbers?.onResult(requestCode,resultCode,data)==true)return
        if (requestCode == 602) { pending?.success(role()?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true); pending = null }
    }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); listening?.open(intent) }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode,permissions,grantResults)
        listening?.permissions(requestCode,grantResults)
    }
    override fun onDestroy(){listening?.dispose();listening=null;numbers?.dispose();numbers=null;super.onDestroy()}
}
