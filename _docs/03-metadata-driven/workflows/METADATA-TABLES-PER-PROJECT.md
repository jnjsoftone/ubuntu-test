# 프로젝트별 _metadata 방식의 테이블 구조

> 프로젝트별 _metadata를 사용할 때 필요한 테이블과 불필요한 테이블

## 🎯 핵심 답변

**프로젝트별 _metadata 방식에서:**

- ❌ `_metadata.project_tables` → **완전히 불필요**
- ⚠️ `_metadata.projects` → **변경 필요** (복수형 → 단수형)

---

## 📊 테이블 구조 비교

### 중앙 metadb 방식 (옵션 B)

```sql
-- metadb
CREATE TABLE _metadata.projects (          -- 여러 프로젝트 관리
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) UNIQUE,
    project_name VARCHAR(200),
    -- ...
);

CREATE TABLE _metadata.mappings_table (    -- 모든 프로젝트의 테이블
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    -- ...
);

CREATE TABLE _metadata.project_tables (    -- 프로젝트-테이블 매핑 (필수!)
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES projects(id),
    table_id BIGINT REFERENCES mappings_table(id),
    -- 어느 프로젝트가 어느 테이블을 사용하는가?
);
```

**왜 필요한가?**
```sql
-- Q: project1이 어떤 테이블을 사용하나?
SELECT mt.*
FROM _metadata.mappings_table mt
JOIN _metadata.project_tables pt ON pt.table_id = mt.id
WHERE pt.project_id = (SELECT id FROM _metadata.projects WHERE project_id = 'project1');

-- ✅ project_tables가 매핑 역할
```

---

### 프로젝트별 _metadata 방식 (옵션 A)

```sql
-- project1_db._metadata
CREATE TABLE _metadata.project (           -- 단일 프로젝트 정보 (선택적)
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) UNIQUE,        -- 'project1'
    project_name VARCHAR(200),             -- 'My First Project'
    -- 이 DB의 프로젝트 정보만 저장
);

CREATE TABLE _metadata.mappings_table (    -- 이 프로젝트의 테이블만
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    -- 이 DB에 있는 테이블 = 자동으로 이 프로젝트의 테이블
);

-- ❌ project_tables 테이블 불필요!
-- 이유: mappings_table에 있는 모든 테이블이 자동으로 이 프로젝트의 테이블
```

**왜 불필요한가?**
```sql
-- Q: project1이 어떤 테이블을 사용하나?
SELECT * FROM _metadata.mappings_table;

-- ✅ 이 DB의 mappings_table = 전부 project1의 테이블
-- ✅ 매핑 테이블 불필요!
```

---

## 📋 상세 분석

### 1. _metadata.project_tables - **완전히 불필요**

#### 중앙 metadb에서의 역할

```sql
-- metadb에 모든 프로젝트 테이블이 섞여있음
mappings_table:
  id | table_name | ...
  1  | users      | ...  ← project1, project2, project3 모두 사용 가능
  2  | products   | ...  ← project1만 사용
  3  | orders     | ...  ← project2만 사용

-- 따라서 매핑 필요
project_tables:
  project_id | table_id
  project1   | 1        ← project1은 users 사용
  project1   | 2        ← project1은 products 사용
  project2   | 1        ← project2는 users 사용
  project2   | 3        ← project2는 orders 사용
```

#### 프로젝트별 _metadata에서는?

```sql
-- project1_db._metadata.mappings_table
id | table_name | ...
1  | users      | ...  ← 자동으로 project1의 테이블
2  | products   | ...  ← 자동으로 project1의 테이블

-- project2_db._metadata.mappings_table
id | table_name | ...
1  | users      | ...  ← 자동으로 project2의 테이블
2  | orders     | ...  ← 자동으로 project2의 테이블

-- ✅ DB가 분리되어 있어서 매핑 불필요!
```

**결론**: `project_tables` 테이블은 **완전히 삭제**

---

### 2. _metadata.projects - **변경 필요**

#### 중앙 metadb에서의 역할

```sql
-- 여러 프로젝트 관리
CREATE TABLE _metadata.projects (
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) UNIQUE,
    project_name VARCHAR(200),
    -- ...
);

INSERT INTO projects VALUES (1, 'project1', 'My First Project');
INSERT INTO projects VALUES (2, 'project2', 'My Second Project');
INSERT INTO projects VALUES (3, 'project3', 'My Third Project');
```

#### 프로젝트별 _metadata에서는?

