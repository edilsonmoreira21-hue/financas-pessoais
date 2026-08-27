# Finanças Pessoais — instalação e sincronização

## Já está no ar

| O quê | Onde |
|---|---|
| App publicado | <https://edilsonmoreira21-hue.github.io/financas-pessoais/> |
| Código | <https://github.com/edilsonmoreira21-hue/financas-pessoais> |
| Banco | Firebase (Firestore) · projeto `financas-pessoais` |

Falta gravar a configuração do Firebase no app — uma vez só, no computador:

```bash
./configurar-firebase.sh AIza... financas-pessoais-xxxxx
```

(Os dois valores estão em Firebase → Project settings → General → Your apps.)

O script grava no `index.html`, comita e publica. Depois disso, qualquer navegador —
computador, celular, o de um amigo — abre direto numa **tela de senha**, sem configurar nada.

Para publicar uma alteração no app depois de editar os arquivos:

```bash
git add -A && git commit -m "ajuste" && git push
```

O GitHub Pages republica sozinho em cerca de um minuto. Se o `git push` reclamar de conta,
rode antes `gh auth switch --user edilsonmoreira21-hue`.


App de finanças em arquivo único, com banco na nuvem (Firebase) e instalação no celular (PWA).
Sem servidor próprio, sem build, sem npm.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `index.html` | O app inteiro (interface, gráficos, sincronização) |
| `firestore.rules` | Regras de segurança do banco — colar no console do Firebase |
| `manifest.json` | Faz o app instalar na tela inicial do celular |
| `sw.js` | Service worker: abre o app offline |
| `icone-192.png`, `icone-512.png` | Ícones do app |
| `servidor-local.py` | Servidor local só para testar no computador |
| `configurar-firebase.sh` | Grava a configuração do Firebase no app e publica |

O app exige entrar com e-mail e senha — é assim que ele sabe de quem são os dados e mantém
computador e celular em sincronia.

## Passo 1 — criar o banco (5 minutos)

1. Em <https://console.firebase.google.com> → **Criar um projeto**.
2. **Authentication → Sign-in method → Email/Password → Ativar.**
3. **Firestore Database → Criar banco de dados** → modo produção → região `southamerica-east1`.
4. Na aba **Rules**, cole o conteúdo de `firestore.rules` e clique em **Publicar**.
5. Em **Project settings → General → Your apps**, registre um app Web e copie a `apiKey` e o
   `projectId`.

> A chave web é pública por natureza — pode ficar no HTML e no repositório. Quem protege os
> dados são as Security Rules: cada conta só lê e escreve em `users/{seu uid}`.
>
> Depois de criar a sua conta no app, vale desligar novos cadastros em
> **Authentication → Settings → User actions → Enable create (sign-up)**. Ninguém veria seus
> dados de qualquer forma, mas isso impede que estranhos criem contas no seu projeto.

## Passo 2 — publicar o app (5 minutos)

Para instalar no celular, os arquivos precisam estar num endereço `https`. O caminho mais
rápido é o **Cloudflare Pages**:

1. Acesse <https://pages.cloudflare.com> → **Create a project** → **Direct Upload**.
2. Arraste a pasta inteira (com `index.html`, `manifest.json`, `sw.js` e os dois ícones).
3. Ele devolve um endereço fixo, tipo `https://financas-abc.pages.dev`.

