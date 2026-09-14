# A little easier

A private daily planning app with on-device task breakdowns, time estimates, brain-dump organization and dictation.

## Open the app

Double-click **Start app.command**, or run `node server.mjs` from this folder, then open http://localhost:5173. Keep the server running while using AI and voice. The launch script opens the page automatically.

Use the localhost app for AI and dictation. Opening index.html as a file still supports manual planning, but cannot connect to the local inference service. To move existing entries from the file version: export in Data & AI settings, open localhost, then import. Import adds entries with new IDs and retains existing entries.

## Improvements

- **Energy actually changes the plan:** Low shows one unfinished task, Steady three, High five. User-selected priorities come first. Skip the check-in or show the full list at any time. Low energy asks AI for a 1–2 minute first step; this is a product choice, not a clinical assessment.
- **Dictate on every text and minutes field:** press Dictate, speak, then Stop. Recordings stop after 90 seconds. Local Whisper appends text for review before saving. English number words are accepted in time fields. Microphone permission is needed. Text AI supports multiple languages; the installed speech model is English.
- **Help me get started:** replaces the timer with the next concrete action, its estimate and a button to move to the next step. Complete or edit the task at any time.
- **Execution Mode:** choose **Help me start** on a task or **Focus now** in navigation to keep one action visible. Choose a 2, 5 or 15-minute starting block, ask for quiet company, or use **I am stuck** to shrink the action, clarify the steps or stop for now. Optional reflections save actual time, energy afterwards and what helped in this browser only. This supports task completion and reflection; it is not a treatment or diagnostic assessment.
- **Task-specific local AI:** edit a task, optionally explain what is hard, then request steps and estimates. Review/edit suggestions before applying them. Accepted step estimates sum to the task estimate. A new task starts with a clearly labelled, editable 15-minute placeholder until you set it or accept AI suggestions.
- **Organized brain dumps:** originals save first. Auto-organize is enabled by default and generates an editable review grouped into Actions, Ideas, Questions and Notes. Accepted lists stay in the log; adding individual items to your day is a separate choice. Disable automatic organization if preferred.

## Privacy and storage

Task text is processed by Apple's on-device Foundation Models framework. There is no cloud AI endpoint or API key. Audio goes only to the server on 127.0.0.1, is transcribed by local Whisper, and is discarded; no audio files or transcripts are logged. The speech runtime is explicitly offline after setup. No analytics, remote scripts, external fonts or remote images are loaded. Resource links leave the app only when clicked.

Your entries use browser localStorage. They are not encrypted or cloud-synced. Browser profiles and file/localhost origins have separate storage. Export backups; clearing browser data removes entries. AI and voice use localhost ports only and require matching request origins.

## Local dependencies

This Mac has macOS 26.5 and an available Apple Intelligence model. AI requires macOS 26+ with Apple Intelligence enabled and its on-device model available. The compiled helper is at `../work/local-planner`; source is `LocalPlanner.swift`. Rebuild with:

```sh
xcrun swiftc -parse-as-library LocalPlanner.swift -o ../work/local-planner
```

Node.js 22+ serves the app without npm dependencies. The speech Python virtual environment is at `../work/voice-venv`. Whisper base.en model files are at `../work/models/whisper-base-en` (about 140 MB). Keep the app's parent folder with its work folder to retain the installed runtime and models.

If reinstalling speech dependencies, create that virtual environment with Python 3.9+, install `faster-whisper==1.2.1`, and download `Systran/faster-whisper-base.en` with huggingface_hub into that model folder (config.json, model.bin, tokenizer.json, vocabulary.txt). Downloads need internet; inference does not. Do not replace local inference with a cloud service without changing the app's privacy disclosure and getting user authorization.

## Validation

The source includes input limits, strict model-output validation, same-origin POST checks, and a static asset allowlist. Developer checks are in `../work/server.test.mjs`. AI output and speech quality still depend on the model, input specificity, microphone and background noise. Estimates are rough and editable; do not treat them as deadlines.
