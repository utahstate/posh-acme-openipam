function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Token')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Token',Mandatory)]
        [securestring]$OpenIPAMToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $RecordTTL='300'

    $apiRoot = 'https://openipam.usu.edu/api'
    $authHeader = Get-OpenIPAMAuthHeader @PSBoundParameters


    # check for an existing record
    Write-Debug "Checking for existing record"
    try {
        $getParams = @{
            Uri = "$apiRoot/dns/?name=$RecordName"
            Headers = $authHeader
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($getParams.Uri)"
        $response = Invoke-RestMethod @getParams @script:UseBasic
    } catch { throw }

    # add the new TXT record if necessary
    if ($response.result.Count -eq 0) {

        $bodyJson = @{ dns_type="TXT"; name=$RecordName; content=$TxtValue; ttl=$RecordTTL } | ConvertTo-Json
        Write-Verbose "Adding $RecordName with value $TxtValue"
        try {
            $postParams = @{
                Uri = "$apiRoot/dns/add/"
                Method = 'Post'
                Body = $bodyJson
                ContentType = 'application/json'
                Headers = $authHeader
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "POST $($postParams.Uri)"
            Write-Debug "Body`n$($postParams.Body)"
            Invoke-RestMethod @postParams @script:UseBasic | Out-Null
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to OpenIPAM.

    .DESCRIPTION
        Use OpenIPAM V4 api to add a TXT record to a OpenIPAM DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER OpenIPAMToken
        The scoped API Token that has been given read/write permissions to the necessary zones.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'API Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -OpenIPAMToken $token

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Token')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Token',Mandatory)]
        [securestring]$OpenIPAMToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = 'https://openipam.usu.edu/api'
    $authHeader = Get-OpenIPAMAuthHeader @PSBoundParameters


    # check for an existing record
    Write-Debug "Checking for existing record"
    try {
        $getParams = @{
            Uri = "$apiRoot/dns/?name=$RecordName"
            Headers = $authHeader
            Verbose = $false
            ErrorAction = 'Stop'
        }
        Write-Debug "GET $($getParams.Uri)"
        $response = Invoke-RestMethod @getParams @script:UseBasic
    } catch { throw }

    # remove the txt record if it exists
    if ($response.result.Count -gt 0) {

        $recID = $response.result[0].id
        Write-Verbose "Removing $RecordName with value $TxtValue"
        try {
            $delParams = @{
                Uri = "$apiRoot/dns/$recID/delete/"
                Method = 'Delete'
                Headers = $authHeader
                Verbose = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "DELETE $($delParams.Uri)"
            Invoke-RestMethod @delParams @script:UseBasic | Out-Null
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from OpenIPAM.

    .DESCRIPTION
        Use OpenIPAM V4 api to remove a TXT record to a OpenIPAM DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER OpenIPAMToken
        The scoped API Token that has been given read/write permissions to the necessary zones.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'API Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -OpenIPAMToken $token

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# API Docs:
# https://openipam.usu.edu/api/

function Get-OpenIPAMAuthHeader {
    [CmdletBinding(DefaultParameterSetName='Token')]
    param(
        [Parameter(ParameterSetName='Token',Mandatory)]
        [securestring]$OpenIPAMToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    if ('Token' -eq $PSCmdlet.ParameterSetName) {

        $OpenIPAMTokenInsecure = [pscredential]::new('a',$OpenIPAMToken).GetNetworkCredential().Password
        return @{ Authorization = "Token $OpenIPAMTokenInsecure" }

    } else {
        throw "Unable to determine valid auth headers."
    }
}