-- ==============================================================================
-- API FAILURE TWIN - SUPABASE POSTGRESQL SCHEMA WITH ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    company TEXT,
    role TEXT DEFAULT 'Site Reliability Engineer',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PROJECTS TABLE
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_demo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SERVICES TABLE
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    service_key TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('frontend', 'gateway', 'service', 'database', 'external_api', 'cache', 'queue')),
    criticality TEXT NOT NULL CHECK (criticality IN ('TIER_0', 'TIER_1', 'TIER_2', 'TIER_3')),
    status TEXT NOT NULL DEFAULT 'HEALTHY' CHECK (status IN ('HEALTHY', 'DEGRADED', 'FAILING', 'MITIGATED')),
    avg_latency_ms INTEGER DEFAULT 45,
    error_rate_pct NUMERIC(5,2) DEFAULT 0.02,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. DEPENDENCIES TABLE
CREATE TABLE IF NOT EXISTS public.dependencies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    source_service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    target_service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    critical BOOLEAN NOT NULL DEFAULT TRUE,
    protocol TEXT DEFAULT 'HTTPS/REST',
    timeout_ms INTEGER DEFAULT 3000,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_service_dependency UNIQUE (source_service_id, target_service_id)
);

-- 5. FEATURES TABLE
CREATE TABLE IF NOT EXISTS public.features (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    feature_key TEXT NOT NULL,
    description TEXT,
    criticality TEXT NOT NULL CHECK (criticality IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. FEATURE_DEPENDENCIES TABLE
CREATE TABLE IF NOT EXISTS public.feature_dependencies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_id UUID NOT NULL REFERENCES public.features(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    critical BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT unique_feature_service UNIQUE (feature_id, service_id)
);

-- 7. SCENARIOS TABLE
CREATE TABLE IF NOT EXISTS public.scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    target_service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    failure_type TEXT NOT NULL CHECK (failure_type IN ('HTTP_500', 'HTTP_429', 'TIMEOUT', 'HIGH_LATENCY', 'SCHEMA_MISMATCH')),
    severity TEXT NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    duration_seconds INTEGER DEFAULT 30,
    configuration JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. SIMULATIONS TABLE
CREATE TABLE IF NOT EXISTS public.simulations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    scenario_id UUID REFERENCES public.scenarios(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED')),
    impact_score INTEGER NOT NULL,
    risk_level TEXT NOT NULL CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    affected_services JSONB NOT NULL DEFAULT '[]'::jsonb,
    affected_features JSONB NOT NULL DEFAULT '[]'::jsonb,
    cascade_depth INTEGER NOT NULL DEFAULT 1,
    critical_dependencies_breached INTEGER DEFAULT 0,
    simulation_result JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. MITIGATIONS TABLE
CREATE TABLE IF NOT EXISTS public.mitigations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID NOT NULL REFERENCES public.simulations(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    reason TEXT NOT NULL,
    expected_effect TEXT NOT NULL,
    score_reduction_pct INTEGER DEFAULT 0,
    applied BOOLEAN DEFAULT FALSE,
    result_comparison JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. INCIDENTS TABLE
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    simulation_id UUID REFERENCES public.simulations(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('DETECTED', 'PROPAGATING', 'CONTAINED', 'MITIGATED', 'RESOLVED')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    summary TEXT,
    timeline JSONB DEFAULT '[]'::jsonb
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.features ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.simulations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mitigations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;

-- 1. Profiles: Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. Projects: Owners can CRUD their projects
CREATE POLICY "Owners can view own projects or demo" ON public.projects
    FOR SELECT USING (auth.uid() = owner_id OR is_demo = TRUE);

CREATE POLICY "Owners can insert own projects" ON public.projects
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update own projects" ON public.projects
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete own projects" ON public.projects
    FOR DELETE USING (auth.uid() = owner_id);

-- Helper expression for project ownership check:
-- EXISTS (SELECT 1 FROM public.projects WHERE projects.id = table.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))

-- 3. Services: Access tied to project ownership
CREATE POLICY "Users can view project services" ON public.services
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = services.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can modify project services" ON public.services
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = services.project_id AND projects.owner_id = auth.uid())
    );

-- 4. Dependencies: Access tied to project ownership
CREATE POLICY "Users can view project dependencies" ON public.dependencies
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = dependencies.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can modify project dependencies" ON public.dependencies
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = dependencies.project_id AND projects.owner_id = auth.uid())
    );

-- 5. Features
CREATE POLICY "Users can view project features" ON public.features
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = features.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can modify project features" ON public.features
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = features.project_id AND projects.owner_id = auth.uid())
    );

-- 6. Feature Dependencies
CREATE POLICY "Users can view feature dependencies" ON public.feature_dependencies
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.features JOIN public.projects ON projects.id = features.project_id 
                WHERE features.id = feature_dependencies.feature_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can modify feature dependencies" ON public.feature_dependencies
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.features JOIN public.projects ON projects.id = features.project_id 
                WHERE features.id = feature_dependencies.feature_id AND projects.owner_id = auth.uid())
    );

-- 7. Scenarios
CREATE POLICY "Users can view project scenarios" ON public.scenarios
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = scenarios.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can modify project scenarios" ON public.scenarios
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = scenarios.project_id AND projects.owner_id = auth.uid())
    );

-- 8. Simulations
CREATE POLICY "Users can view project simulations" ON public.simulations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = simulations.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can insert project simulations" ON public.simulations
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = simulations.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

-- 9. Mitigations
CREATE POLICY "Users can view mitigations" ON public.mitigations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.simulations JOIN public.projects ON projects.id = simulations.project_id 
                WHERE simulations.id = mitigations.simulation_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Users can insert mitigations" ON public.mitigations
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.simulations JOIN public.projects ON projects.id = simulations.project_id 
                WHERE simulations.id = mitigations.simulation_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

-- 10. Incidents
CREATE POLICY "Users can view project incidents" ON public.incidents
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = incidents.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

CREATE POLICY "Owners can modify project incidents" ON public.incidents
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.projects WHERE projects.id = incidents.project_id AND (projects.owner_id = auth.uid() OR projects.is_demo = TRUE))
    );

-- Trigger for automatically creating profile upon auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'System Architect'),
        COALESCE(new.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
