# 🧠 Brainstorm: Voice Translation App — Flutter + On-Device LLM

> Dịch thuật giọng nói Việt ↔ Anh, hoàn toàn on-device, không cần internet.

---

## 1. Tổng Quan Ý Tưởng

Một ứng dụng mobile cho phép người dùng **nói tiếng Việt → nhận bản dịch tiếng Anh** và ngược lại, toàn bộ pipeline chạy local trên thiết bị — không gửi dữ liệu lên cloud, không cần internet, phản hồi nhanh và bảo mật.

```
[User nói] → [STT on-device] → [LLM on-device dịch] → [TTS on-device] → [User nghe]
```

---

## 2. Core Pipeline

### 2.1 Speech-to-Text (STT)
Chuyển giọng nói thành văn bản trước khi đưa vào LLM.

| Option | Notes |
|---|---|
| **Whisper.cpp** (via FFI) | Nhỏ, chính xác, hỗ trợ tiếng Việt tốt, model tiny/base ~150MB |
| `flutter_whisper` / native bridge | Wrapper cho Whisper, chạy trên Android/iOS |
| Android SpeechRecognizer API | Built-in, nhưng cần internet, không offline |
| iOS SFSpeechRecognizer | Built-in iOS, hỗ trợ offline từ iOS 13+ |

**→ Khuyến nghị:** Whisper.cpp via FFI hoặc native bridge cho cross-platform offline.

---

### 2.2 On-Device LLM (Translation Engine)

| Option | Model gợi ý | RAM cần |
|---|---|---|
| **llama.cpp** (via FFI/plugin) | Qwen2.5 1.5B / Phi-3.5 Mini (Q4) | ~1–2GB |
| **MediaPipe LLM Inference** | Gemma 2B | ~1.5GB |
| **Flutter AI Toolkit** (Google) | Gemma 2B on-device | ~1.5GB |
| **MLC LLM** | Phi-2, Qwen2.5 | ~1–2GB |
| **executorch** (Meta) | Llama 3.2 1B | ~1GB |

**→ Khuyến nghị cho dịch thuật:**
- **Gemma 2B / Phi-3.5 Mini (Q4_K_M)** — cân bằng tốt giữa tốc độ và chất lượng dịch
- Prompt đơn giản, nhiệm vụ rõ ràng → model nhỏ là đủ

**Prompt mẫu:**
```
Translate the following Vietnamese text to English. 
Output only the translated text, nothing else.

Text: {input}
```

---

### 2.3 Text-to-Speech (TTS)
Đọc kết quả dịch bằng giọng nói.

| Option | Notes |
|---|---|
| **Flutter TTS** (`flutter_tts`) | Đơn giản, dùng TTS system của OS, offline |
| Android TextToSpeech API | Built-in, offline, hỗ trợ VI + EN |
| iOS AVSpeechSynthesizer | Built-in, offline |
| **Coqui TTS** (nâng cao) | Model TTS offline chất lượng cao hơn |

**→ Khuyến nghị:** `flutter_tts` đủ dùng cho MVP, nâng cấp sau nếu cần chất lượng cao hơn.

---

## 3. UX / App Flow

### 3.1 Màn hình chính — Conversation Mode
```
┌─────────────────────────┐
│  🌐 Tiếng Việt → Anh   │  ← Toggle direction
├─────────────────────────┤
│                         │
│   "Xin chào, bạn        │  ← Original text (live STT)
│    khỏe không?"         │
│                         │
│   ─────────────────     │
│                         │
│   "Hello, how are you?" │  ← Translated text
│                         │
├─────────────────────────┤
│       🎙️  [Hold]        │  ← Push-to-talk button
│   🔊 Auto-play result   │
└─────────────────────────┘
```

### 3.2 Các Mode Dịch

| Mode | Mô tả |
|---|---|
| **Push-to-Talk** | Giữ nút, nói, thả ra → dịch |
| **Auto-detect** | Tự nhận tiếng, bắt đầu dịch khi im lặng |
| **Text Input** | Nhập tay nếu không muốn dùng voice |
| **Conversation Mode** | 2 người dùng 1 phone, dịch qua lại |

---

## 4. Kiến Trúc App (Flutter)

