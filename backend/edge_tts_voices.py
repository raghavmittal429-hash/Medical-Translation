"""
Higher-quality speech synthesis via Microsoft Edge's free neural voices.

Why this exists: gTTS (Google Translate's free speech endpoint) works for
every language this app supports, but its underlying voice engine is
noticeably more robotic-sounding than modern neural TTS. Microsoft Edge's
built-in "Read aloud" feature uses the same neural voice catalog as Azure
Cognitive Services' premium Speech service, and like gTTS it's reachable
for free with no API key or billing account -- the `edge-tts` package
(https://github.com/rany2/edge-tts) just talks to the same free endpoint
the Edge browser itself uses.

This is still an unofficial/undocumented mechanism with no SLA, exactly
like the gTTS approach it sits alongside: Microsoft could change or
rate-limit it without notice. If it's ever unreachable, the caller should
fall back to gTTS, which is the existing, already-proven path -- this
module never needs to be the only option.
"""

import edge_tts

# One well-established neural voice per language this app supports. These
# are standard Microsoft voice names that have been stable for several
# years (the same catalog used by Azure's paid Speech service), but if
# Microsoft ever renames/retires one, edge_tts.Communicate will raise and
# the caller's gTTS fallback takes over -- this never needs to be perfect.
LANGUAGE_TO_EDGE_VOICE = {
    "en": "en-US-AriaNeural",
    "hi": "hi-IN-SwaraNeural",
    "bn": "bn-IN-TanishaaNeural",
    "ta": "ta-IN-PallaviNeural",
    "te": "te-IN-ShrutiNeural",
    "mr": "mr-IN-AarohiNeural",
    "gu": "gu-IN-DhwaniNeural",
    "kn": "kn-IN-SapnaNeural",
    "ml": "ml-IN-SobhanaNeural",
    "pa": "hi-IN-SwaraNeural",  # no dedicated Punjabi neural voice; closest available
    "ur": "hi-IN-SwaraNeural",  # ditto for Urdu
}


async def synthesize(text: str, lang_code: str) -> bytes:
    """Synthesizes `text` using the best available Edge neural voice for
    `lang_code`, returning raw MP3 bytes. Raises on any failure (network,
    unknown voice, etc.) -- callers should catch and fall back to gTTS."""
    voice = LANGUAGE_TO_EDGE_VOICE.get(lang_code, "en-US-AriaNeural")
    communicate = edge_tts.Communicate(text, voice)

    chunks = []
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            chunks.append(chunk["data"])

    audio_bytes = b"".join(chunks)
    if not audio_bytes:
        raise RuntimeError(f"Edge TTS returned no audio for voice '{voice}'")
    return audio_bytes
