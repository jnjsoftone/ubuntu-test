# 메타데이터 기반 개발 워크플로우 가이드

> PostgreSQL + GraphQL (TypeScript) + Next.js 스택을 위한 범용 메타데이터 기반 개발 가이드

## 목차

1. [개요](#개요)
2. [핵심 개념](#핵심-개념)
3. [데이터베이스 스키마](#데이터베이스-스키마)
4. [개발 워크플로우](#개발-워크플로우)
5. [코드 생성 시스템](#코드-생성-시스템)
6. [프로젝트 관리](#프로젝트-관리)
7. [Best Practices](#best-practices)

---

## 개요

### 메타데이터 기반 개발(Metadata-Driven Development)이란?

메타데이터 기반 개발은 데이터베이스 스키마, API 스키마, UI 컴포넌트 등의 정보를 **중앙 메타데이터 시스템**에 정의하고, 이를 기반으로 실제 코드를 **자동 생성**하는 개발 방법론입니다.

### 주요 이점

- **단일 진실 공급원(Single Source of Truth)**: 메타데이터가 모든 레이어의 기준
- **일관성 보장**: DB, API, UI가 항상 동기화된 상태 유지
- **개발 속도 향상**: 반복적인 CRUD 코드 자동 생성
- **유지보수 용이**: 스키마 변경 시 전체 스택 자동 업데이트
- **타입 안정성**: TypeScript 타입 자동 생성으로 런타임 에러 방지

### 기술 스택

| 레이어 | 기술 |
|--------|------|
| **Database** | PostgreSQL 14+ |
| **Backend** | Node.js + TypeScript + GraphQL (Apollo Server) |
| **Frontend** | Next.js 15+ + React 19+ + TypeScript |
| **ORM** | Custom (메타데이터 기반) 또는 Prisma |
| **UI Components** | shadcn/ui + Tailwind CSS |

---

## 핵심 개념

### 1. 메타데이터 레이어 구조

```
┌─────────────────────────────────────────┐
│       Metadata Storage (PostgreSQL)      │
│  - mappings_table                       │
│  - mappings_column                      │
│  - mappings_relation                    │
│  - mappings_api_endpoint                │
│  - projects                             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Code Generation Engine          │
│  - Database DDL Generator               │
│  - GraphQL Schema Generator             │
│  - Resolver Generator                   │
│  - React Component Generator            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Generated Code                  │
│  - DB Migrations                        │
│  - GraphQL Schema & Resolvers           │
│  - React Forms & Tables                 │
│  - TypeScript Types                     │
└─────────────────────────────────────────┘
```

### 2. 메타데이터 흐름

```mermaid
graph LR
    A[개발자 모드 UI] --> B[메타데이터 DB]
    B --> C[코드 생성 엔진]
    C --> D[DB Migrations]
    C --> E[GraphQL Schema]
    C --> F[React Components]
    D --> G[PostgreSQL]
    E --> H[GraphQL Server]
    F --> I[Next.js App]
```

---

## 데이터베이스 스키마

### 1. 메타데이터 테이블 구조

#### 1.1 테이블 레벨 메타데이터 (`mappings_table`)

```sql
CREATE TABLE _metadata.mappings_table (
    id BIGSERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL DEFAULT 'public',
    table_name VARCHAR(100) NOT NULL,
    graphql_type VARCHAR(100),
    label VARCHAR(200) NOT NULL,
    description TEXT,
    primary_key VARCHAR(100) DEFAULT 'id',
    is_api_enabled BOOLEAN DEFAULT TRUE,
    api_permissions JSONB,
    table_constraints JSONB,
    indexes JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(schema_name, table_name)
);

COMMENT ON TABLE mappings_table IS '테이블 레벨 메타데이터 - 각 비즈니스 엔티티의 기본 정보';
```

#### 1.2 컬럼 레벨 메타데이터 (`mappings_column`)

```sql
CREATE TABLE _metadata.mappings_column (
    id BIGSERIAL PRIMARY KEY,
    table_id BIGINT REFERENCES mappings_table(id) ON DELETE CASCADE,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,

    -- 데이터베이스 관련
    pg_column VARCHAR(100) NOT NULL,
    pg_type VARCHAR(100),
    pg_constraints JSONB,

    -- GraphQL 관련
    graphql_field VARCHAR(100),
    graphql_type VARCHAR(50),
    graphql_resolver TEXT,
    is_graphql_input BOOLEAN DEFAULT TRUE,
    is_graphql_output BOOLEAN DEFAULT TRUE,

    -- UI 관련
    label VARCHAR(200) NOT NULL,
    form_type VARCHAR(50) DEFAULT 'text',
    is_required BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,

    -- 값 및 검증
    default_value TEXT,
    enum_options JSONB,
    validation_rules JSONB,

    -- UI 도움말
    placeholder VARCHAR(200),
    help_text TEXT,

    -- API 소스 관련 (외부 API 연동)
    api_source_key VARCHAR(200),
    api_source_path VARCHAR(500),
    api_source_type VARCHAR(100),
    data_transformation JSONB,
    is_api_field BOOLEAN DEFAULT FALSE,
    api_default_value TEXT,
    api_endpoints JSONB,

    -- 권한 및 보안
    permission_read VARCHAR(100) DEFAULT 'public',
    permission_write VARCHAR(100) DEFAULT 'authenticated',

    -- 검색 및 필터링
    is_searchable BOOLEAN DEFAULT FALSE,
    is_sortable BOOLEAN DEFAULT TRUE,
    is_filterable BOOLEAN DEFAULT TRUE,
    search_config JSONB,

    -- 인덱스 관련
    is_primary_key BOOLEAN DEFAULT FALSE,
    is_unique BOOLEAN DEFAULT FALSE,
    is_indexed BOOLEAN DEFAULT FALSE,
    index_config JSONB,

    comment TEXT,
    remark TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(schema_name, table_name, pg_column)
);

COMMENT ON TABLE mappings_column IS '컬럼 레벨 메타데이터 - 각 필드의 상세 정보';
```

#### 1.3 관계 메타데이터 (`mappings_relation`)

```sql
CREATE TYPE relation_type_enum AS ENUM (
    'OneToOne', 'OneToMany', 'ManyToOne', 'ManyToMany'
);

CREATE TABLE _metadata.mappings_relation (
    id BIGSERIAL PRIMARY KEY,
    from_table_id BIGINT REFERENCES mappings_table(id),
    to_table_id BIGINT REFERENCES mappings_table(id),
    from_schema VARCHAR(100) NOT NULL,
    from_table VARCHAR(100) NOT NULL,
    from_column VARCHAR(100) NOT NULL,
    to_schema VARCHAR(100) NOT NULL,
    to_table VARCHAR(100) NOT NULL,
    to_column VARCHAR(100) NOT NULL,
    relation_type relation_type_enum NOT NULL,
    graphql_field VARCHAR(100),
    is_cascade_delete BOOLEAN DEFAULT FALSE,
    constraint_name VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE mappings_relation IS '테이블 간 관계 정의';
```

#### 1.4 API 엔드포인트 메타데이터 (`mappings_api_endpoint`)

```sql
CREATE TYPE http_method_enum AS ENUM (
    'GET', 'POST', 'PUT', 'DELETE', 'PATCH'
);

CREATE TABLE _metadata.mappings_api_endpoint (
    id BIGSERIAL PRIMARY KEY,
    endpoint_name VARCHAR(100) NOT NULL UNIQUE,
    base_url VARCHAR(500) NOT NULL,
    method http_method_enum DEFAULT 'GET',
    headers JSONB,
    auth_config JSONB,
    rate_limit_config JSONB,
    timeout_ms INTEGER DEFAULT 30000,
    retry_config JSONB,
    cache_config JSONB,
    request_mapping JSONB,
    response_mapping JSONB,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE mappings_api_endpoint IS '외부 API 엔드포인트 설정';
```

### 2. 프로젝트 관리 테이블 구조

#### 2.1 프로젝트 테이블 (`projects`)

```sql
CREATE TYPE project_status_enum AS ENUM (
    'PLANNING', 'DEVELOPMENT', 'TESTING', 'STAGING', 'PRODUCTION', 'MAINTENANCE', 'ARCHIVED'
);

CREATE TYPE project_template_enum AS ENUM (
    'BASIC', 'ECOMMERCE', 'CMS', 'DASHBOARD', 'API_ONLY', 'MOBILE_BACKEND', 'MICROSERVICE'
);

CREATE TABLE _metadata.projects (
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) NOT NULL UNIQUE,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,

    -- 디렉토리 및 경로 정보
    root_path VARCHAR(500) NOT NULL,
    backend_path VARCHAR(200) DEFAULT './backend',
    frontend_path VARCHAR(200) DEFAULT './frontend',
    database_path VARCHAR(200) DEFAULT './database',

    -- 프로젝트 메타정보
    template project_template_enum DEFAULT 'BASIC',
    status project_status_enum DEFAULT 'PLANNING',
    version VARCHAR(50) DEFAULT '1.0.0',

    -- 기술 스택 정보
    tech_stack JSONB,
    package_manager VARCHAR(20) DEFAULT 'npm',
    node_version VARCHAR(20),

    -- 데이터베이스 연결 정보
    database_config JSONB,
    default_schema VARCHAR(100) DEFAULT 'public',

    -- 코드 생성 설정
    generation_config JSONB,
    auto_generation BOOLEAN DEFAULT TRUE,
    watch_mode BOOLEAN DEFAULT TRUE,

    -- Git 및 버전 관리
    git_repository VARCHAR(500),
    git_branch VARCHAR(100) DEFAULT 'main',

    -- 팀 및 권한
    owner_id BIGINT,
    team_members JSONB,

    -- 배포 정보
    deployment_config JSONB,
    environments JSONB,

    -- API 및 서비스 설정
    api_config JSONB,
    external_services JSONB,

    -- 개발 도구 설정
    dev_tools_config JSONB,
    linting_config JSONB,
    testing_config JSONB,

    -- 플러그인 및 확장
    plugins JSONB,
    custom_generators JSONB,

    -- 문서
    readme_template TEXT,
    documentation_config JSONB,

    -- 메타데이터
    tags JSONB,
    metadata JSONB,

    -- 감사 정보
    created_by BIGINT,
    updated_by BIGINT,
    last_generation_at TIMESTAMPTZ,
    last_sync_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE projects IS '프로젝트 관리 - 여러 프로젝트를 메타데이터 시스템에서 관리';
```

#### 2.2 프로젝트-테이블 매핑 (`project_tables`)

```sql
CREATE TABLE _metadata.project_tables (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES projects(id) ON DELETE CASCADE,
    table_id BIGINT REFERENCES mappings_table(id) ON DELETE CASCADE,

    is_enabled BOOLEAN DEFAULT TRUE,
    custom_config JSONB,
    generation_priority INTEGER DEFAULT 100,
    environments JSONB,
    permissions JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(project_id, table_id)
);

COMMENT ON TABLE project_tables IS '프로젝트별 사용 테이블 매핑';
```

### 3. 인덱스 및 최적화

```sql
-- JSONB 컬럼에 GIN 인덱스
CREATE INDEX idx_mappings_column_enum_options
ON mappings_column USING GIN (enum_options);

CREATE INDEX idx_mappings_column_validation_rules
ON mappings_column USING GIN (validation_rules);

-- 부분 인덱스 (조건부 인덱스)
CREATE INDEX idx_mappings_column_api_fields
ON mappings_column (table_name, pg_column)
WHERE is_api_field = TRUE;

CREATE INDEX idx_mappings_column_searchable
ON mappings_column (table_name)
WHERE is_searchable = TRUE;

-- 복합 인덱스
CREATE INDEX idx_mappings_column_table_order
ON mappings_column (schema_name, table_name, sort_order);

-- 프로젝트 관련 인덱스
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_project_tables_enabled
ON project_tables(project_id)
WHERE is_enabled = TRUE;
```

---

## 개발 워크플로우

### Phase 1: 프로젝트 초기화

```bash
# 1. 메타데이터 DB 스키마 생성
psql -U postgres -d metadb -f schema/00-metadata-tables.sql

# 2. 프로젝트 등록
INSERT INTO projects (
    project_id, project_name, description, root_path, tech_stack
) VALUES (
    'my-ecommerce',
    'My E-commerce App',
    'Modern e-commerce platform',
    '/workspace/my-ecommerce',
    '{
        "backend": "Node.js + TypeScript + GraphQL",
        "frontend": "Next.js + React",
        "database": "PostgreSQL"
    }'::jsonb
);

# 3. 프로젝트 디렉토리 구조 생성
mkdir -p /workspace/my-ecommerce/{backend,frontend,database}
```

### Phase 2: 메타데이터 정의

#### 2.1 개발자 모드 UI 접속

```bash
# 개발자 모드 실행 (메타데이터 편집기)
cd /var/services/homes/jungsam/dev/dockers/_manager
npm run dev

# 브라우저에서 접속
# http://localhost:20100/metadata-editor
```

#### 2.2 테이블 메타데이터 정의

**예시: Users 테이블**

```sql
-- 1. 테이블 정의
INSERT INTO _metadata.mappings_table (
    schema_name, table_name, graphql_type, label, description, primary_key
) VALUES (
    'public', 'users', 'User', '사용자', '시스템 사용자 정보', 'id'
);

-- 2. 컬럼 정의
INSERT INTO _metadata.mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type, is_required, is_visible, sort_order,
    validation_rules, placeholder
) VALUES
-- ID
((SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'),
 'public', 'users',
 'id', 'BIGSERIAL',
 'id', 'ID',
 'ID', 'hidden', false, false, 0,
 NULL, NULL),

-- 이름
((SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'),
 'public', 'users',
 'name', 'VARCHAR(100)',
 'name', 'String',
 '이름', 'text', true, true, 10,
 '{"required": true, "minLength": 2, "maxLength": 100}'::jsonb,
 '이름을 입력하세요'),

-- 이메일
((SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'),
 'public', 'users',
 'email', 'VARCHAR(255)',
 'email', 'String',
 '이메일', 'email', true, true, 20,
 '{
   "required": true,
   "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
 }'::jsonb,
 'user@example.com'),

-- 상태
((SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'),
 'public', 'users',
 'status', 'VARCHAR(20)',
 'status', 'String',
 '상태', 'select', true, true, 30,
 '{"required": true}'::jsonb,
 '상태를 선택하세요');

-- 3. Enum 옵션 설정
UPDATE mappings_column
SET enum_options = '[
    {"value": "ACTIVE", "label": "활성"},
    {"value": "INACTIVE", "label": "비활성"},
    {"value": "PENDING", "label": "대기중"}
]'::jsonb
WHERE table_name = 'users' AND pg_column = 'status';

-- 4. 인덱스 설정
UPDATE mappings_column
SET is_unique = true, is_indexed = true
WHERE table_name = 'users' AND pg_column = 'email';

-- 5. 검색 가능 필드 설정
UPDATE mappings_column
SET is_searchable = true
WHERE table_name = 'users' AND pg_column IN ('name', 'email');
```

#### 2.3 관계 정의

```sql
-- 예시: User와 Order 간 OneToMany 관계
INSERT INTO mappings_relation (
    from_schema, from_table, from_column,
    to_schema, to_table, to_column,
    relation_type, graphql_field, is_cascade_delete
) VALUES (
    'public', 'users', 'id',
    'public', 'orders', 'user_id',
    'OneToMany', 'orders', false
);
```

### Phase 3: 코드 생성

#### 3.1 데이터베이스 DDL 생성

```typescript
// backend/scripts/generate-db-schema.ts
import { MetadataService } from './services/metadata-service';
import { DatabaseGenerator } from './generators/database-generator';

async function generateDatabaseSchema() {
    const metadata = new MetadataService();
    const generator = new DatabaseGenerator();

    // 메타데이터에서 테이블 정보 로드
    const tables = await metadata.getProjectTables('my-ecommerce');

    // DDL 생성
    const ddl = generator.generateDDL(tables);

    // 파일 저장
    await fs.writeFile('./database/migrations/001_initial_schema.sql', ddl);

    console.log('✅ Database schema generated!');
}

generateDatabaseSchema();
```

**생성된 DDL 예시:**

```sql
-- Generated from metadata on 2024-10-19

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT check_users_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'PENDING'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_name ON users(name) WHERE name IS NOT NULL;

COMMENT ON TABLE users IS '사용자';
COMMENT ON COLUMN users.name IS '이름';
COMMENT ON COLUMN users.email IS '이메일';
COMMENT ON COLUMN users.status IS '상태';
```

#### 3.2 GraphQL 스키마 생성

```typescript
// backend/scripts/generate-graphql-schema.ts
import { GraphQLSchemaGenerator } from './generators/graphql-generator';

async function generateGraphQLSchema() {
    const metadata = new MetadataService();
    const generator = new GraphQLSchemaGenerator();

    const tables = await metadata.getProjectTables('my-ecommerce');
    const schema = generator.generateSchema(tables);

    await fs.writeFile('./backend/src/generated/schema.graphql', schema);

    console.log('✅ GraphQL schema generated!');
}
```

**생성된 스키마 예시:**

```graphql
# Generated from metadata on 2024-10-19

type User {
  id: ID!
  name: String!
  email: String!
  status: String!
  createdAt: DateTime!
  updatedAt: DateTime!
  orders: [Order!]
}

input UserInput {
  name: String!
  email: String!
  status: String!
}

input UserFilter {
  name: String
  email: String
  status: String
}

type Query {
  user(id: ID!): User
  users(filter: UserFilter, limit: Int, offset: Int): [User!]!
  usersCount(filter: UserFilter): Int!
}

type Mutation {
  createUser(input: UserInput!): User!
  updateUser(id: ID!, input: UserInput!): User!
  deleteUser(id: ID!): Boolean!
}
```

#### 3.3 GraphQL 리졸버 생성

```typescript
// backend/src/generated/resolvers/user-resolvers.ts
// Auto-generated from metadata

import { QueryResolvers, MutationResolvers } from '../types';
import { UserService } from '../services/user-service';

export const userResolvers: QueryResolvers & MutationResolvers = {
  Query: {
    user: async (parent, { id }, context) => {
      return await context.services.user.findById(id);
    },

    users: async (parent, { filter, limit = 20, offset = 0 }, context) => {
      return await context.services.user.findAll({ filter, limit, offset });
    },

    usersCount: async (parent, { filter }, context) => {
      return await context.services.user.count(filter);
    }
  },

  Mutation: {
    createUser: async (parent, { input }, context) => {
      // 메타데이터 기반 validation
      await context.validate(input, 'User');
      return await context.services.user.create(input);
    },

    updateUser: async (parent, { id, input }, context) => {
      await context.validate(input, 'User');
      return await context.services.user.update(id, input);
    },

    deleteUser: async (parent, { id }, context) => {
      return await context.services.user.delete(id);
    }
  },

  User: {
    orders: async (parent, args, context) => {
      // 관계 리졸버 (메타데이터의 mappings_relation 기반)
      return await context.loaders.ordersByUserId.load(parent.id);
    }
  }
};
```

#### 3.4 React 폼 컴포넌트 생성

```typescript
// frontend/scripts/generate-forms.ts
import { FormGenerator } from './generators/form-generator';

async function generateForms() {
    const metadata = new MetadataService();
    const generator = new FormGenerator();

    const tables = await metadata.getProjectTables('my-ecommerce');

    for (const table of tables) {
        const formCode = generator.generateForm(table);
        await fs.writeFile(
            `./frontend/src/generated/forms/${table.tableName}-form.tsx`,
            formCode
        );
    }

    console.log('✅ React forms generated!');
}
```

**생성된 폼 예시:**

```typescript
// frontend/src/generated/forms/user-form.tsx
// Auto-generated from metadata

import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';

// Validation schema from metadata
const userSchema = z.object({
  name: z.string()
    .min(2, '최소 2자 이상 입력하세요')
    .max(100, '최대 100자까지 입력 가능합니다'),
  email: z.string()
    .email('올바른 이메일 형식이 아닙니다')
    .min(1, '이메일을 입력하세요'),
  status: z.enum(['ACTIVE', 'INACTIVE', 'PENDING'])
});

type UserFormValues = z.infer<typeof userSchema>;

export interface UserFormProps {
  initialData?: Partial<UserFormValues>;
  onSubmit: (data: UserFormValues) => void | Promise<void>;
  loading?: boolean;
}

export const UserForm: React.FC<UserFormProps> = ({
  initialData,
  onSubmit,
  loading = false
}) => {
  const form = useForm<UserFormValues>({
    resolver: zodResolver(userSchema),
    defaultValues: initialData || {
      name: '',
      email: '',
      status: 'PENDING'
    }
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        {/* 이름 필드 */}
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>이름 *</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  placeholder="이름을 입력하세요"
                  disabled={loading}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        {/* 이메일 필드 */}
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>이메일 *</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  type="email"
                  placeholder="user@example.com"
                  disabled={loading}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        {/* 상태 필드 */}
        <FormField
          control={form.control}
          name="status"
          render={({ field }) => (
            <FormItem>
              <FormLabel>상태 *</FormLabel>
              <Select
                onValueChange={field.onChange}
                defaultValue={field.value}
                disabled={loading}
              >
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="상태를 선택하세요" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="ACTIVE">활성</SelectItem>
                  <SelectItem value="INACTIVE">비활성</SelectItem>
                  <SelectItem value="PENDING">대기중</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={loading}>
          {loading ? '저장 중...' : '저장'}
        </Button>
      </form>
    </Form>
  );
};
```

#### 3.5 React 테이블 컴포넌트 생성

```typescript
// frontend/src/generated/tables/user-table.tsx
// Auto-generated from metadata

import React from 'react';
import { ColumnDef } from '@tanstack/react-table';
import { DataTable } from '@/components/ui/data-table';
import { Badge } from '@/components/ui/badge';

export interface User {
  id: string;
  name: string;
  email: string;
  status: 'ACTIVE' | 'INACTIVE' | 'PENDING';
  createdAt: string;
  updatedAt: string;
}

const columns: ColumnDef<User>[] = [
  {
    accessorKey: 'name',
    header: '이름',
    enableSorting: true,
    enableColumnFilter: true,
  },
  {
    accessorKey: 'email',
    header: '이메일',
    enableSorting: true,
    enableColumnFilter: true,
  },
  {
    accessorKey: 'status',
    header: '상태',
    enableSorting: true,
    cell: ({ row }) => {
      const status = row.getValue('status') as string;
      const statusMap = {
        ACTIVE: { label: '활성', variant: 'success' as const },
        INACTIVE: { label: '비활성', variant: 'destructive' as const },
        PENDING: { label: '대기중', variant: 'secondary' as const },
      };
      const { label, variant } = statusMap[status as keyof typeof statusMap];
      return <Badge variant={variant}>{label}</Badge>;
    },
  },
  {
    accessorKey: 'createdAt',
    header: '생성일',
    enableSorting: true,
    cell: ({ row }) => new Date(row.getValue('createdAt')).toLocaleString('ko-KR'),
  },
];

export interface UserTableProps {
  data: User[];
  loading?: boolean;
  onRowClick?: (row: User) => void;
}

export const UserTable: React.FC<UserTableProps> = ({
  data,
  loading = false,
  onRowClick
}) => {
  return (
    <DataTable
      columns={columns}
      data={data}
      loading={loading}
      onRowClick={onRowClick}
      searchableColumns={['name', 'email']}
      filterableColumns={[
        {
          id: 'status',
          title: '상태',
          options: [
            { label: '활성', value: 'ACTIVE' },
            { label: '비활성', value: 'INACTIVE' },
            { label: '대기중', value: 'PENDING' },
          ]
        }
      ]}
    />
  );
};
```

### Phase 4: 동기화 모드

#### 4.1 자동 동기화 (Watch Mode)

```typescript
// backend/scripts/watch-metadata.ts
import chokidar from 'chokidar';
import { generateAll } from './generate-all';

async function watchMode() {
    console.log('🔍 Watching metadata changes...');

    // PostgreSQL LISTEN/NOTIFY를 사용한 실시간 감지
    const client = await pool.connect();

    await client.query(`
        CREATE OR REPLACE FUNCTION notify_metadata_change()
        RETURNS TRIGGER AS $$
        BEGIN
            PERFORM pg_notify('metadata_changed', json_build_object(
                'table', TG_TABLE_NAME,
                'operation', TG_OP,
                'data', row_to_json(NEW)
            )::text);
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    `);

    await client.query(`
        CREATE TRIGGER trg_mappings_table_notify
        AFTER INSERT OR UPDATE OR DELETE ON mappings_table
        FOR EACH ROW EXECUTE FUNCTION notify_metadata_change();

        CREATE TRIGGER trg_mappings_column_notify
        AFTER INSERT OR UPDATE OR DELETE ON mappings_column
        FOR EACH ROW EXECUTE FUNCTION notify_metadata_change();
    `);

    client.on('notification', async (msg) => {
        if (msg.channel === 'metadata_changed') {
            console.log('🔄 Metadata changed, regenerating...');
            await generateAll();
            console.log('✅ Code regenerated successfully!');
        }
    });

    await client.query('LISTEN metadata_changed');
}

watchMode();
```

#### 4.2 수동 동기화 (CLI)

```bash
# package.json scripts
{
  "scripts": {
    "meta:sync": "ts-node scripts/generate-all.ts",
    "meta:sync:table": "ts-node scripts/generate-all.ts --table",
    "meta:sync:dry-run": "ts-node scripts/generate-all.ts --dry-run",
    "meta:watch": "ts-node scripts/watch-metadata.ts"
  }
}

# 사용 예시
npm run meta:sync                    # 전체 동기화
npm run meta:sync:table -- users     # users 테이블만 동기화
npm run meta:sync:dry-run            # 미리보기 (실제 생성 안함)
npm run meta:watch                   # Watch 모드 실행
```

### Phase 5: 개발 및 커스터마이징

#### 5.1 생성된 코드 활용

```typescript
// frontend/src/pages/users/index.tsx
import { UserTable } from '@/generated/tables/user-table';
import { useUsers } from '@/hooks/use-users';

export default function UsersPage() {
  const { data, loading } = useUsers();

  return (
    <div className="container mx-auto py-10">
      <h1 className="text-3xl font-bold mb-6">사용자 관리</h1>
      <UserTable
        data={data}
        loading={loading}
        onRowClick={(user) => router.push(`/users/${user.id}`)}
      />
    </div>
  );
}
```

#### 5.2 커스텀 로직 추가

```typescript
// backend/src/custom/user-service.ts
// 생성된 코드 확장
import { UserService as GeneratedUserService } from '../generated/services/user-service';

export class UserService extends GeneratedUserService {
  // 커스텀 메서드 추가
  async findByEmailDomain(domain: string) {
    return this.db.query(
      `SELECT * FROM users WHERE email LIKE $1`,
      [`%@${domain}`]
    );
  }

  // 생성된 메서드 오버라이드
  async create(input: UserInput) {
    // 커스텀 로직 추가
    const hashedPassword = await bcrypt.hash(input.password, 10);

    // 부모 메서드 호출
    return super.create({
      ...input,
      password: hashedPassword
    });
  }
}
```

---

## 코드 생성 시스템

### 1. 생성기 아키텍처

```typescript
// generators/base-generator.ts
export abstract class BaseGenerator {
  protected metadata: MetadataService;

  constructor(metadata: MetadataService) {
    this.metadata = metadata;
  }

  abstract generate(tables: TableMetadata[]): Promise<string>;

  protected formatCode(code: string, language: string): string {
    // Prettier를 사용한 코드 포맷팅
    return prettier.format(code, {
      parser: language === 'typescript' ? 'typescript' : 'graphql',
      semi: true,
      singleQuote: true,
      trailingComma: 'es5'
    });
  }
}
```

### 2. 데이터베이스 생성기

```typescript
// generators/database-generator.ts
export class DatabaseGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    let ddl = '-- Generated DDL from metadata\n\n';

    for (const table of tables) {
      ddl += this.generateTableDDL(table);
      ddl += '\n\n';
      ddl += this.generateIndexes(table);
      ddl += '\n\n';
      ddl += this.generateConstraints(table);
      ddl += '\n\n';
    }

    return ddl;
  }

  private generateTableDDL(table: TableMetadata): string {
    const columns = table.columns
      .map(col => this.generateColumnDDL(col))
      .join(',\n    ');

    return `
CREATE TABLE ${table.schemaName}.${table.tableName} (
    ${columns}
);

COMMENT ON TABLE ${table.schemaName}.${table.tableName} IS '${table.label}';
${this.generateColumnComments(table)}
    `.trim();
  }

  private generateColumnDDL(column: ColumnMetadata): string {
    let ddl = `${column.pgColumn} ${column.pgType}`;

    if (column.isPrimaryKey) ddl += ' PRIMARY KEY';
    if (column.isRequired && !column.isPrimaryKey) ddl += ' NOT NULL';
    if (column.defaultValue) ddl += ` DEFAULT ${this.formatDefaultValue(column)}`;
    if (column.isUnique) ddl += ' UNIQUE';

    return ddl;
  }

  private generateIndexes(table: TableMetadata): string {
    const indexes = table.columns
      .filter(col => col.isIndexed && !col.isPrimaryKey)
      .map(col => {
        const indexName = `idx_${table.tableName}_${col.pgColumn}`;
        const indexType = col.indexConfig?.type || 'BTREE';

        return `CREATE INDEX ${indexName} ON ${table.tableName} USING ${indexType} (${col.pgColumn});`;
      })
      .join('\n');

    return indexes;
  }
}
```

### 3. GraphQL 생성기

```typescript
// generators/graphql-generator.ts
export class GraphQLSchemaGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    const types = tables.map(t => this.generateType(t)).join('\n\n');
    const queries = this.generateQueries(tables);
    const mutations = this.generateMutations(tables);

    return this.formatCode(`
${types}

type Query {
${queries}
}

type Mutation {
${mutations}
}
    `, 'graphql');
  }

  private generateType(table: TableMetadata): string {
    const fields = table.columns
      .filter(col => col.isGraphqlOutput)
      .map(col => {
        const nullable = col.isRequired ? '!' : '';
        return `  ${col.graphqlField}: ${col.graphqlType}${nullable}`;
      })
      .join('\n');

    // 관계 필드 추가
    const relations = this.metadata.getRelations(table.id)
      .map(rel => {
        const isArray = rel.relationType.includes('Many');
        const targetType = this.metadata.getTable(rel.toTableId).graphqlType;
        return `  ${rel.graphqlField}: ${isArray ? `[${targetType}!]` : targetType}`;
      })
      .join('\n');

    return `
type ${table.graphqlType} {
${fields}
${relations}
}

input ${table.graphqlType}Input {
${this.generateInputFields(table)}
}

input ${table.graphqlType}Filter {
${this.generateFilterFields(table)}
}
    `.trim();
  }
}
```

### 4. React 컴포넌트 생성기

```typescript
// generators/react-generator.ts
export class ReactFormGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<void> {
    for (const table of tables) {
      const formCode = this.generateFormComponent(table);
      const tableCode = this.generateTableComponent(table);

      await this.writeFile(
        `frontend/src/generated/forms/${table.tableName}-form.tsx`,
        formCode
      );

      await this.writeFile(
        `frontend/src/generated/tables/${table.tableName}-table.tsx`,
        tableCode
      );
    }
  }

  private generateFormComponent(table: TableMetadata): string {
    const imports = this.generateImports(table);
    const schema = this.generateZodSchema(table);
    const fields = this.generateFormFields(table);

    return this.formatCode(`
${imports}

${schema}

type ${table.graphqlType}FormValues = z.infer<typeof ${this.camelCase(table.tableName)}Schema>;

export interface ${table.graphqlType}FormProps {
  initialData?: Partial<${table.graphqlType}FormValues>;
  onSubmit: (data: ${table.graphqlType}FormValues) => void | Promise<void>;
  loading?: boolean;
}

export const ${table.graphqlType}Form: React.FC<${table.graphqlType}FormProps> = ({
  initialData,
  onSubmit,
  loading = false
}) => {
  const form = useForm<${table.graphqlType}FormValues>({
    resolver: zodResolver(${this.camelCase(table.tableName)}Schema),
    defaultValues: initialData
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        ${fields}
        <Button type="submit" disabled={loading}>
          {loading ? '저장 중...' : '저장'}
        </Button>
      </form>
    </Form>
  );
};
    `, 'typescript');
  }

  private generateFormFields(table: TableMetadata): string {
    return table.columns
      .filter(col => col.isVisible && col.formType !== 'hidden')
      .map(col => this.generateFormField(col))
      .join('\n\n');
  }

  private generateFormField(column: ColumnMetadata): string {
    const componentMap = {
      text: this.generateTextField,
      email: this.generateTextField,
      password: this.generateTextField,
      number: this.generateNumberField,
      select: this.generateSelectField,
      checkbox: this.generateCheckboxField,
      textarea: this.generateTextareaField,
      date: this.generateDateField,
    };

    const generator = componentMap[column.formType as keyof typeof componentMap];
    return generator ? generator.call(this, column) : '';
  }
}
```

---

## 프로젝트 관리

### 1. 프로젝트 생성

```typescript
// _manager/api/src/services/project-service.ts
export class ProjectService {
  async createProject(input: CreateProjectInput): Promise<Project> {
    // 1. 프로젝트 레코드 생성
    const project = await this.db.query(`
      INSERT INTO projects (
        project_id, project_name, description, root_path, tech_stack
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [
      input.projectId,
      input.projectName,
      input.description,
      input.rootPath,
      input.techStack
    ]);

    // 2. 디렉토리 구조 생성
    await this.createProjectStructure(project);

    // 3. 초기 환경 설정
    await this.createDefaultEnvironments(project.id);

    // 4. 템플릿 기반 초기 테이블 생성
    if (input.template) {
      await this.applyTemplate(project.id, input.template);
    }

    return project;
  }

  private async createProjectStructure(project: Project): Promise<void> {
    const paths = [
      `${project.rootPath}/backend/src/generated`,
      `${project.rootPath}/backend/src/custom`,
      `${project.rootPath}/frontend/src/generated`,
      `${project.rootPath}/frontend/src/components`,
      `${project.rootPath}/database/migrations`,
      `${project.rootPath}/database/seeds`,
    ];

    for (const path of paths) {
      await fs.mkdir(path, { recursive: true });
    }
  }
}
```

### 2. 테이블 할당

```typescript
// 프로젝트에 테이블 추가
async function assignTableToProject(projectId: string, tableName: string) {
  const project = await getProject(projectId);
  const table = await getTable(tableName);

  await db.query(`
    INSERT INTO project_tables (project_id, table_id, is_enabled)
    VALUES ($1, $2, true)
    ON CONFLICT (project_id, table_id)
    DO UPDATE SET is_enabled = true
  `, [project.id, table.id]);

  // 코드 재생성
  await generateProjectCode(projectId);
}
```

### 3. 환경별 설정

```typescript
// 환경 설정 관리
async function configureEnvironment(
  projectId: string,
  envName: string,
  config: EnvironmentConfig
) {
  await db.query(`
    INSERT INTO project_environments (
      project_id, env_name, env_type,
      database_url, backend_url, frontend_url,
      env_variables
    ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    ON CONFLICT (project_id, env_name)
    DO UPDATE SET
      database_url = EXCLUDED.database_url,
      backend_url = EXCLUDED.backend_url,
      frontend_url = EXCLUDED.frontend_url,
      env_variables = EXCLUDED.env_variables
  `, [
    projectId,
    envName,
    config.envType,
    config.databaseUrl,
    config.backendUrl,
    config.frontendUrl,
    JSON.stringify(config.envVariables)
  ]);
}
```

---

## Best Practices

### 1. 메타데이터 설계 원칙

#### ✅ DO

- **일관된 명명 규칙 사용**: `snake_case` (DB), `camelCase` (GraphQL/JS)
- **상세한 라벨 및 설명 작성**: UI 생성 시 활용
- **validation 규칙 명확히 정의**: 프론트엔드/백엔드 모두 사용
- **검색/필터링 가능 필드 명시**: 성능 최적화
- **관계 정의 시 cascade 옵션 신중히 설정**

#### ❌ DON'T

- 메타데이터와 실제 DB 스키마 불일치 방치
- 생성된 코드 직접 수정 (커스텀 로직은 별도 파일에)
- 과도한 컬럼 수 (테이블 분리 고려)
- 순환 참조 관계 생성

### 2. 코드 생성 전략

#### 생성 vs 커스터마이징 구분

```
generated/           # 절대 수정하지 말것 (덮어씌워짐)
├── types.ts
├── schema.graphql
├── resolvers/
└── forms/

custom/              # 커스텀 로직 작성
├── services/
├── hooks/
└── utils/
```

#### 생성 코드 확장 패턴

```typescript
// ✅ 좋은 예: 상속을 통한 확장
import { UserService as GeneratedUserService } from '@/generated/services';

export class UserService extends GeneratedUserService {
  async customMethod() {
    // 커스텀 로직
  }
}

// ❌ 나쁜 예: 생성 파일 직접 수정
// generated/services/user-service.ts 파일을 직접 수정
```

### 3. 버전 관리

#### Git Ignore 설정

```gitignore
# Generated code (선택적으로 ignore)
backend/src/generated/
frontend/src/generated/

# 메타데이터는 반드시 커밋
!database/metadata/
```

#### 변경 이력 관리

```sql
-- 메타데이터 변경 시 자동으로 이력 기록
CREATE TRIGGER trg_track_metadata_changes
AFTER INSERT OR UPDATE OR DELETE ON mappings_column
FOR EACH ROW
EXECUTE FUNCTION log_metadata_change();
```

### 4. 성능 최적화

#### 선택적 코드 생성

```typescript
// 변경된 테이블만 재생성
async function incrementalGenerate(changedTables: string[]) {
  for (const tableName of changedTables) {
    await generateTableCode(tableName);
  }
}
```

#### 캐싱 전략

```typescript
// 메타데이터 캐싱
const metadataCache = new NodeCache({ stdTTL: 300 });

async function getTableMetadata(tableName: string) {
  const cached = metadataCache.get(tableName);
  if (cached) return cached;

  const metadata = await db.getTableMetadata(tableName);
  metadataCache.set(tableName, metadata);
  return metadata;
}
```

### 5. 보안 고려사항

#### 권한 기반 코드 생성

```typescript
// 사용자 권한에 따른 필드 필터링
function filterFieldsByPermission(
  columns: ColumnMetadata[],
  userRole: string
): ColumnMetadata[] {
  return columns.filter(col => {
    const readPermission = col.permissionRead;
    return hasPermission(userRole, readPermission);
  });
}
```

#### 민감 정보 보호

```sql
-- 민감 정보 마스킹 설정
UPDATE mappings_column
SET
  is_graphql_output = false,  -- GraphQL 응답에서 제외
  permission_read = 'admin'   -- 관리자만 조회 가능
WHERE pg_column IN ('password', 'ssn', 'credit_card');
```

### 6. 테스트 전략

#### 메타데이터 검증 테스트

```typescript
// tests/metadata-validation.test.ts
describe('Metadata Validation', () => {
  test('모든 테이블은 primary key를 가져야 함', async () => {
    const tables = await metadata.getAllTables();

    for (const table of tables) {
      const hasPrimaryKey = table.columns.some(col => col.isPrimaryKey);
      expect(hasPrimaryKey).toBe(true);
    }
  });

  test('GraphQL 필드명은 camelCase여야 함', async () => {
    const columns = await metadata.getAllColumns();

    for (const col of columns) {
      expect(col.graphqlField).toMatch(/^[a-z][a-zA-Z0-9]*$/);
    }
  });
});
```

#### 생성 코드 테스트

```typescript
// tests/generated-code.test.ts
describe('Generated Code', () => {
  test('생성된 GraphQL 스키마가 유효함', async () => {
    const schema = await fs.readFile('./backend/src/generated/schema.graphql', 'utf-8');
    const parsed = parse(schema);
    expect(parsed).toBeDefined();
  });

  test('생성된 폼 컴포넌트가 TypeScript 에러 없음', async () => {
    const result = await exec('tsc --noEmit frontend/src/generated/forms/*.tsx');
    expect(result.exitCode).toBe(0);
  });
});
```

### 7. 마이그레이션 전략

#### 메타데이터 변경 → DB 마이그레이션

```typescript
// scripts/generate-migration.ts
async function generateMigration(tableName: string) {
  // 1. 현재 DB 스키마 조회
  const currentSchema = await introspectDatabase(tableName);

  // 2. 메타데이터에서 원하는 스키마 조회
  const desiredSchema = await getMetadataSchema(tableName);

  // 3. Diff 계산
  const diff = calculateSchemaDiff(currentSchema, desiredSchema);

  // 4. 마이그레이션 SQL 생성
  const migration = generateMigrationSQL(diff);

  // 5. 파일 저장
  const timestamp = Date.now();
  await fs.writeFile(
    `./database/migrations/${timestamp}_update_${tableName}.sql`,
    migration
  );
}
```

---

## 부록

### A. CLI 명령어 참조

```bash
# 프로젝트 관리
npm run project:create <name>          # 새 프로젝트 생성
npm run project:list                   # 프로젝트 목록
npm run project:info <id>              # 프로젝트 상세 정보

# 메타데이터 관리
npm run meta:sync                      # 전체 동기화
npm run meta:sync:table -- <name>      # 특정 테이블만
npm run meta:validate                  # 메타데이터 검증
npm run meta:export                    # 메타데이터 내보내기
npm run meta:import -- <file>          # 메타데이터 가져오기

# 코드 생성
npm run generate:all                   # 전체 코드 생성
npm run generate:db                    # DB DDL만
npm run generate:graphql               # GraphQL만
npm run generate:react                 # React 컴포넌트만

# 개발 모드
npm run dev:meta                       # 메타데이터 편집기
npm run dev:watch                      # Watch 모드

# 마이그레이션
npm run migration:generate -- <table>  # 마이그레이션 생성
npm run migration:run                  # 마이그레이션 실행
npm run migration:rollback             # 마이그레이션 롤백
```

### B. 환경 변수 설정

```env
# .env.example

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/metadb
DATABASE_SCHEMA=public

# Code Generation
AUTO_GENERATION=true
WATCH_MODE=true
GENERATION_OUTPUT_DIR=./src/generated

# Dev Tools
DEV_TOOLS_ENABLED=true
DEV_TOOLS_PORT=20101

# GraphQL
GRAPHQL_PORT=4000
GRAPHQL_PATH=/graphql

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:4000/graphql
```

### C. 유용한 SQL 쿼리

```sql
-- 프로젝트별 테이블 목록
SELECT
  p.project_name,
  mt.table_name,
  mt.label,
  COUNT(mc.id) as column_count
FROM projects p
JOIN project_tables pt ON p.id = pt.project_id
JOIN mappings_table mt ON pt.table_id = mt.id
LEFT JOIN mappings_column mc ON mt.id = mc.table_id
WHERE pt.is_enabled = true
GROUP BY p.project_name, mt.table_name, mt.label
ORDER BY p.project_name, mt.table_name;

-- 검색 가능한 컬럼 목록
SELECT
  table_name,
  pg_column,
  label,
  pg_type
FROM _metadata.mappings_column
WHERE is_searchable = true
ORDER BY table_name, sort_order;

-- GraphQL API에 노출된 필드
SELECT
  mt.graphql_type,
  mc.graphql_field,
  mc.graphql_type as field_type,
  mc.is_required
FROM _metadata.mappings_column mc
JOIN mappings_table mt ON mc.table_id = mt.id
WHERE mc.is_graphql_output = true
  AND mt.is_api_enabled = true
ORDER BY mt.graphql_type, mc.sort_order;

-- 외부 API 연동 필드
SELECT
  table_name,
  pg_column,
  label,
  api_source_key,
  api_source_path
FROM _metadata.mappings_column
WHERE is_api_field = true;
```

---

## 결론

이 메타데이터 기반 개발 워크플로우를 통해:

1. **개발 속도 향상**: 반복 작업 자동화로 개발 시간 단축
2. **일관성 보장**: 모든 레이어가 메타데이터 기반으로 동기화
3. **유지보수 용이**: 스키마 변경이 전체 스택에 자동 반영
4. **타입 안정성**: TypeScript 기반 end-to-end 타입 안정성
5. **확장성**: 프로젝트별 독립적인 메타데이터 관리

메타데이터는 **단일 진실 공급원(Single Source of Truth)**으로 작동하며, 이를 기반으로 전체 애플리케이션 스택을 일관되게 유지할 수 있습니다.

---

**작성일**: 2024-10-19
**버전**: 1.0.0
**문서 관리**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/meta-data-driven`