```
lib/
├── core/
│   ├── models/
│   │   └── translation_result.dart
│   └── services/
│       ├── stt_service.dart       # Speech-to-Text interface
│       ├── llm_service.dart       # LLM translation interface
│       └── tts_service.dart       # Text-to-Speech interface
├── features/
│   └── translator/
│       ├── bloc/                  # State management (Bloc/Cubit)
│       ├── pages/
│       │   └── translator_page.dart
│       └── widgets/
│           ├── waveform_widget.dart
│           ├── translation_card.dart
│           └── mic_button.dart
└── main.dart
```

**State Management:** Bloc / Cubit — phù hợp cho async pipeline STT → LLM → TTS.

---

## 5. Thách Thức Kỹ Thuật

### 5.1 Model Size & Download
- LLM model lớn (~1–4GB) → cần **lazy download** lần đầu mở app
- Dùng `background_fetch` hoặc progress UI để download model
- Lưu vào `getApplicationDocumentsDirectory()`

### 5.2 Latency Pipeline
```
STT: ~0.5–1s → LLM: ~2–5s → TTS: ~0.3s
                ↑ đây là bottleneck
```
- Có thể stream output từ LLM (token by token) và TTS từng câu để giảm perceived latency
- Dùng `Isolate` của Dart để tránh block UI thread

### 5.3 Tiếng Việt STT
- Whisper có hỗ trợ tiếng Việt khá tốt (model `small` trở lên)
- Android system STT offline cho tiếng Việt còn hạn chế
- Cần test thực tế trên nhiều thiết bị

### 5.4 FFI / Native Integration
- llama.cpp / whisper.cpp cần viết **Flutter FFI** hoặc dùng **Method Channel**
- Có sẵn một số plugin nhưng cần kiểm tra maintenance status

### 5.5 iOS vs Android
- iOS: nhiều giới hạn background processing hơn
- Android: cần xin `RECORD_AUDIO` permission
- Model lớn → cần kiểm tra RAM trên mid-range devices

---

## 6. Tính Năng Mở Rộng (v2+)

| Feature | Mô tả |
|---|---|
| 📜 **History** | Lưu lịch sử các lần dịch |
| 🔖 **Phrasebook** | Lưu các cụm từ hay dùng |
| 🌍 **Multi-language** | Mở rộng thêm ngôn ngữ (JP, KR, FR...) |
| 📷 **Camera Translation** | OCR + dịch text từ ảnh |
| 🔊 **Custom Voice** | Chọn giọng TTS (nam/nữ, tốc độ) |
| ⚙️ **Model Switcher** | Cho phép chọn model LLM khác nhau |
| 🌐 **Offline Map** | Tích hợp vào travel companion app |

---

## 7. Stack Đề Xuất (MVP)

| Layer | Tech |
|---|---|
| **Framework** | Flutter 3.x + Dart |
| **State** | flutter_bloc |
| **STT** | whisper.cpp via FFI hoặc `speech_to_text` plugin (online fallback) |
| **LLM** | MediaPipe Gemma 2B hoặc llama.cpp (Phi-3.5 Mini Q4) |
| **TTS** | `flutter_tts` |
| **Storage** | `path_provider` + local file |
| **Permissions** | `permission_handler` |
| **Audio** | `record` package |

---

## 8. MVP Scope Gợi Ý

**Sprint 1 — Foundation:**
- [ ] Setup project, cấu trúc thư mục
- [ ] Integrate TTS (dễ nhất, test nhanh)
- [ ] Integrate STT (system hoặc Whisper)

**Sprint 2 — Core:**
- [ ] Integrate on-device LLM
- [ ] Kết nối pipeline: STT → LLM → TTS
- [ ] UI cơ bản: mic button, hiển thị text

**Sprint 3 — Polish:**
- [ ] Toggle VI↔EN
- [ ] Loading states, error handling
- [ ] Model download progress UI

---

## 9. Câu Hỏi Cần Quyết Định

1. **Device target:** Android only hay cả iOS? (ảnh hưởng chọn STT engine)
2. **LLM framework:** MediaPipe (dễ hơn) hay llama.cpp (flexible hơn)?
3. **STT:** Whisper offline hoàn toàn hay chấp nhận online fallback cho tiếng Việt?
4. **Model download:** Bundle sẵn trong app (lớn) hay download lần đầu?
5. **Min spec device:** Cần xác định RAM tối thiểu hỗ trợ (3GB? 4GB?)

---

> ✅ Khi nào sẵn sàng, tiến sang **Planning** để breakdown task, chọn tech stack chính thức, và estimate timeline!
