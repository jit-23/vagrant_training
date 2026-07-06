# `microservice/` — GitLab with external Postgres and Redis

This directory deploys GitLab as three separate Kubernetes workloads instead of
GitLab's default "omnibus" mode, where Postgres and Redis run bundled *inside*
the same container/process as GitLab itself:

```
microservice/
├── namespace.yaml           # 1 Namespace object
├── postgres/postgres.yaml   # 1 Secret, 1 Service, 1 StatefulSet
├── redis/redis.yaml         # 1 Service, 1 StatefulSet
└── gitlab/gitlab.yaml       # 3 PersistentVolumeClaims, 1 Service, 1 Deployment
```

GitLab's own container still runs the omnibus image (it bundles the Rails
app, Sidekiq workers, Puma, Workhorse, etc. into one image — splitting *that*
apart is a much bigger undertaking than this exercise), but it is configured
via `GITLAB_OMNIBUS_CONFIG` to disable its **bundled** Postgres and Redis
processes and instead talk to the standalone `postgres` and `redis`
Kubernetes Services defined in the other two files. That's what "external
Redis and Postgres" means here: external to the GitLab container, but still
inside the same cluster and namespace.

All four manifests share one thing that ties them together: every object
lives in `namespace: microservice`, and Service names become resolvable DNS
names within that namespace via Kubernetes' internal DNS (CoreDNS/kube-dns).
That DNS resolution is the *entire* mechanism by which these three workloads
"connect" to each other — there are no IPs hardcoded anywhere.

---

## 1. `namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservice
```

| Line | Meaning |
|---|---|
| `apiVersion: v1` | `Namespace` is a core API object, so it lives in the unversioned/legacy `v1` group (no `apps/`, `batch/`, etc. prefix). |
| `kind: Namespace` | Declares this object as a Namespace — a logical partition inside the cluster that scopes names, RBAC, resource quotas, and network policies. |
| `metadata.name: microservice` | The namespace's name. Every other manifest in this directory sets `metadata.namespace: microservice`, placing all objects inside this partition. |

**Why it exists:** every namespaced object (Secret, Service, StatefulSet,
Deployment, PVC) needs a namespace to live in. Applying this file first
creates that home. If you skip it and just `kubectl apply -f gitlab/...`,
the other manifests would fail with `namespaces "microservice" not found`
(unless a namespace by that name already exists another way, e.g. via
`kubectl create namespace`).

It also matters for DNS: Kubernetes Service DNS names are namespace
qualified. A Service named `postgres` in namespace `microservice` is
reachable in-cluster as `postgres.microservice.svc.cluster.local` (or just
`postgres` from another pod *in the same namespace*, thanks to the
per-namespace DNS search path). This is exactly the hostname used in
`gitlab/gitlab.yaml`'s `GITLAB_OMNIBUS_CONFIG`.

---

## 2. `postgres/postgres.yaml`

Three objects, separated by `---` YAML document separators (each `---`
starts a new object that `kubectl apply -f` applies independently).

### 2.1 — the `Secret` (lines 1–10)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: microservice
type: Opaque
stringData:
  POSTGRES_USER: gitlab
  POSTGRES_PASSWORD: gitlab-postgres-pass
  POSTGRES_DB: gitlabhq_production
```

| Line | Meaning |
|---|---|
| `kind: Secret` | A Secret object — a key/value store meant for sensitive data. It is stored base64-encoded (not encrypted, unless the cluster has encryption-at-rest configured) inside etcd. |
| `metadata.name: postgres-secret` | The name other objects use to reference this Secret (`secretKeyRef.name`, `secretRef.name`). |
| `metadata.namespace: microservice` | Secrets are namespaced — a pod can only mount/reference a Secret that lives in its own namespace. |
| `type: Opaque` | The generic Secret type — "just arbitrary key/value data," as opposed to specialized types like `kubernetes.io/tls` or `kubernetes.io/dockerconfigjson`. |
| `stringData:` | A *write-only* convenience field. You write plaintext strings here; the API server base64-encodes them into `data:` on save. (If you `kubectl get secret -o yaml` afterward, you'll see `data:` with base64 values, not this `stringData:` block — it's not stored as-is.) |
| `POSTGRES_USER: gitlab` | The Postgres role name the `postgres:15` image will create on first boot (the official Postgres image reads this exact env var name at container startup to bootstrap the DB). |
| `POSTGRES_PASSWORD: gitlab-postgres-pass` | The password for that role. **This is a placeholder for a training exercise** — in anything beyond a lab, generate this randomly and never commit it to git. |
| `POSTGRES_DB: gitlabhq_production` | The database name to auto-create on first boot. `gitlabhq_production` is GitLab's own convention/expectation for its production database name. |

