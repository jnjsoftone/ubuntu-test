# 메타데이터 저장소 아키텍처 비교

> 프로젝트별 _metadata vs 중앙 metadb - 어떤 방식을 선택할까?

## 📋 상황

- **환경**: 1개의 PostgreSQL 서버 (Ubuntu Docker 플랫폼)
- **프로젝트**: 여러 개의 독립적인 프로젝트
- **DB 구조**: 각 프로젝트는 별도의 DB 사용 (예: project1_db, project2_db, ...)

## 🎯 두 가지 옵션

### 옵션 A: 프로젝트별 _metadata (분산형)

```
PostgreSQL 서버
├── project1_db
│   ├── _metadata schema (project1 메타데이터)
│   │   ├── mappings_table
│   │   └── mappings_column
│   └── public schema (project1 비즈니스 데이터)
│       ├── users
│       └── products
│
├── project2_db
│   ├── _metadata schema (project2 메타데이터)
│   │   ├── mappings_table
│   │   └── mappings_column
│   └── public schema (project2 비즈니스 데이터)
│       ├── orders
│       └── payments
│
└── project3_db
    ├── _metadata schema (project3 메타데이터)
    └── public schema (project3 비즈니스 데이터)
```

### 옵션 B: 중앙 metadb (중앙집중형)

```
PostgreSQL 서버
├── metadb (모든 프로젝트의 메타데이터)
│   └── _metadata schema
│       ├── mappings_table (모든 프로젝트)
│       ├── mappings_column (모든 프로젝트)
│       ├── projects (프로젝트 목록)
│       └── project_tables (프로젝트별 테이블 매핑)
│
├── project1_db
│   └── public schema (비즈니스 데이터만)
│       ├── users
│       └── products
│
├── project2_db
│   └── public schema (비즈니스 데이터만)
│       ├── orders
│       └── payments
│
└── project3_db
    └── public schema (비즈니스 데이터만)
```

---

## 📊 상세 비교

### 1. ✅ **독립성 (Isolation)**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐⭐⭐⭐

**장점:**
- ✅ 완벽한 프로젝트 독립성
- ✅ 프로젝트별 백업/복원 용이
- ✅ 프로젝트 삭제 시 메타데이터도 함께 삭제 (Clean)
- ✅ 프로젝트 이전/복사 용이 (DB 전체 덤프)

**시나리오:**
```bash
# 프로젝트 전체 백업 (메타데이터 + 비즈니스 데이터)
pg_dump project1_db > project1_full_backup.sql

# 다른 서버로 이전
psql -h new-server -d project1_db < project1_full_backup.sql

# ✅ 메타데이터도 자동으로 포함됨!
```

#### 옵션 B: 중앙 metadb ⭐⭐

**단점:**
- ⚠️ 프로젝트 간 메타데이터가 metadb에 섞임
- ⚠️ 프로젝트 이전 시 metadb에서 해당 프로젝트 메타데이터 추출 필요
- ⚠️ 프로젝트 삭제 시 metadb 정리 필요

**시나리오:**
```bash
# 프로젝트 백업 시 두 단계 필요
# 1. 비즈니스 데이터
pg_dump project1_db > project1_business.sql

# 2. 메타데이터 (프로젝트별 필터링 필요)
pg_dump metadb -t _metadata.mappings_table \
  --where="table_id IN (SELECT id FROM _metadata.project_tables WHERE project_id = 'project1')" \
  > project1_metadata.sql

# ⚠️ 복잡하고 실수 가능성
```

---

### 2. ✅ **크로스 프로젝트 조회**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐

**단점:**
- ⚠️ 여러 프로젝트의 메타데이터를 한 번에 조회하기 어려움
- ⚠️ 프로젝트 간 메타데이터 비교/분석 복잡

**시나리오:**
```sql
-- ❌ 불가능: 모든 프로젝트에서 'users' 테이블 찾기
-- DB가 달라서 한 쿼리로 불가능
```

#### 옵션 B: 중앙 metadb ⭐⭐⭐⭐⭐

**장점:**
- ✅ 모든 프로젝트의 메타데이터를 한 쿼리로 조회
- ✅ 프로젝트 간 메타데이터 비교 용이
- ✅ 전체 통계/분석 쉬움

**시나리오:**
```sql
-- ✅ 가능: 모든 프로젝트에서 'email' 컬럼 사용하는 테이블 찾기
SELECT
    p.project_name,
    mt.table_name,
    mc.pg_column,
    mc.validation_rules
FROM _metadata.mappings_column mc
JOIN _metadata.mappings_table mt ON mc.table_id = mt.id
JOIN _metadata.project_tables pt ON pt.table_id = mt.id
JOIN _metadata.projects p ON pt.project_id = p.id
WHERE mc.pg_column = 'email';

-- ✅ 결과: 전체 플랫폼에서 email 컬럼 현황 파악
```

