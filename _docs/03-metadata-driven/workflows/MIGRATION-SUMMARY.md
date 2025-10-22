# 메타데이터 테이블 명명 변경 요약

> 모든 메타데이터 테이블을 `_metadata` schema로 변경 완료

## 📊 변경 사항

### 이전 (변경 전)

```sql
-- 메타데이터 전용 DB 사용
CREATE DATABASE metadb;

-- public schema에 테이블 생성
CREATE TABLE mappings_table ( ... );
CREATE TABLE mappings_column ( ... );
CREATE TABLE mappings_relation ( ... );
CREATE TABLE projects ( ... );
```

### 이후 (변경 후)

```sql
-- 프로젝트 DB에 _metadata schema 생성
CREATE DATABASE myapp_db;
CREATE SCHEMA _metadata;

-- _metadata schema에 테이블 생성
CREATE TABLE _metadata.mappings_table ( ... );
CREATE TABLE _metadata.mappings_column ( ... );
CREATE TABLE _metadata.mappings_relation ( ... );
CREATE TABLE _metadata.projects ( ... );
```

---

## 🎯 주요 변경 내용

### 1. Schema 구조

**이전:**
```
metadb (별도 DB)
└── public
    ├── mappings_table
    ├── mappings_column
    ├── mappings_relation
    └── projects
```

**이후:**
```
myapp_db (프로젝트 DB)
├── _metadata (메타데이터 schema)
│   ├── mappings_table
│   ├── mappings_column
│   ├── mappings_relation
│   ├── projects
│   └── project_tables
│
└── public (비즈니스 데이터 schema)
    ├── users
    ├── products
    └── orders
```

### 2. 테이블 전체 이름

| 이전 | 이후 |
|------|------|
| `mappings_table` | `_metadata.mappings_table` |
| `mappings_column` | `_metadata.mappings_column` |
| `mappings_relation` | `_metadata.mappings_relation` |
| `mappings_api_endpoint` | `_metadata.mappings_api_endpoint` |
| `projects` | `_metadata.projects` |
| `project_tables` | `_metadata.project_tables` |
| `metadata_sync_log` | `_metadata.metadata_sync_log` |

### 3. ENUM 타입

| 이전 | 이후 |
|------|------|
| `relation_type_enum` | `_metadata.relation_type_enum` |
| `http_method_enum` | `_metadata.http_method_enum` |
| `project_status_enum` | `_metadata.project_status_enum` |
| `project_template_enum` | `_metadata.project_template_enum` |

---

## 📝 변경된 파일 목록

### workflows 디렉토리

1. ✅ **PHASE-1-METADATA-TABLES-SETUP.md**
   - 모든 CREATE TABLE 문
   - 모든 SELECT/INSERT/DELETE 문
   - 모든 인덱스 및 트리거 정의
   - DB 초기화 섹션 (두 가지 옵션 제공)

2. ✅ **PHASE-2-MODELING.md**
   - SQL 예제 코드
   - INSERT 문
   - SELECT 문

3. ✅ **PHASE-3-BACKEND.md**
   - 메타데이터 조회 쿼리

4. ✅ **CLAUDE-CODE-FULL-GUIDE.md**
   - 모든 SQL 예제

5. ✅ **SCHEMA-VS-PREFIX-COMPARISON.md**
   - `metadata` → `_metadata`로 업데이트
   - 최종 선택 명시

6. ✅ **README.md**
   - 테이블 목록 업데이트

### concepts 디렉토리

7. ✅ **META-DRIVEN-DEVELOPMENT-WORKFLOW.md**
   - 모든 CREATE TABLE 문
   - SQL 예제

### guides 디렉토리

8. ✅ **guides/README.md**
   - 참조 업데이트 (간접적)

### backend nodejs 디렉토리

9. ✅ **src/custom/README.md**
   - 테이블명 참조 업데이트

10. ✅ **src/generated/README.md**
    - 테이블명 참조 업데이트

### 메인 디렉토리

11. ✅ **README.md**
    - Phase 0 설명 업데이트

---

## 🔧 사용 방법

### 기본 사용법

```sql
-- Schema 생성
CREATE SCHEMA _metadata;

-- 테이블 생성
CREATE TABLE _metadata.mappings_table ( ... );

-- 조회
SELECT * FROM _metadata.mappings_table WHERE table_name = 'users';

-- 삽입
INSERT INTO _metadata.mappings_table (schema_name, table_name, ...)
VALUES ('public', 'users', ...);
```

