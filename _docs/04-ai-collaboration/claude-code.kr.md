# AI 협업 가이드라인

이 문서는 Claude Code, Codex CLI, Gemini CLI 등 AI 도구를 활용한 개발 가이드라인입니다.

## 🤖 AI 도구 활용 전략

### 지원 AI 도구
- **Claude Code**: 전체 아키텍처 설계, 복잡한 로직 구현, 리팩토링
- **Codex CLI**: 빠른 코드 스니펫 생성, 함수 구현
- **Gemini CLI**: 문서 작성, 코드 리뷰, 테스트 케이스 생성

### AI 도구 선택 기준

| 작업 유형 | 추천 도구 | 이유 |
|---------|---------|------|
| 전체 시스템 설계 | Claude Code | 복잡한 컨텍스트 이해 능력 |
| GraphQL Schema 설계 | Claude Code | 타입 시스템 이해 및 관계 설정 |
| CRUD API 생성 | Codex CLI | 반복적인 패턴 빠른 생성 |
| 데이터베이스 마이그레이션 | Claude Code | 데이터 무결성 고려 필요 |
| 테스트 코드 작성 | Gemini CLI | 다양한 엣지 케이스 생성 |
| 문서화 | Gemini CLI | 자연스러운 문서 작성 |
| 디버깅 | Claude Code | 복잡한 문제 분석 능력 |

## 📝 효과적인 프롬프트 작성

### 컨텍스트 제공
AI에게 충분한 컨텍스트를 제공하세요:

```
이 플랫폼은 메타데이터 기반 개발 환경입니다.
- 기술 스택: Node.js, PostgreSQL, GraphQL, Next.js
- 포트 범위: ${PLATFORM_PORT_START} - ${PLATFORM_PORT_END}
- 데이터베이스: PostgreSQL (포트 ${PLATFORM_POSTGRES_PORT})

다음 작업을 수행해주세요:
[구체적인 작업 설명]
```

### 프로젝트 구조 참조
```
/docs/architecture/ 폴더의 구조를 참고하여,
새로운 프로젝트를 생성해주세요.
- 프로젝트명: user-management
- GraphQL API 포함
- PostgreSQL 스키마 자동 생성
```

### 단계별 작업 요청
복잡한 작업은 단계별로 나누어 요청:

```
Step 1: GraphQL schema 정의 (User, Role 테이블)
Step 2: TypeORM entities 생성
Step 3: Resolvers 구현
Step 4: 테스트 코드 작성
```

## 🔄 AI 협업 워크플로우

### 1. 설계 단계
```bash
# Claude Code를 활용한 아키텍처 설계
$ claude-code "설계: 사용자 인증 시스템 (JWT + PostgreSQL)"
```

**프롬프트 예시:**
```
${PLATFORM_NAME} 플랫폼에 JWT 기반 인증 시스템을 설계해주세요.

요구사항:
1. PostgreSQL users 테이블 설계
2. JWT 토큰 생성/검증 로직
3. GraphQL mutation: login, register, refreshToken
4. 환경변수: JWT_SECRET (이미 설정됨)

출력 형식:
- 데이터베이스 스키마 (SQL)
- GraphQL schema 정의
- 폴더 구조
```

### 2. 구현 단계
```bash
# 생성된 설계를 바탕으로 코드 구현
$ claude-code "구현: /docs/architecture/auth-design.md 기반 코드 생성"
```

### 3. 테스트 단계
```bash
# Gemini로 테스트 케이스 생성
$ gemini "테스트: src/auth/auth.service.ts의 모든 메서드"
```

### 4. 문서화 단계
```bash
# API 문서 자동 생성
$ gemini "문서화: src/auth/ 모듈의 API 문서 작성"
```

## 🎯 AI 활용 베스트 프랙티스

### ✅ DO (권장)

1. **명확한 제약사항 명시**
   ```
   - 포트 범위: 프로젝트당 10개 (자동 할당)
   - 데이터베이스: PostgreSQL (공유 인스턴스)
   - 환경변수는 반드시 .env에서 읽기
   ```

2. **기존 패턴 참조**
   ```
   projects/example-project의 구조를 따라서 새 프로젝트를 생성해주세요.
   ```