---

### 3. ✅ **메타데이터 공유/재사용**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐

**단점:**
- ⚠️ 공통 테이블 정의를 각 프로젝트마다 복사 필요
- ⚠️ 공통 테이블 변경 시 모든 프로젝트 수동 업데이트

**시나리오:**
```sql
-- ❌ 비효율: users 테이블 정의를 3개 프로젝트에서 사용
-- → 각 프로젝트 DB에 동일한 메타데이터 3번 입력
INSERT INTO project1_db._metadata.mappings_table (...); -- 중복
INSERT INTO project2_db._metadata.mappings_table (...); -- 중복
INSERT INTO project3_db._metadata.mappings_table (...); -- 중복

-- users 테이블 스키마 변경 시
-- → 3개 프로젝트 모두 수동 업데이트 필요
```

#### 옵션 B: 중앙 metadb ⭐⭐⭐⭐⭐

**장점:**
- ✅ 공통 테이블 정의를 한 번만 저장
- ✅ 여러 프로젝트에서 참조만 추가
- ✅ 공통 테이블 변경 시 자동 반영

**시나리오:**
```sql
-- ✅ 효율: users 테이블 정의 1번만 저장
INSERT INTO metadb._metadata.mappings_table (
    table_name, graphql_type, label, is_shared
) VALUES (
    'users', 'User', '사용자', true  -- shared 표시
);

-- 3개 프로젝트에서 참조만 추가
INSERT INTO metadb._metadata.project_tables (project_id, table_id)
VALUES
    ('project1', (SELECT id FROM _metadata.mappings_table WHERE table_name = 'users')),
    ('project2', (SELECT id FROM _metadata.mappings_table WHERE table_name = 'users')),
    ('project3', (SELECT id FROM _metadata.mappings_table WHERE table_name = 'users'));

-- ✅ users 스키마 변경 시 → 모든 프로젝트 자동 반영!
```

---

### 4. ✅ **코드 생성 복잡도**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐⭐⭐⭐

**장점:**
- ✅ 코드 생성기가 단순함 (1개 DB만 접속)
- ✅ 프로젝트별 독립 실행

**시나리오:**
```typescript
// 코드 생성기
async function generateCode(projectId: string) {
  const db = await connectDB(`${projectId}_db`);

  // 해당 DB의 _metadata에서 읽기
  const tables = await db.query(`
    SELECT * FROM _metadata.mappings_table
  `);

  // 간단!
}
```

#### 옵션 B: 중앙 metadb ⭐⭐⭐

**단점:**
- ⚠️ 2개 DB 연결 필요 (metadb + project_db)
- ⚠️ 프로젝트별 필터링 필요

**시나리오:**
```typescript
// 코드 생성기
async function generateCode(projectId: string) {
  const metaDB = await connectDB('metadb');
  const projectDB = await connectDB(`${projectId}_db`);

  // 1. metadb에서 해당 프로젝트 메타데이터 조회
  const tables = await metaDB.query(`
    SELECT mt.*
    FROM _metadata.mappings_table mt
    JOIN _metadata.project_tables pt ON pt.table_id = mt.id
    JOIN _metadata.projects p ON pt.project_id = p.id
    WHERE p.project_id = $1
  `, [projectId]);

  // 2. projectDB에 DDL 생성
  // 약간 복잡
}
```

---

### 5. ✅ **성능**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐⭐⭐⭐

**장점:**
- ✅ 각 프로젝트의 메타데이터만 조회 (작은 데이터셋)
- ✅ 인덱스 효율적
- ✅ 동시 접속 시 DB 분산

#### 옵션 B: 중앙 metadb ⭐⭐⭐

**단점:**
- ⚠️ metadb에 모든 프로젝트 메타데이터 → 테이블 크기 증가
- ⚠️ 프로젝트별 필터링 필요 (WHERE 절 추가)
- ⚠️ 동시 접속 시 metadb가 병목

**시나리오:**
```sql
-- 옵션 A: 빠름
SELECT * FROM _metadata.mappings_table;  -- 10개 테이블

-- 옵션 B: 느림
SELECT * FROM _metadata.mappings_table
WHERE table_id IN (
  SELECT table_id FROM _metadata.project_tables
  WHERE project_id = 'project1'
);  -- 1000개 테이블 중 10개 필터링
```

---

### 6. ✅ **유지보수**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐⭐

