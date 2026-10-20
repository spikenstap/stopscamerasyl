package kz.stopscam.stopscam

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object CallPolicy {
    fun decide(personalRule: String?, reputationBlock: Boolean): Pair<Boolean,String> = when(personalRule) {
        "blocked" -> true to "personal_block"
        "trusted" -> false to "personal_allow"
        else -> reputationBlock to if(reputationBlock) "reputation" else "unknown"
    }
    fun block(enabled: Boolean, status: String, confirmed: Boolean, confidence: Double, expires: Long, now: Long): Boolean =
        enabled && status == "flagged" && confirmed && confidence.isFinite() && confidence >= 0.95 && confidence <= 1.0 && expires > now
    fun normalize(raw: String): String {
        val digits = raw.filter { it.isDigit() }
        return when {
            digits.length == 11 && digits.startsWith("8") -> "+7" + digits.substring(1)
            raw.startsWith("+") -> "+$digits"
            digits.startsWith("00") -> "+" + digits.substring(2)
            digits.length == 11 && digits.startsWith("7") -> "+$digits"
            else -> digits
        }
    }
}

class CallStore(context: Context) {
    val prefs = context.getSharedPreferences("stopscam_calls", Context.MODE_PRIVATE)
    fun reputation(number: String): JSONObject? = try {
        prefs.getString("rep:$number", null)?.let { JSONObject(it) }?.takeIf { it.optLong("expiresAt") > System.currentTimeMillis() }
    } catch (_: Exception) { null }
    fun cache(number: String, value: JSONObject) {
        val expiry = minOf(value.optLong("expiresAt"), System.currentTimeMillis() + 86400000)
        value.put("expiresAt", expiry)
        synchronized(lock) {
            val edit = prefs.edit()
            prefs.all.filterKeys { it.startsWith("rep:") }.forEach { (key, raw) ->
                val expired = try { JSONObject(raw as String).optLong("expiresAt") <= System.currentTimeMillis() } catch (_: Exception) { true }
                if (expired) edit.remove(key)
            }
            edit.putString("rep:${CallPolicy.normalize(number)}", value.toString()).apply()
        }
    }
    fun events(): JSONArray = synchronized(lock) {
        try { JSONArray(prefs.getString("events", "[]")) } catch (_: Exception) { JSONArray() }
    }
    fun append(event: JSONObject) = synchronized(lock) {
        val old = events()
        val next = JSONArray()
        // Match the app's explicit 200-entry retention policy.
        for (i in maxOf(0, old.length() - 199) until old.length()) next.put(old.getJSONObject(i))
        next.put(event)
        prefs.edit().putString("events", next.toString()).commit()
    }
    fun ack(ids: Set<String>) = synchronized(lock) {
        val old = events(); val next = JSONArray()
        for (i in 0 until old.length()) { val e = old.getJSONObject(i); if (!ids.contains(e.optString("id"))) next.put(e) }
        prefs.edit().putString("events", next.toString()).commit()
    }
    companion object { private val lock = Any() }
}
