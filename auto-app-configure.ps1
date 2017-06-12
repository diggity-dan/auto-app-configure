<#

.SYNOPSIS
Add breif description of the commandlet.


.DESCRIPTION
Add a more detailed description.


.PARAMETER ParameterName
Description of the parameter


.INPUTS
This script does not support pipeline inputs.


.OUTPUTS
This function returns exceptions to the calling script.


.NOTES
Author: Dan Anderson


.EXAMPLE
Add usage examples.

#>


[CmdletBinding()]

Param (

[Parameter(Mandatory=$False)]
[string]$ConfigFile = $null,

[Parameter(Mandatory=$False)]
[string]$ModuleDir = $null,

[Parameter(Mandatory=$False)]
[string]$AppSettingsDir = $null,

[Parameter(Mandatory=$False)]
[string]$WebAppRoot = $null,

[Parameter(Mandatory=$False)]
[string]$ServiceRoot = $null

)


#################################################
# Get relative path for execution/loading modules:
#################################################

#For running in the ISE - $MyInvocation works only from command line:
If($psISE.CurrentFile.FullPath.Length -gt 0){
    $ThisScriptPath = (Split-Path -Parent -Path $psISE.CurrentFile.FullPath)
}
Else {
    $ThisScriptPath = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)
}

#If params are null, load defaults using relative paths.
If(-not $ConfigFile){
    $ConfigFile = $ThisScriptPath + "\script-config\test.config"
}

If(-not $ModuleDir) {
    $ModuleDir = $ThisScriptPath + "\modules"
}

If(-not $AppSettingsDir){
    $AppSettingsDir = $ThisScriptPath + "\app-settings"
}

If(-not $WebAppRoot){
    $WebAppRoot = "C:\inetpub\wwwroot"
}

If(-not $ServiceRoot){
    $ServiceRoot = "D:\Exascale"
}

#Log important values:
Write-Output "`r`n$("-" * 50)`r`n"
Write-Output "Running auto-app-configure with settings:`r`n"
Write-Output "Modules Directory: $($ModuleDir)"
Write-Output "Script Config: $($ConfigFile)"
Write-Output "Settings Directory: $($AppSettingsDir)"
Write-Output "Web Application Root: $($WebAppRoot)"
Write-Output "Service Root: $($ServiceRoot)"
Write-Output "`r`n"

#################################################
# Import all modules:
#################################################

#Check for modules and count the collection:
$ModuleList = (Get-ChildItem -Path $ModuleDir -Filter "*.psm1" -Recurse -Force)
$ModuleCount = ($ModuleList | Measure-Object).Count

#Load all modules if any exist:
If($ModuleCount -ge 1) {

  ForEach($Module in $ModuleList) {
      Try{

        Write-Output "Loading Module: $($Module.FullName)"
        Import-Module -Name $Module.FullName -DisableNameChecking -Force

      }
      Catch{

        Write-Error $($_.Exception)

      }
  } #ForEach($Module in $ModuleList)

  Write-Output "Modules finished loading."
  Write-Output "`r`n$("-" * 50)`r`n"
}

###################################################
#Read script config:
###################################################

Try {

    #Create file object, and read in temp copy:
    $ConfigObject = (Get-Item -Path $ConfigFile -Force)
    $ScriptTempFile = [IO.File]::ReadAllText($ConfigObject)

    #Replace convenience tokens:

    #CurrentDate:
    $ScriptTempFile = $ScriptTempFile.Replace("{{DATE}}", $(Get-Date -Format "dd-MMM-yyyy"))

    #Current Script Location:
    $ScriptTempFile = $ScriptTempFile.Replace("{{MYLOCATION}}", $($ThisScriptPath))

    #App Settings Root:
    $ScriptTempFile = $ScriptTempFile.Replace("{{APPSETTINGS}}", $($AppSettingsDir))

    #Web Application Root:
    $ScriptTempFile = $ScriptTempFile.Replace("{{WEBAPPROOT}}", $($WebAppRoot))

    #Service Root:
    $ScriptTempFile = $ScriptTempFile.Replace("{{SERVICEROOT}}", $($ServiceRoot))


    #Set configuration:
    [XML]$ScriptConfiguration = $ScriptTempFile

}
Catch {

    Write-Error $($_.Exception)
    Exit

}


#################################################
# Loop the configuration:
#################################################


ForEach($app in $ScriptConfiguration.root.app) {

    Write-Output "Starting configuration:"
    Write-Output "Type: $($app.type)"
    Write-Output "Region: $($app.region)"
    Write-Output "Environment: $($app.environment)"
    Write-Output "`r`n$("-" * 50)`r`n"

    #loop handlers:
    ForEach($item in $app.handler) {

        Try{

            #Ensure the settings file exists:
            If( $item.settingsfile -eq "" -or (-not (Test-Path -Path $item.settingsfile)) ){

                Continue
            }
            Else{
                #Read in the settings file:
                $SettingsObject = Import-Csv -Path $item.settingsfile
            }

            #Ensure the active file exists:
            If($item.activefile -eq "" -or (-not (Test-Path -Path $item.activefile)) ){

                Continue
            }

            #Get tokenizer settings:

            #Tag
            If( $($item.runtime.tag).Length -gt 1){
                $Tag = $item.runtime.tag
            }
            Else{
                $Tag = ""
            }

            #AllowBlankTag:
            If($item.runtime.allowblanktag -eq "true"){
                $AllowBlankTag = $True
            }
            Else{
                $AllowBlankTag = $False
            }

            #TokenOnly:
            If($item.runtime.tokenonly -eq "true"){
                $TokenOnlyMode = $True
            }
            Else{
                $TokenOnlyMode = $False
            }

            #TestMode:
            If($item.runtime.testmode -eq "true"){
                $UseTestMode = $True
            }
            Else{
                $UseTestMode = $False
            }

            #Write tokenizer settings:
            Write-Output "Tokenizer settings:"
            Write-Output "Active File Input: $($item.activefile)"
            Write-Output "Settings File: $($item.settingsfile)"
            Write-Output "Tag: $($item.runtime.tag)"
            Write-Output "Allow Blank Tags: $($item.runtime.allowblanktag)"
            Write-Output "Token Only Mode: $($item.runtime.tokenonly)"
            Write-Output "Test Mode: $($item.runtime.testmode)"
            Write-Output "`r`n"

            #Determine which tokenizer to use:
            switch ($item.runtime.tokenizer)
            {
                "Tokenize-XML" {

                    Write-Output "Running Tokenize-XML..."
                    $TokenizedFile = Tokenize-XML -BaseFile $($item.activefile) -SettingsObject $SettingsObject -Tag $Tag -AllowBlankTag $AllowBlankTag -TokenOnly $TokenOnlyMode -TestMode $UseTestMode

                    #Log replacement complete:
                    Write-Output "Done."
                    Write-Output "`r`n"
                }
                Default {
                    $TokenizedFile = $($item.activefile)
                    Write-Output "WARNING: Could not match Tokenizer function: $($item.tokenizer)"
                    Write-Output "WARNING: Setting active file to untokenized version"
                    Write-Output "`r`n"
                }

            } #Switch Values

            #Write the file back out to the original location:
            Write-Output "Saving file to: $($TokenizedFile)"
            Write-Output "`r`n$("-" * 50)`r`n"

            #Reset the objects:
            $TokenizedFile = $null
            $SettingsObject = $null
            $ActiveTempFile = $null

        } #Try
        Catch {
            Write-Error ($_.Exception)
            Continue
        }

    } # ForEach($item in $app.handler)

} # ForEach($app in $ScriptConfiguration.root.app)
