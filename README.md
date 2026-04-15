# Flutter password cracker (Rust)

A proof-of-concept app that demonstrates native Rust integration for CPU-intensive cryptographic tasks, with real-time streaming updates back to the Flutter UI.

(เป็นแอปตัวอย่างการผสานรวม Rust เพื่อประมวลผลงาน Crypto ที่ใช้ CPU สูง พร้อมส่งข้อมูลแบบ Real-time กลับมายัง UI)

---

## Features

- **SHA-256 hashing** — synchronous Rust call via FFI, returns instantly
  (การ Hash SHA-256 ผ่าน Rust FFI ทำงานได้รวดเร็วทันที)
- **Brute-force cracker** — exhaustive search over `a–z` charset up to a given length
  (การถอดรหัสแบบ Brute-force ค้นหาตัวอักษร `a–z` ตามความยาวที่กำหนด)
- **Real-time streaming** — `StreamSink<CrackProgress>` pipes live updates from Rust to Dart
  (การส่งข้อมูลแบบ Real-time จาก Rust มายัง Dart)
- **Multithreaded** — `rayon` thread pool uses all available CPU cores automatically
  (รองรับ Multithread โดยใช้ CPU ทุก Core อัตโนมัติด้วย `rayon`)
- **Responsive UI** — Rust runs on its own threads; Flutter main isolate is never blocked
  (UI ลื่นไหล เพราะ Rust ทำงานแยก Thread ทำให้ Main Isolate ของ Flutter ไม่ถูกขัดจังหวะ)
- **Live terminal log** — shows current guess, attempt count, and hash rate as they happen
  (แสดง Log ทั้งรหัสที่กำลังสุ่ม, จำนวนครั้ง และความเร็วในการ Hash)

---

## Tech Stack

| Layer       | Technology                  |
|-------------|-----------------------------|
| UI          | Flutter (Dart)              |
| Bridge      | flutter_rust_bridge v2      |
| Hashing     | Rust · `sha2` crate         |
| Parallelism | Rust · `rayon` crate        |
| FFI         | Rust `cdylib` + `staticlib` |

---

## Project Structure

```
flutter_password_cracker/
│
├── lib/
│   ├── main.dart                        # App entry point, RustLib.init()
│   ├── screens/
│   │   └── crack_screen.dart            # Main UI screen
│   ├── widgets/
│   │   └── crack_progress_widget.dart   # Live stats + terminal log
│   └── src/
│       └── rust/
│           ├── frb_generated.dart       # Auto-generated bridge (do not edit)
│           ├── frb_generated.io.dart    # Native platform impl
│           └── frb_generated.web.dart  # Web platform impl
│
├── rust/
│   ├── Cargo.toml                       # Rust dependencies
│   └── src/
│       ├── lib.rs                       # Crate root, exposes `api` module
│       ├── api/
│       │   └── mod.rs                   # Public bridge functions
│       └── frb_generated.rs            # Auto-generated Rust glue (do not edit)
│
├── flutter_rust_bridge.yaml            # Codegen config
├── pubspec.yaml                        # Flutter dependencies
└── README.md
```

---

## Setup

### Prerequisites

| Tool                        | Install                                                           |
|-----------------------------|-------------------------------------------------------------------|
| Flutter SDK                 | https://flutter.dev/docs/get-started/install                      |
| Rust + Cargo                | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| flutter_rust_bridge_codegen | `cargo install flutter_rust_bridge_codegen`                       |
| cargo-ndk (Android)         | `cargo install cargo-ndk`                                         |

Make sure Cargo's bin directory is on your PATH:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
# Add to ~/.zshrc or ~/.bashrc to make permanent
```

---

### 1. Clone & install dependencies

```bash
git clone https://github.com/Sumat-Dev/flutter_password_cracker.git
cd flutter_password_cracker
flutter pub get
```

---

### 2. Add Rust targets

```bash
# iOS
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

# Android
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
```

---

### 3. Regenerate the bridge (if you modify Rust code)

```bash
flutter_rust_bridge_codegen generate
```

The config in `flutter_rust_bridge.yaml` points codegen at the right files automatically:

```yaml
rust_input: crate::api
rust_root: rust/
dart_output: lib/src/rust/
```

---

## How It Works

### Hashing (sync)

```
Flutter UI
    │
    │  crateApiHashString(input: "abc")   ← sync FFI call
    ▼
Rust: sha2::Sha256::digest("abc")
    │
    │  returns "ba7816bf..."              ← String back to Dart
    ▼
Flutter UI displays hash
```

### Cracking (streaming)

```
Flutter UI
    │
    │  crateApiBruteForceCrack(targetHash, maxLength)
    ▼
Rust: spawns rayon thread pool
    │   ├─ thread 0: aaa, aab, aac ...
    │   ├─ thread 1: baa, bab, bac ...
    │   ├─ thread 2: caa, cab, cac ...
    │   └─ thread N: ...
    │
    │  StreamSink.add(CrackProgress) every 50,000 attempts
    ▼
Dart Stream<CrackProgress> → setState() → UI update
    │
    │  StreamSink.add(CrackProgress { isFound: true })
    ▼
Flutter UI shows result banner
```

### Data structure

```rust
pub struct CrackProgress {
    pub current_attempt: String,   // latest guess being tested
    pub total_attempts:  u64,      // total hashes computed so far
    pub hashes_per_sec:  f64,      // throughput
    pub elapsed_secs:    f64,      // wall clock time
    pub is_found:        bool,     // true on final emission
    pub result:          Option<String>, // the cracked password
}
```

---

## Performance Notes

- Rust SHA-256 via `sha2` is typically **10–20x faster** than a pure Dart implementation
  (Rust SHA-256 เร็วกว่า Dart ประมาณ 10-20 เท่า)
- `rayon` automatically scales to the number of logical CPU cores — no manual thread management needed
  (`rayon` ปรับสเกลตามจำนวน Core ของ CPU โดยอัตโนมัติ)
- The `StreamSink` emits every 50,000 attempts to balance UI responsiveness against FFI call overhead
  (ส่งข้อมูลกลับทุกๆ 50,000 ครั้งเพื่อความสมดุลระหว่างความลื่นของ UI และ Overhead ของ FFI)
- Keep demo passwords at **3–5 characters** (`a–z` only)
  (แนะนำให้ทดสอบรหัสผ่านความยาว 3-5 ตัวอักษร)

---

## Limitations

This is a proof-of-concept, not a production tool.

- Charset is limited to lowercase `a–z` (รองรับเฉพาะตัวพิมพ์เล็ก a-z)
- No dictionary or rule-based attacks (ไม่มีระบบ Dictionary)
- No GPU acceleration (ไม่รองรับ GPU)
- Max practical length is ~5 chars for a demo (ความยาวที่เหมาะสมในการทดสอบคือไม่เกิน 5 ตัวอักษร)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
