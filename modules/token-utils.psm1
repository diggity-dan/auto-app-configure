


Function Tokenize-XML {

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
    [string]$BaseFile = $null,

    [Parameter(Mandatory=$False)]
    $SettingsObject = $null,

    [Parameter(Mandatory=$False)]
    [string]$Tag = $null,

    [Parameter(Mandatory=$False)]
    [bool]$AllowBlankTag = $False,

    [Parameter(Mandatory=$False)]
    [bool]$TokenOnly = $False,

    [Parameter(Mandatory=$False)]
    [bool]$TestMode = $False

    )


    Process {


        ######################################################
        #Pre-Massage File before processing:
        ######################################################


        Try {

            #Read in file
            $TempFile = [IO.File]::ReadAllText($BaseFile)

            #Do some pre-massaging (adding items, variables, etc..)
            #Nothing to do at this time, leaving as a placeholder.

            #All done with pre-massage, set content to XML:
            [XML]$XMLFile = $TempFile

        }
        Catch {

            Write-Error $($_.Exception)
            Return
        }


        ######################################################
        # Handle Test Mode:
        ######################################################


        If($TestMode){
            $FileExtension = ".test"
        }
        Else {
            $FileExtension = ""
        }


        ######################################################
        # Loop Settings Object:
        ######################################################

        #Default the Settings Gate to false:
        $MakeChange = $False

        ForEach($row in $SettingsObject) {

            #Set gated change (only change settings if SettingsGate is true):
            If($Tag -eq "") {$MakeChange = $True}
            If($Tag -eq $row.Tag) {$MakeChange = $True}
            If( $AllowBlankTag -and ($row.Tag -eq "") ) {$MakeChange = $True}

            #Only run the replacement if the gate passed:
            If($MakeChange) {

                #Get settings from the input object:
                $SelectedNodes = $XMLFile.SelectNodes($($row.Xpath))
                $Token = $($row.Token)
                $NewValue = $($row.NewValue)

                #Replace with value/token:
                ForEach($node in $SelectedNodes){
                    If($TokenOnly) {
                        $node.SetAttribute("$($row.Attribute)", "$($Token)")
                    }
                    Else {
                        $node.SetAttribute("$($row.Attribute)", "$($NewValue)")
                    }
                } #ForEach($node in $SelectedNodes)

                #Reset gated change:
                $MakeChange = $False

            } Else {
                Continue
            } #If/Else $MakeChange

        } # ForEach($row in $SettingsObject)


        ######################################################
        # Save the file:
        ######################################################

        Try {

            $XMLFile.Save("$($BaseFile)$($FileExtension)")
            Return "$($BaseFile)$($FileExtension)"

        }
        Catch {

            Write-Error $($_.Exception)
            Return

        }

        ######################################################

    } #End Process

} #End Function


Export-Modulemember -Function Tokenize-XML
