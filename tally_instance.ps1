# Step 1: Bring Disk Online, Initialize, Partition, and Format
Write-Host "Checking for uninitialized disks..."

# Get the disk that is not initialized and not online
$disk = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Offline' -and $_.PartitionStyle -eq 'RAW' }

if ($disk) {
Write-Host "Found a new disk. Bringing it online..."

# Bring the disk online
$disk | Set-Disk -IsOffline $false

# Initialize the disk (GPT format)
Write-Host "Initializing disk..."
$disk | Initialize-Disk -PartitionStyle GPT

# Create a new partition using all available space
Write-Host "Creating partition..."
$partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

# Format the new partition as NTFS and label it
Write-Host "Formatting partition as NTFS..."
Format-Volume -FileSystem NTFS -NewFileSystemLabel "NewDisk" -Partition $partition -Confirm:$false

# Optionally assign a specific drive letter (e.g., "E:")
Write-Host "Assigning drive letter 'E' to the new partition..."
$partition | Set-Partition -NewDriveLetter "E"

Write-Host "Disk initialized, partitioned, and formatted successfully."
} else {
Write-Host "No uninitialized disks found."
}

# Get the disk that is RAW
$diskToInitialize = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }

if ($diskToInitialize) {
Write-Host "Initializing RAW disk: Disk Number $($diskToInitialize.Number)"

# Bring the disk online
$diskToInitialize | Set-Disk -IsOffline $false

# Initialize the disk (GPT or MBR, choose according to your needs)
$diskToInitialize | Initialize-Disk -PartitionStyle GPT

# Create a new partition using all available space
$partition = New-Partition -DiskNumber $diskToInitialize.Number -UseMaximumSize -AssignDriveLetter

# Format the new partition as NTFS and label it
Format-Volume -FileSystem NTFS -NewFileSystemLabel "NewDisk" -Partition $partition -Confirm:$false

Write-Host "Disk initialized, partitioned, and formatted successfully."
} else {
Write-Host "No RAW disks found."
}

# Step 2: Define user details
$adminUsers = @(
@{Username="francis"; Password="Clevertap@123"},
@{Username="rafiq"; Password="Clevertap@123"}
)

$regularUsers = @(
@{Username="rohan"; Password="Clevertap@123"},
@{Username="jayesh.sumsera"; Password="Clevertap@123"},
@{Username="Sameer"; Password="Clevertap@123"}
)

# Create admin users
foreach ($user in $adminUsers) {
$username = $user.Username
$password = ConvertTo-SecureString $user.Password -AsPlainText -Force
New-LocalUser -Name $username -Password $password -FullName "$username" -Description "Admin User"
Add-LocalGroupMember -Group "Administrators" -Member $username
Write-Host "Created admin user: $username"
}

# Create regular users
foreach ($user in $regularUsers) {
$username = $user.Username
$password = ConvertTo-SecureString $user.Password -AsPlainText -Force
New-LocalUser -Name $username -Password $password -FullName "$username" -Description "Regular User"
Write-Host "Created regular user: $username"
}

# Set the download URL for the latest cloudflared version (Windows 64-bit)
$downloadUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
$cloudflaredPath = "$env:C:\cloudflared\bin"

# Check if cloudflared directory exists, if not create it
if (-not (Test-Path -Path $cloudflaredPath)) {
New-Item -ItemType Directory -Path $cloudflaredPath
}

# Download the cloudflared binary
$exePath = "$cloudflaredPath\cloudflared.exe"
Write-Host "Downloading cloudflared from $downloadUrl..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath

# Verify if download was successful
if (Test-Path -Path $exePath) {
Write-Host "cloudflared downloaded successfully."

# Add cloudflared directory to system PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$cloudflaredPath*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$cloudflaredPath", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "cloudflared path added to system PATH."
} else {
    Write-Host "cloudflared path is already in the system PATH."
}

# Verify installation
Write-Host "Verifying cloudflared installation..."
$versionOutput = & "$exePath" --version
Write-Host $versionOutput
} else {
Write-Host "Failed to download cloudflared."
}

# Update the current PowerShell session with the latest PATH environment variable
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

