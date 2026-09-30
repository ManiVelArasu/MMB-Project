plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mobile.mmb.project_mmb"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Add this lint block
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mobile.mmb.project_mmb"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Google ML Kit
    implementation(
        "com.google.mlkit:segmentation-selfie:16.0.0-beta6"
    )

    // Kotlin Coroutines
    implementation(
        "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
    )

    // SmartAuth / Google Credentials API
    implementation(
        "com.google.android.gms:play-services-auth:21.4.0"
    )
}