#!/bin/bash
# Grava a chave publishable do Supabase dentro do index.html e publica.
#
#   ./configurar-chave.sh sb_publishable_xxxxxxxxxxxxxxxx
#
# A chave publishable pode ficar no código: quem protege os dados é o RLS do banco,
# que só deixa cada conta enxergar as próprias linhas. Nunca use aqui a "secret key".
set -e
cd "$(dirname "$0")"

if [ -z "$1" ]; then
  echo "uso: ./configurar-chave.sh <chave publishable do Supabase>"
  echo "     (Supabase → Project Settings → API Keys → Publishable key)"
  exit 1
fi

python3 - "$1" <<'PY'
import sys, io, re
chave = sys.argv[1].strip()
if chave.startswith('sb_secret'):
    sys.exit('ERRO: essa é a secret key. Use a publishable key.')
if not (chave.startswith('sb_publishable_') or chave.startswith('eyJ')):
    sys.exit('ERRO: isso não parece uma chave publishable/anon do Supabase.')

p = 'index.html'
s = io.open(p, encoding='utf-8').read()
novo, n = re.subn(r"key: '[^']*' // chave publishable",
                  "key: '%s' // chave publishable" % chave, s, count=1)
if n != 1:
    sys.exit('ERRO: não encontrei a linha da chave em index.html.')
io.open(p, 'w', encoding='utf-8').write(novo)
print('chave gravada em index.html')
PY

if [ -d .git ]; then
  git add index.html
  git commit -q -m "Configura a chave publishable do Supabase" || true

  # publica usando a conta pessoal do GitHub e devolve a conta ativa como estava
  ANTES=$(gh auth status 2>/dev/null | grep -B1 'Active account: true' | grep 'Logged in to' | sed 's/.*account //;s/ .*//' || true)
  gh auth switch --user edilsonmoreira21-hue >/dev/null 2>&1 || true
  if git push -q 2>/dev/null; then
    echo "publicado — https://edilsonmoreira21-hue.github.io/financas-pessoais/ atualiza em cerca de um minuto"
  else
    echo "a chave foi gravada, mas o push falhou. Rode: git push"
  fi
  [ -n "$ANTES" ] && gh auth switch --user "$ANTES" >/dev/null 2>&1 || true
fi
