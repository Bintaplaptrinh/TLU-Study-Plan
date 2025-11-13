dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Add Flutter's Maven repository
        maven { url = uri("https://storage.googleapis.com/flutter_infra_release/flutter/maven") }
    }
}

plugins {
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0" apply false
    id("com.mikepenz.aboutlibraries.plugin") version "13.1.0" apply false
    id("com.mikepenz.aboutlibraries.plugin.android") version "13.1.0" apply false
}

include(":app")
