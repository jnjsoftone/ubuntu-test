# 개발 워크플로우 (Development Workflows)

> 메타데이터 기반 개발의 실제 실행 프로세스를 단계별로 안내합니다.

## 📋 문서 목록

### 🌟 시작 가이드

**[Claude Code 실전 가이드](./CLAUDE-CODE-FULL-GUIDE.md)** - **처음 시작하는 분은 여기서!**

Claude Code를 활용한 메타데이터 기반 Fullstack 개발의 전체 프로세스를 5단계로 설명합니다.
- 전체 개발 프로세스 개요
- 단계별 의사결정 포인트
- Claude Code 프롬프트 예시
- 체크리스트 및 Best Practices

---

## 📚 단계별 워크플로우

### Phase 0: [메타데이터 테이블 초기화](./PHASE-1-METADATA-TABLES-SETUP.md) ⭐ **필수 사전 작업**

프로젝트 DB에 `_metadata` schema를 생성하고 메타데이터 테이블을 초기화하는 단계입니다.

**포함 내용:**
- 📋 메타데이터 테이블 목록 및 구조 상세 설명
- 💾 완전한 초기화 SQL 스크립트 (`00-metadata-tables.sql`)
- 🔧 `_metadata` schema 생성 및 설정
- ✅ 검증 및 테스트 방법
- 📦 백업 및 복원 가이드

**핵심 테이블:**
- `_metadata.project` - 프로젝트 정보 (단일 레코드)
- `_metadata.mappings_table` - 테이블 메타데이터
- `_metadata.mappings_column` - 컬럼 메타데이터 (DB, GraphQL, UI)
- `_metadata.mappings_relation` - 관계 메타데이터

**아키텍처:**
- ✅ 프로젝트별 격리 (각 프로젝트 DB마다 독립적인 `_metadata` schema)
- ✅ 프로젝트 정보는 단일 레코드 (`CONSTRAINT single_project CHECK (id = 1)`)
- ❌ `project_tables` 테이블 불필요 (DB 분리로 매핑 자동)

**소요 시간:** 30분

**중요**: 각 프로젝트마다 독립적인 `_metadata` schema를 생성하여 프로젝트 간 완전한 격리를 보장합니다.

---

### Phase 1: [기획 및 요구사항 분석](./CLAUDE-CODE-DEVELOPMENT-GUIDE.md)

프로젝트 시작 단계의 실행 가이드입니다.

**포함 내용:**
- 요구사항 분석 및 검증
- 기술 스택 결정
- 프로젝트 구조 설계
- PostgreSQL 원격 연결 설정
- 보안 정책 정의
- API 설계 초안

**소요 시간:** 1-2일

---

### Phase 2: [데이터 모델링](./PHASE-2-MODELING.md)

메타데이터 정의 및 데이터베이스 설계 단계입니다.

**포함 내용:**
- 메타데이터 DB 초기화
- ERD 작성
- 테이블/컬럼 메타데이터 정의
- 관계 정의
- Seed 데이터 정의
- 메타데이터 검증

**소요 시간:** 2-3일

---

### Phase 3: [Backend 개발](./PHASE-3-BACKEND.md)

백엔드 코드 생성 및 구현 단계입니다.

**포함 내용:**
- 코드 생성 시스템 구축
- Database DDL 생성
- GraphQL 스키마/리졸버 생성
- Service 레이어 구현
- 인증/권한 Middleware
- Apollo Server 설정

**소요 시간:** 3-5일

---

### Phase 4: [Frontend 개발](./PHASE-4-FRONTEND.md)

프론트엔드 컴포넌트 생성 및 구현 단계입니다.

**포함 내용:**
- Apollo Client 설정
- React 컴포넌트 자동 생성
- 인증 페이지 구현
- 사용자 프로필 페이지
- 관리자 페이지
- Protected Route

**소요 시간:** 3-5일

---

### Phase 5: [테스트 및 배포](./PHASE-5-TESTING-DEPLOYMENT.md)

테스트, 최적화, 배포 단계입니다.

**포함 내용:**
- Backend 통합 테스트
- Frontend E2E 테스트
- 성능 테스트 (K6)
- Docker 배포
- CI/CD (GitHub Actions)
- 모니터링 설정

**소요 시간:** 2-3일

---

## 🎯 워크플로우 특징

### 순차적 진행

각 Phase는 이전 단계의 결과물을 기반으로 합니다:

```
Phase 1 (기획)
  → Phase 2 (모델링)
    → Phase 3 (Backend)
      → Phase 4 (Frontend)
        → Phase 5 (테스트/배포)
```

### 반복 가능

각 Phase 내에서 필요시 이전 단계로 돌아가 수정할 수 있습니다.

### 자동화 지원

메타데이터 변경 시 코드가 자동으로 재생성되어 일관성을 유지합니다.

---

## ✅ 체크리스트

각 Phase를 완료하기 전에 확인해야 할 사항:

### Phase 1 완료 기준
- [ ] 요구사항 문서 작성 완료
- [ ] 기술 스택 결정 및 문서화
- [ ] PostgreSQL 연결 테스트 성공
- [ ] 보안 정책 문서 작성

### Phase 2 완료 기준
- [ ] 메타데이터 DB 초기화 완료
- [ ] ERD 작성 및 검토 완료
- [ ] 모든 테이블/컬럼 메타데이터 정의
- [ ] 관계 정의 완료
- [ ] 메타데이터 검증 통과

### Phase 3 완료 기준
- [ ] 코드 생성 시스템 구축 완료
- [ ] Database DDL 생성 및 적용 완료
- [ ] GraphQL 스키마 생성 완료
- [ ] 모든 리졸버 구현 완료
- [ ] 인증/권한 시스템 구현 완료
- [ ] Apollo Server 실행 성공

### Phase 4 완료 기준
- [ ] Apollo Client 설정 완료
- [ ] 모든 React 컴포넌트 생성 완료
- [ ] 인증 페이지 구현 및 테스트 완료
- [ ] Protected Route 동작 확인
- [ ] UI/UX 검토 완료

### Phase 5 완료 기준
- [ ] Backend 통합 테스트 통과
- [ ] Frontend E2E 테스트 통과
- [ ] 성능 테스트 통과
- [ ] Docker 배포 성공
- [ ] CI/CD 파이프라인 구축 완료
- [ ] 모니터링 시스템 설정 완료

---

## 📊 전체 일정 예상

| Phase | 소요 시간 | 누적 시간 |
|-------|-----------|-----------|
| Phase 1: 기획 | 1-2일 | 1-2일 |
| Phase 2: 모델링 | 2-3일 | 3-5일 |
| Phase 3: Backend | 3-5일 | 6-10일 |
| Phase 4: Frontend | 3-5일 | 9-15일 |
| Phase 5: 테스트/배포 | 2-3일 | 11-18일 |

**총 예상 기간:** 2-3주 (개발자 1명 기준)

---

## 🔗 관련 문서

- [상위 문서로 돌아가기](../README.md)
- [메타데이터 기반 개발 개념](../concepts/META-DRIVEN-DEVELOPMENT-WORKFLOW.md)
- [개발 가이드라인](../guides/META-DRIVEN-DEVELOPMENT-GUIDELINES.md)
- [코드 생성 템플릿](../guides/CODE-GENERATION-TEMPLATES.md)

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows/`

**버전**: 1.0.0
