# Troubleshooting

Common issues and solutions for the ${PLATFORM_NAME} platform.

## 📚 Troubleshooting Guides

- [Common Issues](./common-issues.md) - Frequently encountered problems and solutions

## 🔍 Issue Categories

### Port Issues
- Port allocation conflicts
- Services not accessible
- Port already in use errors

### Database Issues
- Connection failures
- Migration errors
- Schema synchronization problems

### Docker Issues
- Container startup failures
- Network connectivity
- Volume mounting problems

### Environment Issues
- Environment variables not loading
- Configuration mismatches
- Path resolution errors

## 🚨 Quick Diagnostics

### Check Platform Status
```bash
cd /var/services/homes/jungsam/dev/dockers/platforms/${PLATFORM_NAME}
docker-compose ps
```

### Check Port Allocation
```bash
cd /var/services/homes/jungsam/dev/dockers/_manager
node scripts/port-allocator.js platform <platform-sn>
```

### Check Database Connection
```bash
# MySQL
docker exec <platform>_mysql mysql -u root -p

# PostgreSQL
docker exec <platform>_postgres psql -U postgres
```

### Check Logs
```bash
docker-compose logs -f [service-name]
```

## 📖 How to Use This Section

### 1. Search for Your Error
Use Ctrl+F to search for specific error messages in [Common Issues](./common-issues.md)

### 2. Follow Step-by-Step Solutions
Each issue includes:
- Problem description
- Root cause
- Step-by-step solution
- Prevention tips

### 3. Still Stuck?
- Check [Platform Architecture](../02-architecture/platform-overview.md) for system understanding
- Review [Development Workflow](../00-getting-started/development-workflow.md)
- Ask in project communication channels

## 🔗 Related Documentation

- [Platform Architecture](../02-architecture/platform-overview.md) - Understanding system components
- [Development Workflow](../00-getting-started/development-workflow.md) - Correct development process
- [Standards](../01-standards/) - Following conventions prevents issues

---

**Last Updated**: 2024-10-20
