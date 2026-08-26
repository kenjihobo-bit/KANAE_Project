# sleep-guard.ps1
#
# team-review(GPT/Geminiとの議論)の実行中、PCがスリープしてAPI通信が
# 中断されるのを防ぐためのスクリプト。Windows専用(PowerShell + powercfgに依存)。
# 使わなくても仕組み自体は動くが、長い議論の途中でスリープに入り通信が切れる
# 事故を防ぎたい場合に使う。
#
# 使い方:
#   開始時: powershell -File scripts/sleep-guard.ps1 -Action start
#   終了時: powershell -File scripts/sleep-guard.ps1 -Action stop
#
# 仕組み:
#   start時に、現在のスリープまでの時間(AC/DC電源それぞれ、秒単位)を
#   .sleep-state.json に記録してから、スリープを無効化(0=しない)にする。
#   stop時に、記録した元の値を読み込んで復元し、記録ファイルを削除する。

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop")]
    [string]$Action
)

$stateFile = Join-Path (Split-Path $PSScriptRoot -Parent) ".sleep-state.json"

function Get-StandbyIndex {
    param([string]$PowerType) # "ac" or "dc"
    $output = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE
    if ($PowerType -eq "ac") {
        $line = $output | Select-String "現在の AC 電源設定のインデックス|Current AC Power Setting Index"
    } else {
        $line = $output | Select-String "現在の DC 電源設定のインデックス|Current DC Power Setting Index"
    }
    if ($line -match "0x([0-9a-fA-F]+)") {
        return [Convert]::ToInt32($matches[1], 16)
    }
    return $null
}

if ($Action -eq "start") {
    if (Test-Path $stateFile) {
        Write-Output "警告: 前回のsleep-state.jsonが残っています(前回stopし忘れの可能性)。先にそちらを復元します。"
        & $PSCommandPath -Action stop
    }

    $acSeconds = Get-StandbyIndex -PowerType "ac"
    $dcSeconds = Get-StandbyIndex -PowerType "dc"

    @{ ac = $acSeconds; dc = $dcSeconds; savedAt = (Get-Date).ToString("o") } |
        ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8

    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0 | Out-Null
    powercfg /setactive SCHEME_CURRENT | Out-Null

    Write-Output "スリープを無効化しました(元の設定: AC=${acSeconds}秒 / DC=${dcSeconds}秒 を記録済み)"
}
elseif ($Action -eq "stop") {
    if (-not (Test-Path $stateFile)) {
        Write-Output "sleep-state.jsonが見つかりません。何もせず終了します(すでに復元済みの可能性)。"
        exit 0
    }

    $state = Get-Content $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json

    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE $state.ac | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE $state.dc | Out-Null
    powercfg /setactive SCHEME_CURRENT | Out-Null

    Remove-Item $stateFile -Force

    Write-Output "スリープ設定を元に戻しました(AC=$($state.ac)秒 / DC=$($state.dc)秒)"
}
