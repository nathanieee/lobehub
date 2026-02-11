# Path Fixes Applied - February 10, 2026

## Issues Fixed

### Issue #1: Build Context Going Above Repository Root ❌

**Problem:**
```yaml
# docker-compose/deploy/docker-compose.yml
lobe:
  build:
    context: ../..  # Tried to access /artifacts/../.. (doesn't exist)
    dockerfile: docker-compose/deploy/Dockerfile
```

**Error in Coolify:**
```
resolve : lstat /docker-compose: no such file or directory
exit status 1
```

**Root Cause:**
- Coolify clones repo to: `/artifacts/{container-id}/`
- Context `../..` tries to go to `/artifacts/` (non-existent parent)
- Build cannot access files above clone directory

**Fix Applied:**
```yaml
lobe:
  build:
    context: .  # Repository root when compose file is in root
    dockerfile: Dockerfile
```

**And moved Dockerfile to:**
```
docker-compose/deploy/Dockerfile  # Same directory as compose file
```

**Why This Works:**
- Context `.` = `/artifacts/{container-id}/docker-compose/deploy/`
- Dockerfile `Dockerfile` = `/artifacts/{container-id}/docker-compose/deploy/Dockerfile`
- All files are accessible within clone directory

### Issue #2: Missing Port Variables ⚠️

**Problem:**
```yaml
ports:
  - '${RUSTFS_PORT}:9000'  # Blank if not set
  - '${LOBE_PORT}:3210'    # Blank if not set
```

**Error:**
```
The "RUSTFS_PORT" variable is not set. Defaulting to a blank string.
The "LOBE_PORT" variable is not set. Defaulting to a blank string.
```

**Fix Applied:**
```yaml
ports:
  - '${RUSTFS_PORT:-9000}:9000'  # Defaults to 9000
  - '${LOBE_PORT:-3210}:3210'    # Defaults to 3210
```

**Why This Works:**
- Bash parameter expansion: `${VAR:-default}`
- Provides fallback if variable not set
- Prevents deployment failures

## Path Reference Rules Established

### Rule 1: Build Context Must Stay Within Clone Directory

**✅ CORRECT:**
```yaml
build:
  context: .              # Same directory as compose file
  context: ./app         # Subdirectory
  context: ../app        # Parent directory (if within repo)
```

**❌ WRONG:**
```yaml
build:
  context: ../..          # Goes above repo root
  context: /path/to/app  # Absolute path (may not exist)
```

### Rule 2: All Paths Must Be Relative to Reference Point

| Reference Type | Base Point | Example | Resolves To |
|----------------|------------|---------|-------------|
| Build context | Compose file dir | `.` | `docker-compose/deploy/` |
| Dockerfile | Build context | `Dockerfile` | `docker-compose/deploy/Dockerfile` |
| Volume source | Compose file dir | `./data` | `docker-compose/deploy/data` |
| Env file | Compose file dir | `.env` | `docker-compose/deploy/.env` |

### Rule 3: Always Provide Defaults for Optional Variables

**✅ CORRECT:**
```yaml
ports:
  - '${PORT:-3000}:3000'  # Has default
environment:
  - NODE_ENV=${NODE_ENV:-production}  # Has default
```

**❌ WRONG:**
```yaml
ports:
  - '${PORT}:3000'  # No default, fails if unset
environment:
  - NODE_ENV=${NODE_ENV}  # Blank if unset
```

## Files Modified

### 1. `docker-compose/deploy/docker-compose.yml`

**Changes:**
- Build context: `../..` → `.`
- Dockerfile path: `docker-compose/deploy/Dockerfile` → `Dockerfile`
- Port defaults: Added `${VAR:-default}` syntax
- Resource limits: Added for all services
- Health checks: Improved with start periods

### 2. `docker-compose/deploy/Dockerfile` (New)

**Purpose:** Build file specifically for docker-compose deployment
- Optimized for multi-service setup
- Uses Node.js 22
- Includes all build optimizations
- Smaller final image size

