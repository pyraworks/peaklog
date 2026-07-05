# ffmpeg_kit_flutter_new's AbiDetect class exposes native methods (getNativeAbi,
# getNativeCpuAbi, isNativeLTSBuild, getNativeBuildConf) that are only bound via
# JNI RegisterNatives() from libffmpegkit_abidetect.so, not called from any Java/
# Kotlin/Dart code R8 can see. Without a keep rule R8 strips them as dead code,
# RegisterNatives() then fails at startup, and GeneratedPluginRegistrant's
# registration loop aborts before registering every plugin listed after
# ffmpeg_kit_flutter_new (sqflite, url_launcher, package_info_plus, ...).
# https://github.com/sk3llo/ffmpeg_kit_flutter/issues/124
-keep class com.antonkarpenko.ffmpegkit.** { *; }
