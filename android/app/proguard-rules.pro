# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.firebase.** { *; }

# Firebase
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes *Annotation*

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.analytics.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Hive
-keep class com.hive.** { *; }
-keep class hive.** { *; }

# Prevent warnings
-dontwarn io.flutter.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.baseflow.geolocator.**
-dontwarn com.baseflow.geocoding.**

# Essential Packages
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class io.flutter.plugins.googlemaps.** { *; }

# Kotlin Coroutines & Metadata (Often needed)
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }

# AndroidX Activity & Core (for edge-to-edge)
-keep class androidx.activity.** { *; }
-keep class androidx.core.view.** { *; }
-keep interface androidx.activity.** { *; }
-keep interface androidx.core.view.** { *; }
