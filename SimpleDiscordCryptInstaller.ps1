$ErrorActionPreference = 'Stop'


$startMenuPath = [Environment]::GetFolderPath('StartMenu')+'\Programs\Discord Inc\'
$desktopPath = [Environment]::GetFolderPath('Desktop')+'\'
$taskbarPath = $env:APPDATA+'\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\'
$discordPath = $env:LOCALAPPDATA+'\Discord'
$discordDataPath = $env:APPDATA+'\discord'
$discordResourcesPath = $discordPath+'\app-*'
$discordIconPath = $startMenuPath+'Discord.lnk'
$discordDesktopIconPath = $desktopPath+'Discord.lnk'
$discordTaskbarIconPath = $taskbarPath+'Discord.lnk'
$discordExeName = 'Discord.exe'
$discordPtbPath = $env:LOCALAPPDATA+'\DiscordPTB'
$discordPtbDataPath = $env:APPDATA+'\discordptb'
$discordPtbResourcesPath = $discordPtbPath+'\app-*'
$discordPtbIconPath = $startMenuPath+'Discord PTB.lnk'
$discordPtbDesktopIconPath = $desktopPath+'Discord PTB.lnk'
$discordPtbTaskbarIconPath = $taskbarPath+'Discord PTB.lnk'
$discordPtbExeName = 'DiscordPTB.exe'
$discordCanaryPath = $env:LOCALAPPDATA+'\DiscordCanary'
$discordCanaryDataPath = $env:APPDATA+'\discordcanary'
$discordCanaryResourcesPath = $discordCanaryPath+'\app-*'
$discordCanaryIconPath = $startMenuPath+'Discord Canary.lnk'
$discordCanaryDesktopIconPath = $desktopPath+'Discord Canary.lnk'
$discordCanaryTaskbarIconPath = $taskbarPath+'Discord Canary.lnk'
$discordCanaryExeName = 'DiscordCanary.exe'
$iconLocation = '\app.ico,0'
$pluginPath = $env:LOCALAPPDATA+'\SimpleDiscordCrypt'
$startupRegistry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'


$shell = New-Object -ComObject WScript.Shell
function RootElectron([string]$discordIconPath, [string]$exeName, [string]$path, [string]$resourcesPath, [string]$desktopIconPath, [string]$taskbarIconPath) {
	'rooting'
	$shortcut = $shell.CreateShortcut($discordIconPath)
	if($shortcut.WorkingDirectory -eq "") {
		$shortcut.WorkingDirectory = (Resolve-Path $resourcesPath | % { $_.Path } | Measure -Maximum).Maximum
		$shortcut.IconLocation = $path + $iconLocation
	}
	$shortcut.TargetPath = $env:WINDIR+'\System32\cmd.exe'
	$shortcut.Arguments = "/c `"set NODE_OPTIONS=-r ../../SimpleDiscordCrypt/NodeLoad.js && start ^`"^`" ^`"$path\Update.exe^`" --processStart $exeName`""
	$shortcut.WindowStyle = 7
	$shortcut.Save()

	if(Test-Path $desktopIconPath) {
		copy $discordIconPath $desktopIconPath -Force
	}
	if(Test-Path $taskbarIconPath) {
		copy $discordIconPath $taskbarIconPath -Force
	}
}

function RemoveExtension([string]$electonDataPath) {
	$extensionListPath = "$electonDataPath\DevTools Extensions"
	if(Test-Path $extensionListPath) {
		[string]$s = Get-Content $extensionListPath
		if($s.Length -ne 0) {
			$extensionList = ConvertFrom-Json $s
			$newExtensionList = @($extensionList | ? { $_ -notmatch '(?:^|[\\\/])SimpleDiscordcrypt[\\\/]?$' })
			if($newExtensionList.Length -ne $extensionList.Length) {
				'removing old extension'
				Set-Content $extensionListPath (ConvertTo-Json $newExtensionList)
			}
		}
	}
}

function ReplaceStartup([string]$registryKey, [string]$newPath) {
	if((Get-ItemProperty -Path $startupRegistry -Name $registryKey -ErrorAction SilentlyContinue).$registryKey -ne $null) {
		'replacing startup'
		Set-ItemProperty -Path $startupRegistry -Name $registryKey -Value $newPath
	}
}


$install = $false

