Place the official Android sing-box runtime here.

Preferred path:
- android/app/libs/libbox.aar

Alternative path if you only have native shared libraries:
- android/app/src/main/jniLibs/arm64-v8a/libbox.so
- android/app/src/main/jniLibs/armeabi-v7a/libbox.so
- android/app/src/main/jniLibs/x86_64/libbox.so

After adding the runtime, merge the Gradle snippet from:
- docs/runtime/HOST_PROJECT_MERGE_SNIPPETS.md
