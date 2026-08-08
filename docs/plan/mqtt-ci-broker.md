# Reliable MQTT Testing: Docker/CI Broker

## Overview

The current test suite uses `XCTSkip` to gracefully handle `test.mosquitto.org`
being unreachable. This document describes what is needed to make the suite
always-green by running a local Mosquitto broker — the natural next step for CI.

## Why

- `test.mosquitto.org` has no SLA; port 1883 is blocked on many networks
- CI pipelines need deterministic pass/fail, not conditional skips
- A local broker runs in milliseconds vs. multi-second network sleeps

## What changes

### 1. Test host (env-var configurable)

Replace the hard-coded hostname with an environment variable with fallback:

```swift
let testHost = ProcessInfo.processInfo.environment["MQTT_TEST_HOST"] ?? "127.0.0.1"
let testPort = Int32(ProcessInfo.processInfo.environment["MQTT_TEST_PORT"] ?? "1883") ?? 1883
```

Remove (or convert to a "skip if Docker not running" guard) the `isBrokerReachable()` check.

Default (`127.0.0.1`) makes CI green with no configuration. Developers who want
to test against the real broker set `MQTT_TEST_HOST=test.mosquitto.org`.

### 2. Local dev (Homebrew)

```bash
brew install mosquitto
brew services start mosquitto    # listens on 127.0.0.1:1883, no auth
```

### 3. Docker Compose (local + CI parity)

Create `docker-compose.mqtt.yml`:

```yaml
version: '3'
services:
  mosquitto:
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
    volumes:
      - ./mosquitto/config:/mosquitto/config:ro
```

Create `mosquitto/config/mosquitto.conf`:

```
listener 1883
allow_anonymous true
```

Run: `docker compose -f docker-compose.mqtt.yml up -d`

### 4. GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  swift-test:
    runs-on: macos-latest
    services:
      mosquitto:
        image: eclipse-mosquitto:2
        ports:
          - 1883:1883
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: swift test
        run: swift test
```

GitHub Actions `services:` runs the container on the same network as the runner,
so `127.0.0.1:1883` is reachable without extra configuration.

### 5. TLS test (port 8883)

`testServerCertificate` requires a TLS-enabled broker. Two options:

**Option A — Skip in CI (easiest)**

Guard the test with an env var:

```swift
func testServerCertificate() throws {
    try XCTSkipUnless(ProcessInfo.processInfo.environment["MQTT_TLS_ENABLED"] == "1",
                      "TLS broker not configured — set MQTT_TLS_ENABLED=1 to run")
    // ... existing test body ...
}
```

**Option B — Self-signed certs (full coverage)**

Generate a CA and server cert for `127.0.0.1` (one-time):

```bash
mkdir -p mosquitto/certs

# CA
openssl genrsa -out mosquitto/certs/ca.key 2048
openssl req -new -x509 -days 3650 -key mosquitto/certs/ca.key \
  -out mosquitto/certs/ca.crt -subj "/CN=MoscapsuleTestCA"

# Server cert for localhost
openssl genrsa -out mosquitto/certs/server.key 2048
openssl req -new -key mosquitto/certs/server.key \
  -out mosquitto/certs/server.csr -subj "/CN=127.0.0.1"
openssl x509 -req -days 3650 -in mosquitto/certs/server.csr \
  -CA mosquitto/certs/ca.crt -CAkey mosquitto/certs/ca.key \
  -CAcreateserial -out mosquitto/certs/server.crt

# Update test bundle with local CA cert
cp mosquitto/certs/ca.crt MoscapsuleTests/cert.bundle/mosquitto.org.crt
```

Updated `mosquitto/config/mosquitto.conf`:

```
listener 1883
allow_anonymous true

listener 8883
cafile /mosquitto/config/ca.crt
certfile /mosquitto/config/server.crt
keyfile /mosquitto/config/server.key
allow_anonymous true
```

The generated certs are **not secrets** (test-only, self-signed) — commit them.

## Effort estimate

| Scope | Effort |
|-------|--------|
| Plain MQTT on 127.0.0.1 (ports 1883) | ~2 h |
| GitHub Actions CI workflow | ~1 h |
| TLS (port 8883) with self-signed certs | +2 h |
