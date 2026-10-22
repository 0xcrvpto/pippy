using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Media;
using System.Reflection;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace Pippy;
static class Visuals {
    public static readonly Brush Ink = new SolidColorBrush(Color.FromRgb(37,52,59));
    public static readonly Brush Muted = new SolidColorBrush(Color.FromRgb(105,120,125));
    public static readonly Brush Cream = new SolidColorBrush(Color.FromRgb(247,245,240));
    public static readonly Brush Line = new SolidColorBrush(Color.FromRgb(231,233,229));
    public static readonly Color Coral = Color.FromRgb(241,154,120), Lilac = Color.FromRgb(168,167,236), Mint = Color.FromRgb(131,205,177), Green = Color.FromRgb(95,175,139);
    public static Color KindColor(Kind kind) => kind switch { Kind.Rally => Coral, Kind.Blink => Lilac, _ => Mint };
    public static Brush Tint(Color color, double alpha) => new SolidColorBrush(Color.FromArgb((byte)Math.Round(alpha*255), color.R, color.G, color.B));
    public static string Category(Kind kind) => kind switch { Kind.Rally => "WORKOUT", Kind.Blink => "EYE BREAK", _ => "STRETCH & MOVE" };
    public static string Tagline(Kind kind) => kind switch { Kind.Rally => "A little gym-time nudge", Kind.Blink => "20-20-20 screen reset", _ => "Uncurl and move a little" };
    public static string Time(int minute) => new DateTime(2001,1,1).AddMinutes(minute).ToString("t", CultureInfo.CurrentCulture);

