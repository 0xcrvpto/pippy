"""Create original, softly enveloped cue sets using standard-library synthesis."""
from pathlib import Path
import math, struct, wave
root = Path(__file__).resolve().parent.parent
out = root/'Assets/Sounds'
out.mkdir(exist_ok=True)
rate = 44100

# Each voice: attack seconds, decay rate, and (frequency ratio, level) partials.
# Slow-enough attacks and zero-ended releases avoid sharp clicks or metallic edges.
voices = {
    'Blink': (0.06, 3.2, [(1, 1), (2, 0.12)]),
    'Marimba': (0.006, 6.5, [(1, 1), (3.9, 0.22), (9.2, 0.04)]),
    'Chimes': (0.012, 2.4, [(1, 1), (2.76, 0.28), (5.4, 0.1)]),
    'Kalimba': (0.008, 4.8, [(1, 1), (5.9, 0.16), (2, 0.08)]),
    'Woodblock': (0.004, 16, [(1, 1), (2.3, 0.3), (4.1, 0.08)]),
}

def cue(notes, length, voice='Blink'):
    attack, decay, partials = voices[voice]
    samples = [0.0] * int(rate * length)
    for start, frequency, duration, gain in notes:
        for i in range(int(rate * duration)):
            t = i / rate
            envelope = math.sin(math.pi * min(1, t / attack) / 2) ** 2
            envelope *= math.exp(-decay * t / duration)
            envelope *= min(1, max(0, (duration-t) / min(0.18, duration / 3))) ** 2
            tone = sum(level * math.sin(2*math.pi*frequency*ratio*t) for ratio, level in partials)
            index = int(start*rate)+i
            if index < len(samples): samples[index] += gain * envelope * tone
    return samples

def save(name, data):
    assert max(map(abs, data)) < 0.3
    with wave.open(str(out/name), 'wb') as f:
        f.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', round(x*32767)) for x in data))
    print(f'{name}: {len(data)/rate:.2f}s, peak {max(map(abs,data)):.3f}')

# Start, halfway, and complete cues per set. "Blink" is the original Soft Bells set,
# kept under its existing names because the Windows build embeds them.
sets = {
    'Blink': [
        cue([(0, 659.25, .7, .20)], .8),
        cue([(0, 783.99, .65, .17)], .75),
        cue([(0, 783.99, .65, .17), (.22, 1046.50, .85, .16)], 1.2)],
    'Marimba': [
        cue([(0, 523.25, .6, .19), (.14, 659.25, .6, .16)], .8, 'Marimba'),
        cue([(0, 783.99, .55, .17)], .65, 'Marimba'),
        cue([(0, 523.25, .5, .15), (.12, 659.25, .5, .15), (.24, 783.99, .7, .16)], 1.0, 'Marimba')],
    'Chimes': [
        cue([(0, 880.00, 1.1, .14), (.18, 1174.66, 1.0, .10)], 1.3, 'Chimes'),
        cue([(0, 1046.50, 1.0, .13)], 1.1, 'Chimes'),
        cue([(0, 880.00, 1.0, .11), (.16, 1046.50, 1.0, .10), (.32, 1318.51, 1.2, .10)], 1.6, 'Chimes')],
    'Kalimba': [
        cue([(0, 587.33, .7, .19)], .8, 'Kalimba'),
        cue([(0, 739.99, .65, .17)], .75, 'Kalimba'),
        cue([(0, 587.33, .55, .15), (.16, 739.99, .55, .15), (.32, 880.00, .8, .16)], 1.2, 'Kalimba')],
    'Woodblock': [
        cue([(0, 880.00, .18, .2), (.16, 1046.50, .18, .18)], .45, 'Woodblock'),
        cue([(0, 1046.50, .18, .18)], .3, 'Woodblock'),
        cue([(0, 880.00, .18, .17), (.13, 1046.50, .18, .17), (.26, 1318.51, .22, .17)], .6, 'Woodblock')],
}

for prefix, cues in sets.items():
    for suffix, data in zip(['Start', 'Halfway', 'Complete'], cues): save(f'{prefix}{suffix}.wav', data)
    # A short demonstration of the three cues, without a 20-second wait.
    gap = 1.2 if prefix == 'Blink' else max(len(data) for data in cues) / rate + 0.35
    preview = [0.0] * int(rate * max(4 if prefix == 'Blink' else 0, gap * 2 + len(cues[2]) / rate))
    for offset, data in zip([0, gap, gap * 2], cues):
        for i, value in enumerate(data): preview[int(offset*rate)+i] += value
    save(f'{prefix}Preview.wav', preview)
