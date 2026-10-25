ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuario FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS usuario_tenant_isolation ON public.usuario;

CREATE POLICY usuario_tenant_isolation
ON public.usuario
USING (
    tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid
)
WITH CHECK (
    tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid
);
