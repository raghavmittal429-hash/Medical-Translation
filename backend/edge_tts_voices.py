"""
High-quality speech synthesis via Microsoft Edge's free neural voices
with optimized rate, pitch, and volume for natural medical narration.

The edge-tts package uses the same neural voice catalog as Azure
Cognitive Services' premium Speech service — completely free, no API key.
"""

import edge_tts

# Best neural voice per language — calm, clear, professional.
# Rate: -5% (slightly slower than default for medical content clarity)
# Pitch: +0Hz (natural, no artificial adjustment)
# Volume: +0% (balanced)
LANGUAGE_TO_EDGE_VOICE = {
    "en": "en-US-JennyNeural",      # warm, clear, natural American English
    "hi": "hi-IN-SwaraNeural",      # best Hindi neural voice
    "bn": "bn-IN-TanishaaNeural",
    "ta": "ta-IN-PallaviNeural",
    "te": "te-IN-ShrutiNeural",
    "mr": "mr-IN-AarohiNeural",
    "gu": "gu-IN-DhwaniNeural",
    "kn": "kn-IN-SapnaNeural",
    "ml": "ml-IN-SobhanaNeural",
    "pa": "hi-IN-SwaraNeural",
    "ur": "hi-IN-SwaraNeural",
    "or": "hi-IN-SwaraNeural",
    "as": "bn-IN-TanishaaNeural",
}

# Voice tuning for medical report narration:
# Slightly slower rate improves comprehension of medical terms.
# No pitch shift keeps the voice sounding natural and human.
RATE  = "-8%"   # 8% slower than default
PITCH = "+0Hz"  # no pitch change
VOLUME = "+0%"  # normal volume


async def synthesize(text: str, lang_code: str) -> bytes:
    """
    Synthesize text using the best Edge neural voice for lang_code.
    Returns raw MP3 bytes. Raises on failure.
    """
    voice = LANGUAGE_TO_EDGE_VOICE.get(lang_code, "en-US-JennyNeural")

    print(f"[edge_tts] voice={voice} rate={RATE} lang={lang_code} chars={len(text)}")

    communicate = edge_tts.Communicate(
        text,
        voice,
        rate=RATE,
        pitch=PITCH,
        volume=VOLUME,
    )

    chunks = []
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            chunks.append(chunk["data"])

    audio_bytes = b"".join(chunks)
    if not audio_bytes:
        raise RuntimeError(f"Edge TTS returned no audio for voice '{voice}'")

    print(f"[edge_tts] OK — {len(audio_bytes)} bytes")
    return audio_bytes
