# ─── Flutter Embedding ───────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# ─── Firebase & Google Play Services ─────────────────────────────
# Allows R8 to obfuscate internal classes while preserving necessary entrypoints
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**

# ─── Firebase Crashlytics ────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ─── Razorpay ────────────────────────────────────────────────────
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}

# ─── SafeDevice (Root/Jailbreak detection) ───────────────────────
-keep class com.apparence.safe_device.** { *; }

# ─── General Reflection & Desugaring ─────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-dontwarn java.nio.file.*
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# ─── Google Play Core & ML Kit ───────────────────────────────────
-dontwarn com.google.android.play.core.**
-dontwarn com.google.mlkit.**

# ─── Flutter Local Notifications ─────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
