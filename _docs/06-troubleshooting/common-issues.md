# Common Issues and Solutions

This document lists common issues and their solutions when developing on the ${PLATFORM_NAME} platform.

> **Language**: For Korean version, see [01-common-issues.kr.md](./01-common-issues.kr.md)

## 🔍 Table of Contents

1. [Port-Related Issues](#port-related-issues)
2. [Database Connection Issues](#database-connection-issues)
3. [Docker-Related Issues](#docker-related-issues)
4. [Code Generation Issues](#code-generation-issues)
5. [GraphQL-Related Issues](#graphql-related-issues)
6. [Environment Variable Issues](#environment-variable-issues)
7. [Git/GitHub Issues](#gitgithub-issues)

---

## Port-Related Issues

### ❌ Problem: "Port already in use" Error
```
Error: listen EADDRINUSE: address already in use :::21201
```

**Cause**: Allocated port is already in use by another process

**Solution**:

```bash
# 1. Check process using the port
lsof -i :21201
# or
netstat -tuln | grep 21201

# 2. Kill the process
kill -9 <PID>

# 3. Check Docker containers
docker ps | grep 21201

# 4. Stop the container
docker stop <CONTAINER_ID>

# 5. Clean up unused containers
docker container prune
```

**Prevention**:
```bash
# Check ports before starting project
npm run port:check

# Use automatic allocation system (no manual port assignment)
node /var/services/homes/jungsam/dev/dockers/_manager/scripts/port-allocator.js project <platform-sn> <project-sn>
```

### ❌ Problem: Port Number Incorrectly Assigned

**Cause**: Manually set ports or incorrect environment variables

**Solution**:
```bash
# 1. Check allocated ports
cat .env | grep PORT

# 2. Recalculate ports
node /var/services/homes/jungsam/dev/dockers/_manager/scripts/port-allocator.js project <platform-sn> <project-sn>

# 3. Regenerate .env file
npm run env:regenerate

# 4. Restart Docker containers
docker-compose down
docker-compose up -d
```

---

## Database Connection Issues

### ❌ Problem: "Connection refused" Error
```
Error: connect ECONNREFUSED ${BASE_IP}:${PLATFORM_POSTGRES_PORT}
```

**Cause**: PostgreSQL server not running or inaccessible

**Solution**:
```bash
# 1. Check PostgreSQL container status
docker ps | grep postgres

# 2. Start container if not running
docker-compose up -d postgres

# 3. Check logs
docker logs ${PLATFORM_NAME}-postgres

# 4. Test connection
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER}

# 5. Check network
docker network ls
docker network inspect ${PLATFORM_NAME}_network
```

**Check Environment Variables**:
```bash
# Check database settings in .env
cat .env | grep -E "POSTGRES|DATABASE"

# Expected output:
# POSTGRES_HOST=1.231.118.217
# POSTGRES_PORT=21202
# POSTGRES_USER=postgres
# DATABASE_URL=postgresql://postgres:password@1.231.118.217:21202/project_name
```

### ❌ Problem: "Database does not exist" Error
```
Error: database "project_myproject" does not exist
```

**Solution**:
```bash
# 1. List databases
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -l

# 2. Create database
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE DATABASE project_myproject;"

# 3. Or use npm script
npm run db:create

# 4. Run migrations
npm run migration:run
```

### ❌ Problem: "Too many connections" Error

**Cause**: Database connection pool exhausted

**Solution**:
```typescript
// Configure connection pool in ormconfig.json
{
  "type": "postgres",
  "extra": {
    "max": 20,                      // Max connections (default: 10)
    "idleTimeoutMillis": 30000,     // Idle timeout
    "connectionTimeoutMillis": 2000 // Connection timeout
  }
}
```

```bash
# Restart application to apply new settings
npm run dev
```

---

## Docker-Related Issues

### ❌ Problem: "Cannot connect to Docker daemon" Error

**Cause**: Docker daemon not running or permission issues

**Solution**:
```bash
# 1. Check Docker status
systemctl status docker

# 2. Start Docker
sudo systemctl start docker

# 3. Add user to docker group (to avoid sudo)
sudo usermod -aG docker $USER

# 4. Apply group changes (logout/login or)
newgrp docker

# 5. Verify
docker ps
```

### ❌ Problem: "No space left on device" Error

**Cause**: Docker disk space full

**Solution**:
```bash
# 1. Check disk usage
docker system df

# 2. Clean up unused resources
docker system prune -a

# 3. Remove unused volumes
docker volume prune

# 4. Remove unused images
docker image prune -a

# 5. Check system disk space
df -h
```

---

## Code Generation Issues

### ❌ Problem: Generated Code Has Errors

**Cause**: Invalid metadata or template issues

**Solution**:
```bash
# 1. Validate metadata
npm run metadata:validate

# 2. Check metadata syntax
cat metadata/tables/users.json | jq .

# 3. Regenerate code
npm run generate:all --force

# 4. Check TypeScript errors
npm run type-check

# 5. If errors persist, check AI prompt
claude-code "Fix TypeScript errors in generated code"
```

### ❌ Problem: Code Generation Fails

**Cause**: Missing dependencies or template files

**Solution**:
```bash
# 1. Install dependencies
npm install

# 2. Check template files exist
ls _templates/

# 3. Reinstall code generators
npm install -D @typeorm/cli graphql-codegen

# 4. Clear cache and regenerate
rm -rf node_modules/.cache
npm run generate:all
```

---

## GraphQL-Related Issues

### ❌ Problem: "Cannot query field" Error
```
Error: Cannot query field "usersAll" on type "Query"
```

**Cause**: Schema not properly registered or naming mismatch

**Solution**:
```bash
# 1. Check GraphQL schema
cat src/schema/users.ts

# 2. Verify resolver registration
cat src/index.ts | grep -A 10 "resolvers"

# 3. Check naming convention
# Queries should follow: {domain}{Entity}{Action}
# Example: usersAll, usersOne, usersByEmail

# 4. Restart server
npm run dev
```

### ❌ Problem: GraphQL Query Returns Null

**Cause**: Resolver not implemented or database query failed

**Solution**:
```bash
# 1. Check resolver implementation
cat src/resolvers/users.ts

# 2. Enable GraphQL debug mode
# In src/index.ts
const server = new ApolloServer({
  typeDefs,
  resolvers,
  debug: true, // Add this
});

# 3. Check database data
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -d project_name -c "SELECT * FROM users;"

# 4. Check logs
npm run dev | grep -i error
```

---

## Environment Variable Issues

### ❌ Problem: Environment Variables Not Loaded

**Cause**: .env file not found or not loaded properly

**Solution**:
```bash
# 1. Check .env file exists
ls -la .env

# 2. Check dotenv is installed
npm list dotenv

# 3. Verify loading in code
// src/index.ts
import dotenv from 'dotenv';
dotenv.config();
console.log('Loaded env vars:', process.env.PROJECT_NAME);

# 4. Check .env syntax (no spaces around =)
# ✅ Good: PROJECT_NAME=myproject
# ❌ Bad: PROJECT_NAME = myproject

# 5. Restart server
npm run dev
```

### ❌ Problem: Undefined Environment Variable

**Cause**: Variable not defined in .env or typo

**Solution**:
```bash
# 1. List all env vars
cat .env

# 2. Check for typo
# ✅ Good: PROJECT_API_PORT
# ❌ Bad: PROJECT_API__PORT (double underscore)

# 3. Add missing variable
echo "MISSING_VAR=value" >> .env

# 4. Use .env.example as reference
diff .env .env.example

# 5. Restart application
npm run dev
```

---

## Git/GitHub Issues

### ❌ Problem: "Permission denied (publickey)" Error

**Cause**: SSH key not configured or not added to GitHub

**Solution**:
```bash
# 1. Check SSH key exists
ls -la ~/.ssh/id_rsa*

# 2. Generate SSH key if missing
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 3. Copy public key
cat ~/.ssh/id_rsa.pub

# 4. Add to GitHub
# Go to: Settings > SSH and GPG keys > New SSH key

# 5. Test connection
ssh -T git@github.com
```

### ❌ Problem: "Repository not found" Error

**Cause**: Repository doesn't exist or no access

**Solution**:
```bash
# 1. Check repository URL
git remote -v

# 2. Verify repository exists on GitHub
# Visit: https://github.com/<username>/<repo>

# 3. Update remote URL if needed
git remote set-url origin git@github.com:<username>/<repo>.git

# 4. Check access permissions
# Ensure you have read/write access to the repository
```

---

## Quick Diagnostic Commands

### System Health Check
```bash
# Check all services
docker ps

# Check ports
lsof -i -P -n | grep LISTEN

# Check databases
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -l

# Check disk space
df -h

# Check memory
free -h
```

### Application Health Check
```bash
# Check environment
cat .env | grep -v "PASSWORD\|SECRET"

# Check TypeScript
npm run type-check

# Check tests
npm run test

# Check dependencies
npm outdated
```

---

## Getting Help

### Before Asking for Help

1. **Check this document** - Search for your error message (Ctrl+F)
2. **Check logs** - Look at application and Docker logs
3. **Verify environment** - Ensure .env is correct
4. **Try regenerating** - Sometimes regenerating code fixes issues

### How to Ask for Help

Include the following information:

```markdown
**Problem**: [Brief description]

**Error Message**:
```
[Full error message with stack trace]
```

**Environment**:
- Platform: ${PLATFORM_NAME}
- Project: [project-name]
- Node version: [run: node -v]
- Docker version: [run: docker -v]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Error occurs]

**What I've Tried**:
- [Thing 1]
- [Thing 2]
```

---

**Last Updated**: 2024-10-19
**Version**: 1.0.0

> **See Also**:
> - [Development Workflow](../guidelines/02-development-workflow.md) - Standard workflow
> - [Platform Overview](../architecture/01-platform-overview.md) - Architecture reference
