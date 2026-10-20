package kz.stopscam.stopscam

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import org.json.JSONObject
import java.util.UUID

class StopScamCallScreeningService : CallScreeningService() {
    override fun onScreenCall(details: Call.Details) {
        if (Build.VERSION.SDK_INT >= 29 && details.callDirection != Call.Details.DIRECTION_INCOMING) return
        var blocked = false
        var decisionSource="unknown"
        var personalRule: String?=null
        var number = ""
        var reputation: JSONObject? = null
        var store: CallStore? = null
        try {
            store = CallStore(this)
            number = CallPolicy.normalize(details.handle?.schemeSpecificPart ?: "")
            reputation = store.reputation(number)
            personalRule=NumberDatabase.get(this).rule(number)
            val reputationBlock = reputation?.let {
                CallPolicy.block(store.prefs.getBoolean("autoBlock", false), it.optString("status"), it.optBoolean("confirmed"), it.optDouble("confidence", 0.0), it.optLong("expiresAt"), System.currentTimeMillis())
            } ?: false
            val decision=CallPolicy.decide(personalRule,reputationBlock)
            blocked=decision.first;decisionSource=decision.second
        } catch (_: Exception) { blocked = false }
        // No networking, AI, database scan or notification work before responding.
        respondToCall(details, CallResponse.Builder().setDisallowCall(blocked).setRejectCall(blocked).setSkipCallLog(false).setSkipNotification(false).build())
        try {
            val activeStore = store ?: CallStore(this)
            activeStore.append(JSONObject().put("id", UUID.randomUUID().toString()).put("number", number)
                .put("timestamp", System.currentTimeMillis()).put("blocked", blocked)
                .put("decisionSource",decisionSource).put("personalRule",personalRule)
                .put("reputation", reputation ?: JSONObject().put("status", "unknown").put("confidence", 0).put("confirmed", false).put("source", "").put("reason", "no_cache")))
            val kk = activeStore.prefs.getString("language", "ru") == "kk"
            val nm = getSystemService(NotificationManager::class.java)
            if (!nm.areNotificationsEnabled()) return
            nm.createNotificationChannel(NotificationChannel("call_checks", if (kk) "Қоңырауларды тексеру" else "Проверка звонков", NotificationManager.IMPORTANCE_DEFAULT))
            val text = if (decisionSource=="personal_block") { if(kk) "Жеке қара тізім: қоңырау бұғатталды" else "Личный чёрный список: звонок заблокирован" }
                else if(decisionSource=="personal_allow") { if(kk) "Жеке рұқсат: қоңырау өткізілді" else "Личное разрешение: звонок пропущен" }
                else if (blocked) { if (kk) "Расталған қауіп: қоңырау бұғатталды" else "Подтверждённая угроза: звонок заблокирован" }
                else if (reputation?.optString("status") == "flagged") { if (kk) "Бедел қызметі қауіп белгіледі" else "Служба репутации отметила угрозу" }
                else { if (kk) "Қоңырау өткізілді. Қауіпсіздігі расталмады." else "Звонок пропущен. Безопасность не подтверждена." }
            val pending = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            nm.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), Notification.Builder(this, "call_checks")
                .setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle("StopScam")
                .setContentText(text).setContentIntent(pending).setAutoCancel(true).setVisibility(Notification.VISIBILITY_PRIVATE).build())
        } catch (_: Exception) { /* Screening already responded; history/notification cannot block a call. */ }
    }
}
