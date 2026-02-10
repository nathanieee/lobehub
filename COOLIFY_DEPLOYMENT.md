# Coolify Deployment Guide for LobeHub

This guide provides specific instructions for deploying LobeHub using Coolify.

## Prerequisites

- Coolify instance running (v4.0+ recommended)
- At least 4GB RAM available for builds
- 30+ minutes for initial build time

## Deployment Configuration

### 1. Create New Application

1. In Coolify dashboard, click **"New Resource"**
2. Select **"Application"**
3. Choose your Git repository (GitHub, GitLab, etc.)
4. Select the branch to deploy

### 2. Build Pack Configuration

**Critical: Select "Dockerfile" as the build pack**

- Build Pack: **Dockerfile** (NOT Nixpacks)
- Dockerfile Path: `Dockerfile` (default)
- Build Context: `.` (default)
- Branch: Your target branch

### 3. Build Arguments

Add these build arguments in Coolify:

```bash
NODEJS_VERSION=22
BUILDKIT_INLINE_CACHE=1
```

### 4. Environment Variables

#### Required Build-Time Variables

```bash
CI=true
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
```

#### Required Runtime Variables

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/dbname
DATABASE_DRIVER=node

# Security (generate with: openssl rand -base64 32)
AUTH_SECRET=your_auth_secret_here
KEY_VAULTS_SECRET=your_key_vaults_secret_here

# Application
APP_URL=https://your-domain.com
PORT=3210
```

### 5. Network Configuration

- **Port**: `3210` (default)
- **Health Check Path**: `/api/health`
- **Health Check Interval**: `30s`
- **Health Check Timeout**: `10s`
- **Health Check Retries**: `3`

### 6. Resource Limits

Recommended settings:

```yaml
Memory Limit: 4Gi
Memory Request: 2Gi
CPU Limit: 2
CPU Request: 1
```

### 7. Build Configuration

- **Build Timeout**: `30m` (30 minutes)
- **Build Cache**: Enabled (for faster rebuilds)
- **Concurrent Builds**: 1 (to avoid resource conflicts)

## Troubleshooting

### Build Failures

#### Error: "RuntimeException" or "build_image failed"

**Cause**: Node.js version mismatch or resource constraints

**Solutions**:
1. Ensure `NODEJS_VERSION=22` is set in Build Args
2. Increase memory limits to 4GB+
3. Enable "Force rebuild without cache"
4. Check Coolify logs: `Logs → Build Logs`

#### Error: "Module not found" or dependency issues

**Solutions**:
1. Verify all environment variables are set
2. Check `DATABASE_URL` and `AUTH_SECRET` are provided
3. Ensure build context includes all required files
4. Try rebuilding without cache

#### Error: Build timeout

**Solutions**:
1. Increase build timeout to 45m
2. Check server resource availability
3. Reduce concurrent builds on the server
4. Use BuildKit cache for faster subsequent builds

### Runtime Issues

#### Application not starting

**Check**:
1. Database is accessible: `DATABASE_URL` is correct
2. Required secrets are set: `AUTH_SECRET`, `KEY_VAULTS_SECRET`
3. Port 3210 is not in use
4. Logs: `Logs → Application Logs`

#### Database migration errors

**Solution**:
1. Ensure `DATABASE_URL` is correct and accessible
2. Check PostgreSQL is running and healthy
3. Verify database user has proper permissions
4. Check logs for specific migration errors

## Performance Optimization

### Build Caching

Enable BuildKit cache for faster rebuilds:

```bash
# In Build Args
BUILDKIT_INLINE_CACHE=1
```

### Resource Optimization

For production deployments:
- Use at least 2GB RAM for the application
- Enable Redis for caching: `REDIS_URL=redis://localhost:6379`
- Configure S3/RustFS for object storage

### Monitoring

Set up health checks:

```yaml
Health Check:
  Path: /api/health
  Interval: 30s
  Timeout: 10s
  Retries: 3
```

## Advanced Configuration

### Custom Domain

1. Add domain in Coolify: **Settings → Domains**
2. Update `APP_URL` environment variable
3. Configure DNS (A record or CNAME)
4. Enable SSL (automatic with Coolify)

### Database Configuration

For external PostgreSQL:

```bash
DATABASE_URL=postgresql://user:password@external-host:5432/dbname
```

For Coolify-managed PostgreSQL:
1. Add PostgreSQL service in Coolify
2. Use internal connection string
3. Example: `postgresql://postgres:password@postgres:5432/lobechat`

### Redis Configuration

For Coolify-managed Redis:

```bash
REDIS_URL=redis://redis:6379
REDIS_PREFIX=lobechat
REDIS_TLS=0
```

## Migration from Other Platforms

### From Vercel

1. Export environment variables from Vercel
2. Import into Coolify
3. Update `APP_URL` to new domain
4. Run database migrations
5. Update DNS to point to Coolify

### From Docker Compose

1. Extract environment variables from `.env` file
2. Configure in Coolify UI
3. Update database connection strings
4. Migrate data if needed
5. Deploy

## Support

For issues specific to:
- **Coolify**: Check [Coolify Docs](https://coolify.io/docs)
- **LobeHub**: Check [LobeHub Docs](https://lobehub.com/docs)
- **This Deployment**: Review logs in Coolify dashboard

## Quick Reference

| Setting | Value |
|---------|-------|
| Build Pack | Dockerfile |
| Port | 3210 |
| Node.js Version | 22 |
| Build Timeout | 30m |
| Memory (min) | 2GB |
| Memory (recommended) | 4GB |
| Health Check | `/api/health` |

## Checklist

Before deploying:

- [ ] Build pack set to "Dockerfile"
- [ ] Build args configured: `NODEJS_VERSION=22`
- [ ] Environment variables set: `AUTH_SECRET`, `KEY_VAULTS_SECRET`, `DATABASE_URL`
- [ ] Database is accessible
- [ ] Port 3210 is available
- [ ] Sufficient resources (4GB+ RAM)
- [ ] Build timeout set to 30m+
- [ ] Health checks configured
