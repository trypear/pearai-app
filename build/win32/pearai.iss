; Inno Docs - https://jrsoftware.org/ishelp/


; ********************************************
; These should match with the values in the product.json
#define Quality "stable"
#define NameShort "PearAI"
#define NameLong "PearAI"
#define MyAppExeName "PearAI.exe"
#define ExeBasename "PearAI"
#define AppMutex "pearai"
#define InstallTarget "user"
#define Arch "x64"

#define IncompatibleTargetAppId "{{D77B7E06-80BA-4137-BCF4-654B95CCEBC5}"
#define TunnelApplicationName "code-tunnel"
#define TunnelMutex "pearai-tunnel"
#define TunnelServiceMutex "pearai-tunnelservice"
; ********************************************

#define CurrentUserName GetEnv('USERNAME')
#define DesktopDir "C:\Users\" + CurrentUserName + "\Desktop"

#define MyAppName "PearAI"
#define ApplicationName "PearAI"
; Check if MyAppVersion is passed as a parameter, otherwise use default
#ifndef MyAppVersion
  #define MyAppVersion "1.5.2"
#endif
#define MyAppPublisher "PearAI Inc."
#define MyAppURL "https://trypear.ai"
#define PearLicenseFile DesktopDir + "\VSCode-win32-x64\resources\app\LICENSE.txt"
#define SetupIconFileName DesktopDir + "\PearAI Assets\Pear Icon.ico"
#define CompressionType "bzip"
#define SetupType "UserSetup"
#define OutputBaseFilename MyAppName + "-" + SetupType + "-" + Arch + "-" + MyAppVersion + "-" + CompressionType
#define OutputDirName DesktopDir + "\inno-output"


