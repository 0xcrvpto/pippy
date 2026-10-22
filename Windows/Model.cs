using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace Pippy;
public enum Kind { Rally, Blink, Mochi }
public enum Cue { Start, Halfway, Complete }
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
    public Dictionary<Kind, DateTimeOffset> Last { get; set; } = new();
    public string LastWorkoutSlot { get; set; } = "";
    public WindowHours Hours => new(WorkoutStart, WorkoutEnd);
    public void Normalize() {
        var fallback = new Settings();
        Enabled ??= new(); Minutes ??= new(); Last ??= new();
        foreach (var kind in Enum.GetValues<Kind>()) {
            Enabled.TryAdd(kind, true);
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
