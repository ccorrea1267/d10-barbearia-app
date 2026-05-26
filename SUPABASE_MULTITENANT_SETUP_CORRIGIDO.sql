-- 🏗️ SETUP MULTI-TENANT +D10 Barbearia (VERSÃO CORRIGIDA v2)
-- Cole TUDO isso no Supabase SQL Editor e execute

-- ===== PASSO 1: CRIAR TODAS AS TABELAS PRIMEIRO =====

CREATE TABLE IF NOT EXISTS public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL UNIQUE,
  email VARCHAR NOT NULL UNIQUE,
  phone VARCHAR,
  address VARCHAR,
  city VARCHAR,
  state VARCHAR,
  cnpj VARCHAR UNIQUE,
  plan VARCHAR DEFAULT 'free',
  subscription_date TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  role VARCHAR DEFAULT 'staff',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, email)
);

CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR NOT NULL,
  email VARCHAR,
  phone VARCHAR,
  cpf VARCHAR,
  preferred_barber VARCHAR,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, email)
);

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

CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  date_slot DATE NOT NULL,
  time_slot TIME NOT NULL,
  barber VARCHAR NOT NULL,
  service VARCHAR NOT NULL,
  status VARCHAR DEFAULT 'pending',
  notes TEXT,
  reminder_sent BOOLEAN DEFAULT false,
  whatsapp_confirmed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  message TEXT NOT NULL,
  campaign_type VARCHAR DEFAULT 'custom',
  scheduled_date TIMESTAMP,
  sent_date TIMESTAMP,
  status VARCHAR DEFAULT 'draft',
  sent_to_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ===== PASSO 2: CRIAR ÍNDICES =====
CREATE INDEX IF NOT EXISTS idx_users_tenant ON public.users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_auth ON public.users(auth_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant ON public.customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_tenant ON public.appointments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_time_slots_tenant ON public.time_slots(tenant_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_tenant ON public.campaigns(tenant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_customer ON public.appointments(customer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(date_slot);

-- ===== PASSO 3: CRIAR FUNÇÃO (AGORA QUE A TABELA EXISTE) =====
CREATE OR REPLACE FUNCTION get_current_tenant_id()
RETURNS UUID AS $$
  SELECT tenant_id FROM public.users WHERE auth_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- ===== PASSO 4: HABILITAR ROW LEVEL SECURITY =====
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

-- ===== PASSO 5: CRIAR POLICIES RLS =====

-- TENANTS
DROP POLICY IF EXISTS "Tenants see only themselves" ON public.tenants;
CREATE POLICY "Tenants see only themselves"
  ON public.tenants FOR SELECT
  USING (id = get_current_tenant_id());

DROP POLICY IF EXISTS "Tenants can update themselves" ON public.tenants;
CREATE POLICY "Tenants can update themselves"
  ON public.tenants FOR UPDATE
  USING (id = get_current_tenant_id());

-- USERS
DROP POLICY IF EXISTS "Users see only their tenant users" ON public.users;
CREATE POLICY "Users see only their tenant users"
  ON public.users FOR SELECT
  USING (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Users can insert in their tenant" ON public.users;
CREATE POLICY "Users can insert in their tenant"
  ON public.users FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Users can update their records" ON public.users;
CREATE POLICY "Users can update their records"
  ON public.users FOR UPDATE
  USING (tenant_id = get_current_tenant_id());

-- CUSTOMERS
DROP POLICY IF EXISTS "Customers are isolated by tenant" ON public.customers;
CREATE POLICY "Customers are isolated by tenant"
  ON public.customers FOR SELECT
  USING (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Customers can be inserted by tenant" ON public.customers;
CREATE POLICY "Customers can be inserted by tenant"
  ON public.customers FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Customers can be updated by tenant" ON public.customers;
CREATE POLICY "Customers can be updated by tenant"
  ON public.customers FOR UPDATE
  USING (tenant_id = get_current_tenant_id());

-- TIME_SLOTS
DROP POLICY IF EXISTS "Time slots are isolated by tenant" ON public.time_slots;
CREATE POLICY "Time slots are isolated by tenant"
  ON public.time_slots FOR SELECT
  USING (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Time slots can be inserted by tenant" ON public.time_slots;
CREATE POLICY "Time slots can be inserted by tenant"
  ON public.time_slots FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Time slots can be updated by tenant" ON public.time_slots;
CREATE POLICY "Time slots can be updated by tenant"
  ON public.time_slots FOR UPDATE
  USING (tenant_id = get_current_tenant_id());

-- APPOINTMENTS
DROP POLICY IF EXISTS "Appointments are isolated by tenant" ON public.appointments;
CREATE POLICY "Appointments are isolated by tenant"
  ON public.appointments FOR SELECT
  USING (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Appointments can be inserted by tenant" ON public.appointments;
CREATE POLICY "Appointments can be inserted by tenant"
  ON public.appointments FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Appointments can be updated by tenant" ON public.appointments;
CREATE POLICY "Appointments can be updated by tenant"
  ON public.appointments FOR UPDATE
  USING (tenant_id = get_current_tenant_id());

-- CAMPAIGNS
DROP POLICY IF EXISTS "Campaigns are isolated by tenant" ON public.campaigns;
CREATE POLICY "Campaigns are isolated by tenant"
  ON public.campaigns FOR SELECT
  USING (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Campaigns can be inserted by tenant" ON public.campaigns;
CREATE POLICY "Campaigns can be inserted by tenant"
  ON public.campaigns FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

DROP POLICY IF EXISTS "Campaigns can be updated by tenant" ON public.campaigns;
CREATE POLICY "Campaigns can be updated by tenant"
  ON public.campaigns FOR UPDATE
  USING (tenant_id = get_current_tenant_id());

-- ===== ✅ SETUP COMPLETO! =====
-- Seu banco está pronto para vender!
