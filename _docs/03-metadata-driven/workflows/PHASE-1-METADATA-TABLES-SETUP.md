# Phase 1: 메타데이터 테이블 초기화

> 프로젝트 모델링 전에 생성해야 하는 PostgreSQL 메타데이터 테이블 완벽 가이드

## 📋 목차

1. [개요](#개요)
2. [메타데이터 DB 초기화](#메타데이터-db-초기화)
3. [메타데이터 테이블 목록](#메타데이터-테이블-목록)
4. [테이블 상세 스키마](#테이블-상세-스키마)
5. [초기화 스크립트](#초기화-스크립트)
6. [검증 및 테스트](#검증-및-테스트)

---

## 개요

### 메타데이터 테이블이란?

메타데이터 테이블은 **실제 비즈니스 데이터를 저장하는 테이블이 아니라**, 그 테이블들의 **스키마 정보**를 저장하는 특별한 테이블입니다.

```
프로젝트 DB (예: myapp_db)
├── _metadata schema (메타데이터 저장)
│   ├── project                 ← 이 프로젝트 정보 (단일 레코드)
│   ├── mappings_table          ← 이 문서에서 생성
│   ├── mappings_column            스키마 정의 저장
│   └── mappings_relation
│
└── public schema (비즈니스 데이터)
    ├── users                   ← 나중에 자동 생성됨
    ├── products                   실제 데이터 저장
    └── orders
```

**주요 특징:**
- `_metadata` schema에 메타데이터 테이블 저장
- `public` schema에 비즈니스 테이블 저장
- 같은 DB에 함께 저장하여 관리 편의성 확보

**아키텍처 방식:**
이 문서는 **프로젝트별 _metadata 방식**을 사용합니다:
- ✅ 각 프로젝트 DB마다 독립적인 `_metadata` schema 보유
- ✅ 프로젝트 간 완전한 격리 및 독립적인 백업/복원
- ✅ `_metadata.project` 테이블은 단일 레코드만 저장 (이 DB의 프로젝트 정보)
- ❌ `_metadata.project_tables` 테이블 불필요 (DB 분리로 매핑 자동)
- 📚 자세한 내용: [METADATA-ARCHITECTURE-COMPARISON.md](./METADATA-ARCHITECTURE-COMPARISON.md)

### 왜 필요한가?

1. **단일 진실 공급원**: 모든 스키마 정보를 한 곳에서 관리
2. **자동 코드 생성**: 메타데이터를 읽어 DB, API, UI 코드 자동 생성
3. **일관성 보장**: DB, GraphQL, TypeScript, React가 항상 동기화
4. **변경 추적**: 스키마 변경 이력 관리
5. **프로젝트별 격리**: 각 프로젝트 DB마다 독립적인 _metadata 보유

### 생성 순서

```
1. 프로젝트 DB 생성 (또는 기존 DB 사용)
   ↓
2. _metadata schema 생성
   ↓
3. ENUM 타입 생성 (in _metadata schema)
   ↓
4. 프로젝트 정보 테이블 생성
   - _metadata.project (단일 레코드)
   ↓
5. 핵심 메타데이터 테이블 생성
   - _metadata.mappings_table
   - _metadata.mappings_column
   - _metadata.mappings_relation
   ↓
6. 선택적 테이블 생성
   - _metadata.mappings_api_endpoint
   - _metadata.metadata_sync_log
   ↓
7. 인덱스 및 최적화
   ↓
8. 검증
```

---

## 메타데이터 DB 초기화

### 1. 데이터베이스 초기화

**프로젝트 DB에 _metadata schema 생성 (프로젝트별 메타데이터 격리)**

```bash
# PostgreSQL에 접속
psql -U postgres

# 기존 프로젝트 DB 사용 (또는 새로 생성)
CREATE DATABASE myapp_db
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

# 접속
\c myapp_db

# _metadata schema 생성
CREATE SCHEMA _metadata;
COMMENT ON SCHEMA _metadata IS '메타데이터 기반 개발 시스템의 메타데이터 저장소';

# 확장 설치 (JSONB 검색 최적화)
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- 텍스트 검색 최적화

# Search Path 설정 (선택 - schema명 생략 가능)
ALTER DATABASE myapp_db SET search_path TO public, _metadata;

# 종료
\q
```

**아키텍처 특징:**
- ✅ 각 프로젝트 DB마다 독립적인 `_metadata` schema 보유
- ✅ 프로젝트 간 완전한 격리 (독립적인 백업/복원)
- ✅ 확장성 우수 (프로젝트 추가 시 독립적으로 확장)
- ✅ 코드 생성기가 단일 DB만 접속하면 모든 정보 조회 가능

### 2. 스키마 파일 준비

메타데이터 테이블 DDL을 파일로 저장합니다:

```bash
# 작업 디렉토리 생성
mkdir -p /workspace/metadata-system/schema

# SQL 파일 생성 (아래 스크립트 참조)
cd /workspace/metadata-system/schema
```

---

## 메타데이터 테이블 목록

**모든 테이블은 `_metadata` schema에 생성됩니다.**

### 프로젝트 정보 테이블 (필수)

| 전체 테이블명 | 테이블명 | 용도 | 특징 |
|--------------|---------|------|------|
| `_metadata.project` | project | 이 프로젝트 정보 | 단일 레코드 (id=1) |

### 핵심 메타데이터 테이블 (필수)

| 전체 테이블명 | 테이블명 | 용도 | 관계 |
|--------------|---------|------|------|
| `_metadata.mappings_table` | mappings_table | 테이블 레벨 메타데이터 | - |
| `_metadata.mappings_column` | mappings_column | 컬럼 레벨 메타데이터 | → `mappings_table` (FK) |
| `_metadata.mappings_relation` | mappings_relation | 테이블 간 관계 정의 | → `mappings_table` (FK × 2) |

### 선택적 테이블

| 전체 테이블명 | 테이블명 | 용도 | 필요 시점 |
|--------------|---------|------|----------|
| `_metadata.mappings_api_endpoint` | mappings_api_endpoint | 외부 API 연동 설정 | 외부 API 사용 시 |
| `_metadata.metadata_sync_log` | metadata_sync_log | 변경 이력 추적 | 이력 관리 필요 시 |

### ENUM 타입

| ENUM 타입 | 값 | 용도 |
|-----------|-----|------|
| `relation_type_enum` | `OneToOne`, `OneToMany`, `ManyToOne`, `ManyToMany` | 관계 타입 |
| `http_method_enum` | `GET`, `POST`, `PUT`, `DELETE`, `PATCH` | HTTP 메서드 |
| `project_status_enum` | `PLANNING`, `DEVELOPMENT`, `TESTING`, 등 | 프로젝트 상태 |
| `project_template_enum` | `BASIC`, `ECOMMERCE`, `CMS`, 등 | 프로젝트 템플릿 |

---

## 테이블 상세 스키마

### 1. _metadata.mappings_table (테이블 메타데이터)

**용도**: 각 비즈니스 엔티티(테이블)의 기본 정보를 저장합니다.

```sql
CREATE TABLE _metadata.mappings_table (
    id BIGSERIAL PRIMARY KEY,

    -- 테이블 식별
    schema_name VARCHAR(100) NOT NULL DEFAULT 'public',
    table_name VARCHAR(100) NOT NULL,

    -- GraphQL 매핑
    graphql_type VARCHAR(100),              -- 예: 'User', 'Product'

    -- 설명
    label VARCHAR(200) NOT NULL,            -- 예: '사용자'
    description TEXT,                        -- 상세 설명

    -- 테이블 설정
    primary_key VARCHAR(100) DEFAULT 'id',  -- PK 컬럼명
    is_api_enabled BOOLEAN DEFAULT TRUE,    -- API 노출 여부

    -- 권한 및 제약
    api_permissions JSONB,                   -- {'read': 'public', 'write': 'admin'}
    table_constraints JSONB,                 -- CHECK, UNIQUE 제약 조건

    -- 인덱스
    indexes JSONB,                           -- 인덱스 정의

    -- 감사
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약조건
    UNIQUE(schema_name, table_name)
);

COMMENT ON TABLE _metadata.mappings_table IS '테이블 레벨 메타데이터 - 각 비즈니스 엔티티의 기본 정보';

-- 예제 데이터
COMMENT ON COLUMN mappings_table.api_permissions IS
    '예: {"read": "public", "write": "authenticated", "delete": "admin"}';
COMMENT ON COLUMN mappings_table.table_constraints IS
    '예: {"checks": [{"name": "check_status", "condition": "status IN (''ACTIVE'', ''INACTIVE'')"}]}';
COMMENT ON COLUMN mappings_table.indexes IS
    '예: [{"columns": ["email"], "type": "UNIQUE"}, {"columns": ["created_at"], "type": "BTREE"}]';
```

**주요 컬럼 설명**:

- `schema_name`: PostgreSQL 스키마명 (기본 'public')
- `table_name`: 실제 테이블명 (snake_case 권장)
- `graphql_type`: GraphQL Type 이름 (PascalCase)
- `label`: UI에 표시될 한글 이름
- `api_permissions`: JSONB로 권한 세밀하게 제어
- `table_constraints`: CHECK, UNIQUE 등의 제약 조건 정의

---

### 2. mappings_column (컬럼 메타데이터)

**용도**: 각 컬럼의 상세 정보 (DB 타입, GraphQL 타입, UI 설정 등)를 저장합니다.

```sql
CREATE TABLE _metadata.mappings_column (
    id BIGSERIAL PRIMARY KEY,
    table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,

    -- ========================================
    -- 데이터베이스 관련
    -- ========================================
    pg_column VARCHAR(100) NOT NULL,        -- PostgreSQL 컬럼명 (snake_case)
    pg_type VARCHAR(100),                   -- 예: 'VARCHAR(255)', 'INTEGER', 'TIMESTAMPTZ'
    pg_constraints JSONB,                   -- NOT NULL, DEFAULT, CHECK 등

    -- ========================================
    -- GraphQL 관련
    -- ========================================
    graphql_field VARCHAR(100),             -- GraphQL 필드명 (camelCase)
    graphql_type VARCHAR(50),               -- 예: 'String', 'Int', 'DateTime'
    graphql_resolver TEXT,                  -- 커스텀 리졸버 함수명
    is_graphql_input BOOLEAN DEFAULT TRUE,  -- Input에 포함 여부
    is_graphql_output BOOLEAN DEFAULT TRUE, -- Output에 포함 여부

    -- ========================================
    -- UI 관련
    -- ========================================
    label VARCHAR(200) NOT NULL,            -- UI 라벨 (예: '이메일 주소')
    form_type VARCHAR(50) DEFAULT 'text',   -- 'text', 'email', 'number', 'select', 등
    is_required BOOLEAN DEFAULT FALSE,      -- 필수 입력 여부
    is_visible BOOLEAN DEFAULT TRUE,        -- UI 표시 여부
    sort_order INTEGER DEFAULT 0,           -- 폼 필드 순서

    -- ========================================
    -- 값 및 검증
    -- ========================================
    default_value TEXT,                     -- 기본값
    enum_options JSONB,                     -- SELECT/RADIO 옵션
    validation_rules JSONB,                 -- 검증 규칙

    -- ========================================
    -- UI 도움말
    -- ========================================
    placeholder VARCHAR(200),               -- 입력란 힌트
    help_text TEXT,                         -- 설명 텍스트

    -- ========================================
    -- API 소스 관련 (외부 API 연동)
    -- ========================================
    api_source_key VARCHAR(200),            -- API 응답의 키 경로
    api_source_path VARCHAR(500),           -- API 엔드포인트 경로
    api_source_type VARCHAR(100),           -- API 타입
    data_transformation JSONB,              -- 데이터 변환 로직
    is_api_field BOOLEAN DEFAULT FALSE,     -- 외부 API 필드 여부
    api_default_value TEXT,                 -- API 기본값
    api_endpoints JSONB,                    -- 연동 API 목록

    -- ========================================
    -- 권한 및 보안
    -- ========================================
    permission_read VARCHAR(100) DEFAULT 'public',        -- 읽기 권한
    permission_write VARCHAR(100) DEFAULT 'authenticated',-- 쓰기 권한

    -- ========================================
    -- 검색 및 필터링
    -- ========================================
    is_searchable BOOLEAN DEFAULT FALSE,    -- 전체 텍스트 검색 가능
    is_sortable BOOLEAN DEFAULT TRUE,       -- 정렬 가능
    is_filterable BOOLEAN DEFAULT TRUE,     -- 필터 가능
    search_config JSONB,                    -- 검색 설정

    -- ========================================
    -- 인덱스 관련
    -- ========================================
    is_primary_key BOOLEAN DEFAULT FALSE,   -- PK 여부
    is_unique BOOLEAN DEFAULT FALSE,        -- UNIQUE 제약
    is_indexed BOOLEAN DEFAULT FALSE,       -- 인덱스 생성 여부
    index_config JSONB,                     -- 인덱스 세부 설정

    -- ========================================
    -- 기타
    -- ========================================
    comment TEXT,                           -- 컬럼 주석
    remark TEXT,                            -- 개발자 메모
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약조건
    UNIQUE(schema_name, table_name, pg_column)
);

COMMENT ON TABLE _metadata.mappings_column IS '컬럼 레벨 메타데이터 - 각 필드의 상세 정보';

-- 예제 데이터 주석
COMMENT ON COLUMN mappings_column.pg_constraints IS
    '예: {"notNull": true, "default": "ACTIVE", "check": "status IN (''ACTIVE'', ''INACTIVE'')"}';

COMMENT ON COLUMN mappings_column.enum_options IS
    '예: [{"value": "ACTIVE", "label": "활성"}, {"value": "INACTIVE", "label": "비활성"}]';

COMMENT ON COLUMN mappings_column.validation_rules IS
    '예: {"minLength": 3, "maxLength": 50, "pattern": "^[a-zA-Z0-9]+$", "email": true}';

COMMENT ON COLUMN mappings_column.search_config IS
    '예: {"weight": "A", "language": "korean", "boost": 2.0}';
```

**주요 컬럼 그룹**:

1. **DB 관련**: `pg_column`, `pg_type`, `pg_constraints`
2. **GraphQL 관련**: `graphql_field`, `graphql_type`, `is_graphql_input/output`
3. **UI 관련**: `label`, `form_type`, `placeholder`, `help_text`
4. **검증**: `validation_rules`, `enum_options`, `default_value`
5. **권한**: `permission_read`, `permission_write`
6. **검색**: `is_searchable`, `is_filterable`, `search_config`

---

### 3. mappings_relation (관계 메타데이터)

**용도**: 테이블 간의 Foreign Key 관계를 정의합니다.

```sql
-- ENUM 타입 먼저 생성
CREATE TYPE _metadata.relation_type_enum AS ENUM (
    'OneToOne',     -- 1:1
    'OneToMany',    -- 1:N
    'ManyToOne',    -- N:1
    'ManyToMany'    -- N:M (조인 테이블 필요)
);

CREATE TABLE _metadata.mappings_relation (
    id BIGSERIAL PRIMARY KEY,

    -- 관계 참조
    from_table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,
    to_table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,

    -- FROM 테이블 (소유자)
    from_schema VARCHAR(100) NOT NULL,
    from_table VARCHAR(100) NOT NULL,
    from_column VARCHAR(100) NOT NULL,      -- FK 컬럼명

    -- TO 테이블 (참조 대상)
    to_schema VARCHAR(100) NOT NULL,
    to_table VARCHAR(100) NOT NULL,
    to_column VARCHAR(100) NOT NULL,        -- 참조 컬럼명 (보통 PK)

    -- 관계 타입
    relation_type _metadata.relation_type_enum NOT NULL,

    -- GraphQL 설정
    graphql_field VARCHAR(100),             -- GraphQL 필드명

    -- 제약 설정
    is_cascade_delete BOOLEAN DEFAULT FALSE,-- ON DELETE CASCADE 여부
    constraint_name VARCHAR(200),           -- FK 제약 조건명

    -- 감사
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약조건
    UNIQUE(from_schema, from_table, from_column, to_schema, to_table, to_column)
);

COMMENT ON TABLE _metadata.mappings_relation IS '테이블 간 관계 정의 - Foreign Key 및 GraphQL 관계';
```

**관계 타입 예시**:

```sql
-- 1:N 관계 예시 (users → posts)
-- 한 명의 사용자가 여러 게시글을 작성
INSERT INTO mappings_relation (
    from_table_id, to_table_id,
    from_schema, from_table, from_column,
    to_schema, to_table, to_column,
    relation_type, graphql_field
) VALUES (
    (SELECT id FROM _metadata.mappings_table WHERE table_name = 'posts'),
    (SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'),
    'public', 'posts', 'user_id',
    'public', 'users', 'id',
    'ManyToOne',
    'author'  -- GraphQL: post.author
);
```

---

### 4. project (프로젝트 정보)

**용도**: 이 데이터베이스가 속한 프로젝트의 정보를 저장합니다 (단일 레코드).

```sql
-- ENUM 타입 먼저 생성
CREATE TYPE _metadata.project_status_enum AS ENUM (
    'PLANNING',      -- 기획 중
    'DEVELOPMENT',   -- 개발 중
    'TESTING',       -- 테스트 중
    'STAGING',       -- 스테이징
    'PRODUCTION',    -- 운영 중
    'MAINTENANCE',   -- 유지보수
    'ARCHIVED'       -- 보관
);

CREATE TYPE _metadata.project_template_enum AS ENUM (
    'BASIC',          -- 기본 템플릿
    'ECOMMERCE',      -- 이커머스
    'CMS',            -- CMS
    'DASHBOARD',      -- 대시보드
    'API_ONLY',       -- API 전용
    'MOBILE_BACKEND', -- 모바일 백엔드
    'MICROSERVICE'    -- 마이크로서비스
);

CREATE TABLE _metadata.project (
    id BIGSERIAL PRIMARY KEY,

    -- 프로젝트 식별
    project_id VARCHAR(100) NOT NULL,           -- 예: 'my-ecommerce'
    project_name VARCHAR(200) NOT NULL,         -- 예: 'My E-commerce Platform'
    description TEXT,

    -- ========================================
    -- 디렉토리 및 경로 정보
    -- ========================================
    root_path VARCHAR(500) NOT NULL,            -- 예: '/workspace/my-ecommerce'
    backend_path VARCHAR(200) DEFAULT './backend',
    frontend_path VARCHAR(200) DEFAULT './frontend',
    database_path VARCHAR(200) DEFAULT './database',

    -- ========================================
    -- 프로젝트 메타정보
    -- ========================================
    template _metadata.project_template_enum DEFAULT 'BASIC',
    status _metadata.project_status_enum DEFAULT 'PLANNING',
    version VARCHAR(50) DEFAULT '1.0.0',

    -- ========================================
    -- 기술 스택 정보
    -- ========================================
    tech_stack JSONB,                           -- 기술 스택 상세
    package_manager VARCHAR(20) DEFAULT 'npm',  -- npm, pnpm, yarn
    node_version VARCHAR(20),                   -- 예: '20.11.0'

    -- ========================================
    -- 데이터베이스 연결 정보
    -- ========================================
    database_config JSONB,                      -- DB 연결 설정
    default_schema VARCHAR(100) DEFAULT 'public',

    -- ========================================
    -- 코드 생성 설정
    -- ========================================
    generation_config JSONB,                    -- 생성 옵션
    auto_generation BOOLEAN DEFAULT TRUE,       -- 자동 생성 여부
    watch_mode BOOLEAN DEFAULT TRUE,            -- Watch 모드 여부

    -- ========================================
    -- Git 및 버전 관리
    -- ========================================
    git_repository VARCHAR(500),                -- GitHub 저장소 URL
    git_branch VARCHAR(100) DEFAULT 'main',

    -- ========================================
    -- 팀 및 권한
    -- ========================================
    owner_id BIGINT,                            -- 소유자 ID
    team_members JSONB,                         -- 팀원 목록

    -- ========================================
    -- 배포 정보
    -- ========================================
    deployment_config JSONB,                    -- 배포 설정
    environments JSONB,                         -- 환경별 설정

    -- ========================================
    -- API 및 서비스 설정
    -- ========================================
    api_config JSONB,                           -- API 설정
    external_services JSONB,                    -- 외부 서비스 연동

    -- ========================================
    -- 개발 도구 설정
    -- ========================================
    dev_tools_config JSONB,                     -- 개발 도구
    linting_config JSONB,                       -- Lint 설정
    testing_config JSONB,                       -- 테스트 설정

    -- ========================================
    -- 플러그인 및 확장
    -- ========================================
    plugins JSONB,                              -- 플러그인 목록
    custom_generators JSONB,                    -- 커스텀 제너레이터

    -- ========================================
    -- 문서
    -- ========================================
    readme_template TEXT,                       -- README 템플릿
    documentation_config JSONB,                 -- 문서 설정

    -- ========================================
    -- 메타데이터
    -- ========================================
    tags JSONB,                                 -- 태그
    metadata JSONB,                             -- 기타 메타데이터

    -- ========================================
    -- 감사 정보
    -- ========================================
    created_by BIGINT,
    updated_by BIGINT,
    last_generation_at TIMESTAMPTZ,             -- 마지막 코드 생성 시각
    last_sync_at TIMESTAMPTZ,                   -- 마지막 동기화 시각

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약조건: 단일 프로젝트만 저장
    CONSTRAINT single_project CHECK (id = 1)
);

COMMENT ON TABLE _metadata.project IS '프로젝트 정보 - 이 DB의 프로젝트 정보 (단일 레코드)';

-- 예제 데이터 주석
COMMENT ON COLUMN project.tech_stack IS
    '예: {"backend": "Node.js + TypeScript + GraphQL", "frontend": "Next.js + React 19", "database": "PostgreSQL 16"}';

COMMENT ON COLUMN project.database_config IS
    '예: {"host": "localhost", "port": 5432, "database": "myapp_dev", "ssl": false}';

COMMENT ON COLUMN project.generation_config IS
    '예: {"outputDir": "./src/generated", "includeComments": true, "prettier": true}';
```

**JSONB 필드 예시**:

```json
// tech_stack
{
  "backend": "Node.js 20 + TypeScript 5.3 + GraphQL",
  "frontend": "Next.js 15.5.4 + React 19",
  "database": "PostgreSQL 16",
  "orm": "None (Raw SQL)",
  "testing": "Jest + Playwright"
}

// database_config
{
  "host": "localhost",
  "port": 5432,
  "database": "myapp_dev",
  "user": "postgres",
  "ssl": false,
  "poolSize": 20
}

// generation_config
{
  "outputDir": "./src/generated",
  "includeComments": true,
  "prettier": true,
  "typescript": {
    "strict": true,
    "target": "ES2022"
  }
}
```

---

### 5. mappings_api_endpoint (외부 API 연동) - 선택적

**용도**: 외부 API를 메타데이터로 관리하여 자동 연동합니다.

```sql
CREATE TYPE _metadata.http_method_enum AS ENUM (
    'GET', 'POST', 'PUT', 'DELETE', 'PATCH'
);

CREATE TABLE _metadata.mappings_api_endpoint (
    id BIGSERIAL PRIMARY KEY,

    -- API 식별
    endpoint_name VARCHAR(100) NOT NULL UNIQUE,     -- 예: 'github_user_api'
    base_url VARCHAR(500) NOT NULL,                 -- 예: 'https://api.github.com'
    method _metadata.http_method_enum DEFAULT 'GET',

    -- 헤더 및 인증
    headers JSONB,                                  -- 요청 헤더
    auth_config JSONB,                              -- 인증 설정

    -- Rate Limiting
    rate_limit_config JSONB,                        -- 요청 제한 설정

    -- Timeout 및 Retry
    timeout_ms INTEGER DEFAULT 30000,               -- 타임아웃 (밀리초)
    retry_config JSONB,                             -- 재시도 설정

    -- 캐싱
    cache_config JSONB,                             -- 캐시 설정

    -- 데이터 매핑
    request_mapping JSONB,                          -- 요청 데이터 변환
    response_mapping JSONB,                         -- 응답 데이터 변환

    -- 기타
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,

    -- 감사
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE _metadata.mappings_api_endpoint IS '외부 API 엔드포인트 설정';

-- 예제 데이터 주석
COMMENT ON COLUMN mappings_api_endpoint.auth_config IS
    '예: {"type": "Bearer", "tokenField": "access_token", "refreshUrl": "/oauth/token"}';

COMMENT ON COLUMN mappings_api_endpoint.rate_limit_config IS
    '예: {"maxRequests": 100, "windowMs": 60000}';

COMMENT ON COLUMN mappings_api_endpoint.retry_config IS
    '예: {"maxRetries": 3, "backoff": "exponential", "initialDelay": 1000}';
```

---

### 6. metadata_sync_log (변경 이력) - 선택적

**용도**: 메타데이터 변경 이력을 추적합니다.

```sql
CREATE TABLE _metadata.metadata_sync_log (
    id BIGSERIAL PRIMARY KEY,

    -- 변경 정보
    table_name VARCHAR(100) NOT NULL,       -- 변경된 메타데이터 테이블
    operation VARCHAR(20) NOT NULL,         -- INSERT, UPDATE, DELETE
    record_id BIGINT,                       -- 변경된 레코드 ID

    -- 변경 내용
    old_data JSONB,                         -- 변경 전 데이터
    new_data JSONB,                         -- 변경 후 데이터

    -- 코드 생성 정보
    code_generated BOOLEAN DEFAULT FALSE,   -- 코드 재생성 여부
    generation_time_ms INTEGER,             -- 생성 소요 시간

    -- 감사
    changed_by BIGINT,                      -- 변경자
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE _metadata.metadata_sync_log IS '메타데이터 변경 이력 추적';

-- 인덱스
CREATE INDEX idx_metadata_sync_log_table ON _metadata.metadata_sync_log(table_name, changed_at DESC);
CREATE INDEX idx_metadata_sync_log_record ON _metadata.metadata_sync_log(table_name, record_id);
```

---

## 초기화 스크립트

### 완전한 초기화 스크립트

다음 SQL 파일을 `00-metadata-tables.sql`로 저장합니다:

```sql
-- ============================================
-- 메타데이터 시스템 초기화 스크립트
-- ============================================
-- 생성일: 2024-10-19
-- 용도: 메타데이터 기반 개발을 위한 테이블 생성
-- 실행: psql -U postgres -d metadb -f 00-metadata-tables.sql
-- ============================================

-- PostgreSQL 확장 설치
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================
-- ENUM 타입 생성
-- ============================================

-- 관계 타입
CREATE TYPE _metadata.relation_type_enum AS ENUM (
    'OneToOne', 'OneToMany', 'ManyToOne', 'ManyToMany'
);

-- HTTP 메서드
CREATE TYPE _metadata.http_method_enum AS ENUM (
    'GET', 'POST', 'PUT', 'DELETE', 'PATCH'
);

-- 프로젝트 상태
CREATE TYPE _metadata.project_status_enum AS ENUM (
    'PLANNING', 'DEVELOPMENT', 'TESTING', 'STAGING', 'PRODUCTION', 'MAINTENANCE', 'ARCHIVED'
);

-- 프로젝트 템플릿
CREATE TYPE _metadata.project_template_enum AS ENUM (
    'BASIC', 'ECOMMERCE', 'CMS', 'DASHBOARD', 'API_ONLY', 'MOBILE_BACKEND', 'MICROSERVICE'
);

-- ============================================
-- 핵심 메타데이터 테이블
-- ============================================

-- 1. 테이블 메타데이터
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

COMMENT ON TABLE _metadata.mappings_table IS '테이블 레벨 메타데이터';

-- 2. 컬럼 메타데이터
CREATE TABLE _metadata.mappings_column (
    id BIGSERIAL PRIMARY KEY,
    table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,

    -- DB
    pg_column VARCHAR(100) NOT NULL,
    pg_type VARCHAR(100),
    pg_constraints JSONB,

    -- GraphQL
    graphql_field VARCHAR(100),
    graphql_type VARCHAR(50),
    graphql_resolver TEXT,
    is_graphql_input BOOLEAN DEFAULT TRUE,
    is_graphql_output BOOLEAN DEFAULT TRUE,

    -- UI
    label VARCHAR(200) NOT NULL,
    form_type VARCHAR(50) DEFAULT 'text',
    is_required BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,

    -- Validation
    default_value TEXT,
    enum_options JSONB,
    validation_rules JSONB,

    -- Help
    placeholder VARCHAR(200),
    help_text TEXT,

    -- API Source
    api_source_key VARCHAR(200),
    api_source_path VARCHAR(500),
    api_source_type VARCHAR(100),
    data_transformation JSONB,
    is_api_field BOOLEAN DEFAULT FALSE,
    api_default_value TEXT,
    api_endpoints JSONB,

    -- Permissions
    permission_read VARCHAR(100) DEFAULT 'public',
    permission_write VARCHAR(100) DEFAULT 'authenticated',

    -- Search
    is_searchable BOOLEAN DEFAULT FALSE,
    is_sortable BOOLEAN DEFAULT TRUE,
    is_filterable BOOLEAN DEFAULT TRUE,
    search_config JSONB,

    -- Index
    is_primary_key BOOLEAN DEFAULT FALSE,
    is_unique BOOLEAN DEFAULT FALSE,
    is_indexed BOOLEAN DEFAULT FALSE,
    index_config JSONB,

    -- Audit
    comment TEXT,
    remark TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(schema_name, table_name, pg_column)
);

COMMENT ON TABLE _metadata.mappings_column IS '컬럼 레벨 메타데이터';

-- 3. 관계 메타데이터
CREATE TABLE _metadata.mappings_relation (
    id BIGSERIAL PRIMARY KEY,
    from_table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,
    to_table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,
    from_schema VARCHAR(100) NOT NULL,
    from_table VARCHAR(100) NOT NULL,
    from_column VARCHAR(100) NOT NULL,
    to_schema VARCHAR(100) NOT NULL,
    to_table VARCHAR(100) NOT NULL,
    to_column VARCHAR(100) NOT NULL,
    relation_type _metadata.relation_type_enum NOT NULL,
    graphql_field VARCHAR(100),
    is_cascade_delete BOOLEAN DEFAULT FALSE,
    constraint_name VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(from_schema, from_table, from_column, to_schema, to_table, to_column)
);

COMMENT ON TABLE _metadata.mappings_relation IS '테이블 간 관계 정의';

-- ============================================
-- 프로젝트 정보 테이블
-- ============================================

-- 4. 프로젝트 정보 (단일 레코드)
CREATE TABLE _metadata.project (
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,
    root_path VARCHAR(500) NOT NULL,
    backend_path VARCHAR(200) DEFAULT './backend',
    frontend_path VARCHAR(200) DEFAULT './frontend',
    database_path VARCHAR(200) DEFAULT './database',
    template _metadata.project_template_enum DEFAULT 'BASIC',
    status _metadata.project_status_enum DEFAULT 'PLANNING',
    version VARCHAR(50) DEFAULT '1.0.0',
    tech_stack JSONB,
    package_manager VARCHAR(20) DEFAULT 'npm',
    node_version VARCHAR(20),
    database_config JSONB,
    default_schema VARCHAR(100) DEFAULT 'public',
    generation_config JSONB,
    auto_generation BOOLEAN DEFAULT TRUE,
    watch_mode BOOLEAN DEFAULT TRUE,
    git_repository VARCHAR(500),
    git_branch VARCHAR(100) DEFAULT 'main',
    owner_id BIGINT,
    team_members JSONB,
    deployment_config JSONB,
    environments JSONB,
    api_config JSONB,
    external_services JSONB,
    dev_tools_config JSONB,
    linting_config JSONB,
    testing_config JSONB,
    plugins JSONB,
    custom_generators JSONB,
    readme_template TEXT,
    documentation_config JSONB,
    tags JSONB,
    metadata JSONB,
    created_by BIGINT,
    updated_by BIGINT,
    last_generation_at TIMESTAMPTZ,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약조건: 단일 프로젝트만 저장
    CONSTRAINT single_project CHECK (id = 1)
);

COMMENT ON TABLE _metadata.project IS '프로젝트 정보 (단일 레코드)';

-- ============================================
-- 선택적 테이블
-- ============================================

-- 5. API 엔드포인트 (외부 API 연동 시)
CREATE TABLE _metadata.mappings_api_endpoint (
    id BIGSERIAL PRIMARY KEY,
    endpoint_name VARCHAR(100) NOT NULL UNIQUE,
    base_url VARCHAR(500) NOT NULL,
    method _metadata.http_method_enum DEFAULT 'GET',
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

COMMENT ON TABLE _metadata.mappings_api_endpoint IS '외부 API 엔드포인트 설정';

-- 6. 변경 이력 (이력 관리 필요 시)
CREATE TABLE _metadata.metadata_sync_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL,
    record_id BIGINT,
    old_data JSONB,
    new_data JSONB,
    code_generated BOOLEAN DEFAULT FALSE,
    generation_time_ms INTEGER,
    changed_by BIGINT,
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE _metadata.metadata_sync_log IS '메타데이터 변경 이력';

-- ============================================
-- 인덱스 생성
-- ============================================

-- JSONB GIN 인덱스
CREATE INDEX idx_mappings_column_enum_options
ON _metadata.mappings_column USING GIN (enum_options);

CREATE INDEX idx_mappings_column_validation_rules
ON _metadata.mappings_column USING GIN (validation_rules);

CREATE INDEX idx_project_tech_stack
ON _metadata.project USING GIN (tech_stack);

-- 부분 인덱스
CREATE INDEX idx_mappings_column_api_fields
ON _metadata.mappings_column (table_name, pg_column)
WHERE is_api_field = TRUE;

CREATE INDEX idx_mappings_column_searchable
ON _metadata.mappings_column (table_name)
WHERE is_searchable = TRUE;

-- 복합 인덱스
CREATE INDEX idx_mappings_column_table_order
ON _metadata.mappings_column (schema_name, table_name, sort_order);

CREATE INDEX idx_project_status
ON _metadata.project(status);

CREATE INDEX idx_metadata_sync_log_table
ON _metadata.metadata_sync_log(table_name, changed_at DESC);

-- ============================================
-- 트리거 (자동 updated_at 업데이트)
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- mappings_table
CREATE TRIGGER trigger_mappings_table_updated_at
    BEFORE UPDATE ON _metadata.mappings_table
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- mappings_column
CREATE TRIGGER trigger_mappings_column_updated_at
    BEFORE UPDATE ON _metadata.mappings_column
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- project
CREATE TRIGGER trigger_project_updated_at
    BEFORE UPDATE ON _metadata.project
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 완료 메시지
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ 메타데이터 테이블 초기화 완료!';
    RAISE NOTICE '';
    RAISE NOTICE '생성된 테이블:';
    RAISE NOTICE '  - project (프로젝트 정보, 단일 레코드)';
    RAISE NOTICE '  - mappings_table';
    RAISE NOTICE '  - mappings_column';
    RAISE NOTICE '  - mappings_relation';
    RAISE NOTICE '  - mappings_api_endpoint';
    RAISE NOTICE '  - metadata_sync_log';
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계: 프로젝트 정보 입력 및 Phase 2 - 메타데이터 정의';
END $$;
```

### 실행 방법

#### 옵션 A: Node.js 스크립트 사용 (권장) ✨

**프로젝트 템플릿에 포함된 방식으로, 원격 PostgreSQL 서버에 적합합니다.**

```bash
# 1. 프로젝트 백엔드 디렉토리로 이동
cd /workspace/my-project/backend/nodejs

# 2. 의존성 설치 (처음 한 번만)
npm install

# 3. 환경변수 설정 (.env 파일)
cat > .env <<EOF
DB_HOST=your-postgres-host
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your-password
DB_NAME=myapp_db
PROJECT_ID=myapp
PROJECT_NAME=My Application
PROJECT_ROOT_PATH=/workspace/my-project
EOF

# 4. 메타데이터 초기화 스크립트 실행
npm run metadata:init

# 출력 예시:
# 📦 메타데이터 테이블 초기화 시작...
# 🔗 연결 정보:
#    Host: your-postgres-host
#    Port: 5432
#    Database: myapp_db
# 📝 _metadata schema 생성 완료
# 📝 ENUM 타입 생성 완료
# 📝 메타데이터 테이블 생성 완료
# 📝 인덱스 생성 완료
# 📝 트리거 생성 완료
# 📝 프로젝트 정보 초기화 완료
# 🔍 검증 중...
# 🎉 메타데이터 테이블 초기화 완료!
```

**스크립트 위치:**
- `backend/nodejs/scripts/init-metadata.ts` - 메타데이터 초기화
- `backend/nodejs/scripts/backup-metadata.ts` - 메타데이터 백업
- `backend/nodejs/scripts/restore-metadata.ts` - 메타데이터 복원

**특징:**
- ✅ `jnu-db` 패키지 사용으로 간편한 PostgreSQL 조작
- ✅ 원격 DB 서버 접속 지원
- ✅ 자동 프로젝트 정보 초기화
- ✅ 검증 및 오류 처리 내장
- ✅ 환경변수 기반 설정

---

#### 옵션 B: SQL 파일 직접 실행 (로컬 psql 사용)

**로컬 PostgreSQL 서버에서 psql 명령어를 사용할 수 있는 경우:**

```bash
# 1. 파일 저장
cd /workspace/metadata-system/schema

# 2. PostgreSQL 실행
psql -U postgres -d myapp_db -f 00-metadata-tables.sql

# 3. 결과 확인
psql -U postgres -d myapp_db -c "\dt _metadata.*"
```

---

### 프로젝트 정보 초기화

#### 옵션 A를 사용한 경우 (Node.js 스크립트)

**자동으로 초기화됩니다!** ✅

`npm run metadata:init` 실행 시 `.env` 파일의 환경변수를 읽어 자동으로 프로젝트 정보가 입력됩니다:

- `PROJECT_ID` → `project_id`
- `PROJECT_NAME` → `project_name`
- `DB_HOST`, `DB_PORT` 등 → `database_config`

**확인 방법:**

```bash
# jnu-db를 사용하여 프로젝트 정보 확인
npm run metadata:check
```

또는 직접 쿼리:

```typescript
// TypeScript 코드에서
import { Postgres } from 'jnu-db';

const db = new Postgres(dbConfig);
const result = await db.findOne('_metadata.project', {});
console.log(result.data);
```

---

#### 옵션 B를 사용한 경우 (SQL 직접 실행)

**수동으로 프로젝트 정보를 입력해야 합니다:**

```bash
psql -U postgres -d myapp_db
```

```sql
-- 프로젝트 정보 입력 (id는 반드시 1)
INSERT INTO _metadata.project (
    id,
    project_id,
    project_name,
    description,
    root_path,
    tech_stack,
    database_config,
    generation_config
) VALUES (
    1,  -- 반드시 1
    'myapp',
    'My Application',
    'My awesome application project',
    '/workspace/myapp',
    '{
        "backend": "Node.js 20 + TypeScript 5.3 + GraphQL",
        "frontend": "Next.js 15.5.4 + React 19",
        "database": "PostgreSQL 16"
    }'::jsonb,
    '{
        "host": "localhost",
        "port": 5432,
        "database": "myapp_db",
        "ssl": false
    }'::jsonb,
    '{
        "outputDir": "./src/generated",
        "includeComments": true,
        "prettier": true
    }'::jsonb
);

-- 확인
SELECT
    project_id,
    project_name,
    tech_stack->>'backend' as backend,
    tech_stack->>'frontend' as frontend
FROM _metadata.project;
```

**중요:**
- ✅ `id`는 반드시 `1`이어야 함
- ✅ `CONSTRAINT single_project CHECK (id = 1)` 제약조건으로 보호됨
- ❌ 두 번째 레코드 삽입 시도 시 에러 발생 (정상 동작)

---

## 검증 및 테스트

### 1. 테이블 생성 확인

```sql
-- metadb 접속
\c metadb

-- 모든 테이블 목록
\dt

-- 기대 결과:
-- project
-- mappings_table
-- mappings_column
-- mappings_relation
-- mappings_api_endpoint
-- metadata_sync_log
```

### 2. ENUM 타입 확인

```sql
-- ENUM 타입 목록
\dT

-- 기대 결과:
-- relation_type_enum
-- http_method_enum
-- project_status_enum
-- project_template_enum
```

### 3. 인덱스 확인

```sql
-- 특정 테이블의 인덱스 확인
\d mappings_column

-- 또는 SQL로 확인
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename LIKE 'mappings_%'
ORDER BY tablename, indexname;
```

### 4. 샘플 데이터 삽입 테스트

```sql
-- 1. 프로젝트 정보 생성 (id는 반드시 1)
INSERT INTO _metadata.project (
    id, project_id, project_name, description, root_path, tech_stack
) VALUES (
    1,  -- 반드시 1
    'test-project',
    'Test Project',
    'Sample project for testing',
    '/workspace/test',
    '{"backend": "Node.js", "frontend": "React"}'::jsonb
) RETURNING *;

-- 2. 테이블 메타데이터 생성
INSERT INTO _metadata.mappings_table (
    schema_name, table_name, graphql_type, label, description
) VALUES (
    'public', 'users', 'User', '사용자', '테스트 사용자 테이블'
) RETURNING id;

-- 3. 컬럼 메타데이터 생성
INSERT INTO _metadata.mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type,
    graphql_field, graphql_type,
    label, form_type
) VALUES (
    (SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'),
    'public', 'users',
    'email', 'VARCHAR(255)',
    'email', 'String',
    '이메일', 'email'
);

-- 4. 확인
SELECT * FROM _metadata.project;  -- 항상 1개 레코드만
SELECT * FROM _metadata.mappings_table;
SELECT * FROM _metadata.mappings_column;

-- 5. 테스트 데이터 삭제
DELETE FROM _metadata.project WHERE id = 1;
DELETE FROM _metadata.mappings_table WHERE table_name = 'users';
```

### 5. 관계 무결성 테스트

```sql
-- Cascade 삭제 테스트
BEGIN;

-- 테이블 생성
INSERT INTO _metadata.mappings_table (schema_name, table_name, graphql_type, label)
VALUES ('public', 'test_table', 'Test', '테스트') RETURNING id;

-- 컬럼 추가
INSERT INTO _metadata.mappings_column (
    table_id, schema_name, table_name, pg_column, pg_type, graphql_field, graphql_type, label
) VALUES (
    (SELECT id FROM _metadata.mappings_table WHERE table_name = 'test_table'),
    'public', 'test_table', 'name', 'VARCHAR(100)', 'name', 'String', '이름'
);

-- 컬럼이 있는지 확인
SELECT COUNT(*) FROM _metadata.mappings_column WHERE table_name = 'test_table';
-- 예상: 1

-- 테이블 삭제 (CASCADE로 컬럼도 함께 삭제되어야 함)
DELETE FROM _metadata.mappings_table WHERE table_name = 'test_table';

-- 컬럼이 삭제되었는지 확인
SELECT COUNT(*) FROM _metadata.mappings_column WHERE table_name = 'test_table';
-- 예상: 0 (Cascade 성공)

ROLLBACK;
```

---

## 다음 단계

메타데이터 테이블 초기화가 완료되었습니다! 이제 다음 단계로 진행하세요:

### ✅ 완료된 작업
- [x] 메타데이터 DB 생성
- [x] `_metadata` schema 생성 (프로젝트별 격리)
- [x] ENUM 타입 정의
- [x] 프로젝트 정보 테이블 생성 (단일 레코드)
- [x] 핵심 메타데이터 테이블 생성
- [x] 인덱스 및 트리거 설정

### 📌 다음 단계

1. **프로젝트 정보 입력 (필수)**
   ```sql
   INSERT INTO _metadata.project (id, project_id, project_name, ...) VALUES (1, ...);
   ```

2. **[Phase 2: 모델링](./PHASE-2-MODELING.md)**
   - 비즈니스 테이블 메타데이터 정의
   - ERD 작성
   - 관계 정의

3. **메타데이터 편집기 실행** (선택)
   ```bash
   cd /var/services/homes/jungsam/dev/dockers/_manager
   npm run dev
   # http://localhost:20100/metadata-editor
   ```

4. **CLI로 메타데이터 정의** (수동)
   - SQL로 직접 INSERT
   - 또는 메타데이터 편집 스크립트 사용

---

## 부록

### A. 메타데이터 백업

```bash
# _metadata schema만 백업 (권장)
pg_dump -U postgres -d myapp_db --schema=_metadata \
    --file=metadata-backup-$(date +%Y%m%d).sql

# 또는 개별 테이블 백업
pg_dump -U postgres -d myapp_db \
    --table=_metadata.project \
    --table=_metadata.mappings_table \
    --table=_metadata.mappings_column \
    --table=_metadata.mappings_relation \
    --data-only \
    --file=metadata-backup-$(date +%Y%m%d).sql

# 전체 DB 백업 (구조 + 데이터)
pg_dump -U postgres -d myapp_db > myapp_db-full-backup-$(date +%Y%m%d).sql
```

### B. 메타데이터 복원

```bash
# 백업 복원
psql -U postgres -d myapp_db -f metadata-backup-20241019.sql
```

### C. 메타데이터 초기화 (재설정)

```sql
-- ⚠️ 주의: 모든 메타데이터가 삭제됩니다!

-- 테이블 삭제 (역순)
DROP TABLE IF EXISTS _metadata.metadata_sync_log CASCADE;
DROP TABLE IF EXISTS _metadata.mappings_api_endpoint CASCADE;
DROP TABLE IF EXISTS _metadata.mappings_relation CASCADE;
DROP TABLE IF EXISTS _metadata.mappings_column CASCADE;
DROP TABLE IF EXISTS _metadata.mappings_table CASCADE;
DROP TABLE IF EXISTS _metadata.project CASCADE;

-- ENUM 타입 삭제
DROP TYPE IF EXISTS _metadata.project_template_enum CASCADE;
DROP TYPE IF EXISTS _metadata.project_status_enum CASCADE;
DROP TYPE IF EXISTS _metadata.http_method_enum CASCADE;
DROP TYPE IF EXISTS _metadata.relation_type_enum CASCADE;

-- 함수 삭제
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- 확인
\dt
\dT
```

---

## 문의 및 지원

- 메타데이터 테이블 설계 관련: [concepts/META-DRIVEN-DEVELOPMENT-WORKFLOW.md](../concepts/META-DRIVEN-DEVELOPMENT-WORKFLOW.md)
- 개발 가이드라인: [guides/META-DRIVEN-DEVELOPMENT-GUIDELINES.md](../guides/META-DRIVEN-DEVELOPMENT-GUIDELINES.md)
- 코드 생성 템플릿: [guides/CODE-GENERATION-TEMPLATES.md](../guides/CODE-GENERATION-TEMPLATES.md)

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows/`

**버전**: 1.0.0

**작성일**: 2024-10-19
