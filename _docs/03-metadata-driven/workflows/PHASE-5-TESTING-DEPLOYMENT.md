# Phase 5: 테스트 및 배포 - Claude Code 프롬프트

> 통합 테스트, E2E 테스트, 배포 단계

## 5.1 Backend 테스트

### 프롬프트 5-1: GraphQL API 테스트

```
GraphQL API에 대한 통합 테스트를 작성해주세요:

테스트 프레임워크: Jest + Supertest

파일 구조:
- backend/tests/setup.ts
- backend/tests/auth.test.ts
- backend/tests/users.test.ts
- backend/tests/roles.test.ts

테스트 시나리오:

1. 인증 테스트 (auth.test.ts)
   - 회원가입 성공
   - 회원가입 실패 (이메일 중복)
   - 로그인 성공
   - 로그인 실패 (잘못된 비밀번호)
   - 토큰 갱신
   - 로그아웃

2. 사용자 테스트 (users.test.ts)
   - 사용자 목록 조회 (admin)
   - 사용자 상세 조회
   - 사용자 생성 (admin)
   - 사용자 수정
   - 사용자 삭제 (admin)
   - 권한 없는 접근 (403)

3. 역할 테스트 (roles.test.ts)
   - 역할 목록 조회
   - 역할 할당
   - 역할 제거

환경:
- 테스트 DB: auth_test
- 각 테스트 전 DB 초기화
```

**예상 구현:**

```typescript
// backend/tests/setup.ts
import { Pool } from 'pg';
import { execSync } from 'child_process';

let testDb: Pool;

beforeAll(async () => {
  // 테스트 DB 생성
  testDb = new Pool({
    host: process.env.TEST_DB_HOST,
    port: parseInt(process.env.TEST_DB_PORT || '5432'),
    database: 'auth_test',
    user: process.env.TEST_DB_USER,
    password: process.env.TEST_DB_PASSWORD,
  });

  // 스키마 적용
  execSync('npm run migrate:test', { stdio: 'inherit' });

  // Seed 데이터 삽입
  execSync('npm run seed:test', { stdio: 'inherit' });
});

afterAll(async () => {
  await testDb.end();
});

beforeEach(async () => {
  // 각 테스트 전 데이터 초기화 (Seed 데이터 제외)
  await testDb.query('TRUNCATE TABLE users, user_roles, refresh_tokens CASCADE');
});

export { testDb };

// backend/tests/auth.test.ts
import request from 'supertest';
import { app } from '../src/index';
import { testDb } from './setup';

describe('Authentication', () => {
  describe('Register', () => {
    it('should register a new user', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              register(input: {
                email: "test@example.com"
                password: "Test@123"
                firstName: "Test"
                lastName: "User"
              }) {
                user {
                  id
                  email
                }
                accessToken
              }
            }
          `
        });

      expect(response.status).toBe(200);
      expect(response.body.data.register.user.email).toBe('test@example.com');
      expect(response.body.data.register.accessToken).toBeDefined();
    });

    it('should fail with duplicate email', async () => {
      // 첫 번째 사용자 생성
      await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              register(input: {
                email: "duplicate@example.com"
                password: "Test@123"
                firstName: "Test"
                lastName: "User"
              }) {
                user { id }
              }
            }
          `
        });

      // 같은 이메일로 재시도
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              register(input: {
                email: "duplicate@example.com"
                password: "Test@123"
                firstName: "Test"
                lastName: "User"
              }) {
                user { id }
              }
            }
          `
        });

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].extensions.code).toBe('EMAIL_ALREADY_EXISTS');
    });
  });

  describe('Login', () => {
    beforeEach(async () => {
      // 테스트 사용자 생성
      await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              register(input: {
                email: "login@example.com"
                password: "Test@123"
                firstName: "Login"
                lastName: "Test"
              }) {
                user { id }
              }
            }
          `
        });
    });

    it('should login successfully', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              login(input: {
                email: "login@example.com"
                password: "Test@123"
              }) {
                user {
                  email
                }
                accessToken
                refreshToken
              }
            }
          `
        });

      expect(response.status).toBe(200);
      expect(response.body.data.login.user.email).toBe('login@example.com');
      expect(response.body.data.login.accessToken).toBeDefined();
      expect(response.body.data.login.refreshToken).toBeDefined();
    });

    it('should fail with wrong password', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              login(input: {
                email: "login@example.com"
                password: "WrongPassword"
              }) {
                user { id }
              }
            }
          `
        });

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].extensions.code).toBe('INVALID_CREDENTIALS');
    });
  });

  describe('Token Refresh', () => {
    it('should refresh access token', async () => {
      // 로그인
      const loginResponse = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              login(input: {
                email: "login@example.com"
                password: "Test@123"
              }) {
                refreshToken
              }
            }
          `
        });

      const refreshToken = loginResponse.body.data.login.refreshToken;

      // 토큰 갱신
      const refreshResponse = await request(app)
        .post('/graphql')
        .send({
          query: `
            mutation {
              refreshToken(token: "${refreshToken}") {
                accessToken
                refreshToken
              }
            }
          `
        });

      expect(refreshResponse.status).toBe(200);
      expect(refreshResponse.body.data.refreshToken.accessToken).toBeDefined();
    });
  });
});

