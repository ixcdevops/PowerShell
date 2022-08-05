function prompt {
    $ctx=(Get-Content $env:USERPROFILE\.Azure\AzureRmContext.json -Raw|ConvertFrom-Json).DefaultContextKey -split " - ";
    $subscription=(($ctx[0]).split('(')[0]).Trim();
    $account=($ctx[2]).split('@')[0];
    $tenant=($ctx[2]).split('@')[1]

    $title="$tenant";

    #Assign Windows Title Text
    $host.ui.RawUI.WindowTitle = $title;

    #Configure current user, current folder and date outputs
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $Date = Get-Date -Format 'dddd hh:mm:ss tt'

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    #Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
    $LastCommand = Get-History -Count 1
    if ($lastCommand) { $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds }

    if ($RunTime -ge 60) {
        $ts = [timespan]::fromseconds($RunTime)
        $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
        $ElapsedTime = -join ($min, " min ", $sec, " sec")
    }
    else {
        $ElapsedTime = [math]::Round(($RunTime), 2)
        $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
    }

    #Format the prompt:
    Write-Host ""
    Write-host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " 🐟AZUSER:$account " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-host " Subscription: $Subscription " -backgroundcolor DarkCyan -ForegroundColor Yellow -NoNewline;
    Write-host " $elapsedTime(s) " -backgroundcolor DarkGreen -ForegroundColor Yellow -NoNewline;
    Write-Host " $date `n" -ForegroundColor White
    return "$pwd> "
}

function select-subscription ($choice) {
    $spacer='   ';
    $i=1;
	$subscriptions = Get-AzSubscription;

    If ($null -eq $choice) {
    Write-Host '======== Available Subscriptions ============' -ForegroundColor Yellow;
    ForEach ($Sub in $subscriptions) {
        $j=$spacer + $i;
        $k=$j.Substring($j.length -2,2)

        Write-host "[ $k ]`t" -ForegroundColor Green -nonewline;
        Write-host "$($sub.Name)" -ForegroundColor Cyan;
        $i++
    }
    Write-Host '=============================================' -ForegroundColor Yellow;
    Write-Host 'Note: this changes both Powershell and AZ CLI Contexts' -ForegroundColor DarkGreen;
    Write-host "`nEnter subscription number to change to: " -ForegroundColor Green -NoNewline;
    [int] $choice=(Read-Host) -1;
    } else {$choice=$choice-1;}
    If ($choice -eq -1) {Return "Context change skipped;"}
    Else {
        Set-AzContext -SubscriptionId $subscriptions[$Choice].Id;
        az Account set --subscription $subscriptions[$choice].Name
        New-Variable -Name subID -Value $subscriptions[$Choice].Id -Scope Global -Force;
        New-Variable -Name tenantID -Value $subscriptions[$Choice].TenantId -Scope Global -Force;
    }
    }

new-alias -Name cs -Value 'select-subscription';

function select-tenant ($choice) {
    $spacer='   ';
    $i=1;
	$contexts= Get-AzContext -ListAvailable;

    If ($null -eq $choice) {
    Write-Host '======== Available Contexts ===================================================' -ForegroundColor Yellow;
    ForEach ($ctx in $contexts) {
        $j=$spacer + $i;
        $k=$j.Substring($j.length -2,2)

        Write-host "[ $k ]`t" -ForegroundColor Green -nonewline;
        Write-host "$($ctx.Account)`t$($ctx.Subscription.Name)" -ForegroundColor Cyan;
        $i++
    }
    Write-Host '===============================================================================' -ForegroundColor Yellow;
    Write-host "`nEnter Context number to change to: " -ForegroundColor Green -NoNewline;
    [int] $choice=(Read-Host) -1;
    } else {$choice=$choice-1;}
    If ($choice -eq -1) {Return "Context change skipped;"}
    Else {
        Set-AzContext -context $contexts[$Choice]|Out-null;
        New-Variable -Name tenantID -Value $contexts[$Choice].Tenant.Id -Scope Global -Force;
        select-subscription;
    }
    }

    new-alias -Name ct -Value 'select-tenant';
