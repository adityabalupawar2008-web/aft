# API Failure Twin 🛡️⚡

> **"Simulate the failure. See the blast radius. Fix it before users feel it."**

API Failure Twin is an explainable, dependency-aware digital twin that simulates upstream and downstream API failures, visualizes the blast radius across microservices, maps technical failures to user-facing features (Checkout, Live Map Tracking, User Auth), recommends architectural mitigations, and quantitatively compares the system before and after mitigation.

---

## 🏆 Product Differentiation

Traditional chaos engineering injects destructive failures into live staging or production clusters. **API Failure Twin** is a pre-production digital twin that:
1. **Models Dependencies:** Visualizes caller-callee topologies, criticality tiers (Tier 0 to Tier 3), and network protocols.
2. **Deterministic Fault Injection:** Simulates `HTTP 500`, `HTTP 429`, `TIMEOUT`, `HIGH LATENCY`, and `SCHEMA MISMATCH` without risking production.
3. **Explains Downstream Causality:** Explains in plain English *why* a customer feature broke via an explicit causal dependency chain.
4. **Resilience Synthesis:** Recommends concrete patterns (Circuit Breakers, Adaptive Queues, Stale Caches, Contract Validation).
5. **Before / After Verification:** Re-simulates with active mitigation to verify blast radius reduction with side-by-side metric deltas.

---

## 🚀 Quick Start (One Command)

### Prerequisites
- Node.js LTS (v18+) & npm

### Installation & Run
```bash
# 1. Clone repository
git clone https://github.com/your-username/api-failure-twin.git
cd api-failure-twin

# 2. Install dependencies
npm install

# 3. Start development server (or production build)
npm run dev
# or for optimized production server:
npm run build && npm start
```

Visit **[http://localhost:3000](http://localhost:3000)** in your browser.

---

## 🧭 Live Demo Evaluation Walkthrough (3-Minute Judge Script)

| Step | Action | What Judges See |
|---|---|---|
| **1** | Open `/dashboard` | System status: `SYSTEM HEALTHY`, 2 active twin projects, monitored nodes. |
| **2** | Click **"Instant Demo"** or open `/workspace/proj-ecommerce-core` | Full cockpit with 12 microservice nodes rendered in React Flow. |
| **3** | Click **"Payment API — HTTP 429 Rate Limiting"** scenario | Fault injected into Payment API. |
| **4** | Click **"SIMULATE FAILURE"** | Upstream cascade propagates: `Payment API 🔴` → `Payment Service 🔴` → `Order Service 🔴` → `API Gateway 🔴` → `Checkout OUTAGE 🔴`. |
| **5** | Inspect **Blast Radius Panel** | Impact Score: `100 / 100`, Risk: `CRITICAL`, Depth: `4 hops`, `4` critical dependencies breached. |
| **6** | Click **"Why Affected?"** tab | Automated causal trace: `Why is Checkout affected? Internal Payment Orchestrator depends on Stripe Acquirer...`. |
| **7** | Click **"Mitigations"** tab | Recommends `Adaptive Priority Queue + Exponential Backoff with Jitter` with code snippet. |
| **8** | Click **"APPLY MITIGATION & RE-SIMULATE"** | Cockpit re-simulates in < 300ms with resilience policy engaged. |
| **9** | Inspect **Before vs After Modal** | Side-by-side table: Services saved: `4 → 1`, Features saved: `1 → 0`, Impact Score: `100 → 24` (-76 pts), MTTR: `45s → 4s`. Fireworks! |
| **10** | Click **"Replay Last Simulation"** | Re-executes identical deterministic simulation inputs. |

---

## 🏗️ Architecture & Tech Stack

```text
┌─────────────────────────────────────────────────────────────┐
│                 Next.js 14 App Router (React 18)            │
├──────────────────────────────┬──────────────────────────────┤
│ Frontend Presentation        │ Server-Side APIs             │
│ • Tailwind CSS & Dark Obsidian│ • /api/simulate             │
│ • React Flow (@xyflow/react) │ • /api/projects              │
│ • Recharts & Lucide Icons    │ • SSR Auth Cookie Sessions   │
└──────────────┬───────────────┴──────────────┬───────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────────┐┌─────────────────────────────┐
│ Deterministic Twin Engine    ││ Supabase Cloud Backend      │
│ • Reverse BFS Graph Traversal││ • PostgreSQL Database       │
│ • Criticality Tier Inversion ││ • Row Level Security (RLS)  │
│ • Deterministic Scoring      ││ • Supabase Auth             │
│ • Mitigation Synthesis       ││ • Isolated Server Secrets   │
└──────────────────────────────┘└─────────────────────────────┘
```

- **Frontend:** Next.js 14, React 18, TypeScript, Tailwind CSS, `@xyflow/react`, `recharts`, `lucide-react`, `canvas-confetti`.
- **Backend:** Next.js Server-Side Route Handlers (`/api/simulate`, `/api/projects`).
- **Database & Auth:** Supabase PostgreSQL with 10 tables, triggers, and Row Level Security (RLS).
- **Digital Twin Engine:** Zero-external-dependency TypeScript topological graph traversal and impact scoring.

---

## 🔒 Security & Credential Isolation

- **Client Browser Code:** Strictly limited to `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.
- **Server Code:** `SUPABASE_SECRET_KEY` remains backend-only and is never prefixed with `NEXT_PUBLIC_`.
- **Row Level Security (RLS):** Enabled on all 10 database tables. Users can only query and mutate their own private projects.
- **Simulation Sandbox:** Synthetic metadata simulation with zero production destructive payloads.

---

## 🗄️ Database Setup (Supabase PostgreSQL)

A complete SQL migration script is provided in [`schema.sql`](file:///c:/Users/Adity/OneDrive/Desktop/project%20touch/schema.sql).

1. Create a project at [supabase.com](https://supabase.com).
2. Go to **SQL Editor** in the Supabase Dashboard.
3. Paste the contents of `schema.sql` and click **Run**.
4. Copy your project credentials into `.env.local`:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SECRET_KEY=your-secret-key
   ```
5. *(Optional)* If no Supabase credentials are configured, the application automatically runs in **Zero-Config Demo Mode** with full offline persistence!

---

## 🌐 Public Pages Sitemap

- `/` — Master Landing Page (Hero, Scenarios, Problem/Solution, Workflow, Security, FAQ, CTA)
- `/features` — Deep-dive product capabilities
- `/how-it-works` — Architectural 5-step walkthrough & mathematical formula
- `/security` — Honest security architecture & compliance posture
- `/pricing` — Community, Team, and Enterprise plans
- `/about` — Engineering philosophy & mission
- `/contact` — Engineering feedback form
- `/terms` — Terms & Conditions (Strict simulation-only disclaimers)
- `/privacy` — Privacy Policy (Transparent data retention & disclosures)
- `/cookie-policy` — Cookie Policy (Essential authentication cookies only)
- `/acceptable-use` — Acceptable Use Policy (Prohibiting unauthorized attacks)
- `/dashboard` — Projects & Digital Twins management
- `/workspace/[projectId]` — Master digital twin cockpit

---

## 📄 License

MIT License. Designed and engineered for the Hackathon 2026.
