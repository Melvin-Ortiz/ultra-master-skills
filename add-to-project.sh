#!/bin/bash
# add-to-project.sh
# Agrega Ultra Master Skills como submodule a cualquier proyecto git
# Uso: bash add-to-project.sh
# Con URL personalizada: SKILLS_REPO="https://..." bash add-to-project.sh

SKILLS_REPO="${SKILLS_REPO:-https://github.com/Melvin-Ortiz/ultra-master-skills.git}"

echo "Agregando Ultra Master Skills al proyecto..."

if [ ! -d ".git" ]; then
    echo "ERROR: No es un repositorio git. Ejecuta 'git init' primero."
    exit 1
fi

mkdir -p .agent .claude

if [ ! -d ".agent/skills" ]; then
    git submodule add "$SKILLS_REPO" .agent/skills
else
    echo "AVISO: .agent/skills ya existe. Omitiendo."
fi

if [ ! -d ".claude/skills" ]; then
    git submodule add "$SKILLS_REPO" .claude/skills
else
    echo "AVISO: .claude/skills ya existe. Omitiendo."
fi

git submodule update --init --recursive

SKILL_COUNT=$(find .agent/skills -maxdepth 1 -type d | wc -l)
echo ""
echo "Listo! $((SKILL_COUNT - 1)) skills disponibles."
echo "   .agent/skills/  -> Antigravity, Gemini CLI"
echo "   .claude/skills/ -> Claude Code"
echo ""
echo "Siguiente paso — hacer commit:"
echo "   git add .gitmodules .agent/skills .claude/skills"
echo "   git commit -m 'feat: agregar ultra-master-skills como submodule'"