**How it's consumed:** two different ways, by two different workloads —
this is the crux of "how the manifests relate to each other":

1. **By Postgres itself** (`postgres/postgres.yaml` StatefulSet, `envFrom.secretRef`, line 46–48) — the `postgres:15` container reads `POSTGRES_USER`/`POSTGRES_PASSWORD`/`POSTGRES_DB` as env vars at first startup to initialize the database cluster (create the role, create the DB, set the password).
2. **By GitLab** (`gitlab/gitlab.yaml`, `secretKeyRef`, lines 77–81) — GitLab needs to know that *same* password to authenticate against Postgres as a client. Rather than duplicating the plaintext password into the GitLab manifest, it re-reads the *same* Secret key (`POSTGRES_PASSWORD`) so there's a single source of truth for the credential.

### 2.2 — the `Service` (lines 12–23)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: microservice
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
```

| Line | Meaning |
|---|---|
| `kind: Service` | A stable network identity/load-balancer object. Pods are ephemeral and get new IPs when rescheduled; a Service gives callers a fixed name/IP to talk to regardless of which pod is currently backing it. |
| `metadata.name: postgres` | This becomes the DNS name: `postgres.microservice.svc.cluster.local` (or short form `postgres` in-namespace). **This exact string is hardcoded as `gitlab_rails['db_host']` in `gitlab/gitlab.yaml` line 88.** That line is the literal connection between the two files. |
| `spec.clusterIP: None` | Makes this a **headless Service**. Instead of getting one virtual cluster IP that load-balances across replicas, DNS lookups return the pod IP(s) directly. This is the conventional pairing for a `StatefulSet` — `spec.serviceName` on a StatefulSet (see below) *must* point at a headless Service, because each StatefulSet pod gets its own stable, individually-addressable DNS record (`postgres-0.postgres.microservice.svc.cluster.local`). For a single-replica DB this mostly matters as "the correct pattern to use," since with `replicas: 1` there's only one pod to resolve to anyway. |
| `spec.selector.app: postgres` | Tells the Service which pods to route traffic to: any pod carrying the label `app: postgres`. This matches `spec.template.metadata.labels.app: postgres` on the StatefulSet below — **label matching, not naming, is how a Service finds its pods.** |
| `spec.ports[0].port: 5432` / `targetPort: 5432` | `port` is what clients connect to (`postgres:5432`); `targetPort` is the port the container actually listens on inside the pod. They're the same here because Postgres's default port is used unchanged. |

### 2.3 — the `StatefulSet` (lines 25–72)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: microservice
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          envFrom:
            - secretRef:
                name: postgres-secret
          env:
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "gitlab"]
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            exec:
              command: ["pg_isready", "-U", "gitlab"]
            initialDelaySeconds: 15
            periodSeconds: 20
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 5Gi
```

