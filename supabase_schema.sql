-- ====================================================================
-- HAYA EVENT MANAGEMENT - SUPABASE ROW-LEVEL SECURITY (RLS) FIX
-- Copy & Paste this entire script into your Supabase Dashboard -> SQL Editor and click RUN
-- ====================================================================

-- 1. DISABLE RLS TO ALLOW FULL ACCESS FOR ALL TABLES
ALTER TABLE public.enquiries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.venues DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_sections DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items DISABLE ROW LEVEL SECURITY;

-- 2. (OPTIONAL) CREATE PERMISSIVE POLICIES IF YOU WANT TO KEEP RLS ENABLED IN PRODUCTION
DROP POLICY IF EXISTS "Allow public access" ON public.enquiries;
CREATE POLICY "Allow public access" ON public.enquiries FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.events;
CREATE POLICY "Allow public access" ON public.events FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.tasks;
CREATE POLICY "Allow public access" ON public.tasks FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.customers;
CREATE POLICY "Allow public access" ON public.customers FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.payments;
CREATE POLICY "Allow public access" ON public.payments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.quotations;
CREATE POLICY "Allow public access" ON public.quotations FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.expenses;
CREATE POLICY "Allow public access" ON public.expenses FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.vendors;
CREATE POLICY "Allow public access" ON public.vendors FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.venues;
CREATE POLICY "Allow public access" ON public.venues FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.inventory;
CREATE POLICY "Allow public access" ON public.inventory FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.invoices;
CREATE POLICY "Allow public access" ON public.invoices FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.invoice_sections;
CREATE POLICY "Allow public access" ON public.invoice_sections FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access" ON public.invoice_items;
CREATE POLICY "Allow public access" ON public.invoice_items FOR ALL USING (true) WITH CHECK (true);
