# ${PLATFORM_NAME} 플랫폼 문서

${PLATFORM_NAME} 플랫폼 개발을 위한 종합 문서입니다. AI 협업(Claude Code, Codex CLI, Gemini CLI)을 활용한 메타데이터 기반 개발 환경을 제공합니다.

## 📌 문서 범위

**이 문서는 플랫폼 레벨 문서입니다** - 모든 프로젝트에 적용되는 공통 가이드라인과 표준입니다.

**주요 특징**:
- **보편적**: 전체 플랫폼 생태계에 적용되는 표준
- **안정적**: 플랫폼 전체 패턴이 발전할 때만 변경됨
- **AI 최적화**: 영문 버전(`.md`)은 AI(Claude Code)가 이해하기 쉽게 간결하게 작성
- **개발자 친화적**: 한글 버전(`.kr.md`)은 상세하고 이해하기 쉽게 작성
- **플랫폼 생성 시 복사됨**: `cu.sh`로 새 플랫폼 생성 시 이 `_docs/` 디렉토리가 복사됩니다

**프로젝트 문서와의 관계**:
- 플랫폼 문서 (여기) = **일반적인 표준과 가이드라인**
- 프로젝트 문서 (`ubuntu-project/_docs/`) = **프로젝트별 구현 세부사항**
- 전체 문서 아키텍처는 [CLAUDE.md](/volume1/homes/jungsam/dockers/CLAUDE.md) 참조

## 📚 문서 구조

```
_docs/
├── README.md                        # 이 문서 (문서 인덱스)
├── 00-getting-started/              # 신규: 빠른 시작 및 워크플로우
│   ├── README.md
│   └── development-workflow.md / .kr.md
├── 01-standards/                    # 신규: 모든 코딩 표준 통합
│   ├── README.md
│   ├── graphql.md / .kr.md         # GraphQL (설계 + 네이밍 통합)
│   ├── rest-api.md / .kr.md        # REST API 표준
│   ├── typescript.md               # TypeScript 규칙
│   ├── nextjs.md                   # Next.js 모범 사례
│   └── database.md / .kr.md        # 데이터베이스 표준
├── 02-architecture/                 # 플랫폼 아키텍처 (이름 변경)
│   ├── platform-overview.md / .kr.md
│   └── metadata-schema.md / .kr.md
├── 03-metadata-driven/              # 메타데이터 기반 개발 (이름 변경)
│   ├── concepts/
│   ├── guides/
│   └── workflows/
├── 04-ai-collaboration/             # AI 협업 가이드 (이동)
│   ├── README.md
│   └── claude-code.md / .kr.md
├── 05-examples/                     # 실전 예제 (번호 변경)
│   ├── README.md
│   └── simple-crud.md / .kr.md
├── 06-troubleshooting/              # 문제 해결 (번호 변경)
│   ├── README.md
│   └── common-issues.md / .kr.md
└── 99-chats/                        # 채팅 아카이브 (이름 변경)
    └── claude/
```

---

## 🚀 빠른 시작

### 처음 시작하는 경우

1. **플랫폼 이해하기**
   - [플랫폼 아키텍처 개요](./architecture/01-platform-overview.md) 📖
   - 핵심 개념: 도메인별 격리, 자동 포트 할당, 메타데이터 기반 개발

2. **개발 환경 설정**
   - [개발 워크플로우](./guidelines/02-development-workflow.md) 🔄
   - 프로젝트 생성, 환경 설정, 코드 생성

3. **첫 번째 프로젝트 만들기**
   - [간단한 CRUD API 예제](./examples/01-simple-crud.md) ✨
   - 메타데이터 정의부터 배포까지 전 과정

### 개발 경험이 있는 경우

- **빠른 레퍼런스**:
  - [코딩 컨벤션](./guidelines/04-coding-conventions.md) - TypeScript, GraphQL 규칙
  - [데이터베이스 관리](./guidelines/03-database-management.md) - 스키마, 마이그레이션
  - [GraphQL API 설계](./api/01-graphql-design.md) - 네이밍, 패턴, 최적화

- **AI 활용**:
  - [AI 협업 가이드](./guidelines/01-ai-collaboration.md) - Claude Code, Codex, Gemini 활용법

---

## 📖 주제별 문서

### 1️⃣ 가이드라인 (Guidelines)

개발 과정에서 따라야 할 규칙과 모범 사례

| 문서 | 설명 | 대상 |
|-----|------|------|
| [AI 협업](./guidelines/01-ai-collaboration.md) | Claude Code, Codex, Gemini 활용 전략 | 모든 개발자 |
| [개발 워크플로우](./guidelines/02-development-workflow.md) | 프로젝트 생성부터 배포까지 전체 프로세스 | 모든 개발자 |
| [데이터베이스 관리](./guidelines/03-database-management.md) | 스키마 설계, 마이그레이션, 최적화, 백업 | Backend 개발자 |
| [코딩 컨벤션](./guidelines/04-coding-conventions.md) | TypeScript, GraphQL, 네이밍 규칙 | 모든 개발자 |

