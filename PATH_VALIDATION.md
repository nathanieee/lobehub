# Path Reference & Validation Guide

## Critical Rule for Path References

**ALWAYS define paths relative to where they are referenced from, with clear documentation of the base context.**

## Repository Structure

```
lobehub/                              ← Repository root
├── docker-compose/
│   └── deploy/
│       ├── Dockerfile               ← Build Dockerfile
│       ├── docker-compose.yml       ← Compose file
│       ├── .env.coolify             ← Env template
│       ├── bucket.config.json       ← S3 config
│       └── searxng-settings.yml     ← Search config
├── Dockerfile                       ← Root Dockerfile (standalone)
├── package.json
└── ...
```

## Path Reference Standards

### 1. Docker Compose Build Contexts

**Rule**: Build context is relative to the docker-compose.yml file location

**Example**:
```yaml
# File: docker-compose/deploy/docker-compose.yml
services:
  lobe:
    build:
      context: .                    # ✅ CORRECT: Relative to compose file
      # Resolves to: docker-compose/deploy/
      dockerfile: Dockerfile        # ✅ CORRECT: Relative to context

      # ❌ WRONG: context: ../..
      # This would try to go above repository root
```

**When Coolify deploys**:
1. Clones repo to: `/artifacts/{container-id}/`
2. Project directory: `/artifacts/{container-id}/`
3. Compose file: `/artifacts/{container-id}/docker-compose/deploy/docker-compose.yml`
4. Context `.` = `/artifacts/{container-id}/docker-compose/deploy/`
5. Dockerfile `Dockerfile` = `/artifacts/{container-id}/docker-compose/deploy/Dockerfile`

**BUT we need context to be repo root**, so:
```yaml
lobe:
  build:
    context: ../..                  # ✅ CORRECT for local build
    # From docker-compose/deploy/ → go up 2 levels → repo root

    # ❌ WRONG for Coolify!
    # Coolify doesn't have access above /artifacts/

    # ✅ SOLUTION: Use context: .
    #    dockerfile: Dockerfile
    #    And move Dockerfile to docker-compose/deploy/
```

### 2. Volume Mount Paths

**Rule**: Volume paths are relative to the docker-compose.yml location

```yaml
volumes:
  - './data:/var/lib/postgresql/data'  # ✅ CORRECT
  # Creates: docker-compose/deploy/data/

  - './searxng-settings.yml:/etc/searxng/settings.yml'  # ✅ CORRECT
  # Maps: docker-compose/deploy/searxng-settings.yml
```

### 3. Environment File References

**Rule**: .env files are relative to docker-compose.yml

```yaml
env_file:
  - .env                            # ✅ CORRECT
  # Looks for: docker-compose/deploy/.env
```

### 4. File References in Commands

**Rule**: Paths in commands are relative to the build context

```yaml
rustfs-init:
  volumes:
    - ./bucket.config.json:/bucket.config.json:ro  # ✅ CORRECT
    # Maps: docker-compose/deploy/bucket.config.json
```

## Deployment Platform Path Rules

### Coolify Deployment

**Context**: `/artifacts/{container-id}/`

| Reference Type | Correct Path | Resolves To |
|----------------|--------------|-------------|
| Build context | `.` | `/artifacts/{id}/docker-compose/deploy/` |
| Dockerfile | `Dockerfile` | `/artifacts/{id}/docker-compose/deploy/Dockerfile` |
| Volume | `./data` | `/artifacts/{id}/docker-compose/deploy/data` |
| Config file | `./config.json` | `/artifacts/{id}/docker-compose/deploy/config.json` |

