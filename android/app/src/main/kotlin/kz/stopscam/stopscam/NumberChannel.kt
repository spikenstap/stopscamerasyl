package kz.stopscam.stopscam

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.util.concurrent.Executors

class NumberChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val files=Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result?=null
    private var exportText: String?=null
    private val db=NumberDatabase.get(activity)
    init {
        MethodChannel(messenger,"kz.stopscam/numbers",StandardMethodCodec.INSTANCE,messenger.makeBackgroundTaskQueue()).setMethodCallHandler { call,result ->
            try {
                when(call.method) {
                    "list" -> result.success(db.all())
                    "find" -> result.success(db.find(call.argument<String>("phone") ?: ""))
                    "save" -> { db.save(call.arguments as Map<String,Any?>); result.success(null) }
                    "delete" -> { db.delete(call.argument<String>("phone") ?: ""); result.success(null) }
                    "report" -> { db.report(call.arguments as Map<String,Any?>); result.success(null) }
                    "reports" -> result.success(db.reports(call.argument<String>("phone") ?: ""))
                    "deleteReport" -> { db.deleteReport((call.argument<Number>("id") ?: 0).toLong()); result.success(null) }
                    "import" -> result.success(db.importNumbers(call.argument<List<Map<String,Any?>>>("items") ?: emptyList(),call.argument<Boolean>("restoreRules")==true))
                    "pickImport", "export" -> activity.runOnUiThread {
                        if(pending!=null) result.error("busy","Document operation pending",null)
                        else {
                            pending=result
                            try {
                                val exporting=call.method=="export"
                                exportText=if(exporting)call.argument<String>("csv") else null
                                if((exportText?.toByteArray(Charsets.UTF_8)?.size ?: 0)>8*1024*1024)throw NumberStoreException("limit")
                                val intent=Intent(if(exporting)Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type=if(exporting)"text/csv" else "*/*"
                                    if(exporting)putExtra(Intent.EXTRA_TITLE,"StopScam-numbers.csv")
                                }
                                activity.startActivityForResult(intent,if(exporting)712 else 711)
                            }catch(_:Exception){pending=null;exportText=null;result.error("io","Document picker unavailable",null)}
                        }
                    }
                    else -> result.notImplemented()
                }
            }catch(e:NumberStoreException){result.error(e.code,"Number operation failed",null)}
            catch(_:Exception){result.error("storage","Number storage failed",null)}
        }
    }
    fun onResult(request: Int, code: Int, data: Intent?): Boolean {
        if(request!=711 && request!=712)return false
        val result=pending ?: return true
        val csv=exportText; pending=null;exportText=null
        val uri=data?.data
        if(code!=Activity.RESULT_OK || uri==null){result.success(if(request==712)false else null);return true}
        files.execute {
            try {
                if(request==712){
                    activity.contentResolver.openOutputStream(uri,"wt")?.use { it.write((csv ?: "").toByteArray(Charsets.UTF_8)) } ?: throw NumberStoreException("io")
                    result.success(true)
                }else{
                    val bytes=activity.contentResolver.openInputStream(uri)?.use { stream ->
                        val out=java.io.ByteArrayOutputStream();val buffer=ByteArray(8192)
                        while(true){val n=stream.read(buffer);if(n<0)break;if(out.size()+n>8*1024*1024)throw NumberStoreException("limit");out.write(buffer,0,n)}
                        out.toByteArray()
                    } ?: throw NumberStoreException("io")
                    val decoder=Charsets.UTF_8.newDecoder().onMalformedInput(java.nio.charset.CodingErrorAction.REPORT)
                    result.success(decoder.decode(java.nio.ByteBuffer.wrap(bytes)).toString())
                }
            }catch(e:NumberStoreException){result.error(e.code,"Document operation failed",null)}
            catch(_:Exception){result.error("io","Cannot read or write UTF-8 document",null)}
        }
        return true
    }
    fun dispose(){pending?.error("cancelled","Activity closed",null);pending=null;files.shutdown()}
}
