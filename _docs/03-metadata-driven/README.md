# 메타데이터 기반 개발 (Metadata-Driven Development)

> PostgreSQL + GraphQL (TypeScript) + Next.js 스택을 위한 메타데이터 기반 개발 가이드

## 📖 문서 구성

이 디렉토리는 메타데이터 기반 개발 시스템을 구축하고 활용하기 위한 완전한 가이드를 제공합니다.

### 📁 디렉토리 구조

```
meta-data-driven/
├── workflows/          # 개발 단계별 실행 워크플로우
├── concepts/           # 배경 이론 및 아키텍처 개념
├── guides/             # 실전 가이드 및 템플릿
└── README.md           # 이 문서
```

---

## 🚀 workflows/ - 개발 단계별 워크플로우

실제 개발 프로세스를 단계별로 수행하기 위한 실행 가이드입니다.

### 🌟 [Claude Code 실전 가이드](./workflows/CLAUDE-CODE-FULL-GUIDE.md) - **시작은 여기서!**

Claude Code를 활용한 메타데이터 기반 Fullstack 개발의 전체 프로세스를 5단계로 설명합니다.

**포함 내용:**
- 📋 전체 개발 프로세스 개요
- 🎯 단계별 의사결정 포인트
- 💬 각 단계별 Claude Code 프롬프트 예시
- ✅ 체크리스트
- 🗂️ 프로젝트 구조
- 💡 Best Practices

**읽어야 할 사람:** 모든 개발자 (처음 시작하는 분)

---

### 📚 단계별 상세 워크플로우

#### ⭐ [Phase 0: 메타데이터 테이블 초기화](./workflows/PHASE-1-METADATA-TABLES-SETUP.md) - **필수 사전 작업**
- 메타데이터 전용 DB 생성
- 메타데이터 테이블 생성 (`_metadata.mappings_table`, `_metadata.mappings_column`, 등)
- 완전한 초기화 SQL 스크립트 제공
- 검증 및 테스트
- **중요**: 메타데이터 시스템 최초 구축 시 1회만 실행

#### [Phase 1: 기획](./workflows/CLAUDE-CODE-DEVELOPMENT-GUIDE.md)
- 요구사항 분석 및 검증
- 기술 스택 결정
- 프로젝트 구조 설계
- PostgreSQL 원격 연결 설정
- 보안 정책 정의
- API 설계 초안

#### [Phase 2: 모델링](./workflows/PHASE-2-MODELING.md)
- 프로젝트 등록 (projects 테이블)
- ERD 작성
- 테이블/컬럼 메타데이터 정의
- 관계 정의
- Seed 데이터 정의
- 메타데이터 검증

#### [Phase 3: Backend 개발](./workflows/PHASE-3-BACKEND.md)
- 코드 생성 시스템 구축
- Database DDL 생성
- GraphQL 스키마/리졸버 생성
- Service 레이어 구현
- 인증/권한 Middleware
- Apollo Server 설정

#### [Phase 4: Frontend 개발](./workflows/PHASE-4-FRONTEND.md)
- Apollo Client 설정
- React 컴포넌트 자동 생성
- 인증 페이지 구현
- 사용자 프로필 페이지
- 관리자 페이지
- Protected Route

#### [Phase 5: 테스트 및 배포](./workflows/PHASE-5-TESTING-DEPLOYMENT.md)
- Backend 통합 테스트
- Frontend E2E 테스트
- 성능 테스트 (K6)
- Docker 배포
- CI/CD (GitHub Actions)
- 모니터링 설정

---

## 📚 concepts/ - 배경 이론 및 아키텍처

메타데이터 기반 개발의 핵심 개념과 시스템 아키텍처를 이해하기 위한 이론 문서입니다.

### 1. [메타데이터 기반 개발 워크플로우](./concepts/META-DRIVEN-DEVELOPMENT-WORKFLOW.md)

전체 개발 워크플로우의 개념과 아키텍처를 설명합니다.

