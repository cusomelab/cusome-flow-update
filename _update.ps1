# CUSOME FLOW 자동 업데이트 — CUSOME_FLOW_시작.bat이 호출.
# 원격 version.txt 비교 → 새 버전이면 payload.zip 받아 '코드만' 앱 폴더에 덮어씀.
# (python 런타임 / flow_session / 결과물 / user_settings 는 payload에 없어 안 건드림. version.txt는 여기서 직접 기록)
$app = Split-Path -Parent $MyInvocation.MyCommand.Path
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# 개발 폴더(.git 있음)는 자동 업데이트 안 함 — 내 수정 보호
if (Test-Path (Join-Path $app ".git")) { return }

$owner = "cusomelab"; $repo = "cusome-flow-update"
$verUrl = "https://raw.githubusercontent.com/$owner/$repo/main/version.txt"
$localFile = Join-Path $app "version.txt"

$local = ""
if (Test-Path $localFile) { try { $local = (Get-Content $localFile -Raw).Trim() } catch {} }

$remote = ""
try {
    $resp = Invoke-WebRequest -Uri $verUrl -UseBasicParsing -TimeoutSec 10
    $remote = ("" + $resp.Content)
    $remote = ($remote -split "`n")[0].Trim()
} catch { return }   # 오프라인/실패 → 조용히 기존 버전으로 실행
if (-not $remote) { return }
if ($remote -le $local) { return }   # 이미 최신(문자열 비교: yyyyMMdd_HHmm = 시간순)

Write-Host " >> New update found: $remote  (downloading...)" -ForegroundColor Cyan
$zip = Join-Path $env:TEMP ("cf_payload_" + $remote + ".zip")
$ext = Join-Path $env:TEMP ("cf_upd_" + $remote)
try {
    if (Test-Path $ext) { Remove-Item $ext -Recurse -Force -ErrorAction SilentlyContinue }
    $dlUrl = "https://github.com/$owner/$repo/releases/download/$remote/payload.zip"
    Invoke-WebRequest -Uri $dlUrl -OutFile $zip -UseBasicParsing -TimeoutSec 180
    Expand-Archive -Path $zip -DestinationPath $ext -Force
    # 코드만 덮어씀 — version.txt 제외(아래서 직접 기록). python/세션/결과물은 payload에 없어 안 건드려지고, 삭제도 안 함.
    robocopy $ext $app /E /XF version.txt /NFL /NDL /NJH /NJS /NC /NS /R:1 /W:1 | Out-Null
    Set-Content -Path $localFile -Value $remote -Encoding ascii -NoNewline
    Write-Host " >> Updated to $remote" -ForegroundColor Green
} catch {
    Write-Host "  (update skipped - running current version)" -ForegroundColor DarkGray
} finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $ext -Recurse -Force -ErrorAction SilentlyContinue
}
