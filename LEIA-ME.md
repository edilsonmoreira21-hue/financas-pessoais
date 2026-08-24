# Finanças Pessoais — instalação e sincronização

App de finanças em arquivo único, com banco na nuvem (Supabase) e instalação no celular (PWA).
Sem servidor próprio, sem build, sem npm.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `index.html` | O app inteiro (interface, gráficos, sincronização) |
| `supabase.sql` | Esquema do banco — roda uma vez no Supabase |
| `manifest.json` | Faz o app instalar na tela inicial do celular |
| `sw.js` | Service worker: abre o app offline |
| `icone-192.png`, `icone-512.png` | Ícones do app |
| `servidor-local.py` | Servidor local só para testar no computador |

Funciona sem nada disso: abrindo o `index.html` direto, o app já roda e guarda tudo no
navegador. A nuvem só é necessária para ver os mesmos dados no computador e no celular.

## Passo 1 — criar o banco (5 minutos)

1. Crie uma conta em <https://supabase.com> e clique em **New project**.
   Guarde a senha do banco que ele pedir (não é a senha do app).
2. Aberto o projeto, vá em **SQL Editor** → **New query**.
3. Cole todo o conteúdo de `supabase.sql` e clique em **Run**.
4. Vá em **Project Settings → API** e copie dois valores:
   - **Project URL** — algo como `https://abcdefgh.supabase.co`
   - **anon public** — a chave longa que começa com `eyJ...`

> A chave `anon` é pública por natureza. Quem protege os dados é o RLS que o `supabase.sql`
> ativou: cada conta só enxerga as próprias linhas.

## Passo 2 — publicar o app (5 minutos)

Para instalar no celular, os arquivos precisam estar num endereço `https`. O caminho mais
rápido é o **Cloudflare Pages**:

1. Acesse <https://pages.cloudflare.com> → **Create a project** → **Direct Upload**.
2. Arraste a pasta inteira (com `index.html`, `manifest.json`, `sw.js` e os dois ícones).
3. Ele devolve um endereço fixo, tipo `https://financas-abc.pages.dev`.

Alternativas equivalentes: Netlify Drop (<https://app.netlify.com/drop>) ou GitHub Pages.

## Passo 3 — conectar e entrar

No app publicado, abra **Configurações → Sincronização na nuvem**:

1. Cole a **Project URL** e a chave **anon public** → *Salvar conexão*.
2. Digite seu e-mail e uma senha → **Criar conta** (só na primeira vez; depois é *Entrar*).
3. Tudo o que já existia no aparelho sobe para a nuvem automaticamente.

No outro aparelho, repita os passos 1 e 2 usando **Entrar** — os dados descem sozinhos.

> Se o Supabase pedir confirmação por e-mail ao criar a conta, confirme pelo link recebido e
> depois use **Entrar**. Para dispensar essa etapa: Authentication → Sign In / Providers →
> desmarque *Confirm email*.

## Passo 4 — instalar no celular

- **Android/Chrome:** abra o endereço → menu ⋮ → *Instalar aplicativo*.
- **iPhone/Safari:** abra o endereço → botão compartilhar → *Adicionar à Tela de Início*.

O ícone vai para a tela inicial e o app abre em tela cheia, sem barra de navegador.

## Como a sincronização funciona

- O aparelho continua sendo a fonte imediata: tudo é gravado primeiro no `localStorage`, então
  o app abre instantâneo e funciona **sem internet**.
- Cada alteração fica marcada como pendente e sobe sozinha 2,5 segundos depois, ao voltar a
  conexão, ou quando você reabre o app.
- Conflito entre aparelhos: vence a alteração com carimbo de tempo mais recente; o que ainda
  está pendente no aparelho nunca é sobrescrito antes de subir.
- Exclusões viajam como marcação (`deletado`), para sumirem também no outro aparelho. Depois
  de 60 dias essas marcas são descartadas localmente.
- O ícone ☁ no topo mostra o estado: verde sincronizado, âmbar pendente, vermelho falhou.
  Clicar nele força uma sincronização.

## Custos e limites

Plano gratuito do Supabase: 500 MB de banco — anos de lançamentos ocupam poucos MB.
O projeto gratuito é pausado após 7 dias sem nenhum acesso; usando o app normalmente isso
não acontece, e reativar é um clique no painel.

## Testar no computador antes de publicar

```bash
python3 servidor-local.py 8765
```

Depois abra <http://localhost:8765>. Esse servidor é só para desenvolvimento — o service
worker e o `localStorage` exigem `http`/`https`, não funcionam bem abrindo o arquivo via
`file://` em alguns navegadores.

## Backup

Mesmo com a nuvem, **Configurações → Exportar JSON** gera um backup completo do que está no
aparelho, e o CSV abre direto no Excel.