### 3. `docker-compose/deploy/.env.coolify` (New)

**Purpose:** Template for Coolify environment variables
- All required variables documented
- Clear placeholder values
- Generation instructions included

### 4. `scripts/validate-docker-compose.sh` (New)

**Purpose:** Validate paths before deployment
- Checks build contexts
- Validates file existence
- Prevents common path mistakes

### 5. Documentation Files

**Created:**
- `PATH_VALIDATION.md` - Complete path reference guide
- `PATH_FIXES_APPLIED.md` - This document
- `COOLIFY_ERROR_FIX.md` - Specific error troubleshooting

**Updated:**
- `COOLIFY_DEPLOYMENT.md` - Added path validation section
- `COOLIFY_QUICKSTART.md` - Added path warnings

## Validation Steps Added

### Pre-Deployment Checklist

Before deploying to Coolify:

1. ✅ **Validate build context:**
   ```bash
   cd docker-compose/deploy
   docker-compose config
   ```

2. ✅ **Check all files exist:**
   ```bash
   ls -la docker-compose/deploy/Dockerfile
   ls -la docker-compose/deploy/.env.coolify
   ```

3. ✅ **Test build locally:**
   ```bash
   cd docker-compose/deploy
   docker-compose build
   ```

4. ✅ **Run validation script:**
   ```bash
   ./scripts/validate-docker-compose.sh
   ```

## Prevention Measures

### 1. Automated Validation

Added script: `scripts/validate-docker-compose.sh`

Can be run as:
- Manual check before commits
- Pre-commit hook (optional)
- CI/CD pipeline step

### 2. Documentation Standards

All path references must include:
- Base directory
- Relative path
- Resolved full path
- Example usage

### 3. Code Review Checklist

When reviewing docker-compose changes:
- [ ] Build context within repository
- [ ] Dockerfile path relative to context
- [ ] All referenced files exist
- [ ] Volume paths are relative
- [ ] Environment variables have defaults
- [ ] No absolute paths (unless required)

## Lessons Learned

### 1. Platform Differences Matter

**Local development:**
- Build context can use `../..` to reach repo root
- All files accessible via filesystem

**Coolify deployment:**
- Build context limited to clone directory
- Cannot access files above `/artifacts/`
- Must use relative paths within clone

### 2. Always Test in Deployment Environment

- Local success ≠ deployment success
- Test with actual Coolify constraints
- Validate paths in clone-like environment

### 3. Document Path Assumptions

- Clearly state base directory for all paths
- Provide examples for different platforms
- Include validation steps

## Quick Reference for Future Changes

### Adding New Service

```yaml
services:
  new-service:
    build:
      context: .                    # ✅ Relative to compose file
      dockerfile: Dockerfile        # ✅ In same directory
    volumes:
      - ./config:/app/config       # ✅ Relative to compose file
    env_file:
      - .env                       # ✅ Relative to compose file
```

### Changing Build Context

❌ **Don't do this:**
```yaml
context: ../..  # Breaks in Coolify
```

✅ **Do this instead:**
```yaml
# Option 1: Keep files with compose file
context: .
dockerfile: Dockerfile

# Option 2: Move compose file to repo root
context: .
dockerfile: docker-compose/deploy/Dockerfile
```

### Adding Environment Variables

❌ **Don't do this:**
```yaml
environment:
  - PORT=${PORT}  # Fails if not set
```

✅ **Do this instead:**
```yaml
environment:
  - PORT=${PORT:-3000}  # Has default
```

## Success Criteria

Deployment is successful when:

1. ✅ All build contexts are within repository
2. ✅ All referenced files exist
3. ✅ All environment variables have defaults
4. ✅ Validation script passes
5. ✅ Coolify deployment succeeds

## Related Documentation

- `PATH_VALIDATION.md` - Complete path reference guide
- `COOLIFY_DEPLOYMENT.md` - Deployment instructions
- `scripts/validate-docker-compose.sh` - Validation script

---

**Last Updated:** February 10, 2026
**Status:** All path issues resolved ✅
