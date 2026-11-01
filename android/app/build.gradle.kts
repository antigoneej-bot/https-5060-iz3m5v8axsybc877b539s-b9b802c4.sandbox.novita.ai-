// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties
import java.io.FileInputStream
import java.util.Base64
import java.net.URI

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
// Use the same public IDs for native manifest and Dart. This also protects
// manual `flutter build` calls from mismatched app/banner configurations.
val adDefines = (providers.gradleProperty("dart-defines").orNull ?: "")
    .split(",").filter { it.isNotBlank() }.mapNotNull {
        val decoded = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
        val pair = decoded.split("=", limit = 2)
        if (pair.size == 2) pair[0] to pair[1] else null
    }.toMap()
if (adDefines["RELEASE_ENV"] == "production") {
    for (flag in listOf("UNLOCK_ALL_PREMIUM", "APP_CHECK_DEBUG_PROVIDER", "TEST_SHOW_ONBOARDING", "ADMOB_TEST_ADS")) {
        require(adDefines[flag] != "true") { "Production build rejects test flag: $flag" }
    }
    for (key in listOf("PRIVACY_OPERATOR", "PRIVACY_CONTACT", "PRIVACY_POLICY_URL", "ACCOUNT_DELETION_URL")) {
        require(!adDefines[key].isNullOrBlank()) { "Verified release configuration required: $key" }
    }
    for (key in listOf("PRIVACY_POLICY_URL", "ACCOUNT_DELETION_URL", "GARDEN_BACKEND_URL", "SOCIAL_AUTH_URL")) {
        val uri = URI(adDefines[key] ?: "")
        require(uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo == null) { "HTTPS URL required: $key" }
    }
}
val testAdAppId = "ca-app-pub-3940256099942544~3347511713"
val adTestMode = adDefines["ADMOB_TEST_ADS"] == "true"
val adAppId = adDefines["ADMOB_ANDROID_APP_ID"] ?: ""
val adBannerId = adDefines["ADMOB_ANDROID_BANNER_ID"] ?: ""
if (!adTestMode && (adAppId.isNotEmpty() || adBannerId.isNotEmpty())) {
    val appMatch = Regex("^ca-app-pub-([0-9]{16})~[0-9]{10}$").matchEntire(adAppId)
    val bannerMatch = Regex("^ca-app-pub-([0-9]{16})/[0-9]{10}$").matchEntire(adBannerId)
    require(appMatch != null && bannerMatch != null &&
        appMatch.groupValues[1] == bannerMatch.groupValues[1] &&
        appMatch.groupValues[1] != "3940256099942544") {
        "Provide matching ADMOB_ANDROID_APP_ID and ADMOB_ANDROID_BANNER_ID, or explicitly use ADMOB_TEST_ADS=true."
    }
}
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mysticcat.journal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mysticcat.journal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] =
            if (adTestMode || adAppId.isEmpty()) testAdAppId else adAppId
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["admobAppId"] = testAdAppId
            applicationIdSuffix = ".preview"
            versionNameSuffix = "-test"
        }
        release {
            // flutter_local_notifications reads its cached schedules through
            // Gson TypeToken; retain its generic signatures in R8 release builds.
            proguardFiles("proguard-rules.pro")
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null // Never sign a release artifact with the debug key.
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.android.installreferrer:installreferrer:2.2")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Needed to read FirebaseApp.getInstance().persistenceKey from native code
    // (garden/app_check_debug channel). Version is already resolved
    // transitively via the firebase_core Flutter plugin; pinning here avoids
    // relying on that transitive classpath for a direct Kotlin import.
    implementation("com.google.firebase:firebase-common:21.0.0")
}


// Preview installs alongside the store app. Firebase is explicitly initialized
// from Dart options; the store-only google-services client has a different id.
tasks.matching { it.name == "processDebugGoogleServices" }.configureEach {
    enabled = false
}
