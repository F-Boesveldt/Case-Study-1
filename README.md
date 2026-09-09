# Case Study 1 — Scalable Web/DB Environment (Flavor A)

Infrastructure-as-code for the CS1 case study. See the Analysis Document
and Design Document for the full requirements mapping, architecture
reasoning, and TCO analysis behind these choices.

## Structure

- `terraform/` — root config, wires together the modules below
- `terraform/modules/network` — hub-and-spoke VNet, subnets, NSGs, UDRs
- `terraform/modules/compute` — web tier (VM Scale Set + load balancer)
- `terraform/modules/monitoring` — Prometheus/Grafana VM
- `.github/workflows/terraform.yml` — CI/CD pipeline (plan on PR, apply on merge to main)

## Getting started

1. Create the remote state storage account (see the comment at the top of
   `terraform/backend.tf`) and fill in the storage account name there.
2. Set the following as GitHub Actions secrets (Settings → Secrets and
   variables → Actions): `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`,
   `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, `ADMIN_SSH_PUBLIC_KEY`,
   `DB_ADMIN_PASSWORD`.
3. Locally: `cd terraform && terraform init && terraform plan`.

## Status

Week 1 skeleton — network module is fully specified per the Design
Document; compute and monitoring modules are scaffolded with TODOs for
Week 2/3 implementation work (cloud-init configs, autoscale rules,
Prometheus scrape config, MySQL Flexible Server).
