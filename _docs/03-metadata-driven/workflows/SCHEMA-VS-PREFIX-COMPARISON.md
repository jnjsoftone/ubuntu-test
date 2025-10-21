# Schema 분리 vs Prefix: 실질적 기능 비교

> `__metadata.mappings_table` vs `_meta_mappings_table` - 어떤 차이가 있을까?

## 📊 결론부터

**솔직한 답변**: 대부분의 경우 **기능적 차이는 크지 않습니다**.

차이는 주로 **관리 편의성**과 **확장성**에 있으며, 소규모 프로젝트에서는 `_meta_` prefix가 더 실용적일 수 있습니다.

**최종 선택**: 이 프로젝트에서는 **`_metadata` schema 방식**을 사용합니다.

---

## 🎯 실질적 기능 차이 분석

### 1. ✅ **권한 관리** - 명확한 기능적 이점

#### Schema 분리 방식

```sql
-- 개발자: 비즈니스 데이터만 수정 가능
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO developer;
GRANT SELECT ON ALL TABLES IN SCHEMA _metadata TO developer;  -- 읽기만

-- 관리자: 메타데이터 수정 가능
GRANT ALL ON ALL TABLES IN SCHEMA _metadata TO admin;

-- 🎯 새 테이블 자동 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA _metadata
GRANT SELECT ON TABLES TO developer;
```

**이점:**
- ✅ Schema 단위로 일괄 권한 제어
- ✅ 실수로 메타데이터 테이블 수정하는 것 방지
- ✅ 새 테이블 추가 시 권한 자동 적용

#### Prefix 방식

```sql
-- 테이블 하나하나 권한 설정 필요
GRANT SELECT ON _meta_mappings_table TO developer;
GRANT SELECT ON _meta_mappings_column TO developer;
GRANT SELECT ON _meta_mappings_relation TO developer;
-- ... (모든 메타데이터 테이블마다 반복)

-- 비즈니스 테이블도 하나씩
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO developer;
GRANT SELECT, INSERT, UPDATE, DELETE ON products TO developer;
-- ...
```

**단점:**
- ⚠️ 각 테이블마다 개별 권한 설정
- ⚠️ 패턴 매칭 어려움 (`GRANT ... ON _meta_*` 불가능)

**결론**: Schema 분리가 **권한 관리에서 명확히 우수**합니다.

---

### 2. ✅ **백업/복원** - 실질적 이점

#### Schema 분리 방식

```bash
# 메타데이터만 백업
pg_dump -U postgres -d myapp_db --schema=_metadata > metadata-backup.sql

# 비즈니스 데이터만 백업
pg_dump -U postgres -d myapp_db --schema=public > business-backup.sql

# 메타데이터만 복원 (비즈니스 데이터는 그대로)
psql -U postgres -d myapp_db < metadata-backup.sql
```

**시나리오 예시:**
- 프로덕션 → 개발 환경 복사 시 메타데이터만 복사
- 메타데이터 롤백 (비즈니스 데이터는 유지)
- 테스트 환경에서 메타데이터만 업데이트

#### Prefix 방식

```bash
# 특정 테이블들만 백업 (패턴 매칭 불가)
pg_dump -U postgres -d myapp_db \
  -t _meta_mappings_table \
  -t _meta_mappings_column \
  -t _meta_mappings_relation \
  -t _meta_projects \
  -t _meta_project_tables \
  > metadata-backup.sql
```

**단점:**
- ⚠️ 모든 메타데이터 테이블을 `-t` 옵션으로 나열해야 함
- ⚠️ 새 메타데이터 테이블 추가 시 백업 스크립트 수정 필요
- ⚠️ 실수로 일부 테이블 누락 가능

**결론**: Schema 분리가 **백업/복원에서 편리**합니다.

---

### 3. ✅ **이름 충돌 방지** - 특정 상황에서 중요

#### 시나리오: `projects` 테이블이 두 곳에 필요한 경우

**문제 상황:**
```sql
-- 메타데이터: 여러 프로젝트 관리
CREATE TABLE projects (
    id BIGSERIAL PRIMARY KEY,
    project_id VARCHAR(100),
    project_name VARCHAR(200),
    ...
);

-- 비즈니스 데이터: 고객이 진행하는 프로젝트 (예: PM 도구)
CREATE TABLE projects (  -- ❌ 충돌!
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT,
    project_title VARCHAR(200),
    deadline DATE,
    ...
);
```

#### Schema 분리 방식

