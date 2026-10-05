<#
.SYNOPSIS
    Suppression des utilisateurs depuis un CSV vers l'Active Directory.
.DESCRIPTION
    Désactive le compte, le déplace dans "Desactives", archive les données 
    et gère les logs.
.NOTES
    Auteur: Louis MEDO
#>

# ==========================================
# VARIABLES
# ==========================================
Param(
    [string]$csvPath = ".\AnciensUtilisateursEcocert.csv",
    [string]$archiveShare = "\\ADECOCERT\AnciensCollaborateurs",
    [string]$logDir = "A:\Logs\Scripts\SupUtilisateurs",
    [string]$logFile = "$logDir\DesactivationComptes-$(Get-Date -Format 'yyyy-MM-dd-HH-mm').log",
    [string]$ouDesactives = "OU=Desactives,OU=Ecocert,DC=local,DC=ecocert4,DC=fr"
)

# ==========================================
# PRÉREQUIS & FONCTION DE LOG
# ==========================================
Import-Module ActiveDirectory

# Création du dossier de logs s'il n'existe pas
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Function Write-Log {
    Param([string]$Message)
    $LogLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $LogLine
    Add-Content -Path $logFile -Value $LogLine
}

# ==========================================
# EXECUTION
# ==========================================
Write-Log "--- DEBUT DU TRAITEMENT ---"
$users = Import-Csv -Path $csvPath -Delimiter ","

foreach ($user in $users) {
    $sam = "$($user.prenom).$($user.nom)".ToLower()

    try {
        $adUser = Get-ADUser -Identity $sam -Properties HomeDirectory, Description, MemberOf -ErrorAction Stop
        
        # Retirer des groupes (Exclusion du groupe principal pour éviter une erreur fatale)
        $adUser.MemberOf | Where-Object { $_ -notmatch "CN=Utilisateurs du domaine" } | Remove-ADGroupMember -Members $sam -Confirm:$false
        
        # Désactivation et mise à jour de la description
        $dateStr = Get-Date -Format "dd/MM/yyyy"
        Set-ADUser -Identity $sam -Description "Desactive le $dateStr - $($adUser.Description)"
        Disable-ADAccount -Identity $sam
        
        # Déplacement du compte AD
        Move-ADObject -Identity $adUser.ObjectGUID -TargetPath $ouDesactives
        
        # Archivage des données personnelles
        $homeDir = $adUser.HomeDirectory
        if ($homeDir -and (Test-Path $homeDir)) {
            $destDir = Join-Path -Path $archiveShare -ChildPath $sam
            Move-Item -Path $homeDir -Destination $destDir -Force
            
            # Sécurisation du dossier archivé
            icacls $destDir /inheritance:r /grant "Administrateurs:(OI)(CI)F" /T /Q | Out-Null
        }

        Write-Log "SUCCÈS : $sam desactive, retire des groupes, deplace et donnees archivees."
    }
    catch {
        Write-Log "ERREUR : Impossible de traiter $sam. Detail : $_"
    }
}
Write-Log "--- FIN DU TRAITEMENT ---"