using System;
using System.IO;
using System.Linq;
using System.Media;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace Pippy;
static class Visuals {
    public static readonly Brush Ink = new SolidColorBrush(Color.FromRgb(37,52,59));
    public static readonly Brush Muted = new SolidColorBrush(Color.FromRgb(105,120,125));
    public static readonly Brush Cream = new SolidColorBrush(Color.FromRgb(247,245,240));
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
        var button = new Button { Content = text, Padding = new Thickness(14,7,14,7), Margin = new Thickness(0,0,8,0),
            Background = primary ? Ink : Brushes.White, Foreground = primary ? Brushes.White : Ink,
            BorderThickness = new Thickness(0), Cursor = System.Windows.Input.Cursors.Hand };
        button.Click += click; return button;
    }
    public static Border Card(UIElement content) => new() { Child = content, Background = Brushes.White, CornerRadius = new CornerRadius(18), Padding = new Thickness(18), Margin = new Thickness(0,0,0,12) };
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