```sql
-- 메타데이터 프로젝트
CREATE TABLE _metadata.projects ( ... );

-- 비즈니스 프로젝트
CREATE TABLE public.customer_projects ( ... );

-- 쿼리
SELECT * FROM _metadata.projects WHERE project_id = 'myapp';
SELECT * FROM public.customer_projects WHERE customer_id = 123;
```

**이점:**
- ✅ 완벽한 네임스페이스 격리
- ✅ 같은 이름 사용 가능

#### Prefix 방식

```sql
-- 메타데이터 프로젝트
CREATE TABLE _meta_projects ( ... );

-- 비즈니스 프로젝트
CREATE TABLE projects ( ... );  -- OK

-- 또는
CREATE TABLE customer_projects ( ... );  -- 이름 변경 필요
```

**단점:**
- ⚠️ 한쪽은 이름 변경 필요
- ⚠️ 의미론적으로 부자연스러울 수 있음

**결론**: 이름 충돌이 예상되면 Schema 분리가 **확실히 유리**합니다.

---

### 4. ⚠️ **검색/필터링** - 약간의 편의성

#### Schema 분리 방식

```sql
-- psql에서 메타데이터 테이블만 조회
\dt metadata.*

-- SQL로 메타데이터 테이블만 조회
SELECT tablename
FROM pg_tables
WHERE schemaname = 'metadata';

-- 애플리케이션에서 비즈니스 테이블만 조회
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT LIKE 'sql_%';
```

**이점:**
- ✅ Schema로 명확히 필터링
- ✅ 관리 도구에서 그룹화 지원

#### Prefix 방식

```sql
-- 메타데이터 테이블 조회
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE '_meta_%';

-- 비즈니스 테이블만 조회
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT LIKE '_meta_%'
  AND tablename NOT LIKE 'pg_%';
```

**단점:**
- ⚠️ 패턴 매칭 필요
- ⚠️ 실수로 `_meta2_` 같은 prefix 사용하면 누락

**결론**: 약간의 차이만 있습니다.

---

### 5. ❌ **성능** - 차이 없음

**Schema 분리든 Prefix든 성능 차이는 거의 없습니다.**

```sql
-- 둘 다 동일한 성능
SELECT * FROM _metadata.mappings_table WHERE table_name = 'users';
SELECT * FROM _meta_mappings_table WHERE table_name = 'users';
```

PostgreSQL 내부적으로는 둘 다 동일하게 처리됩니다.

---

### 6. ❌ **코드 생성 로직** - 차이 없음

코드 생성기에서는 둘 다 동일하게 처리 가능:

```typescript
// Schema 분리
const metadataTable = '_metadata.mappings_table';
const query = `SELECT * FROM ${metadataTable}`;

// Prefix
const metadataTable = '_meta_mappings_table';
const query = `SELECT * FROM ${metadataTable}`;
```

**결론**: 애플리케이션 로직에서는 **차이 없음**.

---

## 📋 종합 비교표

| 기능 | Schema 분리 | Prefix | 차이 정도 |
|------|-------------|--------|-----------|
| **권한 관리** | ⭐⭐⭐⭐⭐ Schema 단위 제어 | ⭐⭐ 테이블별 개별 설정 | 🔴 큰 차이 |
| **백업/복원** | ⭐⭐⭐⭐⭐ `--schema` 옵션 | ⭐⭐⭐ 테이블 나열 필요 | 🟡 중간 차이 |
| **이름 충돌** | ⭐⭐⭐⭐⭐ 완벽한 격리 | ⭐⭐⭐ Prefix 변경 필요 | 🟡 상황에 따라 |
| **검색/필터** | ⭐⭐⭐⭐ Schema 필터 | ⭐⭐⭐ 패턴 매칭 | 🟢 작은 차이 |
| **성능** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🟢 차이 없음 |
| **코드 복잡도** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🟢 차이 없음 |
| **학습 곡선** | ⭐⭐⭐ Schema 개념 필요 | ⭐⭐⭐⭐⭐ 즉시 이해 | 🟡 Schema가 약간 복잡 |
| **호환성** | ⭐⭐⭐⭐⭐ 모든 도구 지원 | ⭐⭐⭐⭐ 일부 도구에서 숨김 | 🟢 작은 차이 |

---

## 🎯 상황별 권장사항

### Schema 분리를 선택해야 하는 경우

