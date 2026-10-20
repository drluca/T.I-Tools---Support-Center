#Requires -Version 5.1

$Host.UI.RawUI.WindowTitle = "TI Tools - Menu de Suporte"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  +============================================================+" -ForegroundColor Cyan
    Write-Host "  |                TI TOOLS  -  SUPPORT CENTER                 |" -ForegroundColor Cyan
    Write-Host "  |                       Versao 1.1.0                         |" -ForegroundColor Cyan
    Write-Host "  +============================================================+" -ForegroundColor Cyan
    Write-Host "  Computador: $env:COMPUTERNAME   |   Usuario: $env:USERNAME" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Section {
    param([string]$Titulo)
    Write-Host ""
    Write-Host "  +------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |               $Titulo" -ForegroundColor Yellow                          
    Write-Host "  +------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
}

function Write-MenuItem {
    param([string]$Numero, [string]$Descricao)
    Write-Host "    [$Numero] " -ForegroundColor Green -NoNewline
    Write-Host $Descricao -ForegroundColor White
}

function Write-Ok    { param([string]$m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info  { param([string]$m) Write-Host "  [>>] $m" -ForegroundColor Cyan  }
function Write-Aviso { param([string]$m) Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Write-Erro  { param([string]$m) Write-Host "  [X]  $m" -ForegroundColor Red   }

function Pause-Menu {
    Write-Host ""
    Write-Host "  Pressione qualquer tecla para voltar ao menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Confirmar {
    param([string]$Pergunta)
    Write-Host ""
    Write-Host "  $Pergunta [S/N]: " -ForegroundColor Yellow -NoNewline
    $r = Read-Host
    return ($r -match '^[Ss]$')
}

# ---------------------------------------------------------------------------
# Elevacao de privilegios
# ---------------------------------------------------------------------------

function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-ComAdmin {
    param(
        [string]      $Descricao,
        [scriptblock] $ScriptBlock
    )

    # Ja e admin: executa diretamente
    if (Test-IsAdmin) {
        & $ScriptBlock
        return
    }

    # Nao e admin: exibe aviso
    Write-Host ""
    Write-Host "  +------------------------------------------------------------+" -ForegroundColor Red
    Write-Host "  |  PERMISSAO ELEVADA NECESSARIA                              |" -ForegroundColor Red
    Write-Host "  |                                                            |" -ForegroundColor Red
    Write-Host "  |  A operacao selecionada requer privilegios de              |" -ForegroundColor Red
    Write-Host "  |  Administrador para ser executada com sucesso:             |" -ForegroundColor Red
    Write-Host "  |                                                            |" -ForegroundColor Red
    Write-Host "  |  >> $($Descricao.PadRight(55))|" -ForegroundColor Yellow
    Write-Host "  |                                                            |" -ForegroundColor Red
    Write-Host "  +------------------------------------------------------------+" -ForegroundColor Red
    Write-Host ""

    if (-not (Confirmar "Deseja reiniciar o TI Tools como Administrador agora?")) {
        Write-Aviso "Operacao cancelada pelo usuario."
        return
    }

    # Copia o script para %TEMP% (caminho sem espacos) antes de elevar
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.ScriptName }
    $tmpCopy    = Join-Path $env:TEMP "TITools_elevated.ps1"
    Copy-Item -Path $scriptPath -Destination $tmpCopy -Force

    Write-Info "Abrindo janela de elevacao do Windows (UAC)..."
    Write-Info "Informe as credenciais de Administrador na janela que vai abrir."

    try {
        # Start-Process com -Verb RunAs dispara o UAC nativo do Windows.
        # O Windows cuida da autenticacao — funciona com contas locais e de dominio.
        Start-Process powershell.exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmpCopy`"" `
            -Verb RunAs `
            -Wait

        Write-Ok "Sessao elevada concluida."
    }
    catch {
        if ($_.Exception.Message -match 'cancelled|cancelad|negad|denied') {
            Write-Aviso "Elevacao cancelada pelo usuario."
        } else {
            Write-Erro "Falha ao elevar: $($_.Exception.Message)"
        }
    }
    finally {
        Start-Sleep -Seconds 1
        Remove-Item $tmpCopy -Force -ErrorAction SilentlyContinue
    }
}

function Menu-Limpeza {
    do {
        Write-Header
        Write-Section "1. Limpeza e Otimizacao"
        Write-MenuItem "1" "Limpar cache DNS"
        Write-MenuItem "2" "Abrir Limpeza de Disco"
        Write-MenuItem "3" "Limpar temporarios do usuario"
        Write-MenuItem "4" "Limpar temporarios do Windows"
        Write-MenuItem "5" "Esvaziar Lixeira"
        Write-MenuItem "6" "Consultar espaco livre em disco"
        Write-MenuItem "7" "Executar todas as limpezas (1, 3, 4, 5)"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" {
                Write-Header; Write-Section "Limpar Cache DNS"
                Write-Info "Executando: ipconfig /flushdns"
                ipconfig /flushdns
                Pause-Menu
            }
            "2" {
                Write-Header; Write-Section "Limpeza de Disco"
                Write-Info "Abrindo cleanmgr.exe..."
                Start-Process cleanmgr.exe
                Write-Ok "Limpeza de Disco aberta."
                Pause-Menu
            }
            "3" {
                Write-Header; Write-Section "Limpar Temporarios do Usuario"
                if (Confirmar "Remover arquivos em $env:TEMP ?") {
                    Write-Info "Removendo $env:TEMP\*..."
                    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Ok "Temporarios do usuario limpos."
                } else { Write-Aviso "Operacao cancelada." }
                Pause-Menu
            }
            "4" {
                Write-Header; Write-Section "Limpar Temporarios do Windows"
                if (Confirmar "Remover arquivos em $env:windir\Temp ?") {
                    Invoke-ComAdmin "Limpar Temporarios do Windows ($env:windir\Temp)" {
                        Write-Info "Removendo $env:windir\Temp\*..."
                        Remove-Item "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Ok "Temporarios do Windows limpos."
                    }
                } else { Write-Aviso "Operacao cancelada." }
                Pause-Menu
            }
            "5" {
                Write-Header; Write-Section "Esvaziar Lixeira"
                if (Confirmar "Esvaziar a Lixeira agora?") {
                    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                    Write-Ok "Lixeira esvaziada."
                } else { Write-Aviso "Operacao cancelada." }
                Pause-Menu
            }
            "6" {
                Write-Header; Write-Section "Espaco Livre em Disco"
                Get-PSDrive -PSProvider FileSystem |
                    Format-Table Name,
                        @{N='Usado (GB)';E={[math]::Round($_.Used/1GB,2)}},
                        @{N='Livre (GB)';E={[math]::Round($_.Free/1GB,2)}} -AutoSize
                Pause-Menu
            }
            "7" {
                Write-Header; Write-Section "Limpeza Completa"
                if (Confirmar "Executar limpeza completa (DNS + Temp usuario + Temp Windows + Lixeira)?") {
                    Write-Info "1/4 - Limpando cache DNS..."
                    ipconfig /flushdns | Out-Null
                    Write-Ok "Cache DNS limpo."
                    Write-Info "2/4 - Limpando temporarios do usuario..."
                    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Ok "Temp usuario limpo."
                    Write-Info "3/4 - Limpando temporarios do Windows (requer admin)..."
                    Invoke-ComAdmin "Limpar Temporarios do Windows ($env:windir\Temp)" {
                        Remove-Item "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Ok "Temp Windows limpo."
                    }
                    Write-Info "4/4 - Esvaziando Lixeira..."
                    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                    Write-Ok "Lixeira esvaziada."
                    Write-Host ""
                    Write-Ok "Limpeza completa finalizada!"
                } else { Write-Aviso "Operacao cancelada." }
                Pause-Menu
            }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Rede {
    do {
        Write-Header
        Write-Section "2. Rede e Conectividade"
        Write-MenuItem "1"  "Exibir configuracao de rede (ipconfig /all)"
        Write-MenuItem "2"  "Testar conectividade IP (ping 8.8.8.8)"
        Write-MenuItem "3"  "Testar conectividade com dominio (ping google.com)"
        Write-MenuItem "4"  "Consultar DNS (nslookup)"
        Write-MenuItem "5"  "Consultar DNS pelo PowerShell (Resolve-DnsName)"
        Write-MenuItem "6"  "Renovar endereco IP DHCP"
        Write-MenuItem "7"  "Liberar endereco IP DHCP"
        Write-MenuItem "8"  "Exibir rotas de rede"
        Write-MenuItem "9"  "Verificar adaptadores de rede"
        Write-MenuItem "10" "Consultar configuracao IP"
        Write-MenuItem "11" "Testar porta TCP de um servidor"
        Write-MenuItem "12" "Consultar conexoes TCP ativas"
        Write-MenuItem "13" "Testar conectividade por PowerShell"
        Write-Host ""
        Write-MenuItem "0"  "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1"  { Write-Header; Write-Section "Configuracao de Rede"
                   ipconfig /all | More; Pause-Menu }
            "2"  { Write-Header; Write-Section "Ping 8.8.8.8"
                   ping 8.8.8.8 -n 4; Pause-Menu }
            "3"  { Write-Header; Write-Section "Ping google.com"
                   ping google.com -n 4; Pause-Menu }
            "4"  { Write-Header; Write-Section "nslookup"
                   Write-Host "  Dominio [google.com]: " -NoNewline -ForegroundColor Green
                   $d = Read-Host; if (!$d) { $d = "google.com" }
                   nslookup $d; Pause-Menu }
            "5"  { Write-Header; Write-Section "Resolve-DnsName"
                   Write-Host "  Dominio [google.com]: " -NoNewline -ForegroundColor Green
                   $d = Read-Host; if (!$d) { $d = "google.com" }
                   Resolve-DnsName $d | Format-Table -AutoSize; Pause-Menu }
            "6"  { Write-Header; Write-Section "Renovar IP DHCP"
                   Write-Info "Executando ipconfig /renew..."
                   ipconfig /renew; Pause-Menu }
            "7"  { Write-Header; Write-Section "Liberar IP DHCP"
                   if (Confirmar "Liberar endereco IP DHCP? A conexao sera interrompida.") {
                       ipconfig /release
                   } else { Write-Aviso "Cancelado." }
                   Pause-Menu }
            "8"  { Write-Header; Write-Section "Rotas de Rede"
                   route print; Pause-Menu }
            "9"  { Write-Header; Write-Section "Adaptadores de Rede"
                   Get-NetAdapter | Format-Table Name, Status, LinkSpeed, MacAddress -AutoSize
                   Pause-Menu }
            "10" { Write-Header; Write-Section "Configuracao IP"
                   Get-NetIPConfiguration | Format-List; Pause-Menu }
            "11" { Write-Header; Write-Section "Testar Porta TCP"
                   Write-Host "  Servidor: " -NoNewline -ForegroundColor Green; $srv = Read-Host
                   Write-Host "  Porta:    " -NoNewline -ForegroundColor Green; $prt = Read-Host
                   if ($srv -and $prt) {
                       Test-NetConnection $srv -Port $prt | Format-List
                   } else { Write-Erro "Servidor e porta sao obrigatorios." }
                   Pause-Menu }
            "12" { Write-Header; Write-Section "Conexoes TCP Ativas"
                   Get-NetTCPConnection | Where-Object State -eq 'Established' |
                       Sort-Object RemoteAddress |
                       Format-Table LocalAddress,LocalPort,RemoteAddress,RemotePort,State -AutoSize
                   Pause-Menu }
            "13" { Write-Header; Write-Section "Test-Connection"
                   Write-Host "  Host [8.8.8.8]: " -NoNewline -ForegroundColor Green
                   $h = Read-Host; if (!$h) { $h = "8.8.8.8" }
                   Test-Connection $h -Count 4; Pause-Menu }
            "0"  { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Reparacao {
    do {
        Write-Header
        Write-Section "3. Reparacao do Windows"
        Write-MenuItem "1" "Verificar e reparar arquivos do sistema (sfc /scannow)"
        Write-MenuItem "2" "Verificar imagem do Windows (DISM ScanHealth)"
        Write-MenuItem "3" "Reparar imagem do Windows (DISM RestoreHealth)"
        Write-MenuItem "4" "Verificar versao do Windows (winver)"
        Write-MenuItem "5" "Consultar atualizacoes instaladas (Get-HotFix)"
        Write-MenuItem "6" "Atualizar politicas de grupo (gpupdate /force)"
        Write-MenuItem "7" "Consultar eventos do sistema (ultimos 50)"
        Write-MenuItem "8" "Reiniciar o computador"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Write-Header; Write-Section "SFC /scannow"
                  Write-Aviso "Este processo pode levar alguns minutos..."
                  Invoke-ComAdmin "Verificar e reparar arquivos do sistema (sfc /scannow)" {
                      sfc /scannow
                  }
                  Pause-Menu }
            "2" { Write-Header; Write-Section "DISM - ScanHealth"
                  Write-Aviso "Aguarde, isso pode demorar..."
                  Invoke-ComAdmin "Verificar imagem do Windows (DISM ScanHealth)" {
                      DISM /Online /Cleanup-Image /ScanHealth
                  }
                  Pause-Menu }
            "3" { Write-Header; Write-Section "DISM - RestoreHealth"
                  Write-Aviso "Aguarde, isso pode demorar e requer internet..."
                  Invoke-ComAdmin "Reparar imagem do Windows (DISM RestoreHealth)" {
                      DISM /Online /Cleanup-Image /RestoreHealth
                  }
                  Pause-Menu }
            "4" { Write-Header; Write-Section "Versao do Windows"
                  Start-Process winver; Pause-Menu }
            "5" { Write-Header; Write-Section "Atualizacoes Instaladas"
                  Get-HotFix | Sort-Object InstalledOn -Descending |
                      Select-Object -First 20 |
                      Format-Table HotFixID, Description, InstalledOn -AutoSize
                  Pause-Menu }
            "6" { Write-Header; Write-Section "Atualizar Politicas de Grupo"
                  Invoke-ComAdmin "Atualizar politicas de grupo (gpupdate /force)" {
                      gpupdate /force
                  }
                  Pause-Menu }
            "7" { Write-Header; Write-Section "Eventos do Sistema (ultimos 50)"
                  Get-WinEvent -LogName System -MaxEvents 50 |
                      Format-Table TimeCreated, LevelDisplayName, Message -AutoSize -Wrap
                  Pause-Menu }
            "8" { Write-Header; Write-Section "Reiniciar Computador"
                  if (Confirmar "Reiniciar o computador agora?") {
                      Restart-Computer
                  } else { Write-Aviso "Reinicio cancelado." }
                  Pause-Menu }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Disco {
    do {
        Write-Header
        Write-Section "4. Disco e Armazenamento"
        Write-MenuItem "1" "Verificar disco (chkdsk C: /scan)"
        Write-MenuItem "2" "Consultar discos fisicos"
        Write-MenuItem "3" "Consultar saude dos discos"
        Write-MenuItem "4" "Consultar unidades e espaco livre"
        Write-MenuItem "5" "Consultar erros recentes de armazenamento (ultimos 7 dias)"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Write-Header; Write-Section "CHKDSK C:"
                  Write-Aviso "Executando verificacao em modo scan..."
                  Invoke-ComAdmin "Verificar disco (chkdsk C: /scan)" {
                      chkdsk C: /scan
                  }
                  Pause-Menu }
            "2" { Write-Header; Write-Section "Discos Fisicos"
                  Get-PhysicalDisk | Format-Table -AutoSize; Pause-Menu }
            "3" { Write-Header; Write-Section "Saude dos Discos"
                  Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus |
                      Format-Table -AutoSize
                  Pause-Menu }
            "4" { Write-Header; Write-Section "Unidades e Espaco Livre"
                  Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
                      Select-Object DeviceID,
                          @{N='Tamanho (GB)'; E={[math]::Round($_.Size/1GB,2)}},
                          @{N='Livre (GB)';   E={[math]::Round($_.FreeSpace/1GB,2)}},
                          @{N='% Livre';      E={[math]::Round($_.FreeSpace/$_.Size*100,1)}} |
                      Format-Table -AutoSize
                  Pause-Menu }
            "5" { Write-Header; Write-Section "Erros de Armazenamento (ultimos 7 dias)"
                  Write-Info "Buscando eventos..."
                  Get-WinEvent -FilterHashtable @{
                      LogName   = 'System'
                      StartTime = (Get-Date).AddDays(-7)
                  } -ErrorAction SilentlyContinue |
                      Where-Object { $_.ProviderName -match 'disk|Ntfs|storahci|stornvme' } |
                      Select-Object -First 30 TimeCreated, ProviderName, Id, Message |
                      Format-Table -AutoSize -Wrap
                  Pause-Menu }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Boot {
    do {
        Write-Header
        Write-Section "5. Inicializacao do Windows - BCD e Boot"
        Write-Aviso "Atencao: comandos de boot podem afetar a inicializacao do sistema."
        Write-Host ""
        Write-MenuItem "1" "Consultar configuracao de boot (bcdedit /enum)"
        Write-MenuItem "2" "Listar todas as entradas BCD (bcdedit /enum all)"
        Write-MenuItem "3" "Abrir ferramenta de particoes (diskpart)"
        Write-MenuItem "4" "Reconstruir arquivos de inicializacao (bcdboot)"
        Write-MenuItem "5" "Procurar instalacoes do Windows (bootrec /scanos)"
        Write-MenuItem "6" "Reconstruir configuracao de inicializacao (bootrec /rebuildbcd)"
        Write-MenuItem "7" "Corrigir MBR (bootrec /fixmbr)"
        Write-MenuItem "8" "Corrigir setor de inicializacao (bootrec /fixboot)"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Write-Header; Write-Section "bcdedit /enum"
                  Invoke-ComAdmin "Consultar configuracao de boot (bcdedit /enum)" {
                      bcdedit /enum
                  }
                  Pause-Menu }
            "2" { Write-Header; Write-Section "bcdedit /enum all"
                  Invoke-ComAdmin "Listar todas as entradas BCD (bcdedit /enum all)" {
                      bcdedit /enum all | More
                  }
                  Pause-Menu }
            "3" { Write-Header; Write-Section "DiskPart"
                  Write-Aviso "Abrindo diskpart em nova janela elevada..."
                  Start-Process diskpart -Verb RunAs; Pause-Menu }
            "4" { Write-Header; Write-Section "bcdboot C:\Windows"
                  if (Confirmar "Reconstruir arquivos de inicializacao?") {
                      Invoke-ComAdmin "Reconstruir arquivos de inicializacao (bcdboot)" {
                          bcdboot C:\Windows
                      }
                  } else { Write-Aviso "Cancelado." }
                  Pause-Menu }
            "5" { Write-Header; Write-Section "bootrec /scanos"
                  Invoke-ComAdmin "Procurar instalacoes do Windows (bootrec /scanos)" {
                      bootrec /scanos
                  }
                  Pause-Menu }
            "6" { Write-Header; Write-Section "bootrec /rebuildbcd"
                  if (Confirmar "Reconstruir configuracao de inicializacao?") {
                      Invoke-ComAdmin "Reconstruir configuracao de inicializacao (bootrec /rebuildbcd)" {
                          bootrec /rebuildbcd
                      }
                  } else { Write-Aviso "Cancelado." }
                  Pause-Menu }
            "7" { Write-Header; Write-Section "bootrec /fixmbr"
                  if (Confirmar "Corrigir o MBR? Use apenas em sistemas Legacy BIOS.") {
                      Invoke-ComAdmin "Corrigir MBR (bootrec /fixmbr)" {
                          bootrec /fixmbr
                      }
                  } else { Write-Aviso "Cancelado." }
                  Pause-Menu }
            "8" { Write-Header; Write-Section "bootrec /fixboot"
                  if (Confirmar "Corrigir setor de inicializacao?") {
                      Invoke-ComAdmin "Corrigir setor de inicializacao (bootrec /fixboot)" {
                          bootrec /fixboot
                      }
                  } else { Write-Aviso "Cancelado." }
                  Pause-Menu }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Processos {
    do {
        Write-Header
        Write-Section "6. Processos, Servicos e Desempenho"
        Write-MenuItem "1" "Listar processos"
        Write-MenuItem "2" "Top 10 processos por CPU acumulado"
        Write-MenuItem "3" "Top 10 processos por uso de memoria"
        Write-MenuItem "4" "Listar todos os servicos"
        Write-MenuItem "5" "Listar servicos em execucao"
        Write-MenuItem "6" "Consultar processador e carga"
        Write-MenuItem "7" "Consultar memoria do sistema"
        Write-MenuItem "8" "Abrir Gerenciador de Tarefas"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Write-Header; Write-Section "Processos"
                  Get-Process | Sort-Object CPU -Descending | Format-Table -AutoSize | More
                  Pause-Menu }
            "2" { Write-Header; Write-Section "Top 10 - CPU Acumulado"
                  Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
                      Format-Table ProcessName, Id, CPU, WorkingSet64 -AutoSize
                  Pause-Menu }
            "3" { Write-Header; Write-Section "Top 10 - Uso de Memoria"
                  Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 |
                      Select-Object ProcessName, Id,
                          @{N='Memoria (MB)'; E={[math]::Round($_.WorkingSet64/1MB,1)}} |
                      Format-Table -AutoSize
                  Pause-Menu }
            "4" { Write-Header; Write-Section "Todos os Servicos"
                  Get-Service | Sort-Object Status -Descending | Format-Table -AutoSize | More
                  Pause-Menu }
            "5" { Write-Header; Write-Section "Servicos em Execucao"
                  Get-Service | Where-Object Status -eq 'Running' |
                      Sort-Object DisplayName | Format-Table -AutoSize
                  Pause-Menu }
            "6" { Write-Header; Write-Section "Processador e Carga"
                  Get-CimInstance Win32_Processor |
                      Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, LoadPercentage |
                      Format-List
                  Pause-Menu }
            "7" { Write-Header; Write-Section "Memoria do Sistema"
                  $os = Get-CimInstance Win32_OperatingSystem
                  $total = [math]::Round($os.TotalVisibleMemorySize/1MB, 2)
                  $livre = [math]::Round($os.FreePhysicalMemory/1MB, 2)
                  $usada = [math]::Round($total - $livre, 2)
                  Write-Host ""
                  Write-Host "  Total : $total GB" -ForegroundColor White
                  Write-Host "  Usada : $usada GB" -ForegroundColor Yellow
                  Write-Host "  Livre : $livre GB" -ForegroundColor Green
                  Pause-Menu }
            "8" { Write-Header; Write-Section "Gerenciador de Tarefas"
                  Start-Process taskmgr; Write-Ok "Gerenciador de Tarefas aberto."
                  Pause-Menu }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Seguranca {
    do {
        Write-Header
        Write-Section "7. Seguranca"
        Write-MenuItem "1" "Consultar estado do Microsoft Defender"
        Write-MenuItem "2" "Executar verificacao rapida do Defender"
        Write-MenuItem "3" "Consultar perfis do Firewall"
        Write-MenuItem "4" "Consultar estado do BitLocker"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Write-Header; Write-Section "Estado do Microsoft Defender"
                  Get-MpComputerStatus | Format-List; Pause-Menu }
            "2" { Write-Header; Write-Section "Verificacao Rapida - Defender"
                  Write-Info "Iniciando Quick Scan... Aguarde."
                  Invoke-ComAdmin "Executar verificacao rapida do Defender (Quick Scan)" {
                      Start-MpScan -ScanType QuickScan
                      Write-Ok "Scan iniciado em segundo plano."
                  }
                  Pause-Menu }
            "3" { Write-Header; Write-Section "Perfis do Firewall"
                  Get-NetFirewallProfile |
                      Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction -AutoSize
                  Pause-Menu }
            "4" { Write-Header; Write-Section "Estado do BitLocker"
                  Invoke-ComAdmin "Consultar estado do BitLocker" {
                      Get-BitLockerVolume |
                          Format-Table MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage -AutoSize
                  }
                  Pause-Menu }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Inventario {
    do {
        Write-Header
        Write-Section "8. Inventario do Computador"
        Write-MenuItem "1" "Nome do computador e usuario atual"
        Write-MenuItem "2" "Fabricante e modelo"
        Write-MenuItem "3" "Numero de serie"
        Write-MenuItem "4" "Versao e compilacao do Windows"
        Write-MenuItem "5" "Memoria RAM instalada"
        Write-MenuItem "6" "Enderecos IPv4"
        Write-MenuItem "7" "Impressoras instaladas"
        Write-MenuItem "8" "Data de inicializacao do sistema"
        Write-MenuItem "9" "Relatorio completo do inventario"
        Write-Host ""
        Write-MenuItem "0" "Voltar ao menu principal"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Write-Header; Write-Section "Computador e Usuario"
                  Write-Host "  Computador : $env:COMPUTERNAME" -ForegroundColor White
                  Write-Host "  Usuario    : $env:USERNAME"     -ForegroundColor White
                  Pause-Menu }
            "2" { Write-Header; Write-Section "Fabricante e Modelo"
                  Get-CimInstance Win32_ComputerSystem |
                      Select-Object Manufacturer, Model, TotalPhysicalMemory | Format-List
                  Pause-Menu }
            "3" { Write-Header; Write-Section "Numero de Serie"
                  Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SerialNumber, Version | Format-List
                  Pause-Menu }
            "4" { Write-Header; Write-Section "Versao do Windows"
                  Get-CimInstance Win32_OperatingSystem |
                      Select-Object Caption, Version, BuildNumber, OSArchitecture | Format-List
                  Pause-Menu }
            "5" { Write-Header; Write-Section "Memoria RAM Instalada"
                  $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
                  $total = [math]::Round($ram.Sum/1GB, 2)
                  Write-Host "  RAM Total instalada: $total GB" -ForegroundColor White
                  Write-Host ""
                  Get-CimInstance Win32_PhysicalMemory |
                      Select-Object BankLabel, Manufacturer,
                          @{N='Capacidade (GB)'; E={[math]::Round($_.Capacity/1GB,2)}},
                          Speed | Format-Table -AutoSize
                  Pause-Menu }
            "6" { Write-Header; Write-Section "Enderecos IPv4"
                  Get-NetIPAddress -AddressFamily IPv4 |
                      Where-Object { $_.IPAddress -ne '127.0.0.1' } |
                      Format-Table InterfaceAlias, IPAddress, PrefixLength -AutoSize
                  Pause-Menu }
            "7" { Write-Header; Write-Section "Impressoras Instaladas"
                  Get-Printer | Format-Table Name, DriverName, PortName, PrinterStatus -AutoSize
                  Pause-Menu }
            "8" { Write-Header; Write-Section "Ultimo Boot do Sistema"
                  $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
                  $uptime = (Get-Date) - $boot
                  Write-Host "  Ultimo boot : $($boot.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor White
                  Write-Host "  Uptime      : $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Cyan
                  Pause-Menu }
            "9" { Write-Header; Write-Section "Relatorio Completo"
                  Write-Host "  -- Identificacao -------------------------------------------" -ForegroundColor DarkGray
                  $cs   = Get-CimInstance Win32_ComputerSystem
                  $bios = Get-CimInstance Win32_BIOS
                  $os   = Get-CimInstance Win32_OperatingSystem
                  $ram  = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
                  Write-Host "  Computador : $env:COMPUTERNAME"
                  Write-Host "  Usuario    : $env:USERNAME"
                  Write-Host "  Fabricante : $($cs.Manufacturer)"
                  Write-Host "  Modelo     : $($cs.Model)"
                  Write-Host "  Nr Serie   : $($bios.SerialNumber)"
                  Write-Host "  Windows    : $($os.Caption) (Build $($os.BuildNumber))"
                  Write-Host "  RAM        : $([math]::Round($ram.Sum/1GB,2)) GB"
                  $boot   = $os.LastBootUpTime
                  $uptime = (Get-Date) - $boot
                  Write-Host "  Boot       : $($boot.ToString('dd/MM/yyyy HH:mm:ss'))  (uptime $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m)"
                  Write-Host ""
                  Write-Host "  -- Rede ----------------------------------------------------" -ForegroundColor DarkGray
                  Get-NetIPAddress -AddressFamily IPv4 |
                      Where-Object { $_.IPAddress -ne '127.0.0.1' } |
                      Format-Table InterfaceAlias, IPAddress -AutoSize
                  Pause-Menu }
            "0" { return }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

function Menu-Principal {
    do {
        Write-Header
        Write-Host "  Selecione uma categoria:" -ForegroundColor White
        Write-Host ""
        Write-MenuItem "1" "Limpeza e Otimizacao"
        Write-MenuItem "2" "Rede e Conectividade"
        Write-MenuItem "3" "Reparacao do Windows"
        Write-MenuItem "4" "Disco e Armazenamento"
        Write-MenuItem "5" "Inicializacao - BCD e Boot"
        Write-MenuItem "6" "Processos, Servicos e Desempenho"
        Write-MenuItem "7" "Seguranca"
        Write-MenuItem "8" "Inventario do Computador"
        Write-Host ""
        Write-MenuItem "0" "Sair"
        Write-Host ""
        Write-Host "  Opcao: " -ForegroundColor Green -NoNewline
        $op = Read-Host

        switch ($op) {
            "1" { Menu-Limpeza    }
            "2" { Menu-Rede       }
            "3" { Menu-Reparacao  }
            "4" { Menu-Disco      }
            "5" { Menu-Boot       }
            "6" { Menu-Processos  }
            "7" { Menu-Seguranca  }
            "8" { Menu-Inventario }
            "0" { Write-Host ""; Write-Host "  Ate logo!" -ForegroundColor Cyan; Write-Host ""; exit }
            default { Write-Aviso "Opcao invalida."; Start-Sleep 1 }
        }
    } while ($true)
}

Menu-Principal