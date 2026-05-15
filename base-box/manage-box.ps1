# Get configuration from JSON
$configPath = "../automation_config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    $boxName = $config.boxName
} else {
    Write-Error "Configuration file not found: $configPath"
    exit 1
}

$boxFile = "custom_base.box"

# Dynamically detect architecture
$rawArch = $env:PROCESSOR_ARCHITECTURE.ToLower()
if ($rawArch -eq "amd64") {
    $arch = "amd64"
} else {
    $arch = $rawArch
}

# --- Functions ---

function New-Box {
    Write-Host "Creating box $boxName ($arch) for Virtualbox..."
    
    if (Test-Path $boxFile) { 
        Remove-Item $boxFile -Force 
    }

    $env:ENABLE_SYNC = "false"
    $env:AUTO_UPDATE = "false"
    
    vagrant up --provision-with packages
    vagrant reload
    vagrant reload --provision-with vbguest
    
    $env:ENABLE_SYNC = "true"
    $env:AUTO_UPDATE = "true"
    
    vagrant reload
    vagrant halt
    vagrant package --output $boxFile
    vagrant destroy --force
}

function Add-Box {
    Write-Host "Adding box $boxName ($arch) for Virtualbox..."
    
    vagrant box add $boxName $boxFile `
        --provider virtualbox `
        --architecture $arch `
        --force
        
    if (Test-Path $boxFile) { 
        Remove-Item $boxFile -Force 
    }
}

function Remove-Box {
    vagrant box remove $boxName --provider virtualbox
}

# --- Command Routing ---

$target = $args[0]

switch ($target) {
    "box"        { New-Box }
    "add-box"    { Add-Box }
    "remove-box" { Remove-Box }
    Default {
        Write-Host "Usage: .\Makefile.ps1 [box | add-box | remove-box]"
    }
}