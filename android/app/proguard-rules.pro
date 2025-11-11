# Copyright (C) 2025 Nguyen Duy Thanh (@Nekkochan0x0007). All right reserved

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Your app
-keep class com.nekkochan.tlucalendar.** { *; }

# Keep Play Core classes used by Flutter
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }

# Prevent R8 from removing Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Suppress missing class warnings
-dontwarn com.google.android.play.core.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Common Android
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
    void set*(***);
    *** get*();
}

# Performance Optimizations (Safe additions)
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove debug logs in release (Safe)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# Keep Parcelables (Safe - for data transfer)
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Memory optimizations (Safe)
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# Safe class loading optimizations
-keepattributes Signature
-keepattributes Exceptions

# Remove kotlin metadata annotations (Safe - reduces size)
-dontwarn kotlin.reflect.jvm.internal.**

# XML handling (fix for R8 missing classes)
-dontwarn javax.xml.stream.**
-dontwarn org.apache.tika.**
-dontwarn java.beans.**
-dontwarn javax.xml.**
-keep class javax.xml.stream.** { *; }
