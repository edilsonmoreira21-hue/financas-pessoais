-- ============================================================
--  Finanças Pessoais — esquema do banco (Supabase / PostgreSQL)
--  Cole este arquivo inteiro no SQL Editor do Supabase e clique em RUN.
--  Pode ser executado mais de uma vez sem quebrar nada.
-- ============================================================

-- ---------- lançamentos ----------
create table if not exists public.transacoes (
  id             text primary key,
  user_id        uuid not null default auth.uid() references auth.users on delete cascade,
  tipo           text not null check (tipo in ('receita','despesa')),
  valor          numeric(14,2) not null default 0,
  data           date not null,
  categoria      text not null,
  descricao      text not null default '',
  conta          text,
  fixo           boolean not null default false,
  deletado       boolean not null default false,
  atualizado_em  timestamptz not null default now()
);

-- ---------- orçamentos (um limite por categoria) ----------
create table if not exists public.orcamentos (
  user_id        uuid not null default auth.uid() references auth.users on delete cascade,
  categoria      text not null,
  limite         numeric(14,2) not null default 0,
  deletado       boolean not null default false,
  atualizado_em  timestamptz not null default now(),
  primary key (user_id, categoria)
);

-- ---------- metas ----------
create table if not exists public.metas (
  id             text primary key,
  user_id        uuid not null default auth.uid() references auth.users on delete cascade,
  nome           text not null,
  alvo           numeric(14,2) not null default 0,
  atual          numeric(14,2) not null default 0,
  prazo          date,
  deletado       boolean not null default false,
  atualizado_em  timestamptz not null default now()
);

-- ---------- dívidas (empréstimos, financiamentos, compras parceladas) ----------
create table if not exists public.dividas (
  id             text primary key,
  user_id        uuid not null default auth.uid() references auth.users on delete cascade,
  nome           text not null,
  credor         text,
  parcela        numeric(14,2) not null default 0,
  atual          integer not null default 1,
  total          integer not null default 1,
  proxima        date not null,
  lancar         boolean not null default true,
  deletado       boolean not null default false,
  atualizado_em  timestamptz not null default now()
);

-- ---------- preferências (categorias e contas) ----------
create table if not exists public.preferencias (
  user_id        uuid primary key default auth.uid() references auth.users on delete cascade,
  dados          jsonb not null default '{}'::jsonb,
  atualizado_em  timestamptz not null default now()
);

-- ---------- índices para a sincronização incremental ----------
create index if not exists idx_transacoes_sync on public.transacoes (user_id, atualizado_em);
create index if not exists idx_transacoes_data on public.transacoes (user_id, data);
create index if not exists idx_orcamentos_sync on public.orcamentos (user_id, atualizado_em);
create index if not exists idx_metas_sync      on public.metas      (user_id, atualizado_em);
create index if not exists idx_dividas_sync    on public.dividas    (user_id, atualizado_em);

-- ============================================================
--  Segurança: cada conta só enxerga as próprias linhas.
--  Isso é o que torna seguro deixar a chave "anon" dentro do HTML.
-- ============================================================
alter table public.transacoes   enable row level security;
alter table public.orcamentos   enable row level security;
alter table public.metas        enable row level security;
alter table public.dividas      enable row level security;
alter table public.preferencias enable row level security;

drop policy if exists "dono das transacoes"   on public.transacoes;
drop policy if exists "dono dos orcamentos"   on public.orcamentos;
drop policy if exists "dono das metas"        on public.metas;
drop policy if exists "dono das dividas"      on public.dividas;
drop policy if exists "dono das preferencias" on public.preferencias;

create policy "dono das transacoes" on public.transacoes
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "dono dos orcamentos" on public.orcamentos
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "dono das metas" on public.metas
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "dono das dividas" on public.dividas
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "dono das preferencias" on public.preferencias
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
