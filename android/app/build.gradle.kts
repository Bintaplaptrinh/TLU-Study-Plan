// Copyright (C) 2025 Nguyen Duy Thanh (@Nekkochan0x0007). All right reserved

plugins {
    id("com.mikepenz.aboutlibraries.plugin")
    id("com.mikepenz.aboutlibraries.plugin.android")
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.tlu.studyplanner"
    compileSdk = 34

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tlu.studyplanner"
        minSdk = 21
        targetSdk = 34
        versionCode = 2025110220
        versionName = "1.0.0"

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    buildFeatures {
        buildConfig = true
        compose = true
    }

    // Signing configuration for release builds
    val keystoreFile = rootProject.file("rel.jks")

    if (keystoreFile.exists()) {
        signingConfigs {
            create("release") {
                storeFile = keystoreFile
                storePassword = System.getenv("STORE_PASSWORD") ?: ""
                keyAlias = System.getenv("KEY_ALIAS") ?: ""
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
        release {
            if (keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
    }
}

dependencies {
    // Flutter Embedding
    debugImplementation("io.flutter:flutter_embedding_debug:1.0.0-e7978291e77b97c8a74c153842c1d0defa1a8112")
    releaseImplementation("io.flutter:flutter_embedding_release:1.0.0-e7978291e77b97c8a74c153842c1d0defa1a8112")

    // Manually added Flutter plugin native dependencies
    implementation("com.dexterous.flutterlocalnotifications:flutter_local_notifications:17.1.2")
    implementation("dev.fluttercommunity.plus.androidalarmmanager:android_alarm_manager_plus:5.0.2")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    implementation("androidx.activity:activity-compose:1.11.0")
    implementation("androidx.compose.ui:ui:1.9.4")
    implementation("androidx.compose.material3:material3:1.4.0")
    implementation("androidx.compose.material:material-icons-extended:1.7.8")
    implementation("androidx.compose.ui:ui-tooling-preview:1.9.4")
    debugImplementation("androidx.compose.ui:ui-tooling:1.9.4")

    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.appcompat:appcompat:1.7.1")

    implementation("com.mikepenz:aboutlibraries-core:13.1.0")
    implementation("com.mikepenz:aboutlibraries-compose-core:13.1.0")
    implementation("com.mikepenz:aboutlibraries-compose:13.1.0")
    implementation("com.mikepenz:aboutlibraries-compose-m3:13.1.0")
    implementation("com.mikepenz:aboutlibraries:13.1.0")
}