try {

while(Test-Path $discordPath) {
	'Discord found'
	if(Test-Path $discordDataPath) { 'data directory found' } else { 'data directory not found'; break }
	if(Test-Path $discordResourcesPath) { 'resources directory found' } else { 'resources directory not found'; break }

	RemoveExtension $discordDataPath

	RootElectron $discordIconPath $discordExeName $discordPath $discordResourcesPath $discordDesktopIconPath $discordTaskbarIconPath

	ReplaceStartup 'Discord' $discordIconPath
	
	$install = $true
	break
}

while(Test-Path $discordPtbPath) {
	'DiscordPTB found'
	if(Test-Path $discordPtbDataPath) { 'data directory found' } else { 'data directory not found'; break }
	if(Test-Path $discordPtbResourcesPath) { 'resources directory found' } else { 'resources directory not found'; break }

	RemoveExtension $discordPtbDataPath

	RootElectron $discordPtbIconPath $discordPtbExeName $discordPtbPath $discordPtbResourcesPath $discordPtbDesktopIconPath $discordPtbTaskbarIconPath
	
	ReplaceStartup 'DiscordPTB' $discordPtbIconPath

	$install = $true
	break
}

while(Test-Path $discordCanaryPath) {
	'DiscordCanary found'
	if(Test-Path $discordCanaryDataPath) { 'data directory found' } else { 'data directory not found'; break }
	if(Test-Path $discordCanaryResourcesPath) { 'resources directory found' } else { 'resources directory not found'; break }

	RemoveExtension $discordCanaryDataPath

	RootElectron $discordCanaryIconPath $discordCanaryExeName $discordCanaryPath $discordCanaryResourcesPath $discordCanaryDesktopIconPath $discordCanaryTaskbarIconPath
	
	ReplaceStartup 'DiscordCanary' $discordCanaryIconPath

	$install = $true
	break
}


if($install) {
	'installing'
	
	[void](New-Item "$pluginPath\NodeLoad.js" -Type File -Force -Value @'
const onHeadersReceived = (details, callback) => { // SDCEx Hook headers to disable CSP blocking. This might be a security issue, because you can then send requests to everywhere you want?
	let response = { cancel: false };
	let responseHeaders = details.responseHeaders;
	if(responseHeaders['content-security-policy'] != null) {
		responseHeaders['content-security-policy'] = [""];
		response.responseHeaders = responseHeaders;
	}
	callback(response);
};

let originalBrowserWindow;
function browserWindowHook(options) {
	if(options?.webPreferences?.preload != null && options.title?.startsWith("Discord")) {
		let webPreferences = options.webPreferences;
		let originalPreload = webPreferences.preload;
		webPreferences.preload = `${__dirname}/SimpleDiscordCryptLoader.js`;
		webPreferences.additionalArguments = [...(webPreferences.additionalArguments || []), `--sdc-preload=${originalPreload}`];
	}
	return new originalBrowserWindow(options);
}
browserWindowHook.ISHOOK = true;


let originalElectronBinding;
function electronBindingHook(name) {
	let result = originalElectronBinding.apply(this, arguments);

	if(name === 'atom_browser_window' && !result.BrowserWindow.ISHOOK) {
		originalBrowserWindow = result.BrowserWindow;
		Object.assign(browserWindowHook, originalBrowserWindow);
		browserWindowHook.prototype = originalBrowserWindow.prototype;
		result.BrowserWindow = browserWindowHook;
		const electron = require('electron');
		electron.app.whenReady().then(() => { electron.session.defaultSession.webRequest.onHeadersReceived(onHeadersReceived) });
	}
	
	return result;
}
electronBindingHook.ISHOOK = true;

originalElectronBinding = process._linkedBinding;
if(originalElectronBinding.ISHOOK) return;
Object.assign(electronBindingHook, originalElectronBinding);
electronBindingHook.prototype = originalElectronBinding.prototype;
process._linkedBinding = electronBindingHook;
'@)

	[void](New-Item "$pluginPath\SimpleDiscordCryptLoader.js" -Type File -Force -Value @'
let requireGrab = require;
if (requireGrab != null) {
	const require = requireGrab;

	if(window.chrome?.storage) delete chrome.storage;

	const localStorage = window.localStorage;
	const CspDisarmed = true;

	// SDCEx Manual Updates. Why should you trust a service not to steal your keys?
	var tempDlHelper = window.tempDlHelper = {
		updateInfoName: "SimpleDiscordCryptExUpdateInfo",
		https: require("https"),
		latestVersion: 0,
		cachedObject: null,
		downloadAndEval: function () {
			tempDlHelper.https.get(`https://raw.githubusercontent.com/Ceiridge/SimpleDiscordCrypt-Extended/${encodeURIComponent(tempDlHelper.latestVersion)}/SimpleDiscordCrypt.user.js`, {
				headers: {
					"User-Agent": navigator.userAgent // A User-Agent is recommended
				}
			}, (response) => {
				response.setEncoding('utf8');
				let data = "";
				response.on('data', (chunk) => data += chunk);
				response.on('end', async () => {
					tempDlHelper.updateUpdateObject("savedScript", data); // Save current version of the script
					tempDlHelper.updateUpdateObject("version", tempDlHelper.latestVersion);
					tempDlHelper.finish();

					eval(data);
				});
			});
		},
		updateUpdateObject: function (key, value) {
			let dbObj = JSON.parse(localStorage.getItem(tempDlHelper.updateInfoName)); // Localstorage can only store strings
			dbObj[key] = value;
			localStorage.setItem(tempDlHelper.updateInfoName, JSON.stringify(dbObj));
		},
		getLatestVersion: function () {
			return new Promise(resolve => {
				tempDlHelper.https.get("https://api.github.com/repos/Ceiridge/SimpleDiscordCrypt-Extended/git/refs/heads/master", {
					headers: {
						"User-Agent": navigator.userAgent // Needs a User-Agent
					}
				}, response => {
					response.setEncoding("utf8");
					let data = "";
					response.on('data', (chunk) => data += chunk);
					response.on('end', () => {
						let responseJson = JSON.parse(data);
						resolve(responseJson["object"]["sha"]);
					});
				}); // Get latest commit sha
			});
		},
		finish: function () {
			delete tempDlHelper;
			delete window.tempDlHelper;
		},
		userInteract: function (apply) {
			if (apply) {
				tempDlHelper.downloadAndEval(); // Finishes for me
			} else {
				eval(tempDlHelper.cachedObject["savedScript"]);
				tempDlHelper.finish();
			}
		}
	}

	async function tmpAsyncFnc() {
		tempDlHelper.latestVersion = await tempDlHelper.getLatestVersion();

		if (localStorage.getItem(tempDlHelper.updateInfoName) === null) { // If no version exists, download, execute and set
			localStorage.setItem(tempDlHelper.updateInfoName, "{}"); // Empty json object
			tempDlHelper.downloadAndEval();
		} else {
			tempDlHelper.cachedObject = JSON.parse(localStorage.getItem(tempDlHelper.updateInfoName));
			let currentVersion = tempDlHelper.cachedObject["version"];

			if (currentVersion != tempDlHelper.latestVersion) {
				let dialogAnswer = 0;
				let electronObj = require("electron");
				let dialogObj = electronObj.remote.dialog;
				let shellObj = electronObj.shell;

				while (dialogAnswer === 0) { // Open the blocking dialog again if the first button was clicked
					dialogAnswer = dialogObj.showMessageBoxSync(null, {
						type: "question",
						buttons: ["View changes", "Apply latest update", "Execute saved version"],
						defaultId: 0,
						title: "New SimpleDiscordCrypt Extended Update",
						message: "A new SimpleDiscordCrypt Extended version has been found."
					});

					if (dialogAnswer === 0) {
						shellObj.openExternal(`https://github.com/Ceiridge/SimpleDiscordCrypt-Extended/compare/${encodeURIComponent(currentVersion)}..master`);
					}
				}

				tempDlHelper.userInteract(dialogAnswer === 1); // Apply if second button was clicked
			} else {
				tempDlHelper.userInteract(false); // Just eval the saved script and finish
			}
		}
	}
	tmpAsyncFnc();
	delete tmpAsyncFnc;


	
	const commandLineSwitches = process.electronBinding('command_line');
	let originalPreloadScript = commandLineSwitches.getSwitchValue('sdc-preload');

	if(originalPreloadScript != null) {
		commandLineSwitches.appendSwitch('preload', originalPreloadScript);
		require(originalPreloadScript);
	}
} else console.log("Uh-oh, looks like something is blocking require");
'@)

	'FINISHED'

    $needsWait = $false
    $discordProcesses = Get-Process 'Discord' -ErrorAction SilentlyContinue
    $discordProcesses | % { $needsWait = $_.CloseMainWindow() -or $needsWait }

    $discordPtbProcesses = Get-Process 'DiscordPTB' -ErrorAction SilentlyContinue
    $discordPtbProcesses | % { $needsWait = $_.CloseMainWindow() -or $needsWait }

    $discordCanaryProcesses = Get-Process 'DiscordCanary' -ErrorAction SilentlyContinue
    $discordCanaryProcesses | % { $needsWait = $_.CloseMainWindow() -or $needsWait }

    if($needsWait) { sleep 1 }

    $processes = ($discordProcesses + $discordPtbProcesses + $discordCanaryProcesses)
    if($processes.Length -ne 0) {
        $processes | Stop-Process
        if($discordProcesses.Length -ne 0) { [void](start $discordIconPath)  }
        if($discordPtbProcesses.Length -ne 0) { [void](start $discordPtbIconPath)  }
        if($discordCanaryProcesses.Length -ne 0) { [void](start $discordCanaryIconPath)  }
    }
}
else { 'Discord not found' }

}
catch { $_ }
finally { [Console]::ReadLine() }
