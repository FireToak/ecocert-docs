<#
.SYNOPSIS
    Synchronisation des utilisateurs depuis un CSV vers l'Active Directory.
.DESCRIPTION
    Script idempotent pour la creation et la modification des utilisateurs ECOCERT.
    Verifie la conformite des donnees avant traitement. IL FAUT CREER L'OU "Ecocert" en amont !
.NOTES
    Auteur: Louis MEDO
#>

Param(
    [string]$CsvPath = ".\UtilisateursEcocert.csv",
    [string]$LogPath = ".\Sync-Users-$(Get-Date -Format 'yyyy-MM-dd-hh-mm').txt",
    [string]$Domaine = "local.ecocert4.lan",
    [string]$BaseOU = "OU=Ecocert,DC=local,DC=ecocert4,DC=fr",
    [string]$DefaultPassword = "ChangezMoiSVP@37ù"
)

# Fonction de journalisation
Function Write-Log {
    Param([string]$Message)$LogLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]$Message"
    Write-Host $LogLine
    Add-Content -Path $LogPath -Value $LogLine
}

Write-Log "CsvPath : $CsvPath"
Write-Log "LogPath : $LogPath"
Write-Log "Domaine : $Domaine"
Write-Log "BaseOU : $BaseOU"

# -----------------------------------------------------------------------------
# INITIALISATION
# -----------------------------------------------------------------------------
Import-Module ActiveDirectory

Write-Log "=== DEBUT DE LA SYNCHRONISATION ==="

# -----------------------------------------------------------------------------
# VERIFICATION DU FICHIER SOURCE
# -----------------------------------------------------------------------------
If (-not (Test-Path $CsvPath)) {
    Write-Log "ERREUR CRITIQUE : Le fichier $CsvPath est introuvable."
    Exit
}

$Utilisateurs = Import-Csv -Path $CsvPath -Delimiter ","
Write-Log "Utilisateurs : $Utilisateurs"

