-- ====================================================================
-- HAYA EVENT MANAGEMENT - SUPABASE DATABASE MIGRATION SCRIPT
-- Copy & Paste this entire script into Supabase SQL Editor and click RUN
-- ====================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. EVENTS TABLE
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    date TEXT NOT NULL,
    time TEXT NOT NULL,
    venue TEXT NOT NULL,
    guests INTEGER NOT NULL DEFAULT 0,
    manager TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planning', -- confirmed, planning, completed, cancelled
    contract_value NUMERIC NOT NULL DEFAULT 0,
    amount_received NUMERIC NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. TASKS TABLE
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    event_title TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'medium', -- high, medium, low
    is_completed BOOLEAN NOT NULL DEFAULT false,
    category TEXT NOT NULL DEFAULT 'Today',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. ENQUIRIES TABLE
CREATE TABLE IF NOT EXISTS public.enquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    total_date TEXT NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'newEnquiry', -- newEnquiry, quoted, followUp, contacted
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    total_events INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TEXT NOT NULL,
    event_type TEXT NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    method TEXT NOT NULL DEFAULT 'UPI', -- UPI, Bank Transfer, Cash, Credit Card
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. QUOTATIONS TABLE
CREATE TABLE IF NOT EXISTS public.quotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_number TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    date TEXT NOT NULL,
    total_amount NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Sent', -- Draft, Sent, Accepted, Rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. EXPENSES TABLE
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    category TEXT NOT NULL, -- Decor, Catering, Equipment, Logistics, Marketing
    amount NUMERIC NOT NULL DEFAULT 0,
    date TEXT NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'UPI',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. VENDORS TABLE
CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- Catering, Photography, Decor, Sound & Lighting, Florist
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    rating TEXT NOT NULL DEFAULT '5.0 ⭐',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 10. VENUES TABLE
CREATE TABLE IF NOT EXISTS public.venues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 0,
    price_per_day NUMERIC NOT NULL DEFAULT 0,
    contact_person TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 11. INVENTORY TABLE
CREATE TABLE IF NOT EXISTS public.inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_name TEXT NOT NULL,
    category TEXT NOT NULL, -- Furniture, Lighting, Audio Visual, Tableware
    quantity INTEGER NOT NULL DEFAULT 0,
    rental_price NUMERIC NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 12. INVOICES TABLE
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    venue TEXT NOT NULL,
    invoice_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    show_discount BOOLEAN NOT NULL DEFAULT false,
    discount_amount NUMERIC NOT NULL DEFAULT 0,
    show_tax BOOLEAN NOT NULL DEFAULT true,
    tax_percentage NUMERIC NOT NULL DEFAULT 18,
    show_advance_paid BOOLEAN NOT NULL DEFAULT false,
    advance_paid NUMERIC NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 13. INVOICE SECTIONS & ITEMS (RELATIONAL)
CREATE TABLE IF NOT EXISTS public.invoice_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number TEXT NOT NULL REFERENCES public.invoices(invoice_number) ON DELETE CASCADE,
    heading TEXT NOT NULL,
    section_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id UUID NOT NULL REFERENCES public.invoice_sections(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    qty NUMERIC,
    rate NUMERIC,
    price NUMERIC NOT NULL DEFAULT 0
);

-- 14. COMPANY SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.company_settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    company_name TEXT NOT NULL DEFAULT 'Haya Event Management',
    company_phone TEXT NOT NULL DEFAULT '+91 9747451938',
    company_email TEXT NOT NULL DEFAULT 'admin@hayaevents.com',
    company_address TEXT NOT NULL DEFAULT 'Central Avenue, Tech Park, Mumbai',
    company_gstin TEXT NOT NULL DEFAULT '27ABCDE1234F1Z5',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 15. USER PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- DISABLE ROW LEVEL SECURITY FOR ALL TABLES TO ALLOW FULL API ACCESS
ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiries DISABLE ROW LEVEL SECURITY;
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
ALTER TABLE public.company_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- SEED INITIAL COMPANY SETTINGS ROW
INSERT INTO public.company_settings (id, company_name, company_phone, company_email, company_address, company_gstin)
VALUES ('default', 'Haya Event Management', '+91 9747451938', 'admin@hayaevents.com', 'Central Avenue, Tech Park, Mumbai', '27ABCDE1234F1Z5')
ON CONFLICT (id) DO NOTHING;

-- SEED 2 USERS (ANEES & MUBEEN)
INSERT INTO public.user_profiles (username, email, full_name)
VALUES
('anees', 'anees@hayaevents.com', 'Anees'),
('mubeen', 'mubeen@hayaevents.com', 'Mubeen')
ON CONFLICT (username) DO NOTHING;
