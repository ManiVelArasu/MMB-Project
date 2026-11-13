
# Preserve annotations used by libraries
-keepattributes *Annotation*

# Preserve generic signatures
-keepattributes Signature

# Preserve Flutter plugin registration and native entry points
-keep class io.flutter.plugins.** { *; }
