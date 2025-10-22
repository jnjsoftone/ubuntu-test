# 메타데이터 기반 개발 가이드라인

> PostgreSQL + GraphQL (TypeScript) + Next.js 스택을 위한 실전 개발 가이드

## 목차

1. [개발 환경 설정](#개발-환경-설정)
2. [메타데이터 정의 가이드](#메타데이터-정의-가이드)
3. [코드 생성 및 커스터마이징](#코드-생성-및-커스터마이징)
4. [TypeScript 타입 시스템](#typescript-타입-시스템)
5. [GraphQL 스키마 설계](#graphql-스키마-설계)
6. [React 컴포넌트 패턴](#react-컴포넌트-패턴)
7. [테스트 전략](#테스트-전략)
8. [배포 및 CI/CD](#배포-및-cicd)
9. [트러블슈팅](#트러블슈팅)

---

## 개발 환경 설정

### 1. 필수 도구 설치

```bash
# Node.js 20 LTS 설치 확인
node --version  # v20.x.x

# PostgreSQL 14+ 설치 확인
psql --version  # PostgreSQL 14.x

# pnpm 설치 (권장)
npm install -g pnpm

# TypeScript 글로벌 설치
npm install -g typescript ts-node
```

### 2. 프로젝트 초기 설정

#### 2.1 메타데이터 DB 초기화

```bash
# 메타데이터 전용 데이터베이스 생성
psql -U postgres -c "CREATE DATABASE metadb;"

# 스키마 생성
psql -U postgres -d metadb -f /var/services/homes/jungsam/dev/dockers/_manager/database/schema/metadata-schema.sql
```

#### 2.2 프로젝트 구조 생성

```bash
# 프로젝트 루트 디렉토리 생성
mkdir -p /workspace/my-project/{backend,frontend,database}

# Backend 구조
cd /workspace/my-project/backend
npm init -y
mkdir -p src/{generated,custom,services,resolvers,utils}

# Frontend 구조
cd /workspace/my-project/frontend
npx create-next-app@latest . --typescript --tailwind --app
mkdir -p src/{generated,components,hooks,lib}

# Database 구조
cd /workspace/my-project/database
mkdir -p {migrations,seeds,scripts}
```

### 3. 패키지 설치

#### Backend Dependencies

```bash
cd /workspace/my-project/backend

# Core dependencies
pnpm add graphql @apollo/server graphql-tag
pnpm add pg pg-hstore
pnpm add typescript ts-node @types/node
pnpm add dotenv zod

# Dev dependencies
pnpm add -D @types/pg nodemon tsx
pnpm add -D prettier eslint @typescript-eslint/parser
```

#### Frontend Dependencies

```bash
cd /workspace/my-project/frontend

# UI & Forms
pnpm add @tanstack/react-table
pnpm add react-hook-form @hookform/resolvers zod
pnpm add date-fns clsx tailwind-merge

# GraphQL Client
pnpm add @apollo/client graphql

# shadcn/ui components
npx shadcn@latest init
npx shadcn@latest add form input button select table
```

### 4. 환경 변수 설정

#### Backend `.env`

```env
# Database
METADATA_DATABASE_URL=postgresql://postgres:password@localhost:5432/metadb
APP_DATABASE_URL=postgresql://postgres:password@localhost:5432/myapp

# Server
PORT=4000
NODE_ENV=development

# GraphQL
GRAPHQL_PATH=/graphql
GRAPHQL_PLAYGROUND=true

# Code Generation
AUTO_GENERATION=true
WATCH_MODE=true
```

#### Frontend `.env.local`

```env
# API
NEXT_PUBLIC_GRAPHQL_URL=http://localhost:4000/graphql

# App
NEXT_PUBLIC_APP_NAME=My Application
NEXT_PUBLIC_APP_VERSION=1.0.0
```

---

## 메타데이터 정의 가이드

### 1. 명명 규칙

#### 데이터베이스 (PostgreSQL)

```sql
-- ✅ 올바른 예시
table_name: users, user_profiles, order_items
column_name: user_id, created_at, is_active, first_name

-- ❌ 잘못된 예시
table_name: Users, userProfiles, OrderItems
column_name: userId, createdAt, isActive, firstName
```

#### GraphQL

```graphql
# ✅ 올바른 예시
type User {
  id: ID!
  firstName: String!
  createdAt: DateTime!
}

input UserInput {
  firstName: String!
  email: String!
}

# ❌ 잘못된 예시
type user {
  ID: ID!
  first_name: String!
  created_at: DateTime!
}
```

#### TypeScript/React

```typescript
// ✅ 올바른 예시
interface User {
  id: string;
  firstName: string;
  createdAt: Date;
}

const UserForm: React.FC<UserFormProps> = () => {};

// ❌ 잘못된 예시
interface user {
  ID: string;
  first_name: string;
}

const userForm = () => {};
```

### 2. 테이블 메타데이터 정의 템플릿

```sql
-- 테이블 기본 정의
INSERT INTO mappings_table (
    schema_name,
    table_name,
    graphql_type,
    label,
    description,
    primary_key,
    is_api_enabled,
    api_permissions
) VALUES (
    'public',                          -- 스키마 이름
    'products',                        -- 테이블 이름 (snake_case)
    'Product',                         -- GraphQL 타입 (PascalCase)
    '상품',                            -- 한글 라벨
    '판매 상품 정보를 관리하는 테이블',  -- 상세 설명
    'id',                              -- 기본키 컬럼명
    true,                              -- API 노출 여부
    '{
        "read": ["public"],
        "create": ["authenticated"],
        "update": ["authenticated", "admin"],
        "delete": ["admin"]
    }'::jsonb                          -- 권한 설정
);
```

### 3. 컬럼 메타데이터 정의 패턴

#### 기본 텍스트 필드

```sql
INSERT INTO mappings_column (
    table_id,
    schema_name,
    table_name,
    pg_column,
    pg_type,
    graphql_field,
    graphql_type,
    label,
    form_type,
    is_required,
    is_visible,
    sort_order,
    validation_rules,
    placeholder,
    help_text
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'products'),
    'public',
    'products',
    'name',                            -- DB 컬럼명
    'VARCHAR(200)',                    -- DB 타입
    'name',                            -- GraphQL 필드명
    'String',                          -- GraphQL 타입
    '상품명',                          -- UI 라벨
    'text',                            -- 폼 타입
    true,                              -- 필수 여부
    true,                              -- 표시 여부
    10,                                -- 정렬 순서
    '{
        "required": true,
        "minLength": 2,
        "maxLength": 200,
        "pattern": "^[가-힣a-zA-Z0-9\\s]+$"
    }'::jsonb,                         -- 검증 규칙
    '상품명을 입력하세요',               -- Placeholder
    '2~200자 이내로 입력해주세요'        -- 도움말
);
```

#### 이메일 필드

```sql
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type,
    is_required, is_visible, is_unique, is_indexed,
    sort_order, validation_rules, placeholder
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'users'),
    'public', 'users',
    'email', 'VARCHAR(255)',
    'email', 'String',
    '이메일', 'email',
    true, true, true, true,
    20,
    '{
        "required": true,
        "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
        "transform": ["trim", "toLowerCase"]
    }'::jsonb,
    'user@example.com'
);
```

#### Enum/Select 필드

```sql
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type,
    is_required, is_visible, sort_order,
    default_value, enum_options, validation_rules
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'products'),
    'public', 'products',
    'status', 'VARCHAR(20)',
    'status', 'ProductStatus',
    '상태', 'select',
    true, true, 30,
    'DRAFT',                           -- 기본값
    '[
        {"value": "DRAFT", "label": "임시저장"},
        {"value": "PUBLISHED", "label": "판매중"},
        {"value": "SOLD_OUT", "label": "품절"},
        {"value": "DISCONTINUED", "label": "단종"}
    ]'::jsonb,                         -- 옵션 목록
    '{"required": true}'::jsonb
);
```

#### 숫자 필드

```sql
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type,
    is_required, is_visible, sort_order,
    default_value, validation_rules, placeholder
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'products'),
    'public', 'products',
    'price', 'DECIMAL(10,2)',
    'price', 'Float',
    '가격', 'number',
    true, true, 40,
    '0',
    '{
        "required": true,
        "min": 0,
        "max": 99999999.99,
        "step": 0.01
    }'::jsonb,
    '가격을 입력하세요'
);
```

#### Boolean (체크박스) 필드

```sql
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type,
    is_required, is_visible, sort_order,
    default_value
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'products'),
    'public', 'products',
    'is_featured', 'BOOLEAN',
    'isFeatured', 'Boolean',
    '추천 상품', 'checkbox',
    false, true, 50,
    'false'
);
```

#### 날짜/시간 필드

```sql
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type,
    is_required, is_visible, sort_order,
    validation_rules
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'products'),
    'public', 'products',
    'available_from', 'TIMESTAMPTZ',
    'availableFrom', 'DateTime',
    '판매 시작일', 'datetime',
    false, true, 60,
    '{
        "min": "now",
        "format": "YYYY-MM-DD HH:mm:ss"
    }'::jsonb
);
```

#### 텍스트 영역 (Textarea)

```sql
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type,
    is_required, is_visible, sort_order,
    validation_rules, placeholder
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'products'),
    'public', 'products',
    'description', 'TEXT',
    'description', 'String',
    '상품 설명', 'textarea',
    false, true, 70,
    '{
        "maxLength": 2000
    }'::jsonb,
    '상품에 대한 자세한 설명을 입력하세요'
);
```

### 4. 관계 정의 패턴

#### One-to-Many 관계

```sql
-- User 1 : N Orders
INSERT INTO mappings_relation (
    from_schema, from_table, from_column,
    to_schema, to_table, to_column,
    relation_type, graphql_field,
    is_cascade_delete, constraint_name
) VALUES (
    'public', 'users', 'id',
    'public', 'orders', 'user_id',
    'OneToMany',
    'orders',                          -- User.orders
    false,                             -- User 삭제 시 Order는 유지
    'fk_orders_user_id'
);
```

#### Many-to-One 관계

```sql
-- Order N : 1 User
INSERT INTO mappings_relation (
    from_schema, from_table, from_column,
    to_schema, to_table, to_column,
    relation_type, graphql_field,
    is_cascade_delete, constraint_name
) VALUES (
    'public', 'orders', 'user_id',
    'public', 'users', 'id',
    'ManyToOne',
    'user',                            -- Order.user
    false,
    'fk_orders_user_id'
);
```

#### Many-to-Many 관계

```sql
-- Products <-> Categories (through product_categories)

-- 1. 중간 테이블 정의
INSERT INTO mappings_table (
    schema_name, table_name, graphql_type,
    label, description
) VALUES (
    'public', 'product_categories', 'ProductCategory',
    '상품-카테고리 매핑', '상품과 카테고리의 다대다 관계 중간 테이블'
);

-- 2. 관계 정의 (Products -> Categories)
INSERT INTO mappings_relation (
    from_schema, from_table, from_column,
    to_schema, to_table, to_column,
    relation_type, graphql_field,
    is_cascade_delete
) VALUES (
    'public', 'products', 'id',
    'public', 'categories', 'id',
    'ManyToMany',
    'categories',                      -- Product.categories
    false
);

-- 3. 관계 정의 (Categories -> Products)
INSERT INTO mappings_relation (
    from_schema, from_table, from_column,
    to_schema, to_table, to_column,
    relation_type, graphql_field,
    is_cascade_delete
) VALUES (
    'public', 'categories', 'id',
    'public', 'products', 'id',
    'ManyToMany',
    'products',                        -- Category.products
    false
);
```

### 5. 외부 API 연동 필드

```sql
-- 외부 API에서 데이터를 가져오는 필드
UPDATE mappings_column
SET
    is_api_field = true,
    api_source_key = 'user_info.full_name',
    api_source_path = 'data.user.profile.name',
    api_source_type = 'string',
    data_transformation = '{
        "type": "string_transform",
        "operations": [
            {"action": "trim"},
            {"action": "toUpperCase"}
        ]
    }'::jsonb,
    api_endpoints = '["getUserProfile", "getUserList"]'::jsonb
WHERE table_name = 'users' AND pg_column = 'name';
```

---

## 코드 생성 및 커스터마이징

### 1. 코드 생성 스크립트

#### 전체 생성 스크립트 (`scripts/generate-all.ts`)

```typescript
import { MetadataService } from '../services/metadata-service';
import { DatabaseGenerator } from '../generators/database-generator';
import { GraphQLGenerator } from '../generators/graphql-generator';
import { TypeScriptGenerator } from '../generators/typescript-generator';
import { ReactGenerator } from '../generators/react-generator';

async function generateAll() {
  console.log('🚀 Starting code generation...\n');

  const metadata = new MetadataService();
  const projectId = process.env.PROJECT_ID || 'default';

  // 1. 프로젝트 테이블 로드
  const tables = await metadata.getProjectTables(projectId);
  console.log(`📋 Found ${tables.length} tables\n`);

  // 2. Database DDL 생성
  console.log('📦 Generating database schema...');
  const dbGenerator = new DatabaseGenerator();
  const ddl = await dbGenerator.generate(tables);
  await writeFile('./database/migrations/schema.sql', ddl);
  console.log('✅ Database schema generated\n');

  // 3. GraphQL Schema 생성
  console.log('📦 Generating GraphQL schema...');
  const gqlGenerator = new GraphQLGenerator();
  const schema = await gqlGenerator.generateSchema(tables);
  await writeFile('./backend/src/generated/schema.graphql', schema);
  console.log('✅ GraphQL schema generated\n');

  // 4. GraphQL Resolvers 생성
  console.log('📦 Generating resolvers...');
  const resolvers = await gqlGenerator.generateResolvers(tables);
  await writeFile('./backend/src/generated/resolvers/index.ts', resolvers);
  console.log('✅ Resolvers generated\n');

  // 5. TypeScript Types 생성
  console.log('📦 Generating TypeScript types...');
  const tsGenerator = new TypeScriptGenerator();
  const types = await tsGenerator.generate(tables);
  await writeFile('./backend/src/generated/types.ts', types);
  console.log('✅ TypeScript types generated\n');

  // 6. React Components 생성
  console.log('📦 Generating React components...');
  const reactGenerator = new ReactGenerator();
  await reactGenerator.generateForms(tables);
  await reactGenerator.generateTables(tables);
  console.log('✅ React components generated\n');

  console.log('🎉 Code generation completed successfully!');
}

generateAll().catch(console.error);
```

#### Watch 모드 (`scripts/watch.ts`)

```typescript
import { MetadataWatcher } from '../services/metadata-watcher';
import { generateAll } from './generate-all';

async function watchMode() {
  console.log('👀 Watching for metadata changes...\n');

  const watcher = new MetadataWatcher({
    connectionString: process.env.METADATA_DATABASE_URL!,
    channel: 'metadata_changed'
  });

  watcher.on('change', async (event) => {
    console.log(`🔄 Metadata changed: ${event.table} (${event.operation})`);
    console.log('🔄 Regenerating code...\n');

    await generateAll();

    console.log('✅ Code regeneration completed\n');
  });

  await watcher.start();
}

watchMode();
```

### 2. 생성된 코드 확장 패턴

#### Service 확장

```typescript
// backend/src/generated/services/user-service.ts (생성됨)
export class UserServiceBase {
  async findById(id: string): Promise<User | null> {
    return this.db.query<User>(
      'SELECT * FROM users WHERE id = $1',
      [id]
    ).then(result => result.rows[0] || null);
  }

  async findAll(filter?: UserFilter): Promise<User[]> {
    // 기본 CRUD 로직
  }
}

// backend/src/custom/services/user-service.ts (커스텀)
import { UserServiceBase } from '../../generated/services/user-service';

export class UserService extends UserServiceBase {
  // 커스텀 메서드 추가
  async findByEmailDomain(domain: string): Promise<User[]> {
    return this.db.query<User>(
      'SELECT * FROM users WHERE email LIKE $1',
      [`%@${domain}`]
    ).then(result => result.rows);
  }

  // 기존 메서드 오버라이드
  async create(input: UserInput): Promise<User> {
    // 비밀번호 해싱 등 추가 로직
    const hashedPassword = await bcrypt.hash(input.password, 10);

    return super.create({
      ...input,
      password: hashedPassword
    });
  }
}
```

#### Resolver 확장

```typescript
// backend/src/generated/resolvers/user-resolvers.ts (생성됨)
export const userResolversBase: Resolvers = {
  Query: {
    user: async (parent, { id }, context) => {
      return context.services.user.findById(id);
    }
  }
};

// backend/src/custom/resolvers/user-resolvers.ts (커스텀)
import { userResolversBase } from '../../generated/resolvers/user-resolvers';

export const userResolvers: Resolvers = {
  ...userResolversBase,

  Query: {
    ...userResolversBase.Query,

    // 커스텀 쿼리 추가
    usersByDomain: async (parent, { domain }, context) => {
      return context.services.user.findByEmailDomain(domain);
    }
  },

  Mutation: {
    ...userResolversBase.Mutation,

    // 커스텀 뮤테이션 추가
    registerUser: async (parent, { input }, context) => {
      // 회원가입 특화 로직
      await context.services.email.sendWelcomeEmail(input.email);
      return context.services.user.create(input);
    }
  },

  User: {
    // 계산된 필드 추가
    fullName: (parent) => {
      return `${parent.firstName} ${parent.lastName}`;
    },

    // 관계 필드 커스터마이징
    orders: async (parent, args, context) => {
      // 캐싱, 필터링 등 추가 로직
      return context.loaders.ordersByUserId.load(parent.id);
    }
  }
};
```

#### React 컴포넌트 확장

```typescript
// frontend/src/generated/forms/user-form.tsx (생성됨)
export const UserFormBase: React.FC<UserFormProps> = ({ ... }) => {
  // 기본 폼 구현
};

// frontend/src/components/users/user-form.tsx (커스텀)
import { UserFormBase } from '@/generated/forms/user-form';
import { useUserValidation } from '@/hooks/use-user-validation';

export const UserForm: React.FC<UserFormProps> = (props) => {
  const { validateEmail } = useUserValidation();

  // 커스텀 로직 추가
  const handleSubmit = async (data: UserFormValues) => {
    // 추가 검증
    const isEmailValid = await validateEmail(data.email);
    if (!isEmailValid) {
      toast.error('이미 사용 중인 이메일입니다.');
      return;
    }

    // 원래 onSubmit 호출
    await props.onSubmit(data);
  };

  return (
    <div className="space-y-4">
      {/* 커스텀 헤더 */}
      <h2 className="text-2xl font-bold">사용자 등록</h2>

      {/* 생성된 폼 재사용 */}
      <UserFormBase {...props} onSubmit={handleSubmit} />

      {/* 커스텀 푸터 */}
      <p className="text-sm text-gray-500">
        * 표시된 항목은 필수 입력 항목입니다.
      </p>
    </div>
  );
};
```

### 3. 디렉토리 구조 규칙

```
backend/
├── src/
│   ├── generated/              # 자동 생성된 코드 (절대 수정 금지)
│   │   ├── types.ts
│   │   ├── schema.graphql
│   │   ├── resolvers/
│   │   │   ├── index.ts
│   │   │   ├── user-resolvers.ts
│   │   │   └── product-resolvers.ts
│   │   └── services/
│   │       ├── user-service.ts
│   │       └── product-service.ts
│   │
│   ├── custom/                 # 커스텀 로직 (여기에 코드 작성)
│   │   ├── resolvers/
│   │   │   ├── user-resolvers.ts
│   │   │   └── product-resolvers.ts
│   │   ├── services/
│   │   │   ├── user-service.ts
│   │   │   └── email-service.ts
│   │   └── middleware/
│   │       ├── auth.ts
│   │       └── logger.ts
│   │
│   ├── utils/                  # 유틸리티 함수
│   ├── config/                 # 설정 파일
│   └── index.ts                # 엔트리 포인트
│
└── scripts/                    # 코드 생성 스크립트
    ├── generate-all.ts
    ├── watch.ts
    └── generators/
        ├── database-generator.ts
        ├── graphql-generator.ts
        └── react-generator.ts

frontend/
├── src/
│   ├── generated/              # 자동 생성된 코드
│   │   ├── types.ts
│   │   ├── forms/
│   │   │   ├── user-form.tsx
│   │   │   └── product-form.tsx
│   │   └── tables/
│   │       ├── user-table.tsx
│   │       └── product-table.tsx
│   │
│   ├── components/             # 커스텀 컴포넌트
│   │   ├── users/
│   │   │   ├── user-form.tsx
│   │   │   └── user-detail.tsx
│   │   └── ui/                 # shadcn/ui 컴포넌트
│   │
│   ├── hooks/                  # 커스텀 훅
│   │   ├── use-users.ts
│   │   └── use-user-validation.ts
│   │
│   ├── lib/                    # 라이브러리 설정
│   │   ├── apollo-client.ts
│   │   └── utils.ts
│   │
│   └── app/                    # Next.js App Router
│       ├── users/
│       │   ├── page.tsx
│       │   └── [id]/
│       │       └── page.tsx
│       └── layout.tsx
```

---

## TypeScript 타입 시스템

### 1. 생성된 타입 구조

```typescript
// backend/src/generated/types.ts

// 데이터베이스 엔티티 타입
export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  status: UserStatus;
  createdAt: Date;
  updatedAt: Date;
}

// Enum 타입
export enum UserStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  PENDING = 'PENDING'
}

// GraphQL Input 타입
export interface UserInput {
  email: string;
  firstName: string;
  lastName: string;
  status: UserStatus;
}

// GraphQL Filter 타입
export interface UserFilter {
  email?: string;
  firstName?: string;
  status?: UserStatus;
  createdAfter?: Date;
  createdBefore?: Date;
}

// Pagination 타입
export interface PageInfo {
  hasNextPage: boolean;
  hasPreviousPage: boolean;
  startCursor?: string;
  endCursor?: string;
}

export interface UserConnection {
  edges: UserEdge[];
  pageInfo: PageInfo;
  totalCount: number;
}

export interface UserEdge {
  node: User;
  cursor: string;
}
```

### 2. 공유 타입 정의

```typescript
// backend/src/types/common.ts

export interface PaginationInput {
  limit?: number;
  offset?: number;
  cursor?: string;
}

export interface SortInput {
  field: string;
  direction: 'ASC' | 'DESC';
}

export interface SearchInput {
  query: string;
  fields: string[];
}

// Context 타입
export interface GraphQLContext {
  user?: User;
  services: {
    user: UserService;
    product: ProductService;
    email: EmailService;
  };
  loaders: {
    userById: DataLoader<string, User>;
    ordersByUserId: DataLoader<string, Order[]>;
  };
  db: DatabaseConnection;
}

// Service 인터페이스
export interface IService<T, TInput, TFilter> {
  findById(id: string): Promise<T | null>;
  findAll(filter?: TFilter, pagination?: PaginationInput): Promise<T[]>;
  create(input: TInput): Promise<T>;
  update(id: string, input: Partial<TInput>): Promise<T>;
  delete(id: string): Promise<boolean>;
}
```

### 3. 타입 가드 및 유틸리티

```typescript
// backend/src/utils/type-guards.ts

export function isUser(obj: any): obj is User {
  return (
    typeof obj === 'object' &&
    typeof obj.id === 'string' &&
    typeof obj.email === 'string'
  );
}

export function isUserStatus(value: string): value is UserStatus {
  return Object.values(UserStatus).includes(value as UserStatus);
}

// 타입 변환 유틸리티
export function toGraphQLUser(dbUser: any): User {
  return {
    id: String(dbUser.id),
    email: dbUser.email,
    firstName: dbUser.first_name,
    lastName: dbUser.last_name,
    status: dbUser.status as UserStatus,
    createdAt: new Date(dbUser.created_at),
    updatedAt: new Date(dbUser.updated_at)
  };
}

export function toDbUser(user: UserInput): Record<string, any> {
  return {
    email: user.email,
    first_name: user.firstName,
    last_name: user.lastName,
    status: user.status
  };
}
```

---

## GraphQL 스키마 설계

### 1. 생성된 스키마 구조

```graphql
# backend/src/generated/schema.graphql

# Scalar types
scalar DateTime
scalar JSON

# Enums
enum UserStatus {
  ACTIVE
  INACTIVE
  PENDING
}

# Main types
type User {
  id: ID!
  email: String!
  firstName: String!
  lastName: String!
  fullName: String!           # Computed field
  status: UserStatus!
  createdAt: DateTime!
  updatedAt: DateTime!

  # Relations
  orders: [Order!]!
  profile: UserProfile
}

# Input types
input UserInput {
  email: String!
  firstName: String!
  lastName: String!
  status: UserStatus
}

input UserUpdateInput {
  email: String
  firstName: String
  lastName: String
  status: UserStatus
}

input UserFilter {
  email: String
  firstName: String
  status: UserStatus
  search: String              # Full-text search
  createdAfter: DateTime
  createdBefore: DateTime
}

# Pagination
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type UserEdge {
  node: User!
  cursor: String!
}

type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

# Queries
type Query {
  # Single item
  user(id: ID!): User

  # List
  users(
    filter: UserFilter
    sort: SortInput
    limit: Int = 20
    offset: Int = 0
  ): [User!]!

  # Pagination
  usersPaginated(
    filter: UserFilter
    sort: SortInput
    first: Int
    after: String
    last: Int
    before: String
  ): UserConnection!

  # Count
  usersCount(filter: UserFilter): Int!

  # Search
  searchUsers(query: String!, limit: Int = 10): [User!]!
}

# Mutations
type Mutation {
  # Create
  createUser(input: UserInput!): User!

  # Update
  updateUser(id: ID!, input: UserUpdateInput!): User!

  # Delete
  deleteUser(id: ID!): Boolean!

  # Batch operations
  createUsers(inputs: [UserInput!]!): [User!]!
  deleteUsers(ids: [ID!]!): Int!
}

# Subscriptions (optional)
type Subscription {
  userCreated: User!
  userUpdated(id: ID): User!
  userDeleted: ID!
}
```

### 2. 커스텀 스키마 확장

```graphql
# backend/src/custom/schema.graphql

extend type Query {
  # 커스텀 쿼리
  usersByDomain(domain: String!): [User!]!
  userStats: UserStats!
  me: User
}

extend type Mutation {
  # 커스텀 뮤테이션
  registerUser(input: RegisterUserInput!): AuthPayload!
  loginUser(email: String!, password: String!): AuthPayload!
  logoutUser: Boolean!
  changePassword(oldPassword: String!, newPassword: String!): Boolean!
}

# 커스텀 타입
type UserStats {
  totalUsers: Int!
  activeUsers: Int!
  inactiveUsers: Int!
  pendingUsers: Int!
  newUsersToday: Int!
  newUsersThisWeek: Int!
  newUsersThisMonth: Int!
}

input RegisterUserInput {
  email: String!
  password: String!
  firstName: String!
  lastName: String!
  agreeToTerms: Boolean!
}

type AuthPayload {
  user: User!
  token: String!
  refreshToken: String!
  expiresIn: Int!
}
```

---

## React 컴포넌트 패턴

### 1. 생성된 폼 컴포넌트 활용

```typescript
// frontend/src/app/users/new/page.tsx

'use client';

import { UserForm } from '@/generated/forms/user-form';
import { useCreateUser } from '@/hooks/use-users';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

export default function NewUserPage() {
  const router = useRouter();
  const { createUser, loading } = useCreateUser();

  const handleSubmit = async (data: UserFormValues) => {
    try {
      const user = await createUser(data);
      toast.success('사용자가 생성되었습니다.');
      router.push(`/users/${user.id}`);
    } catch (error) {
      toast.error('사용자 생성에 실패했습니다.');
      console.error(error);
    }
  };

  return (
    <div className="container max-w-2xl mx-auto py-10">
      <h1 className="text-3xl font-bold mb-6">새 사용자 등록</h1>

      <UserForm
        onSubmit={handleSubmit}
        loading={loading}
      />
    </div>
  );
}
```

### 2. 생성된 테이블 컴포넌트 활용

```typescript
// frontend/src/app/users/page.tsx

'use client';

import { UserTable } from '@/generated/tables/user-table';
import { useUsers } from '@/hooks/use-users';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { PlusIcon } from 'lucide-react';

export default function UsersPage() {
  const router = useRouter();
  const { data, loading, refetch } = useUsers();

  return (
    <div className="container mx-auto py-10">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">사용자 관리</h1>

        <Button onClick={() => router.push('/users/new')}>
          <PlusIcon className="mr-2 h-4 w-4" />
          새 사용자
        </Button>
      </div>

      <UserTable
        data={data}
        loading={loading}
        onRowClick={(user) => router.push(`/users/${user.id}`)}
      />
    </div>
  );
}
```

### 3. GraphQL 훅 패턴

```typescript
// frontend/src/hooks/use-users.ts

import { useQuery, useMutation } from '@apollo/client';
import { gql } from '@apollo/client';
import type { User, UserInput, UserFilter } from '@/generated/types';

// Queries
const GET_USERS = gql`
  query GetUsers($filter: UserFilter, $limit: Int, $offset: Int) {
    users(filter: $filter, limit: $limit, offset: $offset) {
      id
      email
      firstName
      lastName
      status
      createdAt
    }
  }
`;

const GET_USER = gql`
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      email
      firstName
      lastName
      status
      createdAt
      updatedAt
      orders {
        id
        totalAmount
        createdAt
      }
    }
  }
`;

// Mutations
const CREATE_USER = gql`
  mutation CreateUser($input: UserInput!) {
    createUser(input: $input) {
      id
      email
      firstName
      lastName
      status
    }
  }
`;

const UPDATE_USER = gql`
  mutation UpdateUser($id: ID!, $input: UserUpdateInput!) {
    updateUser(id: $id, input: $input) {
      id
      email
      firstName
      lastName
      status
    }
  }
`;

const DELETE_USER = gql`
  mutation DeleteUser($id: ID!) {
    deleteUser(id: $id)
  }
`;

// Hooks
export function useUsers(filter?: UserFilter) {
  const { data, loading, error, refetch } = useQuery(GET_USERS, {
    variables: { filter },
  });

  return {
    data: data?.users || [],
    loading,
    error,
    refetch,
  };
}

export function useUser(id: string) {
  const { data, loading, error, refetch } = useQuery(GET_USER, {
    variables: { id },
    skip: !id,
  });

  return {
    data: data?.user,
    loading,
    error,
    refetch,
  };
}

export function useCreateUser() {
  const [createUser, { loading, error }] = useMutation(CREATE_USER, {
    refetchQueries: [{ query: GET_USERS }],
  });

  return {
    createUser: async (input: UserInput) => {
      const result = await createUser({ variables: { input } });
      return result.data.createUser;
    },
    loading,
    error,
  };
}

export function useUpdateUser() {
  const [updateUser, { loading, error }] = useMutation(UPDATE_USER);

  return {
    updateUser: async (id: string, input: Partial<UserInput>) => {
      const result = await updateUser({ variables: { id, input } });
      return result.data.updateUser;
    },
    loading,
    error,
  };
}

export function useDeleteUser() {
  const [deleteUser, { loading, error }] = useMutation(DELETE_USER, {
    refetchQueries: [{ query: GET_USERS }],
  });

  return {
    deleteUser: async (id: string) => {
      await deleteUser({ variables: { id } });
    },
    loading,
    error,
  };
}
```

---

## 테스트 전략

### 1. 메타데이터 검증 테스트

```typescript
// tests/metadata/validation.test.ts

import { MetadataService } from '@/services/metadata-service';

describe('Metadata Validation', () => {
  let metadata: MetadataService;

  beforeAll(() => {
    metadata = new MetadataService();
  });

  test('모든 테이블은 기본키를 가져야 함', async () => {
    const tables = await metadata.getAllTables();

    for (const table of tables) {
      const hasPrimaryKey = table.columns.some(col => col.isPrimaryKey);
      expect(hasPrimaryKey).toBe(true);
    }
  });

  test('필수 필드는 기본값이 없어야 함', async () => {
    const columns = await metadata.getAllColumns();

    for (const col of columns) {
      if (col.isRequired && !col.isPrimaryKey) {
        expect(col.defaultValue).toBeNull();
      }
    }
  });

  test('Enum 필드는 옵션을 가져야 함', async () => {
    const columns = await metadata.getColumnsByFormType('select');

    for (const col of columns) {
      expect(col.enumOptions).toBeDefined();
      expect(Array.isArray(col.enumOptions)).toBe(true);
      expect(col.enumOptions.length).toBeGreaterThan(0);
    }
  });

  test('관계는 순환 참조가 없어야 함', async () => {
    const relations = await metadata.getAllRelations();
    const graph = buildRelationGraph(relations);

    expect(hasCycle(graph)).toBe(false);
  });
});
```

### 2. 코드 생성 테스트

```typescript
// tests/generators/graphql-generator.test.ts

import { GraphQLGenerator } from '@/generators/graphql-generator';
import { parse } from 'graphql';

describe('GraphQL Generator', () => {
  let generator: GraphQLGenerator;

  beforeAll(() => {
    generator = new GraphQLGenerator();
  });

  test('생성된 스키마가 유효한 GraphQL 스키마임', async () => {
    const tables = await loadTestTables();
    const schema = await generator.generateSchema(tables);

    expect(() => parse(schema)).not.toThrow();
  });

  test('모든 타입은 ID 필드를 가짐', async () => {
    const tables = await loadTestTables();
    const schema = await generator.generateSchema(tables);

    const parsed = parse(schema);
    const types = parsed.definitions.filter(d => d.kind === 'ObjectTypeDefinition');

    for (const type of types) {
      const hasId = type.fields.some(f => f.name.value === 'id');
      expect(hasId).toBe(true);
    }
  });
});
```

### 3. E2E 테스트

```typescript
// tests/e2e/user-crud.test.ts

import { test, expect } from '@playwright/test';

test.describe('User CRUD Operations', () => {
  test('사용자 생성, 조회, 수정, 삭제', async ({ page }) => {
    // 1. 사용자 목록 페이지 접속
    await page.goto('/users');
    await expect(page.getByRole('heading', { name: '사용자 관리' })).toBeVisible();

    // 2. 새 사용자 생성
    await page.click('text=새 사용자');
    await page.fill('input[name="firstName"]', 'John');
    await page.fill('input[name="lastName"]', 'Doe');
    await page.fill('input[name="email"]', 'john@example.com');
    await page.selectOption('select[name="status"]', 'ACTIVE');
    await page.click('button[type="submit"]');

    // 3. 생성 확인
    await expect(page).toHaveURL(/\/users\/\d+/);
    await expect(page.getByText('John Doe')).toBeVisible();

    // 4. 수정
    await page.click('text=수정');
    await page.fill('input[name="firstName"]', 'Jane');
    await page.click('button[type="submit"]');
    await expect(page.getByText('Jane Doe')).toBeVisible();

    // 5. 삭제
    await page.click('text=삭제');
    await page.click('text=확인');
    await expect(page).toHaveURL('/users');
  });
});
```

---

## 배포 및 CI/CD

### 1. Docker 설정

```dockerfile
# backend/Dockerfile

FROM node:20-alpine AS builder

WORKDIR /app

# 의존성 설치
COPY package*.json ./
RUN npm ci

# 소스 복사 및 빌드
COPY . .
RUN npm run generate  # 코드 생성
RUN npm run build

# Production 이미지
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

EXPOSE 4000

CMD ["node", "dist/index.js"]
```

### 2. GitHub Actions CI/CD

```yaml
# .github/workflows/ci-cd.yml

name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Setup metadata database
        run: |
          psql -h localhost -U postgres -c "CREATE DATABASE metadb;"
          psql -h localhost -U postgres -d metadb -f database/schema/metadata.sql

      - name: Generate code
        run: npm run generate

      - name: Run tests
        run: npm test

      - name: Run E2E tests
        run: npm run test:e2e

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Build and push Docker image
        run: |
          docker build -t myapp:latest .
          docker push myapp:latest

      - name: Deploy to production
        run: |
          # 배포 스크립트 실행
          ./deploy.sh
```

---

## 트러블슈팅

### 1. 코드 생성 오류

**문제**: 코드 생성 시 타입 에러 발생

```
Error: Cannot find type 'UserStatus'
```

**해결**:
1. 메타데이터에서 enum_options 확인
2. GraphQL enum 타입이 생성되었는지 확인
3. TypeScript enum이 exports 되었는지 확인

```typescript
// 확인 사항
const column = await metadata.getColumn('users', 'status');
console.log(column.enumOptions); // null이면 안됨

// 수정
UPDATE mappings_column
SET enum_options = '[...]'::jsonb
WHERE table_name = 'users' AND pg_column = 'status';
```

### 2. GraphQL 쿼리 성능 문제

**문제**: N+1 쿼리 발생

**해결**: DataLoader 사용

```typescript
// context.ts
import DataLoader from 'dataloader';

export function createContext() {
  return {
    loaders: {
      userById: new DataLoader(async (ids: readonly string[]) => {
        const users = await db.query(
          'SELECT * FROM users WHERE id = ANY($1)',
          [ids]
        );
        return ids.map(id => users.find(u => u.id === id));
      }),
    },
  };
}
```

### 3. 메타데이터 동기화 문제

**문제**: 메타데이터 변경 후 코드가 자동 생성되지 않음

**해결**:
1. Watch 모드가 실행 중인지 확인
2. PostgreSQL NOTIFY가 작동하는지 확인

```bash
# Watch 모드 확인
ps aux | grep "watch"

# NOTIFY 테스트
psql -U postgres -d metadb -c "NOTIFY metadata_changed, 'test';"
```

---

**문서 버전**: 1.0.0
**최종 수정**: 2024-10-19
**관리**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/meta-data-driven`
