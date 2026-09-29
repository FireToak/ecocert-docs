<#
.SYNOPSIS
    Synchronisation des utilisateurs depuis un CSV vers l'Active Directory.
.DESCRIPTION
    Script idempotent pour la cr�ation et la modification des utilisateurs ECOCERT.
    V�rifie la conformit� des donn�es avant traitement. IL FAUT CREER L'OU "Ecocert" en amont !
.NOTES
    Auteur: Louis MEDO
#>

Param(
    [string]$CsvPath = ".\UtilisateursEcocert.csv",
    [string]$LogPath = ".\Sync-Users-$(Get-Date -Format 'yyyy-MM-dd-hh-mm').txt",
    [string]$Domaine = "local.ecocert4.lan",
    [string]$BaseOU = "OU=Ecocert,DC=local,DC=ecocert4,DC=fr"
    [string]$DefaultPassword = "ChangezMoiSVP@37ù"
)

Write-Log "CsvPath : $CsvPath"
Write-Log "LogPath : $LogPath"
Write-Log "Domaine : $Domaine"
Write-Log "BaseOU : $BaseOU"

# -----------------------------------------------------------------------------
# 1. INITIALISATION
# -----------------------------------------------------------------------------
Import-Module ActiveDirectory

# Fonction de journalisation
Function Write-Log {
    Param([string]$Message)$LogLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]$Message"
    Write-Host $LogLine
    Add-Content -Path $LogPath -Value $LogLine
}

Write-Log "=== D�BUT DE LA SYNCHRONISATION ==="

# -----------------------------------------------------------------------------
# 2. V�RIFICATION DU FICHIER SOURCE
# -----------------------------------------------------------------------------
If (-not (Test-Path $CsvPath)) {
    Write-Log "ERREUR CRITIQUE : Le fichier $CsvPath est introuvable."
    Exit
}

$Utilisateurs = Import-Csv -Path $CsvPath -Delimiter ","
Write-Log "Utilisateurs : $Utilisateurs"

# -----------------------------------------------------------------------------
# 3. BOUCLE
# -----------------------------------------------------------------------------
ForEach ($User in $Utilisateurs) {
    Try {
        # --- Validation des donn�es ---
        $SamAccountName = "$($User.Prenom).$($User.Nom)".ToLower()
        $Email = "$($User.Prenom.Substring(0,1)).$($User.Nom)@$Domaine".ToLower()
        
        # Regex pour le format "33 x xx xx xx xx"
        If ($User.Telephone -and $User.Telephone -notmatch "^33 [1-9] \d{2} \d{2} \d{2} \d{2}$") {
            Write-Log "REJET : $($SamAccountName) - Format t�l�phone invalide : $($User.Telephone)"
            Continue # Passe au compte suivant
        }


        # D�finir le chemin de l'OU Service
        $ServiceOUPath = "OU=$($User.Service),$BaseOU"

        # V�rifier et cr�er l'OU Service si elle n'existe pas
        If (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($User.Service)'" -SearchBase $BaseOU -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
            Try {
                New-ADOrganizationalUnit -Name $User.Service -Path $BaseOU -ErrorAction Stop
                Write-Log "INFO : Cr�ation de l'UO Service : $ServiceOUPath"
            }
            Catch {
                Write-Log "ERREUR : Impossible de cr�er l'UO Service $($User.Service). $($_.Exception.Message)"
                Continue # Passe � l'utilisateur suivant
            }
        }

        # V�rifier et cr�er l'OU Utilisateurs dans le Service si elle n'existe pas
        If (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Utilisateurs'" -SearchBase $ServiceOUPath -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
            Try {
                New-ADOrganizationalUnit -Name "Utilisateurs" -Path $ServiceOUPath -ErrorAction Stop
                Write-Log "INFO : Cr�ation de l'UO Utilisateurs : $TargetOU"
            }
            Catch {
                Write-Log "ERREUR : Impossible de cr�er l'UO Utilisateurs dans $($User.Service). $($_.Exception.Message)"
                Continue
            }
        }

        # D�termination de l'OU cible
        $TargetOU = "OU=Utilisateurs,OU=$($User.Service),$BaseOU"

        # --- V�rification de l'existence dans l'AD ---
        $ADUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -Properties EmailAddress, OfficePhone, Title, Office, Department -ErrorAction SilentlyContinue

        If (-not $ADUser) {

            # V�rification et cr�ation de l'UO
            If (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($User.Service)'" -SearchBase $BaseOU -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
                Try {
                    New-ADOrganizationalUnit -Name $User.Service -Path $BaseOU -ErrorAction Stop
                    Write-Log "INFO : Cr�ation de l'UO OU=$($User.Service),$BaseOU"
                }
                Catch {
                    Write-Log "ERREUR : Impossible de cr�er l'UO pour $($User.Service). V�rifiez vos droits."
                    Continue
                }
            }
           
            # --- Cr�ation (New-ADUser) ---
            $SecurePwd = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

            # Tableau de hash pour la cr�ation de l'utilisateur
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

            Write-Log "SUCC�S : Cr�ation de $SamAccountName"
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

            # Mise � jour si diff�rences d�tect�es
            If ($PropsToUpdate.Count -gt 0) {
                Set-ADUser -Identity $SamAccountName @PropsToUpdate -ErrorAction Stop
                Write-Log "SUCC�S : Mise � jour de $SamAccountName ($($PropsToUpdate.Keys -join ', '))"
            }
            Else {
                Write-Log "INFO : $SamAccountName est d�j� � jour."
            }
        }
    }
    Catch {
        Write-Log "ERREUR : �chec sur $($User.Prenom) $($User.Nom) - $($_.Exception.Message)"
    }
}

Write-Log "=== FIN DE LA SYNCHRONISATION ==="