<#
.NOTES
    Author:         Heather O'Neal
    Creation Date:  April 08, 2021
    Organization:   
    Filename:       Restart-Service.ps1
.GIT
    

.CHANGELOG
    [1.0]   04/2021  Initial script development
    
.SYNOPSIS
    Restart a service on schedule
.DESCRIPTION
    
.INPUTS
    ServerName: FQDN of server on which to change the service
    ServiceNames: Array of services to change
.OUTPUTS
    Returns the Servicename, Status and result (success| timeout) for each change
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------
$ServerName = "x"
$ServiceNames = @("x")  #Array of services to change

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Switch-ServiceState {
    param(
        [Parameter(Mandatory=$true)]
        [String[]]$ServiceNames, 
        [Parameter(Mandatory=$true)]
        [ValidateSet("Running", "Stopped")]
        [String]$DesiredState,
        [Parameter(Mandatory=$true)]
        [String]$ServerName
        )

    foreach($ServiceName in $ServiceNames){
        $ServiceStatus = (Get-Service $ServiceName -ComputerName $ServerName).Status
        if($ServiceStatus -ne $DesiredState){
            switch ($DesiredState) {
                "Running" {  
                    get-service $ServiceName -ComputerName $ServerName | Start-Service
                    break
                }
                "Stopped"{
                    get-service $ServiceName -ComputerName $ServerName | Stop-Service
                    break
                }
                Default { #Invalid DesiredState
                    Return "Invalid Desired State"
                } 
            } #END Switch
        } # END If
    }  #END ForEach 

    #Initialize return Hashmap
    $return = @()
    # Verify service state. Sleep while Service State is not equal to desired state
    foreach($ServiceName in $ServiceNames){
        $i = 0                  #counter
        $max = 60               #Break loop after 60 checks i.e. more than 5 minutes
        $Result = "Success"     #Initialize result for each service to success
        Do {
            $ServiceStatus = (Get-Service $ServiceName -ComputerName $ServerName).Status
            $i++ #Increment counter
            if($i -gt $max) {           #Check for timeout
                $Result = "TIMEOUT"
                break                   #Exit Do loop, but continue checking other services
            } 
             #If not timeout, wait 5 seconds and check again
            Start-Sleep -Seconds 5
        } while ($ServiceStatus -ne $DesiredState) 

        #Create a PSCustom Object with the service state information, result will be success or timeout.
        $ServiceInfo = [PSCustomObject]@{
            ServiceName = $ServiceName
            Status = $ServiceStatus
            Result = $Result
        } 
        #Add PSObject to return hashmap before continuing to next service.
        $return += $ServiceInfo
    } #END ForEach

    return $return
} # END function Switch-Service-State

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Stop the services
$DesiredState = "Stopped"
$return = Switch-ServiceState $ServiceNames $DesiredState $ServerName
write-host $return

#start the services
$DesiredState = "Running"
$return = Switch-ServiceState $ServiceNames $DesiredState $ServerName
write-host $return