**옵션 2-A: 단수형 project 테이블로 변경 (권장)**

```sql
-- 이 DB의 프로젝트 정보만 저장
CREATE TABLE _metadata.project (           -- 단수형!
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) NOT NULL,      -- 'project1'
    project_name VARCHAR(200) NOT NULL,    -- 'My First Project'
    description TEXT,

    -- 프로젝트 설정
    tech_stack JSONB,
    generation_config JSONB,

    -- 메타정보
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 단일 프로젝트이므로 1개 레코드만
    CONSTRAINT single_project CHECK (id = 1)
);

-- 사용
INSERT INTO _metadata.project (id, project_id, project_name)
VALUES (1, 'project1', 'My First Project');

-- 조회
SELECT * FROM _metadata.project;  -- 항상 1개 레코드
```

**옵션 2-B: 완전히 삭제하고 설정 파일 사용**

```typescript
// config/project.ts
export const PROJECT_CONFIG = {
  projectId: 'project1',
  projectName: 'My First Project',
  description: '...',
  techStack: {
    backend: 'Node.js + TypeScript',
    frontend: 'Next.js',
  },
  generationConfig: {
    outputDir: './src/generated',
  }
};
```

**권장**: 옵션 2-A (DB에 저장)
- 이유: 코드 생성기가 DB만 접속해도 모든 정보 조회 가능

---

## ✅ 최종 테이블 구조 (프로젝트별 _metadata)

### 필수 테이블

```sql
-- 1. 프로젝트 정보 (단수형, 단일 레코드)
CREATE TABLE _metadata.project (
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,
    tech_stack JSONB,
    generation_config JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT single_project CHECK (id = 1)
);

-- 2. 테이블 메타데이터
CREATE TABLE _metadata.mappings_table (
    id BIGSERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL DEFAULT 'public',
    table_name VARCHAR(100) NOT NULL,
    graphql_type VARCHAR(100),
    label VARCHAR(200) NOT NULL,
    description TEXT,
    -- ...
    UNIQUE(schema_name, table_name)
);

-- 3. 컬럼 메타데이터
CREATE TABLE _metadata.mappings_column (
    id BIGSERIAL PRIMARY KEY,
    table_id BIGINT REFERENCES _metadata.mappings_table(id) ON DELETE CASCADE,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    pg_column VARCHAR(100) NOT NULL,
    pg_type VARCHAR(100),
    graphql_field VARCHAR(100),
    graphql_type VARCHAR(50),
    label VARCHAR(200) NOT NULL,
    -- ...
    UNIQUE(schema_name, table_name, pg_column)
);

-- 4. 관계 메타데이터
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
    -- ...
);
```

### 선택적 테이블

```sql
-- 5. 외부 API 엔드포인트 (필요시)
CREATE TABLE _metadata.mappings_api_endpoint (
    id BIGSERIAL PRIMARY KEY,
    endpoint_name VARCHAR(100) NOT NULL UNIQUE,
    base_url VARCHAR(500) NOT NULL,
    method _metadata.http_method_enum DEFAULT 'GET',
    -- ...
);

-- 6. 메타데이터 변경 이력 (필요시)
CREATE TABLE _metadata.metadata_sync_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL,
    record_id BIGINT,
    old_data JSONB,
    new_data JSONB,
    -- ...
);
```

### ❌ 불필요한 테이블

```sql
-- ❌ 삭제: project_tables (매핑 불필요)
-- DROP TABLE IF EXISTS _metadata.project_tables;

-- ❌ 삭제: projects (복수형)
-- DROP TABLE IF EXISTS _metadata.projects;
```

---

## 🔧 초기화 스크립트 업데이트

### 기존 (중앙 metadb용)

```sql
-- ❌ 중앙 metadb 방식
CREATE TABLE _metadata.projects ( ... );          -- 복수형
CREATE TABLE _metadata.project_tables ( ... );    -- 매핑 테이블
CREATE TABLE _metadata.mappings_table ( ... );
```

### 업데이트 (프로젝트별 _metadata용)

```sql
-- ✅ 프로젝트별 _metadata 방식
CREATE TABLE _metadata.project (              -- 단수형, 단일 레코드
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100) NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,
    tech_stack JSONB,
    generation_config JSONB,
    database_config JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT single_project CHECK (id = 1)
);

-- ❌ project_tables 제거

CREATE TABLE _metadata.mappings_table ( ... );
CREATE TABLE _metadata.mappings_column ( ... );
CREATE TABLE _metadata.mappings_relation ( ... );
```