**단점:**
- ⚠️ 메타데이터 스키마 변경 시 모든 프로젝트 DB 업데이트 필요
- ⚠️ 마이그레이션 스크립트를 모든 DB에 실행

**시나리오:**
```bash
# _metadata 스키마에 새 컬럼 추가 시
for db in project1_db project2_db project3_db; do
  psql -d $db -c "ALTER TABLE _metadata.mappings_column ADD COLUMN new_field TEXT;"
done

# ⚠️ 프로젝트 수만큼 반복
```

#### 옵션 B: 중앙 metadb ⭐⭐⭐⭐⭐

**장점:**
- ✅ 메타데이터 스키마 변경 시 metadb만 업데이트
- ✅ 마이그레이션 1회 실행

**시나리오:**
```bash
# _metadata 스키마에 새 컬럼 추가
psql -d metadb -c "ALTER TABLE _metadata.mappings_column ADD COLUMN new_field TEXT;"

# ✅ 1번만 실행
```

---

### 7. ✅ **확장성**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐⭐⭐⭐

**장점:**
- ✅ 프로젝트 수 무제한 확장 가능
- ✅ 각 프로젝트가 독립적으로 확장
- ✅ 나중에 프로젝트별 서버 분리 가능

#### 옵션 B: 중앙 metadb ⭐⭐⭐

**단점:**
- ⚠️ 프로젝트 수 증가 시 metadb 크기 증가
- ⚠️ 프로젝트 100개+ 시 성능 저하 가능

---

### 8. ✅ **개발 편의성**

#### 옵션 A: 프로젝트별 _metadata ⭐⭐⭐⭐

**장점:**
- ✅ 로컬 개발 시 1개 DB만 복사
- ✅ 테스트 환경 구축 쉬움

**시나리오:**
```bash
# 로컬 개발 환경
pg_dump -h production -d project1_db | psql -h localhost -d project1_db

# ✅ 메타데이터 + 비즈니스 데이터 모두 복사됨
```

#### 옵션 B: 중앙 metadb ⭐⭐

**단점:**
- ⚠️ 로컬 개발 시 metadb + project_db 둘 다 필요
- ⚠️ 테스트 환경 구축 복잡

---

## 📋 종합 비교표

| 항목 | 프로젝트별 _metadata | 중앙 metadb | 차이 |
|------|---------------------|-------------|------|
| **독립성** | ⭐⭐⭐⭐⭐ 완벽한 독립 | ⭐⭐ 공유됨 | 🔴 큰 차이 |
| **크로스 조회** | ⭐⭐ 어려움 | ⭐⭐⭐⭐⭐ 쉬움 | 🔴 큰 차이 |
| **메타데이터 공유** | ⭐⭐ 중복 저장 | ⭐⭐⭐⭐⭐ 재사용 | 🔴 큰 차이 |
| **코드 생성** | ⭐⭐⭐⭐⭐ 단순 | ⭐⭐⭐ 약간 복잡 | 🟡 중간 차이 |
| **성능** | ⭐⭐⭐⭐⭐ 빠름 | ⭐⭐⭐ 필터링 필요 | 🟡 중간 차이 |
| **유지보수** | ⭐⭐⭐ 반복 작업 | ⭐⭐⭐⭐⭐ 중앙 관리 | 🟡 중간 차이 |
| **확장성** | ⭐⭐⭐⭐⭐ 무제한 | ⭐⭐⭐ 제한적 | 🟡 중간 차이 |
| **개발 편의성** | ⭐⭐⭐⭐ 단순 | ⭐⭐ 복잡 | 🟡 중간 차이 |
| **백업/복원** | ⭐⭐⭐⭐⭐ 쉬움 | ⭐⭐ 복잡 | 🔴 큰 차이 |

---

## 🎯 상황별 추천

### 🥇 프로젝트별 _metadata 선택 (옵션 A)

다음 경우에 **강력 추천**:

1. **프로젝트가 완전히 독립적**
   - 각 프로젝트가 서로 다른 고객/조직
   - 프로젝트 간 데이터/메타데이터 공유 불필요

2. **프로젝트별 배포/이전 빈번**
   - SaaS 멀티테넌시 (각 고객이 별도 프로젝트)
   - 프로젝트를 다른 서버로 이전할 가능성

3. **간단함 우선**
   - 코드 생성기 단순하게 유지
   - 개발자 학습 곡선 낮추기

4. **확장성 중요**
   - 프로젝트 수가 많거나 계속 증가
   - 나중에 프로젝트별 서버 분리 가능성

