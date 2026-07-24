#!/usr/bin/env python3
"""MANABIT combat SFX generator - procedural synthesis ruling (combat-juice push 2026-07-18).

Pure Python stdlib (wave/struct/math/random - no numpy, no installs). random.seed(7) for
byte-identical regeneration. 44100 Hz 16-bit mono PCM, peak-normalized to -3 dBFS (all mix
gain lives in the playback manifest in ui/sfx.gd), soft-clip tanh(x*0.9).

Emits 14 wavs / 11 seams into <repo>/audio/sfx/ and prints a manifest line per file.
Cozy palette: toks (modal free-bar sines), 2-op FM bells, bandpass noise sweeps, brass stacks.
BANNED: casino chimes, harsh beeps, foil crinkle.

Run:  py -3 tools/audio/make_sfx.py
Then: godot --headless --path . --import   (a forgotten import reads as generator failure)
"""
import json
import math
import os
import random
import struct
import wave
import zlib

random.seed(7)

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "audio", "sfx")
MODE_RATIOS = [1.0, 2.76, 5.40, 8.93]   # free-bar partials - the toy-plastic "tok"


def buf(ms):
    return [0.0] * int(SR * ms / 1000.0)


def mix(dst, src, at_ms=0.0, gain=1.0):
    off = int(SR * at_ms / 1000.0)
    for i, s in enumerate(src):
        j = off + i
        if 0 <= j < len(dst):
            dst[j] += s * gain
    return dst


def db(x):
    return 10.0 ** (x / 20.0)


# --- filters (RBJ biquads) --------------------------------------------------------------
class Biquad:
    def __init__(self):
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0
        self.b0 = 1.0
        self.b1 = self.b2 = self.a1 = self.a2 = 0.0

    def set(self, kind, f, q):
        f = max(20.0, min(f, SR * 0.45))
        w = 2.0 * math.pi * f / SR
        alpha = math.sin(w) / (2.0 * q)
        cw = math.cos(w)
        if kind == "bp":
            b0, b1, b2 = alpha, 0.0, -alpha
        elif kind == "lp":
            b0 = (1.0 - cw) / 2.0
            b1 = 1.0 - cw
            b2 = b0
        else:  # hp
            b0 = (1.0 + cw) / 2.0
            b1 = -(1.0 + cw)
            b2 = b0
        a0 = 1.0 + alpha
        self.b0, self.b1, self.b2 = b0 / a0, b1 / a0, b2 / a0
        self.a1, self.a2 = (-2.0 * cw) / a0, (1.0 - alpha) / a0

    def tick(self, x):
        y = self.b0 * x + self.b1 * self.x1 + self.b2 * self.x2 - self.a1 * self.y1 - self.a2 * self.y2
        self.x2, self.x1 = self.x1, x
        self.y2, self.y1 = self.y1, y
        return y


def filtered(sig, kind, f, q=0.707):
    bq = Biquad()
    bq.set(kind, f, q)
    return [bq.tick(s) for s in sig]


# --- primitives -------------------------------------------------------------------------
def tok(f0, decays_ms, dur_ms, click_gain=db(-6.0), modes=None, amp=1.0):
    """Modal decaying sines at free-bar ratios + a 6ms lowpassed noise click."""
    ratios = modes if modes is not None else MODE_RATIOS
    out = buf(dur_ms)
    n = len(out)
    for m, r in enumerate(ratios):
        dec = decays_ms[min(m, len(decays_ms) - 1)] / 1000.0
        f = f0 * r
        if f > SR * 0.45:
            continue
        ph = random.uniform(0.0, math.pi)
        a = amp / (1.0 + m * 0.7)
        for i in range(n):
            t = i / SR
            out[i] += a * math.exp(-t / dec) * math.sin(2.0 * math.pi * f * t + ph)
    click = [random.uniform(-1.0, 1.0) for _ in range(int(SR * 0.006))]
    click = filtered(click, "lp", 3000.0, 0.9)
    ce = len(click)
    for i in range(ce):
        click[i] *= (1.0 - i / ce)
    mix(out, click, 0.0, click_gain)
    return out


def bell(f, ratio, index0, index_decay_ms, amp_decay_ms, dur_ms, amp=1.0, droop=0.0):
    """2-op FM bell, modulation index decaying to ~0. droop = fractional pitch sag over the tail."""
    out = buf(dur_ms)
    n = len(out)
    ph = 0.0
    for i in range(n):
        t = i / SR
        idx = index0 * math.exp(-t / (index_decay_ms / 1000.0))
        a = amp * math.exp(-t / (amp_decay_ms / 1000.0))
        sag = 1.0 - droop * min(1.0, t / (amp_decay_ms / 1000.0))
        ph += 2.0 * math.pi * (f * sag) / SR
        out[i] = a * math.sin(ph + idx * math.sin(ph * ratio))
    return out


def sweep_noise(dur_ms, f_lo, f_hi, q, atk_ms, dec_ms, amp=1.0):
    """Bandpass-glide noise with a hump envelope (attack then exponential fall)."""
    n = int(SR * dur_ms / 1000.0)
    bq = Biquad()
    out = []
    for i in range(n):
        t = i / n
        f = f_lo * ((f_hi / f_lo) ** t)
        bq.set("bp", f, q)
        tm = i / SR * 1000.0
        if tm < atk_ms:
            env = tm / atk_ms
        else:
            env = math.exp(-(tm - atk_ms) / dec_ms)
        out.append(bq.tick(random.uniform(-1.0, 1.0)) * env * amp)
    return out


def sine_drop(f_hi, f_lo, glide_ms, decay_ms, dur_ms, amp=1.0):
    """Exponential pitch glide with exponential amp decay - the deep 'soul struck' drop."""
    out = buf(dur_ms)
    ph = 0.0
    for i in range(len(out)):
        t = i / SR
        g = min(1.0, (t * 1000.0) / glide_ms)
        f = f_hi * ((f_lo / f_hi) ** g)
        ph += 2.0 * math.pi * f / SR
        out[i] = amp * math.exp(-t / (decay_ms / 1000.0)) * math.sin(ph)
    return out


def brass(freqs, atk_ms, dec_ms, dur_ms, amp=1.0):
    """8 harmonics at 1/n^1.3, lowpassed 2.2 kHz - the warm little victory brass."""
    out = buf(dur_ms)
    n = len(out)
    for f0 in freqs:
        for h in range(1, 9):
            f = f0 * h
            if f > SR * 0.45:
                continue
            a = amp / (h ** 1.3) / len(freqs)
            ph = random.uniform(0.0, math.pi)
            for i in range(n):
                tm = i / SR * 1000.0
                if tm < atk_ms:
                    env = tm / atk_ms
                else:
                    env = math.exp(-(tm - atk_ms) / dec_ms)
                out[i] += a * env * math.sin(2.0 * math.pi * f * (i / SR) + ph)
    return filtered(out, "lp", 2200.0, 0.8)


# --- wave-4a primitives (new voices; used ONLY by the re-seeded wave-4a batch) -----------
def sine_chord(freqs, atk_ms, hold_ms, dec_ms, dur_ms, amp=1.0):
    """Pure-sine chord: linear attack, hold, exponential decay - the mana chord voice."""
    out = buf(dur_ms)
    n = len(out)
    for f in freqs:
        ph = random.uniform(0.0, math.pi)
        a = amp / len(freqs)
        for i in range(n):
            tm = i / SR * 1000.0
            if tm < atk_ms:
                env = tm / atk_ms
            elif tm < atk_ms + hold_ms:
                env = 1.0
            else:
                env = math.exp(-(tm - atk_ms - hold_ms) / dec_ms)
            out[i] += a * env * math.sin(2.0 * math.pi * f * (i / SR) + ph)
    return out


