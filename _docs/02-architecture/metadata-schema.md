# Metadata Schema Definition

This document defines the metadata schema, which is the core of metadata-driven code generation.

## 📋 Metadata File Structure

```
metadata/
├── tables/              # Table definitions
│   ├── users.json
│   ├── posts.json
│   ├── comments.json
│   └── categories.json
├── relationships/       # Relationship definitions
│   ├── user-posts.json
│   ├── post-comments.json
│   └── post-categories.json
├── apis/               # API definitions (optional)
│   └── custom-queries.json
└── config.json         # Global configuration
```

## 🗂️ Table Metadata Schema

### Basic Structure
```typescript
interface TableMetadata {
  tableName: string;                    // Table name (snake_case)
  description?: string;                 // Table description
  columns: ColumnDefinition[];          // Column definitions
  indexes?: IndexDefinition[];          // Index definitions
  uniqueConstraints?: UniqueConstraint[]; // Unique constraints
  checks?: CheckConstraint[];           // Check constraints
  softDelete?: boolean;                 // Soft delete enabled
  timestamps?: boolean;                 // Auto-add created_at, updated_at
  auditing?: boolean;                   // Add created_by, updated_by
  graphql?: GraphQLConfig;              // GraphQL configuration
}
```

### Complete Example
```json
{
  "tableName": "posts",
  "description": "Blog posts table",
  "timestamps": true,
  "softDelete": true,
  "auditing": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid",
      "comment": "Unique identifier"
    },
    {
      "name": "title",
      "type": "varchar",
      "length": 200,
      "nullable": false,
      "comment": "Post title"
    },
    {
      "name": "slug",
      "type": "varchar",
      "length": 250,
      "nullable": false,
      "unique": true,
      "comment": "URL-friendly title"
    },
    {
      "name": "content",
      "type": "text",
      "nullable": false,
      "comment": "Post content (Markdown)"
    },
    {
      "name": "excerpt",
      "type": "varchar",
      "length": 500,
      "nullable": true,
      "comment": "Summary"
    },
    {
      "name": "status",
      "type": "enum",
      "enum": ["DRAFT", "PUBLISHED", "ARCHIVED"],
      "default": "DRAFT",
      "nullable": false,
      "comment": "Post status"
    },
    {
      "name": "view_count",
      "type": "int",
      "default": 0,
      "nullable": false,
      "comment": "View count"
    },
    {
      "name": "published_at",
      "type": "timestamp",
      "nullable": true,
      "comment": "Publication date"
    },
    {
      "name": "user_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "users",
        "column": "id",
        "onDelete": "CASCADE",
        "onUpdate": "CASCADE"
      },
      "comment": "Author ID"
    },
    {
      "name": "category_id",
      "type": "uuid",
      "nullable": true,
      "foreignKey": {
        "table": "categories",
        "column": "id",
        "onDelete": "SET NULL",
        "onUpdate": "CASCADE"
      },
      "comment": "Category ID"
    },
    {
      "name": "metadata",
      "type": "jsonb",
      "nullable": true,
      "default": "{}",
      "comment": "Additional metadata (tags, SEO, etc.)"
    }
  ],
  "indexes": [
    {
      "name": "idx_posts_user_id",
      "columns": ["user_id"],
      "comment": "Optimize queries by author"
    },
    {
      "name": "idx_posts_status",
      "columns": ["status"],
      "comment": "Optimize filtering by status"
    },
    {
      "name": "idx_posts_published_at",
      "columns": ["published_at"],
      "order": "DESC",
      "where": "status = 'PUBLISHED'",
      "comment": "Optimize sorting published posts"
    },
    {
      "name": "idx_posts_slug",
      "columns": ["slug"],
      "unique": true,
      "comment": "Prevent slug duplication and optimize lookups"
    }
  ],
  "uniqueConstraints": [
    {
      "name": "uq_posts_title_user",
      "columns": ["title", "user_id"],
      "comment": "Prevent duplicate titles per user"
    }
  ],
  "checks": [
    {
      "name": "chk_posts_view_count",
      "expression": "view_count >= 0",
      "comment": "View count must be non-negative"
    }
  ],
  "graphql": {
    "queries": {
      "findOne": true,
      "findMany": true,
      "count": true
    },
    "mutations": {
      "create": true,
      "update": true,
      "delete": true
    },
    "subscriptions": {
      "onCreate": true,
      "onUpdate": false,
      "onDelete": false
    }
  }
}
```

## 📊 Column Definition Schema

### ColumnDefinition
```typescript
interface ColumnDefinition {
  name: string;                     // Column name (snake_case)
  type: DataType;                   // Data type
  length?: number;                  // Length (varchar, char, etc.)
  precision?: number;               // Precision (decimal)
  scale?: number;                   // Decimal places (decimal)
  primaryKey?: boolean;             // Is primary key
  generated?: GenerationType;       // Auto-generation type
  nullable?: boolean;               // Allow NULL (default: true)
  unique?: boolean;                 // Is unique
  default?: any;                    // Default value
  enum?: string[];                  // Enum value list
  foreignKey?: ForeignKeyDefinition; // Foreign key definition
  onUpdate?: string;                // Action on UPDATE
  comment?: string;                 // Column description
  exclude?: ExcludeTarget[];        // Exclude targets (graphql, api, etc.)
  validation?: ValidationRules;      // Validation rules
}
```

