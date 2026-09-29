$ErrorActionPreference = "Stop"

$anthropicVariables = @("ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY", "ANTHROPIC_BASE_URL")
$userSettingsPath = Join-Path $HOME ".claude\settings.json"

if (Test-Path $userSettingsPath) {
	$userSettings = Get-Content -Raw $userSettingsPath | ConvertFrom-Json
	$settingsChanged = $false
	if ($userSettings.env) {
		foreach ($name in $anthropicVariables) {
			if ($null -ne $userSettings.env.PSObject.Properties[$name]) {
				$userSettings.env.PSObject.Properties.Remove($name)
				$settingsChanged = $true
			}
		}
	}
	if ($settingsChanged) {
		$userSettings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $userSettingsPath -Encoding UTF8
		Write-Host "Removed old Anthropic endpoint/auth settings from Claude user settings."
	}
}

foreach ($name in $anthropicVariables) {
	[Environment]::SetEnvironmentVariable($name, $null, "User")
	Remove-Item "Env:$name" -ErrorAction SilentlyContinue
}

$authMode = Read-Host "Auth mode: [1] Claude account sign-in (default) [2] Anthropic API key"
$useApiKey = $authMode -eq "2"
$officialApiBaseUrl = "https://api.anthropic.com"
$apiBaseUrl = $officialApiBaseUrl
$keyPointer = [IntPtr]::Zero

if ($useApiKey) {
	$apiBaseUrl = Read-Host "API base URL (Enter for $officialApiBaseUrl)"
	if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) {
		$apiBaseUrl = $officialApiBaseUrl
	}

	$secureKey = Read-Host "Enter a fresh Anthropic Console API key (input is hidden)" -AsSecureString
	$keyPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
}

try {
	if ($useApiKey) {
		$env:ANTHROPIC_BASE_URL = $apiBaseUrl.TrimEnd('/')
		$env:ANTHROPIC_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)
	}

	$exportDirectory = Join-Path $PSScriptRoot "export\in"
	New-Item -ItemType Directory -Path $exportDirectory -Force | Out-Null
	$sessionSettings = @{ env = @{ ANTHROPIC_BASE_URL = $apiBaseUrl.TrimEnd('/') } } | ConvertTo-Json -Compress

	claude --settings $sessionSettings --add-dir $exportDirectory
}
finally {
	foreach ($name in $anthropicVariables) {
		Remove-Item "Env:$name" -ErrorAction SilentlyContinue
	}
	if ($keyPointer -ne [IntPtr]::Zero) {
		[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer)
	}
}