def glide_sine(f_a, f_b, dur_ms, atk_ms=60.0, dec_ms=None, amp=1.0):
    """Exponential pitch glide f_a -> f_b across the whole buffer; sustains unless dec_ms."""
    out = buf(dur_ms)
    n = len(out)
    phase = random.uniform(0.0, math.pi)
    for i in range(n):
        tm = i / SR * 1000.0
        g = min(1.0, tm / dur_ms)
        f = f_a * ((f_b / f_a) ** g)
        phase += 2.0 * math.pi * f / SR
        if tm < atk_ms:
            env = tm / atk_ms
        elif dec_ms is None:
            env = 1.0
        else:
            env = math.exp(-(tm - atk_ms) / dec_ms)
        out[i] = amp * env * math.sin(phase)
    return out


def noise_env(dur_ms, kind, f, q, atk_ms, dec_ms, amp=1.0):
    """Filtered noise burst with linear attack + exponential decay (paper / felt / bellows)."""
    n = int(SR * dur_ms / 1000.0)
    raw = filtered([random.uniform(-1.0, 1.0) for _ in range(n)], kind, f, q)
    out = []
    for i in range(n):
        tm = i / SR * 1000.0
        env = tm / atk_ms if tm < atk_ms else math.exp(-(tm - atk_ms) / dec_ms)
        out.append(raw[i] * env * amp)
    return out


def tick_metal(f0, dur_ms=60.0, amp=1.0):
    """One dry brass ratchet tick: inharmonic metal partials, very fast felt-stopped decay."""
    out = buf(dur_ms)
    n = len(out)
    decs = [22.0, 14.0, 9.0]
    for m, r in enumerate([1.0, 2.41, 3.83]):
        f = f0 * r
        if f > SR * 0.45:
            continue
        ph = random.uniform(0.0, math.pi)
        a = amp / (1.0 + m * 0.9)
        dec = decs[m] / 1000.0
        for i in range(n):
            t = i / SR
            out[i] += a * math.exp(-t / dec) * math.sin(2.0 * math.pi * f * t + ph)
    click = filtered([random.uniform(-1.0, 1.0) for _ in range(int(SR * 0.003))], "hp", 2500.0, 0.8)
    ce = len(click)
    for i in range(ce):
        click[i] *= (1.0 - i / ce)
    mix(out, click, 0.0, amp * 0.5)
    return out


def ratchet(dur_ms, n_ticks, f0, p=1.0, amp=1.0):
    """Tick train across dur_ms. p < 1 = accelerating (dense late), p > 1 = decelerating."""
    out = buf(dur_ms)
    for i in range(n_ticks):
        frac = i / float(max(1, n_ticks - 1))
        t = (dur_ms - 70.0) * (frac ** p)
        f = f0 * random.uniform(0.94, 1.06)
        mix(out, tick_metal(f, 55.0), t, amp)
    return out


def soften(sig, atk_ms):
    """Round a transient: linear attack ramp over the first atk_ms (bible: no clicky onsets)."""
    n = int(SR * atk_ms / 1000.0)
    for i in range(min(n, len(sig))):
        sig[i] *= i / float(n)
    return sig


# --- finalize ---------------------------------------------------------------------------
def write(name, sig, fade_out_ms=8.0, peak_db=-3.0):
    # peak_db: per-file peak norm target. Default -3.0 keeps the shipped 14 byte-identical;
    # UI-bus files pass -12.0 (the UI law: any Ui file peaking above -12 dBFS is a bug).
    fo = int(SR * fade_out_ms / 1000.0)
    n = len(sig)
    for i in range(max(0, n - fo), n):
        sig[i] *= (n - i) / fo
    sig = [math.tanh(s * 0.9) for s in sig]
    peak = max(1e-9, max(abs(s) for s in sig))
    target = db(peak_db)
    sig = [s * target / peak for s in sig]
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in sig))
    print("MANIFEST %-20s %4dms peak %.1fdBFS -> %s" % (name, int(1000.0 * len(sig) / SR), peak_db, path))


def main():
    # attack_whoosh_0 - sweep_noise 240ms bandpass 350 -> 1600 Hz Q 1.4, hump env 40/120
    write("attack_whoosh_0", sweep_noise(240, 350, 1600, 1.4, 40, 120))

    # hit_0..2 - tok f0 560/620/690, mode decays 70/45/30/18ms, click -6 dB under body, 140ms
    for i, f0 in enumerate([560, 620, 690]):
        write("hit_%d" % i, tok(f0, [70, 45, 30, 18], 140))

    # hit_core_0 - sine_drop 130 -> 72 over 180 decay 320 + 12ms knock lowpassed 900
    #             + two bells 880/932 (semitone beat = the soul rang wrong) decay 420 at -10 dB
    core = buf(550)
    mix(core, sine_drop(130, 72, 180, 320, 550), 0.0, 1.0)
    knock = filtered([random.uniform(-1.0, 1.0) for _ in range(int(SR * 0.012))], "lp", 900.0, 0.8)
    mix(core, knock, 0.0, 0.9)
    mix(core, bell(880, 1.0, 2.0, 160, 420, 480), 20.0, db(-10.0))
    mix(core, bell(932, 1.0, 2.0, 160, 420, 480), 20.0, db(-10.0))
    write("hit_core_0", core)

    # part_break_0..1 - crack 28ms noise hp 1.4k + body tok 190 + THREE clatter toks
    #                   (onsets 60/130/210, f0 900-1700, amp 0.8 -> 0.4), two scatter seeds
    for v in range(2):
        brk = buf(360)
        crack = filtered([random.uniform(-1.0, 1.0) for _ in range(int(SR * 0.028))], "hp", 1400.0, 0.8)
        ce = len(crack)
        for i in range(ce):
            crack[i] *= (1.0 - i / ce)
        mix(brk, crack, 0.0, 0.9)
        mix(brk, tok(190, [90, 60, 40, 25], 300), 0.0, 0.9)
        for k, onset in enumerate([60, 130, 210]):
            fr = random.uniform(900.0, 1700.0)
            mix(brk, tok(fr, [40, 26, 16], 120, db(-12.0)), onset, 0.8 - 0.2 * k)
        write("part_break_%d" % v, brk)

    # guard_up_0 - bell 1245 ratio 3.7 index 4 -> 0.4 decay 380 + swish -14 dB, lowpassed 6k
    grd = buf(420)
    mix(grd, bell(1245, 3.7, 4.0, 140, 380, 420), 0.0, 1.0)
    mix(grd, sweep_noise(200, 900, 2600, 1.2, 30, 90), 0.0, db(-14.0))
    write("guard_up_0", filtered(grd, "lp", 6000.0, 0.8))

    # mend_0 - 4 bells C6 E6 G6 C7 onsets 0/70/140/210 decay 320, lowpass 7.5k, 640ms
    mnd = buf(640)
    for onset, f in zip([0, 70, 140, 210], [1046.50, 1318.51, 1567.98, 2093.00]):
        mix(mnd, bell(f, 2.0, 1.6, 180, 320, 420), onset, 0.8)
    write("mend_0", filtered(mnd, "lp", 7500.0, 0.8))

    # victory_chord_0 - brass C4+E4+G4 attack 60 decay 1000 + bell C6 entering at 180ms, 1.5s
    vic = buf(1500)
    mix(vic, brass([261.63, 329.63, 392.00], 60, 1000, 1400), 0.0, 1.0)
    mix(vic, bell(1046.50, 2.0, 1.8, 200, 600, 1000), 180.0, 0.5)
    write("victory_chord_0", vic, 30.0)

    # loss_settle_0 - toks 240 at t0 and 185 at 220ms + soft A3+C4 pad -12 dB, 900ms
    los = buf(900)
    mix(los, tok(240, [140, 90, 60, 35], 500), 0.0, 0.9)
    mix(los, tok(185, [160, 100, 65, 40], 600), 220.0, 0.8)
    mix(los, brass([220.00, 261.63], 220, 500, 850), 60.0, db(-12.0))
    write("loss_settle_0", los, 40.0)

    # death_winddown_0 - five drooping bells E5 C5 A4 F4 D4 at 0/100/220/370/540 (widening
    # gaps), note decays 220, each -6% over its tail; final note glides to 220 Hz.
    # TOTAL FILE <= 900ms (must be fully decayed before the unmaking's silence at t=1200).
    dth = buf(895)
    for onset, f in zip([0, 100, 220, 370], [659.26, 523.25, 440.00, 349.23]):
        mix(dth, bell(f, 2.0, 1.4, 150, 220, 330, droop=0.06), onset, 0.8)
    # final note: D4 gliding down to 220 Hz over 180ms, 200ms decay
    fin = buf(340)
    mix(fin, sine_drop(293.66, 220.0, 180, 200, 340), 0.0, 1.0)
    mix(dth, fin, 540.0, 0.85)
    write("death_winddown_0", dth, 25.0)

    # invalid_clunk_0 - damped tok 150, modes 1+2 only, 120ms
    write("invalid_clunk_0", tok(150, [55, 30], 120, db(-8.0), modes=[1.0, 2.76]))

    # core_peril_0 - two sines 108 + 110 (2 Hz beat), attack 200 / release 300, 800ms
    per = buf(800)
    for f in [108.0, 110.0]:
        for i in range(len(per)):
            tm = i / SR * 1000.0
            if tm < 200.0:
                env = tm / 200.0
            elif tm < 500.0:
                env = 1.0
            else:
                env = max(0.0, 1.0 - (tm - 500.0) / 300.0)
            per[i] += 0.5 * env * math.sin(2.0 * math.pi * f * i / SR)
    write("core_peril_0", per, 30.0)

    print("DONE 14 wavs / 11 seams -> %s" % os.path.abspath(OUT))
    wave_4a()
    wave_4b()


