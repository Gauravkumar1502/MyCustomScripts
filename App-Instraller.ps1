# A basic script for installing a list of apps from a text file using winget or choco
#
# Note: If you get an error about the script not being allowed to run, the below command will change the execution polciy temporarily for one session only:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
#
# To execute the script, open a Powershell window to the directory with the script and run the following command using your scripts file name (and don't forget the .\ )
# .\Apps-Installer.ps1
# -------------------------------------------------------------------------------------------
# Script by Gaurav Kumar - ( https://github.com/Gauravkumar1502 )
# -------------------------------------------------------------------------------------------

# Pause the script and display instructions
Write-Host "This script will install the each app listed in the 'appsList.txt' file using winget or choco."
Write-Host ""
Write-Host "Please create or update 'appsList.txt' file in the same directory as this script and list the apps id or package name followed by the package manager name (winget or choco) in the following format:"
write-host "[winget | choco] [app id | package name]"
write-host "Example:"
write-host "winget Git.Git"
Write-Host ""
Write-Host -NoNewline "Do you want to continue? [Y/N]: "

if ((Read-Host).ToUpper() -ne "Y") {
    Write-Host "Exiting script."
    exit
}

# Check if winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed. Please install winget and run the script again."
    exit
}

# Check if choco is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Choco is not installed."
    Write-Host -NoNewline "Do you want to install choco? [Y/N]: "
    if ((Read-Host).ToUpper() -eq "Y") {
        # Install choco
        $installChoco = Start-Process -FilePath "powershell" -ArgumentList "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" -PassThru -NoNewWindow
        $installChoco.WaitForExit()
        if ($installChoco.ExitCode -eq 0) {
            Write-Host "Choco installed successfully"
        } else {
            Write-Host "Failed to install choco"
            exit
        }
    } else {
        Write-Host "Exiting script."
        exit
    }
}

# Read the list of apps from the file
$appsToInstall = Get-Content -Path ".\appsList.txt"

# Create an array to hold unsuccessful attempts to install apps
$failedToInstall = @()

# Function to install an app using Winget
function InstallWingetApp($appId) {
    Write-host ""
    Write-Host "Installing app: $appId"
    # Start the installation process in the current PowerShell session
    $installProcess = Start-Process -FilePath "winget" -ArgumentList "install -e --id $appId" -PassThru -NoNewWindow

    # Wait for the installation process to complete
    $installProcess.WaitForExit()
    return $installProcess.ExitCode
}

# Function to install an app using Choco
function InstallChocoApp($packageName) {
    Write-Host ""
    Write-Host "Installing app: $packageName"
    # Start the installation process in the current PowerShell session
    $installProcess = Start-Process -FilePath "choco" -ArgumentList "install $packageName -y" -PassThru -NoNewWindow

    # Wait for the installation process to complete
    $installProcess.WaitForExit()
    return $installProcess.ExitCode
}

# Process each line
foreach ($app in $appsToInstall) {
    # Trim any leading or trailing white space
    $app = $app.Trim()

    # Ignore empty lines
    if ($app -eq "") {
        continue
    }
    $appDetails = $app.Split(" ")

    # Install the app using the appropriate package manager
    if ($appDetails[0] -eq "winget") {
        if (InstallWingetApp($appDetails[1]) -ne 0) {
            $failedToInstall += $app
        }
    } elseif ($appDetails[0] -eq "choco") {
        if (InstallChocoApp($appDetails[1]) -ne 0) {
            $failedToInstall += $app
        }
    } else {
        Write-Host "Invalid package manager specified for app: $app"
        $failedToInstall += $app
    }
}

write-host ""
if ($failedToInstall.Count -gt 0) {
    Write-Host "Installation process completed, but failed to install the following apps:"
    foreach ($app in $failedToInstall) {
        Write-Host $app
    }
} else {
    Write-Host "All apps installed successfully."
}