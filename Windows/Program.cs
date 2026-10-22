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
        home = new HomeWindow(settings, Save, kind => { schedule.Reset(kind,DateTimeOffset.Now); Save(); }, ShowReminder, () => audio.Play("BlinkPreview"));
        home.Closing += (_, e) => { if (!quitting) { e.Cancel = true; home.Hide(); } };
        using var iconStream = Visuals.Resource("AppIcon.ico");
        tray = new Forms.NotifyIcon { Icon = new System.Drawing.Icon(iconStream), Text = "Pippy — little check-ins", Visible = true };
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Open Pippy", null, (_,_) => app.Dispatcher.Invoke(OpenHome));
        foreach (var kind in Enum.GetValues<Kind>()) menu.Items.Add("Preview "+kind, null, (_,_) => app.Dispatcher.Invoke(() => ShowReminder(kind)));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add("Quit Pippy", null, (_,_) => app.Dispatcher.Invoke(() => { quitting = true; app.Shutdown(); }));
        tray.ContextMenuStrip = menu; tray.DoubleClick += (_,_) => app.Dispatcher.Invoke(OpenHome);
        clock.Tick += (_,_) => { var kind = schedule.Due(DateTimeOffset.Now); if (kind.HasValue) { Save(); ShowReminder(kind.Value); } };
        clock.Start(); OpenHome();
    }
    void OpenHome() { home.Show(); home.Activate(); }
    void Save() {
        try { store.Save(settings); }
        catch (Exception e) when (e is IOException || e is UnauthorizedAccessException) {
            MessageBox.Show("Pippy couldn't save your settings. Check that your user folder is writable.", "Pippy");
        }
    }
    void ShowReminder(Kind kind) {
        if (popup != null) { if (!pending.Contains(kind)) pending.Enqueue(kind); return; }
        popup = new ReminderWindow(kind, settings, cue => { if(settings.Sound) audio.Play("Blink"+cue); }, () => schedule.Snooze(kind, DateTimeOffset.Now));
        popup.Closed += (_,_) => {
            popup = null;
            if (!quitting && pending.Count > 0) app.Dispatcher.BeginInvoke(new Action(() => ShowReminder(pending.Dequeue())));
        };
        popup.Show();
    }
    public void Dispose() { quitting=true; clock.Stop(); popup?.Close(); tray.Visible=false; tray.Icon?.Dispose(); tray.Dispose(); audio.Dispose(); }
}
sealed class HomeWindow : Window {
    public HomeWindow(Settings settings, Action save, Action<Kind> reset, Action<Kind> preview, Action previewSound) {
        Title = "Pippy"; Width=600; Height=810; MinWidth=540; MinHeight=600; Background=Visuals.Cream;
        Icon=Visuals.Bitmap("AppIcon.png"); WindowStartupLocation=WindowStartupLocation.CenterScreen;
        var stack = new StackPanel { Margin=new Thickness(28) };
        Content=new ScrollViewer { Content=stack, VerticalScrollBarVisibility=ScrollBarVisibility.Auto };
        stack.Children.Add(Visuals.Text("A little care, on your terms.",26,true));
        stack.Children.Add(Visuals.Text("Three tiny desk buddies. A gentler day.",14));
        foreach(var kind in Enum.GetValues<Kind>()) {
            var row = new DockPanel(); var image=Visuals.Mascot(kind,74); DockPanel.SetDock(image,Dock.Left); row.Children.Add(image);
            var detail=new StackPanel(); row.Children.Add(detail);
            string purpose=kind switch { Kind.Rally=>"Workout",Kind.Blink=>"Eye break",_=>"Stretch & move" };
            var enabled=new CheckBox { Content=kind+"  ·  "+purpose, FontSize=16, FontWeight=FontWeights.SemiBold, Foreground=Visuals.Ink, IsChecked=settings.Enabled[kind], Margin=new Thickness(0,0,0,9) };
            enabled.Click+=(_,_)=>{settings.Enabled[kind]=enabled.IsChecked==true;reset(kind);}; detail.Children.Add(enabled);
            var controls=new StackPanel { Orientation=Orientation.Horizontal };
            controls.Children.Add(Visuals.Text("Every ",12));
            var intervals=new ComboBox { Width=62, ItemsSource=Settings.Choices(kind), SelectedItem=settings.Minutes[kind], Margin=new Thickness(0,0,7,0) };
            intervals.SelectionChanged+=(_,_)=>{ if(intervals.SelectedItem is int n){settings.Minutes[kind]=n;reset(kind);} };
            controls.Children.Add(intervals); controls.Children.Add(Visuals.Text("min  ",12));
            controls.Children.Add(Visuals.Button("Preview",(_,_)=>preview(kind))); detail.Children.Add(controls);
            stack.Children.Add(Visuals.Card(row));
        }
        var hours=new StackPanel(); hours.Children.Add(Visuals.Text("Rally's workout hours",16,true));
        var times=new StackPanel { Orientation=Orientation.Horizontal };
        TextBox Field(int minutes,string name) { var box=new TextBox { Text=$"{minutes/60:00}:{minutes%60:00}", Width=76, FontSize=16, Padding=new Thickness(6), Margin=new Thickness(8,0,14,8) }; System.Windows.Automation.AutomationProperties.SetName(box,name); return box; }
        var start=Field(settings.WorkoutStart,"Workout start, 24-hour time"); var end=Field(settings.WorkoutEnd,"Workout end, 24-hour time");
        times.Children.Add(Visuals.Text("From",13));times.Children.Add(start);times.Children.Add(Visuals.Text("to",13));times.Children.Add(end);hours.Children.Add(times);
        var note=Visuals.Text("24-hour time · every day · overnight windows supported",11);hours.Children.Add(note);
        void SaveHours() {
            if(!TimeOnly.TryParseExact(start.Text,new[]{"H:mm","HH:mm"},CultureInfo.InvariantCulture,DateTimeStyles.None,out var a) || !TimeOnly.TryParseExact(end.Text,new[]{"H:mm","HH:mm"},CultureInfo.InvariantCulture,DateTimeStyles.None,out var b) || a==b) {
                note.Text="Enter two different times, such as 09:00 and 18:00. Previous hours are kept."; return;
            }
            settings.WorkoutStart=a.Hour*60+a.Minute;settings.WorkoutEnd=b.Hour*60+b.Minute;save();
            note.Text=settings.WorkoutStart>settings.WorkoutEnd?"Saved · ends the following morning":"Saved · repeats at your selected interval";
        }
        start.LostKeyboardFocus+=(_,_)=>SaveHours();end.LostKeyboardFocus+=(_,_)=>SaveHours();
        stack.Children.Add(Visuals.Card(hours));
        var soundPanel=new StackPanel();
        var sound=new CheckBox {Content="Gentle reminder sounds",IsChecked=settings.Sound,FontSize=14,Margin=new Thickness(0,0,0,10)};
        sound.Click+=(_,_)=>{settings.Sound=sound.IsChecked==true;save();};soundPanel.Children.Add(sound);
        soundPanel.Children.Add(Visuals.Text("Blink chimes at 20 seconds, 10 seconds, and completion.",12));
        soundPanel.Children.Add(Visuals.Button("Preview Blink's sounds",(_,_)=>previewSound()));
        soundPanel.Children.Add(Visuals.Text("Explicit previews play even when reminders are muted.",10));
        var reduced=new CheckBox {Content="Reduce mascot motion",IsChecked=settings.ReduceMotion,Margin=new Thickness(0,8,0,0)};
        reduced.Click+=(_,_)=>{settings.ReduceMotion=reduced.IsChecked==true;save();};soundPanel.Children.Add(reduced);
        stack.Children.Add(Visuals.Card(soundPanel));
        stack.Children.Add(Visuals.Text("Changes save automatically. Closing this window keeps Pippy in the system tray. Eye and stretch reminders run from 11 a.m. to 11 p.m.",11));
    }
}