# =========================================================================================
# WAVE 4a - P0 one-shots from the ratified full-game inventory (groups 2/3/4)
# design/gdd/audio-full-game.md is the single source of truth for every spec below.
# SEED DISCIPLINE (tech plan T1 / RISK 3): the 14 legacy wavs above stay on the single
# seed(7) stream untouched; every wave-4a file re-seeds from zlib.crc32 of its own name
# (stable across processes - never built-in hash()), so adding or reordering batch files
# can never shift another file's bytes. Byte-reproducibility is additive.
# UI LAW: files routed to the Ui bus are peak-normalized to -12 dBFS (peak_db=-12.0);
# everything else keeps the house -3 dBFS.
# KEY LAW: every tonal element lands in C major / A minor.
# =========================================================================================

def _snap(v):
    # THE hero: 6ms click (variant grain) + brass ding A4 440 ratio 3.5 + mana shimmer ~C7
    # at -16 dB, 260ms, felt tail, lp 7k. Rarity ladder is pitch_scale at the call site.
    out = buf(260)
    click = [random.uniform(-1.0, 1.0) for _ in range(int(SR * 0.006))]
    if v == 0:
        click = filtered(click, "lp", 4200.0, 0.9)
    else:
        click = filtered(filtered(click, "hp", 1500.0, 0.8), "lp", 6000.0, 0.9)
    ce = len(click)
    for i in range(ce):
        click[i] *= (1.0 - i / ce)
    mix(out, click, 0.0, 0.9)
    mix(out, bell(440.0, 3.5, 3.5, 110, 150, 256), 4.0, 1.0)
    shim = buf(200)
    for f in [2093.00, 2637.02]:
        ph = random.uniform(0.0, math.pi)
        for i in range(len(shim)):
            t = i / SR
            shim[i] += 0.5 * math.exp(-t / 0.11) * math.sin(2.0 * math.pi * f * t + ph)
    mix(out, shim, 10.0, db(-16.0))
    return filtered(out, "lp", 7000.0, 0.8)


def _core_wake():
    # mana: warm Am chord A3+C4+E4, 150ms slow attack, C6 bell shimmer -14 dB, felt tail
    out = sine_chord([220.00, 261.63, 329.63], 150, 150, 220, 900)
    mix(out, bell(1046.50, 2.0, 1.6, 150, 300, 500), 180.0, db(-14.0))
    return out


def _route_step(v):
    # wood+brass: felt footfall tok 180 + 2-3 tiny satchel jingle ticks 1.2-2k at -14 dB
    out = buf(220)
    mix(out, tok(180, [80, 50, 32, 20], 200, db(-10.0)), 0.0, 1.0)
    jingles = [(70.0, 1400.0), (120.0, 1900.0)] if v == 0 else [(65.0, 1250.0), (115.0, 1600.0), (160.0, 1950.0)]
    for at, f in jingles:
        mix(out, tick_metal(f, 50.0), at, db(-14.0))
    return out


def _fork_reveal():
    # brass: soft double chime E5 then G5, 90ms apart, gentle attack, quiet
    out = buf(500)
    mix(out, soften(bell(659.26, 2.0, 1.4, 120, 260, 420), 30.0), 0.0, 0.85)
    mix(out, soften(bell(783.99, 2.0, 1.4, 120, 260, 400), 30.0), 90.0, 0.85)
    return filtered(out, "lp", 7000.0, 0.8)


def _switch_throw():
    # brass: heavy lever - low brass thunk C4 + metal tok 700 + wood rail clunk 150, felt stop
    out = buf(300)
    mix(out, brass([261.63], 5, 130, 280), 0.0, 0.9)
    mix(out, tick_metal(700.0, 90.0), 15.0, 0.7)
    mix(out, tok(150, [70, 42, 26, 16], 220), 55.0, 0.85)
    return out


def _seal_channel():
    # brass+mana: accelerating ratchet over 850ms + rising sine hum A3->A4 at -10 dB under.
    # Ends open - the runtime cuts it with seal_crack or on release.
    out = ratchet(850, 12, 1150.0, 0.6, 1.0)
    mix(out, glide_sine(220.0, 440.0, 850, 120.0), 0.0, db(-10.0))
    return out


def _seal_crack():
    # brass hero: 20ms hp crack + warm G5 bell + small brass bloom
    out = buf(500)
    mix(out, noise_env(20, "hp", 2000.0, 0.8, 1.5, 7.0), 0.0, 1.0)
    mix(out, bell(783.99, 2.0, 2.2, 120, 260, 480), 12.0, 0.9)
    mix(out, brass([392.00, 493.88], 25, 220, 420), 25.0, db(-9.0))
    return out


def _lid_spring():
    # brass: quick 2-tok flick 500->800 + tiny sprung bell E5 ratio 2.4, playful
    out = buf(250)
    mix(out, tok(500, [40, 26, 16], 110), 0.0, 0.9)
    mix(out, tok(800, [36, 22, 14], 100), 55.0, 0.8)
    mix(out, bell(659.26, 2.4, 2.6, 70, 130, 180), 85.0, 0.5)
    return out


def _ledger_open():
    # parchment: bandpass page slide + soft low flump, quiet (Ui bus - peak -12)
    out = buf(300)
    mix(out, sweep_noise(270, 500, 1100, 1.0, 70, 120), 0.0, 1.0)
    mix(out, tok(150, [80, 45], 130, db(-14.0), modes=[1.0, 2.76]), 185.0, 0.55)
    return out


def _fettle_greet():
    # brass automaton: 2 warm bell taps C5, E5 + tiny bellows puff, friendly
    out = buf(600)
    mix(out, bell(523.25, 2.5, 2.0, 110, 210, 420), 0.0, 0.9)
    mix(out, bell(659.26, 2.5, 2.0, 110, 210, 420), 140.0, 0.85)
    mix(out, noise_env(240, "lp", 500.0, 0.8, 90.0, 110.0), 290.0, 0.32)
    return out


