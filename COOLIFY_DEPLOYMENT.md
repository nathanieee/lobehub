# Coolify Deployment Guide for LobeHub

This guide provides comprehensive instructions for deploying LobeHub using Coolify.

## Quick Start - Choose Your Deployment Method

LobeHub supports **three deployment methods** in Coolify. Choose based on your infrastructure:

| Method | Services | RAM | Use Case | Difficulty |
|--------|----------|-----|----------|------------|
| **Docker Compose** ⭐ | All (App + DB + Redis + S3) | 4GB+ | Full self-hosted deployment | Medium |
| **Dockerfile** | App only | 2GB+ | With external services | Easy |
| **Nixpacks** | App only | 2GB+ | Quick deployment | Easy |

**Recommendation**: Use **Docker Compose** for complete self-hosted deployment with all services included.

---

## Method 1: Docker Compose (Recommended) ⭐

Deploys: **LobeHub + PostgreSQL + Redis + RustFS (S3) + Searxng**

### Prerequisites

- Coolify instance (v4.0+)
- **4GB+ RAM** available
- **2+ CPU cores** recommended
- 30-60 minutes for initial build

### Step-by-Step Deployment

#### 1. Create New Application in Coolify

1. Go to Coolify Dashboard
2. Click **"New Resource"** → **"Application"**
3. Select your Git repository
4. Choose the branch to deploy

#### 2. Configure Build Pack

**Critical Settings:**

```
Build Pack: Docker Compose
Compose Path: docker-compose/deploy/docker-compose.yml
Base Directory: / (root)
```

⚠️ **Important**: Do NOT select "Dockerfile" or "Nixpacks" - choose **"Docker Compose"**

#### 3. Configure Environment Variables

Copy these from `docker-compose/deploy/.env.example`:

**Required Variables:**

```bash
# Security (generate with: openssl rand -base64 32)
KEY_VAULTS_SECRET=your_key_vaults_secret_here
AUTH_SECRET=your_auth_secret_here

# Database
POSTGRES_PASSWORD=your_secure_password_here
LOBE_DB_NAME=lobechat

# S3/RustFS
RUSTFS_ACCESS_KEY=admin
RUSTFS_SECRET_KEY=your_rustfs_password
RUSTFS_LOBE_BUCKET=lobe

# Application
APP_URL=https://your-domain.com
PORT=3210
```

**Optional Variables:**

```bash
# AI Provider Keys
OPENAI_API_KEY=sk-xxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx

# Email (for verification)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-email@example.com
SMTP_PASS=your-password
```

#### 4. Network Configuration

```
Port: 3210
Health Check: /api/health
Check Interval: 30s
Timeout: 10s
Retries: 3
```

#### 5. Deploy

1. Click **"Deploy"**
2. Wait for all services to start (3-5 minutes)
3. Monitor logs: **Logs → Deployment Logs**
4. Verify health checks pass

#### 6. Access Your Application

```
URL: http://your-server-ip:3210
Or configure domain in Coolify Settings
```

### What Gets Deployed

The Docker Compose deployment includes:

- **lobe**: LobeHub application (Port 3210)
- **postgresql**: ParadeDB database (Port 5432)
- **redis**: Redis cache (Port 6379)
- **rustfs**: S3-compatible storage (Port 9000)
- **searxng**: Search engine (internal)
- **network-service**: Networking container

### Resource Usage

Automatic limits configured:
```
Application: 4GB RAM, 2 CPU
PostgreSQL: 2GB RAM, 1 CPU
Redis: 512MB RAM, 0.5 CPU
RustFS: 1GB RAM, 1 CPU
Total: ~7.5GB RAM, 4.5 CPU
```

### Troubleshooting Docker Compose

#### Error: "Service failed to build"

**Solution**: Check build logs for specific errors
- Ensure sufficient RAM (4GB+ available)
- Check internet connectivity for dependencies
- Try "Force rebuild without cache"

#### Error: "Database connection failed"

**Solution**:
1. Wait for PostgreSQL health check (check logs)
2. Verify `DATABASE_URL` environment variable
3. Ensure postgresql container is running: `docker ps | grep postgres`

#### Error: "S3/RustFS connection failed"

**Solution**:
1. Check RustFS is healthy: `docker logs lobe-rustfs`
2. Verify S3 credentials in environment variables
3. Ensure `RUSTFS_LOBE_BUCKET` exists

#### Application not starting

**Check**:
1. All containers running: `docker ps`
2. Database migrations completed
3. Required secrets set: `AUTH_SECRET`, `KEY_VAULTS_SECRET`
4. Port 3210 not in use

---

## Method 2: Dockerfile (App Only)

Deploys: **LobeHub application only**

### Prerequisites

- Coolify instance (v4.0+)
- **2GB+ RAM** available
- **External PostgreSQL** database
- **External Redis** (optional but recommended)
- **External S3** or object storage

### Step-by-Step Deployment

#### 1. Configure Build Pack

```
Build Pack: Dockerfile
Dockerfile Path: Dockerfile
Build Context: . (root)
```

#### 2. Build Arguments

