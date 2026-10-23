package kz.stopscam.stopscam

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.*

class CallListeningChannel(private val activity: MainActivity, messenger: BinaryMessenger) {
    private val channel=MethodChannel(messenger,"kz.stopscam/listening")
    private val events=EventChannel(messenger,"kz.stopscam/listening/events")
    private var permissionResult: MethodChannel.Result?=null
    init {
        events.setStreamHandler(object:EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                CallListeningState.sink=sink; CallListeningState.emit()
            }
            override fun onCancel(arguments: Any?) { CallListeningState.sink=null }
        })
        channel.setMethodCallHandler { call, result ->
            try {
                when(call.method) {
                    "status" -> result.success(CallListeningState.snapshot()+mapOf(
                        "available" to (Build.VERSION.SDK_INT>=31 && SpeechRecognizer.isOnDeviceRecognitionAvailable(activity))))
                    "permission" -> {
                        if(permissionResult!=null) result.error("busy","Permission pending",null)
                        else {
                            val permissions=mutableListOf(Manifest.permission.RECORD_AUDIO)
                            if(Build.VERSION.SDK_INT>=33) permissions.add(Manifest.permission.POST_NOTIFICATIONS)
                            val missing=permissions.filter { activity.checkSelfPermission(it)!=PackageManager.PERMISSION_GRANTED }
                            if(missing.isEmpty()) result.success(true)
                            else { permissionResult=result; activity.requestPermissions(missing.toTypedArray(),805) }
                        }
                    }
                    "start" -> {
                        if(!activity.hasWindowFocus() || call.argument<Boolean>("consent")!=true ||
                            activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO)!=PackageManager.PERMISSION_GRANTED) {
                            result.error("permission","Visible consent and microphone permission required",null)
                        } else if(!activity.getSystemService(NotificationManager::class.java).areNotificationsEnabled()) {
                            result.error("notifications_required","Notifications required",null)
                        } else {
                            val dictionary=call.argument<String>("dictionary") ?: ""
                            val rules=KeywordJson.parse(dictionary)
                            require(rules.phrases.isNotEmpty())
                            activity.startForegroundService(Intent(activity,CallListeningService::class.java)
                                .putExtra("dictionary",dictionary)
                                .putExtra("language",call.argument<String>("language"))
                                .putExtra("saveTranscript",call.argument<Boolean>("saveTranscript")==true))
                            result.success(null)
                        }
                    }
                    "stop" -> {
                        if(CallListeningState.active) activity.startService(Intent(activity,CallListeningService::class.java).setAction("STOP"))
                        result.success(null)
                    }
                    "savedTranscript" -> result.success(CallTranscriptStore(activity).read())
                    "deleteTranscript" -> { CallTranscriptStore(activity).clear(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("listening","Local speech operation failed",null) }
        }
    }
    fun permissions(requestCode: Int, results: IntArray): Boolean {
        if(requestCode!=805) return false
        permissionResult?.success(results.isNotEmpty() && results.all { it==PackageManager.PERMISSION_GRANTED })
        permissionResult=null
        return true
    }
    fun open(intent: Intent?) {
        if(intent?.getBooleanExtra("callListening",false)==true) {
            CallListeningState.openRequested=true; CallListeningState.emit()
            intent.removeExtra("callListening")
        }
    }
    fun dispose() {
        permissionResult?.success(false); permissionResult=null
        channel.setMethodCallHandler(null); events.setStreamHandler(null); CallListeningState.sink=null
    }
}
