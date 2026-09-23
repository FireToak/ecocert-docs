# ATTENTION, si le script est lancé depuis un éditeur powershell (powershell ISE)
# il faut que l'éditeur ait été lancé en tant qu'administrateur
################################################################

###################
# ATTENTION : 1. Changez le mode de sécurité de PowerShell afin d'autoriser l'exécution de scripts locaux
# Set-ExecutionPolicy RemoteSigned  (en ligne de commandes)
###################

###################
# ATTENTION : la variable $fichier doit être modifiee
# en tenant compte du repertoire ou vous stockez le fichier utilisateursEcocert.csv
###################
$fichier=Import-Csv -Delimiter ";" C:\PWS\utilisateursEcocert.csv


###################
# ATTENTION : la variable $domaine doit être modifiee
# en tenant compte de votre nom de domaine (changer X par votre numero de votre groupe (1 à 6)!)
###################
$domaine="ecocert"
$domainecomplet=$domaine+".lan"
$path="DC=$domaine,DC=lan"
write-host $path


#Import des utilisateurs
foreach ($ligne in $fichier) {
    Write-Host "LIGNE:"
    Write-Host $ligne
    $ligne.nom = $ligne.nom.toUpper()
	
	# login = prenom.nom en minuscule
	$n=$ligne.nom.toLower()
	$p=$ligne.prenom.toLower()
	$login=$p+"."+$n
	Write-Host "Utilisateur : $login"   

	$email=$domaine
	
	try {
		$user=Get-ADUser -LDAPFilter "(sAMAccountName=$($ligne.login))" 
		Write-Host "Utilisateur $($ligne.login) déjà existant"
	}
	catch {
        write-host $ligne.nom
        Write-Host $ligne.prenom
		New-ADUser -Name "$($ligne.nom) $($ligne.prenom)" -SamAccountName "$($ligne.login)" -GivenName "$($ligne.prenom)" -Surname "$($ligne.nom)" -DisplayName "$($ligne.prenom) $($ligne.nom)" -EmailAddress $email -UserPrincipalName "$login@$domainecomplet" -ChangePasswordAtLogon $true -AccountPassword(ConvertTo-SecureString "etudiant_007" -AsPlainText -Force) -Enabled $true
        Write-Host "Utilisateur $($ligne.login) créé"
	}
    
}