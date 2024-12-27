# Variables globales
$backupPath = "$env:USERPROFILE\Desktop\WifiBackup"
$ssid = "Nom_de_Mon_WIFI"
$key = "Password WIFi"
$encryptionType = "WPA2PSK"

function Show-Menu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                                                      ║" -ForegroundColor Blue
    Write-Host "║            ██     ██    ██     ███████ ██            ║" -ForegroundColor Cyan
    Write-Host "║            ██     ██    ██     ██      ██            ║" -ForegroundColor Cyan
    Write-Host "║            ██  █  ██    ██     █████   ██            ║" -ForegroundColor Cyan
    Write-Host "║            ██ ███ ██    ██     ██      ██            ║" -ForegroundColor Cyan
    Write-Host "║             ███ ███     ██     ██      ██            ║" -ForegroundColor Cyan
    Write-Host "║                                                      ║" -ForegroundColor Blue
    Write-Host "║              Gestion des profils Wi-Fi               ║" -ForegroundColor Yellow
    Write-Host "║                         FAFA                         ║" -ForegroundColor Blue
    Write-Host "╠══════════════════════════════════════════════════════╣" -ForegroundColor Blue
    Write-Host "║                                                      ║" -ForegroundColor Blue
    Write-Host "║  [1] ⇒ Sauvegarder les profils Wi-Fi                 ║" -ForegroundColor Green
    Write-Host "║  [2] ⇒ Connecter au Wi-Fi de l'entreprise            ║" -ForegroundColor Green
    Write-Host "║  [3] ⇒ Supprimer tous les profils Wi-Fi              ║" -ForegroundColor Green
    Write-Host "║  [4] ⇒ Restaurer les anciens profils                 ║" -ForegroundColor Green
    Write-Host "║  [Q] ⇒ Quitter                                       ║" -ForegroundColor Green
    Write-Host "║                                                      ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Blue
}

function Show-ProgressBar {
    param (
        [int]$PercentComplete
    )
    $width = 50
    $complete = [math]::Floor($width * ($PercentComplete / 100))
    $remaining = $width - $complete
    $progressBar = "[" + "■" * $complete + "□" * $remaining + "]"
    Write-Host "`r$progressBar $PercentComplete%" -NoNewline
}

function Backup-WifiProfiles {
    if (!(Test-Path $backupPath)) {
        New-Item -ItemType Directory -Path $backupPath | Out-Null
    }
    
    $profiles = netsh wlan show profiles | Select-String "\:(.+)$"
    $totalProfiles = $profiles.Count
    $currentProfile = 0

    foreach ($profile in $profiles) {
        $name = $profile.Matches.Groups[1].Value.Trim()
        $xmlPath = "$backupPath\$name.xml"
        netsh wlan export profile name="$name" folder="$backupPath" key=clear | Out-Null
        $currentProfile++
        $percentComplete = [math]::Floor(($currentProfile / $totalProfiles) * 100)
        Show-ProgressBar -PercentComplete $percentComplete
    }
    Write-Host "`n`nSauvegarde terminée !" -ForegroundColor Green
}

function Connect-EnterpriseWifi {
    $profileXML = @"
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <hex>376972656C6964655F536572766572203547487A</hex>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>$encryptionType</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$key</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
    <MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
        <enableRandomization>false</enableRandomization>
        <randomizationSeed>1717643993</randomizationSeed>
    </MacRandomization>
</WLANProfile>
"@
    $profilePath = "$env:TEMP\EnterpriseWiFiProfile.xml"
    $profileXML | Out-File -FilePath $profilePath
    
    Write-Host "Ajout du profil Wi-Fi..." -NoNewline
    netsh wlan add profile filename="$profilePath" | Out-Null
    Write-Host " OK" -ForegroundColor Green

    Write-Host "Connexion au réseau..." -NoNewline
    netsh wlan connect name=$ssid | Out-Null
    Write-Host " OK" -ForegroundColor Green

    Remove-Item -Path $profilePath
    Write-Host "`nConnexion au réseau Wi-Fi '$ssid' effectuée avec succès !" -ForegroundColor Green
}

function Remove-AllWifiProfiles {
    $profiles = netsh wlan show profiles | Select-String "\:(.+)$"
    $totalProfiles = $profiles.Count
    $currentProfile = 0

    foreach ($profile in $profiles) {
        $name = $profile.Matches.Groups[1].Value.Trim()
        netsh wlan delete profile name="$name" | Out-Null
        $currentProfile++
        $percentComplete = [math]::Floor(($currentProfile / $totalProfiles) * 100)
        Show-ProgressBar -PercentComplete $percentComplete
    }
    Write-Host "`n`nTous les profils Wi-Fi ont été supprimés !" -ForegroundColor Yellow
}

function Restore-WifiProfiles {
    if (!(Test-Path $backupPath)) {
        Write-Host "Aucune sauvegarde trouvée." -ForegroundColor Red
        return
    }
    $profiles = Get-ChildItem -Path $backupPath -Filter *.xml
    $totalProfiles = $profiles.Count
    $currentProfile = 0

    foreach ($profile in $profiles) {
        netsh wlan add profile filename="$($profile.FullName)" | Out-Null
        $currentProfile++
        $percentComplete = [math]::Floor(($currentProfile / $totalProfiles) * 100)
        Show-ProgressBar -PercentComplete $percentComplete
    }
    Write-Host "`n`nRestauration des profils Wi-Fi terminée !" -ForegroundColor Green
}

# Boucle principale du menu
do {
    Show-Menu
    $input = Read-Host "Entrez votre choix"
    switch ($input) {
        '1' {
            Backup-WifiProfiles
            pause
        }
        '2' {
            Connect-EnterpriseWifi
            pause
        }
        '3' {
            Remove-AllWifiProfiles
            pause
        }
        '4' {
            Restore-WifiProfiles
            pause
        }
        'q' {
            Clear-Host
            Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Blue
            Write-Host "║                                                      ║" -ForegroundColor Blue
            Write-Host "║   Merci d'avoir utilisé le gestionnaire de Wi-Fi !   ║" -ForegroundColor Yellow
            Write-Host "║                                                      ║" -ForegroundColor Blue
            Write-Host "║                   À bientôt !                        ║" -ForegroundColor Yellow
            Write-Host "║                                                      ║" -ForegroundColor Blue
            Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Blue
            return
        }
        default {
            Write-Host "Option non valide. Veuillez réessayer." -ForegroundColor Red
            pause
        }
    }
} while ($true)