    const string Xmlns = "xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'";
    // A rounded pill whose hover/press overlay uses the text colour, so it works on light and dark fills.
    static readonly Style PillStyle = (Style)XamlReader.Parse($@"<Style {Xmlns} TargetType='Button'>
      <Setter Property='Cursor' Value='Hand'/><Setter Property='FontWeight' Value='SemiBold'/><Setter Property='FocusVisualStyle' Value='{{x:Null}}'/>
      <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='Button'>
        <Grid x:Name='Root'>
          <Border x:Name='Body' Background='{{TemplateBinding Background}}' CornerRadius='14' BorderBrush='#25343B' BorderThickness='0'/>
          <Border x:Name='Hover' Background='{{TemplateBinding Foreground}}' CornerRadius='14' Opacity='0'/>
          <ContentPresenter Margin='{{TemplateBinding Padding}}' HorizontalAlignment='Center' VerticalAlignment='Center'/>
        </Grid>
        <ControlTemplate.Triggers>
          <Trigger Property='IsMouseOver' Value='True'><Setter TargetName='Hover' Property='Opacity' Value='0.09'/></Trigger>
          <Trigger Property='IsPressed' Value='True'><Setter TargetName='Hover' Property='Opacity' Value='0.17'/></Trigger>
          <Trigger Property='IsKeyboardFocused' Value='True'><Setter TargetName='Body' Property='BorderThickness' Value='1.5'/></Trigger>
          <Trigger Property='IsEnabled' Value='False'><Setter TargetName='Root' Property='Opacity' Value='0.55'/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter></Style>");
    // An on/off switch drawn from a CheckBox, in Pippy green.
    static readonly Style SwitchStyle = (Style)XamlReader.Parse($@"<Style {Xmlns} TargetType='CheckBox'>
      <Setter Property='Cursor' Value='Hand'/><Setter Property='FocusVisualStyle' Value='{{x:Null}}'/>
      <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='CheckBox'>
        <Border x:Name='Track' Width='40' Height='22' CornerRadius='11' Background='#D7DBD6' BorderBrush='#25343B' BorderThickness='0'>
          <Border x:Name='Knob' Width='18' Height='18' CornerRadius='9' Background='White' HorizontalAlignment='Left' Margin='2,0,0,0'>
            <Border.Effect><DropShadowEffect BlurRadius='3' ShadowDepth='1' Opacity='0.25'/></Border.Effect>
          </Border>
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property='IsChecked' Value='True'>
            <Setter TargetName='Track' Property='Background' Value='#5FAF8B'/>
            <Setter TargetName='Knob' Property='HorizontalAlignment' Value='Right'/><Setter TargetName='Knob' Property='Margin' Value='0,0,2,0'/>
          </Trigger>
          <Trigger Property='IsKeyboardFocused' Value='True'><Setter TargetName='Track' Property='BorderThickness' Value='1.5'/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter></Style>");

    public static CheckBox Switch(bool on, string name) {
        var toggle = new CheckBox { IsChecked = on, Style = SwitchStyle, VerticalAlignment = VerticalAlignment.Center };
        AutomationProperties.SetName(toggle, name); return toggle;
    }
    public static Button Pill(string text, RoutedEventHandler click, Brush fill, Brush? foreground = null, double size = 12) {
        var button = new Button { Content = text, Style = PillStyle, Background = fill, Foreground = foreground ?? Ink, FontSize = size,
            Padding = new Thickness(14,6,14,6), Margin = new Thickness(0,0,8,0), VerticalAlignment = VerticalAlignment.Center };
        button.Click += click; return button;
    }
    public static TextBlock Quiet(string text, double size = 12) { var block = Text(text, size); block.Foreground = Muted; return block; }
    public static TextBlock Glyph(string glyph, double size, Brush brush) => new() { Text = glyph, FontFamily = new FontFamily("Segoe MDL2 Assets"), FontSize = size, Foreground = brush, VerticalAlignment = VerticalAlignment.Center };

    /// Opens a link with the user's default handler; returns false if nothing handled it.
    public static bool Open(string uri) {
        try { Process.Start(new ProcessStartInfo(uri) { UseShellExecute = true }); return true; }
        catch (Exception e) when (e is System.ComponentModel.Win32Exception || e is InvalidOperationException) { return false; }
    }
    public static void EmailFeedback() {
        if (Open(Feedback.MailtoUri())) return;
        // No mail app is set up: hand over the address instead.
        try { Clipboard.SetText(Feedback.Email); } catch (System.Runtime.InteropServices.COMException) { }
        if (MessageBox.Show($"No mail app opened, so {Feedback.Email} is on your clipboard. Paste it into any email app.\n\nOpen Telegram instead?", "Pippy feedback", MessageBoxButton.YesNo) == MessageBoxResult.Yes) TelegramFeedback();
    }
    public static void TelegramFeedback() {
        if (!Open(Feedback.Telegram)) MessageBox.Show("Pippy couldn't open your browser. Message " + Feedback.Telegram + " on Telegram.", "Pippy feedback");
    }
    public static ContextMenu FeedbackMenu() {
        var menu = new ContextMenu();
        var mail = new MenuItem { Header = "Email the developer…" }; mail.Click += (_,_) => EmailFeedback();
        var chat = new MenuItem { Header = "Message on Telegram…" }; chat.Click += (_,_) => TelegramFeedback();
        menu.Items.Add(mail); menu.Items.Add(chat); return menu;
    }
    public static Stream Resource(string name) {
        var assembly = Assembly.GetExecutingAssembly();
        var match = assembly.GetManifestResourceNames().Single(n => n.EndsWith("."+name, StringComparison.Ordinal));
        return assembly.GetManifestResourceStream(match)!;
    }
    public static BitmapImage Bitmap(string name) {
        using var stream = Resource(name);
        var image = new BitmapImage(); image.BeginInit(); image.CacheOption = BitmapCacheOption.OnLoad; image.StreamSource = stream; image.EndInit(); image.Freeze(); return image;
    }
    public static Image Mascot(Kind kind, int size = 80) => new() { Source = Bitmap(kind+".png"), Width = size, Height = size, Margin = new Thickness(0,0,16,0) };
    public static TextBlock Text(string text, double size = 13, bool bold = false) => new() {
        Text = text, FontSize = size, FontWeight = bold ? FontWeights.SemiBold : FontWeights.Normal,
        Foreground = Ink, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0,0,0,7)
    };
    public static Button Button(string text, RoutedEventHandler click, bool primary = false) {
        var button = Pill(text, click, primary ? Ink : Brushes.White, primary ? Brushes.White : Ink, 13);
        button.Padding = new Thickness(16,8,16,8); return button;
    }
    public static Border Card(UIElement content) => new() { Child = content, Background = Brushes.White, CornerRadius = new CornerRadius(18), Padding = new Thickness(18),
        Margin = new Thickness(0,0,0,12), BorderBrush = Line, BorderThickness = new Thickness(1) };
    public static void Render(Window window, string path) {
        window.UpdateLayout();
        var bitmap = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96,96,PixelFormats.Pbgra32);
        bitmap.Render(window); var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(bitmap));
        using var file = File.Create(path); png.Save(file);
    }
}
sealed class AudioPlayer : IDisposable {
    SoundPlayer? player;
    Stream? stream;
    public void Play(string name) {
        Dispose(); stream = Visuals.Resource(name+".wav"); player = new SoundPlayer(stream); player.Load(); player.Play();
    }
    public void Dispose() { player?.Stop(); player?.Dispose(); stream?.Dispose(); player=null; stream=null; }
}

/// A compact value chip: scroll, drag vertically, use the arrow keys, or click for a menu.
sealed class PickerChip : Border {
    readonly IReadOnlyList<int> values;
    readonly Func<int,string> format;
    readonly bool wraps;
    readonly Brush fill, hover;
    readonly TextBlock text = new() { FontSize = 13, FontWeight = FontWeights.SemiBold, Foreground = Visuals.Ink, VerticalAlignment = VerticalAlignment.Center };
    int index;
    double wheel, lastY;
    bool pressed, dragged;
    /// Values the chip steps over, such as a workout end that would equal its start.
    public Func<int,bool> Skip { get; set; } = _ => false;
    public event Action<int>? Changed;
    public int Value => values[index];

