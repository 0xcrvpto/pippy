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
            foreach(var set in Enum.GetValues<SoundSet>())
            foreach(var name in Enum.GetValues<Cue>().Select(cue=>Sounds.File(set,cue)).Append(Sounds.Preview(set))) {
                using var stream=Visuals.Resource(name+".wav");using var player=new System.Media.SoundPlayer(stream);player.Load();Assert(player.IsLoadCompleted,"audio decoding "+name);
            }
            Assert(Sounds.File(SoundSet.Bells,Cue.Halfway)=="BlinkHalfway"&&Sounds.Nudge(SoundSet.Chimes)=="ChimesStart","sound filenames");
            var fresh=new Settings();Assert(fresh.SoundSets[Kind.Blink]==SoundSet.Bells&&fresh.SoundSets[Kind.Rally]==SoundSet.Marimba&&fresh.SoundSets[Kind.Mochi]==SoundSet.Kalimba,"sound defaults");
            fresh.SoundSets[Kind.Mochi]=SoundSet.Woodblock;store.Save(fresh);Assert(store.Load().SoundSets[Kind.Mochi]==SoundSet.Woodblock&&store.Load().SoundSets[Kind.Blink]==SoundSet.Bells,"sound choice persists");
            File.WriteAllText(Path.Combine(temp,"settings.json"),"{\"SoundSets\":{\"Rally\":42}}");Assert(store.Load().SoundSets[Kind.Rally]==SoundSet.Marimba&&store.Load().SoundSets[Kind.Blink]==SoundSet.Bells,"invalid sound recovers");
            var q=Picker.QuarterHours;
            Assert(q[Picker.Step(q,95,1,true,_=>false)]==0&&q[Picker.Step(q,0,-2,true,_=>false)]==1410,"picker wraps midnight");
            Assert(q[Picker.Step(q,95,1,true,m=>m==0)]==15,"picker skips matching time");
            var minutes=Settings.Choices(Kind.Blink).ToList();Assert(Picker.Step(minutes,minutes.Count-1,1,false,_=>false)==minutes.Count-1&&minutes[Picker.Step(minutes,minutes.Count-1,-3,false,_=>false)]==45,"picker clamps intervals");
            Assert(Picker.Nearest(q,560)==37,"picker nearest value");
            var mail=Feedback.MailtoUri();Assert(mail.StartsWith("mailto:0xcrvpto@webuild3.xyz?subject=Pippy%20feedback&body=")&&!mail.Contains(' '),"feedback email link");
            Assert(Feedback.Telegram=="https://t.me/i0xcrvpto","feedback telegram link");
            var hoursSettings=new Settings();
            Assert(hoursSettings.HoursFor(Kind.Blink)==new WindowHours(660,1380)&&hoursSettings.HoursFor(Kind.Mochi)==new WindowHours(660,1380),"break hours default");
            Assert(hoursSettings.SetHours(Kind.Blink,540,1020)&&!hoursSettings.SetHours(Kind.Mochi,60,60)&&hoursSettings.HoursFor(Kind.Mochi)==new WindowHours(660,1380),"break hours independent and validated");
            store.Save(hoursSettings);Assert(store.Load().HoursFor(Kind.Blink)==new WindowHours(540,1020),"break hours persist");
            File.WriteAllText(Path.Combine(temp,"settings.json"),"{\"ActiveStart\":{\"Blink\":5},\"ActiveEnd\":{\"Blink\":5}}");Assert(store.Load().HoursFor(Kind.Blink)==new WindowHours(660,1380),"invalid break hours recover");
            var breakSchedule=new Schedule(hoursSettings,new DateTimeOffset(2026,10,22,7,0,0,TimeSpan.Zero));hoursSettings.Enabled[Kind.Rally]=false;
            Assert(breakSchedule.Due(new DateTimeOffset(2026,10,22,8,0,0,TimeSpan.Zero))==null,"no eye break before its hours");
            Assert(breakSchedule.Due(new DateTimeOffset(2026,10,22,9,30,0,TimeSpan.Zero))==Kind.Blink,"eye break inside its hours");
            Assert(Updates.IsNewer("v0.6.1","0.6")&&Updates.IsNewer("0.10","0.9.9")&&!Updates.IsNewer("v0.6.1","0.6.1")&&!Updates.IsNewer("0.6","0.6.1"),"update version comparison");
            var latest=Updates.Parse("{\"tag_name\":\"v0.7.0\",\"html_url\":\"https://github.com/0xcrvpto/pippy/releases/tag/v0.7.0\",\"draft\":false,\"prerelease\":false,\"assets\":[{\"name\":\"Pippy-0.7-arm64.dmg\",\"browser_download_url\":\"https://example.com/mac.dmg\"},{\"name\":\"Pippy-0.7-Windows-x64-Setup.exe\",\"browser_download_url\":\"https://example.com/win.exe\"}]}");
            Assert(latest!=null&&latest.Version=="0.7.0"&&latest.Download=="https://example.com/win.exe","update release parsing");
            var pageOnly=Updates.Parse("{\"tag_name\":\"v0.8\",\"html_url\":\"https://github.com/0xcrvpto/pippy/releases/tag/v0.8\",\"assets\":[]}");
            Assert(pageOnly!=null&&pageOnly.Download==pageOnly.Page,"update page fallback");
            Assert(Updates.Parse("{\"tag_name\":\"v0.9\",\"html_url\":\"x\",\"prerelease\":true}")==null&&Updates.Parse("nope")==null,"update ignores prereleases and bad JSON");
            using(var icon=Visuals.Resource("AppIcon.ico"))using(var image=new System.Drawing.Icon(icon))Assert(image.Width>0,"tray icon");
            File.WriteAllText(Path.Combine(Path.GetTempPath(),"pippy-test-result.txt"),"PASS: schedule, per-buddy active hours, persistence, snooze, countdown, images, audio for every sound set, sound choices, picker, feedback links, update parsing, icon");
            return 0;
        } catch(Exception e) { File.WriteAllText(Path.Combine(Path.GetTempPath(),"pippy-test-result.txt"),e.ToString());return 1; }
        finally { if(Directory.Exists(temp))Directory.Delete(temp,true); }
    }
    public static int Smoke(Application app,string output) {
        Directory.CreateDirectory(output);var settings=new Settings {ReduceMotion=true};
        var cues=new List<Cue>();int snoozes=0,saves=0;var previews=new List<Kind>();
        var home=new HomeWindow(settings,()=>saves++,_=>saves++,_=>{},previews.Add);
        var popup=new ReminderWindow(Kind.Blink,settings,cues.Add,()=>snoozes++);
        var wait=new DispatcherTimer {Interval=TimeSpan.FromSeconds(21.5)};
        app.DispatcherUnhandledException+=(_,e)=>{File.WriteAllText(Path.Combine(output,"error.txt"),e.Exception.ToString());e.Handled=true;app.Shutdown(1);};
        home.Show();popup.Show();
        app.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle,new Action(()=>{
            Visuals.Render(home,Path.Combine(output,"preferences.png"));Visuals.Render(popup,Path.Combine(output,"blink.png"));
            Assert(home.Intervals[Kind.Blink].StepBy(-1)&&settings.Minutes[Kind.Blink]==15,"UI interval chip saves");
            home.Start.Select(17*60);home.End.Select(17*60+15);
            Assert(home.End.StepBy(-1)&&settings.WorkoutStart==17*60&&settings.WorkoutEnd==16*60+45,"UI time chip skips start and saves");
            Assert(home.HourChips[Kind.Mochi].Start.StepBy(-4)&&settings.HoursFor(Kind.Mochi)==new WindowHours(600,1380)&&settings.HoursFor(Kind.Blink)==new WindowHours(660,1380),"UI break hours save independently");
            home.Toggles[Kind.Mochi].IsChecked=false;home.Toggles[Kind.Mochi].RaiseEvent(new RoutedEventArgs(System.Windows.Controls.Primitives.ButtonBase.ClickEvent));
            Assert(!settings.Enabled[Kind.Mochi],"UI switch saves");Visuals.Render(home,Path.Combine(output,"preferences-edited.png"));
            home.SoundPickers[Kind.Rally].SelectedIndex=(int)SoundSet.Chimes;
            Assert(settings.SoundSets[Kind.Rally]==SoundSet.Chimes&&previews.SequenceEqual(new[]{Kind.Rally}),"UI sound picker saves and previews");
            Assert(saves>=4,"UI changes save");
            Assert(home.UpdateBanner.Visibility==Visibility.Collapsed,"update banner starts hidden");
            home.ShowUpdate(new Release("0.7","https://github.com/0xcrvpto/pippy/releases","https://github.com/0xcrvpto/pippy/releases"));
            Assert(home.UpdateBanner.Visibility==Visibility.Visible,"update banner shows");Visuals.Render(home,Path.Combine(output,"update.png"));
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
                Assert(snoozes==2,"UI snooze buttons");File.WriteAllText(Path.Combine(output,"smoke-result.txt"),"PASS: windows render; real 20-second timer; all three cues; snooze clicks; interval, time and sound controls save");app.Shutdown(0);
            }catch(Exception e){File.WriteAllText(Path.Combine(output,"error.txt"),e.ToString());app.Shutdown(1);}
        };
        return app.Run();
    }
}
