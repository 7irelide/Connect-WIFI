# Variables
$SSID = "7irelide_Server 5GHz"
$Key = "WIFI-C10TR3M02P@S-WIFI"

# - "WPA" : Wi-Fi Protected Access, première version. Plus sûr que WEP, mais moins sécurisé que WPA2 et WPA3. Utilisé rarement dans les configurations modernes.
# - "WPA2PSK" : WPA2 (Wi-Fi Protected Access II) en mode clé pré-partagée (PSK). Actuellement le standard pour les réseaux domestiques et d'entreprises, combinant une bonne sécurité et une facilité de configuration.
# - "WPA3SAE" : WPA3 (Wi-Fi Protected Access III) avec Simultaneous Authentication of Equals (SAE). Le mode le plus récent pour les réseaux personnels, offrant une sécurité accrue par rapport à WPA2.
# - "WEP" : Wired Equivalent Privacy. Très ancien et non sécurisé, considéré comme obsolète. Recommandé d'éviter son utilisation.
# - "open" : Pas de cryptage (réseau ouvert). Utilisé principalement pour les réseaux publics où aucune authentification n'est requise.
# - "WPA2Enterprise" : WPA2 en mode entreprise, utilise 802.1X pour l'authentification (souvent avec un serveur RADIUS). Offrant une sécurité renforcée pour les réseaux professionnels.
# - "WPA3Enterprise" : WPA3 en mode entreprise, avec des améliorations de sécurité par rapport à WPA2Enterprise. Utilisé pour les environnements nécessitant une sécurité renforcée.
# - "WPA3Enterprise192" : WPA3 Enterprise avec cryptage de 192 bits, destiné aux environnements les plus sécurisés, conforme aux exigences de sécurité gouvernementales et militaires.

$EncryptionType = "WPA2PSK"  # Options possibles: WPA, WPA2PSK, WPA3SAE, WEP, open, WPA2Enterprise, WPA3Enterprise, WPA3Enterprise192

########################################################################################################
# Vérification si le profil Wi-Fi existe déjà
$existingProfile = netsh wlan show profiles | Select-String -Pattern $SSID

if ($existingProfile) {
    Write-Output "Le profil Wi-Fi '$SSID' existe déjà. Tentative de mise à jour des informations de sécurité..."
    # Suppression du profil existant
    $removeResult = netsh wlan delete profile name=$SSID
    if ($removeResult) {
        Write-Output "Le profil Wi-Fi existant a été supprimé."
    } else {
        Write-Output "Impossible de mettre à jour le profil existant. Il sera supprimé pour être recréé."
    }
} else {
    Write-Output "Aucun profil existant trouvé pour '$SSID'. Un nouveau profil sera créé."
}

# Contenu du fichier XML pour le profil Wi-Fi
$profileXML = @"
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <hex>376972656C6964655F536572766572203547487A</hex> <!-- Hexadécimal pour '7irelide_Server 5GHz' -->
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>$EncryptionType</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Key</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
    <MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
        <enableRandomization>false</enableRandomization>
        <randomizationSeed>1717643993</randomizationSeed>
    </MacRandomization>
</WLANProfile>
"@

# Sauvegarde du profil dans un fichier temporaire
$profilePath = "$env:TEMP\WiFiProfile.xml"
$profileXML | Out-File -FilePath $profilePath

# Ajout du profil Wi-Fi
netsh wlan add profile filename="$profilePath"

# Connexion au réseau Wi-Fi
netsh wlan connect name=$SSID

# Nettoyage du fichier XML temporaire
Remove-Item -Path $profilePath

Write-Output "Connexion au réseau Wi-Fi '$SSID' complétée."