```bash
NODEJS_VERSION=22
BUILDKIT_INLINE_CACHE=1
```

#### 3. Environment Variables

**Required:**

```bash
# Database
DATABASE_URL=postgresql://user:password@external-host:5432/dbname
DATABASE_DRIVER=node

# Security
AUTH_SECRET=your_auth_secret
KEY_VAULTS_SECRET=your_key_vaults_secret

# Application
APP_URL=https://your-domain.com
PORT=3210
```

**Optional (Redis):**

```bash
REDIS_URL=redis://external-host:6379
REDIS_PREFIX=lobechat
```

**Optional (S3):**

```bash
S3_ENDPOINT=https://your-s3-compatible-storage
S3_BUCKET=your-bucket-name
S3_ACCESS_KEY_ID=your-access-key
S3_SECRET_ACCESS_KEY=your-secret-key
S3_ENABLE_PATH_STYLE=1
```

#### 4. Deploy

1. Click **"Deploy"**
2. Wait for build (10-20 minutes)
3. Monitor logs

### Troubleshooting Dockerfile

#### Build timeout

**Solution**:
- Increase timeout to 45m
- Enable "Force rebuild without cache"
- Check server resources

#### Module not found errors

**Solution**:
- Verify all environment variables set
- Check `DATABASE_URL` is correct
- Ensure external services accessible

---

## Method 3: Nixpacks (App Only)

Deploys: **LobeHub application only**

### When to Use

- Quick deployments without external services
- Testing and development
- When you don't need full stack

### Step-by-Step Deployment

#### 1. Configure Build Pack

```
Build Pack: Nixpacks
Base Directory: /
```

#### 2. Environment Variables

Same as Dockerfile method above.

#### 3. Deploy

1. Click **"Deploy"**
2. Wait for build (15-25 minutes)

### Limitations

⚠️ **Nixpacks cannot deploy additional services** - only the application container.

---

## Common Issues & Solutions

### Issue: Build fails with "exit code 1"

**Cause**: Resource constraints or dependency issues

**Solutions**:
1. Check available RAM (need 4GB+ for Docker Compose)
2. Enable "Force rebuild without cache"
3. Verify build arguments set correctly
4. Check logs for specific error messages

### Issue: Application not accessible

**Check**:
1. Port 3210 not blocked by firewall
2. Domain DNS configured correctly
3. Health checks passing in Coolify
4. All containers running

### Issue: Database migration errors

**Solution**:
1. Ensure `DATABASE_URL` is correct
2. Check PostgreSQL is accessible
3. Verify database user has permissions
4. Check logs: `Logs → Application Logs`

### Issue: High memory usage

**For Docker Compose**:
- Expected: ~7GB total
- Reduce PostgreSQL memory in docker-compose.yml
- Disable RustFS if using external S3

**For Dockerfile/Nixpacks**:
- Expected: ~2GB
- Check for memory leaks in logs
- Restart application

---

## Performance Optimization

### Build Caching

Enable for faster rebuilds:

```bash
# Build Arguments
BUILDKIT_INLINE_CACHE=1

# Environment
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
```

### Database Optimization

For production:
- Use managed PostgreSQL (AWS RDS, etc.)
- Enable connection pooling
- Regular backups

### Redis Caching

Configure for better performance:

```bash
REDIS_URL=redis://external-host:6379
REDIS_PREFIX=lobechat
REDIS_TLS=0
```

---

## Migration from Other Platforms

### From Vercel

1. Export environment variables
2. Import into Coolify
3. Update `APP_URL`
4. Migrate database
5. Update DNS

### From Local Development

1. Export `.env` variables
2. Configure in Coolify
3. Update `DATABASE_URL` to production
4. Deploy and verify

---

## Security Best Practices

1. **Generate strong secrets**:
   ```bash
   openssl rand -base64 32
   ```

2. **Use HTTPS**:
   - Configure SSL certificate in Coolify
   - Update `APP_URL` to https://

3. **Restrict database access**:
   - Don't expose PostgreSQL ports publicly
   - Use strong passwords
   - Regular backups

4. **Monitor logs**:
   - Check Coolify logs regularly
   - Set up alerts for errors

---

## Support & Resources

- **Coolify Docs**: https://coolify.io/docs
- **LobeHub Docs**: https://lobehub.com/docs
- **Issue Tracker**: https://github.com/lobehub/lobe-chat/issues

---

## Quick Reference

### Docker Compose (Recommended)

| Setting | Value |
|---------|-------|
| Build Pack | Docker Compose |
| Compose Path | `docker-compose/deploy/docker-compose.yml` |
| Port | 3210 |
| RAM | 4GB+ |
| Build Time | 30-60 min |

### Dockerfile

| Setting | Value |
|---------|-------|
| Build Pack | Dockerfile |
| Build Args | `NODEJS_VERSION=22` |
| Port | 3210 |
| RAM | 2GB+ |
| Build Time | 10-20 min |

### Nixpacks

| Setting | Value |
|---------|-------|
| Build Pack | Nixpacks |
| Port | 3210 |
| RAM | 2GB+ |
| Build Time | 15-25 min |

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
