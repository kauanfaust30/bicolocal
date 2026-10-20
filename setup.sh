#!/usr/bin/env bash
# Prepara o projeto BicoLocal (macOS / Linux).
# Uso: bash setup.sh
set -e

precisa() {
  command -v "$1" >/dev/null 2>&1 || { echo "FALTA: $1. $2"; exit 1; }
}

precisa git "Instale o Git: https://git-scm.com"
precisa flutter "Instale o Flutter: https://docs.flutter.dev/get-started/install"
precisa python3 "Instale o Python 3.11+: https://python.org"
precisa codex "Instale o Codex CLI: npm i -g @openai/codex (ou use a extensao do VS Code)"

command -v uv >/dev/null 2>&1 || { echo "Instalando uv..."; pip install uv; }
command -v specify >/dev/null 2>&1 || {
  echo "Instalando Specify CLI (repositorio oficial da GitHub)..."
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
}

# guarda o AGENTS.md para o init nao sobrescrever
cp AGENTS.md /tmp/AGENTS.bicolocal.md

[ -f pubspec.yaml ] || { echo "Criando o projeto Flutter..."; flutter create . --project-name bicolocal; }
[ -d .git ] || git init

if [ ! -d .specify ]; then
  echo "Iniciando o Spec Kit com a integracao do Codex..."
  specify init --here --force --integration codex --script sh
fi

# garante que as instrucoes do BicoLocal continuam no AGENTS.md
if ! grep -q "BicoLocal: instru" AGENTS.md; then
  printf "\n\n" >> AGENTS.md
  cat /tmp/AGENTS.bicolocal.md >> AGENTS.md
fi

git add -A
git commit -m "Inicia o projeto Flutter com Spec Kit e Codex" || true

echo
echo "Pronto. Abra o Codex nesta pasta e siga o LEIA-ME.md (passo 3)."
echo "Confira se existem as skills em .agents/skills (speckit-*)."