**주요 내용:**
- ✅ 메타데이터 기반 개발 개요 및 핵심 개념
- ✅ 데이터베이스 스키마 구조 (메타데이터 테이블)
- ✅ 5단계 개발 워크플로우 개념
  - Phase 1: 프로젝트 초기화
  - Phase 2: 메타데이터 정의
  - Phase 3: 코드 생성
  - Phase 4: 동기화 모드 (자동/수동)
  - Phase 5: 개발 및 커스터마이징
- ✅ 코드 생성 시스템 아키텍처
- ✅ 프로젝트 관리 개념
- ✅ Best Practices

**읽어야 할 사람:** 프로젝트 매니저, 아키텍트, 모든 개발자

---

## 🛠️ guides/ - 실전 가이드 및 템플릿

실제 개발에 필요한 상세 가이드라인, 구현 예제, 코드 템플릿을 제공합니다.

### 1. [개발 가이드라인](./guides/META-DRIVEN-DEVELOPMENT-GUIDELINES.md)

실전 개발을 위한 상세한 가이드라인과 예제를 제공합니다.

**주요 내용:**
- ✅ 개발 환경 설정
  - Node.js, PostgreSQL, pnpm 설치
  - 프로젝트 구조 생성
  - 패키지 설치
  - 환경 변수 설정
- ✅ 메타데이터 정의 가이드
  - 명명 규칙 (Database, GraphQL, TypeScript)
  - 다양한 필드 타입별 정의 예시
  - 관계 정의 패턴
- ✅ 코드 생성 및 커스터마이징
  - 생성 vs 커스터마이징 구분
  - 디렉토리 구조 규칙
  - 확장 패턴
- ✅ TypeScript 타입 시스템
- ✅ GraphQL 스키마 설계
- ✅ React 컴포넌트 패턴
- ✅ 테스트 전략
- ✅ 배포 및 CI/CD
- ✅ 트러블슈팅

**읽어야 할 사람:** 백엔드/프론트엔드 개발자

---

### 2. [코드 생성 템플릿](./guides/CODE-GENERATION-TEMPLATES.md)

실제 코드를 생성하는 Generator 구현 템플릿을 제공합니다.

**주요 내용:**
- ✅ Generator 기본 구조 (BaseGenerator)
- ✅ Database DDL Generator
- ✅ GraphQL Schema Generator
- ✅ TypeScript Types Generator
- ✅ Resolver Generator
- ✅ React Form Generator
- ✅ React Table Generator
- ✅ Migration Generator

**읽어야 할 사람:** 백엔드 개발자, 시스템 아키텍트

---

### 3. [Backend 디렉토리 구조 가이드](/var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/backend/nodejs/METADATA-DRIVEN-STRUCTURE.md)

Node.js + TypeScript + GraphQL 프로젝트에서 메타데이터 기반 개발을 적용할 때의 실제 디렉토리 구조 및 코드 배치 가이드입니다.

**주요 내용:**
- ✅ 생성 코드 vs 커스텀 코드 분리 원칙
- ✅ `src/generated/` 디렉토리 구조 (자동 생성 영역)
- ✅ `src/custom/` 디렉토리 구조 (개발자 작성 영역)
- ✅ 확장 패턴 및 상속 예제
- ✅ 실전 예제 (사용자 인증, 필드 추가, 비즈니스 로직)
- ✅ Git 버전 관리 전략
- ✅ FAQ 및 트러블슈팅

**읽어야 할 사람:** 백엔드 개발자 (프로젝트 시작 전 필수)

---

## 🚀 빠른 시작

### 1단계: 메타데이터 DB 초기화

```bash
# 메타데이터 전용 데이터베이스 생성
psql -U postgres -c "CREATE DATABASE metadb;"

# 스키마 생성 (워크플로우 가이드 참조)
psql -U postgres -d metadb -f schema/metadata-schema.sql
```

### 2단계: 프로젝트 등록

