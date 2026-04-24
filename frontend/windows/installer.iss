[Setup]
AppName=Temple Clock
AppVersion=1.0.0
AppPublisher=CareShift
DefaultDirName={autopf}\Temple Clock
DefaultGroupName=Temple Clock
UninstallDisplayIcon={app}\careshift.exe
Compression=lzma2
SolidCompression=yes
OutputDir=..\build\windows\installer
OutputBaseFilename=TempleClock_Setup
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\careshift.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Temple Clock"; Filename: "{app}\careshift.exe"
Name: "{autodesktop}\Temple Clock"; Filename: "{app}\careshift.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\careshift.exe"; Description: "Launch Temple Clock"; Flags: nowait postinstall skipifsilent