    public PickerChip(IReadOnlyList<int> values, int selected, bool wraps, Color tint, Func<int,string> format, string name) {
        this.values = values; this.format = format; this.wraps = wraps;
        fill = Visuals.Tint(tint, .18); hover = Visuals.Tint(tint, .32);
        index = values.ToList().IndexOf(selected) is var found && found >= 0 ? found : Picker.Nearest(values, selected);
        Background = fill; CornerRadius = new CornerRadius(14); Height = 28; Padding = new Thickness(12,0,10,0);
        Cursor = Cursors.Hand; Focusable = true; KeyboardNavigation.SetIsTabStop(this, true); FocusVisualStyle = null;
        BorderBrush = Visuals.Ink; VerticalAlignment = VerticalAlignment.Center; ToolTip = "Scroll, drag, or click to change";
        AutomationProperties.SetName(this, name);
        var dip = 1.0;
        text.MinWidth = values.Max(v => new FormattedText(format(v), CultureInfo.CurrentCulture, FlowDirection.LeftToRight,
            new Typeface(text.FontFamily, FontStyles.Normal, FontWeights.SemiBold, FontStretches.Normal), 13, Brushes.Black, dip).Width);
        var chevrons = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(8,0,0,0) };
        chevrons.Children.Add(Visuals.Glyph("\uE70E", 7, Visuals.Muted)); chevrons.Children.Add(Visuals.Glyph("\uE70D", 7, Visuals.Muted));
        var row = new StackPanel { Orientation = Orientation.Horizontal }; row.Children.Add(text); row.Children.Add(chevrons);
        Child = row; Refresh();
        MouseEnter += (_,_) => Background = hover; MouseLeave += (_,_) => Background = fill;
        GotKeyboardFocus += (_,_) => BorderThickness = new Thickness(1.5); LostKeyboardFocus += (_,_) => BorderThickness = new Thickness(0);
    }

    void Refresh() { text.Text = format(Value); AutomationProperties.SetItemStatus(this, format(Value)); }

    public void Select(int value) { int found = values.ToList().IndexOf(value); if (found >= 0) { index = found; Refresh(); } }

    /// Moves by `delta` steps, skipping excluded values; returns whether the value changed.
    public bool StepBy(int delta) {
        int next = Picker.Step(values, index, delta, wraps, Skip);
        if (next == index) return false;
        index = next; Refresh(); Changed?.Invoke(Value); return true;
    }

    protected override void OnMouseWheel(MouseWheelEventArgs e) {
        // Wheels report 120 per notch; precision touchpads report smaller deltas that accumulate.
        wheel += e.Delta; int steps = (int)(wheel / 120);
        if (steps != 0) { wheel -= steps * 120; StepBy(steps); }
        e.Handled = true; // keep the page from scrolling while adjusting
    }
    protected override void OnMouseLeftButtonDown(MouseButtonEventArgs e) {
        Focus(); CaptureMouse(); pressed = true; dragged = false; lastY = e.GetPosition(this).Y; e.Handled = true;
    }
    protected override void OnMouseMove(MouseEventArgs e) {
        if (!pressed) return;
        // Dragging up increases the value, about one step per 8 pixels.
        double y = e.GetPosition(this).Y; int steps = (int)((lastY - y) / 8);
        if (steps != 0) { dragged = true; lastY -= steps * 8; StepBy(steps); }
    }
    protected override void OnMouseLeftButtonUp(MouseButtonEventArgs e) {
        if (!pressed) return;
        pressed = false; ReleaseMouseCapture(); e.Handled = true;
        if (!dragged) OpenMenu();
    }
    protected override void OnKeyDown(KeyEventArgs e) {
        switch (e.Key) {
            case Key.Up: case Key.Right: StepBy(1); e.Handled = true; break;
            case Key.Down: case Key.Left: StepBy(-1); e.Handled = true; break;
            case Key.Enter: case Key.Space: OpenMenu(); e.Handled = true; break;
        }
    }
    void OpenMenu() {
        var menu = new ContextMenu { PlacementTarget = this, Placement = System.Windows.Controls.Primitives.PlacementMode.Bottom, MaxHeight = 320 };
        MenuItem? current = null;
        for (int i = 0; i < values.Count; i++) {
            if (Skip(values[i]) && i != index) continue;
            int choice = i;
            var item = new MenuItem { Header = format(values[i]), IsChecked = i == index };
            item.Click += (_,_) => { if (choice == index) return; index = choice; Refresh(); Changed?.Invoke(Value); };
            if (i == index) current = item;
            menu.Items.Add(item);
        }
        menu.Opened += (_,_) => current?.BringIntoView();
        menu.IsOpen = true;
    }
}
