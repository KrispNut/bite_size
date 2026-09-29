plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Push needs Firebase, and Firebase needs the google-services.json from the
// Firebase console (Project settings → Your apps → com.bootlegcorp.bitesize).
// Without it the plugin would fail the build outright; with this guard the
// app builds and runs, PushService just reports push as off.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn("bite_size: android/app/google-services.json missing — building without push")
}

android {
    namespace = "com.bootlegcorp.bitesize"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "34.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bootlegcorp.bitesize"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

