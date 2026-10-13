# Local Supabase via Docker Container

We decided to host Supabase locally using a Docker container setup (`docker-compose.yml` / Supabase CLI) instead of relying solely on cloud-hosted Supabase SaaS. This provides a self-contained local backend, eliminates external hosting costs and latency during local development, allows direct local PostgreSQL inspections, and keeps all test sync workflows fully reproducible on the developer machine.
