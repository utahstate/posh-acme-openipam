# posh-acme-openipam
OpenIPAM plugin for Posh-ACME for Let's Encrypt certificates

As an administrator do the following steps.

Install the Posh-ACME powershell module:
```
Install-Module -Name Posh-ACME -Scope AllUsers
```
Copy the OpenIPAM.ps1 file into the Posh-ACME plugins folder:
```
Invoke-Webrequest -Uri https://raw.githubusercontent.com/utahstate/posh-acme-openipam/main/OpenIPAM.ps1 -OutFile C:\Program Files\WindowsPowerShell\Modules\Posh-ACME\4.30.1\Plugins\OpenIPAM.ps1
```
Setup your OpenIPAM API key:
```
$pArgs = @{
    OpenIPAMToken = (Read-Host 'OpenIPAM API Token' -AsSecureString)
}
```
Set the domain name for the certificate:
```
$certNames = 'example.usu.edu'
```
Or for multiple domain names on the certificate:
```
$certNames = 'example1.usu.edu', 'example2.usu.edu'
```
Or for a wildcard certificate:
```
$certNames = '*.example.usu.edu', 'example.usu.edu'
```
Request the certificate:
```
New-PACertificate $certNames -AcceptTOS -Plugin OpenIPAM -PluginArgs $pArgs
```

# Scheduled Task
The Posh-ACME module does not have a scheduled task for renewal so you will have to set something in task scheduler.  Create a powershell script and schedule it to run.  This would be a good example:
Posh-ACME-Renew.ps1
```
Set-PAOrder example.usu.edu
if ($cert = Submit-Renewal) {
    # do stuff with $cert to deploy it
}
```
