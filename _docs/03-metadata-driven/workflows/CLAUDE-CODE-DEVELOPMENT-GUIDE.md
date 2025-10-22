# Phase 1: 기획 단계 - Claude Code 프롬프트

## 1.1 요구사항 분석 및 검증

### 프롬프트 1-1: 요구사항 검토

```
다음 사용자 인증/권한 시스템 요구사항을 검토하고 누락된 부분이나 개선점을 제안해주세요:

요구사항:
- 사용자 관리: 회원가입, 로그인, 프로필 관리
- 역할 기반 권한 관리 (RBAC): Admin, Manager, User
- JWT 기반 인증
- 이메일 인증
- 비밀번호 재설정
- 사용자 활동 로그

기술 스택:
- PostgreSQL (원격 서버)
- Backend: Node.js + TypeScript + GraphQL
- Frontend: Next.js 15 + React 19

다음 관점에서 검토해주세요:
1. 보안 측면에서 누락된 기능
2. 사용자 경험 개선 사항
3. 확장성 고려사항
4. GDPR/개인정보보호 관련 요구사항
```

**예상 Claude 응답:**
- 2FA(이중 인증) 추가 고려
- 세션 관리 및 동시 로그인 제어
- 비밀번호 정책 (복잡도, 만료)
- 계정 잠금 정책 (로그인 실패 시)
- 개인정보 동의 관리
- 사용자 데이터 삭제 요청 처리

---

### 프롬프트 1-2: 기술 스택 검증

```
다음 기술 스택으로 사용자 인증/권한 시스템을 구축하려고 합니다:

기술 스택:
- Database: PostgreSQL 14 (원격 서버 - ip: xxx.xxx.xxx.xxx)
- Backend: Node.js 20 + TypeScript + Apollo Server
- Frontend: Next.js 15.5.4 + React 19
- Auth: JWT + bcrypt
- Deployment: Docker

고려사항:
1. 이 스택의 장단점
2. 보안 관련 주의사항
3. 원격 PostgreSQL 사용 시 고려사항
4. 추가로 필요한 라이브러리나 도구
```

**예상 Claude 응답:**
- PostgreSQL 연결 풀링 설정 (pg-pool)
- JWT 라이브러리 (jsonwebtoken)
- 보안 관련: helmet, cors, rate-limiting
- 환경변수 관리: dotenv
- 데이터 검증: zod
- 원격 DB 연결: SSL/TLS 설정 필요

---

## 1.2 프로젝트 구조 설계

### 프롬프트 1-3: 프로젝트 초기 구조 생성

```
메타데이터 기반 개발을 위한 프로젝트 초기 구조를 생성해주세요:

프로젝트명: auth-system
위치: /workspace/auth-system

요구사항:
1. Backend (TypeScript + GraphQL)
   - src/generated (자동 생성 코드)
   - src/custom (커스텀 코드)
   - src/middleware (인증, 로깅 등)
   - src/utils

2. Frontend (Next.js)
   - src/generated (자동 생성 컴포넌트)
   - src/components (커스텀 컴포넌트)
   - src/hooks
   - src/lib (Apollo Client 등)

3. Database
   - migrations
   - seeds
   - scripts (코드 생성 스크립트)

4. 환경 설정 파일
   - .env.example
   - docker-compose.yml
   - package.json (workspace)

디렉토리 구조와 주요 설정 파일의 내용을 생성해주세요.
```

---

## 1.3 데이터베이스 연결 설정

### 프롬프트 1-4: PostgreSQL 원격 연결 설정

```
원격 PostgreSQL 서버 연결 설정을 도와주세요:

서버 정보:
- Host: xxx.xxx.xxx.xxx
- Port: 5432
- Database: auth_db
- User: auth_user

요구사항:
1. 안전한 연결 설정 (SSL/TLS)
2. Connection pooling 설정
3. 환경변수 관리
4. 연결 상태 모니터링
5. 에러 처리 및 재연결 로직

다음 파일들을 생성해주세요:
- backend/src/config/database.ts
- backend/.env.example
- backend/src/utils/db-health-check.ts
```

**생성될 파일 예시:**

```typescript
// backend/src/config/database.ts
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: false
  } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

export default pool;
```

---

## 1.4 보안 정책 정의

### 프롬프트 1-5: 보안 정책 문서 생성

```
사용자 인증/권한 시스템의 보안 정책 문서를 작성해주세요:

포함 내용:
1. 비밀번호 정책
   - 최소 길이, 복잡도 요구사항
   - 만료 정책
   - 재사용 제한

2. JWT 정책
   - Access Token 만료 시간
   - Refresh Token 만료 시간
   - Secret 관리

3. 계정 보안
   - 로그인 실패 시 잠금 정책
   - 세션 관리
   - IP 제한

4. 데이터 보호
   - 개인정보 암호화
   - 로그 보안
   - GDPR 준수

다음 형식으로 작성:
- docs/security-policy.md
- backend/src/config/security-config.ts
```

---

## 1.5 API 설계 초안

### 프롬프트 1-6: GraphQL API 설계

```
사용자 인증/권한 시스템을 위한 GraphQL API를 설계해주세요:

요구사항:
1. Mutation
   - 회원가입 (register)
   - 로그인 (login)
   - 로그아웃 (logout)
   - 토큰 갱신 (refreshToken)
   - 비밀번호 변경 (changePassword)
   - 비밀번호 재설정 요청 (requestPasswordReset)
   - 비밀번호 재설정 (resetPassword)
   - 이메일 인증 (verifyEmail)

2. Query
   - 현재 사용자 정보 (me)
   - 사용자 목록 (users) - Admin만
   - 사용자 상세 (user) - Admin만

3. Type
   - User
   - Role
   - AuthPayload
   - Permission

다음을 포함해서 작성:
- GraphQL 스키마 초안
- 각 API의 권한 요구사항
- 입력 검증 규칙
```

---

## 체크리스트

기획 단계 완료 전 확인사항:

- [ ] 비즈니스 요구사항 명확히 정의됨
- [ ] 기술 스택 결정 및 검증 완료
- [ ] 프로젝트 구조 설계 완료
- [ ] PostgreSQL 원격 연결 설정 완료
- [ ] 보안 정책 문서 작성 완료
- [ ] API 설계 초안 작성 완료
- [ ] 환경 변수 설정 완료
- [ ] Git 저장소 초기화 완료
