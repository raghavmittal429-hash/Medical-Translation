"""
Text-to-speech using ElevenLabs' Multilingual v2 model.

ElevenLabs produces noticeably more natural, expressive speech than both
Microsoft Edge TTS and gTTS -- it uses a genuine neural voice model trained
for emotional range and natural prosody across many languages, including all
9 Indian languages this app supports.

Requires ELEVENLABS_API_KEY in backend/.env. Free tier: 10,000 characters/month
(~10 minutes of audio). Paid plans start at $5/month for more characters.
Get your key at: https://elevenlabs.io/app/settings/api-keys

Model used: eleven_multilingual_v2
- Supports 29 languages including Hindi and Tamil
- Best quality, most stable for medical/professional content
- Slightly higher latency than Flash models but superior voice quality

Voice: Rachel (voice_id: 21m00Tcm4TlvDq8ikWAM)
- ElevenLabs' most versatile, widely-used default voice
- Works naturally across all supported Indian languages
- Calm, clear, professional tone -- well-suited for medical reports

Falls back to the next layer (Edge TTS -> gTTS) automatically if:
- ELEVENLABS_API_KEY is not configured
- API call fails (network, quota exhausted, etc.)
"""

import io
import os

from elevenlabs.client import ElevenLabs
from elevenlabs import VoiceSettings

# eleven_multilingual_v2 is ElevenLabs' most stable, emotionally rich
# model -- ideal for medical content where clarity and naturalness matter.
MODEL_ID = "eleven_multilingual_v2"

# Rachel -- ElevenLabs' default voice, calm and professional.
# Works naturally across all Indian languages with Multilingual v2.
DEFAULT_VOICE_ID = "21m00Tcm4TlvDq8ikWAM"

# Voice settings tuned for medical report narration:
# - Stability 0.65: consistent tone without sounding robotic
# - Similarity boost 0.80: stays close to the reference voice
# - Style 0.20: slight expressiveness without sounding dramatic
# - Speaker boost: on -- improves clarity for Indian language phonemes
VOICE_SETTINGS = VoiceSettings(
    stability=0.65,
    similarity_boost=0.80,
    style=0.20,
    use_speaker_boost=True,
)

# ElevenLabs Multilingual v2 caps each request at 5000 characters.
# Long report sections are split here so the caller never hits that limit.
MAX_CHARS_PER_REQUEST = 4800


class ElevenLabsConfigError(Exception):
    """Raised when ELEVENLABS_API_KEY is not set in the environment."""


class ElevenLabsTtsError(Exception):
    """Raised when the ElevenLabs API call itself fails."""


def _get_client():
    api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    if not api_key:
        raise ElevenLabsConfigError(
            "ELEVENLABS_API_KEY is not set in backend/.env. "
            "Get a free key at https://elevenlabs.io/app/settings/api-keys "
            "and add it to backend/.env as ELEVENLABS_API_KEY=..."
        )
    return ElevenLabs(api_key=api_key)


def _split_text(text: str, max_len: int = MAX_CHARS_PER_REQUEST) -> list:
    """Split text into chunks that respect ElevenLabs' character limit,
    breaking on sentence boundaries where possible."""
    import re
    text = text.strip()
    if len(text) <= max_len:
        return [text]

    chunks = []
    while len(text) > max_len:
        # Find the last sentence boundary within the limit
        slice_ = text[:max_len]
        cut = max(
            slice_.rfind('. '),
            slice_.rfind('! '),
            slice_.rfind('? '),
            slice_.rfind('\n'),
        )
        if cut == -1:
            cut = max_len  # no boundary found -- hard cut
        else:
            cut += 1  # include the punctuation
        chunks.append(text[:cut].strip())
        text = text[cut:].strip()

    if text:
        chunks.append(text)
    return chunks


def synthesize(text: str, language_code: str = "en") -> bytes:
    """
    Synthesize `text` using ElevenLabs Multilingual v2 and return raw MP3 bytes.
    Raises ElevenLabsConfigError if the API key isn't set, or
    ElevenLabsTtsError if the API call fails.
    Callers should catch both and fall back to Edge TTS or gTTS.
    """
    client = _get_client()
    chunks = _split_text(text)
    audio_parts = []

    for chunk in chunks:
        if not chunk:
            continue
        try:
            audio_iter = client.text_to_speech.convert(
                voice_id=DEFAULT_VOICE_ID,
                text=chunk,
                model_id=MODEL_ID,
                language_code=language_code,
                voice_settings=VOICE_SETTINGS,
                output_format="mp3_44100_128",
                apply_text_normalization="auto",
            )
            chunk_bytes = b"".join(audio_iter)
            if chunk_bytes:
                audio_parts.append(chunk_bytes)
        except Exception as e:
            raise ElevenLabsTtsError(
                f"ElevenLabs API error: {e}"
            ) from e

    if not audio_parts:
        raise ElevenLabsTtsError("ElevenLabs returned no audio content.")

    return b"".join(audio_parts)