def _fettle_appraise():
    # brass: single mid bell G4 + short ratchet tick pair, thoughtful
    out = buf(450)
    mix(out, bell(392.00, 2.5, 1.8, 130, 240, 430), 0.0, 0.9)
    mix(out, tick_metal(1100.0, 55.0), 210.0, 0.35)
    mix(out, tick_metal(1240.0, 55.0), 285.0, 0.30)
    return out


def _fettle_apologise():
    # wood+air: descending soft tok pair E4 -> C4 + small bellows sigh, round
    out = buf(500)
    mix(out, tok(329.63, [95, 60, 38, 24], 260, db(-10.0)), 0.0, 0.9)
    mix(out, tok(261.63, [110, 70, 42, 26], 300, db(-10.0)), 160.0, 0.85)
    mix(out, noise_env(280, "lp", 420.0, 0.8, 130.0, 130.0), 190.0, 0.28)
    return out


def _wax_stamp():
    # wax: lowpassed thump drop 180->90 + soft squish lp 600, ONE thunk, zero ring
    out = buf(220)
    mix(out, sine_drop(180, 90, 100, 140, 220), 0.0, 1.0)
    mix(out, noise_env(80, "lp", 600.0, 0.8, 6.0, 40.0), 8.0, 0.5)
    mix(out, noise_env(12, "lp", 900.0, 0.8, 1.0, 6.0), 0.0, 0.6)
    return out


def _doorstep_untie():
    # parchment+twine: 3 small bp pulls at 2k + soft wood tok landing
    out = buf(400)
    for at, g in [(0.0, 0.7), (110.0, 0.8), (220.0, 0.9)]:
        mix(out, noise_env(60, "bp", 2000.0, 1.4, 8.0, 30.0), at, g)
    mix(out, tok(300, [60, 38, 24], 90), 310.0, 0.6)
    return out


def _forge_melt():
    # ember+brass: lp noise swell + descending brass E4->A3 + sparse crackle, warm not violent
    out = buf(800)
    mix(out, noise_env(650, "lp", 800.0, 0.8, 320.0, 260.0), 0.0, 0.9)
    mix(out, glide_sine(330.0, 220.0, 700, 60.0, 400.0), 40.0, 0.55)
    mix(out, glide_sine(660.0, 440.0, 700, 60.0, 350.0), 40.0, 0.25)
    for _ in range(6):
        at = random.uniform(120.0, 680.0)
        mix(out, noise_env(18, "hp", 3000.0, 0.8, 2.0, 8.0), at, 0.18)
    return out


def _still_drip(v):
    # glimmer/liquid: rising chirp + tiny glass-edge bell (~A6) at -10 dB; NOT brass
    k = [1.0, 1.12, 0.9][v]
    out = buf(180)
    mix(out, sine_drop(900.0 * k, 1400.0 * k, 40, 90, 170), 0.0, 1.0)
    mix(out, bell(1760.0 * k, 3.0, 2.5, 60, 100, 150), 25.0, db(-10.0))
    return filtered(out, "lp", 7000.0, 0.8)


def _coin_scrap(v):
    # brass filings pour, felt-damped bp 3-5k ticks; v0 = rising density (gain), v1 = falling (spend)
    out = buf(300)
    nt = 16
    p = 0.6 if v == 0 else 1.6
    for i in range(nt):
        frac = i / float(nt - 1)
        t = 240.0 * (frac ** p)
        g = (0.35 + 0.65 * frac) if v == 0 else (1.0 - 0.65 * frac)
        f = random.uniform(3000.0, 5000.0)
        mix(out, noise_env(14, "bp", f, 2.2, 1.5, 6.0), t, 0.8 * g)
    return filtered(out, "lp", 6500.0, 0.8)


def _gear_tick(v):
    # brass: single dry ratchet tick 900-1400, felt stop (Ui bus - peak -12)
    return tick_metal([950.0, 1150.0, 1350.0][v], 60.0)


def _reveal_common():
    # wood: dry tok E4, decays [70,45,30,18], dies fast, NO shimmer - common is honest
    return tok(329.63, [70, 45, 30, 18], 220)


def _reveal_rare():
    # glass: bell C6 ratio 3.0 index 3.5 decay 380 + E6 at -6 dB entering 60ms, lp 7k
    out = buf(750)
    mix(out, bell(1046.50, 3.0, 3.5, 150, 380, 750), 0.0, 1.0)
    mix(out, bell(1318.51, 3.0, 3.0, 150, 340, 690), 60.0, db(-6.0))
    return filtered(out, "lp", 7000.0, 0.8)


def _reveal_epic():
    # deep bell G3 big FM body + warm 98 Hz sub at -10 dB + faux choral C4-G4 slow attack
    # at -18 dB lp 3k. DOWN and WIDE, never shrill - the anti-casino geometry.
    out = buf(2400)
    mix(out, bell(196.00, 2.76, 5.0, 300, 900, 2400), 0.0, 1.0)
    mix(out, sine_drop(98.0, 98.0, 10, 900, 2000), 0.0, db(-10.0))
    chor_freqs = [f * random.uniform(0.995, 1.005) for f in [261.63, 329.63, 392.00, 392.00]]
    chor = filtered(sine_chord(chor_freqs, 300, 500, 500, 1800), "lp", 3000.0, 0.8)
    mix(out, chor, 150.0, db(-18.0))
    return filtered(out, "lp", 6500.0, 0.8)


def _new_stamp():
    # wood+brass ka-chunk: tok 400 then tok 700 40ms later + paper flap at -14 dB, felt-damped
    out = buf(180)
    mix(out, tok(400, [50, 32, 20, 12], 120), 0.0, 0.9)
    mix(out, tok(700, [40, 26, 16, 10], 110), 40.0, 0.85)
    mix(out, noise_env(45, "bp", 1800.0, 1.2, 5.0, 22.0), 28.0, db(-14.0))
    return out


def _equip_whoosh():
    # air: small bandpass sweep 200-900, quiet
    return sweep_noise(160, 200, 900, 1.2, 40, 70)


def _strain_creak():
    # wood groan: slow modal bend 120->150 over 400ms with 12 Hz AM stutter (stick-slip)
    out = buf(450)
    n = len(out)
    for m, r in enumerate([1.0, 2.76]):
        ph = random.uniform(0.0, math.pi)
        a = 1.0 / (1.0 + m * 0.7)
        phase = 0.0
        for i in range(n):
            t = i / SR
            tm = t * 1000.0
            g = min(1.0, tm / 400.0)
            f = 120.0 * ((150.0 / 120.0) ** g) * r
            phase += 2.0 * math.pi * f / SR
            am = 0.55 + 0.45 * math.sin(2.0 * math.pi * 12.0 * t + ph)
            env = tm / 50.0 if tm < 50.0 else math.exp(-(tm - 50.0) / 260.0)
            out[i] += a * env * am * math.sin(phase + ph)
    return filtered(out, "lp", 2500.0, 0.8)


def _christen_chime():
    # brass+glass: tiny bell pair C6+E6 over soft brass under-tone, gentle - NOT hero-loud
    out = buf(600)
    mix(out, bell(1046.50, 2.0, 1.8, 130, 240, 500), 0.0, 0.85)
    mix(out, bell(1318.51, 2.0, 1.8, 130, 240, 500), 90.0, 0.70)
    mix(out, brass([261.63, 392.00], 80, 280, 500), 40.0, db(-14.0))
    return filtered(out, "lp", 7000.0, 0.8)


def _bound_chord():
    # brass hero: warm C4+E4+G4+C5 bloom, 120ms slow attack, C6 bell crown, felt tail
    out = buf(1200)
    mix(out, brass([261.63, 329.63, 392.00, 523.25], 120, 700, 1150), 0.0, 1.0)
    mix(out, bell(1046.50, 2.0, 1.8, 180, 420, 900), 150.0, 0.45)
    return out