### Data Types
```typescript
type DataType =
  // Numeric
  | 'int' | 'integer' | 'bigint' | 'smallint'
  | 'decimal' | 'numeric' | 'float' | 'double'

  // String
  | 'varchar' | 'char' | 'text'

  // UUID
  | 'uuid'

  // Date/Time
  | 'date' | 'time' | 'timestamp' | 'datetime'

  // Boolean
  | 'boolean' | 'bool'

  // JSON
  | 'json' | 'jsonb'

  // Binary
  | 'bytea' | 'blob'

  // Enum
  | 'enum'

  // Array (PostgreSQL)
  | 'text[]' | 'int[]' | 'uuid[]';
```

### Generation Types
```typescript
type GenerationType =
  | 'uuid'        // Auto-generate UUID
  | 'increment'   // Auto-increment (AUTO_INCREMENT)
  | 'identity'    // IDENTITY (PostgreSQL 10+)
  | 'rowid';      // ROWID (Oracle)
```

### Foreign Key Definition
```typescript
interface ForeignKeyDefinition {
  table: string;          // Referenced table
  column: string;         // Referenced column
  onDelete?: ReferentialAction;  // Action on DELETE
  onUpdate?: ReferentialAction;  // Action on UPDATE
}

type ReferentialAction =
  | 'CASCADE'      // Cascade action
  | 'SET NULL'     // Set to NULL
  | 'SET DEFAULT'  // Set to default value
  | 'RESTRICT'     // Restrict (throw error)
  | 'NO ACTION';   // No action
```

### Validation Rules
```typescript
interface ValidationRules {
  min?: number;              // Minimum value (number)
  max?: number;              // Maximum value (number)
  minLength?: number;        // Minimum length (string)
  maxLength?: number;        // Maximum length (string)
  pattern?: string;          // Regex pattern
  email?: boolean;           // Email format validation
  url?: boolean;             // URL format validation
  custom?: string;           // Custom validation function name
}
```

## 🔗 Relationship Metadata Schema

### RelationshipMetadata
```typescript
interface RelationshipMetadata {
  name: string;                     // Relationship name
  type: RelationType;               // Relationship type
  from: RelationEndpoint;           // From entity
  to: RelationEndpoint;             // To entity
  cascade?: CascadeOptions;         // Cascade options
  eager?: boolean;                  // Eager loading
  lazy?: boolean;                   // Lazy loading
  nullable?: boolean;               // Allow NULL
  comment?: string;                 // Relationship description
}

type RelationType =
  | 'one-to-one'
  | 'one-to-many'
  | 'many-to-one'
  | 'many-to-many';

interface RelationEndpoint {
  table: string;        // Table name
  column?: string;      // Foreign key column (many-to-one, one-to-one)
  relation: string;     // Relation property name (used in Entity)
}

interface CascadeOptions {
  insert?: boolean;     // CASCADE INSERT
  update?: boolean;     // CASCADE UPDATE
  delete?: boolean;     // CASCADE DELETE
}
```

### One-to-Many Example
```json
{
  "name": "user-posts",
  "type": "one-to-many",
  "from": {
    "table": "users",
    "relation": "posts"
  },
  "to": {
    "table": "posts",
    "column": "user_id",
    "relation": "user"
  },
  "cascade": {
    "insert": false,
    "update": true,
    "delete": true
  },
  "eager": false,
  "comment": "1:N relationship between users and posts"
}
```

### Many-to-Many Example
```json
{
  "name": "posts-tags",
  "type": "many-to-many",
  "from": {
    "table": "posts",
    "relation": "tags"
  },
  "to": {
    "table": "tags",
    "relation": "posts"
  },
  "joinTable": {
    "name": "post_tags",
    "columns": [
      {
        "name": "post_id",
        "type": "uuid",
        "foreignKey": { "table": "posts", "column": "id", "onDelete": "CASCADE" }
      },
      {
        "name": "tag_id",
        "type": "uuid",
        "foreignKey": { "table": "tags", "column": "id", "onDelete": "CASCADE" }
      },
      {
        "name": "created_at",
        "type": "timestamp",
        "default": "now()"
      }
    ]
  },
  "comment": "N:M relationship between posts and tags"
}
```

## ⚙️ Global Configuration (config.json)

```json
{
  "project": {
    "name": "my-project",
    "version": "1.0.0",
    "description": "My awesome project"
  },
  "database": {
    "type": "postgres",
    "naming": {
      "strategy": "snake_case",
      "tablePrefix": "",
      "columnPrefix": ""
    }
  },
  "graphql": {
    "playground": true,
    "introspection": true,
    "naming": {
      "strategy": "camelCase"
    },
    "pagination": {
      "default": 20,
      "max": 100
    }
  },
  "generation": {
    "overwrite": {
      "entities": true,
      "schema": true,
      "resolvers": false,
      "services": false
    },
    "templates": {
      "entity": "templates/entity.hbs",
      "resolver": "templates/resolver.hbs",
      "service": "templates/service.hbs"
    }
  },
  "features": {
    "softDelete": true,
    "timestamps": true,
    "auditing": false,
    "versioning": false
  }
}
```

