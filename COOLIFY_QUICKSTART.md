# Coolify Deployment Quickstart Guide

## You Selected: Docker Compose (Full Stack) ⭐

This is the **recommended method** for complete self-hosted deployment.

---

## 🚀 5-Minute Setup in Coolify

### 1. Create Application

1. Open Coolify Dashboard
2. Click **"New Resource"** → **"Application"**
3. Select your Git repository
4. Choose branch: `main` (or your branch)

### 2. Select Build Pack

**⚠️ CRITICAL STEP**

```
Build Pack: Docker Compose  ← Select this!
```

**Do NOT select:**
- ❌ Dockerfile
- ❌ Nixpacks
- ❌ Automatic

### 3. Configure Path

```
Compose Path: docker-compose/deploy/docker-compose.yml
Base Directory: /
```

### 4. Add Environment Variables

**Copy from:** `docker-compose/deploy/.env.example`

**Required (minimum):**

```bash
# Generate these with: openssl rand -base64 32
KEY_VAULTS_SECRET=YOUR_KEY_VAULTS_SECRET_HERE
AUTH_SECRET=YOUR_AUTH_SECRET_HERE

# Database
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD
LOBE_DB_NAME=lobechat

# S3 Storage
RUSTFS_ACCESS_KEY=admin
RUSTFS_SECRET_KEY=YOUR_RUSTFS_PASSWORD
RUSTFS_LOBE_BUCKET=lobe

# Application
APP_URL=http://localhost:3210
PORT=3210
```

**Optional (for AI features):**

```bash
# OpenAI (example)
OPENAI_API_KEY=sk-your-key-here

# Or any other provider
ANTHROPIC_API_KEY=sk-ant-your-key-here
```

### 5. Configure Network

```
Port: 3210
```

Coolify will auto-detect the port from docker-compose.yml.

### 6. Deploy!

1. Click **"Deploy"** button
2. Wait **3-5 minutes** for all services to start
3. Monitor: **Logs** tab

### 7. Access Your App

```
http://your-server-ip:3210
```

Or configure a custom domain in Coolify Settings.

---

## 📊 What Gets Deployed

| Service | Port | RAM | Purpose |
|---------|------|-----|---------|
| LobeHub | 3210 | 4GB | Main application |
| PostgreSQL | 5432 | 2GB | Database |
| Redis | 6379 | 512MB | Cache |
| RustFS | 9000 | 1GB | S3 storage |
| Searxng | - | 256MB | Search |

**Total Resources**: ~7.5GB RAM, 4.5 CPU

---

## ✅ Verification

### Check All Services Running

In Coolify Dashboard:
1. Go to **Application** → **Logs**
2. Look for green checkmarks on all services
3. No error messages in logs

### Test Health Check

```bash
curl http://your-server-ip:3210/api/health
```

Should return: `{"status":"ok"}`

### Access Application

Open browser: `http://your-server-ip:3210`

You should see the LobeHub interface.

---

## 🛠️ Troubleshooting

### Build Fails

**Check:**
- [ ] Selected "Docker Compose" (not Dockerfile/Nixpacks)
- [ ] Sufficient RAM (4GB+ available)
- [ ] All required env vars set
- [ ] Internet connection for dependencies

**Solution**: Enable "Force rebuild without cache"

### Services Not Starting

**Check logs:**
1. Click **Application** → **Logs**
2. Look for specific service errors
3. Common issues:
   - PostgreSQL: `POSTGRES_PASSWORD` not set
   - RustFS: `RUSTFS_SECRET_KEY` missing
   - LobeHub: Database connection failed

**Solution**: Wait for dependencies to start (PostgreSQL takes 1-2 min)

### Can't Access Application

**Check:**
- [ ] Port 3210 not blocked by firewall
- [ ] All containers running
- [ ] Health checks passing

**Solution**:
```bash
# Check containers
docker ps | grep lobe

# Check logs
docker logs lobehub
```

---

## 🎯 Next Steps

### 1. Configure Domain (Optional)

In Coolify:
1. Go to **Settings** → **Domains**
2. Add your domain
3. Update `APP_URL` env var
4. Coolify auto-configures SSL

### 2. Add AI Provider Keys

In Coolify:
1. Go to **Settings** → **Environment Variables**
2. Add your API keys:
   - `OPENAI_API_KEY`
   - `ANTHROPIC_API_KEY`
   - Or any other provider

### 3. Configure Email (Optional)

For email verification:

```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

---

## 📚 Full Documentation

See: [COOLIFY_DEPLOYMENT.md](./COOLIFY_DEPLOYMENT.md)

For:
- All 3 deployment methods
- Detailed troubleshooting
- Performance optimization
- Security best practices

---

## 🆘 Need Help?

**Check Logs:**
- Coolify Dashboard → Application → Logs

**Common Issues:**
- Build timeout → Increase to 45m
- Out of memory → Check available RAM
- Database errors → Verify `DATABASE_URL`

**Resources:**
- Coolify Docs: https://coolify.io/docs
- LobeHub Docs: https://lobehub.com/docs
- GitHub Issues: https://github.com/lobehub/lobe-chat/issues

---

## 🎉 Success!

Your LobeHub instance is now running with:
- ✅ Full database (PostgreSQL)
- ✅ Caching (Redis)
- ✅ Object storage (RustFS)
- ✅ Search (Searxng)
- ✅ All AI provider support

Enjoy your self-hosted AI workspace! 🚀
