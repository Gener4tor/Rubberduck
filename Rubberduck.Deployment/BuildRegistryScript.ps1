﻿# The parameters should be supplied by the Build event of the project
# in order to take macros from Visual Studio to avoid hard-coding
# the paths. To simplify the process, the project should have a 
# reference to the projects that needs to be registered, so that 
# their DLL files will be present in the $(TargetDir) macro. 
#
# TODO: Figure a better way to locate the SDK tool where the TlbExp.exe
#	    is located.
#
# Possible syntax for Post Build event of the project to invoke this:
# C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe 
#  -command "$(ProjectDir)BuildRegistryScript.ps1 
#  -builderAssemblyPath '$(TargetPath)' 
#  -netToolsDir '$(FrameworkSDKDir)bin\NETFX 4.6.1 Tools\' 
#  -wixToolsDir '$(SolutionDir)packages\WiX.Toolset.3.9.1208.0\tools\wix\' 
#  -sourceDir '$(TargetDir)' 
#  -targetDir '$(TargetDir)' 
#  -includeDir '$(ProjectDir)InnoSetup\Includes\'
#  -filesToExtract 'Rubberduck.dll'"
param (
	[Parameter(Mandatory=$true)][string]$builderAssemblyPath,
	[Parameter(Mandatory=$true)][string]$netToolsDir,
	[Parameter(Mandatory=$true)][string]$wixToolsDir,
	[Parameter(Mandatory=$true)][string]$sourceDir,
	[Parameter(Mandatory=$true)][string]$targetDir,
	[Parameter(Mandatory=$true)][string]$includeDir,
	[Parameter(Mandatory=$true)][string]$filesToExtract
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop";

try
{
	# Allow multiple DLL files to be registered if necessary
	$separator = "|"
	$option = [System.StringSplitOptions]::RemoveEmptyEntries
	$files = $filesToExtract.Split($separator, $option);

	foreach($file in $files)
	{
		$sourceDll = $sourceDir + $file;
		$targetDll = $targetDir + $file;
		$sourceTlb32 = $sourceDir + ($file -replace ".dll", ".x32.tlb");
		$targetTlb32 = $targetDir + ($file -replace ".dll", ".x32.tlb");
		$sourceTlb64 = $sourceDir + ($file -replace ".dll", ".x64.tlb");
		$targetTlb64 = $targetDir + ($file -replace ".dll", ".x64.tlb");
		$dllXml = $targetDll + ".xml"
		$tlbXml = $targetTlb32 + ".xml"

		# Use for debugging issues with passing parameters to the external programs
		# Note that it is not legal to have syntax like `& $cmdIncludingArguments` or `& $cmd $args`
		# For simplicity, the arguments are pass in literally.
		# & "C:\GitHub\Rubberduck\Rubberduck\Rubberduck.Deployment\echoargs.exe" ""$sourceDll"" /win32 /out:""$sourceTlb"";
		
		$cmd = "{0}tlbexp.exe" -f $netToolsDir;
		& $cmd ""$sourceDll"" /win32 /out:""$sourceTlb32"";
		& $cmd ""$sourceDll"" /win64 /out:""$sourceTlb64"";

		$cmd = "{0}heat.exe" -f $wixToolsDir;
		& $cmd file ""$sourceDll"" -out ""$dllXml"";
		& $cmd file ""$sourceTlb32"" -out ""$tlbXml"";
			
		[System.Reflection.Assembly]::LoadFrom($builderAssemblyPath);
		$builder = New-Object Rubberduck.Deployment.Builders.RegistryEntryBuilder
	
		$entries = $builder.Parse($tlbXml, $dllXml);

		# For debugging
		# $entries | Format-Table | Out-String |% {Write-Host $_};

		$writer = New-Object Rubberduck.Deployment.Writers.InnoSetupRegistryWriter
		$content = $writer.Write($entries);
		 
		$regFile = ($includeDir + ($file -replace ".dll", ".reg.iss"))
		$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
		[System.IO.File]::WriteAllLines($regFile, $content, $Utf8NoBomEncoding)
	}
}
catch
{
	Write-Host -Foreground Red -Background Black ($_);
}

# for debugging locally
# Write-Host "Press any key to continue...";
# Read-Host -Prompt "Press Enter to continue";