**추천 학습 순서**: AI 협업 → 개발 워크플로우 → 데이터베이스 관리 → 코딩 컨벤션

### 2️⃣ 아키텍처 (Architecture)

플랫폼의 구조와 설계 원칙

| 문서 | 설명 | 대상 |
|-----|------|------|
| [플랫폼 아키텍처 개요](./architecture/01-platform-overview.md) | 전체 아키텍처, 포트 할당, 기술 스택 | 모든 개발자 |
| [메타데이터 스키마](./architecture/02-metadata-schema.md) | 메타데이터 정의, 코드 생성 규칙 | Backend 개발자 |

**필독**: 플랫폼 아키텍처 개요는 모든 개발자가 반드시 읽어야 합니다.

### 3️⃣ API 설계 (API)

GraphQL API 설계 원칙과 패턴

| 문서 | 설명 | 대상 |
|-----|------|------|
| [GraphQL API 설계](./api/01-graphql-design.md) | 스키마 구조, 네이밍, 쿼리/뮤테이션 패턴 | Backend/Frontend 개발자 |

**참고**: 메타데이터 기반 자동 생성 코드도 이 원칙을 따릅니다.

### 4️⃣ 문제 해결 (Troubleshooting)

자주 발생하는 문제와 해결 방법

| 문서 | 설명 | 난이도 |
|-----|------|--------|
| [일반적인 문제](./troubleshooting/01-common-issues.md) | 포트, DB, Docker, 환경변수 등 | ⭐ 초급 |

**Tip**: 에러 발생 시 Ctrl+F로 에러 메시지 검색

### 5️⃣ 예제 (Examples)

실전 프로젝트 예제

| 문서 | 설명 | 난이도 |
|-----|------|--------|
| [간단한 CRUD API](./examples/01-simple-crud.md) | 블로그 CRUD API 전체 구현 과정 | ⭐ 초급 |

**추천**: 첫 번째 프로젝트는 반드시 예제를 따라해보세요.

---

## 🎯 사용 시나리오별 가이드

### 📝 시나리오 1: 새 프로젝트 시작
```
1. 플랫폼 아키텍처 이해
   └─ architecture/01-platform-overview.md

2. 개발 워크플로우 숙지
   └─ guidelines/02-development-workflow.md

3. 예제 따라하기
   └─ examples/01-simple-crud.md

4. 메타데이터 정의
   └─ architecture/02-metadata-schema.md

5. AI로 코드 생성
   └─ guidelines/01-ai-collaboration.md
```

### 🔧 시나리오 2: 데이터베이스 설계
```
1. 메타데이터 스키마 학습
   └─ architecture/02-metadata-schema.md

2. 데이터베이스 관리 가이드
   └─ guidelines/03-database-management.md

3. GraphQL API 설계 확인
   └─ api/01-graphql-design.md

4. 문제 발생 시
   └─ troubleshooting/01-common-issues.md
```

### 🤖 시나리오 3: AI 협업 최적화
```
1. AI 협업 가이드 숙지
   └─ guidelines/01-ai-collaboration.md

2. 코딩 컨벤션 확인
   └─ guidelines/04-coding-conventions.md

3. 프롬프트 작성 예제
   └─ 각 가이드라인 문서의 예제 참조

4. 실전 적용
   └─ examples/ 폴더의 예제들
```

### 🐛 시나리오 4: 문제 해결
```
1. 일반적인 문제 확인
   └─ troubleshooting/01-common-issues.md

2. 해당 영역 가이드 참조
   ├─ 포트 문제: architecture/01-platform-overview.md
   ├─ DB 문제: guidelines/03-database-management.md
   └─ API 문제: api/01-graphql-design.md

3. AI 도구 활용
   └─ guidelines/01-ai-collaboration.md

4. 여전히 해결 안 되면
   └─ 플랫폼 관리자에게 문의
```

---

## 🔑 핵심 개념

### 메타데이터 기반 개발
- **메타데이터 정의** → **코드 자동 생성** → **커스텀 로직 추가**
- 80% 이상의 보일러플레이트 코드 자동화
- 일관된 코드 품질 보장

### 자동 포트 할당
- 플랫폼당 200개 포트 (SN × 200)
- 프로젝트당 20개 포트 (Production 10 + Development 10)
- 충돌 방지 시스템

### AI 협업
- **Claude Code**: 복잡한 아키텍처, 리팩토링
- **Codex CLI**: 빠른 코드 스니펫 생성
- **Gemini CLI**: 문서 작성, 테스트 케이스

