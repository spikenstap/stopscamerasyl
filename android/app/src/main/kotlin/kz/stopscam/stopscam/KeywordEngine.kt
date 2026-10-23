package kz.stopscam.stopscam

import java.util.Locale

data class KeywordPhrase(val id: String, val category: String, val variants: List<String>, val weight: Int)
data class KeywordRules(val phrases: List<KeywordPhrase>, val caution: Int, val danger: Int)
enum class KeywordLevel { NONE, CAUTION, DANGER }
data class KeywordResult(val level: KeywordLevel, val score: Int, val phrases: List<KeywordPhrase>)

/** Pure logic. Times are monotonic milliseconds; ASR revisions replace their utterance. */
class KeywordEngine(private val rules: KeywordRules) {
    private data class Utterance(val at: Long, val ids: Set<String>, val final: Boolean)
    private val utterances = linkedMapOf<Long, Utterance>()
    private val patterns = rules.phrases.associate { p ->
        p.id to p.variants.map { variant ->
            val words = variant.lowercase(Locale.ROOT).replace('ё','е').split(Regex("\\s+"))
            val pattern = words.joinToString("\\s+") { word ->
                if (word.endsWith("*")) Regex.escape(word.dropLast(1)) + "[\\p{L}\\p{N}]*"
                else Regex.escape(normalize(word))
            }
            Regex("(?<![\\p{L}\\p{N}])(?:$pattern)(?![\\p{L}\\p{N}])")
        }
    }
    companion object {
        fun normalize(text: String) = text.lowercase(Locale.ROOT).replace('ё','е')
            .replace(Regex("[^\\p{L}\\p{N}\\s]"), " ").replace(Regex("\\s+"), " ").trim()
    }
    fun accept(id: Long, text: String, final: Boolean, now: Long): KeywordResult {
        expire(now)
        val old = utterances[id]
        if (old?.final == true) return evaluate(now)
        val normalized = normalize(text.take(8000))
        val matches = rules.phrases.filter { p ->
            patterns.getValue(p.id).any { regex ->
                regex.findAll(normalized).any { match ->
                    // Explicit warnings not to disclose/install/transfer are not requests.
                    val prefix = normalized.substring(0, match.range.first).trimEnd()
                    val negated = p.category in setOf("otp","remote_access","money_transfer") &&
                        Regex("(?:^| )(?:не|никогда не|никому не)$").containsMatchIn(prefix)
                    !negated
                }
            }
        }.map { it.id }.toSet()
        val at = if (old?.ids == matches) old.at else now
        utterances[id] = Utterance(at, matches, final)
        while (utterances.size > 500) utterances.remove(utterances.keys.first())
        return evaluate(now)
    }
    private fun expire(now: Long) {
        utterances.entries.removeAll { now - it.value.at >= 60_000 }
    }
    fun evaluate(now: Long): KeywordResult {
        expire(now)
        val ids = utterances.values.flatMap { it.ids }.toSet()
        val phrases = rules.phrases.filter { it.id in ids }
        val categories = phrases.map { it.category }.toSet()
        val combined = ("otp" in categories && ("bank_security" in categories || "authority" in categories)) ||
            ("remote_access" in categories && ("bank_security" in categories || "money_transfer" in categories))
        val score = phrases.sumOf { it.weight }
        return KeywordResult(
            if (combined || score >= rules.danger) KeywordLevel.DANGER
            else if (score >= rules.caution) KeywordLevel.CAUTION else KeywordLevel.NONE,
            score, phrases,
        )
    }
    fun clear() = utterances.clear()
}
