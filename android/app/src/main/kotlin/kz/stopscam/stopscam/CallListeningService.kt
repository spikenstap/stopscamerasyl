package kz.stopscam.stopscam

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.*
import android.speech.*
import io.flutter.plugin.common.EventChannel

object CallListeningState {
    var sink: EventChannel.EventSink? = null
    var active = false
    var level = "NONE"
    var score = 0
    var text = ""
    var phrases = emptyList<String>()
    var error: String? = null
    var openRequested = false
    fun snapshot(): Map<String,Any?> = mapOf("active" to active, "level" to level,
        "score" to score, "text" to text, "phrases" to phrases, "error" to error,
        "open" to openRequested)
    fun emit() { if (sink != null) { sink?.success(snapshot()); openRequested = false } }
    fun clear(reason: String? = null) {
        active=false; level="NONE"; score=0; text=""; phrases=emptyList(); error=reason; emit()
    }
}

class CallListeningService : Service(), RecognitionListener {
    private val handler = Handler(Looper.getMainLooper())
    private var recognizer: SpeechRecognizer? = null
    private var engine: KeywordEngine? = null
    private var language = "ru"
    private var saveTranscript = false
    private val transcript = StringBuilder()
    private var utterance = 0L
    private var lastSpeech = 0L
    private var started = 0L
    private var lastWarning = -60_000L
    private var finishing = false
    private var ready = false
    private val manager get() = getSystemService(NotificationManager::class.java)
    private fun now() = SystemClock.elapsedRealtime()
    private fun intent() = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        .putExtra(RecognizerIntent.EXTRA_LANGUAGE,if(language=="kk") "kk-KZ" else "ru-RU")
        .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE,true)
        .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS,true)
        .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS,1)
    private fun message(ru: String, kk: String) = if(language=="kk") kk else ru

    override fun onBind(intent: Intent?) = null
    override fun onStartCommand(start: Intent?, flags: Int, startId: Int): Int {
        if (start?.action == "STOP") { finish(); return START_NOT_STICKY }
        if (CallListeningState.active) return START_NOT_STICKY
        try {
            if (Build.VERSION.SDK_INT < 31 || !SpeechRecognizer.isOnDeviceRecognitionAvailable(this)) {
                finish("offline_unavailable"); return START_NOT_STICKY
            }
            language = start?.getStringExtra("language") ?: "ru"
            saveTranscript = start?.getBooleanExtra("saveTranscript",false) == true
            engine = KeywordEngine(KeywordJson.parse(start?.getStringExtra("dictionary") ?: ""))
            manager.createNotificationChannel(NotificationChannel("call-listening","StopScam: microphone",NotificationManager.IMPORTANCE_LOW))
            manager.createNotificationChannel(NotificationChannel("call-danger","StopScam: warning",NotificationManager.IMPORTANCE_HIGH))
            if (!manager.areNotificationsEnabled() ||
                manager.getNotificationChannel("call-listening")?.importance == NotificationManager.IMPORTANCE_NONE ||
                manager.getNotificationChannel("call-danger")?.importance == NotificationManager.IMPORTANCE_NONE) {
                finish("notifications_required"); return START_NOT_STICKY
            }
            val notification = Notification.Builder(this,"call-listening")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentTitle(message("StopScam: микрофон включён","StopScam: микрофон қосулы"))
                .setContentText(message("Локальное распознавание • Остановить","Жергілікті тану • Тоқтату"))
                .setContentIntent(openIntent()).setOngoing(true)
                .addAction(Notification.Action.Builder(null,message("Остановить","Тоқтату"),
                    PendingIntent.getService(this,802,Intent(this,CallListeningService::class.java).setAction("STOP"),
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)).build())
                .build()
            startForeground(801,notification,ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            CallListeningState.clear()
            CallListeningState.active=true
            CallListeningState.emit()
            started=now(); lastSpeech=started
            recognizer=SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
            recognizer!!.setRecognitionListener(this)
            if (Build.VERSION.SDK_INT >= 33) {
                recognizer!!.checkRecognitionSupport(intent(),mainExecutor,object:RecognitionSupportCallback {
                    override fun onSupportResult(support: RecognitionSupport) {
                        if (finishing) return
                        val locale = if(language=="kk") "kk-KZ" else "ru-RU"
                        if (!support.installedOnDeviceLanguages.any { it.equals(locale,true) || it.equals(language,true) }) {
                            finish("language_unavailable"); return
                        }
                        ready=true; listen()
                    }
                    override fun onError(error: Int) { finish("offline_unavailable") }
                })
                handler.postDelayed({ if(!ready && !finishing) finish("offline_unavailable") },5000)
            } else { ready=true; listen() }
            handler.post(watchdog)
        } catch (_: Exception) { finish("recognition_error") }
        return START_NOT_STICKY
    }
    private fun openIntent() = PendingIntent.getActivity(this,803,
        Intent(this,MainActivity::class.java).putExtra("callListening",true)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    private fun listen() {
        if (finishing) return
        utterance++
        try { recognizer?.startListening(intent()) } catch (_: Exception) { finish("recognition_error") }
    }
    private val watchdog=object:Runnable {
        override fun run() {
            if(finishing) return
            if(now()-started >= 30*60_000L) { finish("session_limit"); return }
            if(ready && now()-lastSpeech >= 20_000L) { finish("no_audio"); return }
            engine?.evaluate(now())?.let { publish(it) }
            handler.postDelayed(this,1000)
        }
    }
    private fun recognized(bundle: Bundle?, final: Boolean) {
        if(finishing) return
        val text=bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.take(8000).orEmpty()
        if(text.isNotBlank()) {
            lastSpeech=now()
            CallListeningState.text=text
            engine?.accept(utterance,text,final,now())?.let { publish(it) }
            if(final && saveTranscript) {
                transcript.append(text).append('\n')
                if(transcript.length>12000) transcript.delete(0,transcript.length-12000)
            }
        }
        if(final) handler.postDelayed({ listen() },350)
    }
    private fun publish(result: KeywordResult) {
        CallListeningState.level=result.level.name
        CallListeningState.score=result.score
        CallListeningState.phrases=result.phrases.map { it.variants.first() }
        CallListeningState.emit()
        if(result.level==KeywordLevel.DANGER && now()-lastWarning>=30_000) {
            lastWarning=now()
            val warning=message(
                "Это похоже на мошенничество. Не называйте коды и данные карты. Положите трубку и перезвоните в банк по номеру на карте.",
                "Бұл алаяқтыққа ұқсайды. Кодтар мен карта деректерін айтпаңыз. Қоңырауды аяқтап, картадағы нөмір арқылы банкке қайта хабарласыңыз.")
            manager.notify(804,Notification.Builder(this,"call-danger")
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle(message("StopScam: возможное мошенничество","StopScam: алаяқтық белгісі"))
                .setContentText(warning).setStyle(Notification.BigTextStyle().bigText(warning))
                .setContentIntent(openIntent()).setAutoCancel(true)
                .setCategory(Notification.CATEGORY_STATUS).build())
        }
    }
    private fun finish(reason: String? = null) {
        if(finishing) return
        finishing=true
        handler.removeCallbacksAndMessages(null)
        recognizer?.cancel(); recognizer?.destroy(); recognizer=null
        var finalReason=reason
        if(saveTranscript && transcript.isNotBlank()) {
            try { CallTranscriptStore(this).save(transcript.toString()) }
            catch (_: Exception) { finalReason="storage_error" }
        }
        transcript.clear(); engine?.clear(); engine=null
        CallListeningState.clear(finalReason)
        manager.cancel(804)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
    override fun onTaskRemoved(rootIntent: Intent?) { finish(); super.onTaskRemoved(rootIntent) }
    override fun onDestroy() { finish(); super.onDestroy() }
    override fun onResults(results: Bundle?) = recognized(results,true)
    override fun onPartialResults(partialResults: Bundle?) = recognized(partialResults,false)
    override fun onError(error: Int) {
        if(finishing) return
        when(error) {
            SpeechRecognizer.ERROR_NO_MATCH,SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                if(now()-lastSpeech>=20_000) finish("no_audio")
                else handler.postDelayed({ listen() },500)
            }
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> finish("language_unavailable")
            else -> finish("recognition_error")
        }
    }
    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
}