---

## 📊 기술 스택

### Backend
- Node.js + TypeScript
- GraphQL (Apollo Server)
- TypeORM
- PostgreSQL

### Frontend
- Next.js (App Router)
- React 19
- Tailwind CSS 4

### Infrastructure
- Docker
- N8N (워크플로우 자동화)
- Nginx (Reverse Proxy)

---

## 🔄 문서 업데이트

이 문서는 플랫폼과 함께 계속 발전합니다.

### 최근 업데이트
- 2024-10-19: 초기 문서 구조 생성
  - Guidelines: AI 협업, 개발 워크플로우, DB 관리, 코딩 컨벤션
  - Architecture: 플랫폼 개요, 메타데이터 스키마
  - API: GraphQL 설계 가이드
  - Troubleshooting: 일반적인 문제
  - Examples: 간단한 CRUD API

### 향후 추가 예정
- [ ] 인증/인가 시스템 가이드
- [ ] 파일 업로드 가이드
- [ ] 실시간 기능 (Subscriptions) 가이드
- [ ] 배포 및 운영 가이드
- [ ] 성능 최적화 가이드
- [ ] 테스트 전략 가이드

---

## 💡 문서 작성 원칙

1. **명확성**: 누구나 이해할 수 있는 설명
2. **실용성**: 실전에서 바로 사용 가능한 예제
3. **완전성**: 시작부터 끝까지 완전한 가이드
4. **일관성**: 모든 문서에서 동일한 용어와 패턴 사용

---

## 🤝 기여 가이드

문서 개선 아이디어가 있으면:

1. **오타/오류 수정**: 직접 수정 후 PR
2. **새로운 예제 추가**: `examples/` 폴더에 추가
3. **가이드라인 개선**: 실제 경험을 바탕으로 보완
4. **FAQ 추가**: `troubleshooting/` 폴더에 추가

---

## 📞 도움말

### 문서 관련 질문
- 문서 내용이 이해가 안 되는 경우
- 더 자세한 설명이 필요한 경우
- 예제가 동작하지 않는 경우

### AI 도구 활용
```bash
# Claude Code로 문서 읽기
claude-code "docs/architecture/01-platform-overview.md 를 읽고 요약해줘"

# 특정 주제 질문
claude-code "포트 할당 시스템에 대해 설명해줘 (docs/architecture/01-platform-overview.md 참조)"
```

### 플랫폼 관리자
- 기술적 문제
- 플랫폼 설정 변경
- 권한 관련 이슈

---

## 🎓 학습 경로 추천

### 🌱 초보자 (1-2주)
```
Week 1:
- Day 1-2: 플랫폼 아키텍처 개요
- Day 3-4: 개발 워크플로우
- Day 5: 간단한 CRUD API 예제

Week 2:
- Day 1-2: 메타데이터 스키마
- Day 3-4: 데이터베이스 관리
- Day 5: 코딩 컨벤션
```

### 🚀 중급자 (1주)
```
- Day 1: AI 협업 가이드
- Day 2: GraphQL API 설계
- Day 3-4: 고급 예제 실습
- Day 5: 커스텀 로직 개발
```

### ⚡ 고급자 (수시 참조)
```
- 코딩 컨벤션 (레퍼런스)
- 문제 해결 가이드 (필요시)
- API 설계 패턴 (설계시)
```

---

## 📌 자주 찾는 문서

| 문서 | 경로 |
|-----|------|
| 포트 할당 시스템 | [architecture/01-platform-overview.md](./architecture/01-platform-overview.md#포트-할당-체계) |
| 메타데이터 예시 | [architecture/02-metadata-schema.md](./architecture/02-metadata-schema.md#전체-예시) |
| GraphQL 네이밍 규칙 | [api/01-graphql-design.md](./api/01-graphql-design.md#네이밍-컨벤션) |
| 데이터베이스 마이그레이션 | [guidelines/03-database-management.md](./guidelines/03-database-management.md#마이그레이션-관리) |
| AI 프롬프트 예시 | [guidelines/01-ai-collaboration.md](./guidelines/01-ai-collaboration.md#효과적인-프롬프트-작성) |
| 포트 충돌 해결 | [troubleshooting/01-common-issues.md](./troubleshooting/01-common-issues.md#포트-관련-문제) |

---

## 🌟 다음 단계

문서를 다 읽었다면:

1. ✅ [간단한 CRUD API](./examples/01-simple-crud.md) 예제 따라하기
2. ✅ 자신만의 프로젝트 메타데이터 정의하기
3. ✅ AI 도구로 코드 생성해보기
4. ✅ 커스텀 로직 추가하기
5. ✅ 다른 개발자와 지식 공유하기

**Happy Coding! 🚀**