### Search Path 설정 (선택사항)

Schema명을 생략하고 싶다면:

```sql
-- DB 레벨 설정
ALTER DATABASE myapp_db SET search_path TO public, _metadata;

-- 세션 레벨 설정
SET search_path TO public, _metadata;

-- 이후 schema명 생략 가능
SELECT * FROM mappings_table WHERE table_name = 'users';
```

### 애플리케이션 코드

```typescript
// TypeScript 예시
import { Pool } from 'pg';

const pool = new Pool({
  host: 'localhost',
  database: 'myapp_db',
  // search_path 설정
  options: '-c search_path=public,_metadata'
});

// 명시적 schema 사용
const tables = await pool.query(`
  SELECT * FROM _metadata.mappings_table
  WHERE schema_name = 'public'
`);

// 또는 search_path 설정 후 schema 생략
const tables = await pool.query(`
  SELECT * FROM mappings_table
  WHERE schema_name = 'public'
`);
```

---

## ✅ 장점

### 1. 명확한 구분
- `_metadata` schema로 메타데이터임을 명시
- 알파벳 정렬 시 맨 위에 표시
- 비즈니스 테이블과 물리적 분리

### 2. 권한 관리
```sql
-- Schema 단위로 권한 제어
GRANT ALL ON SCHEMA _metadata TO admin;
GRANT SELECT ON ALL TABLES IN SCHEMA _metadata TO developer;
```

### 3. 백업/복원
```bash
# 메타데이터만 백업
pg_dump -d myapp_db --schema=_metadata > metadata-backup.sql

# 비즈니스 데이터만 백업
pg_dump -d myapp_db --schema=public > business-backup.sql
```

### 4. 이름 충돌 방지
```sql
-- 같은 이름 사용 가능
_metadata.projects  -- 메타데이터: 프로젝트 관리
public.projects     -- 비즈니스: 고객 프로젝트
```

### 5. 테이블명 깔끔
```sql
-- Prefix 방식보다 간결
_metadata.mappings_table    (O) 깔끔
_meta_mappings_table        (X) 중복 느낌
```

---

## 📋 체크리스트

개발자가 확인해야 할 사항:

### 새 프로젝트 시작 시

- [ ] 프로젝트 DB 생성 (또는 기존 DB 사용)
- [ ] `CREATE SCHEMA _metadata;` 실행
- [ ] PHASE-1 문서의 초기화 스크립트 실행
- [ ] 테이블 생성 확인: `\dt _metadata.*`
- [ ] Search Path 설정 (선택)

### 기존 코드 마이그레이션 시

- [ ] 모든 `mappings_table` → `_metadata.mappings_table` 변경
- [ ] 모든 `projects` → `_metadata.projects` 변경
- [ ] FK 참조 업데이트
- [ ] 애플리케이션 코드의 쿼리 업데이트
- [ ] 테스트 실행 및 검증

### 검증

```sql
-- Schema 확인
\dn

-- 테이블 확인
\dt _metadata.*

-- ENUM 타입 확인
\dT _metadata.*

-- 샘플 쿼리 테스트
SELECT * FROM _metadata.mappings_table LIMIT 1;
```

---

## 🚀 다음 단계

1. **PHASE-1-METADATA-TABLES-SETUP.md** 읽기
   - `_metadata` schema 생성
   - 모든 메타데이터 테이블 생성

2. **PHASE-2-MODELING.md** 진행
   - 프로젝트 등록
   - 비즈니스 테이블 메타데이터 정의

3. **코드 생성** 시작
   - 메타데이터 기반 DB DDL 생성
   - GraphQL 스키마 생성
   - React 컴포넌트 생성

---

## 📞 문의

문제가 발생하거나 질문이 있으시면:

1. **SCHEMA-VS-PREFIX-COMPARISON.md** 참조
   - Schema 방식 vs Prefix 방식 상세 비교
   - 실질적 기능 차이 분석

2. **PHASE-1-METADATA-TABLES-SETUP.md** 참조
   - 초기화 스크립트
   - 검증 및 테스트 방법

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows/`

**변경일**: 2024-10-19

**버전**: 1.0.0