// backend/tests/users.test.ts
describe('Users', () => {
  let adminToken: string;
  let userToken: string;

  beforeEach(async () => {
    // Admin 사용자 생성 및 로그인
    await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation {
            register(input: {
              email: "admin@example.com"
              password: "Admin@123"
              firstName: "Admin"
              lastName: "User"
            }) {
              user { id }
            }
          }
        `
      });

    // Admin 역할 할당 (직접 DB 조작)
    const adminResult = await testDb.query(
      `SELECT id FROM users WHERE email = 'admin@example.com'`
    );
    const adminId = adminResult.rows[0].id;
    const adminRoleResult = await testDb.query(
      `SELECT id FROM roles WHERE name = 'admin'`
    );
    await testDb.query(
      `INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)`,
      [adminId, adminRoleResult.rows[0].id]
    );

    // Admin 토큰 발급
    const adminLoginResponse = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation {
            login(input: {
              email: "admin@example.com"
              password: "Admin@123"
            }) {
              accessToken
            }
          }
        `
      });
    adminToken = adminLoginResponse.body.data.login.accessToken;

    // 일반 사용자 토큰
    const userLoginResponse = await request(app)
      .post('/graphql')
      .send({
        query: `
          mutation {
            login(input: {
              email: "login@example.com"
              password: "Test@123"
            }) {
              accessToken
            }
          }
        `
      });
    userToken = userLoginResponse.body.data.login.accessToken;
  });

  describe('Query Users', () => {
    it('should allow admin to query users', async () => {
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `
            query {
              users {
                id
                email
                firstName
              }
            }
          `
        });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body.data.users)).toBe(true);
    });

    it('should deny regular user', async () => {
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          query: `
            query {
              users {
                id
              }
            }
          `
        });

      expect(response.body.errors).toBeDefined();
      expect(response.body.errors[0].extensions.code).toBe('FORBIDDEN');
    });
  });

  describe('Create User', () => {
    it('should allow admin to create user', async () => {
      const response = await request(app)
        .post('/graphql')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          query: `
            mutation {
              createUser(input: {
                email: "newuser@example.com"
                firstName: "New"
                lastName: "User"
              }) {
                id
                email
              }
            }
          `
        });

      expect(response.status).toBe(200);
      expect(response.body.data.createUser.email).toBe('newuser@example.com');
    });
  });
});
```

---

## 5.2 Frontend E2E 테스트

### 프롬프트 5-2: Playwright E2E 테스트

```
Playwright를 사용한 E2E 테스트를 작성해주세요:

설치:
npm install -D @playwright/test

파일:
- frontend/tests/e2e/auth.spec.ts
- frontend/tests/e2e/profile.spec.ts
- frontend/tests/e2e/admin.spec.ts
- playwright.config.ts

시나리오:

1. 인증 플로우 (auth.spec.ts)
   - 회원가입 → 이메일 인증 → 로그인
   - 로그아웃
   - 비밀번호 재설정

