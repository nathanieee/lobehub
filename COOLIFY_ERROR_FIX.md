# Coolify Deployment Error Fix

## Error You Encountered

```
time="2026-02-10T15:49:24Z" level=warning msg="The \"RUSTFS_PORT\" variable is not set. Defaulting to a blank string."
time="2026-02-10T15:49:24Z" level=warning msg="The \"LOBE_PORT\" variable is not set. Defaulting to a blank string."
resolve : lstat /docker-compose: no such file or directory
exit status 1
```

## Root Cause

The docker-compose.yml file uses environment variables for port mapping:
- `${RUSTFS_PORT}` for RustFS API port
- `${LOBE_PORT}` for LobeChat application port

Coolify requires these to be explicitly set in the application's environment variables, otherwise it defaults to blank strings, causing port mapping to fail.

## Fix Applied

### 1. Added Default Values to docker-compose.yml

**File**: `docker-compose/deploy/docker-compose.yml`

Changed:
```yaml
ports:
  - '${RUSTFS_PORT}:9000'
  - '${LOBE_PORT}:3210'
```

To:
```yaml
ports:
  - '${RUSTFS_PORT:-9000}:9000'  # Default to 9000
  - '${LOBE_PORT:-3210}:3210'    # Default to 3210
```

The `:-9000` syntax provides default values if the variable is not set.

### 2. Created Coolify-Specific Environment File

**File**: `docker-compose/deploy/.env.coolify`

This file contains ALL required environment variables pre-configured for Coolify:

```bash
# Required Port Configuration
RUSTFS_PORT=9000
LOBE_PORT=3210

# Required Security Secrets
KEY_VAULTS_SECRET=CHANGE_THIS_GENERATE_WITH_OPENSSL
AUTH_SECRET=CHANGE_THIS_GENERATE_WITH_OPENSSL

# Required Database Configuration
LOBE_DB_NAME=lobechat
POSTGRES_PASSWORD=CHANGE_THIS_TO_SECURE_PASSWORD

# Required S3/RustFS Configuration
RUSTFS_ACCESS_KEY=admin
RUSTFS_SECRET_KEY=CHANGE_THIS_TO_SECURE_PASSWORD
RUSTFS_LOBE_BUCKET=lobe

# Required Application Configuration
APP_URL=http://localhost:3210
```

## How to Deploy Now

### Step 1: Open Coolify Application Settings

Go to your application in Coolify → **Settings** → **Environment Variables**

### Step 2: Add These Variables

**Copy and paste each of these into Coolify:**

```bash
RUSTFS_PORT=9000
LOBE_PORT=3210
KEY_VAULTS_SECRET=your_generated_secret_here
AUTH_SECRET=your_generated_secret_here
LOBE_DB_NAME=lobechat
POSTGRES_PASSWORD=your_secure_password_here
RUSTFS_ACCESS_KEY=admin
RUSTFS_SECRET_KEY=your_rustfs_password_here
RUSTFS_LOBE_BUCKET=lobe
APP_URL=http://localhost:3210
```

### Step 3: Generate Secure Secrets

Run these commands to generate secure secrets:

```bash
# Generate KEY_VAULTS_SECRET
openssl rand -base64 32

# Generate AUTH_SECRET
openssl rand -base64 32

# Generate POSTGRES_PASSWORD
openssl rand -base64 16

# Generate RUSTFS_SECRET_KEY
openssl rand -base64 16
```

Replace the placeholder values in Coolify with the generated secrets.

### Step 4: Redeploy

1. Go back to application dashboard
2. Click **"Deploy"** button
3. Monitor the logs - should see successful build this time

## Verification

After deployment, you should see:

✅ **All services starting** without port errors
✅ **Health checks passing** for all services
✅ **Application accessible** at `http://your-server-ip:3210`

## What Was Changed

### Files Modified:

1. **`docker-compose/deploy/docker-compose.yml`**
   - Added default values for `RUSTFS_PORT` and `LOBE_PORT`
   - Prevents "variable is not set" warnings

2. **`docker-compose/deploy/.env.coolify`** (NEW)
   - Ready-to-use environment variables for Coolify
   - All required variables pre-configured
   - Clear instructions for generating secrets

3. **`COOLIFY_QUICKSTART.md`**
   - Updated to emphasize required variables
   - Added troubleshooting for this specific error

4. **`COOLIFY_DEPLOYMENT.md`**
   - Updated environment variables section
   - Added warnings about required ports

## Why This Happened

Coolify's Docker Compose integration:
1. Requires ALL variables used in docker-compose.yml to be defined
2. Doesn't automatically load `.env` files from the repository
3. Needs explicit environment variable configuration in the UI

The `${VAR:-default}` syntax provides a fallback, but Coolify still warns about undefined variables. Setting them explicitly eliminates these warnings and ensures proper configuration.

## Preventing Future Issues

✅ **Always check** that variables used in docker-compose.yml are set in Coolify
✅ **Use the `.env.coolify` file** as a template for required variables
✅ **Generate secure secrets** for production deployments
✅ **Double-check port mappings** match your Coolify network configuration

## Still Having Issues?

If deployment still fails after adding these variables:

1. **Check Coolify logs**:
   - Application → Logs → Build Logs
   - Look for specific error messages

2. **Verify all variables are set**:
   - Go to Settings → Environment Variables
   - Ensure all 10 required variables are present

3. **Check resource availability**:
   - Ensure 4GB+ RAM available
   - Check CPU isn't maxed out

4. **Try "Force rebuild without cache"**:
   - Application → Settings → Advanced
   - Enable "Force rebuild without cache"
   - Redeploy

## Success!

After applying these fixes, your deployment should succeed with all services running properly!

Access your LobeHub instance at: `http://your-server-ip:3210`
