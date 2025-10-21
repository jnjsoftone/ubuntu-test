# Database Management Guidelines

This document provides database management guidelines for the ${PLATFORM_NAME} platform.

## 🗄️ Database Architecture

### Supported Databases
- **PostgreSQL** (Recommended for metadata-driven development)
- **MySQL/MariaDB** (Alternative option)

### Database Structure
```
Platform Database (Shared)
└─ Project Schemas/Databases
   ├─ Project 1 Schema
   ├─ Project 2 Schema
   └─ Project N Schema
```

## 📊 Schema Management

### Naming Conventions
- **Tables**: `snake_case` (e.g., `user_profiles`, `blog_posts`)
- **Columns**: `snake_case` (e.g., `created_at`, `user_id`)
- **Indexes**: `idx_<table>_<column>` (e.g., `idx_users_email`)
- **Foreign Keys**: `fk_<table>_<ref_table>` (e.g., `fk_posts_users`)

### Standard Columns
All tables should include:
```sql
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
deleted_at TIMESTAMP NULL  -- For soft deletes
```

## 🔄 Migration Management

### Migration Files
```bash
migrations/
├── 001_create_users_table.sql
├── 002_create_posts_table.sql
├── 003_add_user_indexes.sql
└── 004_add_soft_delete_columns.sql
```

### Migration Commands
```bash
# Generate migration
npm run migration:generate -- -n CreateUsersTable

# Run migrations
npm run migration:run

# Revert last migration
npm run migration:revert

# Show migration status
npm run migration:show
```

### Migration Best Practices
1. **One Change Per Migration**: Each migration should handle one logical change
2. **Reversible**: Always provide `down` migration
3. **Idempotent**: Safe to run multiple times
4. **Tested**: Test migrations on development environment first
5. **Sequential**: Maintain sequential numbering

## 🔐 Security Guidelines

### Connection Security
- Use SSL/TLS for database connections
- Store credentials in environment variables
- Use connection pooling
- Implement read replicas for scaling

### Access Control
```sql
-- Create application user with limited privileges
CREATE USER app_user WITH PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

### Data Protection
- Encrypt sensitive data at rest
- Use parameterized queries (prevent SQL injection)
- Implement row-level security for multi-tenant applications
- Regular backups with encryption

## 📈 Performance Optimization

### Indexing Strategy
```sql
-- Primary key indexes (automatic)
-- Foreign key indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- Query-specific indexes
CREATE INDEX idx_posts_status_created ON posts(status, created_at DESC);

-- Partial indexes for filtered queries
CREATE INDEX idx_active_users ON users(email) WHERE deleted_at IS NULL;

-- Full-text search indexes (PostgreSQL)
CREATE INDEX idx_posts_search ON posts USING GIN(to_tsvector('english', title || ' ' || content));
```

### Query Optimization
- Use `EXPLAIN ANALYZE` to understand query plans
- Avoid `SELECT *`, specify columns
- Use pagination for large result sets
- Implement query result caching
- Use database views for complex queries

### Connection Pooling
```typescript
// Example using pg-pool
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // Maximum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## 🗃️ Backup and Recovery

### Backup Strategy
```bash
# Daily full backup
pg_dump -U postgres -d mydb -F c -f backup_$(date +%Y%m%d).dump

# Backup with compression
pg_dump -U postgres -d mydb -F c -Z 9 -f backup.dump.gz

# Backup specific schema
pg_dump -U postgres -d mydb -n public -f schema_backup.sql
```

### Recovery
```bash
# Restore from backup
pg_restore -U postgres -d mydb -F c backup.dump

# Restore from SQL file
psql -U postgres -d mydb -f backup.sql
```

### Backup Schedule
- **Full Backup**: Daily at 2 AM
- **Incremental Backup**: Every 6 hours
- **Retention**: Keep 7 daily, 4 weekly, 12 monthly backups
- **Off-site Storage**: Sync backups to cloud storage

## 🔍 Monitoring

### Key Metrics
- Connection count and pool utilization
- Query execution time
- Slow query log
- Database size and growth rate
- Index usage statistics
- Cache hit ratio

### Monitoring Tools
- **PostgreSQL**: pg_stat_statements, pgBadger
- **MySQL**: Performance Schema, slow query log
- **APM Tools**: New Relic, Datadog, Prometheus

### Alerts
Set up alerts for:
- High connection count (> 80% of max)
- Slow queries (> 1 second)
- Database size growth (> 10% per day)
- Replication lag (> 10 seconds)
- Failed backup jobs

## 🧪 Testing

### Database Testing Strategy
```typescript
// Example using Jest
describe('User Database Operations', () => {
  beforeEach(async () => {
    // Set up test database
    await db.migrate.latest();
    await db.seed.run();
  });

  afterEach(async () => {
    // Clean up
    await db.migrate.rollback();
  });

  it('should create user', async () => {
    const user = await createUser({
      email: 'test@example.com',
      name: 'Test User',
    });

    expect(user.id).toBeDefined();
    expect(user.email).toBe('test@example.com');
  });
});
```

## 📚 Related Documents

- [Metadata Schema Definition](../../architecture/02-metadata-schema.md)
- [Development Workflow](../development/01-development-workflow.md)
- [GraphQL API Design](../../api/01-graphql-design.md)