def _bind_press():
    # wax: heavy soft thump drop 150->80 + wax squish + faint seal-ring bell G4 at -12 dB
    out = buf(300)
    mix(out, sine_drop(150, 80, 110, 170, 300), 0.0, 1.0)
    mix(out, noise_env(90, "lp", 600.0, 0.8, 8.0, 45.0), 10.0, 0.5)
    mix(out, bell(392.00, 2.0, 1.6, 90, 150, 260), 30.0, db(-12.0))
    return out


def _drawer_slide():
    # wood-on-felt: lp slide 180ms + wooden stop tok 220 + faint card ruffle at -16 dB
    out = buf(260)
    mix(out, filtered(noise_env(180, "bp", 480.0, 0.7, 55.0, 90.0), "lp", 1500.0, 0.8), 0.0, 0.9)
    mix(out, tok(220, [60, 40, 25, 16], 85), 172.0, 0.85)
    mix(out, noise_env(60, "bp", 2500.0, 1.2, 10.0, 30.0), 115.0, db(-16.0))
    return out


def _drawer_tuck():
    # wood-on-felt: shorter slide + felt-damped clunk 180 + tiny brass bail clink at -16 dB
    out = buf(220)
    mix(out, filtered(noise_env(115, "bp", 460.0, 0.7, 30.0, 60.0), "lp", 1500.0, 0.8), 0.0, 0.85)
    mix(out, tok(180, [55, 30], 110, db(-8.0), modes=[1.0, 2.76]), 105.0, 0.95)
    mix(out, tick_metal(1400.0, 50.0), 148.0, db(-16.0))
    return out


def _ink_wipe():
    # parchment: soft bp noise wipe, very quiet (Ui bus - peak -12)
    return noise_env(250, "bp", 1200.0, 1.0, 90.0, 110.0)


def _tag_untie():
    # twine+parchment: 2 chirp pulls + paper slide-off + tiny felt landing (once per save, ever)
    out = buf(450)
    mix(out, sweep_noise(70, 1200, 2400, 1.3, 10, 35), 0.0, 0.8)
    mix(out, sweep_noise(70, 1200, 2400, 1.3, 10, 35), 120.0, 0.9)
    mix(out, noise_env(150, "bp", 900.0, 0.9, 40.0, 80.0), 225.0, 0.6)
    mix(out, tok(240, [70, 42, 26], 70), 375.0, 0.5)
    return out


def _medallion_tap(v):
    # brass: small bell tap A5 880 ratio 2.5, felt stop (Ui bus - peak -12)
    out = buf(120)
    mix(out, bell(880.0, 2.5, 2.4 if v == 0 else 2.0, 55, 70, 118), 0.0, 1.0)
    mix(out, noise_env(4, "hp", 2800.0, 0.8, 0.8, 2.5), 0.0, db(-16.0 if v == 0 else -14.0))
    return out


def _ui_tap(v):
    # wood micro: tiny tok an octave above furniture - E5 / A5, both in the Am triad
    # (Ui bus - peak -12; the UI law: taps never shout)
    return tok(659.26 if v == 0 else 880.0, [22, 14], 60, db(-14.0), modes=[1.0, 2.76])


def _toast_pin():
    # parchment: tiny paper flick + soft tok pin (Ui bus - peak -12)
    out = buf(150)
    mix(out, noise_env(35, "bp", 2000.0, 1.3, 4.0, 18.0), 0.0, 0.8)
    mix(out, tok(620, [30, 18], 90, db(-12.0), modes=[1.0, 2.76]), 45.0, 0.7)
    return out


def _parts_settle(v):
    # wood: 2-3 soft felt-damped toks 200-300 spread over 400ms, very quiet -
    # the ONLY sound allowed to end the stillness (canonical seam name: parts_settle)
    out = buf(420)
    if v == 0:
        seq = [(0.0, 260, 0.80), (180.0, 210, 0.70), (330.0, 285, 0.50)]
    else:
        seq = [(0.0, 240, 0.75), (150.0, 300, 0.60), (320.0, 200, 0.70)]
    for at, f0, g in seq:
        mix(out, tok(f0, [80, 50, 30, 18], 200, db(-14.0)), at, g)
    return out


# name, fade_out_ms, peak_db, builder - one row per P0 file (spec: inventory groups 2/3/4)
WAVE_4A = [
    ("snap_0",             12.0,  -3.0, lambda: _snap(0)),
    ("snap_1",             12.0,  -3.0, lambda: _snap(1)),
    ("core_wake_0",        50.0,  -3.0, _core_wake),
    ("seal_channel_0",     12.0,  -3.0, _seal_channel),
    ("seal_crack_0",       30.0,  -3.0, _seal_crack),
    ("lid_spring_0",       12.0,  -3.0, _lid_spring),
    ("reveal_common_0",    10.0,  -3.0, _reveal_common),
    ("reveal_rare_0",      40.0,  -3.0, _reveal_rare),
    ("reveal_epic_0",      80.0,  -3.0, _reveal_epic),
    ("bound_chord_0",      60.0,  -3.0, _bound_chord),
    ("bind_press_0",       15.0,  -3.0, _bind_press),
    ("drawer_slide_0",     15.0,  -3.0, _drawer_slide),
    ("drawer_tuck_0",      12.0,  -3.0, _drawer_tuck),
    ("medallion_tap_0",     8.0, -12.0, lambda: _medallion_tap(0)),
    ("medallion_tap_1",     8.0, -12.0, lambda: _medallion_tap(1)),
    ("ui_tap_0",            6.0, -12.0, lambda: _ui_tap(0)),
    ("ui_tap_1",            6.0, -12.0, lambda: _ui_tap(1)),
    ("toast_pin_0",        10.0, -12.0, _toast_pin),
    ("parts_settle_0",     30.0,  -3.0, lambda: _parts_settle(0)),
    ("parts_settle_1",     30.0,  -3.0, lambda: _parts_settle(1)),
    ("wax_stamp_0",        12.0,  -3.0, _wax_stamp),
    ("coin_scrap_0",       15.0,  -3.0, lambda: _coin_scrap(0)),
    ("coin_scrap_1",       15.0,  -3.0, lambda: _coin_scrap(1)),
    ("still_drip_0",       10.0,  -3.0, lambda: _still_drip(0)),
    ("still_drip_1",       10.0,  -3.0, lambda: _still_drip(1)),
    ("still_drip_2",       10.0,  -3.0, lambda: _still_drip(2)),
    ("ledger_open_0",      20.0, -12.0, _ledger_open),
    ("doorstep_untie_0",   20.0,  -3.0, _doorstep_untie),
    ("forge_melt_0",       40.0,  -3.0, _forge_melt),
    ("fettle_greet_0",     30.0,  -3.0, _fettle_greet),
    ("fettle_appraise_0",  25.0,  -3.0, _fettle_appraise),
    ("fettle_apologise_0", 30.0,  -3.0, _fettle_apologise),
    ("switch_throw_0",     15.0,  -3.0, _switch_throw),
    ("route_step_0",       12.0,  -3.0, lambda: _route_step(0)),
    ("route_step_1",       12.0,  -3.0, lambda: _route_step(1)),
    ("fork_reveal_0",      40.0,  -3.0, _fork_reveal),
    ("gear_tick_0",         6.0, -12.0, lambda: _gear_tick(0)),
    ("gear_tick_1",         6.0, -12.0, lambda: _gear_tick(1)),
    ("gear_tick_2",         6.0, -12.0, lambda: _gear_tick(2)),
    ("new_stamp_0",        10.0,  -3.0, _new_stamp),
    ("equip_whoosh_0",     12.0,  -3.0, _equip_whoosh),
    ("strain_creak_0",     30.0,  -3.0, _strain_creak),
    ("christen_chime_0",   40.0,  -3.0, _christen_chime),
    ("ink_wipe_0",         20.0, -12.0, _ink_wipe),
    ("tag_untie_0",        25.0,  -3.0, _tag_untie),
]


