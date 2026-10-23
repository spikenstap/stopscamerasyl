package kz.stopscam.stopscam

import org.json.JSONObject

object KeywordJson {
    fun parse(text: String): KeywordRules {
        require(text.length <= 24000)
        val json = JSONObject(text)
        val caution = json.getInt("cautionThreshold")
        val danger = json.getInt("dangerThreshold")
        require(caution in 2..50 && danger in 3..100 && danger > caution)
        val categories = json.getJSONArray("categories")
        val phrases = mutableListOf<KeywordPhrase>()
        require(categories.length() == 8)
        for (i in 0 until categories.length()) {
            val category = categories.getJSONObject(i)
            val entries = category.getJSONArray("phrases")
            require(entries.length() <= 100)
            for (j in 0 until entries.length()) {
                val entry = entries.getJSONObject(j)
                val variants = entry.getJSONArray("variants")
                require(variants.length() in 1..12 && entry.getInt("weight") in 1..5)
                phrases += KeywordPhrase(entry.getString("id"),category.getString("id"),
                    (0 until variants.length()).map { variants.getString(it) },entry.getInt("weight"))
            }
        }
        require(phrases.map { it.id }.distinct().size == phrases.size)
        return KeywordRules(phrases,caution,danger)
    }
}