```sql
INSERT INTO projects (
    project_id, project_name, description, root_path, tech_stack
) VALUES (
    'my-project',
    'My Application',
    'Project description',
    '/workspace/my-project',
    '{
        "backend": "Node.js + TypeScript + GraphQL",
        "frontend": "Next.js + React",
        "database": "PostgreSQL"
    }'::jsonb
);
```

### 3단계: 메타데이터 정의

개발자 모드 UI 또는 SQL을 통해 테이블과 컬럼 메타데이터를 정의합니다.

```sql
-- 테이블 정의 예시 (가이드라인 문서 참조)
INSERT INTO mappings_table (
    schema_name, table_name, graphql_type, label, description
) VALUES (
    'public', 'users', 'User', '사용자', '시스템 사용자 정보'
);

-- 컬럼 정의 예시
INSERT INTO mappings_column (
    table_id, schema_name, table_name,
    pg_column, pg_type, graphql_field, graphql_type,
    label, form_type, is_required
) VALUES (
    (SELECT id FROM mappings_table WHERE table_name = 'users'),
    'public', 'users',
    'email', 'VARCHAR(255)', 'email', 'String',
    '이메일', 'email', true
);
```

### 4단계: 코드 생성

```bash
# 전체 코드 생성
npm run generate:all

# 또는 개별 생성
npm run generate:db          # Database DDL
npm run generate:graphql     # GraphQL Schema & Resolvers
npm run generate:react       # React Components
```

### 5단계: 개발 시작

```bash
# Watch 모드 실행 (메타데이터 변경 시 자동 재생성)
npm run dev:watch

# 백엔드 개발 서버
npm run dev:backend

# 프론트엔드 개발 서버
npm run dev:frontend
```

---

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────┐
│   Metadata Storage (PostgreSQL)          │
│   - mappings_table                       │
│   - mappings_column                      │
│   - mappings_relation                    │
│   - projects                             │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│   Code Generation Engine                 │
│   - Database DDL Generator               │
│   - GraphQL Schema Generator             │
│   - Resolver Generator                   │
│   - React Component Generator            │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│   Generated Code                         │
│   - DB Migrations                        │
│   - GraphQL Schema & Resolvers           │
│   - React Forms & Tables                 │
│   - TypeScript Types                     │
└─────────────────────────────────────────┘
```

---

## 📂 디렉토리 구조

프로젝트를 생성하면 다음과 같은 구조가 만들어집니다:

```
my-project/
├── backend/
│   ├── src/
│   │   ├── generated/           # 자동 생성 코드 (수정 금지)
│   │   │   ├── types.ts
│   │   │   ├── schema.graphql
│   │   │   ├── resolvers/
│   │   │   └── services/
│   │   ├── custom/              # 커스텀 코드 (여기에 작성)
│   │   │   ├── resolvers/
│   │   │   ├── services/
│   │   │   └── middleware/
│   │   └── index.ts
│   └── package.json
│
├── frontend/
│   ├── src/
│   │   ├── generated/           # 자동 생성 코드
│   │   │   ├── types.ts
│   │   │   ├── forms/
│   │   │   └── tables/
│   │   ├── components/          # 커스텀 컴포넌트
│   │   ├── hooks/
│   │   └── app/
│   └── package.json
│
└── database/
    ├── migrations/              # 자동 생성 마이그레이션
    ├── seeds/
    └── scripts/
```

---

## 🎯 핵심 개념

### 1. 단일 진실 공급원 (Single Source of Truth)

메타데이터 데이터베이스가 모든 스키마 정보의 유일한 출처입니다.

```
Metadata DB → Code Generation → Application Code
```

### 2. 생성 코드 vs 커스텀 코드

```typescript
// ✅ 올바른 방법: 생성된 코드 확장
import { UserService as GeneratedUserService } from '@/generated/services';

export class UserService extends GeneratedUserService {
  // 커스텀 메서드 추가
  async customMethod() { }
}

