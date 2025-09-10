plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.a"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Corrected to use Flutter's NDK version

    compileOptions {
        // ✅ Enables desugaring support
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.a"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion // Corrected to use Flutter's target SDK version
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Remove this line. Do not use the debug signing key for release builds.
            // signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Add desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

// ❌ This line is redundant. The plugin is already applied at the top.
// apply(plugin = "com.google.gms.google-services")