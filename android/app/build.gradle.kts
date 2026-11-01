import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing credentials come from android/key.properties (git-ignored) or,
// if that file is absent, from environment variables. Never hard-code them here.
// See docs/release/UPLOAD_KEY_SETUP.md.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    FileInputStream(keyPropertiesFile).use { keyProperties.load(it) }
}

fun signingValue(property: String, env: String): String? =
    keyProperties.getProperty(property) ?: System.getenv(env)

val releaseStoreFile = signingValue("storeFile", "BTC_UPLOAD_STORE_FILE")
val hasReleaseSigning = releaseStoreFile != null

android {
    namespace = "ge.cartographers.btk_field_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "ge.cartographers.btk_field_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = signingValue("storePassword", "BTC_UPLOAD_STORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "BTC_UPLOAD_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "BTC_UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // No silent fallback to the debug key: an unsigned/debug-signed
            // release must never reach Google Play.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Fail release builds early when no upload key is configured; debug builds are unaffected.
gradle.taskGraph.whenReady {
    val releaseTask = allTasks.any {
        it.project == project && it.name.contains("Release") &&
            (it.name.startsWith("bundle") || it.name.startsWith("assemble") || it.name.startsWith("package"))
    }
    if (releaseTask && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Create android/key.properties or set " +
                "BTC_UPLOAD_* environment variables (see docs/release/UPLOAD_KEY_SETUP.md)."
        )
    }
}

flutter {
    source = "../.."
}
