using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Threading;

namespace Pippy;
sealed class ReminderWindow : Window {
    readonly DispatcherTimer timer = new() {Interval=TimeSpan.FromMilliseconds(200)};
    EyeBreak? eyeBreak;
    bool complete;
    public Button Primary {get;}
    public Button Later {get;}
    public TextBlock Status {get;}
    public ReminderWindow(Kind kind, Settings settings, Action<Cue> sound, Action snooze) {
        Width=370;Height=kind==Kind.Blink?340:310;WindowStyle=WindowStyle.None;ResizeMode=ResizeMode.NoResize;
        AllowsTransparency=true;Background=Brushes.Transparent;Topmost=true;ShowInTaskbar=false;ShowActivated=false;
        Title="Pippy — "+kind;Icon=Visuals.Bitmap("AppIcon.png");
        var grid=new Grid();Content=grid;
        var content=new StackPanel {Margin=new Thickness(23,62,23,20)};
        var card=new Border {Background=Visuals.Cream,CornerRadius=new CornerRadius(24),Margin=new Thickness(0,42,0,0),Child=content};grid.Children.Add(card);
        var mascot=Visuals.Mascot(kind,104);mascot.HorizontalAlignment=HorizontalAlignment.Left;mascot.VerticalAlignment=VerticalAlignment.Top;mascot.Margin=new Thickness(16,0,0,0);grid.Children.Add(mascot);
        var close=Visuals.Button("×",(_,_)=>Close());close.HorizontalAlignment=HorizontalAlignment.Right;close.VerticalAlignment=VerticalAlignment.Top;close.Margin=new Thickness(0,55,14,0);grid.Children.Add(close);
        content.Children.Add(Visuals.Text("A LITTLE NUDGE FROM "+kind.ToString().ToUpperInvariant(),10,true));
        content.Children.Add(Visuals.Text(kind switch {Kind.Blink=>"A little rest for your eyes.",Kind.Mochi=>"Let's uncurl a little.",_=>"Time for a little movement?"},20,true));
        content.Children.Add(Visuals.Text(kind switch {
            Kind.Blink=>settings.Sound?"Look about 20 feet away for 20 seconds. I'll chime when it's time to come back.":"Look about 20 feet away for 20 seconds. A quiet little reset, just for you.",
            Kind.Mochi=>"Roll your shoulders. Stretch your legs. A tiny reset can feel pretty good.",
            _=>"A workout, a walk, or a few stretches. Make a little room for yourself."
        },13));
        Status=Visuals.Text(kind==Kind.Blink?"20 seconds · ready when you are":"",12,true);content.Children.Add(Status);
        var actions=new StackPanel {Orientation=Orientation.Horizontal,Margin=new Thickness(0,8,0,0)};
        Later=Visuals.Button("In 10 minutes",(_,_)=>{snooze();Close();});actions.Children.Add(Later);
        Primary=Visuals.Button(kind==Kind.Blink?"Start break":"Got it",(_,_)=>{
            if(kind!=Kind.Blink || complete){Close();return;}
            if(eyeBreak!=null)return;
            eyeBreak=new EyeBreak(DateTimeOffset.Now);Primary.IsEnabled=false;Primary.Content="Resting…";Later.Visibility=Visibility.Collapsed;
            Status.Text="20 seconds left · look away";sound(Cue.Start);timer.Start();
        },true);actions.Children.Add(Primary);content.Children.Add(actions);
        timer.Tick+=(_,_)=>{
            if(eyeBreak==null)return;
            var now=DateTimeOffset.Now;Status.Text=$"{eyeBreak.Remaining(now)} seconds left · look away";
            var cue=eyeBreak.Tick(now);if(cue.HasValue)sound(cue.Value);
            if(cue==Cue.Complete){complete=true;timer.Stop();Status.Text="Eyes rested. Welcome back!";Primary.IsEnabled=true;Primary.Content="Done";}
        };
        Closed+=(_,_)=>timer.Stop();
        Loaded+=(_,_)=>{
            var area=SystemParameters.WorkArea;Left=area.Right-Width-20;Top=area.Bottom-Height-20;
            if(!settings.ReduceMotion && SystemParameters.ClientAreaAnimation) {
                var transform=new TranslateTransform();mascot.RenderTransform=transform;
                transform.BeginAnimation(TranslateTransform.YProperty,new DoubleAnimation(-8,0,TimeSpan.FromSeconds(.7)){EasingFunction=new BackEase{EasingMode=EasingMode.EaseOut,Amplitude=.3}});
            }
        };
        MouseLeftButtonDown+=(_,e)=>{if(e.OriginalSource==card)DragMove();};
    }
}
