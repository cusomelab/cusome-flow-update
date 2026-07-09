# CUSOME FLOW 자동업데이트 복구 — CUSOME_FLOW_복구.bat이 repo에서 내려받아 실행.
# 하는 일: ①_update.ps1 복구 ②런처에 업데이트 호출 없으면 추가 ③지금 바로 최신 버전 적용
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$app = Join-Path $env:LOCALAPPDATA "Programs\CUSOME FLOW"
if (-not (Test-Path $app)) {
    Write-Host "CUSOME FLOW 설치 폴더를 못 찾았어요: $app" -ForegroundColor Red
    Write-Host "(설치 위치가 다르면 판매자에게 문의해 주세요)"
    return
}

# 1) _update.ps1 복구 (자동업데이트 스크립트)
$ups = Join-Path $app "_update.ps1"
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/cusomelab/cusome-flow-update/main/_update.ps1" -OutFile $ups
Write-Host " 1) 자동업데이트 파일 복구 완료" -ForegroundColor Green

# 2) 런처(CUSOME_FLOW_시작.bat)에 업데이트 호출이 없으면 추가
$bat = Join-Path $app "CUSOME_FLOW_시작.bat"
if (Test-Path $bat) {
    $t = [IO.File]::ReadAllText($bat)
    if ($t -notmatch "_update\.ps1") {
        $ins = "echo  Checking for updates...`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0_update.ps1`"`r`n"
        $t = $t -replace [regex]::Escape('start "" http://localhost:5005'), ($ins + 'start "" http://localhost:5005')
        [IO.File]::WriteAllText($bat, $t, [Text.UTF8Encoding]::new($false))
        Write-Host " 2) 시작 프로그램에 업데이트 확인 단계 추가" -ForegroundColor Green
    } else {
        Write-Host " 2) 시작 프로그램은 이미 정상" -ForegroundColor Green
    }
}

# 3) 지금 바로 최신 버전 적용
Write-Host " 3) 최신 버전 확인/적용 중..." -ForegroundColor Cyan
powershell -NoProfile -ExecutionPolicy Bypass -File $ups
$v = ""
try { $v = (Get-Content (Join-Path $app "version.txt") -Raw).Trim() } catch {}
Write-Host ""
Write-Host "복구 완료! 현재 버전: $v" -ForegroundColor Green
Write-Host "이제 CUSOME_FLOW_시작.bat 으로 실행하면 항상 최신 버전이 자동 적용돼요."
