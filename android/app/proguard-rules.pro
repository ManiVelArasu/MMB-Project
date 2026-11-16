# ---------------------------------------------------------------
# Flutter + plugins (shared_preferences, path_provider, image_picker, etc.)
# ---------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class androidx.datastore.** { *; }
-dontwarn io.flutter.**

# ---------------------------------------------------------------
# Razorpay
# ---------------------------------------------------------------
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*
-dontwarn proguard.annotation.**

# ---------------------------------------------------------------
# Google ML Kit (selfie segmentation / background remover)
# ---------------------------------------------------------------
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ---------------------------------------------------------------
# FFmpeg kit
# ---------------------------------------------------------------
-keep class com.arthenica.** { *; }
-keep class com.antonkarpenko.** { *; }
-dontwarn com.arthenica.**

# ---------------------------------------------------------------
# Google Play services (auth)
# ---------------------------------------------------------------
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ---------------------------------------------------------------
# uCrop (image_cropper)
# ---------------------------------------------------------------
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**