# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Moscapsule is a **Swift wrapper around the Mosquitto C MQTT client library** (v1.4.8 embedded). It exposes a Swift-native API for MQTT 3.1/3.1.1 publish-subscribe messaging on iOS with full TLS/SSL and certificate support.

## Build & Test

```bash
# Build via SPM
swift build

# Build the Xcode framework
xcodebuild build -scheme Moscapsule -sdk iphonesimulator

# Run all tests via SPM
swift test

# Run all tests via Xcode
xcodebuild test -scheme Moscapsule -destination 'platform=iOS Simulator,name=iPhone 17'

# Run a single test
xcodebuild test -scheme Moscapsule \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MoscapsuleTests/MoscapsuleTests/testPublishAndSubscribe

# List SPM tests
swift test list
```

**Test caveat:** All tests are integration tests against `test.mosquitto.org`. When the broker is unreachable, all 10 tests skip gracefully via `XCTSkipUnless` — no failures. `test.mosquitto.org:1883` is blocked on many corporate/home networks; skips are normal. Both `swift test` and `xcodebuild test` behave identically.

**SPM warning (benign):** `swift test` emits "unhandled file" warnings for `Info.plist` in `MoscapsuleTests/` and `Moscapsule/`. Safe to ignore — they don't affect the build or test run.

## Architecture

### Three-Layer Bridge

The core pattern is a **Swift → Objective-C → C** call chain:

1. **`Moscapsule.swift`** — Public Swift API (`MQTTClient`, `MQTTConfig`, `MQTT` factory, all structs/enums)
2. **`MosquittoCallbackBridge.{h,m}`** — Objective-C bridge that receives C function callbacks from Mosquitto and forwards them to Swift closures via `__bridge` casts
3. **`mosquitto/lib/`** — Embedded Mosquitto C source, compiled with `-DWITH_THREADING -DWITH_TLS -DWITH_TLS_PSK`

### Key Classes

| Name | Role |
|------|------|
| `MQTT` | Factory — creates `MQTTClient` via `newConnection(_:connectImmediately:)` |
| `MQTTClient` | Main client; serializes all ops on a single `OperationQueue` (maxConcurrentOperationCount=1) |
| `MQTTConfig` | Configuration + callback closures (set before creating client) |
| `__MosquittoContext` | Internal ObjC object; passed as `void*` userdata through Mosquitto C callbacks |

### Initialization Requirement

`moscapsule_init()` **must be called once** before any SSL/TLS operations. `moscapsule_cleanup()` on teardown. The test suite calls this in `setUpWithError()` with a guard flag (skipped when broker is unreachable).

### Callback Pattern

Callbacks are set on `MQTTConfig` before passing to `MQTT.newConnection()`:

```swift
mqttConfig.onConnectCallback = { returnCode in ... }
mqttConfig.onMessageCallback = { mqttMessage in ... }
```

The ObjC bridge captures the Swift closure via `__bridge` and invokes it from the C callback thread.

## Dependencies

- **OpenSSL-Package** `≥ 3.3.2000` (SPM) — provides TLS support
- **OpenSSL-Universal** `~> 3.3` (CocoaPods) — provides TLS support
- **OpenSSL-Package** git submodule (`submodules/OpenSSL/`) — for manual Xcode integration
- **Mosquitto** — embedded C source in `mosquitto/lib/` (not a Pod dependency)

## CocoaPods

The podspec (`Moscapsule.podspec`) compiles both `Moscapsule/` and `mosquitto/lib/` C sources together into one pod. The `xcconfig` sets `SWIFT_VERSION` and the required Mosquitto compile flags.

Consumers install via:
```ruby
pod 'Moscapsule', :git => 'https://github.com/flightonary/Moscapsule.git'
```
