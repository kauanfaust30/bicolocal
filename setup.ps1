# Prepara o projeto BicoLocal (Windows / PowerShell).
# Uso: powershell -ExecutionPolicy Bypass -File setup.ps1
$ErrorActionPreference = "Stop"

function Precisa($cmd, $dica) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    Write-Host "FALTA: $cmd. $dica" -ForegroundColor Red
    exit 1
  }
}

Precisa "git" "Instale o Git: https://git-scm.com"
Precisa "flutter" "Instale o Flutter: https://docs.flutter.dev/get-started/install"
Precisa "python" "Instale o Python 3.11+: https://python.org"
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
  Write-Host "Aviso: comando codex nao encontrado no terminal. Sem problema se voce usa a extensao Codex do VS Code." -ForegroundColor Yellow
}

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host "Instalando uv..." -ForegroundColor Yellow
  pip install uv
}
# garante que a pasta dos programas do uv esta no PATH desta sessao
$env:Path += ";$env:USERPROFILE\.local\bin"
try { $uvBin = (uv tool dir --bin) 2>$null; if ($uvBin) { $env:Path += ";$uvBin" } } catch {}

if (-not (Get-Command specify -ErrorAction SilentlyContinue)) {
  Write-Host "Instalando Specify CLI (repositorio oficial da GitHub)..." -ForegroundColor Yellow
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
  try { $uvBin = (uv tool dir --bin) 2>$null; if ($uvBin) { $env:Path += ";$uvBin" } } catch {}
}

# se ainda nao achar o specify, roda via uvx (sem instalar)
function Invoke-SpecKit {
  if (Get-Command specify -ErrorAction SilentlyContinue) { & specify @args }
  else { & uvx --from git+https://github.com/github/spec-kit.git specify @args }
}

# guarda o AGENTS.md para o init nao sobrescrever
$agentsOriginal = Get-Content AGENTS.md -Raw

if (-not (Test-Path pubspec.yaml)) {
  Write-Host "Criando o projeto Flutter..." -ForegroundColor Yellow
  flutter create . --project-name bicolocal
}

if (-not (Test-Path .git)) { git init }

if (-not (Test-Path .specify)) {
  Write-Host "Iniciando o Spec Kit com a integracao do Codex..." -ForegroundColor Yellow
  Invoke-SpecKit init --here --force --integration codex --script ps
}

# garante que as instrucoes do BicoLocal continuam no AGENTS.md
$agentsAtual = Get-Content AGENTS.md -Raw
if ($agentsAtual -notmatch "BicoLocal: instru") {
  Set-Content AGENTS.md ($agentsAtual + "`n`n" + $agentsOriginal)
}

git add -A
git commit -m "Inicia o projeto Flutter com Spec Kit e Codex" 2>$null

Write-Host ""
Write-Host "Pronto. Abra o Codex nesta pasta e siga o LEIA-ME.md (passo 3)." -ForegroundColor Green
Write-Host "Confira se existem as skills em .agents/skills (speckit-*)." -ForegroundColor Green