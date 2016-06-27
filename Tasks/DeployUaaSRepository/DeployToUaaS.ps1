[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
    [String] [Parameter(Mandatory = $true)]
    $cloneurl,

    [String] [Parameter(Mandatory = $true)]
    $uaasuser,

    [String] [Parameter(Mandatory = $true)]
    $password,
	
    [String] [Parameter(Mandatory = $true)]
    $sourcepath,
	
	[String] [Parameter(Mandatory = $true)]
    $destinationpath
)

$invokeGit = {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Reason,
		
        [Parameter(Mandatory=$true)]
        [string[]]$ArgumentsList
    )
    try
    {
        $gitPath="C:\Program Files\Git\cmd\git.exe"
        $gitErrorPath=Join-Path $env:TEMP "stderr.txt"
        $gitOutputPath=Join-Path $env:TEMP "stdout.txt"
        if($gitPath.Count -gt 1)
        {
            $gitPath=$gitPath[0]
        }

        Write-Verbose "[Git][$Reason] Begin"
        Write-Verbose "[Git][$Reason] gitPath=$gitPath"
        Write-Host "git $arguments"
        $process=Start-Process $gitPath -ArgumentList $ArgumentsList -NoNewWindow -PassThru -Wait -RedirectStandardError $gitErrorPath -RedirectStandardOutput $gitOutputPath
        $outputText=(Get-Content $gitOutputPath)
        $outputText | ForEach-Object {Write-Host $_}

        Write-Verbose "[Git][$Reason] process.ExitCode=$($process.ExitCode)"
        if($process.ExitCode -ne 0)
        {
            Write-Warning "[Git][$Reason] process.ExitCode=$($process.ExitCode)"
            $errorText=$(Get-Content $gitErrorPath)
            $errorText | ForEach-Object {Write-Host $_}

            if($errorText -ne $null)
            {
                exit $process.ExitCode
            }
        }
        return $outputText
    }
    catch
    {
        Write-Error "[Git][$Reason] Exception $_"
    }
    finally
    {
        Write-Verbose "[Git][$Reason] Done"
    }
}

Write-Verbose "Entering script DeployToUaaS.ps1"

#Encode the credentials
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
$UsernameEncoded = [System.Web.HttpUtility]::UrlEncode($uaasuser)
$PasswordEncoded = [System.Web.HttpUtility]::UrlEncode($password)

#Construct the UaaS git url with credentials
$currentRemoteUri = New-Object System.Uri $cloneurl
$newRemoteUrlBuilder = New-Object System.UriBuilder($currentRemoteUri)
$newRemoteUrlBuilder.UserName = $UsernameEncoded 
$newRemoteUrlBuilder.Password = $PasswordEncoded

#Ensure the path that the UaaS repository will be cloned to
New-Item -ItemType Directory -Force -Path $destinationpath

#Clone the UaaS repository
Write-Host "Cloning UaaS repository..."
Invoke-Command -ScriptBlock $invokeGit -ArgumentList "Clone", @( "clone", $newRemoteUrlBuilder.ToString(), $destinationpath )

#Copy the buildout to the UaaS repository excluding the umbraco and umbraco_client folders
Write-Host "Copying Build output to the UaaS repository..."
Get-ChildItem -Path $sourcepath | % { Copy-Item $_.fullname "$destinationpath" -Recurse -Force -Exclude @("umbraco", "umbraco_client") }

#Change location to the Path where the UaaS repository is cloned
Set-Location -Path $destinationpath

#Silence warnings about LF/CRLF
Write-Host "Silence warnings about LF/CRLF"
git config core.safecrlf false

#Commit the build output to the UaaS repository
Write-Host "Current status of the UaaS repository"
git status
git add -A
git -c user.name="Umbraco as a Service" -c user.email="support@umbraco.io" commit -m "Committing build output from VSTS" --author="Umbraco as a Service <support@umbraco.io>"

#Push the added files to UaaS
Write-Host "Deploying to UaaS..."
Invoke-Command -ScriptBlock $invokeGit -ArgumentList "Push", @( "push", "origin", "master" )

#Remove credentials from the configured remote
git remote set-url "origin" $cloneurl

Write-Host "Deployment finished"

Write-Verbose "Leaving script DeployToUaaS.ps1"
