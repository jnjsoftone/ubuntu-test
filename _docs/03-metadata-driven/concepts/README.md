# 핵심 개념 및 아키텍처 (Concepts & Architecture)

> 메타데이터 기반 개발의 배경 이론과 시스템 아키텍처를 이해합니다.

## 📘 개요

이 디렉토리는 메타데이터 기반 개발 방법론의 핵심 개념, 아키텍처 설계, 기술적 배경을 다룹니다. 실제 개발을 시작하기 전에 이 개념들을 이해하면 전체 시스템을 더 효과적으로 활용할 수 있습니다.

---

## 📚 문서 목록

### [메타데이터 기반 개발 워크플로우](./META-DRIVEN-DEVELOPMENT-WORKFLOW.md)

전체 개발 워크플로우의 개념과 시스템 아키텍처를 설명합니다.

**주요 내용:**

#### 1. 개요 및 핵심 개념
- 메타데이터 기반 개발(Metadata-Driven Development)이란?
- 단일 진실 공급원(Single Source of Truth)
- 주요 이점 (일관성, 개발 속도, 유지보수, 타입 안정성)

#### 2. 데이터베이스 스키마 구조
- 메타데이터 저장소 테이블 구조
  - `projects` - 프로젝트 정보
  - `mappings_table` - 테이블 메타데이터
  - `mappings_column` - 컬럼 메타데이터
  - `mappings_relation` - 관계 메타데이터
  - `metadata_sync_log` - 동기화 이력

#### 3. 5단계 개발 워크플로우
- **Phase 1**: 프로젝트 초기화
  - 메타데이터 DB 생성
  - 프로젝트 등록
  - 환경 설정

- **Phase 2**: 메타데이터 정의
  - 테이블 메타데이터 작성
  - 컬럼 메타데이터 작성
  - 관계 정의
  - 검증

- **Phase 3**: 코드 생성
  - Database DDL
  - GraphQL Schema & Resolvers
  - TypeScript Types
  - React Components

- **Phase 4**: 동기화 모드
  - 자동 동기화 (Watch Mode)
  - 수동 동기화
  - 선택적 재생성

- **Phase 5**: 개발 및 커스터마이징
  - 생성 코드 확장
  - 커스텀 로직 추가
  - 비즈니스 로직 구현

#### 4. 코드 생성 시스템 아키텍처
- Generator 패턴
- Template Engine
- 확장 가능한 구조

#### 5. 프로젝트 관리
- Multi-project 지원
- 버전 관리 전략
- 마이그레이션 관리

#### 6. Best Practices
- 메타데이터 설계 원칙
- 명명 규칙
- 관계 설계 패턴
- 성능 최적화

**읽어야 할 사람:**
- 프로젝트 매니저 (전체 프로세스 이해)
- 시스템 아키텍트 (아키텍처 설계 참고)
- 모든 개발자 (개념 이해)

---

## 🎯 핵심 개념 요약

### 1. 단일 진실 공급원 (Single Source of Truth)

```
┌──────────────────────────┐
│   Metadata Database      │  ← 모든 정보의 유일한 출처
│   (PostgreSQL)           │
└────────────┬─────────────┘
             │
             ↓
┌────────────────────────────┐
│   Code Generation Engine   │
└────────────┬───────────────┘
             │
    ┌────────┴────────┐
    ↓                 ↓
┌─────────┐     ┌──────────┐
│ Backend │     │ Frontend │
│  Code   │     │   Code   │
└─────────┘     └──────────┘
```

메타데이터 DB가 변경되면 → 코드가 자동으로 재생성 → 일관성 보장

### 2. 생성 코드 vs 커스텀 코드