1. **다중 사용자/역할 관리**
   ```sql
   -- 개발자, 관리자, 시스템 계정 등 역할이 명확히 분리된 경우
   GRANT USAGE ON SCHEMA metadata TO admin_role;
   GRANT SELECT ON ALL TABLES IN SCHEMA _metadata TO developer_role;
   ```

2. **여러 환경 간 메타데이터 동기화**
   ```bash
   # Dev → Staging → Production 순서로 메타데이터만 이동
   pg_dump -h dev-db --schema=_metadata | psql -h staging-db
   ```

3. **이름 충돌 가능성**
   ```sql
   -- projects, users, settings 같은 일반적인 이름을
   -- 메타데이터와 비즈니스 데이터 양쪽에서 사용해야 할 때
   _metadata.projects vs public.customer_projects
   ```

4. **프로젝트 규모가 크고 장기 운영 예정**
   - 테이블 50개 이상
   - 운영 기간 3년 이상
   - 팀 규모 5명 이상

### Prefix를 선택해야 하는 경우

1. **소규모 프로젝트**
   - 테이블 20개 미만
   - 개발자 1-3명
   - 빠른 프로토타이핑

2. **단순함 우선**
   ```sql
   -- Schema 개념 학습 불필요
   SELECT * FROM _meta_mappings_table;  -- 직관적
   ```

3. **기존 프로젝트에 추가**
   ```sql
   -- 이미 public schema만 사용 중인 프로젝트에
   -- 메타데이터 시스템을 나중에 추가하는 경우
   ```

4. **모든 것을 한 곳에서 관리**
   ```bash
   # 하나의 schema에 모든 테이블
   \dt
   # _meta_로 시작하는 것들만 메타데이터로 인식
   ```

---

## 💡 실용적 조언

### 프로젝트 시작 단계라면?

**Schema 분리를 권장합니다.** 이유:
- 초기에는 추가 복잡도가 거의 없음
- 나중에 Prefix → Schema 마이그레이션은 번거로움
- 확장성 확보

### 이미 운영 중인 프로젝트라면?

**Prefix 사용을 권장합니다.** 이유:
- 마이그레이션 비용 최소화
- 기존 코드 변경 최소화
- 실질적 기능 차이는 크지 않음

---

## 🔄 마이그레이션 가이드

### Prefix → Schema 마이그레이션

나중에 필요하면 마이그레이션 가능:

```sql
-- 1. 스키마 생성
CREATE SCHEMA metadata;

-- 2. 테이블 이동
ALTER TABLE _meta_mappings_table SET SCHEMA metadata;
ALTER TABLE _meta_mappings_column SET SCHEMA metadata;
ALTER TABLE _meta_mappings_relation SET SCHEMA metadata;

-- 3. 이름 변경 (prefix 제거)
ALTER TABLE metadata._meta_mappings_table RENAME TO mappings_table;
ALTER TABLE metadata._meta_mappings_column RENAME TO mappings_column;
ALTER TABLE metadata._meta_mappings_relation RENAME TO mappings_relation;

-- 4. FK 자동 업데이트됨 (PostgreSQL이 처리)
```

**주의**: 애플리케이션 코드도 업데이트 필요
```typescript
// Before
const table = '_meta_mappings_table';

// After
const table = '_metadata.mappings_table';
```

---

## 🎬 최종 결론

### 기능적 이점 요약

| 항목 | 실질적 이점 | 중요도 |
|------|------------|--------|
| 권한 관리 | ✅ **명확한 이점** | ⭐⭐⭐⭐⭐ (Multi-user 환경) |
| 백업/복원 | ✅ **실용적 이점** | ⭐⭐⭐⭐ (운영 환경) |
| 이름 충돌 | ✅ **상황에 따라** | ⭐⭐⭐ (충돌 시에만) |
| 검색/필터 | ⚠️ 약간의 편의성 | ⭐⭐ |
| 성능 | ❌ 차이 없음 | - |
| 코드 로직 | ❌ 차이 없음 | - |

### 선택 가이드

**Schema 분리 선택:**
- ✅ 다중 사용자 환경
- ✅ 운영/스테이징/개발 환경 분리
- ✅ 엔터프라이즈급 프로젝트
- ✅ 장기 운영 예정

**Prefix 선택:**
- ✅ 소규모 프로젝트
- ✅ 빠른 개발 필요
- ✅ 단순함 우선
- ✅ 기존 프로젝트 추가

### 추천

**새 프로젝트**: Schema 분리 (`_metadata.mappings_table`)
**기존 프로젝트**: Prefix (`_meta_mappings_table`)

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows/`

**버전**: 1.0.0
