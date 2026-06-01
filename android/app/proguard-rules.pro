# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Riverpod / Dart interop
-keep class com.google.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# File picker / saver
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep all model classes (adjust package if needed)
-keep class com.business360.ecashbook_app.** { *; }

# General rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn **
