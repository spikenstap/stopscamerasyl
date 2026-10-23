package kz.stopscam.stopscam

import java.io.File
import org.junit.Assert.*
import org.junit.Test

class KeywordEngineTest {
    private fun rules(): KeywordRules {
        val file=listOf(File("../../assets/call_keywords/ru.json"),File("../assets/call_keywords/ru.json"),
            File("assets/call_keywords/ru.json")).first { it.exists() }
        return KeywordJson.parse(file.readText())
    }
    @Test fun scenarioSetOfTwenty() {
        val scams=listOf(
            "Служба безопасности банка. Назовите код из СМС",
            "Я следователь. Продиктуйте код подтверждения",
            "Безопасный счет. Установите AnyDesk",
            "Установите тим вьювер и переведите деньги",
            "Ваша карта заблокирована. Нужен удалённый доступ",
            "Снимите наличные, оформите кредит, прямо сейчас, никому не говорите",
            "Гарантированный доход, брокер, криптовалюта, быстрый заработок",
            "Ваш сын попал в аварию, нужны деньги. Переведите деньги срочно",
            "Ваша дочь попала в аварию. Снимите наличные, не кладите трубку",
            "Полиция. Назовите код из эс эм эс",
        )
        val benign=listOf(
            "Я курьер, буду через пять минут. Какой у вас подъезд?",
            "Банк сообщает: операция по карте завершена. Никому не сообщайте код подтверждения",
            "Привет, сын, как прошел день? Заедем к бабушке вечером",
            "Карта и банк на столе, код домофона я помню",
            "Ваша карта заблокирована. Позвоните по номеру на карте",
            "Завтра заберу посылку, спасибо за доставку",
            "Мы идём в магазин за хлебом и молоком",
            "Код подтверждения никому не сообщайте",
            "Не установите приложение случайно, сначала прочитайте описание",
            "Прямо сейчас готовлю ужин. Срочно нужен рецепт",
        )
        val detected=scams.count { KeywordEngine(rules()).accept(1,it,true,0).level==KeywordLevel.DANGER }
        val falsePositives=benign.count { KeywordEngine(rules()).accept(1,it,true,0).level!=KeywordLevel.NONE }
        assertEquals("Local scripted scenarios only: detected",10,detected)
        assertEquals("Local scripted scenarios only: false positives",0,falsePositives)
        println("LOCAL_SCENARIOS total=20 danger_detected=$detected/10 false_positives=$falsePositives/10")
    }
    @Test fun partialRevisionsAndFinalsDoNotMultiplyScores() {
        val engine=KeywordEngine(rules())
        val once=engine.accept(1,"назовите код из смс",false,0)
        repeat(5) { assertEquals(once.score,engine.accept(1,"назовите код из смс",false,it*100L).score) }
        assertEquals(0,engine.accept(1,"привет друг",false,1000).score)
        engine.accept(1,"назовите код из смс",true,2000)
        assertEquals(once.score,engine.accept(2,"назовите код из смс",true,3000).score)
        assertEquals(once.score,engine.accept(2,"назовите код из смс назовите код из смс",true,4000).score)
    }
    @Test fun windowExpiresAtSixtySecondsAndDuplicatePartialDoesNotExtendIt() {
        val engine=KeywordEngine(rules())
        engine.accept(1,"безопасный счет",false,0)
        engine.accept(1,"безопасный счет",false,50000)
        assertTrue(engine.evaluate(59999).score>0)
        assertEquals(0,engine.evaluate(60000).score)
        engine.accept(2,"назовите код из смс",true,61000)
        assertEquals(KeywordLevel.NONE,engine.evaluate(61000).level)
    }
    @Test fun combinationAcrossUtterancesAndReset() {
        val engine=KeywordEngine(rules())
        assertEquals(KeywordLevel.NONE,engine.accept(1,"следователь",true,0).level)
        assertEquals(KeywordLevel.DANGER,engine.accept(2,"сообщите код подтверждения",true,1000).level)
        engine.clear()
        assertEquals(KeywordLevel.NONE,engine.evaluate(1000).level)
    }
    @Test fun spellingVariantsPunctuationStemsAndBoundaries() {
        assertEquals("удаленный доступ",KeywordEngine.normalize(" УДАЛЁННЫЙ,  ДОСТУП! "))
        val engine=KeywordEngine(rules())
        assertEquals(KeywordLevel.DANGER,engine.accept(1,"ПРОКУРАТУРА! Назовите код из эс эм эс.",true,0).level)
        assertEquals(0,KeywordEngine(rules()).accept(1,"раскодировка карта банк",true,0).score)
        assertEquals(KeywordLevel.DANGER,KeywordEngine(rules()).accept(1,"Безопасный счёт, установите эни деск",true,0).level)
    }
    @Test fun negatedCodeRequestIsNotAlarmEvidence() {
        val engine=KeywordEngine(rules())
        assertEquals(KeywordLevel.NONE,engine.accept(1,
            "Служба безопасности банка: никогда не сообщите код подтверждения",true,0).level)
    }
}
