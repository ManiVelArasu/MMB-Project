
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// --------------------------------------------------
// Keystore Configuration
// --------------------------------------------------

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val hasReleaseKey = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword"
).all {
    !keystoreProperties.getProperty(it).isNullOrBlank()
}

// --------------------------------------------------
// Android Configuration
// --------------------------------------------------

android {
    namespace = "com.mobile.mmb.project_mmb"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

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

        ndk {
            abiFilters += listOf(
                "armeabi-v7a",
                "arm64-v8a"
            )
        }
    }

    // Native Library Optimization
    packaging {
        jniLibs {
            excludes += setOf(
                "lib/x86/**",
                "lib/x86_64/**"
            )
        }
    }

    // --------------------------------------------------
    // Signing Configuration
    // --------------------------------------------------

    signingConfigs {
        create("release") {
            if (hasReleaseKey) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")

                storeFile = file(
                    keystoreProperties.getProperty("storeFile")
                )
            }
        }
    }

    // --------------------------------------------------
    // Build Types
    // --------------------------------------------------

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Android code optimization
            isMinifyEnabled = true

            // Remove unused Android resources
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            )
        }
    }

    // --------------------------------------------------
    // Kotlin Configuration
    // --------------------------------------------------

    kotlin {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }
}

// --------------------------------------------------
// Flutter Configuration
// --------------------------------------------------

flutter {
    source = "../.."
}

// --------------------------------------------------
// Dependencies
// --------------------------------------------------

dependencies {

    // Google ML Kit Selfie Segmentation
    implementation(
        "com.google.mlkit:segmentation-selfie:16.0.0-beta6"
    )

    // Kotlin Coroutines
    implementation(
        "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
    )

    // Google Play Services Authentication
    implementation(
        "com.google.android.gms:play-services-auth:20.5.0"
    )
}
