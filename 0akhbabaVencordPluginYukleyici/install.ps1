#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

function Write-Step ([string]$msg) { Write-Host "`n  >> $msg" -ForegroundColor Cyan }
function Write-OK   ([string]$msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Info ([string]$msg) { Write-Host "       $msg" -ForegroundColor Gray }
function Write-Warn ([string]$msg) { Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Fail ([string]$msg) { Write-Host "  [X]  $msg" -ForegroundColor Red }

function Abort ([string]$msg) {
    Write-Fail $msg
    Write-Host "`nKurulum iptal edildi. Cikmak icin Enter..."
    $null = Read-Host
    exit 1
}

function Update-SessionPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath    = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $extra = @(
        (Join-Path $env:APPDATA      'pnpm'),
        (Join-Path $env:LOCALAPPDATA 'pnpm'),
        (Join-Path $env:ProgramFiles 'nodejs'),
        (Join-Path $env:ProgramFiles 'Git\cmd')
    )
    $env:PATH = ($machinePath, $userPath, ($extra -join ';')) -join ';'
}

function Find-Command ([string]$name) {
    Update-SessionPath
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Ensure-Git {
    Write-Step "Git kontrolu"
    if (Find-Command 'git') { Write-OK "Git mevcut: $(git --version)"; return }
    Write-Warn "Git bulunamadi -- indiriliyor..."
    if (Find-Command 'winget') {
        winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    } else {
        $tmp = Join-Path $env:TEMP 'GitInstaller.exe'
        Invoke-WebRequest 'https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe' -OutFile $tmp
        Start-Process $tmp -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-' -Wait
    }
    Update-SessionPath
    if (-not (Find-Command 'git')) { Abort "Git kuruldu ama bulunamadi. Yeni terminal ac ve tekrar calistir." }
    Write-OK "Git kuruldu: $(git --version)"
}

function Ensure-Node {
    Write-Step "Node.js kontrolu"
    if (Find-Command 'node') {
        $ver   = node --version
        $major = [int]([regex]::Match($ver, 'v(\d+)').Groups[1].Value)
        if ($major -ge 22) { Write-OK "Node.js mevcut: $ver"; return }
        Write-Warn "Node.js $ver mevcut ama Vencord Node 22+ istiyor. Guncelleniyor..."
    } else {
        Write-Warn "Node.js bulunamadi -- Node.js 22 LTS indiriliyor..."
    }
    if (Find-Command 'winget') {
        winget install --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
    } else {
        $index = Invoke-RestMethod 'https://nodejs.org/dist/index.json'
        $entry = $index | Where-Object { $_.version -match '^v22\.' } | Select-Object -First 1
        if (-not $entry) { Abort "nodejs.org index icerisinde Node 22 LTS bulunamadi." }
        $msi = "https://nodejs.org/dist/$($entry.version)/node-$($entry.version)-x64.msi"
        $tmp = Join-Path $env:TEMP 'NodeInstaller.msi'
        Invoke-WebRequest $msi -OutFile $tmp
        Start-Process 'msiexec.exe' -ArgumentList "/i `"$tmp`" /qn /norestart" -Wait
    }
    Update-SessionPath
    if (-not (Find-Command 'node')) { Abort "Node.js kuruldu ama bulunamadi. Yeni terminal ac ve tekrar calistir." }
    Write-OK "Node.js kuruldu: $(node --version)"
}

function Ensure-Pnpm {
    Write-Step "pnpm kontrolu"
    if (Find-Command 'pnpm') { Write-OK "pnpm mevcut: $(pnpm --version)"; return }
    Write-Warn "pnpm bulunamadi -- kuruluyor..."
    Invoke-WebRequest https://get.pnpm.io/install.ps1 -UseBasicParsing | Invoke-Expression
    Update-SessionPath
    if (-not (Find-Command 'pnpm')) { Abort "pnpm kuruldu ama bulunamadi. Yeni terminal ac ve tekrar calistir." }
    Write-OK "pnpm kuruldu: $(pnpm --version)"
}

function Find-DiscordExe {
    $bases = @(
        (Join-Path $env:LOCALAPPDATA 'Discord'),
        (Join-Path $env:LOCALAPPDATA 'DiscordCanary'),
        (Join-Path $env:LOCALAPPDATA 'DiscordPTB'),
        (Join-Path $env:LOCALAPPDATA 'DiscordDevelopment')
    )
    foreach ($base in $bases) {
        if (-not (Test-Path $base)) { continue }
        $appDirs = Get-ChildItem $base -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
                   Sort-Object Name -Descending
        foreach ($d in $appDirs) {
            $exe = Join-Path $d.FullName 'Discord.exe'
            if (Test-Path $exe) { return $exe }
        }
    }
    return $null
}

function Run-Cmd ([string]$dir, [string]$exe, [string[]]$argList) {
    $escaped = $argList | ForEach-Object {
        if ($_ -match '\s') { "`"$_`"" } else { $_ }
    }
    $cmdLine = "$exe $($escaped -join ' ')"
    Write-Info "Calistiriliyor: $cmdLine"
    $psi                  = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName         = 'cmd.exe'
    $psi.Arguments        = "/c `"$cmdLine`""
    $psi.WorkingDirectory = $dir
    $psi.UseShellExecute  = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) { throw "'$cmdLine' cikis kodu: $($proc.ExitCode)" }
}

function Select-Plugins ([string]$scriptDir) {
    $available = @(
        [pscustomobject]@{ Key="1"; Name="OzelArkaPlan"; File="ozelArkaPlan\index.ts";  Src=(Join-Path $scriptDir 'plugin\ozelArkaPlan\index.ts')  },
        [pscustomobject]@{ Key="2"; Name="SilentEdit";   File="silentEdit\index.tsx";   Src=(Join-Path $scriptDir 'plugin\silentEdit\index.tsx')   }
    )

    Write-Host ""
    Write-Host "  Hangi plugin(ler)i kurmak istiyorsun?" -ForegroundColor White
    Write-Host "  (Birden fazla secmek icin numaralari boslukla ayir, hepsi icin 'hepsi')" -ForegroundColor Gray
    foreach ($p in $available) {
        Write-Host "    [$($p.Key)] $($p.Name)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  Secim: " -NoNewline -ForegroundColor White
    $raw = (Read-Host).Trim().ToLower()

    if ($raw -eq 'hepsi' -or $raw -eq '') { return $available }

    $keys = @($raw -split '\s+')

    # @() ile wrap: tek eslesme bile array olarak kalir
    $selected = @($available | Where-Object { $keys -contains $_.Key })

    if ($selected.Count -eq 0) { Abort "Gecersiz secim. Lutfen listeden numara gir." }
    return $selected
}

Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   0akh baba plugin yükleyici"                    -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

$defaultDir = Join-Path $env:USERPROFILE 'Vencord'
Write-Host "  Kurulum dizini (bos birak = $defaultDir): " -NoNewline -ForegroundColor White
$inputDir = Read-Host
$workDir  = if ($inputDir.Trim()) { $inputDir.Trim() } else { $defaultDir }
$repoDir  = Join-Path $workDir 'Vencord'

Write-Info "Hedef: $repoDir"

$scriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$selectedPlugins = @(Select-Plugins $scriptDir)

Write-Host ""
Write-Host "  Kurulacak plugin(ler):" -ForegroundColor White
foreach ($p in $selectedPlugins) { Write-Host "    - $($p.Name)" -ForegroundColor Yellow }

foreach ($p in $selectedPlugins) {
    if (-not (Test-Path $p.Src)) {
        Abort "Kaynak bulunamadi: $($p.Src)`nDosya yapisi:`n  plugin\ozelArkaPlan\index.ts`n  plugin\silentEdit\index.tsx"
    }
}

Ensure-Git
Ensure-Node
Ensure-Pnpm

Write-Step "Vencord kaynak kodu"
$null = New-Item -ItemType Directory -Force -Path $workDir
if (Test-Path (Join-Path $repoDir '.git')) {
    Write-Info "Mevcut Vencord bulundu -- git pull..."
    Run-Cmd $repoDir 'git' @('pull', '--ff-only')
    Write-OK "Vencord guncellendi."
} else {
    Write-Info "Vencord klonlaniyor (shallow)..."
    Run-Cmd $workDir 'git' @('clone', '--depth=1', 'https://github.com/Vendicated/Vencord.git', $repoDir)
    Write-OK "Vencord klonlandi."
}

Write-Step "pnpm install"
Run-Cmd $repoDir 'pnpm' @('install', '--frozen-lockfile')
Write-OK "Bagimliliklar kuruldu."

Write-Step "Plugin kurulumu"
foreach ($p in $selectedPlugins) {
    $dest    = Join-Path $repoDir "src\userplugins\$($p.File)"
    $destDir = Split-Path -Parent $dest
    $null    = New-Item -ItemType Directory -Force -Path $destDir
    Copy-Item $p.Src $dest -Force
    Write-OK "$($p.Name) yerlestirildi."
}

Write-Step "pnpm build"
Run-Cmd $repoDir 'pnpm' @('build')
Write-OK "Vencord derlendi."

Write-Step "Discord inject"
$discordExe = Find-DiscordExe
if ($discordExe) {
    Write-Info "Discord bulundu: $discordExe"
    Run-Cmd $repoDir 'pnpm' @('inject', $discordExe)
    Write-OK "Inject tamamlandi."
} else {
    Write-Warn "Discord bulunamadi. Inject icin:"
    Write-Info "  cd `"$repoDir`""
    Write-Info "  pnpm inject"
}

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "   Kurulum tamamlandi!"                         -ForegroundColor Green
Write-Host "   Discord'u tamamen kapatip yeniden ac."       -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Cikmak icin Enter..." -ForegroundColor Gray
$null = Read-Host