// ❌ 잘못된 방법: 생성 파일 직접 수정
// generated/services/user-service.ts를 직접 수정하지 마세요!
```

### 3. 자동 동기화

메타데이터가 변경되면 코드가 자동으로 재생성됩니다.

```typescript
// PostgreSQL LISTEN/NOTIFY를 사용한 실시간 감지
watcher.on('metadata_changed', async () => {
  await generateAll();
  console.log('✅ Code regenerated!');
});
```

---

## 🔧 CLI 명령어 참조

### 프로젝트 관리
```bash
npm run project:create <name>          # 새 프로젝트 생성
npm run project:list                   # 프로젝트 목록
npm run project:info <id>              # 프로젝트 상세 정보
```

### 메타데이터 관리
```bash
npm run meta:sync                      # 전체 동기화
npm run meta:sync:table -- <name>      # 특정 테이블만
npm run meta:validate                  # 메타데이터 검증
npm run meta:export                    # 메타데이터 내보내기
npm run meta:import -- <file>          # 메타데이터 가져오기
```

### 코드 생성
```bash
npm run generate:all                   # 전체 코드 생성
npm run generate:db                    # DB DDL만
npm run generate:graphql               # GraphQL만
npm run generate:react                 # React 컴포넌트만
```

### 개발 모드
```bash
npm run dev:meta                       # 메타데이터 편집기
npm run dev:watch                      # Watch 모드
```

### 마이그레이션
```bash
npm run migration:generate -- <table>  # 마이그레이션 생성
npm run migration:run                  # 마이그레이션 실행
npm run migration:rollback             # 마이그레이션 롤백
```

---

## 💡 Best Practices

### 1. 메타데이터 설계

- ✅ 일관된 명명 규칙 사용
- ✅ 상세한 라벨 및 설명 작성
- ✅ validation 규칙 명확히 정의
- ✅ 검색/필터링 가능 필드 명시
- ❌ 메타데이터와 실제 DB 불일치 방지
- ❌ 생성된 코드 직접 수정 금지

### 2. 코드 생성 전략

- ✅ 생성 코드와 커스텀 코드 분리
- ✅ 상속을 통한 확장 패턴 사용
- ✅ 변경된 테이블만 재생성 (성능)
- ❌ 과도한 컬럼 수 (테이블 분리 고려)
- ❌ 순환 참조 관계 생성

### 3. 버전 관리

```gitignore
# .gitignore

# 선택적으로 생성 코드 제외
backend/src/generated/
frontend/src/generated/

# 메타데이터는 반드시 커밋
!database/metadata/
```

---

## 🔗 관련 문서

- [플랫폼 관리 시스템 개요](/var/services/homes/jungsam/dev/dockers/CLAUDE.md)
- [Docker 플랫폼 생성 가이드](/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/README.md)
- [Manager API 문서](http://1.231.118.217:20101/doc/)

---

## 📝 문서 이력

- **v2.1.0** (2024-10-19): Backend 디렉토리 구조 가이드 추가
  - 📂 실제 프로젝트 템플릿 디렉토리 구조 정의
  - 🔒 생성 코드 vs ✏️ 커스텀 코드 배치 규칙
  - 📋 확장 패턴 상세 예제
  - ❓ FAQ 및 트러블슈팅

- **v2.0.0** (2024-10-19): Claude Code 실전 가이드 추가
  - 🌟 Claude Code 활용 Fullstack 개발 가이드
  - Phase 1~5 단계별 상세 가이드
  - 실전 프롬프트 예시 및 의사결정 포인트
  - 사용자 인증/권한 시스템 완전한 예제

- **v1.0.0** (2024-10-19): 초기 문서 작성
  - 메타데이터 기반 개발 워크플로우
  - 개발 가이드라인
  - 코드 생성 템플릿

---

## 🤝 기여

메타데이터 기반 개발 시스템 개선에 기여하실 수 있습니다:

1. 새로운 Generator 추가
2. 메타데이터 스키마 개선
3. 문서 업데이트
4. 버그 리포트 및 수정

---

## 📧 문의

문제가 발생하거나 질문이 있으시면 이슈를 등록해주세요.

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/meta-data-driven/`

**관리**: Platform Management System

**버전**: 1.0.0