| Line | Meaning |
|---|---|
| `apiVersion: apps/v1` | StatefulSet lives in the `apps/` API group (as do Deployment, DaemonSet, ReplicaSet) — workload controllers that aren't "core" v1 objects. |
| `kind: StatefulSet` | A controller for **stateful** workloads: unlike a Deployment, each replica gets (a) a stable, predictable pod name (`postgres-0`, `postgres-1`, ...), (b) its own dedicated PersistentVolumeClaim that survives pod rescheduling, and (c) ordered, one-at-a-time startup/shutdown. This is the standard choice for databases. |
| `spec.serviceName: postgres` | Must name the headless Service defined above. This is what gives each pod (`postgres-0`) its own DNS record under that Service's domain. |
| `spec.replicas: 1` | Single Postgres instance — no replication/HA configured. Fine for a training lab; a production setup would need Patroni/replication, which is out of scope here. |
| `spec.selector.matchLabels.app: postgres` | The StatefulSet's own bookkeeping: "the pods I own and manage are the ones with label `app: postgres`." Must match `template.metadata.labels` below — Kubernetes rejects the object if they don't match. |
| `spec.template` | The **pod template** — the spec used to stamp out each replica pod. Everything under here is "what a `postgres` pod looks like," not the StatefulSet itself. |
| `template.metadata.labels.app: postgres` | The label actually stamped onto each pod. This is what both `spec.selector` (above) and the Service's `spec.selector` (in the Service manifest) match against. |
| `containers[0].name: postgres` | Container name within the pod (relevant for `kubectl logs -c postgres`, multi-container pods, etc. — here there's only one container). |
| `containers[0].image: postgres:15` | The official Postgres Docker Hub image, major version 15 pinned (not `latest`, to avoid surprise major-version upgrades). |
| `containers[0].ports[0].containerPort: 5432` | Documents which port the container listens on. This is informational/for tooling (`kubectl describe`) — it does **not** actually open the port; Postgres opens 5432 regardless of whether this is declared. |
| `envFrom[0].secretRef.name: postgres-secret` | Bulk-imports *every* key in `postgres-secret` as an env var (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`) without listing them one by one. This is what the official Postgres image's entrypoint script reads on first container start to initialize the database. |
| `env[0].name: PGDATA` / `value: /var/lib/postgresql/data/pgdata` | Tells Postgres to put its actual data files in a *subdirectory* of the mount point, not the mount point root. This sidesteps a well-known gotcha: many volume types (and some CSI drivers) place a hidden `lost+found` directory at the root of a fresh volume, which makes Postgres's "is this directory empty enough to initialize" check fail. Using a subdirectory avoids that entirely. |
| `volumeMounts[0]` | Mounts the volume named `postgres-data` (defined by `volumeClaimTemplates` below) at `/var/lib/postgresql/data` inside the container — the path the Postgres image expects for its data directory. |
| `readinessProbe` / `livenessProbe` | Both run `pg_isready -U gitlab` inside the container. **Readiness** controls whether the pod is added to the Service's endpoint list (so GitLab won't be routed to a Postgres pod that's still initializing). **Liveness** controls whether Kubernetes restarts the container if it stops responding. `initialDelaySeconds` staggers them — liveness waits longer (15s vs 5s) so a slow-but-healthy startup isn't mistaken for a hung process and killed prematurely. |
| `volumeClaimTemplates` | **The StatefulSet-specific feature that a Deployment doesn't have.** Instead of one shared PVC, this is a *template*: the StatefulSet controller stamps out one PVC per replica (`postgres-data-postgres-0` for replica `postgres-0`), each bound to its own PersistentVolume, and that binding is preserved across pod restarts/rescheduling — the pod always reattaches to *its* volume, not a random one. |
| `volumeClaimTemplates[0].spec.accessModes: ["ReadWriteOnce"]` | The volume can be mounted read-write by only one node at a time — the standard mode for block storage backing a single-writer database. |
| `volumeClaimTemplates[0].spec.resources.requests.storage: 5Gi` | Requests a 5 GiB volume from whatever `StorageClass` is set as default in the cluster (no `storageClassName` is specified here, so the cluster's default dynamic provisioner handles it). |

---

## 3. `redis/redis.yaml`

Structurally a near-mirror of the Postgres file, minus the Secret (Redis
here runs with no password/ACLs — again, lab-appropriate, not
production-appropriate).

### 3.1 — the `Service` (lines 1–12)

Same pattern as Postgres's Service: `clusterIP: None` (headless, paired with
the StatefulSet below), `selector.app: redis` to find its pods, and
`port/targetPort: 6379` (Redis's default port). Its name, `redis`, is what
`gitlab/gitlab.yaml` line 94 references as `gitlab_rails['redis_host']`.

### 3.2 — the `StatefulSet` (lines 14–56)

| Line | Meaning |
|---|---|
| `spec.serviceName: redis` | Pairs with the headless `redis` Service, same reasoning as Postgres. |
| `spec.replicas: 1` | Single Redis instance, no clustering/sentinel — GitLab will use it as a plain cache + Sidekiq job queue backend, not for HA. |
| `containers[0].image: redis:7` | Official Redis image, major version 7 pinned. |
| `containers[0].command: ["redis-server", "--appendonly", "yes"]` | **Overrides** the image's default entrypoint args. `--appendonly yes` turns on Redis's AOF (Append Only File) persistence, so data written to `/data` survives a container restart. Without this flag, Redis defaults to periodic RDB snapshots only (or nothing, depending on image config), and mounting a PVC at `/data` would otherwise be pointless — this flag is what makes the volume mount below actually matter. |
| `volumeMounts[0]` | Mounts `redis-data` at `/data`, the path the Redis image writes its AOF/RDB files to. |
| `readinessProbe` / `livenessProbe` | Both run `redis-cli ping` (expects `PONG` back) — analogous role to Postgres's `pg_isready` checks above. |
| `volumeClaimTemplates` | Same StatefulSet-per-replica-PVC mechanism as Postgres, but requesting only `1Gi` — Redis here is a cache/queue, not primary data storage, so it needs much less durable space than Postgres. |

**Why StatefulSet instead of Deployment for a cache?** Strictly, a cache
*could* tolerate a Deployment + ephemeral storage (lose the cache, GitLab
just repopulates it). Using a StatefulSet here is a deliberate consistency
choice for the training exercise (matches the answer you picked earlier:
"StatefulSet + PVC + Service" for both) and also means Sidekiq's job queue
(which lives in Redis) survives a pod restart rather than silently dropping
in-flight background jobs.

---

## 4. `gitlab/gitlab.yaml`

Five objects: three PVCs, one Service, one Deployment.

### 4.1 — the three `PersistentVolumeClaim`s (lines 1–32)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-data
  namespace: microservice
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 10Gi
```
(repeated for `gitlab-config` at 1Gi and `gitlab-logs` at 1Gi)

**Why plain PVCs here instead of `volumeClaimTemplates` like Postgres/Redis
use?** `volumeClaimTemplates` is a StatefulSet-only field. GitLab is defined
as a `Deployment` (see below) because, unlike Postgres/Redis, it isn't
identity-sensitive storage that needs a `postgres-0`-style stable name — but
Deployments have no mechanism to auto-generate PVCs per replica, so the PVCs
have to be declared as **standalone objects** up front and then referenced
by name from the pod template's `volumes:` block (lines 117–126). This is
also why `replicas` is pinned to `1` and `strategy.type: Recreate` is set
(explained below) — plain PVCs with `ReadWriteOnce` can only be mounted
read-write by one pod at a time, so this Deployment cannot safely be scaled
past 1 replica as written.

The three separate claims mirror the three directories the GitLab omnibus
image itself expects to be persistent:
- `gitlab-data` (10Gi) → `/var/opt/gitlab` — repositories, uploads, artifacts, CI cache, the actual "product data."
- `gitlab-config` (1Gi) → `/etc/gitlab` — `gitlab.rb`, generated secrets (`gitlab-secrets.json`), TLS certs. Losing this without a backup effectively locks you out of decrypting existing data (2FA secrets, CI variables, etc.), so keeping it on its own named claim (easy to snapshot/back up independently) is deliberate.
- `gitlab-logs` (1Gi) → `/var/log/gitlab` — Nginx/Puma/Sidekiq/Gitaly logs. Smallest, most disposable of the three; separated mainly so log growth can't fill up the data or config volumes.

### 4.2 — the `Service` (lines 34–49)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: gitlab
  namespace: microservice
spec:
  type: NodePort
  selector:
    app: gitlab
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: ssh
      port: 22
      targetPort: 22
```

| Line | Meaning |
|---|---|
| `spec.type: NodePort` | Unlike Postgres/Redis's headless Services (internal-only, cluster-DNS-based), this Service is meant to be reached **from outside the cluster** — a user's browser/`git` client, not another pod. `NodePort` opens a port (auto-assigned from the 30000–32767 range unless `nodePort` is pinned explicitly) on every cluster node's IP, forwarding to this Service. In this vagrant training setup that's the simplest way to reach GitLab without needing a cloud LoadBalancer or an Ingress controller. |
| `selector.app: gitlab` | Routes to pods labeled `app: gitlab` — matches the Deployment's pod template label below. |
| `ports[0]` (`http`, 80→80) | Web UI / HTTP Git access / API. |
| `ports[1]` (`ssh`, 22→22) | `git clone git@...` / SSH-based Git access. Two named ports on one Service because a Service can multiplex several ports as long as each has a unique `name`. |

### 4.3 — the `Deployment` (lines 51–126)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab
  namespace: microservice
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: gitlab
  template:
    metadata:
      labels:
        app: gitlab
    spec:
      containers:
        - name: gitlab
          image: gitlab/gitlab-ce:latest
          ...
```

| Line | Meaning |
|---|---|
| `kind: Deployment` | Chosen over StatefulSet because GitLab's pod has no need for a stable per-replica identity or per-replica storage — it's a single stateless-ish frontend process that happens to mount some pre-existing shared volumes. (Real-world multi-replica GitLab needs shared/NFS-backed storage or the split-out microservice architecture (Gitaly, Praefect, Registry, etc.) that GitLab's own Helm chart provides — genuinely out of scope for one Deployment.) |
| `spec.replicas: 1` | Single instance — see the PVC note above on why this can't safely be scaled up as written (the three `ReadWriteOnce` PVCs would fail to attach to a second pod on a different node, and even on the same node, GitLab wasn't designed to have two omnibus instances sharing one `/var/opt/gitlab`). |
| `spec.strategy.type: Recreate` | Overrides Kubernetes's default Deployment rollout strategy (`RollingUpdate`, which briefly runs old and new pods side by side). `Recreate` kills the old pod *before* starting the new one. This is required here because the old and new pod would otherwise both try to mount the same `ReadWriteOnce` PVCs simultaneously during a rolling update, which fails — `Recreate` guarantees only one pod ever holds the volumes at a time. |
| `spec.selector.matchLabels.app: gitlab` | Must match `template.metadata.labels`, same bookkeeping pattern as the StatefulSets. |
| `containers[0].image: gitlab/gitlab-ce:latest` | GitLab Community Edition's official omnibus image — bundles Puma (web), Workhorse (reverse proxy/git smart-http), Sidekiq (background jobs), Gitaly (Git RPC service), Nginx, and Rails, all as supervised processes inside one container (via `runit`). `:latest` is a training-exercise shortcut; production should pin an explicit version tag for reproducible upgrades. |
| `ports` (80, 22) | Documents the ports the container listens on — matched by the Service's `targetPort`s above. |
| `env[0]` — `GITLAB_ROOT_PASSWORD` | Read by the omnibus image's first-boot script to set the initial `root` user's password (GitLab normally auto-generates a random one and requires a password reset otherwise). Plaintext here again is lab-only. |
| `env[1]` — `GITLAB_POSTGRES_PASSWORD` via `secretKeyRef` | **The cross-file link to `postgres/postgres.yaml`.** Rather than retyping the Postgres password, this pulls the exact same `POSTGRES_PASSWORD` key out of the exact same `postgres-secret` Secret object that the Postgres StatefulSet itself was bootstrapped from — guaranteeing the two can never drift out of sync. |
| `env[2]` — `GITLAB_OMNIBUS_CONFIG` | The big one. This env var is GitLab's officially supported mechanism for injecting `gitlab.rb` configuration at container startup — the entrypoint script writes this literal string into `/etc/gitlab/gitlab.rb` (well, appends/reconciles it) and runs `gitlab-ctl reconfigure`, which is what actually applies these settings via Chef recipes internally. |

**Line-by-line inside the `GITLAB_OMNIBUS_CONFIG` block** (this is not YAML
— it's a literal Ruby-syntax `gitlab.rb` file, passed as one multi-line
string via the `|` block scalar):

| Line | Meaning |
|---|---|
| `external_url 'http://gitlab.local'` | The base URL GitLab uses to generate all absolute links (clone URLs, email links, webhooks, avatars). Must match how users actually reach the instance — in a real deploy this would be the NodePort's host:port or an Ingress hostname; `gitlab.local` here is a placeholder that should be updated to match your actual access URL. |
| `postgresql['enable'] = false` | **This is the crux of "external Postgres."** GitLab omnibus normally starts and manages its *own* bundled Postgres process inside the container. Setting this to `false` disables that bundled process entirely — GitLab now expects a Postgres server to already exist elsewhere. |
| `gitlab_rails['db_adapter'] = 'postgresql'` | Explicitly tells the Rails app which DB adapter to use (redundant with the default, but explicit here since we're overriding the whole DB config block). |
| `gitlab_rails['db_encoding'] = 'utf8'` | Character encoding for the DB connection — GitLab's documented required value. |
| `gitlab_rails['db_host'] = 'postgres.microservice.svc.cluster.local'` | **The cross-file link to `postgres/postgres.yaml`'s Service.** This is the fully-qualified in-cluster DNS name (`<service>.<namespace>.svc.cluster.local`) that resolves — via CoreDNS — to the headless Service's pod IP(s), i.e. the `postgres-0` pod. This is *the* mechanism that makes "external Postgres" actually reachable: no IP address is hardcoded anywhere; DNS + the Service's label selector is what wires the two workloads together at runtime. |
| `gitlab_rails['db_port'] = 5432` | Matches the Postgres Service's `port: 5432`. |
| `gitlab_rails['db_username'] = 'gitlab'` | Matches `POSTGRES_USER: gitlab` in the Secret. |
| `gitlab_rails['db_password'] = '$(GITLAB_POSTGRES_PASSWORD)'` | **Kubernetes env-var interpolation**, not Ruby string interpolation. Kubernetes performs `$(VAR_NAME)` substitution on container env values *before* the container ever starts, as long as `VAR_NAME` was defined earlier in the same container's `env:` list — which it is, at line 77–81. So by the time this string reaches the GitLab entrypoint script, it already contains the literal decoded password from `postgres-secret`. This is what lets the omnibus config block reference Secret-sourced data without needing a templating tool (Helm, Kustomize) or an init-container to do string substitution manually. |
| `gitlab_rails['db_database'] = 'gitlabhq_production'` | Matches `POSTGRES_DB: gitlabhq_production` in the Secret — the database GitLab will connect to and run migrations against on first boot. |
| `redis['enable'] = false` | **The crux of "external Redis,"** mirroring `postgresql['enable'] = false` above — disables the bundled Redis process inside the omnibus container. |
| `gitlab_rails['redis_host'] = 'redis.microservice.svc.cluster.local'` | **The cross-file link to `redis/redis.yaml`'s Service** — same DNS mechanism as the Postgres host line. |
| `gitlab_rails['redis_port'] = 6379` | Matches the Redis Service's `port: 6379`. |

| Line | Meaning |
|---|---|
| `volumeMounts` (lines 96–102) | Wires the pod's three `volumes` (below) into the container filesystem at the exact paths the omnibus image expects (`/var/opt/gitlab`, `/etc/gitlab`, `/var/log/gitlab`). |
| `readinessProbe` — `GET /-/readiness` | GitLab's built-in health endpoint that checks DB, Redis, Gitaly, and queue connectivity. `initialDelaySeconds: 60` gives the (slow) omnibus `reconfigure` + Rails boot process a full minute before the first check, avoiding a flapping "not ready" state during normal startup. |
| `livenessProbe` — `GET /-/liveness` | A lighter-weight "is the process alive at all" check, delayed even further (90s) so it doesn't restart the container mid-boot. |
| `volumes` (lines 117–126) | Binds each named volume (`gitlab-data`, `gitlab-config`, `gitlab-logs`) to the correspondingly-named `PersistentVolumeClaim` object defined at the top of this same file — this is the link between the pod template and the standalone PVCs. |

---

## 5. How the four files relate to each other, end to end

```
namespace.yaml
   └─ creates namespace "microservice"
        ├─ postgres/postgres.yaml
        │    ├─ Secret "postgres-secret"          (creds, read by 2 consumers)
        │    ├─ Service "postgres" (headless)      ──DNS name──┐
        │    └─ StatefulSet "postgres"                          │
        │           ├─ pod labeled app=postgres  ←──selector────┘ (Service routes here)
        │           ├─ envFrom: postgres-secret   (bootstraps DB user/pass/db)
        │           └─ volumeClaimTemplates → PVC → PV (5Gi, per-replica)
        │
        ├─ redis/redis.yaml
        │    ├─ Service "redis" (headless)         ──DNS name──┐
        │    └─ StatefulSet "redis"                             │
        │           ├─ pod labeled app=redis     ←──selector────┘ (Service routes here)
        │           └─ volumeClaimTemplates → PVC → PV (1Gi, per-replica)
        │
        └─ gitlab/gitlab.yaml
             ├─ PVCs: gitlab-data / gitlab-config / gitlab-logs (standalone, pre-created)
             ├─ Service "gitlab" (NodePort)          ──external traffic──┐
             └─ Deployment "gitlab"                                       │
                    ├─ pod labeled app=gitlab       ←──selector───────────┘
                    ├─ volumes → the 3 PVCs above (by claimName)
                    ├─ env: GITLAB_POSTGRES_PASSWORD ← secretKeyRef → postgres-secret.POSTGRES_PASSWORD
                    └─ env: GITLAB_OMNIBUS_CONFIG
                           ├─ db_host    = postgres.microservice.svc.cluster.local  → resolves to Postgres Service
                           ├─ db_password= $(GITLAB_POSTGRES_PASSWORD)              → interpolated from the secret above
                           └─ redis_host = redis.microservice.svc.cluster.local     → resolves to Redis Service
```

**The three coupling mechanisms, summarized:**

1. **Shared namespace** (`microservice`) — required for Service DNS short names and for a Secret to be mountable/referenceable across objects at all (Secrets can't be referenced cross-namespace).
2. **Service DNS names as connection strings** — `postgres` and `redis` Service `metadata.name`s become the literal hostnames GitLab is configured to dial. Rename either Service and you must update the matching `db_host`/`redis_host` line in `gitlab/gitlab.yaml`, or GitLab will fail DNS resolution and refuse to boot into a working state.
3. **Shared Secret (`postgres-secret`) as the single source of truth for the DB password** — both the Postgres StatefulSet (which uses it to *set* the password) and the GitLab Deployment (which uses it to *authenticate* with that password) read the same object/key, using Kubernetes' `$(VAR)` env-interpolation to inject it into the multi-line `GITLAB_OMNIBUS_CONFIG` string.

**Apply order matters** because of these dependencies (`kubectl apply` does
*not* resolve ordering for you — objects referencing not-yet-existent
namespaces/secrets will simply error and need to be re-applied):

```bash
kubectl apply -f namespace.yaml
kubectl apply -f postgres/postgres.yaml
kubectl apply -f redis/redis.yaml
kubectl apply -f gitlab/gitlab.yaml
```

Postgres and Redis before GitLab isn't strictly required for the objects to
be *accepted* by the API server (GitLab's pod would just crash-loop on DB
connection failure and retry), but applying them first means GitLab's first
boot attempt actually succeeds instead of needing a restart once the
database is ready.
