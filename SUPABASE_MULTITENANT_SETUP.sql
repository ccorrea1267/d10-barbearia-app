-- 🏗️ SETUP MULTI-TENANT +D10 Barbearia
-- Cole TUDO isso no Supabase SQL Editor e execute
-- Isso vai criar:
-- 1. Tabelas multi-tenant
-- 2. Row Level Security (RLS)
-- 3. Autenticação por cliente
-- 4. Estrutura completa pronta para vender

-- ===== PASSO 1: TABELA DE TENANTS (CLIENTES) =====
CREATE TABLE IF NOT EXISTS public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL UNIQUE,
  email VARCHAR NOT NULL UNIQUE,
  phone VARCHAR,
  address VARCHAR,
  city VARCHAR,
  state VARCHAR,
  cnpj VARCHAR UNIQUE,

  -- Plano
  plan VARCHAR DEFAULT 'free', -- free, basic, premium
  subscription_date TIMESTAMP DEFAULT NOW(),

  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ===== PASSO 2: TABELA DE USUARIOS (STAFF DA BARBEARIA) =====
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  role VARCHAR DEFAULT 'staff', -- admin, staff, client

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(tenant_id, email)
);

-- ===== PASSO 3: TABELA DE CLIENTES (CUSTOMERS) =====
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  name VARCHAR NOT NULL,
  email VARCHAR,
  phone VARCHAR,
  cpf VARCHAR,

  -- Preferências
  preferred_barber VARCHAR,
  notes TEXT,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(tenant_id, email)
);

-- ===== PASSO 4: TABELA DE HORÁRIOS DISPONÍVEIS =====
CREATE TABLE IF NOT EXISTS public.time_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  date_slot DATE NOT NULL,
  time_slot TIME NOT NULL,
  barber VARCHAR NOT NULL,

  is_available BOOLEAN DEFAULT true,
  duration_minutes INT DEFAULT 30,

  created_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(tenant_id, date_slot, time_slot, barber)
);

-- ===== PASSO 5: TABELA DE AGENDAMENTOS =====
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,

  date_slot DATE NOT NULL,
  time_slot TIME NOT NULL,
  barber VARCHAR NOT NULL,
  service VARCHAR NOT NULL,

  -- Status
  status VARCHAR DEFAULT 'pending', -- pending, confirmed, completed, cancelled
  notes TEXT,

  -- Lembretes
  reminder_sent BOOLEAN DEFAULT false,
  whatsapp_confirmed BOOLEAN DEFAULT false,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ===== PASSO 6: TABELA DE CAMPANHAS =====
CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  title VARCHAR NOT NULL,
  message TEXT NOT NULL,

  -- Tipo
  campaign_type VARCHAR DEFAULT 'custom', -- mothers_day, fathers_day, children_day, custom

  -- Agendamento
  scheduled_date TIMESTAMP,
  sent_date TIMESTAMP,

  -- Status
  status VARCHAR DEFAULT 'draft', -- draft, scheduled, sent
  sent_to_count INT DEFAULT 0,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ===== PASSO 7: ENABLE ROW LEVEL SECURITY =====
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

-- ===== PASSO 8: CRIAR POLICIES (RLS) =====

-- TENANTS: Cada tenant vê só a si mesmo
CREATE POLICY "Tenants see only themselves"
  ON public.tenants FOR SELECT
  USING (id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Tenants can update themselves"
  ON public.tenants FOR UPDATE
  USING (id = auth.jwt_claim('tenant_id')::UUID);

-- USERS: Cada user vê só users do seu tenant
CREATE POLICY "Users see only their tenant users"
  ON public.users FOR SELECT
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Users can insert in their tenant"
  ON public.users FOR INSERT
  WITH CHECK (tenant_id = auth.jwt_claim('tenant_id')::UUID);

-- CUSTOMERS: Cada tenant vê só seus clientes
CREATE POLICY "Customers are isolated by tenant"
  ON public.customers FOR SELECT
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Customers can be inserted by tenant"
  ON public.customers FOR INSERT
  WITH CHECK (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Customers can be updated by tenant"
  ON public.customers FOR UPDATE
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

-- TIME_SLOTS: Isolado por tenant
CREATE POLICY "Time slots are isolated by tenant"
  ON public.time_slots FOR SELECT
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Time slots can be inserted by tenant"
  ON public.time_slots FOR INSERT
  WITH CHECK (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Time slots can be updated by tenant"
  ON public.time_slots FOR UPDATE
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

-- APPOINTMENTS: Isolado por tenant
CREATE POLICY "Appointments are isolated by tenant"
  ON public.appointments FOR SELECT
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Appointments can be inserted by tenant"
  ON public.appointments FOR INSERT
  WITH CHECK (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Appointments can be updated by tenant"
  ON public.appointments FOR UPDATE
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

-- CAMPAIGNS: Isolado por tenant
CREATE POLICY "Campaigns are isolated by tenant"
  ON public.campaigns FOR SELECT
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Campaigns can be inserted by tenant"
  ON public.campaigns FOR INSERT
  WITH CHECK (tenant_id = auth.jwt_claim('tenant_id')::UUID);

CREATE POLICY "Campaigns can be updated by tenant"
  ON public.campaigns FOR UPDATE
  USING (tenant_id = auth.jwt_claim('tenant_id')::UUID);

-- ===== PASSO 9: CRIAR ÍNDICES (PERFORMANCE) =====
CREATE INDEX IF NOT EXISTS idx_users_tenant ON public.users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant ON public.customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_tenant ON public.appointments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_time_slots_tenant ON public.time_slots(tenant_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_tenant ON public.campaigns(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_customer ON public.appointments(customer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(date_slot);

-- ===== PASSO 10: DATA DE EXEMPLO (OPCIONAL) =====
-- Descomente se quiser testar com dados

/*
-- Inserir um tenant de teste
INSERT INTO public.tenants (name, email, phone, cnpj, plan)
VALUES ('D10 Barbearia Teste', 'teste@d10.com', '(11) 98765-4321', '12345678000190', 'premium')
ON CONFLICT (name) DO NOTHING;

-- Inserir clientes de teste
INSERT INTO public.customers (tenant_id, name, email, phone)
SELECT id, 'João Silva', 'joao@email.com', '(11) 91234-5678'
FROM public.tenants WHERE name = 'D10 Barbearia Teste'
ON CONFLICT DO NOTHING;

-- Inserir horários disponíveis
INSERT INTO public.time_slots (tenant_id, date_slot, time_slot, barber)
SELECT id, CURRENT_DATE + INTERVAL '1 day', '09:00'::TIME, 'Barber 1'
FROM public.tenants WHERE name = 'D10 Barbearia Teste'
ON CONFLICT DO NOTHING;
*/

-- ===== ✅ SETUP COMPLETO! =====
-- Seu banco de dados multi-tenant está pronto!
--
-- Para cada novo cliente que você vender:
-- 1. INSERT em `tenants` (criar novo cliente)
-- 2. INSERT em `users` (criar login do admin da barbearia)
-- 3. Supabase Auth: criar usuário com token contendo tenant_id
--
-- O RLS garante que cada cliente vê APENAS seus dados!
-- ===== FIM =====
