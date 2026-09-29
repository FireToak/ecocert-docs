<#
.SYNOPSIS
    Suppression des utilisateurs depuis un CSV vers l'Active Directory.
.DESCRIPTION
    Script qui désactive le compte en le déplacant dans l'OU "Desactives" 
    à la racine de l'OU "Ecocert", en archivant ces données dans le dossier 
    "AnciensCollaborateurs" dans le volume Utilisateurs et qui écrit les logs de toutes les actions dans "C:\vars\log\scripts\SupUtilisateurs"
.NOTES
    Auteur: Louis MEDO
#>

# ==========================================
# VARIABLES
# ==========================================
$csvPath = ".\AnciensUtilisateursEcocert.csv"
$archiveShare = "\\ADECOCERT\AnciensCollaborateurs"
$logFile = "C:\vars\log\scripts\SupUtilisateurs\DesactivationComptes-$(Get-Date -Format 'yyyy-MM-dd-hh-mm').log"
$ouDesactives = "OU=Desactives,OU=Ecocert,DC=local,DC=ecocert4,DC=fr"

# ==========================================
# FONCTION DE LOG
# ==========================================
Function Write-Log {
    Param([string]$Message)$LogLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]$Message"
    Write-Host $LogLine
    Add-Content -Path $logFile -Value $LogLine
}

# ==========================================
# EXECUTION
# ==========================================
Write-Log "--- DEBUT DU TRAITEMENT ---"
$users = Import-Csv -Path $csvPath -Delimiter ","

foreach ($user in $users) {
    # Concatenation du prenom et du nom pour avoir l'identifiant du compte
    $sam = "$($user.prenom).$($user.nom)".ToLower()

    try {
        # Recuperation des informations de l'utilisateur
        $adUser = Get-ADUser -Identity $sam -Properties HomeDirectory, Description, MemberOf -ErrorAction Stop
        
        # Retirer des groupes de securite
        $adUser.MemberOf | Remove-ADGroupMember -Members $sam -Confirm:$false
        
        # Desactivation du compte
        $dateStr = Get-Date -Format "dd/MM/yyyy"
        $oldDesc = $adUser.Description
        Set-ADUser -Identity $sam -Description "Desactive le $dateStr - $oldDesc"
        Disable-ADAccount -Identity $sam
        
        # Deplacement du compte
        Move-ADObject -Identity $adUser.ObjectGUID -TargetPath $ouDesactives
        
        # Deplacement du dossier personnel
        $homeDir = $adUser.HomeDirectory
        if ($homeDir -and (Test-Path $homeDir)) {
            $destDir = Join-Path -Path $archiveShare -ChildPath $sam
            Move-Item -Path $homeDir -Destination $destDir -Force
            
            # Suppression de l'heritage (/inheritance:r) + controle total a l'administrateur
            icacls $destDir /inheritance:r /grant "Administrateurs:(OI)(CI)F" /T /Q | Out-Null
        }

        Write-Log "SUCCÈS : $sam desactive, retire des groupes, deplace et donnees archivees."
    }
    catch {
        Write-Log "ERREUR : Impossible de traiter $sam. Detail : $_"
    }
}
Write-Log "--- FIN DU TRAITEMENT ---"