# Host project merge snippets

This starter does not include generated Flutter host build files, so after:

```bash
flutter create . --platforms=android,ios
```

merge the snippets below into the generated host project.

## Android Manifest meta-data

Add inside `<application>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.example.inet_app.SINGBOX_BINDING_CLASS"
    android:value="com.example.inet_app.vpn.libbox.LibboxSingBoxBinding" />
<meta-data
    android:name="com.example.inet_app.SINGBOX_RUNTIME_FACTORY_CLASS"
    android:value="com.example.inet_app.vpn.libbox.LibboxRuntimeFactory" />
```

## Android Gradle (Groovy)

Add `flatDir` repository and AAR dependency if you place `libbox.aar` into `android/app/libs`:

```groovy
repositories {
    flatDir {
        dirs 'libs'
    }
}

dependencies {
    implementation(name: 'libbox', ext: 'aar')
}
```

If your project uses `packagingOptions`, make sure native `.so` files are not excluded.

## Android Gradle (Kotlin DSL)

```kotlin
repositories {
    flatDir {
        dirs("libs")
    }
}

dependencies {
    implementation(name = "libbox", ext = "aar")
}
```

## Android native library fallback

If you do not use an AAR, copy `.so` files to:

```text
android/app/src/main/jniLibs/arm64-v8a/libbox.so
android/app/src/main/jniLibs/armeabi-v7a/libbox.so
android/app/src/main/jniLibs/x86_64/libbox.so
```

## iOS PacketTunnel Info.plist

Add to `ios/PacketTunnel/Info.plist`:

```xml
<key>SINGBOX_RUNTIME_FACTORY_CLASS</key>
<string>PacketTunnel.LibboxRuntimeFactory</string>
```

## iOS Xcode linking checklist

1. Add `ios/Frameworks/Libbox.xcframework` to the Xcode project.
2. Link it to the `PacketTunnel` target.
3. Ensure `PacketTunnel.entitlements` includes `packet-tunnel-provider`.
4. Verify the Packet Tunnel extension target can see:
   - `LibboxRuntimeFactory.swift`
   - `OfficialLibboxAppleRuntime.swift`
5. Finish the adapter in `ios/PacketTunnel/libbox/runtime/OfficialLibboxAppleRuntime.swift`.