---

## 💡 사용 예시

### 프로젝트 생성 시

```bash
#!/bin/bash
# create-project.sh

PROJECT_ID=$1
PROJECT_NAME=$2

# 1. DB 생성
createdb ${PROJECT_ID}_db

# 2. _metadata schema 생성
psql -d ${PROJECT_ID}_db <<EOF
CREATE SCHEMA _metadata;

-- 3. 메타데이터 테이블 생성
\i metadata-tables-init.sql

-- 4. 프로젝트 정보 입력 (단일 레코드)
INSERT INTO _metadata.project (id, project_id, project_name, tech_stack)
VALUES (
    1,
    '${PROJECT_ID}',
    '${PROJECT_NAME}',
    '{"backend": "Node.js + TypeScript", "frontend": "Next.js"}'::jsonb
);
EOF

echo "✅ ${PROJECT_NAME} 프로젝트 생성 완료!"
```

### 코드 생성기에서 사용

```typescript
// generators/code-generator.ts
import { Pool } from 'pg';

async function generateCode(projectId: string) {
  const db = new Pool({ database: `${projectId}_db` });

  // 1. 프로젝트 정보 조회
  const { rows: [project] } = await db.query(`
    SELECT * FROM _metadata.project
  `);

  console.log(`Generating code for: ${project.project_name}`);

  // 2. 테이블 메타데이터 조회 (project_tables 매핑 불필요!)
  const { rows: tables } = await db.query(`
    SELECT * FROM _metadata.mappings_table
  `);

  // ✅ 이 DB의 모든 테이블 = 자동으로 이 프로젝트의 테이블

  // 3. 각 테이블의 컬럼 조회
  for (const table of tables) {
    const { rows: columns } = await db.query(`
      SELECT * FROM _metadata.mappings_column
      WHERE table_id = $1
      ORDER BY sort_order
    `, [table.id]);

    // 코드 생성...
  }

  await db.end();
}
```

---

## 📊 비교표

| 테이블 | 중앙 metadb | 프로젝트별 _metadata | 변경 사항 |
|--------|------------|---------------------|----------|
| `projects` | ✅ 필수 (복수형) | ⚠️ 변경 (단수형 `project`) | 단일 레코드 |
| `project_tables` | ✅ 필수 | ❌ 삭제 | 매핑 불필요 |
| `mappings_table` | ✅ 필수 | ✅ 필수 | 동일 |
| `mappings_column` | ✅ 필수 | ✅ 필수 | 동일 |
| `mappings_relation` | ✅ 필수 | ✅ 필수 | 동일 |
| `mappings_api_endpoint` | 선택 | 선택 | 동일 |
| `metadata_sync_log` | 선택 | 선택 | 동일 |

---

## ✅ 체크리스트

### PHASE-1 문서 업데이트 필요

- [ ] `_metadata.projects` → `_metadata.project`로 변경
- [ ] 단수형 테이블 설명 추가
- [ ] `CONSTRAINT single_project CHECK (id = 1)` 추가
- [ ] `_metadata.project_tables` 테이블 완전히 제거
- [ ] FK 참조 업데이트 (project_tables 제거)

### 초기화 스크립트 업데이트

- [ ] `CREATE TABLE _metadata.project` (단수형)
- [ ] `CREATE TABLE _metadata.project_tables` 제거
- [ ] 프로젝트 정보 INSERT 예시 추가

### 코드 생성기 업데이트

- [ ] `projects` → `project` 참조 변경
- [ ] `project_tables` JOIN 제거
- [ ] 단순화된 쿼리 사용

---

## 🎯 결론

**프로젝트별 _metadata 방식에서:**

1. **`_metadata.project_tables`** → ❌ **완전히 불필요, 삭제**
   - 이유: DB 분리로 매핑 자동

2. **`_metadata.projects`** → ⚠️ **`_metadata.project`로 변경**
   - 복수형 → 단수형
   - 여러 레코드 → 단일 레코드 (CONSTRAINT 추가)
   - 프로젝트 설정 저장용

3. **나머지 테이블** → ✅ **그대로 사용**
   - mappings_table
   - mappings_column
   - mappings_relation
   - mappings_api_endpoint (선택)
   - metadata_sync_log (선택)

---

**다음 단계**: PHASE-1 문서를 업데이트하여 프로젝트별 _metadata 방식을 반영하시겠습니까?

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows/`

**버전**: 1.0.0
