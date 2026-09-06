# 🏛️ Universal Ecosystem Naming Conventions

This document establishes the official cross-platform naming convention standards for the ecosystem (**Core**, **Web**, and **Mobile**). It covers both **single-word** and **multi-word** brands to ensure 100% architectural and operational consistency across all infrastructure and code layers.

---

## 1. Golden Rules of Transformation

When branding or rebranding an application, the target brand name generates 4 fundamental forms:

| Form | Syntax | Example (Single Word: `Nova`) | Example (Multi Word: `Pulse Flow`) | Target Environments & Use Cases |
| :--- | :--- | :--- | :--- | :--- |
| **Title / Display** | `Title Case` (with spaces) | `Nova` | `Pulse Flow` | UI Headers, Emails, Mobile Display Name, Page Titles |
| **Kebab-Slug** | `kebab-case` (`[a-z0-9-]`) | `nova` | `pulse-flow` | **Docker Containers**, **Docker Networks & Volumes**, **S3 Buckets**, **npm packages**, **URL paths** |
| **Snake-Slug** | `snake_case` (`[a-z0-9_]`) | `nova` | `pulse_flow` | **PostgreSQL Databases**, **Dart Package Name**, internal database roles, Ruby symbols |
| **Flat-Slug** | `lowercase` (`[a-z0-9]`) | `nova` | `pulseflow` | **Mobile Bundle ID / Android ApplicationId**, DNS subdomains (`pulseflow.me`) |
| **Pascal-Slug** | `PascalCase` (`[A-Za-z0-9]`) | `Nova` | `PulseFlow` | Ruby Application Module (`PulseFlowCore`), TypeScript interfaces |

---

## 2. Infrastructure & Docker Naming Standard

### A. Docker Containers
Docker container names must strictly follow **kebab-case**.
> **Why?** Docker container names function as internal DNS hostnames within Docker user-defined networks (RFC 1123 / RFC 1035). Hyphens (`-`) are standard and valid in DNS hostnames, whereas underscores (`_`) violate DNS hostname specifications and can cause proxy/reverse-proxy routing failures.

- **Role Preservation**: Suffixes and roles (`api`, `waka`, `media`, `db`, `garage`, `web`) are immutable. Only the project/brand prefix is replaced.

| Component | Dev Container Name | Production Container Name (Coolify) |
| :--- | :--- | :--- |
| **Rails API** | `dev-<kebab>-core-api` *(e.g. `dev-pulse-flow-core-api`)* | `prod-<kebab>-api` *(e.g. `prod-pulse-flow-api`)* |
| **Solid Queue Worker** | `dev-<kebab>-core-waka` *(e.g. `dev-pulse-flow-core-waka`)* | `prod-<kebab>-waka` *(e.g. `prod-pulse-flow-waka`)* |
| **Media Transcoder** | `dev-<kebab>-core-media` *(e.g. `dev-pulse-flow-core-media`)* | `prod-<kebab>-media` *(e.g. `prod-pulse-flow-media`)* |
| **PostgreSQL Database** | `dev-<kebab>-core-db` *(e.g. `dev-pulse-flow-core-db`)* | `prod-<kebab>-db` *(e.g. `prod-pulse-flow-db`)* |
| **Garage S3 Storage** | `dev-<kebab>-core-garage` *(e.g. `dev-pulse-flow-core-garage`)* | `<kebab>-garage` *(e.g. `pulse-flow-garage`)* |
| **Web Client** | `dev-<kebab>-web` *(e.g. `dev-pulse-flow-web`)* | `prod-<kebab>-web` *(e.g. `prod-pulse-flow-web`)* |

### B. Docker Networks & Volumes
- **Network**: `prod-<kebab>-net` *(e.g. `prod-pulse-flow-net`)*
- **Postgres Volume**: `prod-<kebab>-postgres-data` *(e.g. `prod-pulse-flow-postgres-data`)*
- **Garage Meta Volume**: `<kebab>-garage-meta` *(e.g. `pulse-flow-garage-meta`)*
- **Garage Data Volume**: `<kebab>-garage-data` *(e.g. `pulse-flow-garage-data`)*

---

## 3. Database (PostgreSQL) Naming Standard

PostgreSQL database names must strictly follow **snake_case**.
> **Why?** SQL identifier standards treat hyphens (`-`) as arithmetic subtraction operators. Naming a database `pulse-flow_db` forces every tool, psql script, and ActiveRecord connection to wrap the name in quotes (`"pulse-flow_db"`), frequently breaking URI connection string parsers (`postgres://.../pulse-flow_development`). Snake_case (`pulse_flow_...`) is the universal standard.

- **Development**: `<snake>_core_development` *(e.g. `pulse_flow_core_development`)*
- **Test**: `<snake>_core_test` *(e.g. `pulse_flow_core_test`)*
- **Production**: `<snake>_production` *(e.g. `pulse_flow_production`)*

---

## 4. Object Storage (S3 / Garage) Standard

Bucket names must strictly follow **kebab-case** (or flat lowercase).
> **Why?** Amazon S3 and S3-compatible storage engines (like Garage) strictly mandate DNS-compliant bucket names (`^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$`). Underscores (`_`) are prohibited by S3 specification.

- **Primary Project Bucket**: `<kebab>` *(e.g. `pulse-flow`)*
- **Partition Folders**:
  - Development: `<kebab>/dev/`
  - UAT: `<kebab>/uat/`
  - Production: `<kebab>/prod/`

---

## 5. Web Client (React + Vite) Standard

- **`package.json` `name`**: `<kebab>-web` *(e.g. `pulse-flow-web`)*
- **Browser Title**: `<Title> Web` or `<Title> — Product Foundation` *(e.g. `Pulse Flow — Product Foundation`)*
- **`VITE_REACT_APP_NAME`**: `<Title>` *(e.g. `Pulse Flow`)*
- **Default Domains**: `https://<flat>.me` and `https://api.<flat>.me`

---

## 6. Mobile Client (Flutter) Standard

- **App Label / Display Name**: `<Title> Mobile` *(e.g. `Pulse Flow Mobile`)*
- **Android `applicationId` / iOS Bundle Identifier**: `com.<company>.<flat>` *(e.g. `com.rex9.pulseflow`)*
  > **Why?** Android package names prohibit hyphens (`-`). They only permit lowercase letters, numbers, and dots (`[a-z0-9_.]`).
- **Internal Dart Package Name**: `pubspec.yaml` name must be a valid Dart identifier (`snake_case` only, e.g. `pulse_flow_mobile` or keeping the base package).
- **Repository Folder Name**: While Flutter forbids `-` inside `pubspec.yaml` `name`, the repository/folder name follows the ecosystem convention (`<kebab>-mobile` or `<snake>_mobile`).

---

## 7. Summary Matrix

```
User Input: "Pulse Flow"
 ├── Title:      Pulse Flow
 ├── Kebab:      pulse-flow   ──> Docker containers, compose, networks, volumes, S3 bucket, web package
 ├── Snake:      pulse_flow   ──> PostgreSQL databases, SQL identifiers, Dart package name
 ├── Flat:       pulseflow    ──> Mobile package ID / Bundle ID, domains
 └── Pascal:     PulseFlow    ──> Ruby module, TypeScript interfaces
```