## 🎨 GraphQL Configuration

### GraphQLConfig
```typescript
interface GraphQLConfig {
  queries?: {
    findOne?: boolean | string;      // true or custom query name
    findMany?: boolean | string;
    count?: boolean | string;
    custom?: CustomQuery[];
  };
  mutations?: {
    create?: boolean | string;
    update?: boolean | string;
    delete?: boolean | string;
    custom?: CustomMutation[];
  };
  subscriptions?: {
    onCreate?: boolean | string;
    onUpdate?: boolean | string;
    onDelete?: boolean | string;
    custom?: CustomSubscription[];
  };
  exclude?: string[];                // Field exclusion list
  rename?: { [key: string]: string }; // Field renaming
}
```

### Custom Query Example
```json
{
  "graphql": {
    "queries": {
      "findOne": "post",
      "findMany": "posts",
      "count": "postCount",
      "custom": [
        {
          "name": "publishedPosts",
          "description": "Query only published posts",
          "args": [
            { "name": "limit", "type": "Int", "default": 20 },
            { "name": "offset", "type": "Int", "default": 0 }
          ],
          "return": "[Post!]!",
          "filter": { "status": "PUBLISHED" }
        }
      ]
    },
    "mutations": {
      "custom": [
        {
          "name": "publishPost",
          "description": "Publish a post",
          "args": [{ "name": "id", "type": "ID!" }],
          "return": "Post!",
          "implementation": "custom/mutations/publish-post.ts"
        }
      ]
    },
    "exclude": ["password", "deleted_at"],
    "rename": {
      "user_id": "authorId"
    }
  }
}
```

## 🔍 Validation Rules

Automatic validation when defining metadata:

### Required Validations
- ✅ Duplicate table name check
- ✅ Duplicate column name check (within same table)
- ✅ Foreign key reference table/column existence check
- ✅ Data type validity check
- ✅ Enum value validity check

### Warning Validations
- ⚠️ Missing primary key
- ⚠️ Missing index (on foreign keys)
- ⚠️ Missing timestamp fields
- ⚠️ Too long varchar (performance consideration)

### Validation Commands
```bash
# Validate metadata
npm run metadata:validate

# Validate specific file only
npm run metadata:validate -- metadata/tables/users.json

# Generate detailed report
npm run metadata:validate -- --verbose
```

## 📖 Example Collection

### Users Table (users.json)
```json
{
  "tableName": "users",
  "description": "User information",
  "timestamps": true,
  "softDelete": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid"
    },
    {
      "name": "email",
      "type": "varchar",
      "length": 255,
      "unique": true,
      "nullable": false,
      "validation": { "email": true }
    },
    {
      "name": "password",
      "type": "varchar",
      "length": 255,
      "nullable": false,
      "exclude": ["graphql", "api"]
    },
    {
      "name": "role",
      "type": "enum",
      "enum": ["USER", "ADMIN", "MODERATOR"],
      "default": "USER",
      "nullable": false
    },
    {
      "name": "profile",
      "type": "jsonb",
      "default": "{}",
      "comment": "Profile information (name, avatar, etc.)"
    }
  ],
  "graphql": {
    "queries": { "findOne": true, "findMany": true },
    "mutations": { "create": true, "update": true, "delete": true },
    "exclude": ["password"]
  }
}
```

### Comments Table (comments.json)
```json
{
  "tableName": "comments",
  "timestamps": true,
  "softDelete": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid"
    },
    {
      "name": "content",
      "type": "text",
      "nullable": false,
      "validation": { "minLength": 1, "maxLength": 5000 }
    },
    {
      "name": "post_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "posts",
        "column": "id",
        "onDelete": "CASCADE"
      }
    },
    {
      "name": "user_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "users",
        "column": "id",
        "onDelete": "CASCADE"
      }
    },
    {
      "name": "parent_id",
      "type": "uuid",
      "nullable": true,
      "foreignKey": {
        "table": "comments",
        "column": "id",
        "onDelete": "CASCADE"
      },
      "comment": "Parent comment ID for nested comments"
    }
  ],
  "indexes": [
    { "columns": ["post_id"] },
    { "columns": ["user_id"] }
  ]
}
```

## 🔄 Migration Generation

Auto-generate migrations on metadata changes:

```bash
# Detect metadata changes and generate migration
npm run migration:generate -- -n AddProfileToUsers

# Check generated migration file
cat migrations/1634567890123-AddProfileToUsers.ts
```

## 📚 Related Documents

- [Development Workflow](../guidelines/02-development-workflow.md)
- [Database Management](../guidelines/03-database-management.md)
- [GraphQL API Design](../api/01-graphql-design.md)