def wave_4a():
    for name, fade_ms, peak_db, builder in WAVE_4A:
        random.seed(zlib.crc32(name.encode("ascii")))
        write(name, builder(), fade_ms, peak_db)
    print("DONE wave-4a: %d wavs -> %s" % (len(WAVE_4A), os.path.abspath(OUT)))


# =========================================================================================
# WAVE 4b - LOOPS + STATE HUMS + PERIL BED + THE WOUND SPRING STEMS (loop/stem lane C)
# design/gdd/audio-full-game.md SECTION 4 (tech plan) is canonical. Where the group-5/6
# spec rows and the tech plan disagree, the tech plan wins (open questions Q4/Q5 resolution):
#   - soul_hum is 4.000s CONSTANT-amplitude (the engine AMs it on the shared clock), not an
#     8s baked-breath file; peril_bed is EXACTLY 44100 frames of the 108+110 Hz pair at
#     constant blended amplitude (the 2 Hz pulse is code-side AM, not baked).
#   - stems are 80 BPM / 16 bars / 48.000s = 2,116,800 frames (Q4), victory half-beat 375ms.
# SEED DISCIPLINE (identical to wave-4a): every file re-seeds from zlib.crc32 of its own name
# so adding this batch shifts NO bytes of the legacy 14 or wave-4a. amb_nook is a pure -6 dB
# scaling of the already-normalised amb_workshop buffer, so it consumes no fresh RNG.
# LOOP FILES: no fade-out (that would break the seam) - seamlessness comes from integer-cycle
# tonal content, wrap-crossfaded noise, and a standard smpl loop chunk (0 -> end) written with
# pure struct.pack so Godot's WAV importer "Detect From WAV" honours the loop point.
# KEY LAW: all tonal loops + all four stems live in C major / A minor.
# =========================================================================================

AMB_OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "audio", "ambience")
MUS_OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "audio", "music")
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))

_WAVE_4B_ROWS = []   # (file, dur_ms, peak_dbfs, rms_dbfs, loop_frames) for the summary table


def _smpl_chunk(loop_frames):
    """Standard RIFF smpl chunk marking one forward loop 0 -> loop_frames-1, playCount 0 (inf)."""
    sample_period = int(round(1.0e9 / SR))          # nanoseconds per frame (44100 -> 22676)
    header = struct.pack("<9I", 0, 0, sample_period, 60, 0, 0, 0, 1, 0)
    loop = struct.pack("<6I", 0, 0, 0, loop_frames - 1, 0, 0)   # id, type=forward, start, end, frac, count
    data = header + loop
    return b"smpl" + struct.pack("<I", len(data)) + data


def _write_loop(out_dir, name, sig, peak_db=-3.0, loop=True, normalize=True, category="LOOP"):
    """Finalize a loop/stem file: optional peak-norm (no fade-out), int16 PCM, manual RIFF with
    an optional smpl loop chunk. Returns nothing; appends a summary row. Byte-deterministic."""
    n = len(sig)
    if normalize:
        peak = max(1e-9, max(abs(s) for s in sig))
        sig = [s * db(peak_db) / peak for s in sig]
    ints = [int(max(-1.0, min(1.0, s)) * 32767) for s in sig]
    pcm = b"".join(struct.pack("<h", v) for v in ints)
    fmt = b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16)
    data = b"data" + struct.pack("<I", len(pcm)) + pcm
    body = b"WAVE" + fmt + data + (_smpl_chunk(n) if loop else b"")
    riff = b"RIFF" + struct.pack("<I", len(body)) + body
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, name + ".wav"), "wb") as f:
        f.write(riff)
    apk = max(1, max(abs(v) for v in ints))
    peak_dbfs = 20.0 * math.log10(apk / 32767.0)
    rms = math.sqrt(sum(v * v for v in ints) / max(1, n))
    rms_dbfs = 20.0 * math.log10(max(1.0, rms) / 32767.0)
    _WAVE_4B_ROWS.append((name, int(1000.0 * n / SR), peak_dbfs, rms_dbfs, n if loop else 0))
    print("MANIFEST %-18s %6dms peak %6.1f rms %6.1f loop %7d [%s]" % (
        name, int(1000.0 * n / SR), peak_dbfs, rms_dbfs, n if loop else 0, category))


def _seamless_noise(n, kind, f, q, xf_ms=400.0):
    """A seamlessly-loopable filtered-noise buffer of exactly n frames. Generates n + xf frames
    with continuous filter state, then wrap-blends the extra tail into the head so frame n-1 ->
    frame 0 is a consecutive-sample transition (no click)."""
    x = int(SR * xf_ms / 1000.0)
    raw = filtered([random.uniform(-1.0, 1.0) for _ in range(n + x)], kind, f, q)
    out = [0.0] * n
    for i in range(n):
        if i < x:
            a = i / float(x)
            out[i] = raw[i] * a + raw[n + i] * (1.0 - a)
        else:
            out[i] = raw[i]
    return out


def _apply_lfo(sig, hz, depth, base=1.0):
    """Multiply sig by base + depth*sin(2pi*hz*t). Caller MUST pick hz so hz*len(sig)/SR is an
    integer (so the envelope value at the wrap equals its value at 0 - the loop stays seamless)."""
    n = len(sig)
    for i in range(n):
        sig[i] *= base + depth * math.sin(2.0 * math.pi * hz * i / SR)
    return sig


def mix_at(dst, src, at_frame, gain=1.0):
    """Sample-exact mix (no ms rounding) - the stems must be frame-locked to each other."""
    for i, s in enumerate(src):
        j = at_frame + i
        if 0 <= j < len(dst):
            dst[j] += s * gain
    return dst


def _creak(f0, dur_ms, bend, amp=1.0):
    """A quiet stick-slip wood/leather creak approximation: two modal partials bending upward
    with a slow AM stutter, lowpassed. Baked ambience texture only - NOT the SOURCE-tier
    standalone creak one-shot the spec defers; it rides low inside the bed."""
    out = buf(dur_ms)
    n = len(out)
    for m, r in enumerate([1.0, 2.76]):
        ph = random.uniform(0.0, math.pi)
        a = amp / (1.0 + m * 0.8)
        phase = 0.0
        for i in range(n):
            t = i / SR
            tm = t * 1000.0
            g = min(1.0, tm / (dur_ms * 0.7))
            f = f0 * ((1.0 + bend) ** g) * r
            phase += 2.0 * math.pi * f / SR
            am = 0.6 + 0.4 * math.sin(2.0 * math.pi * 9.0 * t + ph)
            env = tm / 60.0 if tm < 60.0 else math.exp(-(tm - 60.0) / (dur_ms * 0.55))
            out[i] += a * env * am * math.sin(phase + ph)
    return filtered(out, "lp", 2200.0, 0.8)


# --- ambience beds ----------------------------------------------------------------------
AMB_FRAMES = 705600   # 16.000 s exactly (16 * 44100); n/SR = 16 so integer-cycle LFOs are easy


