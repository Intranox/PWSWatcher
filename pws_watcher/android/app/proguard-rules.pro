# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# okhttp3: Conscrypt is optional at runtime
-dontwarn org.conscrypt.**
-dontwarn okhttp3.internal.platform.ConscryptPlatform
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# colorpicker optional dep
-dontwarn top.defaults.checkerboarddrawable.**

# Google Play Core (referenced by Flutter internals but not used in this app)
-dontwarn com.google.android.play.core.**
