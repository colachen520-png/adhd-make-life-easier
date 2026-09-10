"""Offline-only speech transcription. Audio stays in memory and is never logged."""
import io
import json
import sys
from faster_whisper import WhisperModel
model = WhisperModel(sys.argv[1], device='cpu', compute_type='int8', cpu_threads=3, local_files_only=True)
segments, info = model.transcribe(io.BytesIO(sys.stdin.buffer.read()), beam_size=3, language='en', vad_filter=True, condition_on_previous_text=False)
if info.duration > 100:
    raise ValueError('Recording too long')
text = ' '.join(s.text.strip() for s in segments if s.no_speech_prob < .7)
print(json.dumps({'text': text}))