# -----------------------------------------------------------------------------
# BOUCLE
# -----------------------------------------------------------------------------
ForEach ($User in $Utilisateurs) {
    Try {
        # --- Validation des donnees ---
        $SamAccountName = "$($User.Prenom).$($User.Nom)".ToLower()
        $Email = "$($User.Prenom.Substring(0,1)).$($User.Nom)@$Domaine".ToLower()
        
        # Regex pour le format "33 x xx xx xx xx"
        If ($User.Telephone -and $User.Telephone -notmatch "^33 [1-9] \d{2} \d{2} \d{2} \d{2}$") {
            Write-Log "REJET : $($SamAccountName) - Format telephone invalide : $($User.Telephone)"
            Continue # Passe au compte suivant
        }


        # Definir le chemin de l'OU Service
        $ServiceOUPath = "OU=$($User.Service),$BaseOU"

        # Verifier et creer l'OU Service si elle n'existe pas
        If (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($User.Service)'" -SearchBase $BaseOU -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
            Try {
                New-ADOrganizationalUnit -Name $User.Service -Path $BaseOU -ErrorAction Stop
                Write-Log "INFO : Creation de l'UO Service : $ServiceOUPath"
            }
            Catch {
                Write-Log "ERREUR : Impossible de creer l'UO Service $($User.Service). $($_.Exception.Message)"
                Continue # Passe a l'utilisateur suivant
            }
        }

        # Verifier et creer l'OU Utilisateurs dans le Service si elle n'existe pas
        If (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Utilisateurs'" -SearchBase $ServiceOUPath -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
            Try {
                New-ADOrganizationalUnit -Name "Utilisateurs" -Path $ServiceOUPath -ErrorAction Stop
                Write-Log "INFO : Creation de l'UO Utilisateurs : $TargetOU"
            }
            Catch {
                Write-Log "ERREUR : Impossible de creer l'UO Utilisateurs dans $($User.Service). $($_.Exception.Message)"
                Continue
            }
        }

        # Définir le chemin de l'OU Groupe
        $GroupesOUPath = "OU=Groupes,$ServiceOUPath"

        # Verifier et creer l'OU Groupes dans le Service si elle n'existe pas
        If (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Groupes'" -SearchBase $ServiceOUPath -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
            Try { 
                New-ADOrganizationalUnit -Name "Groupes" -Path $ServiceOUPath -ErrorAction Stop
            } 

            Catch { 
                  Continue
            }
        }

        # Définir et créer le Groupe de sécurité Global
        $GroupName = $($User.Service)

        If (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
            Try { New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope Global -Path $GroupesOUPath -ErrorAction Stop } Catch {}
        }

        # Determination de l'OU cible
        $TargetOU = "OU=Utilisateurs,OU=$($User.Service),$BaseOU"

        # --- Verification de l'existence dans l'AD ---
        $ADUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -Properties EmailAddress, OfficePhone, Title, Office, Department -ErrorAction SilentlyContinue

        If (-not $ADUser) {

            # Verification et creation de l'UO service
            If (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($User.Service)'" -SearchBase $BaseOU -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
                Try {
                    New-ADOrganizationalUnit -Name $User.Service -Path $BaseOU -ErrorAction Stop
                    Write-Log "INFO : Creation de l'UO OU=$($User.Service),$BaseOU"
                }
                Catch {
                    Write-Log "ERREUR : Impossible de creer l'UO pour $($User.Service). Verifiez vos droits."
                    Continue
                }
            }
           
            # --- Creation (New-ADUser) ---
            $SecurePwd = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

            # Tableau de hash pour la creation de l'utilisateur
            $NewUserParams = @{
                Name                 = "$($User.Prenom) $($User.Nom)"
                GivenName            = $User.Prenom
                Surname              = $User.Nom
                SamAccountName       = $SamAccountName
                UserPrincipalName    = "$SamAccountName@$Domaine"
                EmailAddress         = $Email
                Department           = $User.Service
                Office               = $User.Bureau
                Path                 = $TargetOU
                AccountPassword      = $SecurePwd
                Enabled              = $true
                ChangePasswordAtLogon = $true
                ErrorAction          = "Stop"
            }

            # Options facultatifs
            if ($User.Telephone) { $NewUserParams.OfficePhone = $User.Telephone }
            if ($User.Fonction) { $NewUserParams.Title = $User.Fonction }
            if ($User.Bureau) { $NewUserParams.Office = $User.Bureau }

            New-ADUser @NewUserParams

            Write-Log "SUCCES : Creation de $SamAccountName"
        }
        Else {
            # --- Modification (Set-ADUser) ---
            $PropsToUpdate = @{}

            # Comparaison des attributs (Idempotence)

            # Options obligatoires
            If ($ADUser.EmailAddress -ne $Email) { $PropsToUpdate.EmailAddress =$Email }
            If ($ADUser.Department -ne $User.Service) { $PropsToUpdate.Department =$User.Service }

            # Options facultatif
            if ($ADUser.OfficePhone) {if ($ADUser.OfficePhone -ne $User.Telephone) { $PropsToUpdate.OfficePhone =$User.Telephone }}
            if ($ADUser.Title) {If ($ADUser.Title -ne $User.Fonction) { $PropsToUpdate.Title =$User.Fonction }}
            if ($ADUser.Office) {If ($ADUser.Office -ne $User.Bureau) { $PropsToUpdate.Office =$User.Bureau }}

            # Mise a jour si differences detectees
            If ($PropsToUpdate.Count -gt 0) {
                Set-ADUser -Identity $SamAccountName @PropsToUpdate -ErrorAction Stop
                Write-Log "SUCCES : Mise a jour de $SamAccountName ($($PropsToUpdate.Keys -join ', '))"
            }

            Else {
                Write-Log "INFO : $SamAccountName est deja a jour."
            }
        }
        # Définition du nom du groupe
        $GroupName = $User.Service
        
        # Récupère la liste des groupes de l'utilisateur
        $UserGroupMemberships = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name
        
        # Ajoute du groupe à l'utilisateur s'il ne le possède pas
        If ($UserGroupMemberships -notcontains $GroupName) {
            Add-ADGroupMember -Identity $GroupName -Members $SamAccountName -ErrorAction Stop
            Write-Log "SUCCÈS : Ajout de $SamAccountName au groupe $GroupName"
        }
    }
    Catch {
        Write-Log "ERREUR : Echec sur $($User.Prenom) $($User.Nom) - $($_.Exception.Message)"
    }
}

Write-Log "=== FIN DE LA SYNCHRONISATION ==="