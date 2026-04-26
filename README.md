# Ultra Master Engineer Skills

12 skills especializados para agentes de IA (Antigravity, Claude Code, Gemini CLI, Cursor).

## Skills incluidos

| Skill | Descripción |
|---|---|
| `adversarial-reviewer` | Revisión hostil desde 3 perspectivas |
| `api-design-reviewer` | Validación REST/GraphQL/gRPC |
| `brainstorming` | Diseño-primero antes de codificar |
| `grill-me` | Interrogación de diseños |
| `improve-codebase-architecture` | Análisis arquitectónico estructural |
| `incident-commander` | Respuesta a incidentes SEV1-4 |
| `prompt-architect` | Frameworks de ingeniería de prompts |
| `subagent-driven-development` | Ejecución paralela con 2-stage review |
| `systematic-debugging` | 4 fases: reproducción → aislamiento → causa → fix |
| `tech-debt-tracker` | Auditoría y priorización de deuda técnica |
| `test-driven-development` | RED-GREEN-REFACTOR disciplinado |
| `verification-before-completion` | Nada es done sin verificación |

## Uso

### Instalación en un proyecto nuevo

```bash
git submodule add https://github.com/melvinortiz1919/ultra-master-skills.git .agent/skills
git submodule add https://github.com/melvinortiz1919/ultra-master-skills.git .claude/skills
git submodule update --init --recursive
```

### Actualizar a la última versión

```bash
git submodule update --remote .agent/skills
git submodule update --remote .claude/skills
git add .agent/skills .claude/skills
git commit -m "chore: actualizar ultra-master-skills"
```

### Script automático para nuevos proyectos

```powershell
# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File add-to-project.ps1
```

```bash
# macOS / Linux
bash add-to-project.sh
```
