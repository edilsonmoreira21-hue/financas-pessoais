#!/bin/bash
# Grava a configuração do Firebase dentro do index.html e publica.
#
#   ./configurar-firebase.sh <apiKey> <projectId>
#
# Os dois valores estão no console do Firebase, em
# Project settings → General → Your apps → SDK setup and configuration.
#
# A chave web pode ficar no código: quem protege os dados são as Security Rules,
# que só deixam cada conta ler e escrever em users/{uid}.
set -e
cd "$(dirname "$0")"

if [ -z "$2" ]; then
  echo "uso: ./configurar-firebase.sh <apiKey> <projectId>"
  echo "     (Firebase → Project settings → General → Your apps)"
  exit 1
fi

python3 - "$1" "$2" <<'PY'
import sys, io, re
chave, projeto = sys.argv[1].strip(), sys.argv[2].strip()

if not re.match(r'^AIza[0-9A-Za-z_\-]{20,}$', chave):
    sys.exit('ERRO: isso não parece a chave web do Firebase (ela começa com AIza).')
if not re.match(r'^[a-z0-9][a-z0-9\-]{3,}$', projeto):
    sys.exit('ERRO: id de projeto inválido (letras minúsculas, números e hífen).')

p = 'index.html'
s = io.open(p, encoding='utf-8').read()
s, a = re.subn(r"apiKey: '[^']*'",    "apiKey: '%s'"    % chave,   s, count=1)
s, b = re.subn(r"projectId: '[^']*'", "projectId: '%s'" % projeto, s, count=1)
if a != 1 or b != 1:
    sys.exit('ERRO: não encontrei o bloco FIREBASE em index.html.')
io.open(p, 'w', encoding='utf-8').write(s)
print('configuração gravada em index.html')
PY

if [ -d .git ]; then
  git add index.html
  git commit -q -m "Configura o projeto Firebase" || true

  ANTES=$(gh auth status 2>/dev/null | grep -B1 'Active account: true' | grep 'Logged in to' | sed 's/.*account //;s/ .*//' || true)
  gh auth switch --user edilsonmoreira21-hue >/dev/null 2>&1 || true
  if git push -q 2>/dev/null; then
    echo "publicado — https://edilsonmoreira21-hue.github.io/financas-pessoais/ atualiza em cerca de um minuto"
  else
    echo "a configuração foi gravada, mas o push falhou. Rode: git push"
  fi
  [ -n "$ANTES" ] && gh auth switch --user "$ANTES" >/dev/null 2>&1 || true
fi