**❌ NEVER USE**:
- `../` - Goes above /artifacts/ (doesn't exist)
- Absolute paths like `/app/` - May not exist in Coolify

### Local Deployment

**Context**: Repository root

| Reference Type | Correct Path | Resolves To |
|----------------|--------------|-------------|
| Build context | `../..` | Repository root |
| Dockerfile | `Dockerfile` | Repository root |
| Volume | `./data` | `./data` |

## Validation Checklist

Before committing changes to docker-compose files:

### ✅ Build Context

- [ ] Context path exists within repository
- [ ] No `../..` or higher parent references
- [ ] Dockerfile path is relative to context
- [ ] All files referenced in Dockerfile exist

### ✅ Volume Mounts

- [ ] Source paths are relative to compose file
- [ ] Source directories exist or will be created
- [ ] No absolute paths (unless required)

### ✅ Configuration Files

- [ ] All referenced files exist
- [ ] Paths are relative to compose file location
- [ ] File extensions are correct

### ✅ Environment Files

- [ ] .env files exist at referenced locations
- [ ] All variables in .env have values or defaults
- [ ] No circular references

## Common Path Mistakes

### Mistake 1: Build Context Above Repository Root

```yaml
# ❌ WRONG
build:
  context: ../../../..  # Goes way above repo

# ✅ CORRECT
build:
  context: .  # Stays within repo
  # Or move Dockerfile to match desired context
```

### Mistake 2: Absolute Paths in Volumes

```yaml
# ❌ WRONG
volumes:
  - /var/lib/postgresql/data:/var/lib/postgresql/data

# ✅ CORRECT
volumes:
  - ./data:/var/lib/postgresql/data
  # Or named volume
  - postgres_data:/var/lib/postgresql/data
```

### Mistake 3: Missing Default Values

```yaml
# ❌ WRONG
ports:
  - '${PORT}:3210'  # Fails if PORT not set

# ✅ CORRECT
ports:
  - '${PORT:-3210}:3210'  # Defaults to 3210
```

## Path Reference Examples

### Example 1: Multi-File Docker Build

```
project/
├── docker/
│   ├── app/
│   │   └── Dockerfile
│   └── docker-compose.yml
```

```yaml
# docker/docker-compose.yml
services:
  app:
    build:
      context: ./app
      dockerfile: Dockerfile
    # Resolves to: docker/app/Dockerfile
```

### Example 2: Shared Config Files

```
project/
├── config/
│   └── app.conf
└── docker/
    └── docker-compose.yml
```

```yaml
# docker/docker-compose.yml
services:
  app:
    volumes:
      - ../config/app.conf:/app/config/app.conf
    # ✅ CORRECT: Relative to compose file
```

### Example 3: Our Current Setup (Optimized)

```
lobehub/
├── docker-compose/
│   └── deploy/
│       ├── Dockerfile               # Build file
│       ├── docker-compose.yml       # Compose file
│       ├── .env.coolify             # Env template
│       └── bucket.config.json       # Config
```

```yaml
# docker-compose/deploy/docker-compose.yml
services:
  lobe:
    build:
      context: .                     # ✅ docker-compose/deploy/
      dockerfile: Dockerfile         # ✅ Dockerfile in same dir
    volumes:
      - ./bucket.config.json:/bucket.config.json:ro  # ✅ Same dir
    env_file:
      - .env                         # ✅ Relative to compose file
```

## Path Validation Commands

### Check All Paths Exist

```bash
# From repository root
find docker-compose/deploy -type f -name "*.yml" -o -name "*.yaml" | while read f; do
  echo "Checking: $f"
  grep -E "(\.\./|context:|dockerfile:|volumes:|env_file:)" "$f"
done
```

### Validate Build Contexts

```bash
# From repository root
cd docker-compose/deploy
docker-compose config 2>&1 | grep -i "error\|not found"
```

### Test Build Locally

```bash
# From repository root
cd docker-compose/deploy
docker-compose build --no-cache
```

## Documentation Standards

When adding path references, always document:

```yaml
services:
  example:
    build:
      # Path: Relative to this compose file
      # Resolves to: docker-compose/deploy/
      context: .
      # Path: Relative to context
      # Resolves to: docker-compose/deploy/Dockerfile
      dockerfile: Dockerfile
```

## Pre-Commit Validation (Recommended)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Validate docker-compose paths
echo "Validating docker-compose paths..."

cd docker-compose/deploy
docker-compose config > /dev/null
if [ $? -ne 0 ]; then
  echo "❌ Docker-compose validation failed"
  exit 1
fi

echo "✅ All paths validated"
```

## Quick Reference

| From | To | Use |
|------|-----|-----|
| `docker-compose/deploy/docker-compose.yml` | Same dir | `./` or `.` |
| `docker-compose/deploy/docker-compose.yml` | Parent dir | `../` |
| `docker-compose/deploy/docker-compose.yml` | Repo root | `../..` (local), `.` (Coolify) |
| `docker-compose/deploy/docker-compose.yml` | Subdir | `./subdir/` |

**Remember**: When in doubt, use `.` as context and move files to match!