Alternativas equivalentes: Netlify Drop (<https://app.netlify.com/drop>) ou GitHub Pages.

## Passo 3 — gravar a configuração e entrar

A configuração vive dentro do `index.html`, então é feita **uma vez** e vale para todos os
aparelhos:

```bash
./configurar-firebase.sh AIza... financas-pessoais-xxxxx
```

Depois é só abrir o endereço publicado: aparece a tela de entrada.

1. Digite e-mail e senha → **Criar conta** (só na primeira vez; depois é *Entrar*).
2. No outro aparelho, mesma tela, botão **Entrar** — os dados descem sozinhos.

A sessão fica salva no aparelho, então você não digita a senha toda vez: só ao trocar de
navegador ou depois de sair da conta.

## Passo 4 — instalar no celular

- **Android/Chrome:** abra o endereço → menu ⋮ → *Instalar aplicativo*.
- **iPhone/Safari:** abra o endereço → botão compartilhar → *Adicionar à Tela de Início*.

O ícone vai para a tela inicial e o app abre em tela cheia, sem barra de navegador.

No celular a interface muda de forma: barra de navegação fixa embaixo (Painel, Extrato,
Cartões, Dívidas e *Mais*), botão flutuante para lançar, cabeçalho de uma linha só com o
seletor de mês, indicadores lado a lado, extrato em cartões no lugar da tabela e formulários
que sobem como folha inferior. O app também respeita as áreas seguras do iPhone (notch e barra
inferior).

## Cartões de crédito e parcelamento

Na aba **Cartões** você cadastra cada cartão com limite, dia de fechamento e dia de vencimento.
A partir daí:

- No formulário de lançamento, o campo *Conta / método* passa a listar os cartões num grupo
  separado. Escolhendo um cartão, a despesa entra na fatura dele.
- A fatura de cada mês é montada pela regra do fechamento: compra feita **depois** do dia de
  fechamento entra na fatura do mês seguinte. O vencimento também acompanha — fecha 28/08 e
  vence dia 5 significa vencer em 05/09.
- A aba mostra a fatura do mês selecionado no topo da tela, com o total, quanto do limite foi
  usado e o que já está comprometido nas faturas seguintes.
- Dá para **editar a fatura direto ali**: o botão *Lançar nesta fatura* já abre o formulário
  apontando para o cartão, e cada linha tem editar e excluir.

**Parcelamento:** no lançamento de despesa existe o campo *Parcelas*. Informe o valor total da
compra e o número de parcelas — o app cria um lançamento por mês, com o selo `3/12`, e mostra
antes de salvar quanto fica cada parcela e em que mês termina. A divisão é feita em centavos e
a sobra vai na primeira parcela, como o cartão faz.

Excluir uma parcela pergunta se você quer excluir também as seguintes, então dá para cancelar
uma compra parcelada inteira ou remover só um mês.

## Aba de dívidas

Empréstimos, financiamentos e compras parceladas ficam na aba **Dívidas**. De cada uma o app
guarda o valor da parcela, a parcela atual, o total de parcelas e a data da próxima — e calcula
sozinho o saldo devedor, quantas faltam e o mês em que a dívida termina.

O botão **Registrar pagamento** avança uma parcela, empurra o vencimento para o mês seguinte e
lança a despesa correspondente na categoria *Dívidas* (dá para desligar esse lançamento
automático no formulário da dívida).

> A coleção `dividas` nasce sozinha no primeiro registro — o Firestore não precisa de migração.

## Como a sincronização funciona

- O app abre numa tela de senha; a sessão fica guardada no aparelho, e sair da conta apaga o
  cache local — outra pessoa que entre na sua máquina não vê seus lançamentos.
- O aparelho continua sendo a fonte imediata: tudo é gravado primeiro no `localStorage`, então
  o app abre instantâneo e funciona **sem internet**.
- Cada alteração fica marcada como pendente e sobe sozinha 2,5 segundos depois, ao voltar a
  conexão, ou quando você reabre o app.
- Conflito entre aparelhos: vence a alteração com carimbo de tempo mais recente; o que ainda
  está pendente no aparelho nunca é sobrescrito antes de subir.
- Os dados ficam em `users/{uid}/transacoes`, `/orcamentos`, `/metas`, `/dividas` e
  `/preferencias`. Como o Firestore não tem esquema fixo, campo novo no app nunca exige
  migração de banco.
- Exclusões viajam como marcação (`deletado`), para sumirem também no outro aparelho. Depois
  de 60 dias essas marcas são descartadas localmente.
- O ícone ☁ no topo mostra o estado: verde sincronizado, âmbar pendente, vermelho falhou.
  Clicar nele força uma sincronização.

## Custos e limites

Plano gratuito do Firebase (Spark): 1 GiB de armazenamento, 50 mil leituras e 20 mil escritas
por dia. Uso pessoal não chega perto disso — a sincronização só lê o que mudou desde a última
vez. E o projeto não é pausado por inatividade.

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
