# ================================================================
# CREATION D'UTILISATEURS ACTIVE DIRECTORY DEPUIS UN CSV
# ================================================================

# ----------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------

# Fichier CSV
$fichierCSV = ".\utilisateursEcocert.csv"

# Domaine
$domaine = "local.ecocert4.fr"

# Base du domaine
$path = "DC=local,DC=ecocert4,DC=fr"

# OU de destination
# IMPORTANT : adapte cette valeur à ton environnement.
#
# Exemple :
# $ou = "OU=Etudiants,DC=local,DC=ecocert4,DC=fr"
#
# Si tu veux utiliser le conteneur Users par défaut :
$ou = "CN=Users,$path"

# Mot de passe initial
$motDePasse = "etudiant_007"


# ----------------------------------------------------------------
# DEBUT
# ----------------------------------------------------------------

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "       CREATION DES UTILISATEURS ACTIVE DIRECTORY" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Fichier CSV : $fichierCSV"
Write-Host "Domaine     : $domaine"
Write-Host "OU          : $ou"
Write-Host ""


# ----------------------------------------------------------------
# VERIFICATION DU MODULE ACTIVE DIRECTORY
# ----------------------------------------------------------------

Write-Host "Vérification du module Active Directory..." -ForegroundColor Yellow

try {

    Import-Module ActiveDirectory -ErrorAction Stop

    Write-Host "Module Active Directory OK." -ForegroundColor Green

}
catch {

    Write-Host "ERREUR : impossible de charger le module Active Directory." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}


# ----------------------------------------------------------------
# VERIFICATION DU DOMAINE
# ----------------------------------------------------------------

Write-Host ""
Write-Host "Vérification du domaine..." -ForegroundColor Yellow

try {

    $domaineAD = Get-ADDomain -Identity $domaine -ErrorAction Stop

    Write-Host "Domaine trouvé : $($domaineAD.DNSRoot)" -ForegroundColor Green
    Write-Host "Contrôleur de domaine : $($domaineAD.PDCEmulator)" -ForegroundColor Green

}
catch {

    Write-Host "ERREUR : impossible de contacter le domaine $domaine." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}


# ----------------------------------------------------------------
# VERIFICATION DE L'OU
# ----------------------------------------------------------------

Write-Host ""
Write-Host "Vérification de l'OU..." -ForegroundColor Yellow

try {

    $ouExiste = Get-ADObject -Identity $ou -ErrorAction Stop

    Write-Host "OU/Conteneur trouvé : $ou" -ForegroundColor Green

}
catch {

    Write-Host "ERREUR : l'OU/Conteneur n'existe pas :" -ForegroundColor Red
    Write-Host $ou -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}


# ----------------------------------------------------------------
# IMPORT DU CSV
# ----------------------------------------------------------------

Write-Host ""
Write-Host "Import du fichier CSV..." -ForegroundColor Yellow

if (-not (Test-Path $fichierCSV)) {

    Write-Host "ERREUR : fichier CSV introuvable :" -ForegroundColor Red
    Write-Host $fichierCSV -ForegroundColor Red
    exit
}

try {

    $fichier = Import-Csv -Path $fichierCSV -Delimiter ";" -ErrorAction Stop

}
catch {

    Write-Host "ERREUR lors de la lecture du CSV." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}


# ----------------------------------------------------------------
# VERIFICATION DU CSV
# ----------------------------------------------------------------

if ($null -eq $fichier -or $fichier.Count -eq 0) {

    Write-Host "ERREUR : le fichier CSV est vide." -ForegroundColor Red
    exit
}

# Vérification des colonnes
$colonnes = $fichier[0].PSObject.Properties.Name

if ($colonnes -notcontains "nom") {

    Write-Host "ERREUR : la colonne 'nom' est absente du CSV." -ForegroundColor Red
    Write-Host "Colonnes trouvées : $($colonnes -join ', ')" -ForegroundColor Yellow
    exit
}

if ($colonnes -notcontains "prenom") {

    Write-Host "ERREUR : la colonne 'prenom' est absente du CSV." -ForegroundColor Red
    Write-Host "Colonnes trouvées : $($colonnes -join ', ')" -ForegroundColor Yellow
    exit
}

Write-Host "CSV valide : $($fichier.Count) utilisateur(s) trouvé(s)." -ForegroundColor Green


# ----------------------------------------------------------------
# PREPARATION DU MOT DE PASSE
# ----------------------------------------------------------------

