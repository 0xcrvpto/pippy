using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using Forms = System.Windows.Forms;

namespace Pippy;
static class Program {
    [STAThread] static int Main(string[] args) {
        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        if (args.Length > 0 && args[0] == "--self-test") return Checks.Run();
        if (args.Length > 0 && args[0] == "--smoke-test") return Checks.Smoke(app, args[1]);
        using var mutex = new Mutex(true, @"Local\Pippy.Desktop", out bool created);
        if (!created) { MessageBox.Show("Pippy is already running. Open it from the system tray.", "Pippy"); return 0; }
        using var controller = new Controller(app);
        return app.Run();
    }
}
sealed class Controller : IDisposable {
    readonly Application app;
    readonly SettingsStore store;
    readonly Settings settings;
    readonly Schedule schedule;
    readonly AudioPlayer audio = new();
    readonly Forms.NotifyIcon tray;
    readonly DispatcherTimer clock = new() { Interval = TimeSpan.FromSeconds(5) };
    readonly Queue<Kind> pending = new();
    readonly Window home;
    ReminderWindow? popup;
    bool quitting;
    public Controller(Application app) {
        this.app = app;
        store = new SettingsStore(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Pippy", "settings.json"));
        settings = store.Load(); schedule = new Schedule(settings, DateTimeOffset.Now);
        home = new HomeWindow(settings, Save, kind => { schedule.Reset(kind,DateTimeOffset.Now); Save(); }, ShowReminder, PreviewSound);
        home.Closing += (_, e) => { if (!quitting) { e.Cancel = true; home.Hide(); } };
        using var iconStream = Visuals.Resource("AppIcon.ico");
        tray = new Forms.NotifyIcon { Icon = new System.Drawing.Icon(iconStream), Text = "Pippy — little check-ins", Visible = true };
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Open Pippy", null, (_,_) => app.Dispatcher.Invoke(OpenHome));
        foreach (var kind in Enum.GetValues<Kind>()) menu.Items.Add("Preview "+kind, null, (_,_) => app.Dispatcher.Invoke(() => ShowReminder(kind)));
        menu.Items.Add(new Forms.ToolStripSeparator());
        var feedback = new Forms.ToolStripMenuItem("Send feedback");
        feedback.DropDownItems.Add("Email the developer…", null, (_,_) => app.Dispatcher.Invoke(Visuals.EmailFeedback));
        feedback.DropDownItems.Add("Message on Telegram…", null, (_,_) => app.Dispatcher.Invoke(Visuals.TelegramFeedback));
        menu.Items.Add(feedback);
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add("Quit Pippy", null, (_,_) => app.Dispatcher.Invoke(() => { quitting = true; app.Shutdown(); }));
        tray.ContextMenuStrip = menu; tray.DoubleClick += (_,_) => app.Dispatcher.Invoke(OpenHome);
        clock.Tick += (_,_) => { var kind = schedule.Due(DateTimeOffset.Now); if (kind.HasValue) { Save(); ShowReminder(kind.Value); } };
        clock.Start(); OpenHome();
    }
    void OpenHome() { home.Show(); home.Activate(); }
    // Explicit previews play even when reminder sounds are off; Blink demonstrates all three break cues.
    void PreviewSound(Kind kind) {
        var set = settings.SoundSets[kind];
        audio.Play(kind == Kind.Blink ? Sounds.Preview(set) : Sounds.Nudge(set));
    }
    void Save() {
        try { store.Save(settings); }
        catch (Exception e) when (e is IOException || e is UnauthorizedAccessException) {
            MessageBox.Show("Pippy couldn't save your settings. Check that your user folder is writable.", "Pippy");
        }
    }
    void ShowReminder(Kind kind) {
        if (popup != null) { if (!pending.Contains(kind)) pending.Enqueue(kind); return; }
        popup = new ReminderWindow(kind, settings, cue => { if(settings.Sound) audio.Play(Sounds.File(settings.SoundSets[kind], cue)); }, () => schedule.Snooze(kind, DateTimeOffset.Now));
        popup.Closed += (_,_) => {
            popup = null;
            if (!quitting && pending.Count > 0) app.Dispatcher.BeginInvoke(new Action(() => ShowReminder(pending.Dequeue())));
        };
        popup.Show();
        if (kind != Kind.Blink && settings.Sound) audio.Play(Sounds.Nudge(settings.SoundSets[kind]));
    }
    public void Dispose() { quitting=true; clock.Stop(); popup?.Close(); tray.Visible=false; tray.Icon?.Dispose(); tray.Dispose(); audio.Dispose(); }
}
