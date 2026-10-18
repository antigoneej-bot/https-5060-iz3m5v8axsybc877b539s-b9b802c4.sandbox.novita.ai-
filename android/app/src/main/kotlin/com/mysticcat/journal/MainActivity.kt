package com.mysticcat.journal

import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
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
        val playbackChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "garden/background_audio")
        MeditationPlaybackService.command = { name -> playbackChannel.invokeMethod(name, null) }
        playbackChannel.setMethodCallHandler { call, result ->
            try {
                val service = Intent(this, MeditationPlaybackService::class.java)
                when (call.method) {
                    "start" -> {
                        if (android.os.Build.VERSION.SDK_INT >= 26) startForegroundService(service)
                        else startService(service)
                        result.success(null)
                    }
                    "update" -> {
                        MeditationPlaybackService.instance?.update(
                            call.argument<String>("title") ?: "마음냥 정원 명상",
                            call.argument<Boolean>("playing") ?: false,
                            call.argument<Number>("position")?.toLong() ?: 0L,
                            call.argument<Number>("duration")?.toLong() ?: 0L,
                            call.argument<Number>("speed")?.toFloat() ?: 1f)
                        result.success(null)
                    }
                    "stop" -> { stopService(service); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("playback-service", e.message, null) }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "garden/install_referrer")
            .setMethodCallHandler { call, result ->
                if (call.method == "read") readPostcardReferrer(result)
                else result.notImplemented()
            }
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
        // ⚠️ QA 전용: App Check 디버그 프로바이더가 생성한 기기별 시크릿을
        // 화면에서 바로 확인할 수 있게 읽어온다. 이 채널은 Play 스토어를
        // 거치지 않는 사이드로딩 테스트 APK에서만 사용되며, 값 자체는
        // Firebase App Check의 "디버그 토큰" 허용 목록에만 쓰인다.
        // (com.google.firebase:firebase-appcheck-debug의 StorageHelper가
        // 저장하는 위치("com.google.firebase.appcheck.debug.store.<persistenceKey>")와
        // 키("com.google.firebase.appcheck.debug.DEBUG_SECRET")를 그대로 읽되,
        // persistenceKey는 추측하지 않고 FirebaseApp에서 직접 조회한다.)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "garden/app_check_debug")
            .setMethodCallHandler { call, result ->
                if (call.method == "readSecret") {
                    try {
                        val persistenceKey = com.google.firebase.FirebaseApp.getInstance().persistenceKey
                        val prefs = getSharedPreferences(
                            "com.google.firebase.appcheck.debug.store.$persistenceKey",
                            MODE_PRIVATE,
                        )
                        result.success(prefs.getString("com.google.firebase.appcheck.debug.DEBUG_SECRET", null))
                    } catch (e: Exception) {
                        result.error("read-failed", e.message, null)
                    }
                } else result.notImplemented()
            }
    }

    private fun readPostcardReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(applicationContext).build()
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        fun finish(source: String?) {
            // All calls arrive through this main-thread handler.
            if (finished) return
            finished = true
            handler.removeCallbacksAndMessages(null)
            try { client.endConnection() } catch (_: Exception) { }
            result.success(source)
        }
        handler.postDelayed({ finish(null) }, 5000)
        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    handler.post {
                        if (!finished) {
                            if (responseCode != InstallReferrerClient.InstallReferrerResponse.OK) {
                                finish(null)
                            } else {
                                try {
                                    val params = Uri.parse("https://referrer.invalid/?" + client.installReferrer.installReferrer)
                                    val matches = params.getQueryParameter("utm_source") == "garden_postcard" &&
                                        params.getQueryParameter("utm_medium") == "share" &&
                                        params.getQueryParameter("utm_campaign") == "garden_v1"
                                    finish(if (matches) "garden_postcard" else "other")
                                } catch (_: Exception) { finish(null) }
                            }
                        }
                    }
                }
                override fun onInstallReferrerServiceDisconnected() {
                    handler.post { finish(null) }
                }
            })
        } catch (_: Exception) { finish(null) }
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