$securePassword = ConvertTo-SecureString `
    $motDePasse `
    -AsPlainText `
    -Force


# ----------------------------------------------------------------
# COMPTEURS
# ----------------------------------------------------------------

$nombreTotal = $fichier.Count
$nombreCrees = 0
$nombreExistants = 0
$nombreErreurs = 0


# ----------------------------------------------------------------
# TRAITEMENT DES UTILISATEURS
# ----------------------------------------------------------------

foreach ($ligne in $fichier) {

    Write-Host ""
    Write-Host "------------------------------------------------------" -ForegroundColor DarkGray

    # ------------------------------------------------------------
    # RECUPERATION NOM / PRENOM
    # ------------------------------------------------------------

    $nom = $ligne.nom.ToString().Trim()
    $prenom = $ligne.prenom.ToString().Trim()

    # Vérification des valeurs
    if ([string]::IsNullOrWhiteSpace($nom)) {

        Write-Host "ERREUR : nom vide." -ForegroundColor Red
        $nombreErreurs++
        continue
    }

    if ([string]::IsNullOrWhiteSpace($prenom)) {

        Write-Host "ERREUR : prénom vide pour la ligne." -ForegroundColor Red
        $nombreErreurs++
        continue
    }


    # ------------------------------------------------------------
    # NORMALISATION
    # ------------------------------------------------------------

    $nom = $nom.ToUpper()
    $prenom = $prenom.Substring(0,1).ToUpper() + $prenom.Substring(1).ToLower()


    # ------------------------------------------------------------
    # CREATION DU LOGIN
    # Format : prenom.nom
    # ------------------------------------------------------------

    $p = $prenom.ToLower()
    $n = $nom.ToLower()

    $login = "$p.$n"


    # ------------------------------------------------------------
    # EMAIL
    # ------------------------------------------------------------

    $email = "$login@$domaine"


    Write-Host "Nom       : $nom"
    Write-Host "Prénom     : $prenom"
    Write-Host "Login      : $login"
    Write-Host "Email      : $email"


    # ------------------------------------------------------------
    # VERIFICATION DU LOGIN
    # ------------------------------------------------------------

    Write-Host "Vérification de l'existence du compte..." -ForegroundColor Yellow

    try {

        $userExistant = Get-ADUser `
            -Identity $login `
            -ErrorAction SilentlyContinue

    }
    catch {

        $userExistant = $null
    }


    # ------------------------------------------------------------
    # SI LE COMPTE EXISTE
    # ------------------------------------------------------------

    if ($null -ne $userExistant) {

        Write-Host "COMPTE DEJA EXISTANT : $login" -ForegroundColor Yellow

        $nombreExistants++

        continue
    }


    # ------------------------------------------------------------
    # CREATION
    # ------------------------------------------------------------

    Write-Host "Création du compte $login..." -ForegroundColor Cyan

    try {

        New-ADUser `
            -Name "$prenom $nom" `
            -SamAccountName $login `
            -UserPrincipalName "$login@$domaine" `
            -GivenName $prenom `
            -Surname $nom `
            -DisplayName "$prenom $nom" `
            -EmailAddress $email `
            -Path $ou `
            -AccountPassword $securePassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true `
            -ErrorAction Stop


        # --------------------------------------------------------
        # VERIFICATION APRES CREATION
        # --------------------------------------------------------

        Write-Host "Vérification de la création..." -ForegroundColor Yellow

        $verification = Get-ADUser `
            -Identity $login `
            -ErrorAction SilentlyContinue


        if ($null -ne $verification) {

            Write-Host "SUCCES : utilisateur $login créé et vérifié." -ForegroundColor Green

            $nombreCrees++

        }
        else {

            Write-Host "ERREUR : New-ADUser n'a pas généré le compte $login." -ForegroundColor Red

            $nombreErreurs++
        }

    }
    catch {

        Write-Host ""
        Write-Host "ERREUR lors de la création de $login" -ForegroundColor Red
        Write-Host "Message : $($_.Exception.Message)" -ForegroundColor Red

        $nombreErreurs++
    }
}


# ----------------------------------------------------------------
# BILAN
# ----------------------------------------------------------------

Write-Host ""
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "                     BILAN" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

Write-Host "Nombre total       : $nombreTotal"
Write-Host "Utilisateurs créés : $nombreCrees" -ForegroundColor Green
Write-Host "Déjà existants     : $nombreExistants" -ForegroundColor Yellow
Write-Host "Erreurs            : $nombreErreurs" -ForegroundColor Red

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

if ($nombreErreurs -eq 0) {

    Write-Host "TRAITEMENT TERMINE SANS ERREUR." -ForegroundColor Green

}
else {

    Write-Host "TRAITEMENT TERMINE AVEC DES ERREURS." -ForegroundColor Red
}

Write-Host ""
