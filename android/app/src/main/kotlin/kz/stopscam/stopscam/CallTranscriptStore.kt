package kz.stopscam.stopscam

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Optional last transcript only. No audio, backup, logs or network access. */
class CallTranscriptStore(context: Context) {
    private val prefs = context.getSharedPreferences("call_transcript", Context.MODE_PRIVATE)
    private val alias = "stopscam.call.transcript"
    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias,null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }
    fun save(text: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE,key())
        val ciphertext = cipher.doFinal(text.take(12000).toByteArray(Charsets.UTF_8))
        check(prefs.edit().putString("data",Base64.encodeToString(cipher.iv+ciphertext,Base64.NO_WRAP)).commit())
    }
    fun read(): String? {
        val encoded = prefs.getString("data",null) ?: return null
        val raw = Base64.decode(encoded,Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE,key(),GCMParameterSpec(128,raw.copyOfRange(0,12)))
        return String(cipher.doFinal(raw.copyOfRange(12,raw.size)),Charsets.UTF_8)
    }
    fun clear() { check(prefs.edit().remove("data").commit()) }
}
