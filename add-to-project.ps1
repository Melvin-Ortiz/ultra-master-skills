# add-to-project.ps1
# Agrega Ultra Master Skills como submodule a cualquier proyecto git
# Uso: .\add-to-project.ps1
# Con URL personalizada: .\add-to-project.ps1 -SkillsRepoUrl "https://github.com/usuario/ultra-master-skills.git"

param(
    [string]$SkillsRepoUrl = "https://github.com/melvinortiz1919/ultra-master-skills.git"
)

$ErrorActionPreference = "Stop"

Write-Host "Agregando Ultra Master Skills al proyecto..." -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    Write-Host "ERROR: No es un repositorio git. Ejecuta 'git init' primero." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path ".agent" | Out-Null
New-Item -ItemType Directory -Force -Path ".claude" | Out-Null

if (Test-Path ".agent/skills") {
    Write-Host "AVISO: .agent/skills ya existe. Omitiendo." -ForegroundColor Yellow
} else {
    Write-Host "Agregando submodule en .agent/skills..." -ForegroundColor Gray
    git submodule add $SkillsRepoUrl .agent/skills
}

if (Test-Path ".claude/skills") {
    Write-Host "AVISO: .claude/skills ya existe. Omitiendo." -ForegroundColor Yellow
} else {
    Write-Host "Agregando submodule en .claude/skills..." -ForegroundColor Gray
    git submodule add $SkillsRepoUrl .claude/skills
}

git submodule update --init --recursive

$skillCount = @(Get-ChildItem ".agent/skills" -Directory).Count
Write-Host ""
Write-Host "Listo! $skillCount skills disponibles." -ForegroundColor Green
Write-Host "   .agent/skills/  -> Antigravity, Gemini CLI" -ForegroundColor Gray
Write-Host "   .claude/skills/ -> Claude Code" -ForegroundColor Gray
Write-Host ""
Write-Host "Siguiente paso — hacer commit:" -ForegroundColor Cyan
Write-Host "   git add .gitmodules .agent/skills .claude/skills"
Write-Host "   git commit -m 'feat: agregar ultra-master-skills como submodule'"
