<#

.NOTES

    *****************************************************************************

    ETML

    Nom du script:	P_sysInfoLogger.ps1

    Auteur:	Zhuravel Mykola, Pinto Gomes Daniel

    Date:	27.01.2025

	*****************************************************************************

    Modifications

	Date  : -

	Auteur: -

	Raisons: -

	*****************************************************************************

.SYNOPSIS

	Script qui fait un diagnostic du PC

.DESCRIPTION

    Script qui donne la version de l'OS, une liste de programmes installés, les infomations sur le RAM, les infomations sur les disques, 

    les infomations sur le processeur

.PARAMETER OS

    Un parametre booléan pour alterner entre metre les informations de l'OS dans le fichier informations

.PARAMETER Disk

    Un parametre booléan pour alterner entre metre les informations des disques locaux dans le fichier informations

.PARAMETER RAM

    Un parametre booléan pour alterner entre metre les informations du RAM dans le fichier informations
 
.PARAMETER Programs

    Un parametre booléan pour alterner entre metre la liste de tout les programes dans le fichier informations
 
.PARAMETER Processor

    Un parametre booléan pour alterner entre metre les informations du processeur dans le fichier informations
 
.PARAMETER Nom

    Un parametre de type string qui peut etre change pour avoir n'importe quel nom sur le fichier
 
.OUTPUTS

	Le script produit un fichier .log dans le bureau de l'utilisateur

.EXAMPLE

	.\sysInfoLogger.ps1 -OS $true -Disk $false -Processor $false

	La ligne que l'on tape pour l'exécution du script avec un choix de paramètres

	Résultat : le fichier contiendra l'information de l'os, les infomations sur le RAM, une liste de programmes installés

    , sans les infomations sur les disques ni les infomations sur le processeur, car les deux parametres sonts $false. 

    Tout les autres parametres seronts present car ils sont $true par default

.EXAMPLE

	.\sysInfoLogger.ps1

	Résultat : toutes les informations possibles seronts mit dans le ficher .log
#>
 
# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire 

param

(

    [bool]$OS = $true,

    [bool]$Disk = $true,

    [bool]$Ram = $true,

    [bool]$Programs = $true,

    [bool]$Processor = $true,

    [string]$Nom = 'SystemInfo'

)
 
###################################################################################################################

# Zone de définition des variables et fonctions, avec exemples
 
#pour les iterations de la boucle

$loopNB = $16

$loopMoins1 = $loopNB - 1
 
#nom user et nom ordinateur

$computerName = $env:USERNAME

$computerInfo = "Nom de l'ordinateur : $env:ComputerName"
 
#le type de fichier

$fileType = '.log'
 
#chemin du fichier de la fin

$outputFilePath = "C:\Users\$computerName\Desktop\"
 
#prend le parametres dans des nouveaux variables

$outputFileName = $Nom
 
#le nom du fichier

$fullFileName = $outputFileName+$fileType
 
#fusion des deux chemin

$completePath = Join-Path -Path $outputFilePath -ChildPath $fullFileName
 
 
#pour le formater le document

$format = "========================================================================"
 
#trouve la date

$date = (Get-Date)

$titleoutput = "Collecte fait le $date"
 
###################################################################################################################

# Zone de tests comme les paramètres renseignés ou les droits administrateurs
 
# Affiche l'aide si un ou plusieurs paramètres ne sont par renseignés, "safe guard clauses" permet d'optimiser l'exécution et la lecture des scripts

if(!$OS -or !$Disk -or !$Ram -or !$Programs -or !$Processor)

{

    Get-Help $MyInvocation.Mycommand.Path

}
 
###################################################################################################################

# intitialization des functions
 
#function qui rend tout joli <3

function Format() 

{
       $format >> $completePath
       
       Add-Content -Path $completePath -Value $currentFormatText -NoNewline
       "`n" >> $completePath

    for ($i = 0; $i -lt $loopNB; $i++) {

        $format >> $completePath
        "`n" >> $completePath

    }

}
 
#version du système d'exploitation

function GetOSInfo()

{

    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem

    $osVersion = "Version du système d'exploitation : $($osInfo.Version)"

    return $osVersion

}
 