# Verify if cloudflared is now available
cloudflared --version

Write-Host "Installation script completed."

# Define the directory and file paths
$cloudflaredDir = "C:\Users\Administrator\.cloudflared"
$configFile = "$cloudflaredDir\config.yml"
$credentialsFile = "$cloudflaredDir\e6261fd1-05dc-4c83-8188-e105a41ef420.json"

# Ensure the .cloudflared directory exists
if (-not (Test-Path -Path $cloudflaredDir)) {
New-Item -ItemType Directory -Path $cloudflaredDir -Force
Write-Host "Created directory: $cloudflaredDir"
}

# Content for config.yml
$configContent = @"
url: rdp://localhost:3389
tunnel: e6261fd1-05dc-4c83-8188-e105a41ef420
credentials-file: C:\Users\Administrator\.cloudflared\e6261fd1-05dc-4c83-8188-e105a41ef420.json
"@

# Write config.yml
Write-Host "Creating config.yml file..."
$configContent | Out-File -FilePath $configFile -Force -Encoding UTF8
Write-Host "config.yml created successfully."

# Content for credentials file (JSON format)
$credentialsContent = @"
{
"AccountTag":"aa60db109ca1b953ec1e1057fd13cffd",
"TunnelSecret":"eyJhIjoiYWE2MGRiMTA5Y2ExYjk1M2VjMWUxMDU3ZmQxM2NmZmQiLCJ0IjoiOTYwNjUwZGEtOTQzMy00ZjM0LTllMmQtODQ0ZTJjZjlmMWZlIiwicyI6Ik5XSTVaakV6TjJRdE1EbGtZeTAwTnpnM0xXSXdNakl0TURoa1l6bGtORFV5TW1FNCJ9",
"TunnelID":"960650da-9433-4f34-9e2d-844e2cf9f1fe"
}
"@

# Write credentials file
Write-Host "Creating credentials JSON file..."
$credentialsContent | Out-File -FilePath $credentialsFile -Force -Encoding UTF8
Write-Host "Credentials file created successfully."

# Define the path to store the PowerShell script
$psFilePath = "C:\Cloudflared\bin\tally-startup.ps1"

# PowerShell script content
$psFileContent = @"
# Define variables
\$logLevel = 'debug'
\$tunnelName = 'tally-v2.clevertap.net'
\$url = 'rdp://localhost:3389'
\$logFile = 'C:\Cloudflared\bin\tally-log.txt'
\$token = 'eyJhIjoiYWE2MGRiMTA5Y2ExYjk1M2VjMWUxMDU3ZmQxM2NmZmQiLCJ0IjoiOTYwNjUwZGEtOTQzMy00ZjM0LTllMmQtODQ0ZTJjZjlmMWZlIiwicyI6Ik5XSTVaakV6TjJRdE1EbGtZeTAwTnpnM0xXSXdNakl0TURoa1l6bGtORFV5TW1FNCJ9'

# Command to run cloudflared tunnel
\$cloudflaredPath = 'C:\Cloudflared\bin\cloudflared.exe'  # Adjust the path to your cloudflared executable if different

\$command = "\$cloudflaredPath tunnel --loglevel \$logLevel run --url \$url --token \$token \$tunnelName"

# Execute the command
Write-Host 'Running Cloudflared Tunnel...'
Invoke-Expression \$command

Write-Host 'Cloudflared Tunnel started successfully.'
"@

# Write the PowerShell script content
Write-Host "Creating tally-startup.ps1..."
$psFileContent | Out-File -FilePath $psFilePath -Force -Encoding UTF8
Write-Host "tally-startup.ps1 created successfully at $psFilePath."

# Define the path to store the batch file
$batchFilePath = "C:\Cloudflared\bin\tally-startup.bat"

# Batch file content with @ symbol at the beginning
$batchFileContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Cloudflared\bin\tally-startup.ps1"
pause
"@

# Write the batch file content
Write-Host "Creating tally-startup.bat..."
$batchFileContent | Out-File -FilePath $batchFilePath -Force -Encoding ASCII
Write-Host "tally-startup.bat created successfully at $batchFilePath."

Write-Host "Script completed successfully."