2. 프로필 관리 (profile.spec.ts)
   - 로그인 → 프로필 조회
   - 프로필 수정
   - 비밀번호 변경

3. 관리자 기능 (admin.spec.ts)
   - Admin 로그인
   - 사용자 목록 조회
   - 사용자 생성
   - 역할 할당
```

**예상 구현:**

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});

// frontend/tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  test('should complete registration flow', async ({ page }) => {
    // 회원가입 페이지 이동
    await page.goto('/register');

    // 폼 입력
    await page.fill('input[name="email"]', 'e2e@example.com');
    await page.fill('input[name="password"]', 'Test@123');
    await page.fill('input[name="confirmPassword"]', 'Test@123');
    await page.fill('input[name="firstName"]', 'E2E');
    await page.fill('input[name="lastName"]', 'Test');

    // 약관 동의
    await page.check('input[name="agreeToTerms"]');
    await page.check('input[name="agreeToPrivacy"]');

    // 제출
    await page.click('button[type="submit"]');

    // 성공 메시지 확인
    await expect(page.getByText('회원가입이 완료되었습니다')).toBeVisible();

    // 이메일 인증 페이지로 리다이렉트 확인
    await expect(page).toHaveURL('/verify-email');
  });

  test('should login successfully', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'admin@example.com');
    await page.fill('input[name="password"]', 'Admin@123');

    await page.click('button[type="submit"]');

    // 로그인 후 대시보드로 이동
    await expect(page).toHaveURL('/dashboard');
  });

  test('should logout', async ({ page }) => {
    // 먼저 로그인
    await page.goto('/login');
    await page.fill('input[name="email"]', 'admin@example.com');
    await page.fill('input[name="password"]', 'Admin@123');
    await page.click('button[type="submit"]');

    // 로그아웃
    await page.click('button[aria-label="User menu"]');
    await page.click('text=로그아웃');

    // 로그인 페이지로 리다이렉트
    await expect(page).toHaveURL('/login');
  });
});

// frontend/tests/e2e/profile.spec.ts
test.describe('Profile Management', () => {
  test.beforeEach(async ({ page }) => {
    // 로그인
    await page.goto('/login');
    await page.fill('input[name="email"]', 'admin@example.com');
    await page.fill('input[name="password"]', 'Admin@123');
    await page.click('button[type="submit"]');
  });

  test('should view profile', async ({ page }) => {
    await page.goto('/profile');

    await expect(page.getByText('admin@example.com')).toBeVisible();
  });

  test('should edit profile', async ({ page }) => {
    await page.goto('/profile');

    // 수정 탭으로 이동
    await page.click('text=프로필 수정');

    // 이름 변경
    await page.fill('input[name="firstName"]', 'Updated');

    // 저장
    await page.click('button[type="submit"]');

    // 성공 메시지
    await expect(page.getByText('프로필이 업데이트되었습니다')).toBeVisible();
  });

  test('should change password', async ({ page }) => {
    await page.goto('/profile');

    await page.click('text=비밀번호 변경');

    await page.fill('input[name="oldPassword"]', 'Admin@123');
    await page.fill('input[name="newPassword"]', 'NewAdmin@123');
    await page.fill('input[name="confirmPassword"]', 'NewAdmin@123');

    await page.click('button[type="submit"]');

    await expect(page.getByText('비밀번호가 변경되었습니다')).toBeVisible();
  });
});
```

---

## 5.3 성능 테스트

### 프롬프트 5-3: K6 성능 테스트

```
K6를 사용한 GraphQL API 성능 테스트를 작성해주세요:

설치:
brew install k6  # macOS
or
apt-get install k6  # Ubuntu

파일:
- backend/tests/performance/load-test.js

시나리오:
1. 로그인 부하 테스트
   - 100명의 가상 사용자
   - 10분간 실행

2. 사용자 조회 부하 테스트
   - 인증된 요청
   - 초당 50 requests

성능 목표:
- 95% 요청이 200ms 이내
- 에러율 1% 미만
```

**예상 구현:**

