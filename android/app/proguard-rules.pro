# flutter_local_notifications 18.0.1 uses anonymous Gson TypeToken subclasses
# when reading scheduled notifications. R8 full mode otherwise erases their
# generic superclass, causing cancellation/scheduling to throw in release APKs.
# Keep both endpoints of the generic signature and their class hierarchy.
-keepattributes Signature
-keep,allowobfuscation class com.google.gson.reflect.TypeToken { *; }
-keep,allowobfuscation class * extends com.google.gson.reflect.TypeToken { *; }
