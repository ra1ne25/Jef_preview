; JefPreview Windows installer (Inno Setup 6)
; Build: ..\scripts\package.ps1

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName "JefPreview"
#define MyAppPublisher "JefPreview"
#define MyAppURL "https://github.com/ra1ne25/Jef_preview"
#define MyAppExeName "JefPreview.Tools.exe"
#define StagingDir "..\build\installer-staging"

[Setup]
AppId={{7F4E2A91-3B6C-4D8E-9F01-2A5B6C7D8E9F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=JefPreview-{#MyAppVersion}-win-x64-setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#StagingDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "diag"; Comment: "JefPreview diagnostics"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "diag"; Tasks: desktopicon

[Run]
Filename: "{sys}\regsvr32.exe"; Parameters: "/s ""{app}\JefPreview.Shell.comhost.dll"""; StatusMsg: "{cm:MsgRegisterCom}"; Flags: runhidden waituntilterminated
Filename: "{app}\{#MyAppExeName}"; Parameters: "register"; StatusMsg: "{cm:MsgRegisterShell}"; Flags: runhidden waituntilterminated
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM prevhost.exe /IM dllhost.exe"; Flags: runhidden; StatusMsg: "{cm:MsgRestartExplorer}"
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM explorer.exe"; Flags: runhidden
Filename: "{win}\explorer.exe"; Flags: nowait

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM prevhost.exe /IM dllhost.exe"; Flags: runhidden; RunOnceId: "StopHosts"
Filename: "{app}\{#MyAppExeName}"; Parameters: "unregister"; Flags: runhidden waituntilterminated; RunOnceId: "UnregShell"
Filename: "{sys}\regsvr32.exe"; Parameters: "/u /s ""{app}\JefPreview.Shell.comhost.dll"""; Flags: runhidden; RunOnceId: "UnregCom"

[CustomMessages]
english.MsgRegisterCom=Registering COM components...
english.MsgRegisterShell=Registering Explorer shell extensions...
english.MsgRestartExplorer=Restarting Windows Explorer...
russian.MsgRegisterCom=Регистрация COM-компонентов...
russian.MsgRegisterShell=Регистрация расширений Проводника...
russian.MsgRestartExplorer=Перезапуск Проводника Windows...

[Messages]
english.WelcomeLabel2=This will install [name/ver] on your computer.%n%nJefPreview adds thumbnail and preview pane support for Janome .jef embroidery files in Windows Explorer.%n%nRequires .NET 9 Desktop Runtime (installer will check). Administrator rights are required.
russian.WelcomeLabel2=На ваш компьютер будет установлен [name/ver].%n%nJefPreview добавляет миниатюры и область предпросмотра для файлов вышивки Janome (.jef) в Проводнике Windows.%n%nТребуется .NET 9 Desktop Runtime (проверка при установке) и права администратора.
english.FinishedLabel=Setup has finished installing [name] on your computer.%n%nOpen Explorer, enable the preview pane (View - Preview pane), and select a .jef file.
russian.FinishedLabel=Установка [name] завершена.%n%nОткройте Проводник, включите область просмотра (Вид - Область просмотра) и выделите файл .jef.

[Code]
function HasDesktopRuntime9: Boolean;
var
  Names: TArrayOfString;
  I: Integer;
begin
  Result := False;
  if RegGetSubkeyNames(HKLM, 'SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App', Names) then
  begin
    for I := 0 to GetArrayLength(Names) - 1 do
      if Copy(Names[I], 1, 2) = '9.' then
      begin
        Result := True;
        Exit;
      end;
  end;
  if RegGetSubkeyNames(HKLM, 'SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App', Names) then
  begin
    for I := 0 to GetArrayLength(Names) - 1 do
      if Copy(Names[I], 1, 2) = '9.' then
      begin
        Result := True;
        Exit;
      end;
  end;
end;

function InitializeSetup: Boolean;
var
  R: Integer;
begin
  Result := True;
  if HasDesktopRuntime9 then
    Exit;

  if ActiveLanguage = 'russian' then
    R := MsgBox('Для JefPreview нужен .NET 9 Desktop Runtime.' + #13#10 + #13#10 +
      'Открыть страницу загрузки Microsoft?', mbConfirmation, MB_YESNO)
  else
    R := MsgBox('.NET 9 Desktop Runtime is required for JefPreview.' + #13#10 + #13#10 +
      'Open the Microsoft download page?', mbConfirmation, MB_YESNO);

  if R = IDYES then
    ShellExec('open', 'https://dotnet.microsoft.com/en-us/download/dotnet/9.0', '', '', SW_SHOW, ewNoWait, R);

  if ActiveLanguage = 'russian' then
    Result := MsgBox('Установите .NET 9 Desktop Runtime и запустите установщик снова.' + #13#10 + #13#10 +
      'Продолжить установку без runtime (не рекомендуется)?', mbConfirmation, MB_YESNO) = IDYES
  else
    Result := MsgBox('Install .NET 9 Desktop Runtime and run this setup again.' + #13#10 + #13#10 +
      'Continue setup without runtime (not recommended)?', mbConfirmation, MB_YESNO) = IDYES;
end;

