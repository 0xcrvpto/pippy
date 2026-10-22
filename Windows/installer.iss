[Setup]
AppId={{4C13DE6C-5688-49E6-8333-39314ED2C34F}
AppName=Pippy
AppVersion=0.6.2
AppPublisher=0xcrvpto
AppPublisherURL=https://github.com/0xcrvpto/pippy
DefaultDirName={localappdata}\Programs\Pippy
DefaultGroupName=Pippy
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.19041
OutputDir=..\dist\windows
OutputBaseFilename=Pippy-0.6.2-Windows-x64-Setup
SetupIconFile=AppIcon.ico
UninstallDisplayIcon={app}\Pippy.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
[Files]
Source: "..\dist\windows\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Pippy"; Filename: "{app}\Pippy.exe"
[Run]
Filename: "{app}\Pippy.exe"; Description: "Open Pippy"; Flags: nowait postinstall skipifsilent
