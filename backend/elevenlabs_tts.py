"""
Text-to-speech using ElevenLabs Multilingual v2.

Requires ELEVENLABS_API_KEY in Render environment variables (or backend/.env
for local development). Free tier: 10,000 characters/month.
Get your key at: https://elevenlabs.io/app/settings/api-keys

Voice model: eleven_multilingual_v2
- Best quality for Indian languages (Hindi, Tamil, Telugu, Malayalam, etc.)
- Natural, expressive speech with correct phonemes for each script

Voice: Aria (9BWtsMINqrJLrRacOk9x)
- ElevenLabs' best multilingual voice -- handles Indian language phonemes
  more naturally than the older Rachel voice
- Calm, clear, professional tone suited for medical report narration

Falls back to Edge TTS -> gTTS automatically if:
- ELEVENLABS_API_KEY is not set / has expired
- API call fails for any reason (quota, network, etc.)
"""

import os

from elevenlabs.client import ElevenLabs
from elevenlabs import VoiceSettings

# eleven_multilingual_v2: best quality model for all 9 Indian languages
MODEL_ID = "eleven_multilingual_v2"

# Aria -- ElevenLabs' most capable multilingual voice.
# Handles Devanagari, Tamil, Telugu, Malayalam, Bengali scripts naturally.
DEFAULT_VOICE_ID = "9BWtsMINqrJLrRacOk9x"

# Voice settings tuned for medical report narration:
# - stability 0.55: slightly more expressive than the old 0.65, avoids
#   monotone delivery on long clinical passages
# - similarity_boost 0.75: clear and consistent without sounding robotic
# - style 0.30: adds natural emphasis without overdramatic delivery
# - use_speaker_boost: improves clarity for Indian language phonemes
VOICE_SETTINGS = VoiceSettings(
    stability=0.55,
    similarity_boost=0.75,
    style=0.30,
    use_speaker_boost=True,
)

# ElevenLabs expects BCP-47 language codes (e.g. "hi-IN", not just "hi").
# This matters for multilingual_v2 -- the right code unlocks the correct
# phoneme set for each language's script.
LANGUAGE_CODE_MAP = {
    "en": "en-IN",   # Indian English -- better accent fit for this app
    "hi": "hi-IN",
    "bn": "bn-IN",
    "ta": "ta-IN",
    "te": "te-IN",
    "mr": "mr-IN",
    "gu": "gu-IN",
    "kn": "kn-IN",
    "ml": "ml-IN",
    "pa": "hi-IN",   # no dedicated Punjabi; closest available
    "ur": "hi-IN",   # ditto for Urdu
    "or": "hi-IN",
    "as": "bn-IN",
}

# Cap per request -- multilingual_v2 allows up to ~5000 chars but splitting
# at 4500 gives comfortable headroom and faster first-audio latency on long
# sections (the first chunk starts playing while the rest is fetched).
MAX_CHARS_PER_REQUEST = 4500


class ElevenLabsConfigError(Exception):
    """Raised when ELEVENLABS_API_KEY is missing from the environment."""


class ElevenLabsTtsError(Exception):
    """Raised when the ElevenLabs API call itself fails."""


def _get_client():
    api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    if not api_key:
        raise ElevenLabsConfigError(
            "ELEVENLABS_API_KEY is not set. "
            "Add it to Render's environment variables or to backend/.env."
        )
    return ElevenLabs(api_key=api_key)


def _split_text(text: str, max_len: int = MAX_CHARS_PER_REQUEST) -> list:
    """Split text at sentence boundaries to stay under ElevenLabs' char limit."""
    text = text.strip()
    if len(text) <= max_len:
        return [text]

    chunks = []
    while len(text) > max_len:
        slice_ = text[:max_len]
        # Prefer sentence-ending punctuation as break points
        cut = max(
            slice_.rfind('. '),
            slice_.rfind('! '),
            slice_.rfind('? '),
            slice_.rfind('\n'),
            slice_.rfind(', '),
        )
        if cut <= 0:
            cut = max_len  # no boundary found -- hard cut
        else:
            cut += 1
        chunks.append(text[:cut].strip())
        text = text[cut:].strip()

    if text:
        chunks.append(text)
    return chunks


def synthesize(text: str, language_code: str = "en") -> bytes:
    """
    Synthesize `text` using ElevenLabs Multilingual v2.
    Returns raw MP3 bytes.

    Raises ElevenLabsConfigError (no key) or ElevenLabsTtsError (API failure).
    Both are caught by the caller in main.py which then falls back to Edge TTS.
    """
    client = _get_client()

    # Use the correct BCP-47 code for this language
    bcp47_code = LANGUAGE_CODE_MAP.get(language_code, "hi-IN")

    chunks = _split_text(text)
    audio_parts = []

    print(f"[elevenlabs] synthesizing {len(text)} chars, "
          f"lang={language_code} ({bcp47_code}), "
          f"model={MODEL_ID}, voice={DEFAULT_VOICE_ID}, "
          f"chunks={len(chunks)}")

    for i, chunk in enumerate(chunks):
        if not chunk:
            continue
        try:
            audio_iter = client.text_to_speech.convert(
                voice_id=DEFAULT_VOICE_ID,
                text=chunk,
                model_id=MODEL_ID,
                language_code=bcp47_code,
                voice_settings=VOICE_SETTINGS,
                output_format="mp3_44100_128",
                apply_text_normalization="auto",
            )
            chunk_bytes = b"".join(audio_iter)
            if chunk_bytes:
                audio_parts.append(chunk_bytes)
                print(f"[elevenlabs] chunk {i+1}/{len(chunks)}: "
                      f"{len(chunk_bytes)} bytes OK")
            else:
                print(f"[elevenlabs] chunk {i+1}/{len(chunks)}: empty response")
        except Exception as e:
            print(f"[elevenlabs] chunk {i+1}/{len(chunks)} FAILED: {e}")
            raise ElevenLabsTtsError(f"ElevenLabs API error on chunk {i+1}: {e}") from e

    if not audio_parts:
        raise ElevenLabsTtsError("ElevenLabs returned no audio content.")

    total = sum(len(p) for p in audio_parts)
    print(f"[elevenlabs] total audio: {total} bytes ({len(audio_parts)} chunks)")
    return b"".join(audio_parts)
