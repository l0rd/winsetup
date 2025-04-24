$mainFunction =
{
    $mypath = $MyInvocation.MyCommand.Path
    Write-Output "Path of the script: $mypath"
    Write-Output "Args for script: $Args"

    GetLatestWinGet

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $dscUri = "https://raw.githubusercontent.com/l0rd/winsetup/main/"
    $dscGenSoftware = "l0rd.generalSoftware.dsc.yml";
    $dscWinSettings = "l0rd.winSettings.dsc.yml";
    $dscDev = "l0rd.dev.dsc.yml";
    $dscPodman = "podman.dev.dsc.yml";
    $dscPowerToysEnterprise = "Z:\source\powertoys\.configurations\configuration.vsEnterprise.dsc.yaml";

    $dscPodmanUri = $dscUri + $dscPodman;
    $dscGenSoftwareUri = $dscUri + $dscGenSoftware
    $dscDevUri = $dscUri + $dscDev
    $dscWinSettingsUri = $dscUri + $dscWinSettings

    # amazing, we can now run WinGet get fun stuff
    if (!$isAdmin)
    {
        # Shoulder tap terminal to it gets registered moving foward
        Start-Process shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App

        winget configuration -f $dscGenSoftwareUri

        # restarting for Admin now
        Start-Process PowerShell -wait -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$mypath' $Args;`"";
        exit;
    }
    else
    {
        Write-Host "Start: Podman dev requirements install"
        winget configuration -f $dscPodmanUri
        Write-Host "Done: Podman dev requirements install"

        # Staring dev workload
        Write-Host "Start: Dev flows install"
        winget configuration -f $dscDevUri

        Write-Host "Start: PowerToys dsc install"
        winget configuration -f $win # no cleanup needed as this is intentionally local

        Write-Host "Done: Dev flows install"
        # ending dev workload
    }
}

function GetLatestWinGet
{
    # forcing WinGet to be installed
    $isWinGetRecent = (winget -v).Trim('v').TrimEnd("-preview").split('.')

    # turning off progress bar to make invoke WebRequest fast
    $ProgressPreference = 'SilentlyContinue'

    if(!(($isWinGetRecent[0] -gt 1) -or ($isWinGetRecent[0] -ge 1 -and $isWinGetRecent[1] -ge 6))) # WinGet is greater than v1 or v1.6 or higher
    {
       $paths = "Microsoft.VCLibs.arm64.14.00.Desktop.appx", "Microsoft.UI.Xaml.2.8.arm64.appx", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
       $uris = "https://aka.ms/Microsoft.VCLibs.arm64.14.00.Desktop.appx", "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.arm64.appx", "https://aka.ms/getwinget"
       Write-Host "Downloading WinGet and its dependencies..."

       for ($i = 0; $i -lt $uris.Length; $i++) {
           $filePath = $paths[$i]
           $fileUri = $uris[$i]
           Write-Host "Downloading: ($filePat) from $fileUri"
           Invoke-WebRequest -Uri $fileUri -OutFile $filePath
       }

       Write-Host "Installing WinGet and its dependencies..."

       foreach($filePath in $paths)
       {
           Write-Host "Installing: ($filePath)"
           Add-AppxPackage $filePath
       }

       Write-Host "Verifying Version number of WinGet"
       winget -v

       Write-Host "Cleaning up"
       foreach($filePath in $paths)
       {
          if (Test-Path $filePath)
          {
             Write-Host "Deleting: ($filePath)"
             Remove-Item $filePath -verbose
          }
          else
          {
             Write-Error "Path doesn't exits: ($filePath)"
          }
       }
    }
    else {
       Write-Host "WinGet in decent state, moving to executing DSC"
    }
}

& $mainFunction