3. **출력 형식 지정**
   ```
   출력:
   1. SQL 마이그레이션 파일 (migrations/xxx-create-users.sql)
   2. TypeORM Entity (src/entities/User.ts)
   3. GraphQL Schema (src/schema/user.graphql)
   ```

4. **검증 요청**
   ```
   생성된 코드가 다음을 만족하는지 검증해주세요:
   - TypeScript strict mode 준수
   - GraphQL naming convention 준수
   - 환경변수 누락 없음
   ```

### ❌ DON'T (비권장)

1. **모호한 요청**
   ```
   ❌ "사용자 관리 기능 만들어줘"
   ✅ "JWT 인증 포함 사용자 CRUD GraphQL API 생성 (User 테이블: id, email, password, role)"
   ```

2. **컨텍스트 없는 질문**
   ```
   ❌ "이 코드 수정해줘"
   ✅ "src/auth/auth.service.ts의 login 메서드에서 비밀번호 검증 로직 추가"
   ```

3. **포트/환경변수 하드코딩 요청**
   ```
   ❌ "포트 3000으로 설정해줘"
   ✅ "환경변수 ${PROJECT_API_PORT}를 사용하여 서버 포트 설정"
   ```

## 🔧 프로젝트별 AI 컨텍스트 파일

각 프로젝트에 `.claude/context.md` 파일 생성:

```markdown
# Project Context for AI

## Project Info
- Name: user-management
- Platform: ${PLATFORM_NAME}
- Ports: ${PROJECT_PORT_START} - ${PROJECT_PORT_END}

## Tech Stack
- Backend: Node.js + TypeScript + GraphQL
- Database: PostgreSQL (포트 ${PLATFORM_POSTGRES_PORT})
- Frontend: Next.js (포트 ${PROJECT_FRONTEND_PORT})

## Database Tables
- users (id, email, password, role, created_at)
- sessions (id, user_id, token, expires_at)

## Environment Variables
- JWT_SECRET: JWT 서명용 시크릿
- DATABASE_URL: PostgreSQL 연결 문자열

## Coding Conventions
- GraphQL naming: camelCase for fields, PascalCase for types
- File naming: kebab-case
- Functions: async/await (no callbacks)
```

## 📚 AI 학습 자료 제공

### docs/examples/ 참조
AI가 학습할 수 있도록 예제 코드 제공:

```bash
docs/examples/
├── graphql-crud/           # GraphQL CRUD 예제
├── authentication/         # JWT 인증 예제
├── database-migration/     # 마이그레이션 예제
└── nextjs-integration/     # Next.js 통합 예제
```

### 템플릿 활용
```
_templates/project/ 의 템플릿을 사용하여 새 프로젝트를 생성해주세요.
변경사항: GraphQL schema에 Comment 타입 추가
```

## 🚨 주의사항

### 보안
- **절대 비밀번호/토큰을 프롬프트에 포함하지 마세요**
- 환경변수 이름만 참조 (예: `JWT_SECRET 환경변수 사용`)

### 포트 충돌 방지
- 포트는 반드시 자동 할당 시스템 사용
- 프로젝트별로 `/manager/scripts/port-allocator.js` 참조

### 데이터베이스
- 절대 production 데이터베이스에 직접 연결하지 마세요
- 마이그레이션은 항상 리뷰 후 적용

## 🎓 AI 학습 리소스

### 플랫폼 이해를 위한 문서
AI에게 다음 문서를 먼저 읽도록 요청:
1. `/docs/README.md` - 전체 구조 이해
2. `/docs/architecture/platform-overview.md` - 아키텍처 개요
3. `/docs/guidelines/02-development-workflow.md` - 개발 워크플로우

### 프롬프트 예시
```
먼저 다음 문서를 읽어주세요:
- /docs/architecture/platform-overview.md
- /docs/guidelines/02-development-workflow.md

그 다음, 새로운 GraphQL API 프로젝트를 생성해주세요.
```

## 📊 AI 활용 성과 측정

### 추적할 메트릭
- 코드 생성 시간 vs 수동 작성 시간
- AI 생성 코드의 리뷰 통과율
- AI 도구별 만족도 (1-5점)

### 개선 사이클
1. AI 활용 → 2. 결과 검토 → 3. 프롬프트 개선 → 4. 가이드라인 업데이트
