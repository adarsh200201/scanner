# Keep ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep Firebase/Play Services (defensive)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Google Play Core (SplitInstall/SplitCompat)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Keep Flutter plugins reflection
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.plugins.**
