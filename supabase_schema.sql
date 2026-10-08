-- ====================================================================
-- HAYA EVENT MANAGEMENT - COMPLETE SUPABASE MIGRATION SCRIPT
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
    is_deleted BOOLEAN NOT NULL DEFAULT false,
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
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. ENQUIRIES TABLE
CREATE TABLE IF NOT EXISTS public.enquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL,
    total_date TEXT NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'newEnquiry', -- newEnquiry, quoted, followUp, contacted
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    total_events INTEGER NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date TEXT NOT NULL,
    event_type TEXT NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    method TEXT NOT NULL DEFAULT 'UPI', -- UPI, Bank Transfer, Cash, Credit Card
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. QUOTATIONS TABLE
CREATE TABLE IF NOT EXISTS public.quotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_number TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    venue TEXT NOT NULL DEFAULT '',
    event_type TEXT NOT NULL DEFAULT 'Wedding Event',
    date TEXT NOT NULL,
    due_date TEXT NOT NULL DEFAULT '25 Sep 2026',
    show_discount BOOLEAN NOT NULL DEFAULT false,
    discount_amount NUMERIC NOT NULL DEFAULT 0,
    show_tax BOOLEAN NOT NULL DEFAULT false,
    tax_percentage NUMERIC NOT NULL DEFAULT 18,
    show_advance_paid BOOLEAN NOT NULL DEFAULT false,
    advance_paid NUMERIC NOT NULL DEFAULT 0,
    manual_total_override BOOLEAN NOT NULL DEFAULT false,
    manual_grand_total NUMERIC NOT NULL DEFAULT 0,
    total_amount NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Sent', -- Draft, Sent, Accepted, Rejected
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- QUOTATION SECTIONS & ITEMS (RELATIONAL)
CREATE TABLE IF NOT EXISTS public.quotation_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_number TEXT NOT NULL REFERENCES public.quotations(quote_number) ON DELETE CASCADE,
    heading TEXT NOT NULL,
    section_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.quotation_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id UUID NOT NULL REFERENCES public.quotation_sections(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    qty NUMERIC,
    rate NUMERIC,
    price NUMERIC NOT NULL DEFAULT 0
);

-- 8. EXPENSES TABLE
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    category TEXT NOT NULL, -- Decor, Catering, Equipment, Logistics, Marketing
    amount NUMERIC NOT NULL DEFAULT 0,
    date TEXT NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'UPI',
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. VENDORS TABLE
CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- Catering, Photography, Decor, Sound & Lighting, Florist
    phone TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',
    rating TEXT NOT NULL DEFAULT '5.0 ⭐',
    is_deleted BOOLEAN NOT NULL DEFAULT false,
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
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 11. INVENTORY TABLE
CREATE TABLE IF NOT EXISTS public.inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_name TEXT NOT NULL,
    category TEXT NOT NULL, -- Furniture, Lighting, Audio Visual, Tableware
    quantity INTEGER NOT NULL DEFAULT 0,
    rental_price NUMERIC NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
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
    show_due_date BOOLEAN NOT NULL DEFAULT true,
    show_discount BOOLEAN NOT NULL DEFAULT false,
    discount_amount NUMERIC NOT NULL DEFAULT 0,
    show_tax BOOLEAN NOT NULL DEFAULT false,
    tax_percentage NUMERIC NOT NULL DEFAULT 18,
    show_advance_paid BOOLEAN NOT NULL DEFAULT false,
    advance_paid NUMERIC NOT NULL DEFAULT 0,
    manual_total_override BOOLEAN NOT NULL DEFAULT false,
    manual_grand_total NUMERIC NOT NULL DEFAULT 0,
    total_amount NUMERIC NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
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
    company_email TEXT NOT NULL DEFAULT 'hayaeventmanagement.info@gmail.com',
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

-- 16. MIGRATION COLUMNS FOR ALL EXISTING TABLES (RUN THIS TO UPDATE EXISTING SCHEMAS)
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS code TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS date TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS time TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS venue TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS guests INTEGER DEFAULT 0;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS manager TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'planning';
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS contract_value NUMERIC DEFAULT 0;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS amount_received NUMERIC DEFAULT 0;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS event_title TEXT;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'medium';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'Today';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS total_date TEXT;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS amount NUMERIC DEFAULT 0;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'newEnquiry';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS email TEXT DEFAULT '';
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS total_events INTEGER DEFAULT 0;
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS date TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS event_type TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS amount NUMERIC DEFAULT 0;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS method TEXT DEFAULT 'UPI';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS quote_number TEXT;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS venue TEXT NOT NULL DEFAULT '';
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS due_date TEXT NOT NULL DEFAULT '25 Sep 2026';
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS event_type TEXT NOT NULL DEFAULT 'Wedding Event';
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS date TEXT;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'Sent';
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS show_discount BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS discount_amount NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS show_tax BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS tax_percentage NUMERIC NOT NULL DEFAULT 18;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS show_advance_paid BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS advance_paid NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS manual_total_override BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS manual_grand_total NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS total_amount NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS amount NUMERIC DEFAULT 0;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS date TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'UPI';
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS email TEXT DEFAULT '';
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS rating TEXT DEFAULT '5.0 ⭐';
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS capacity INTEGER DEFAULT 0;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS price_per_day NUMERIC DEFAULT 0;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS contact_person TEXT;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS item_name TEXT;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 0;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS rental_price NUMERIC DEFAULT 0;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS invoice_number TEXT;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS venue TEXT NOT NULL DEFAULT '';
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS invoice_date TEXT;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS due_date TEXT NOT NULL DEFAULT '';
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS show_due_date BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS show_discount BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS discount_amount NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS show_tax BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS tax_percentage NUMERIC NOT NULL DEFAULT 18;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS show_advance_paid BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS advance_paid NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS manual_total_override BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS manual_grand_total NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS total_amount NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;

-- DISABLE ROW LEVEL SECURITY FOR ALL TABLES TO ALLOW FULL API ACCESS
ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotation_sections DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotation_items DISABLE ROW LEVEL SECURITY;
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
VALUES ('default', 'Haya Event Management', '+91 9747451938', 'hayaeventmanagement.info@gmail.com', 'Central Avenue, Tech Park, Mumbai', '27ABCDE1234F1Z5')
ON CONFLICT (id) DO NOTHING;

-- SEED 2 USERS (ANEES & MUBEEN)
INSERT INTO public.user_profiles (username, email, full_name)
VALUES
('anees', 'anees@hayaevents.com', 'Anees'),
('mubeen', 'mubeen@hayaevents.com', 'Mubeen')
ON CONFLICT (username) DO NOTHING;
