using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace Pippy;
public enum Kind { Rally, Blink, Mochi }
public enum Cue { Start, Halfway, Complete }
public enum SoundSet { Bells, Marimba, Chimes, Kalimba, Woodblock }
public static class Sounds {
    public static string Title(SoundSet set) => set switch {
        SoundSet.Bells => "Soft Bells", SoundSet.Chimes => "Wind Chimes", _ => set.ToString()
    };
    // The original bells keep their Blink* filenames, shared with the Mac app.
    static string Prefix(SoundSet set) => set == SoundSet.Bells ? "Blink" : set.ToString();
    public static string File(SoundSet set, Cue cue) => Prefix(set) + cue;
    public static string Nudge(SoundSet set) => File(set, Cue.Start);
    public static string Preview(SoundSet set) => Prefix(set) + "Preview";
    public static SoundSet Default(Kind kind) => kind switch { Kind.Rally => SoundSet.Marimba, Kind.Blink => SoundSet.Bells, _ => SoundSet.Kalimba };
}
public static class Feedback {
    public const string Email = "0xcrvpto@webuild3.xyz";
    public const string Telegram = "https://t.me/i0xcrvpto";
    public static string Version => typeof(Feedback).Assembly.GetName().Version is { } v ? $"{v.Major}.{v.Minor}" : "dev";
    public static string MailtoUri() {
        string body = "What happened, or what would you like to see?\n\n\n—\nPippy " + Version + " · " + Environment.OSVersion.VersionString;
        return "mailto:" + Email + "?subject=" + Uri.EscapeDataString("Pippy feedback") + "&body=" + Uri.EscapeDataString(body);
    }
}
/// Stepping for the scroll picker: wraps or clamps, and steps over excluded values.
public static class Picker {
    public static int Step(IReadOnlyList<int> values, int index, int delta, bool wraps, Func<int,bool> skip) {
        if (delta == 0) return index;
        int direction = delta > 0 ? 1 : -1, remaining = Math.Abs(delta), candidate = index;
        for (int guard = 0; guard < values.Count * 2 && remaining > 0; guard++) {
            int next = candidate + direction;
            if (wraps) next = (next + values.Count) % values.Count;
            if (next < 0 || next >= values.Count) break;
            candidate = next;
            if (!skip(values[candidate])) remaining--;
        }
        return candidate != index && !skip(values[candidate]) ? candidate : index;
    }
    public static int Nearest(IReadOnlyList<int> values, int value) {
        int best = 0;
        for (int i = 1; i < values.Count; i++) if (Math.Abs(values[i] - value) < Math.Abs(values[best] - value)) best = i;
        return best;
    }
    public static readonly IReadOnlyList<int> QuarterHours = Enumerable.Range(0, 96).Select(i => i * 15).ToList();
}
public record WindowHours(int Start, int End) {
    public bool Valid => Start >= 0 && Start < 1440 && End >= 0 && End < 1440 && Start != End;
    public bool Contains(int minute) => Valid && (Start < End ? minute >= Start && minute < End : minute >= Start || minute < End);
    public bool Slot(int minute, int interval) => interval > 0 && Contains(minute) && ((minute - Start + 1440) % 1440) % interval == 0;
}
public sealed class Settings {
    public bool Sound { get; set; } = true;
    public bool ReduceMotion { get; set; }
    public int WorkoutStart { get; set; } = 840;
    public int WorkoutEnd { get; set; } = 1080;
    public Dictionary<Kind, bool> Enabled { get; set; } = new() { [Kind.Rally] = true, [Kind.Blink] = true, [Kind.Mochi] = true };
    public Dictionary<Kind, int> Minutes { get; set; } = new() { [Kind.Rally] = 60, [Kind.Blink] = 20, [Kind.Mochi] = 45 };
    public Dictionary<Kind, SoundSet> SoundSets { get; set; } = Enum.GetValues<Kind>().ToDictionary(k => k, Sounds.Default);
    public Dictionary<Kind, DateTimeOffset> Last { get; set; } = new();
    public string LastWorkoutSlot { get; set; } = "";
    public WindowHours Hours => new(WorkoutStart, WorkoutEnd);
    public void Normalize() {
        var fallback = new Settings();
        Enabled ??= new(); Minutes ??= new(); Last ??= new(); SoundSets ??= new();
        foreach (var kind in Enum.GetValues<Kind>()) {
            Enabled.TryAdd(kind, true);
            if (!SoundSets.TryGetValue(kind, out var set) || !Enum.IsDefined(set)) SoundSets[kind] = Sounds.Default(kind);
            if (!Minutes.TryGetValue(kind, out int value) || !Choices(kind).Contains(value)) Minutes[kind] = fallback.Minutes[kind];
        }
        if (!Hours.Valid) { WorkoutStart = 840; WorkoutEnd = 1080; }
    }
    public static IEnumerable<int> Choices(Kind kind) => kind switch {
        Kind.Rally => Enumerable.Range(1, 8).Select(i => i * 30),
        Kind.Blink => Enumerable.Range(1, 12).Select(i => i * 5),
        _ => Enumerable.Range(1, 8).Select(i => i * 15)
    };
}
public sealed class SettingsStore {
    readonly string path;
    public SettingsStore(string path) { this.path = path; }
    public Settings Load() {
        try {
            var value = File.Exists(path) ? JsonSerializer.Deserialize<Settings>(File.ReadAllText(path)) ?? new() : new Settings();
            value.Normalize(); return value;
        } catch (Exception e) when (e is IOException || e is JsonException || e is UnauthorizedAccessException) { return new(); }
    }
    public void Save(Settings value) {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllText(path + ".tmp", JsonSerializer.Serialize(value, new JsonSerializerOptions { WriteIndented = true }));
        File.Move(path + ".tmp", path, true);
    }
}
public sealed class Schedule {
    readonly Settings settings;
    readonly Dictionary<Kind, DateTimeOffset> snoozes = new();
    public Schedule(Settings settings, DateTimeOffset now) {
        this.settings = settings;
        foreach (var kind in Enum.GetValues<Kind>()) settings.Last.TryAdd(kind, now);
    }
    public void Snooze(Kind kind, DateTimeOffset now) { snoozes[kind] = now.AddMinutes(10); }
    public void Reset(Kind kind, DateTimeOffset now) { settings.Last[kind] = now; snoozes.Remove(kind); }
    public Kind? Due(DateTimeOffset now) {
        foreach (var kind in Enum.GetValues<Kind>()) {
            if (!settings.Enabled[kind]) continue;
            if (snoozes.TryGetValue(kind, out var until)) {
                if (now < until) continue;
                snoozes.Remove(kind); settings.Last[kind] = now; return kind;
            }
            if (kind == Kind.Rally) {
                var slot = now.ToString("yyyy-MM-dd-HH:mm");
                if (settings.Hours.Slot(now.Hour*60+now.Minute, settings.Minutes[kind]) && slot != settings.LastWorkoutSlot) {
                    settings.LastWorkoutSlot = slot; return kind;
                }
            } else if (now.Hour >= 11 && now.Hour < 23 && (now - settings.Last[kind]).TotalMinutes >= settings.Minutes[kind]) {
                settings.Last[kind] = now; return kind;
            }
        }
        return null;
    }
}
public sealed class EyeBreak {
    readonly DateTimeOffset started;
    bool halfway, complete;
    public EyeBreak(DateTimeOffset started) { this.started = started; }
    public int Remaining(DateTimeOffset now) => Math.Max(0, (int)Math.Ceiling(20 - (now-started).TotalSeconds));
    public Cue? Tick(DateTimeOffset now) {
        int remaining = Remaining(now);
        if (remaining == 0 && !complete) { complete = true; return Cue.Complete; }
        if (remaining > 0 && remaining <= 10 && !halfway) { halfway = true; return Cue.Halfway; }
        return null;
    }
}
