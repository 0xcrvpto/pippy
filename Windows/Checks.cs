using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;

namespace Pippy;
static class Checks {
    static void Assert(bool condition,string message) { if(!condition)throw new Exception(message); }
    public static int Run() {
        var temp=Path.Combine(Path.GetTempPath(),"Pippy-check-"+Guid.NewGuid());
        try {
            var day=new WindowHours(555,705);Assert(day.Slot(555,60)&&day.Slot(615,60)&&!day.Contains(705)&&!day.Contains(554),"daytime boundaries");
            var overnight=new WindowHours(1350,120);Assert(overnight.Slot(30,60)&&overnight.Contains(119)&&!overnight.Contains(120)&&!overnight.Contains(720),"overnight boundaries");
            Assert(!new WindowHours(100,100).Valid,"equal times rejected");
            var store=new SettingsStore(Path.Combine(temp,"settings.json"));var settings=new Settings {WorkoutStart=555,WorkoutEnd=705};
            store.Save(settings);Assert(store.Load().WorkoutStart==555,"settings persist");
            File.WriteAllText(Path.Combine(temp,"settings.json"),"broken JSON");Assert(store.Load().Hours.Valid,"corrupt settings recover");
            var now=new DateTimeOffset(2026,10,22,9,15,0,TimeSpan.Zero);var scheduler=new Schedule(settings,now);
            Assert(scheduler.Due(now)==Kind.Rally,"workout start");Assert(scheduler.Due(now.AddSeconds(5))==null,"no duplicate workout");
            scheduler.Snooze(Kind.Mochi,now);Assert(scheduler.Due(now.AddMinutes(9))==null,"snooze waits");Assert(scheduler.Due(now.AddMinutes(10))==Kind.Mochi,"snooze delivers");
            var eye=new EyeBreak(now);Assert(eye.Remaining(now)==20&&eye.Tick(now.AddSeconds(9))==null,"eye start");
            Assert(eye.Tick(now.AddSeconds(10))==Cue.Halfway&&eye.Tick(now.AddSeconds(11))==null,"one halfway cue");
            Assert(eye.Tick(now.AddSeconds(20))==Cue.Complete&&eye.Tick(now.AddSeconds(21))==null,"one completion cue");
            foreach(var kind in Enum.GetValues<Kind>())Assert(Visuals.Bitmap(kind+".png").PixelWidth>0,"mascot resource");
            foreach(var name in new[]{"BlinkStart","BlinkHalfway","BlinkComplete","BlinkPreview"}) {
                using var stream=Visuals.Resource(name+".wav");using var player=new System.Media.SoundPlayer(stream);player.Load();Assert(player.IsLoadCompleted,"audio decoding");
            }
            using(var icon=Visuals.Resource("AppIcon.ico"))using(var image=new System.Drawing.Icon(icon))Assert(image.Width>0,"tray icon");
            File.WriteAllText(Path.Combine(Path.GetTempPath(),"pippy-test-result.txt"),"PASS: schedule, persistence, snooze, countdown, images, audio, icon");
            return 0;
        } catch(Exception e) { File.WriteAllText(Path.Combine(Path.GetTempPath(),"pippy-test-result.txt"),e.ToString());return 1; }
        finally { if(Directory.Exists(temp))Directory.Delete(temp,true); }
    }
    public static int Smoke(Application app,string output) {
        Directory.CreateDirectory(output);var settings=new Settings {ReduceMotion=true};
        var cues=new List<Cue>();int snoozes=0;var home=new HomeWindow(settings,()=>{},_=>{},_=>{},()=>{});
        var popup=new ReminderWindow(Kind.Blink,settings,cues.Add,()=>snoozes++);
        var wait=new DispatcherTimer {Interval=TimeSpan.FromSeconds(21.5)};
        app.DispatcherUnhandledException+=(_,e)=>{File.WriteAllText(Path.Combine(output,"error.txt"),e.Exception.ToString());e.Handled=true;app.Shutdown(1);};
        home.Show();popup.Show();
        app.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle,new Action(()=>{
            Visuals.Render(home,Path.Combine(output,"preferences.png"));Visuals.Render(popup,Path.Combine(output,"blink.png"));
            popup.Primary.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            Assert(!popup.Primary.IsEnabled&&cues.SequenceEqual(new[]{Cue.Start}),"UI starts break");wait.Start();
        }));
        wait.Tick+=(_,_)=>{
            wait.Stop();try {
                Assert(popup.Primary.IsEnabled&&cues.SequenceEqual(new[]{Cue.Start,Cue.Halfway,Cue.Complete}),"UI countdown completion");
                Visuals.Render(popup,Path.Combine(output,"completed.png"));popup.Close();
                foreach(var kind in new[]{Kind.Rally,Kind.Mochi}) {
                    var other=new ReminderWindow(kind,settings,_=>{},()=>snoozes++);other.Show();Visuals.Render(other,Path.Combine(output,kind+".png"));
                    other.Later.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
                }
                Assert(snoozes==2,"UI snooze buttons");File.WriteAllText(Path.Combine(output,"smoke-result.txt"),"PASS: windows render; real 20-second timer; all three cues; snooze clicks");app.Shutdown(0);
            }catch(Exception e){File.WriteAllText(Path.Combine(output,"error.txt"),e.ToString());app.Shutdown(1);}
        };
        return app.Run();
    }
}
