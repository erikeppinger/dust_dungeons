"""Generates the fight sound effects as small WAV files.

The sounds are synthesized from sine waves, so the project owns them outright
(released as CC0 with the app, no third-party licenses). Re-run after changing
a sound:  python tool/generate_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freqs, ms, volume=0.5, decay=8.0, attack_ms=3):
    """Sum of sine waves with a short attack and exponential decay."""
    n = int(RATE * ms / 1000)
    attack = max(1, int(RATE * attack_ms / 1000))
    samples = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, i / attack) * math.exp(-decay * t)
        v = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
        samples.append(v * env * volume)
    return samples


def sequence(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        ))


SOUNDS = {
    # The boss's beat: low and round.
    "boss_beat": tone([196, 392], 160, volume=0.6, decay=18),
    # The player's tap: higher and short.
    "tap": tone([523], 70, volume=0.4, decay=40),
    # Judgements.
    "perfect": sequence(tone([1047, 1568], 90, volume=0.35, decay=20),
                        tone([1319, 1976], 120, volume=0.3, decay=16)),
    "miss": tone([110, 116], 180, volume=0.5, decay=14),
    # End of fight.
    "win": sequence(*(tone([f, f * 2], 130, volume=0.4, decay=10)
                      for f in (523, 659, 784, 1047))),
    "lose": sequence(*(tone([f], 180, volume=0.4, decay=8)
                       for f in (392, 349, 311, 262))),
    # Count-in click before the echo.
    "count": sequence(tone([880], 40, volume=0.3, decay=60), silence(10)),
}

if __name__ == "__main__":
    for name, samples in SOUNDS.items():
        write(name, samples)
        print(f"wrote {name}.wav")
