package com.soft.anyi

import android.app.ActivityManager
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 设备能力通道（供全局玻璃的自动降级使用）
 *
 * channel = com.soft.anyi/device
 *   sdkInt     -> Android API 级别
 *   totalRamMb -> 总内存（MB，失败 0）
 *   lowRam     -> 系统认定的低内存设备
 *
 * ★ 只读、无副作用；异常一律返回 0/false，Dart 侧自行兜底。
 */
object DeviceInfoBridge {
    const val CHANNEL = "com.soft.anyi/device"

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "sdkInt" -> result.success(android.os.Build.VERSION.SDK_INT)
                    "totalRamMb" -> result.success(totalRamMb(context))
                    "lowRam" -> result.success(isLowRam(context))
                    // ★ 1029：下载失败上报要真实剩余空间，原来 Dart 侧算出来恒为 0，后台误判「存储不足」
                    "freeMb" -> result.success(freeMb())
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                // ★ 1029：freeMb 失败必须回 -1（未知），回 0 会被当成「空间耗尽」
                result.success(if (call.method == "freeMb") -1 else 0)
            }
        }
    }

    private fun totalRamMb(context: Context): Int = try {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        (info.totalMem / (1024 * 1024)).toInt()
    } catch (e: Throwable) { 0 }

    /** 可用存储（MB）。用 /data 分区，Android 11+ 也能拿到；失败返回 -1 表示未知。 */
    private fun freeMb(): Int = try {
        val st = android.os.StatFs(android.os.Environment.getDataDirectory().absolutePath)
        (st.availableBytes / (1024 * 1024)).toInt()
    } catch (e: Throwable) { -1 }

    private fun isLowRam(context: Context): Boolean = try {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        am.isLowRamDevice
    } catch (e: Throwable) { false }
}