def _amb_workshop():
    # air bed (barely-there lowpassed brown noise) + soft wood-brass mantel clock ~0.8 Hz with
    # humanized micro-timing BAKED at loop-safe positions (guard-zoned off the seam per task).
    n = AMB_FRAMES
    air = _seamless_noise(n, "lp", 380.0, 0.7)
    air = filtered(air, "lp", 300.0, 0.7)                       # doubly soft - felt, not heard
    out = [s * db(-16.0) for s in air]                          # air sits well under the ticks
    t = 0.62
    idx = 0
    while t < 15.35:                                            # guard the last ~0.6 s (tick tail)
        f0 = 700.0 if idx % 2 == 0 else 624.0                  # tick / tock
        tk = tok(f0, [26.0, 15.0], 72.0, db(-10.0), modes=[1.0, 2.76])
        mix_at(out, tk, int(SR * t), 0.9)
        mix_at(out, tick_metal(f0 * 2.0, 40.0), int(SR * t), db(-20.0))   # faint brass edge
        t += 1.25 + random.uniform(-0.06, 0.06)                # ~0.8 Hz, never metronomic
        idx += 1
    return out, n


def _amb_barrow():
    # market quiet: low wind over canvas (LFO breath) + Fettle's bellows-ember loop + sparse
    # cart creak + a couple of canvas flaps + ember crackle. All events in the loop-safe zone.
    n = AMB_FRAMES
    wind = _apply_lfo(_seamless_noise(n, "lp", 520.0, 0.7), 0.25, 0.45)   # 0.25 Hz -> 4 cycles
    bellows = _apply_lfo(_seamless_noise(n, "lp", 300.0, 0.7), 0.25, 0.6)  # ~0.25 Hz ember breath
    out = [wind[i] * db(-15.0) + bellows[i] * db(-19.0) for i in range(n)]
    for at in (3.1, 9.7):                                       # sparse cart creaks
        mix_at(out, _creak(150.0, 620.0, 0.22, 1.0), int(SR * at), db(-22.0))
    for at in (1.4, 7.2, 12.9):                                 # soft canvas flaps
        mix_at(out, noise_env(180.0, "lp", 800.0, 0.8, 40.0, 110.0), int(SR * at), db(-24.0))
    for _ in range(14):                                        # ember crackle ticks
        at = random.uniform(0.6, 15.2)
        mix_at(out, noise_env(16.0, "hp", 3000.0, 0.8, 2.0, 7.0), int(SR * at), db(-26.0))
    return out, n


def _amb_run():
    # travel quiet: low wind, drier than the Barrow (rumble rolled off), + sparse leather creaks.
    n = AMB_FRAMES
    wind = _apply_lfo(_seamless_noise(n, "lp", 720.0, 0.7), 0.1875, 0.4)  # 0.1875 Hz -> 3 cycles
    wind = filtered(wind, "hp", 120.0, 0.7)                    # drier: roll off the low rumble
    out = [s * db(-15.0) for s in wind]
    for at in (2.3, 6.1, 10.4, 14.0):                          # satchel-leather creaks between steps
        mix_at(out, _creak(210.0, 380.0, 0.18, 1.0), int(SR * at), db(-24.0))
    return out, n


# --- state hums + peril bed -------------------------------------------------------------
def _tonal_loop(frames, partials):
    """Constant-amplitude sum of sines. partials = [(freq, amp), ...]; every freq must complete
    an integer number of cycles across `frames` for a seamless loop (asserted by the caller)."""
    out = [0.0] * frames
    for f, a in partials:
        for i in range(frames):
            out[i] += a * math.sin(2.0 * math.pi * f * i / SR)
    return out


def _soul_hum():
    # the one living sound in the workshop: warm amber sine blend, A2 fundamental + A3/A4
    # partials, CONSTANT amplitude (the engine AMs it in phase with the visual sleep-breath).
    n = 176400   # 4.000 s -> 110 Hz = 440 cycles, 220 = 880, 440 = 1760 (all integer, seamless)
    return _tonal_loop(n, [(110.0, 1.0), (220.0, db(-8.0)), (440.0, db(-18.0))]), n


def _core_hum(detune_hz):
    # combat room tone: one living core's hum (110 Hz + 2 soft partials), constant amplitude;
    # the engine maps player volume from the core's HP fraction. _0 = yours (110), _1 = theirs
    # (111, ~0.9% detune baked so the pair loops clean at 6.000s - "two souls, not one").
    n = 264600   # 6.000 s -> 110*6=660, 111*6=666, partials all integer -> seamless
    f = 110.0 + detune_hz
    return _tonal_loop(n, [(f, 1.0), (f * 2.0, db(-10.0)), (f * 3.0, db(-14.0))]), n


def _peril_bed():
    # the promoted core-peril STATE bed: the 108+110 Hz beating pair, constant blended
    # amplitude, EXACTLY 44100 frames (108 and 110 both integer-cycle in 1.000 s). The 2 Hz
    # acoustic beat is inherent to the sum; the phase-locked 2 Hz pulse is applied code-side.
    n = 44100
    return _tonal_loop(n, [(108.0, 1.0), (110.0, 1.0)]), n


# --- THE WOUND SPRING - authored note-data (C major / A minor, 80 BPM, 16 bars) ----------
BPM = 80.0
BEAT_SAMP = int(round(SR * 60.0 / BPM))      # 33075 frames = 0.750 s exactly
BARS = 16
BEATS_PER_BAR = 4
STEM_FRAMES = BARS * BEATS_PER_BAR * BEAT_SAMP   # 2,116,800 = 48.000 s exactly
VICTORY_HALF_BEAT_MS = int(round(1000.0 * BEAT_SAMP / SR / 2.0))   # 375 ms

NOTE = {
    "A2": 110.00, "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00,
    "A3": 220.00, "B3": 246.94, "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
    "G4": 392.00, "A4": 440.00, "B4": 493.88, "C5": 523.25, "D5": 587.33, "E5": 659.25,
    "F5": 698.46, "G5": 783.99, "A5": 880.00, "B5": 987.77, "C6": 1046.50, "D6": 1174.66,
    "E6": 1318.51, "F6": 1396.91, "G6": 1567.98, "A6": 1760.00,
}


def _onset(bar, beat):
    return (bar * BEATS_PER_BAR + beat) * BEAT_SAMP


# (bar, beat, note, dur_beats, vel) - lead line: phrase(0-3) rest(4-5) phrase(6-9) rest(10-11) return(12-15)
_MELODY = [
    (0, 0, "E5", 1, 0.90), (0, 1, "A5", 1, 1.00), (0, 2, "G5", 1, 0.85), (0, 3, "E5", 1, 0.80),
    (1, 0, "A5", 2, 1.00),
    (2, 0, "C6", 1, 0.90), (2, 1, "B5", 1, 0.85), (2, 2, "A5", 2, 0.95),
    (3, 0, "G5", 1, 0.85), (3, 1, "E5", 1, 0.80), (3, 2, "A5", 2, 0.90),
    (6, 0, "G5", 1, 0.85), (6, 1, "C6", 1, 0.95), (6, 2, "E6", 1, 1.00), (6, 3, "D6", 1, 0.90),
    (7, 0, "C6", 2, 0.95),
    (8, 0, "D6", 1, 0.90), (8, 1, "C6", 1, 0.85), (8, 2, "G5", 1, 0.80), (8, 3, "E5", 1, 0.80),
    (9, 0, "G5", 2, 0.90),
    (12, 0, "E5", 1, 0.90), (12, 1, "A5", 1, 1.00), (12, 2, "G5", 1, 0.85), (12, 3, "E5", 1, 0.80),
    (13, 0, "A5", 2, 1.00),
    (14, 0, "C6", 1, 0.90), (14, 1, "B5", 1, 0.85), (14, 2, "A5", 1, 0.90), (14, 3, "G5", 1, 0.80),
    (15, 0, "A5", 4, 1.00),
]

# answering bells - octave-up, sparser, sit in the lead's rests (bars 4-5, 10-11) + light counters
_BELLS = [
    (4, 0, "E6", 1, 0.70), (4, 2, "C6", 1, 0.60),
    (5, 0, "A5", 2, 0.65), (5, 2, "E6", 1, 0.50),
    (10, 0, "G5", 1, 0.60), (10, 2, "E6", 1, 0.55),
    (11, 0, "C6", 2, 0.60), (11, 2, "G6", 1, 0.45),
    (1, 2, "E6", 1, 0.40), (7, 2, "G6", 1, 0.45), (13, 2, "E6", 1, 0.40),
]

