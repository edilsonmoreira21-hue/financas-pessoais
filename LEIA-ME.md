# Finanças Pessoais — instalação e sincronização

## Já está no ar

| O quê | Onde |
|---|---|
| App publicado | <https://edilsonmoreira21-hue.github.io/financas-pessoais/> |
| Código | <https://github.com/edilsonmoreira21-hue/financas-pessoais> |
| Banco (Supabase) | projeto `financas-pessoais` · `https://npooxxzrcalmvqodtydt.supabase.co` · região São Paulo |

O esquema do banco já foi aplicado (4 tabelas, RLS ativo, 1 política por tabela).
Falta gravar a chave publishable no app — uma vez só, no computador:

```bash
./configurar-chave.sh sb_publishable_...
```

(A chave está em Supabase → Project Settings → API Keys → **Publishable key**. Nunca use a
*secret key*: o script recusa se você tentar.)

O script grava a chave no `index.html`, comita e publica. Depois disso, qualquer navegador —
computador, celular, o de um amigo — abre direto numa **tela de senha**, sem configurar nada.

Para publicar uma alteração no app depois de editar os arquivos:

```bash
git add -A && git commit -m "ajuste" && git push
```

O GitHub Pages republica sozinho em cerca de um minuto. Se o `git push` reclamar de conta,
rode antes `gh auth switch --user edilsonmoreira21-hue`.


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
| `configurar-chave.sh` | Grava a chave publishable no app e publica |

O app exige entrar com e-mail e senha — é assim que ele sabe de quem são os dados e mantém
computador e celular em sincronia.

## Passo 1 — criar o banco (5 minutos)

1. Crie uma conta em <https://supabase.com> e clique em **New project**.
   Guarde a senha do banco que ele pedir (não é a senha do app).
2. Aberto o projeto, vá em **SQL Editor** → **New query**.
3. Cole todo o conteúdo de `supabase.sql` e clique em **Run**.
4. Vá em **Project Settings → API** e copie dois valores:
   - **Project URL** — algo como `https://abcdefgh.supabase.co`
   - **anon public** — a chave longa que começa com `eyJ...`

> A chave publishable é pública por natureza — pode ficar no HTML e no repositório. Quem
> protege os dados é o RLS que o `supabase.sql` ativou: cada conta só enxerga as próprias
> linhas. A *secret key* é outra coisa e nunca deve sair do painel do Supabase.
>
> Como o cadastro do Supabase vem aberto por padrão, depois de criar a sua conta vale
> desligar novos cadastros em **Authentication → Sign In / Providers**. Ninguém consegue ver
> seus dados de qualquer forma, mas isso evita que estranhos consumam sua cota.

## Passo 2 — publicar o app (5 minutos)

Para instalar no celular, os arquivos precisam estar num endereço `https`. O caminho mais
rápido é o **Cloudflare Pages**:

1. Acesse <https://pages.cloudflare.com> → **Create a project** → **Direct Upload**.
2. Arraste a pasta inteira (com `index.html`, `manifest.json`, `sw.js` e os dois ícones).
3. Ele devolve um endereço fixo, tipo `https://financas-abc.pages.dev`.

Alternativas equivalentes: Netlify Drop (<https://app.netlify.com/drop>) ou GitHub Pages.

## Passo 3 — gravar a chave e entrar

A chave publishable vive dentro do `index.html`, então ela é configurada **uma vez** e vale
para todos os aparelhos:

```bash
./configurar-chave.sh sb_publishable_...
```

Depois é só abrir o endereço publicado: aparece a tela de entrada.

1. Digite e-mail e senha → **Criar conta** (só na primeira vez; depois é *Entrar*).
2. No outro aparelho, mesma tela, botão **Entrar** — os dados descem sozinhos.

A sessão fica salva no aparelho, então você não digita a senha toda vez: só ao trocar de
navegador ou depois de sair da conta.

> Se o Supabase pedir confirmação por e-mail ao criar a conta, confirme pelo link recebido e
> depois use **Entrar**. Para dispensar essa etapa: Authentication → Sign In / Providers →
> desmarque *Confirm email*.

## Passo 4 — instalar no celular

- **Android/Chrome:** abra o endereço → menu ⋮ → *Instalar aplicativo*.
- **iPhone/Safari:** abra o endereço → botão compartilhar → *Adicionar à Tela de Início*.

O ícone vai para a tela inicial e o app abre em tela cheia, sem barra de navegador.

## Aba de dívidas

Empréstimos, financiamentos e compras parceladas ficam na aba **Dívidas**. De cada uma o app
guarda o valor da parcela, a parcela atual, o total de parcelas e a data da próxima — e calcula
sozinho o saldo devedor, quantas faltam e o mês em que a dívida termina.

O botão **Registrar pagamento** avança uma parcela, empurra o vencimento para o mês seguinte e
lança a despesa correspondente na categoria *Dívidas* (dá para desligar esse lançamento
automático no formulário da dívida).

> Se você criou o banco antes desta aba existir, rode o `supabase.sql` de novo no SQL Editor —
> ele só acrescenta a tabela `dividas`, sem tocar no que já existe. Até lá o app continua
> funcionando normalmente e guarda as dívidas apenas no aparelho.

## Como a sincronização funciona

- O app abre numa tela de senha; a sessão fica guardada no aparelho, e sair da conta apaga o
  cache local — outra pessoa que entre na sua máquina não vê seus lançamentos.
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