#informations disk

function GetDiskInfo()

{

    $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } #Drivetype 3 c disques locals

    $diskInfoText = foreach ($disk in $diskInfo) 

    {

        $diskName = $disk.DeviceID

        $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)

        $totalSpace = [math]::Round($disk.Size / 1GB, 2)

        $usedSpace = $totalSpace - $freeSpace

        $percentageUsed = [math]::Round(($usedSpace / $totalSpace) * 100, 2)

        "Espace disque ($diskName) : $freeSpace GB libre / $totalSpace GB total ($percentageUsed% utilisé)`n"

    }

    return $diskInfoText

}
 
#informations sur la RAM

function GetRamInfo()

{

    $ramInfo = Get-CimInstance -ClassName Win32_OperatingSystem
 
    #tout le ram

    $totalRam = [math]::Round($ramInfo.TotalVisibleMemorySize / 1MB, 2)

    #ram libre

    $availableRam = [math]::Round($ramInfo.FreePhysicalMemory / 1MB, 2)  

    #ram utilise

    $usedRam = [math]::Round($totalRam - $availableRam, 2)
 
    #pourcentage utilise

    $ramPercent = [math]::Round(($usedRam / $totalRam) * 100, 2)
 
    return $totalRam, $availableRam, $usedRam, $ramPercent

}
 
#liste des programmes installes

function GetInstalledPrograms()

{

    $installedPrograms = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  

    Select-Object DisplayName, DisplayVersion, Publisher | Format-Table –AutoSize

    return $installedPrograms

}
 
#info pour le processor

function GetProcessorInfo()

{

    #infos generale

    $processorInfo = Get-CimInstance -ClassName Win32_Processor

    $processorText = "Processeur : $($processorInfo.Name), $($processorInfo.NumberOfCores) cœurs"
 
    #pourcentage utilise

    $processorPercent = (Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage)

    $processorPercent = "Pourcentage utilisé: $processorPercent %"
 
    return $processorText, $processorPercent

}
 
###################################################################################################################

# Corps du script
 
#check si le fichier exist

if (-not (Test-Path -Path $completePath)) {

    #cree le fichier si il exist pas

    New-Item -ItemType File -Path $outputFilePath -Name $fullFileName

}
 
#Formatage simple

$format >> $completePath
 
#ligne d'introduction 1, qui donne le nom de l'ordinateur

$computerInfo >> $completePath
 
#ligne d'introdution 2, qui donne la date

$titleoutput >> $completePath
 
#trouve les informations si demandes 

if ($OS -eq $true -or $OS -eq $null)

{

    #formatage

    $currentFormatText = "Information de L'OS"

    Format
 
    $osVersion = GetOSInfo 

    $osVersion >> $completePath   

}
 
if ($Disk -eq $true -or $Disk -eq $null)

{

    #formatage

    $currentFormatText = "Informations des disques locaux"

    Format
 
    $diskInfoText = GetDiskInfo 

    $diskInfoText >> $completePath

}
 
if ($RAM -eq $true -or $RAM -eq $null)

{

    #formatage

    $currentFormatText = "Informations de la RAM"

    Format
 
    $ramPercent, $totalRam, $availableRam, $usedRam = GetRamInfo

    #les variables sonts en desordre, mais je sais pas comment les changer

    "Total RAM: $($ramPercent) GB" >> $completePath

    "Total memoire libre : $($totalRam) GB" >> $completePath

    "Total memoire utilise : $($availableRam) GB" >> $completePath

    "Pourcentage utilisé: $usedRam %" >> $completePath

}
 
if ($Processor -eq $true -or $Processor -eq $null)

{

    #formatage

    $currentFormatText = "Informations du processeur"

    Format
 
    $processorPercent, $processorText = GetProcessorInfo  

    $processorText >> $completePath

    $processorPercent >> $completePath

}
 
if ($Programs -eq $true -or $Programs -eq $null)

{

    #formatage

    $currentFormatText = "Liste de programmes installés"

    Format
 
    $installedPrograms = GetInstalledPrograms

    $installedPrograms >> $completePath

}
#fait de l'espace pour la prochaine fois
"`n`n`n`n`n" >> $completePath