# Notes regarding Dokku install

How to deploy the etherpad-lite instance to popey.org using Dokku:

# Prerequisites

- Install dokku on your server (see https://dokku.com/docs/getting-started/installation/)
- Install the postgres plugin (see popey.org ansible project)


# A) One-time app + domain config

```bash
# ensure the app exists (you already did this)
dokku apps:create pad

# map the domain
dokku domains:set pad pad.popey.org
```

If you use your Let’s Encrypt plugin:

```bash
# (example) set email then enable
# dokku letsencrypt:set pad email you@example.com
# dokku letsencrypt:enable pad
```

# B) Runtime env for Etherpad

Bind to a fixed internal port and trust the reverse proxy:

```bash
dokku config:set pad \
  PORT=5000 \
  TRUST_PROXY=true
```

Admin access at `/admin` (change the password!):

```bash
dokku config:set pad ADMIN_PASSWORD='a-strong-password'
```

(Optional niceties)

```bash
dokku config:set pad TITLE="Popey Pad"
# If you later add export tools inside the image:
# dokku config:set pad SOFFICE=/usr/bin/soffice
# or: dokku config:set pad ABIWORD=/usr/bin/abiword
```

# C) Database: map Dokku’s DSN → Etherpad’s `DB_*`

You already created and linked Postgres:

```bash
dokku postgres:create pad-db
dokku postgres:link pad-db pad
```

Grab the DSN and export Etherpad’s expected variables:

```bash
DSN=$(dokku postgres:info pad-db --dsn)

dokku config:set pad \
  DB_TYPE=postgres \
  DB_HOST=$(echo "$DSN" | sed -E 's|.*@([^:/]+):.*|\1|') \
  DB_PORT=$(echo "$DSN" | sed -E 's|.*:([0-9]+)/.*|\1|') \
  DB_NAME=$(echo "$DSN" | sed -E 's|.*/([^?]+)$|\1|') \
  DB_USER=$(echo "$DSN" | sed -E 's|.*//([^:]+):.*|\1|') \
  DB_PASS=$(echo "$DSN" | sed -E 's|.*://[^:]+:([^@]+)@.*|\1|')
```

# D) Deploy your fork to the **pad** app

```bash
# from your local repo
git remote add dokku dokku@popey.org:pad
git push dokku main   # or your branch
```

# E) Sanity checks & handy commands

```bash
# app status & config
dokku ps:report pad
dokku config pad

# live logs if something’s off
dokku logs pad -t
```

# Quick checklist

* [ ] `dokku domains:set pad pad.popey.org`
* [ ] `dokku config:set pad PORT=5000 TRUST_PROXY=true ADMIN_PASSWORD=...`
* [ ] DSN → `DB_*` block run successfully
* [ ] `git push dokku main`
* [ ] Enable Let’s Encrypt for **pad**
* [ ] Visit `https://pad.popey.org/admin` and log in with `admin` / your `ADMIN_PASSWORD`

If anything errors during build or boot, paste `dokku logs pad -t` and I’ll pinpoint the fix.