```javascript
// backend/tests/performance/load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp-up
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp-up to 200
    { duration: '5m', target: 200 }, // Stay at 200
    { duration: '2m', target: 0 },   // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'], // 95% requests < 200ms
    errors: ['rate<0.01'],             // Error rate < 1%
  },
};

const BASE_URL = 'http://localhost:4000/graphql';

export default function () {
  // 로그인
  const loginRes = http.post(BASE_URL, JSON.stringify({
    query: `
      mutation {
        login(input: {
          email: "test@example.com"
          password: "Test@123"
        }) {
          accessToken
        }
      }
    `
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  const loginSuccess = check(loginRes, {
    'login status is 200': (r) => r.status === 200,
    'login has token': (r) => JSON.parse(r.body).data.login.accessToken !== undefined,
  });

  errorRate.add(!loginSuccess);

  if (loginSuccess) {
    const token = JSON.parse(loginRes.body).data.login.accessToken;

    // 사용자 목록 조회
    const usersRes = http.post(BASE_URL, JSON.stringify({
      query: `
        query {
          users(limit: 20) {
            id
            email
            firstName
          }
        }
      `
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
    });

    const usersSuccess = check(usersRes, {
      'users status is 200': (r) => r.status === 200,
      'users has data': (r) => JSON.parse(r.body).data.users.length > 0,
    });

    errorRate.add(!usersSuccess);
  }

  sleep(1);
}
```

---

## 5.4 Docker 배포

### 프롬프트 5-4: Docker 컨테이너 설정

```
프로젝트를 Docker로 배포하기 위한 설정을 작성해주세요:

파일:
- backend/Dockerfile
- frontend/Dockerfile
- docker-compose.yml
- .dockerignore

요구사항:
1. Multi-stage build
2. Node.js 20-alpine 사용
3. 환경 변수 외부화
4. 헬스 체크 포함

환경:
- Backend: Port 4000
- Frontend: Port 3000
- PostgreSQL: 원격 서버 (연결만)
```

**예상 구현:**

```dockerfile
# backend/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# 의존성 설치
COPY package*.json ./
RUN npm ci

# 소스 복사
COPY . .

# 코드 생성
RUN npm run generate

# 빌드
RUN npm run build

# Production 이미지
FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

# 빌드 결과만 복사
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

# 헬스 체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

EXPOSE 4000

CMD ["node", "dist/index.js"]

# frontend/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# 환경 변수 (빌드 시)
ARG NEXT_PUBLIC_GRAPHQL_URL
ENV NEXT_PUBLIC_GRAPHQL_URL=$NEXT_PUBLIC_GRAPHQL_URL

RUN npm run build

# Production
FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["node", "server.js"]

# docker-compose.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "4000:4000"
    environment:
      - NODE_ENV=production
      - APP_DB_HOST=${APP_DB_HOST}
      - APP_DB_PORT=${APP_DB_PORT}
      - APP_DB_NAME=${APP_DB_NAME}
      - APP_DB_USER=${APP_DB_USER}
      - APP_DB_PASSWORD=${APP_DB_PASSWORD}
      - JWT_ACCESS_SECRET=${JWT_ACCESS_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:4000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]
      interval: 30s
      timeout: 3s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - NEXT_PUBLIC_GRAPHQL_URL=${NEXT_PUBLIC_GRAPHQL_URL}
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - backend
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - backend
      - frontend
    restart: unless-stopped
```

---

## 5.5 CI/CD 설정

### 프롬프트 5-5: GitHub Actions CI/CD

```
GitHub Actions를 사용한 CI/CD 파이프라인을 구성해주세요:

파일:
- .github/workflows/ci.yml
- .github/workflows/deploy.yml

CI 파이프라인:
1. Lint
2. Test (Backend + Frontend)
3. Build
4. E2E Test

CD 파이프라인 (main 브랜치):
1. Build Docker images
2. Push to registry
3. Deploy to server
```

