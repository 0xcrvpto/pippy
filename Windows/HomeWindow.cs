using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace Pippy;
sealed class HomeWindow : Window {
    readonly Settings settings;
    readonly Action save;
    readonly TextBlock status = new() { FontSize = 11, FontWeight = FontWeights.Bold, Foreground = Visuals.Ink, VerticalAlignment = VerticalAlignment.Center };
    readonly Ellipse statusDot = new() { Width = 7, Height = 7, Margin = new Thickness(0,0,7,0), VerticalAlignment = VerticalAlignment.Center };
    readonly Dictionary<Kind, UIElement[]> dimmable = new();
    public Dictionary<Kind, CheckBox> Toggles { get; } = new();
    public Dictionary<Kind, PickerChip> Intervals { get; } = new();
    public Dictionary<Kind, ComboBox> SoundPickers { get; } = new();
    public PickerChip Start { get; }
    public PickerChip End { get; }
    public TextBlock HoursNote { get; }
    public Border UpdateBanner { get; }
    readonly TextBlock updateTitle = new() { FontSize = 14, FontWeight = FontWeights.SemiBold, Foreground = Visuals.Ink };
    Release? release;

    public HomeWindow(Settings settings, Action save, Action<Kind> reset, Action<Kind> preview, Action<Kind> previewSound) {
        this.settings = settings; this.save = save;
        Title = "Pippy"; Width = 640; Height = 880; MinWidth = 580; MinHeight = 600; Background = Visuals.Cream;
        Icon = Visuals.Bitmap("AppIcon.png"); WindowStartupLocation = WindowStartupLocation.CenterScreen;
        var stack = new StackPanel { Margin = new Thickness(28,24,28,20) };
        Content = new ScrollViewer { Content = stack, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };

        stack.Children.Add(Header());
        UpdateBanner = BuildUpdateBanner();
        stack.Children.Add(UpdateBanner);
        stack.Children.Add(Section("REMINDERS"));
        foreach (var kind in Enum.GetValues<Kind>()) stack.Children.Add(ReminderRow(kind, reset, preview));

        // Workout hours: start and end can never meet, so the window always stays valid.
        var hours = new StackPanel();
        var hoursTop = new DockPanel { Margin = new Thickness(0,0,0,10) };
        var hint = Visuals.Quiet("Scroll, drag, or click a time", 11); DockPanel.SetDock(hint, Dock.Right); hoursTop.Children.Add(hint);
        hoursTop.Children.Add(Visuals.Text("Rally's workout hours", 15, true));
        hours.Children.Add(hoursTop);
        Start = new PickerChip(Picker.QuarterHours, settings.WorkoutStart, true, Visuals.Coral, Visuals.Time, "Workout start time");
        End = new PickerChip(Picker.QuarterHours, settings.WorkoutEnd, true, Visuals.Coral, Visuals.Time, "Workout end time");
        Start.Skip = minute => minute == End.Value; End.Skip = minute => minute == Start.Value;
        var times = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0,0,0,10) };
        times.Children.Add(Label("From")); times.Children.Add(Start); times.Children.Add(Label("to", 12)); times.Children.Add(End);
        hours.Children.Add(times);
        HoursNote = Visuals.Quiet("", 11); HoursNote.Margin = new Thickness(0);
        hours.Children.Add(HoursNote);
        void SaveHours() {
            settings.WorkoutStart = Start.Value; settings.WorkoutEnd = End.Value; save(); UpdateHoursNote();
        }
        Start.Changed += _ => SaveHours(); End.Changed += _ => SaveHours();
        UpdateHoursNote();
        stack.Children.Add(Visuals.Card(hours));

        stack.Children.Add(SoundCard(previewSound));
        stack.Children.Add(FeedbackBanner());
        stack.Children.Add(Visuals.Quiet($"Changes save automatically. Closing this window keeps Pippy in the system tray. Eye and stretch reminders run from {Visuals.Time(660)} to {Visuals.Time(1380)}. · Pippy {Feedback.Version}", 11));
        RefreshStatus();
    }

    UIElement Header() {
        var grid = new Grid { Margin = new Thickness(0,0,0,18) };
        grid.ColumnDefinitions.Add(new ColumnDefinition()); grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        // A grid (not a horizontal stack) so the title wraps instead of running under the pills.
        var left = new Grid { Margin = new Thickness(0,0,12,0) };
        left.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto }); left.ColumnDefinitions.Add(new ColumnDefinition());
        left.Children.Add(new Image { Source = Visuals.Bitmap("AppIcon.png"), Width = 44, Height = 44, Margin = new Thickness(0,0,12,0), VerticalAlignment = VerticalAlignment.Top });
        var titles = new StackPanel();
        var title = Visuals.Text("A little care, on your terms.", 22, true); title.FontWeight = FontWeights.Bold; title.Margin = new Thickness(0,0,0,2);
        titles.Children.Add(title); titles.Children.Add(Visuals.Quiet("Three tiny desk buddies. A gentler day.", 13));
        Grid.SetColumn(titles, 1); left.Children.Add(titles); grid.Children.Add(left);

        var right = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(0,6,0,0) };
        Button? feedback = null;
        feedback = Visuals.Pill("Feedback", (_,_) => { var menu = Visuals.FeedbackMenu(); menu.PlacementTarget = feedback; menu.Placement = System.Windows.Controls.Primitives.PlacementMode.Bottom; menu.IsOpen = true; },
            Brushes.White, size: 11);
        feedback.ToolTip = "Report a problem or share an idea";
        right.Children.Add(feedback);
        var pill = new StackPanel { Orientation = Orientation.Horizontal }; pill.Children.Add(statusDot); pill.Children.Add(status);
        right.Children.Add(new Border { Background = Brushes.White, CornerRadius = new CornerRadius(14), Padding = new Thickness(12,6,12,6), Child = pill, VerticalAlignment = VerticalAlignment.Center });
        Grid.SetColumn(right, 1); grid.Children.Add(right);
        return grid;
    }

    /// Shows "Pippy 0.7 is ready" with What's new and Download buttons above the reminders.
    public void ShowUpdate(Release update) {
        release = update;
        updateTitle.Text = $"Pippy {update.Version} is ready";
        UpdateBanner.Visibility = Visibility.Visible;
    }

    Border BuildUpdateBanner() {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto }); grid.ColumnDefinitions.Add(new ColumnDefinition()); grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var icon = Visuals.Glyph("\uE896", 18, Visuals.Tint(Visuals.Green, 1)); icon.Margin = new Thickness(0,0,14,0); grid.Children.Add(icon);
        var text = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        text.Children.Add(updateTitle);
        var detail = Visuals.Quiet("Download and run the installer. Your settings carry over.", 12); detail.Margin = new Thickness(0); text.Children.Add(detail);
        Grid.SetColumn(text, 1); grid.Children.Add(text);
        var buttons = new StackPanel { Orientation = Orientation.Horizontal };
        buttons.Children.Add(Visuals.Pill("What's new", (_,_) => { if (release != null) Visuals.Open(release.Page); }, Brushes.White, size: 12));
        buttons.Children.Add(Visuals.Pill("Download", (_,_) => { if (release != null) Visuals.Open(release.Download); }, Visuals.Ink, Brushes.White, 12));
        var later = Visuals.Pill("\u2715", (_,_) => UpdateBanner.Visibility = Visibility.Collapsed, Brushes.Transparent, Visuals.Muted, 11);
        later.Margin = new Thickness(0); later.ToolTip = "Hide until next launch";
        System.Windows.Automation.AutomationProperties.SetName(later, "Hide update banner");
        buttons.Children.Add(later);
        Grid.SetColumn(buttons, 2); grid.Children.Add(buttons);
        var card = Visuals.Card(grid);
        card.Background = Visuals.Tint(Visuals.Green, .1); card.BorderBrush = Visuals.Tint(Visuals.Green, .4); card.Padding = new Thickness(18,12,14,12);
        card.Visibility = Visibility.Collapsed;
        return card;
    }

    UIElement ReminderRow(Kind kind, Action<Kind> reset, Action<Kind> preview) {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition());
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var tile = new Border { Width = 66, Height = 66, CornerRadius = new CornerRadius(16), Background = Visuals.Tint(Visuals.KindColor(kind), .22),
            Margin = new Thickness(0,0,16,0), VerticalAlignment = VerticalAlignment.Center, Child = Visuals.Mascot(kind, 60) };
        ((Image)tile.Child).Margin = new Thickness(0);
        grid.Children.Add(tile);

        var detail = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        var nameRow = new StackPanel { Orientation = Orientation.Horizontal };
        var name = Visuals.Text(kind.ToString(), 17, true); name.FontWeight = FontWeights.Bold; name.Margin = new Thickness(0,0,8,0);
        var category = Visuals.Quiet(Visuals.Category(kind), 10); category.FontWeight = FontWeights.Bold; category.VerticalAlignment = VerticalAlignment.Center; category.Margin = new Thickness(0,2,0,0);
        nameRow.Children.Add(name); nameRow.Children.Add(category);
        var tagline = Visuals.Quiet(Visuals.Tagline(kind), 12); tagline.Margin = new Thickness(0,1,0,8);
        var controls = new StackPanel { Orientation = Orientation.Horizontal };
        var chip = new PickerChip(Settings.Choices(kind).ToList(), settings.Minutes[kind], false, Visuals.KindColor(kind), m => $"{m} min", kind + " interval");
        chip.Changed += minutes => { settings.Minutes[kind] = minutes; reset(kind); };
        Intervals[kind] = chip;
        controls.Children.Add(Label("Every", 0)); controls.Children.Add(chip);
        var previewButton = Visuals.Pill("▶  Preview", (_,_) => preview(kind), Visuals.Tint(Visuals.KindColor(kind), .16), size: 11);
        previewButton.Margin = new Thickness(10,0,0,0);
        controls.Children.Add(previewButton);
        detail.Children.Add(nameRow); detail.Children.Add(tagline); detail.Children.Add(controls);
        Grid.SetColumn(detail, 1); grid.Children.Add(detail);

        var toggle = Visuals.Switch(settings.Enabled[kind], kind + " reminders");
        toggle.ToolTip = $"Turn {kind} reminders on or off";
        toggle.Click += (_,_) => { settings.Enabled[kind] = toggle.IsChecked == true; reset(kind); ApplyEnabled(kind); RefreshStatus(); };
        Toggles[kind] = toggle;
        Grid.SetColumn(toggle, 2); grid.Children.Add(toggle);
        dimmable[kind] = new UIElement[] { tile, nameRow, tagline, controls };
        ApplyEnabled(kind);
        var card = Visuals.Card(grid); card.Padding = new Thickness(14,14,18,14); card.Margin = new Thickness(0,0,0,10);
        return card;
    }

    UIElement SoundCard(Action<Kind> previewSound) {
        var panel = new StackPanel();
        var top = new DockPanel();
        var master = Visuals.Switch(settings.Sound, "Reminder sounds");
        master.Click += (_,_) => { settings.Sound = master.IsChecked == true; save(); };
        DockPanel.SetDock(master, Dock.Right); top.Children.Add(master);
        var titles = new StackPanel();
        titles.Children.Add(Visuals.Text("Reminder sounds", 15, true));
        var detail = Visuals.Quiet("Give each buddy its own sound. Blink chimes at 20 s, 10 s, and when done.", 12); detail.Margin = new Thickness(0);
        titles.Children.Add(detail); top.Children.Add(titles);
        panel.Children.Add(top);
        foreach (var kind in Enum.GetValues<Kind>()) {
            var row = new Grid { Margin = new Thickness(0,10,0,0) };
            foreach (var width in new[] { GridLength.Auto, new GridLength(70), new GridLength(1, GridUnitType.Star), GridLength.Auto, GridLength.Auto })
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = width });
            var mascot = Visuals.Mascot(kind, 30); mascot.Margin = new Thickness(0,0,10,0); row.Children.Add(mascot);
            var name = Visuals.Text(kind.ToString(), 13, true); name.Margin = new Thickness(0); name.VerticalAlignment = VerticalAlignment.Center;
            Grid.SetColumn(name, 1); row.Children.Add(name);
            var use = Visuals.Quiet(kind == Kind.Blink ? "Break chimes" : "Nudge sound", 12); use.Margin = new Thickness(0); use.VerticalAlignment = VerticalAlignment.Center;
            Grid.SetColumn(use, 2); row.Children.Add(use);
            var picker = new ComboBox { Width = 150, Margin = new Thickness(0,0,10,0), VerticalAlignment = VerticalAlignment.Center, FontSize = 12,
                ItemsSource = Enum.GetValues<SoundSet>().Select(Sounds.Title).ToList(), SelectedIndex = (int)settings.SoundSets[kind] };
            System.Windows.Automation.AutomationProperties.SetName(picker, kind + " sound");
            picker.SelectionChanged += (_,_) => {
                if (picker.SelectedIndex < 0) return;
                settings.SoundSets[kind] = (SoundSet)picker.SelectedIndex; save(); previewSound(kind);
            };
            SoundPickers[kind] = picker;
            Grid.SetColumn(picker, 3); row.Children.Add(picker);
            var play = Visuals.Pill("▶  Preview", (_,_) => previewSound(kind), Visuals.Tint(Visuals.KindColor(kind), .16), size: 11); play.Margin = new Thickness(0);
            System.Windows.Automation.AutomationProperties.SetName(play, $"Preview {kind}'s sound");
            Grid.SetColumn(play, 4); row.Children.Add(play);
            panel.Children.Add(row);
        }
        panel.Children.Add(new Border { Height = 1, Background = Visuals.Line, Margin = new Thickness(0,14,0,12) });
        var motion = new DockPanel();
        var reduced = Visuals.Switch(settings.ReduceMotion, "Reduce mascot motion");
        reduced.Click += (_,_) => { settings.ReduceMotion = reduced.IsChecked == true; save(); };
        DockPanel.SetDock(reduced, Dock.Right); motion.Children.Add(reduced);
        var motionLabel = Visuals.Text("Reduce mascot motion", 13, true); motionLabel.Margin = new Thickness(0); motionLabel.VerticalAlignment = VerticalAlignment.Center;
        motion.Children.Add(motionLabel);
        panel.Children.Add(motion);
        panel.Children.Add(Visuals.Quiet("Sound previews play even when reminder sounds are off.", 11));
        return Visuals.Card(panel);
    }

    UIElement FeedbackBanner() {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto }); grid.ColumnDefinitions.Add(new ColumnDefinition()); grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var icon = Visuals.Glyph("", 18, Visuals.Tint(Visuals.Lilac, 1)); icon.Margin = new Thickness(0,0,14,0); grid.Children.Add(icon);
        var text = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        var title = Visuals.Text("Something off, or have an idea?", 14, true); title.Margin = new Thickness(0);
        text.Children.Add(title); var detail = Visuals.Quiet("Tell me directly — every message gets read.", 12); detail.Margin = new Thickness(0); text.Children.Add(detail);
        Grid.SetColumn(text, 1); grid.Children.Add(text);
        var buttons = new StackPanel { Orientation = Orientation.Horizontal };
        var email = Visuals.Pill("Email", (_,_) => Visuals.EmailFeedback(), Visuals.Tint(Visuals.Lilac, .2), size: 12); email.ToolTip = Feedback.Email;
        var telegram = Visuals.Pill("Telegram", (_,_) => Visuals.TelegramFeedback(), Visuals.Tint(Visuals.Mint, .24), size: 12); telegram.ToolTip = Feedback.Telegram; telegram.Margin = new Thickness(0);
        buttons.Children.Add(email); buttons.Children.Add(telegram);
        Grid.SetColumn(buttons, 2); grid.Children.Add(buttons);
        var card = Visuals.Card(grid); card.Background = new SolidColorBrush(Color.FromArgb(185,255,255,255)); card.Padding = new Thickness(18,12,14,12);
        return card;
    }

    static TextBlock Section(string text) { var block = Visuals.Quiet(text, 11); block.FontWeight = FontWeights.Bold; block.Margin = new Thickness(2,0,0,8); return block; }
    static TextBlock Label(string text, double left = 0) {
        var block = Visuals.Quiet(text, 13); block.Margin = new Thickness(left,0,10,0); block.VerticalAlignment = VerticalAlignment.Center; return block;
    }

    void UpdateHoursNote() => HoursNote.Text = settings.WorkoutStart > settings.WorkoutEnd
        ? "Every day · ends the following morning · saves automatically"
        : "Every day · reminders repeat at your chosen interval · saves automatically";

    void ApplyEnabled(Kind kind) { foreach (var element in dimmable[kind]) element.Opacity = settings.Enabled[kind] ? 1 : .45; }

    void RefreshStatus() {
        int count = settings.Enabled.Values.Count(on => on);
        statusDot.Fill = count > 0 ? Visuals.Tint(Visuals.Green, 1) : Visuals.Muted;
        status.Text = count == 0 ? "ALL PAUSED" : count == 1 ? "1 REMINDER ON" : $"{count} REMINDERS ON";
    }
}
