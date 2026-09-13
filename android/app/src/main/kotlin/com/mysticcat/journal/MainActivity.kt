package com.mysticcat.journal

import android.app.Activity
import android.app.KeyguardManager
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val requestCode = 7319
    private var pending: MethodChannel.Result? = null
    private var requestedSetting: Boolean? = null
    private val lockPrefs get() = getSharedPreferences("garden_privacy", MODE_PRIVATE)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updatePrivacy()
    }

    private fun updatePrivacy() {
        if (lockPrefs.getBoolean("enabled", false)) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "garden/app_lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> result.success(lockPrefs.getBoolean("enabled", false))
                    "authenticate" -> authenticate(result, null)
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled")
                        if (enabled == null) result.error("invalid-argument", null, null)
                        else authenticate(result, enabled)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // The OS verifies the credential. The app never receives or stores a PIN.
    @Suppress("DEPRECATION")
    private fun authenticate(result: MethodChannel.Result, setting: Boolean?) {
        if (pending != null) { result.error("busy", null, null); return }
        val manager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (!manager.isDeviceSecure) {
            result.error("no-device-lock", "휴대전화 설정에서 화면 잠금을 설정해 주세요.", null)
            return
        }
        val intent = manager.createConfirmDeviceCredentialIntent("마음냥 정원", "기록을 열려면 휴대전화 잠금을 확인해 주세요.")
        if (intent == null) { result.error("unavailable", null, null); return }
        pending = result
        requestedSetting = setting
        try { startActivityForResult(intent, requestCode) }
        catch (_: Exception) {
            pending = null
            requestedSetting = null
            result.error("unavailable", null, null)
        }
    }

    @Deprecated("Uses device credential confirmation for Android compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != this.requestCode) return
        val result = pending ?: return
        val setting = requestedSetting
        pending = null
        requestedSetting = null
        val accepted = resultCode == Activity.RESULT_OK
        if (accepted && setting != null) {
            if (!lockPrefs.edit().putBoolean("enabled", setting).commit()) {
                result.error("storage-failed", null, null)
                return
            }
            updatePrivacy()
        }
        result.success(accepted)
    }
}