**예시 상황:**
```
- 고객별 독립 프로젝트 (고객 A, 고객 B, ...)
- 제품별 독립 프로젝트 (제품 X, 제품 Y, ...)
- 환경별 복사 (dev, staging, production)
```

---

### 🥈 중앙 metadb 선택 (옵션 B)

다음 경우에 **추천**:

1. **프로젝트 간 메타데이터 공유 필요**
   - 공통 테이블 정의 재사용 (users, settings, ...)
   - 공통 스키마 변경 시 자동 반영

2. **전체 플랫폼 통합 관리**
   - 모든 프로젝트의 메타데이터를 한눈에 파악
   - 크로스 프로젝트 분석/통계

3. **메타데이터 중앙 제어**
   - 관리자가 모든 프로젝트 메타데이터 관리
   - 표준 스키마 강제

4. **프로젝트 수가 적고 안정적**
   - 10개 이하의 프로젝트
   - 프로젝트 추가/삭제 드뭄

**예시 상황:**
```
- 같은 회사의 여러 서비스 (서비스 A, 서비스 B, ...)
- 공통 플랫폼 + 여러 앱
- 마이크로서비스 아키텍처 (공통 메타데이터)
```

---

## 💡 최종 추천

### 당신의 상황: Ubuntu 플랫폼 + 여러 프로젝트

**추천: 옵션 A (프로젝트별 _metadata)** ⭐⭐⭐⭐⭐

**이유:**

1. **완벽한 독립성**
   ```bash
   # 프로젝트 전체 백업/이전 간단
   pg_dump project1_db > backup.sql
   ```

2. **간단한 코드 생성**
   ```typescript
   // 1개 DB만 접속
   const db = await connectDB(`${projectId}_db`);
   ```

3. **확장 가능**
   ```
   프로젝트 10개든 100개든 문제없음
   나중에 프로젝트별 서버 분리도 가능
   ```

4. **개발 편의**
   ```bash
   # 로컬 개발 시 1개 DB만 복사
   pg_dump project1_db | psql -h localhost
   ```

---

## 🔄 하이브리드 접근 (선택사항)

필요하다면 두 가지 장점을 결합할 수 있습니다:

```
PostgreSQL 서버
├── metadb (공통 메타데이터만)
│   └── _metadata schema
│       ├── shared_tables (공통 테이블 정의)
│       └── projects (프로젝트 목록)
│
├── project1_db
│   ├── _metadata schema (프로젝트별 메타데이터)
│   │   └── mappings_table → shared_tables 참조 가능
│   └── public schema
│
└── project2_db
    ├── _metadata schema (프로젝트별 메타데이터)
    └── public schema
```

**사용 시나리오:**
- 80%: 프로젝트별 _metadata 사용 (독립성)
- 20%: metadb의 shared_tables 참조 (공통 정의)

---

## 📝 구현 가이드

### 옵션 A 구현 (프로젝트별)

```sql
-- 1. 프로젝트 DB 생성
CREATE DATABASE project1_db;

-- 2. _metadata schema 생성
\c project1_db
CREATE SCHEMA _metadata;

-- 3. 메타데이터 테이블 생성
CREATE TABLE _metadata.mappings_table ( ... );
CREATE TABLE _metadata.mappings_column ( ... );
-- ...

-- 4. 프로젝트별 독립 사용
```

### 옵션 B 구현 (중앙)

```sql
-- 1. 중앙 metadb 생성
CREATE DATABASE metadb;

-- 2. _metadata schema 생성
\c metadb
CREATE SCHEMA _metadata;

-- 3. 메타데이터 테이블 생성 (projects 테이블 필수)
CREATE TABLE _metadata.projects ( ... );
CREATE TABLE _metadata.mappings_table ( ... );
CREATE TABLE _metadata.project_tables ( ... );
-- ...

-- 4. 프로젝트 DB는 비즈니스 데이터만
CREATE DATABASE project1_db;
```

---

## ✅ 체크리스트

### 프로젝트별 _metadata 선택 시

- [ ] 각 프로젝트 DB에 _metadata schema 생성
- [ ] 프로젝트 생성 스크립트 준비
- [ ] 백업/복원 스크립트 (DB 단위)
- [ ] 코드 생성기 (1개 DB 접속)

### 중앙 metadb 선택 시

- [ ] metadb 생성 및 초기화
- [ ] projects 테이블로 프로젝트 관리
- [ ] project_tables 테이블로 매핑 관리
- [ ] 코드 생성기 (2개 DB 접속)
- [ ] 프로젝트별 메타데이터 필터링 로직

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows/`

**버전**: 1.0.0

**작성일**: 2024-10-19