**예상 구현:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  backend-test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_DB: auth_test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - name: Install dependencies
        working-directory: backend
        run: npm ci

      - name: Lint
        working-directory: backend
        run: npm run lint

      - name: Generate code
        working-directory: backend
        run: npm run generate
        env:
          METADATA_DB_HOST: ${{ secrets.METADATA_DB_HOST }}
          METADATA_DB_USER: ${{ secrets.METADATA_DB_USER }}
          METADATA_DB_PASSWORD: ${{ secrets.METADATA_DB_PASSWORD }}

      - name: Run tests
        working-directory: backend
        run: npm test
        env:
          TEST_DB_HOST: localhost
          TEST_DB_PORT: 5432
          TEST_DB_USER: test
          TEST_DB_PASSWORD: test

  frontend-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        working-directory: frontend
        run: npm ci

      - name: Lint
        working-directory: frontend
        run: npm run lint

      - name: Build
        working-directory: frontend
        run: npm run build
        env:
          NEXT_PUBLIC_GRAPHQL_URL: http://localhost:4000/graphql

  e2e-test:
    runs-on: ubuntu-latest
    needs: [backend-test, frontend-test]

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: |
          cd backend && npm ci
          cd ../frontend && npm ci

      - name: Install Playwright
        working-directory: frontend
        run: npx playwright install --with-deps

      - name: Start backend
        working-directory: backend
        run: npm start &
        env:
          NODE_ENV: test

      - name: Start frontend
        working-directory: frontend
        run: npm run dev &

      - name: Run E2E tests
        working-directory: frontend
        run: npm run test:e2e

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: frontend/playwright-report/

# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push backend
        uses: docker/build-push-action@v4
        with:
          context: ./backend
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/auth-backend:latest

      - name: Build and push frontend
        uses: docker/build-push-action@v4
        with:
          context: ./frontend
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/auth-frontend:latest
          build-args: |
            NEXT_PUBLIC_GRAPHQL_URL=${{ secrets.NEXT_PUBLIC_GRAPHQL_URL }}

      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          script: |
            cd /opt/auth-system
            docker-compose pull
            docker-compose up -d
```

---

## 5.6 모니터링 설정

### 프롬프트 5-6: 로깅 및 모니터링

```
프로덕션 환경의 로깅 및 모니터링을 설정해주세요:

도구:
- Winston (로깅)
- Prometheus + Grafana (메트릭)
- Sentry (에러 추적)

요구사항:
1. 구조화된 로깅
2. 에러 추적
3. 성능 메트릭
4. 사용자 활동 로깅
```

---

## 체크리스트

테스트 및 배포 단계 완료 전 확인사항:

- [ ] Backend 통합 테스트 작성 완료
- [ ] Frontend E2E 테스트 작성 완료
- [ ] 성능 테스트 실행 및 검증 완료
- [ ] Docker 이미지 빌드 성공
- [ ] docker-compose로 로컬 실행 확인
- [ ] CI/CD 파이프라인 설정 완료
- [ ] 프로덕션 배포 성공
- [ ] 로깅 시스템 작동 확인
- [ ] 모니터링 대시보드 설정 완료
- [ ] 에러 추적 시스템 연동 완료
- [ ] 백업 전략 수립 완료
- [ ] 보안 점검 완료
- [ ] 문서화 완료

---

## 최종 체크리스트

전체 프로젝트 완료 확인:

### 기획
- [ ] 요구사항 명세서 작성
- [ ] ERD 작성
- [ ] API 설계 문서
- [ ] 보안 정책 문서

### 모델링
- [ ] 메타데이터 DB 설정
- [ ] 모든 테이블 메타데이터 정의
- [ ] 관계 정의
- [ ] 초기 데이터 정의

### Backend
- [ ] 코드 생성 시스템 구축
- [ ] GraphQL API 구현
- [ ] 인증/권한 시스템 구현
- [ ] 테스트 작성

### Frontend
- [ ] React 컴포넌트 자동 생성
- [ ] 인증 페이지 구현
- [ ] 관리자 페이지 구현
- [ ] E2E 테스트 작성

### 배포
- [ ] Docker 컨테이너화
- [ ] CI/CD 파이프라인
- [ ] 프로덕션 배포
- [ ] 모니터링 설정

---

**축하합니다! 🎉**

메타데이터 기반 사용자 인증/권한 시스템 개발이 완료되었습니다!
