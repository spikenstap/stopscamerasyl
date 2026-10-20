package kz.stopscam.stopscam

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class NumberStoreException(val code: String) : RuntimeException(code)

class NumberDatabase private constructor(context: Context) : SQLiteOpenHelper(context, "personal_numbers.db", null, 1) {
    init { setWriteAheadLoggingEnabled(true) }
    override fun onConfigure(db: SQLiteDatabase) { db.setForeignKeyConstraintsEnabled(true) }
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""CREATE TABLE numbers (
          phone TEXT PRIMARY KEY NOT NULL,
          label TEXT NOT NULL DEFAULT '',
          rule TEXT NOT NULL CHECK(rule IN ('watch','blocked','trusted')),
          category TEXT NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL)""")
        db.execSQL("""CREATE TABLE reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT NOT NULL REFERENCES numbers(phone) ON DELETE CASCADE ON UPDATE CASCADE,
          category TEXT NOT NULL, note TEXT NOT NULL, createdAt INTEGER NOT NULL)""")
        db.execSQL("CREATE INDEX reports_phone ON reports(phone, createdAt DESC)")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Never destroy user data to recover an unsupported schema.
        throw NumberStoreException("schema")
    }
    private fun Cursor.number(): Map<String, Any> = mapOf(
        "phone" to getString(getColumnIndexOrThrow("phone")), "label" to getString(getColumnIndexOrThrow("label")),
        "rule" to getString(getColumnIndexOrThrow("rule")), "category" to getString(getColumnIndexOrThrow("category")),
        "note" to getString(getColumnIndexOrThrow("note")), "createdAt" to getLong(getColumnIndexOrThrow("createdAt")),
        "updatedAt" to getLong(getColumnIndexOrThrow("updatedAt")), "reportCount" to getInt(getColumnIndexOrThrow("reportCount")))
    private val select = "SELECT n.*, (SELECT COUNT(*) FROM reports r WHERE r.phone=n.phone) AS reportCount FROM numbers n"
    fun all(): List<Map<String, Any>> = readableDatabase.rawQuery("$select ORDER BY n.updatedAt DESC, n.phone", null).use { c ->
        buildList { while(c.moveToNext()) add(c.number()) }
    }
    fun find(phone: String): Map<String, Any>? = readableDatabase.rawQuery("$select WHERE n.phone=?", arrayOf(phone)).use { c -> if(c.moveToFirst()) c.number() else null }
    fun rule(phone: String): String? = readableDatabase.rawQuery("SELECT rule FROM numbers WHERE phone=?", arrayOf(phone)).use { c -> if(c.moveToFirst()) c.getString(0) else null }
    private fun phone(value: Any?): String {
        val text = value as? String ?: throw NumberStoreException("invalid")
        if (!Regex("^\\+[1-9][0-9]{6,14}$").matches(text)) throw NumberStoreException("invalid")
        return text
    }
    private fun text(value: Any?, max: Int): String {
        val text = (value as? String ?: "").trim()
        if(text.length > max || text.contains('\u0000')) throw NumberStoreException("invalid")
        return text
    }
    private fun category(value: Any?): String {
        val result=value as? String ?: "unknown"
        if(result !in listOf("unknown","advertising","suspectedFraud","harassment","other")) throw NumberStoreException("invalid")
        return result
    }
    private fun values(data: Map<String, Any?>, restoreRules: Boolean = true): ContentValues {
        val mode=if(restoreRules) data["rule"] as? String ?: "watch" else "watch"
        if(mode !in listOf("watch","blocked","trusted")) throw NumberStoreException("invalid")
        return ContentValues().apply {
            put("phone",phone(data["phone"])); put("label",text(data["label"],100)); put("rule",mode)
            put("category",category(data["category"])); put("note",text(data["note"],500)); put("updatedAt",System.currentTimeMillis())
        }
    }
    private fun capacity(db: SQLiteDatabase, adding: Int = 1) {
        val count=db.rawQuery("SELECT COUNT(*) FROM numbers",null).use { it.moveToFirst(); it.getInt(0) }
        if(count+adding>5000) throw NumberStoreException("limit")
    }
    fun save(data: Map<String, Any?>) {
        val values=values(data); val target=values.getAsString("phone")
        val original=data["originalPhone"] as? String
        val db=writableDatabase
        db.beginTransaction()
        try {
            if(find(target)!=null && original!=target) throw NumberStoreException("duplicate")
            if(original!=null) {
                if(db.update("numbers",values,"phone=?",arrayOf(original))!=1) throw NumberStoreException("missing")
            } else {
                capacity(db); values.put("createdAt",System.currentTimeMillis()); db.insertOrThrow("numbers",null,values)
            }
            db.setTransactionSuccessful()
        } finally { db.endTransaction() }
    }
    fun delete(phone: String) { writableDatabase.delete("numbers","phone=?",arrayOf(phone)) }
    fun report(data: Map<String, Any?>) {
        val phone=phone(data["phone"]); val category=category(data["category"]); val note=text(data["note"],500)
        if(category=="unknown") throw NumberStoreException("invalid")
        val db=writableDatabase; db.beginTransaction()
        try {
            if(find(phone)==null) {
                capacity(db)
                db.insertOrThrow("numbers",null,values(mapOf("phone" to phone,"rule" to "watch","category" to category)).apply {put("createdAt",System.currentTimeMillis())})
            }
            db.insertOrThrow("reports",null,ContentValues().apply {put("phone",phone);put("category",category);put("note",note);put("createdAt",System.currentTimeMillis())})
            db.update("numbers",ContentValues().apply {put("updatedAt",System.currentTimeMillis())},"phone=?",arrayOf(phone))
            db.setTransactionSuccessful()
        } finally { db.endTransaction() }
    }
    fun reports(phone: String): List<Map<String, Any>> = readableDatabase.rawQuery("SELECT * FROM reports WHERE phone=? ORDER BY createdAt DESC,id DESC LIMIT 100",arrayOf(phone)).use { c ->
        buildList { while(c.moveToNext()) add(mapOf("id" to c.getLong(0),"phone" to c.getString(1),"category" to c.getString(2),"note" to c.getString(3),"createdAt" to c.getLong(4))) }
    }
    fun deleteReport(id: Long) { writableDatabase.delete("reports","id=?",arrayOf(id.toString())) }
    fun importNumbers(items: List<Map<String, Any?>>, restoreRules: Boolean): Map<String, Int> {
        if(items.size>5000) throw NumberStoreException("limit")
        // Validate the complete batch before making any mutation.
        val validated=items.map { values(it,restoreRules) }
        val db=writableDatabase; var added=0;var skipped=0; db.beginTransaction()
        try {
            for(value in validated) {
                if(find(value.getAsString("phone"))!=null) {skipped++;continue}
                capacity(db); value.put("createdAt",System.currentTimeMillis()); db.insertOrThrow("numbers",null,value);added++
            }
            db.setTransactionSuccessful()
        } finally {db.endTransaction()}
        return mapOf("added" to added,"skipped" to skipped)
    }
    companion object {
        @Volatile private var instance: NumberDatabase?=null
        fun get(context: Context): NumberDatabase = instance ?: synchronized(this) {
            instance ?: NumberDatabase(context.applicationContext).also { instance=it }
        }
    }
}
