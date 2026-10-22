"""Create original, softly enveloped bell cues using standard-library synthesis."""
from pathlib import Path
import math, struct, wave
root = Path(__file__).resolve().parent.parent
out = root/'Assets/Sounds'
out.mkdir(exist_ok=True)
rate = 44100

def cue(notes, length):
    samples = [0.0] * int(rate * length)
    for start, frequency, duration, gain in notes:
        for i in range(int(rate * duration)):
            t = i / rate
            # Slow attack and zero-ended release avoid sharp clicks or metallic edges.
            envelope = math.sin(math.pi * min(1, t / 0.06) / 2) ** 2
            envelope *= math.exp(-3.2 * t / duration)
            envelope *= min(1, max(0, (duration-t) / 0.18)) ** 2
            tone = math.sin(2*math.pi*frequency*t) + 0.12*math.sin(2*math.pi*frequency*2*t)
            index = int(start*rate)+i
            if index < len(samples): samples[index] += gain * envelope * tone
    return samples

def save(name, data):
    assert max(map(abs, data)) < 0.3
    with wave.open(str(out/name), 'wb') as f:
        f.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', round(x*32767)) for x in data))
    print(f'{name}: {len(data)/rate:.2f}s, peak {max(map(abs,data)):.3f}')

sounds = [
 ('BlinkStart.wav', cue([(0, 659.25, .7, .20)], .8)),
 ('BlinkHalfway.wav', cue([(0, 783.99, .65, .17)], .75)),
 ('BlinkComplete.wav', cue([(0, 783.99, .65, .17), (.22, 1046.50, .85, .16)], 1.2))
]
for name, data in sounds: save(name, data)
# A short demonstration of the three cues, without a 20-second wait.
preview = [0.0] * (rate * 4)
for offset, (_, data) in zip([0, 1.2, 2.4], sounds):
    for i, value in enumerate(data): preview[int(offset*rate)+i] += value
save('BlinkPreview.wav', preview)