# soft brass pad - I-vi-IV-V colours in C / Am, one chord per 2 bars, stays in key
_PAD = [
    (0, ["A3", "C4", "E4"], 0.85),   # Am
    (2, ["C4", "E4", "G4"], 0.85),   # C
    (4, ["F3", "A3", "C4"], 0.80),   # F
    (6, ["C4", "E4", "G4"], 0.85),   # C
    (8, ["G3", "B3", "D4"], 0.80),   # G
    (10, ["A3", "C4", "E4"], 0.85),  # Am
    (12, ["F3", "A3", "C4"], 0.80),  # F
    (14, ["A3", "C4", "E4"], 0.90),  # Am (resolve)
]


def _stem_melody():
    out = [0.0] * STEM_FRAMES
    for bar, beat, note, dur, vel in _MELODY:
        dur_ms = dur * (60.0 / BPM) * 1000.0 + 450.0
        mix_at(out, bell(NOTE[note], 3.01, 3.5, 90.0, 600.0, dur_ms), _onset(bar, beat), vel)
    return filtered(out, "lp", 7000.0, 0.8)


def _stem_bells():
    out = [0.0] * STEM_FRAMES
    for bar, beat, note, dur, vel in _BELLS:
        dur_ms = dur * (60.0 / BPM) * 1000.0 + 400.0
        mix_at(out, bell(NOTE[note], 3.5, 3.0, 80.0, 450.0, dur_ms), _onset(bar, beat), vel)
    return filtered(out, "lp", 7500.0, 0.8)


def _stem_pad():
    out = [0.0] * STEM_FRAMES
    for start_bar, chord, vel in _PAD:
        dur_ms = 2 * BEATS_PER_BAR * (60.0 / BPM) * 1000.0 + 800.0   # 2 bars + release
        mix_at(out, brass([NOTE[c] for c in chord], 260.0, 2500.0, dur_ms, 0.5), _onset(start_bar, 0), vel)
    return [s * db(-9.0) for s in out]                               # pad sits under the tines


def _stem_pulse():
    # low felt-damped tok heartbeat: strong "lub" A2 on each downbeat, soft "dub" E3 on beat 2 -
    # ~40 bpm felt pulse. This is the stem that survives alone into combat.
    out = [0.0] * STEM_FRAMES
    for bar in range(BARS):
        mix_at(out, tok(110.00, [110.0, 60.0, 35.0], 260.0, db(-14.0), modes=[1.0, 2.76, 5.40]),
               _onset(bar, 0), 0.9)
        mix_at(out, tok(164.81, [90.0, 50.0, 30.0], 220.0, db(-14.0), modes=[1.0, 2.76, 5.40]),
               _onset(bar, 2), 0.5)
    return [s * db(-4.0) for s in out]


def _render_stems():
    # render each stem under its own stable per-file seed, then normalise ALL FOUR by ONE shared
    # gain so their relative balance is preserved and no stem clips (the quartet mixes to ~-6 dBFS
    # peak, each partial stem lower). BENCH plays all four at 0 dB - so the file balance IS the mix.
    stems = {}
    for name, fn in (("mus_bench_melody", _stem_melody), ("mus_bench_bells", _stem_bells),
                     ("mus_bench_pad", _stem_pad), ("mus_bench_pulse", _stem_pulse)):
        random.seed(zlib.crc32(name.encode("ascii")))
        stems[name] = fn()
    full = [0.0] * STEM_FRAMES
    for sig in stems.values():
        for i in range(STEM_FRAMES):
            full[i] += sig[i]
    peaks = [max(1e-9, max(abs(s) for s in sig)) for sig in stems.values()]
    peaks.append(max(1e-9, max(abs(s) for s in full)))
    g = db(-6.0) / max(peaks)
    for name in ("mus_bench_melody", "mus_bench_bells", "mus_bench_pad", "mus_bench_pulse"):
        _write_loop(MUS_OUT, name, [s * g for s in stems[name]], normalize=False, category="STEM")


def _write_stems_manifest():
    manifest = {
        "title": "The Wound Spring - workshop bench motif",
        "key": "C major / A minor",
        "bpm": int(BPM),
        "bars": BARS,
        "beats_per_bar": BEATS_PER_BAR,
        "sr": SR,
        "beat_frames": BEAT_SAMP,
        "beat_ms": int(round(1000.0 * BEAT_SAMP / SR)),
        "length_frames": STEM_FRAMES,
        "length_ms": int(round(1000.0 * STEM_FRAMES / SR)),
        "victory_half_beat_ms": VICTORY_HALF_BEAT_MS,
        "loop": {"start": 0, "end": STEM_FRAMES - 1},
        "stems": ["mus_bench_melody", "mus_bench_bells", "mus_bench_pad", "mus_bench_pulse"],
        "dir": "res://audio/music/",
    }
    blob = json.dumps(manifest, indent=2)
    os.makedirs(MUS_OUT, exist_ok=True)
    for path in (os.path.join(MUS_OUT, "stems_manifest.json"),
                 os.path.join(TOOLS_DIR, "stems_manifest.json")):
        with open(path, "w", encoding="ascii", newline="\n") as f:
            f.write(blob)
    print("MANIFEST stems_manifest.json  bpm %d bars %d frames %d half-beat %dms -> %s (+ tools/audio/)" % (
        int(BPM), BARS, STEM_FRAMES, VICTORY_HALF_BEAT_MS, os.path.abspath(MUS_OUT)))


def wave_4b():
    # --- ambience beds (audio/ambience/) ---
    random.seed(zlib.crc32(b"amb_workshop"))
    ws, _ = _amb_workshop()
    ws_peak = max(1e-9, max(abs(s) for s in ws))
    ws_norm = [s * db(-18.0) / ws_peak for s in ws]
    _write_loop(AMB_OUT, "amb_workshop", ws_norm, normalize=False, category="AMB")
    _write_loop(AMB_OUT, "amb_nook", [s * db(-6.0) for s in ws_norm], normalize=False, category="AMB")
    for name, fn, pk in (("amb_barrow", _amb_barrow, -18.0), ("amb_run", _amb_run, -20.0)):
        random.seed(zlib.crc32(name.encode("ascii")))
        sig, _ = fn()
        _write_loop(AMB_OUT, name, sig, peak_db=pk, category="AMB")
    # --- state hums + peril bed (audio/ambience/) ---
    for name, fn, pk in (("soul_hum", lambda: _soul_hum(), -16.0),
                         ("core_hum_0", lambda: _core_hum(0.0), -16.0),
                         ("core_hum_1", lambda: _core_hum(1.0), -16.0),
                         ("peril_bed", lambda: _peril_bed(), -12.0)):
        random.seed(zlib.crc32(name.encode("ascii")))
        sig, _ = fn()
        _write_loop(AMB_OUT, name, sig, peak_db=pk, category="STATE")
    # --- The Wound Spring stems + manifest (audio/music/) ---
    _render_stems()
    _write_stems_manifest()
    print("DONE wave-4b: %d loops/stems -> %s + %s" % (
        len(_WAVE_4B_ROWS), os.path.abspath(AMB_OUT), os.path.abspath(MUS_OUT)))
    print("\n=== WAVE 4b SUMMARY (file | dur | peak dBFS | rms dBFS | loop frames) ===")
    for name, dur, pk, rms, lf in _WAVE_4B_ROWS:
        print("  %-18s %6dms  %6.1f  %6.1f  %8d" % (name, dur, pk, rms, lf))


if __name__ == "__main__":
    main()