```typescript
// ✅ 올바른 방법: 생성 코드 확장
import { UserService as GeneratedUserService } from '@/generated/services';

export class UserService extends GeneratedUserService {
  // 커스텀 메서드 추가
  async sendWelcomeEmail(userId: string) {
    const user = await this.findById(userId); // 생성된 메서드 사용
    // 커스텀 로직...
  }
}

// ❌ 잘못된 방법: 생성 파일 직접 수정
// generated/services/user-service.ts를 수정하지 마세요!
```

### 3. 자동 동기화

```typescript
// PostgreSQL LISTEN/NOTIFY를 통한 실시간 감지
watcher.on('metadata_changed', async (event) => {
  console.log(`📝 Metadata changed: ${event.table_name}`);
  await generateCode(event.table_name);
  console.log('✅ Code regenerated!');
});
```

### 4. 타입 안정성

```typescript
// 메타데이터에서 TypeScript 타입 자동 생성
export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  createdAt: Date;
  updatedAt: Date;
}

// GraphQL 스키마도 자동 생성
type User {
  id: ID!
  email: String!
  name: String!
  role: UserRole!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

---

## 🏗️ 시스템 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────────┐
│         Metadata Storage Layer              │
│                                              │
│  ┌────────────┐  ┌────────────┐            │
│  │  projects  │  │  mappings_ │            │
│  │            │  │   table    │            │
│  └────────────┘  └────────────┘            │
│                                              │
│  ┌────────────┐  ┌────────────┐            │
│  │  mappings_ │  │  mappings_ │            │
│  │   column   │  │  relation  │            │
│  └────────────┘  └────────────┘            │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│        Code Generation Engine               │
│                                              │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ DB DDL Gen  │  │ GraphQL Gen │          │
│  └─────────────┘  └─────────────┘          │
│                                              │
│  ┌─────────────┐  ┌─────────────┐          │
│  │  Type Gen   │  │  React Gen  │          │
│  └─────────────┘  └─────────────┘          │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│           Generated Code Layer              │
│                                              │
│  Backend (src/generated/)                   │
│  ├── types.ts                               │
│  ├── schema.graphql                         │
│  ├── resolvers/                             │
│  └── services/                              │
│                                              │
│  Frontend (src/generated/)                  │
│  ├── types.ts                               │
│  ├── forms/                                 │
│  └── tables/                                │
└─────────────────────────────────────────────┘
```

---

## 💡 설계 원칙

### 1. 관심사의 분리 (Separation of Concerns)

- **메타데이터 레이어**: 스키마 정의만 담당
- **생성 레이어**: 코드 생성만 담당
- **애플리케이션 레이어**: 비즈니스 로직만 담당

### 2. 확장성 (Extensibility)

- 생성된 코드는 상속/확장 가능
- 새로운 Generator 추가 가능
- 커스텀 템플릿 사용 가능

### 3. 일관성 (Consistency)

- DB, API, UI가 항상 동기화
- 명명 규칙 자동 적용
- 타입 일관성 보장

### 4. 유지보수성 (Maintainability)

- 스키마 변경이 전체 스택에 반영
- 생성 코드는 덮어쓰기 가능
- 커스텀 코드는 보호됨

---

## 🔗 관련 문서

- [상위 문서로 돌아가기](../README.md)
- [워크플로우 실행 가이드](../workflows/README.md)
- [개발 가이드라인](../guides/META-DRIVEN-DEVELOPMENT-GUIDELINES.md)

---

## 📖 추가 학습 자료

### 메타데이터 기반 개발 관련 자료

- [Model-Driven Architecture (MDA)](https://www.omg.org/mda/)
- [Code Generation Patterns](https://martinfowler.com/bliki/CodeGeneration.html)
- [Schema-First Development](https://www.apollographql.com/docs/apollo-server/schema/schema/)

### PostgreSQL 메타데이터

- [PostgreSQL Information Schema](https://www.postgresql.org/docs/current/information-schema.html)
- [PostgreSQL System Catalogs](https://www.postgresql.org/docs/current/catalogs.html)

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/concepts/`

**버전**: 1.0.0