[Setup]
; NOTE: AppId uniquely identifies this application and should not be changed through the life of the application.
; Do not use the same AppId value in installers for other applications. - (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{501F34AE-0E55-47A8-ACED-FBDCD727DEA3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
VersionInfoVersion={#MyAppVersion}
VersionInfoCopyright=© {#MyAppPublisher} {#MyAppVersion}
DefaultGroupName={#NameLong}
AllowNoIcons=yes
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\{#MyAppName}
; "ArchitecturesAllowed=x64compatible" specifies that Setup cannot run on anything but x64 and Windows 11 on Arm.
ArchitecturesAllowed=x64compatible
; "ArchitecturesInstallIn64BitMode=x64compatible" requests that the install be done in "64-bit mode" on x64 or Windows 11 on Arm,
; meaning it should use the native 64-bit Program Files directory and the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
LicenseFile={#PearLicenseFile}
; Uncomment the following line to run in non administrative install mode (install for current user only.)
PrivilegesRequired=lowest
OutputDir={#OutputDirName}
OutputBaseFilename={#OutputBaseFilename}
SetupIconFile={#SetupIconFileName}
Compression=bzip
WizardStyle=modern


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl, {#DesktopDir}\pearai-app\build\win32\i18n\messages.en.isl"

[InstallDelete]
Type: filesandordirs; Name: "{app}\resources\app\out"; Check: IsNotBackgroundUpdate
Type: filesandordirs; Name: "{app}\resources\app\plugins"; Check: IsNotBackgroundUpdate
Type: filesandordirs; Name: "{app}\resources\app\extensions"; Check: IsNotBackgroundUpdate
Type: filesandordirs; Name: "{app}\resources\app\node_modules"; Check: IsNotBackgroundUpdate
Type: filesandordirs; Name: "{app}\resources\app\node_modules.asar.unpacked"; Check: IsNotBackgroundUpdate
Type: files; Name: "{app}\resources\app\node_modules.asar"; Check: IsNotBackgroundUpdate
Type: files; Name: "{app}\resources\app\Credits_45.0.2454.85.html"; Check: IsNotBackgroundUpdate


[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "runcode"; Description: "{cm:RunAfter,{#NameShort}}"; GroupDescription: "{cm:Other}"; Check: WizardSilent


[Files]
Source: "{#DesktopDir}\VSCode-win32-x64\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DesktopDir}\VSCode-win32-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{userprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeBasename}.exe"; Description: "{cm:LaunchProgram,{#NameLong}}"; Tasks: runcode; Flags: nowait postinstall; Check: ShouldRunAfterUpdate
Filename: "{app}\{#ExeBasename}.exe"; Description: "{cm:LaunchProgram,{#NameLong}}"; Flags: nowait postinstall; Check: WizardNotSilent


[Registry]
#if "user" == InstallTarget
#define SoftwareClassesRootKey "HKCU"
#else
#define SoftwareClassesRootKey "HKLM"
#endif

; Environment
#if "user" == InstallTarget
#define EnvironmentRootKey "HKCU"
#define EnvironmentKey "Environment"
#define Uninstall64RootKey "HKCU64"
#define Uninstall32RootKey "HKCU32"
#else
#define EnvironmentRootKey "HKLM"
#define EnvironmentKey "System\CurrentControlSet\Control\Session Manager\Environment"
#define Uninstall64RootKey "HKLM64"
#define Uninstall32RootKey "HKLM32"
#endif

[Code]
function IsBackgroundUpdate(): Boolean;
begin
  Result := ExpandConstant('{param:update|false}') <> 'false';
end;

function IsNotBackgroundUpdate(): Boolean;
begin
  Result := not IsBackgroundUpdate();
end;

// Don't allow installing conflicting architectures
function InitializeSetup(): Boolean;
var
  RegKey: String;
  ThisArch: String;
  AltArch: String;
begin
  Result := True;

  #if "user" == InstallTarget
    if not WizardSilent() and IsAdmin() then begin
      if MsgBox('This User Installer is not meant to be run as an Administrator. Are you sure you want to continue?', mbError, MB_OKCANCEL) = IDCANCEL then begin
        Result := False;
      end;
    end;
  #endif

  #if "user" == InstallTarget
    #if "arm64" == Arch
      #define IncompatibleArchRootKey "HKLM32"
    #else
      #define IncompatibleArchRootKey "HKLM64"
    #endif

    if Result and not WizardSilent() then begin
      RegKey := 'SOFTWARE\PearAI\Windows\CurrentVersion\Uninstall\' + copy('{#IncompatibleTargetAppId}', 2, 38) + '_is1';

      if RegKeyExists({#IncompatibleArchRootKey}, RegKey) then begin
        if MsgBox('{#NameShort} is already installed on this system for all users. We recommend first uninstalling that version before installing this one. Are you sure you want to continue the installation?', mbConfirmation, MB_YESNO) = IDNO then begin
          Result := False;
        end;
      end;
    end;
  #endif

end;

function WizardNotSilent(): Boolean;
begin
  Result := not WizardSilent();
end;

// Updates

var
	ShouldRestartTunnelService: Boolean;

function StopTunnelOtherProcesses(): Boolean;
var
	WaitCounter: Integer;
	TaskKilled: Integer;
begin
	Log('Stopping all tunnel services (at ' + ExpandConstant('"{app}\bin\{#TunnelApplicationName}.exe"') + ')');
	ShellExec('', 'powershell.exe', '-Command "Get-WmiObject Win32_Process | Where-Object { $_.ExecutablePath -eq ' + ExpandConstant('''{app}\bin\{#TunnelApplicationName}.exe''') + ' } | Select @{Name=''Id''; Expression={$_.ProcessId}} | Stop-Process -Force"', '', SW_HIDE, ewWaitUntilTerminated, TaskKilled)

	WaitCounter := 10;
	while (WaitCounter > 0) and CheckForMutexes('{#TunnelMutex}') do
	begin
		Log('Tunnel process is is still running, waiting');
		Sleep(500);
		WaitCounter := WaitCounter - 1
	end;

	if CheckForMutexes('{#TunnelMutex}') then
		begin
			Log('Unable to stop tunnel processes');
			Result := False;
		end
	else
		Result := True;
end;

procedure StopTunnelServiceIfNeeded();
var
	StopServiceResultCode: Integer;
	WaitCounter: Integer;
begin
  ShouldRestartTunnelService := False;
 	if CheckForMutexes('{#TunnelServiceMutex}') then begin
		// stop the tunnel service
		Log('Stopping the tunnel service using ' + ExpandConstant('"{app}\bin\{#ApplicationName}.cmd"'));
		ShellExec('', ExpandConstant('"{app}\bin\{#ApplicationName}.cmd"'), 'tunnel service uninstall', '', SW_HIDE, ewWaitUntilTerminated, StopServiceResultCode);

		Log('Stopping the tunnel service completed with result code ' + IntToStr(StopServiceResultCode));

		WaitCounter := 10;
		while (WaitCounter > 0) and CheckForMutexes('{#TunnelServiceMutex}') do
		begin
			Log('Tunnel service is still running, waiting');
			Sleep(500);
			WaitCounter := WaitCounter - 1
		end;
		if CheckForMutexes('{#TunnelServiceMutex}') then
			Log('Unable to stop tunnel service')
		else
			ShouldRestartTunnelService := True;
	end
end;


// called before the wizard checks for running application
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  if IsNotBackgroundUpdate() then
    StopTunnelServiceIfNeeded();

  if IsNotBackgroundUpdate() and not StopTunnelOtherProcesses() then
     Result := '{#NameShort} is still running a tunnel process. Please stop the tunnel before installing.'
  else
  	Result := '';
end;

// VS Code (PearAI) will create a flag file before the update starts (/update=C:\foo\bar)
// - if the file exists at this point, the user quit Code before the update finished, so don't start Code after update
// - otherwise, the user has accepted to apply the update and Code should start
function LockFileExists(): Boolean;
begin
  Result := FileExists(ExpandConstant('{param:update}'))
end;

function ShouldRunAfterUpdate(): Boolean;
begin
  if IsBackgroundUpdate() then
    Result := not LockFileExists()
  else
    Result := True;
end;

function IsWindows11OrLater(): Boolean;
begin
  Result := (GetWindowsVersion >= $0A0055F0);
end;

function GetAppMutex(Value: string): string;
begin
  if IsBackgroundUpdate() then
    Result := ''
  else
    Result := '{#AppMutex}';
end;

function GetDestDir(Value: string): string;
begin
  if IsBackgroundUpdate() then
    Result := ExpandConstant('{app}\_')
  else
    Result := ExpandConstant('{app}');
end;

function BoolToStr(Value: Boolean): String;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;

function QualityIsInsiders(): boolean;
begin
  if '{#Quality}' = 'insider' then
    Result := True
  else
    Result := False;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  UpdateResultCode: Integer;
	StartServiceResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    if IsBackgroundUpdate() then
    begin
      CreateMutex('{#AppMutex}-ready');

      Log('Checking whether application is still running...');
      while (CheckForMutexes('{#AppMutex}')) do
      begin
        Sleep(1000)
      end;
      Log('Application appears not to be running.');

      StopTunnelServiceIfNeeded();

      Exec(ExpandConstant('{app}\tools\inno_updater.exe'), ExpandConstant('"{app}\{#ExeBasename}.exe" ' + BoolToStr(LockFileExists()) + ' "{cm:UpdatingVisualStudioCode}"'), '', SW_SHOW, ewWaitUntilTerminated, UpdateResultCode);
    end;

    if ShouldRestartTunnelService then
    begin
      // start the tunnel service
      Log('Restarting the tunnel service...');
      ShellExec('', ExpandConstant('"{app}\bin\{#ApplicationName}.cmd"'), 'tunnel service install', '', SW_HIDE, ewWaitUntilTerminated, StartServiceResultCode);
      Log('Starting the tunnel service completed with result code ' + IntToStr(StartServiceResultCode));
      ShouldRestartTunnelService := False
    end;
  end;
end;

// https://stackoverflow.com/a/23838239/261019
procedure Explode(var Dest: TArrayOfString; Text: String; Separator: String);
var
  i, p: Integer;
begin
  i := 0;
  repeat
    SetArrayLength(Dest, i+1);
    p := Pos(Separator,Text);
    if p > 0 then begin
      Dest[i] := Copy(Text, 1, p-1);
      Text := Copy(Text, p + Length(Separator), Length(Text));
      i := i + 1;
    end else begin
      Dest[i] := Text;
      Text := '';
    end;
  until Length(Text)=0;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Path: string;
  VSCodePath: string;
  Parts: TArrayOfString;
  NewPath: string;
  i: Integer;
begin
  if not CurUninstallStep = usUninstall then begin
    exit;
  end;
  if not RegQueryStringValue({#EnvironmentRootKey}, '{#EnvironmentKey}', 'Path', Path)
  then begin
    exit;
  end;
  NewPath := '';
  VSCodePath := ExpandConstant('{app}\bin')
  Explode(Parts, Path, ';');
  for i:=0 to GetArrayLength(Parts)-1 do begin
    if CompareText(Parts[i], VSCodePath) <> 0 then begin
      NewPath := NewPath + Parts[i];

      if i < GetArrayLength(Parts) - 1 then begin
        NewPath := NewPath + ';';
      end;
    end;
  end;
  RegWriteExpandStringValue({#EnvironmentRootKey}, '{#EnvironmentKey}', 'Path', NewPath);
end;

#ifdef Debug
  #expr SaveToFile(AddBackslash(SourcePath) + "code-processed.iss")
#endif

// https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls
// https://docs.microsoft.com/en-US/windows/security/identity-protection/access-control/security-identifiers
procedure DisableAppDirInheritance();
var
  ResultCode: Integer;
  Permissions: string;
begin
  Permissions := '/grant:r "*S-1-5-18:(OI)(CI)F" /grant:r "*S-1-5-32-544:(OI)(CI)F" /grant:r "*S-1-5-11:(OI)(CI)RX" /grant:r "*S-1-5-32-545:(OI)(CI)RX"';

  #if "user" == InstallTarget
    Permissions := Permissions + Format(' /grant:r "*S-1-3-0:(OI)(CI)F" /grant:r "%s:(OI)(CI)F"', [GetUserNameString()]);
  #endif

  Exec(ExpandConstant('{sys}\icacls.exe'), ExpandConstant('"{app}" /inheritancelevel:r ') + Permissions, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

