# REST API 설계 가이드

이 문서는 ${PLATFORM_NAME} 플랫폼에서의 REST API 설계 원칙과 패턴을 정의합니다.

## 🎯 설계 원칙

### 1. RESTful 아키텍처
- 리소스 기반 URL 구조
- HTTP 메서드의 의미론적 사용 (GET, POST, PUT, DELETE, PATCH)
- 무상태(Stateless) 통신
- 계층적 시스템 구조

### 2. 일관성 (Consistency)
- 표준화된 응답 형식
- 일관된 에러 처리
- 통일된 네이밍 규칙
- 버전 관리 전략

### 3. 명확성 (Clarity)
- 자명한 엔드포인트 이름
- 명확한 HTTP 상태 코드 사용
- 포괄적인 API 문서화 (Swagger/OpenAPI)

## 📐 URL 구조

### 기본 패턴

```
{protocol}://{host}:{port}/api/{version}/{resource}/{identifier}/{sub-resource}
```

**예시**:
```
http://localhost:20101/api/v1/platforms
http://localhost:20101/api/v1/platforms/ubuntu-ilmac
http://localhost:20101/api/v1/platforms/ubuntu-ilmac/projects
http://localhost:20101/api/v1/projects/my-web-app
```

### URL 네이밍 규칙

**리소스명**:
- 복수형 명사 사용 (`/platforms`, `/projects`, `/users`)
- 소문자 + 하이픈 구분 (`/git-users`, `/database-configs`)
- 동사 사용 금지 (`/createUser` ❌ → `/users` ✅)

**경로 매개변수**:
- kebab-case 사용 (`platform-id`, `project-name`)
- 명확한 식별자 (`/platforms/{id}`, `/projects/{projectId}`)

**쿼리 매개변수**:
- camelCase 사용 (`?pageSize=20`, `?sortOrder=desc`)
- 필터링, 정렬, 페이징에 사용

## 🌐 HTTP 메서드

### GET - 조회
```typescript
// 전체 리스트 조회
GET /api/platforms
Response: 200 OK
{
  "success": true,
  "data": [...]
}

// 단일 리소스 조회
GET /api/platforms/{id}
Response: 200 OK
{
  "success": true,
  "data": { "id": "...", "name": "..." }
}

// 하위 리소스 조회
GET /api/platforms/{id}/projects
Response: 200 OK
{
  "success": true,
  "data": [...]
}

// 리소스 없음
GET /api/platforms/{id}
Response: 404 Not Found
{
  "success": false,
  "error": "Platform not found"
}
```

### POST - 생성
```typescript
// 새 리소스 생성
POST /api/platforms
Content-Type: application/json
{
  "name": "ubuntu-dev",
  "description": "Development platform",
  "githubUser": "myuser"
}

Response: 201 Created
{
  "success": true,
  "data": {
    "id": "ubuntu-dev",
    "name": "ubuntu-dev",
    "createdAt": "2024-10-19T00:00:00Z",
    ...
  },
  "message": "Platform created successfully"
}

// 유효성 검증 실패
Response: 400 Bad Request
{
  "success": false,
  "error": "Name and githubUser are required"
}

// 중복 리소스
Response: 409 Conflict
{
  "success": false,
  "error": "Platform with this name already exists"
}
```

### PUT - 전체 수정
```typescript
// 리소스 전체 교체
PUT /api/platforms/{id}
Content-Type: application/json
{
  "name": "ubuntu-dev-updated",
  "description": "Updated description",
  "githubUser": "myuser"
}

Response: 200 OK
{
  "success": true,
  "data": { ... },
  "message": "Platform updated successfully"
}

// 리소스 없음
Response: 404 Not Found
{
  "success": false,
  "error": "Platform not found"
}
```

### PATCH - 부분 수정
```typescript
// 일부 필드만 수정
PATCH /api/platforms/{id}
Content-Type: application/json
{
  "description": "Updated description only"
}

Response: 200 OK
{
  "success": true,
  "data": { ... },
  "message": "Platform updated successfully"
}
```

### DELETE - 삭제
```typescript
// 리소스 삭제
DELETE /api/platforms/{id}

Response: 200 OK
{
  "success": true,
  "message": "Platform deleted successfully"
}

// 또는 204 No Content (본문 없음)
Response: 204 No Content

// 리소스 없음
Response: 404 Not Found
{
  "success": false,
  "error": "Platform not found"
}
```

## 📊 응답 형식

### 표준 응답 구조

모든 API 응답은 일관된 형식을 따릅니다:

```typescript
interface ApiResponse<T = any> {
  success: boolean;      // 요청 성공 여부
  data?: T;             // 응답 데이터 (성공 시)
  error?: string;       // 에러 메시지 (실패 시)
  message?: string;     // 성공 메시지 (선택적)
}
```

**성공 응답**:
```json
{
  "success": true,
  "data": {
    "id": "platform-1",
    "name": "ubuntu-dev"
  }
}
```

**에러 응답**:
```json
{
  "success": false,
  "error": "Resource not found"
}
```

**생성 성공 응답**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Resource created successfully"
}
```

### 페이지네이션 응답

```typescript
interface PaginatedResponse<T> {
  success: boolean;
  data: T[];
  pagination: {
    page: number;         // 현재 페이지 (1-based)
    limit: number;        // 페이지당 항목 수
    total: number;        // 전체 항목 수
    totalPages: number;   // 전체 페이지 수
  };
}
```

**예시**:
```json
{
  "success": true,
  "data": [
    { "id": "1", "name": "Platform 1" },
    { "id": "2", "name": "Platform 2" }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

## 🔍 쿼리 매개변수

### 페이지네이션

```
GET /api/platforms?page=1&limit=20
```

**매개변수**:
- `page`: 페이지 번호 (기본값: 1)
- `limit`: 페이지당 항목 수 (기본값: 20, 최대: 100)
- `offset`: 오프셋 (대안: `offset=0&limit=20`)

### 정렬

```
GET /api/platforms?sortBy=createdAt&sortOrder=desc
```

**매개변수**:
- `sortBy`: 정렬 기준 필드
- `sortOrder`: 정렬 순서 (`asc`, `desc`)

**복합 정렬**:
```
GET /api/platforms?sort=name:asc,createdAt:desc
```

### 필터링

```
GET /api/platforms?status=active&githubUser=myuser
GET /api/projects?platformId=ubuntu-dev&status=production
```

**연산자 사용**:
```
GET /api/platforms?createdAt[gte]=2024-01-01&createdAt[lte]=2024-12-31
```

지원 연산자:
- `eq`: 같음 (기본값)
- `ne`: 같지 않음
- `gt`: 초과
- `gte`: 이상
- `lt`: 미만
- `lte`: 이하
- `in`: 포함
- `like`: 부분 일치

### 검색

```
GET /api/platforms?search=ubuntu
GET /api/projects?q=web-app
```

### 필드 선택

```
GET /api/platforms?fields=id,name,status
GET /api/projects?include=platform,database
```

### 복합 예시

```
GET /api/projects?platformId=ubuntu-dev&status=active&page=1&limit=10&sortBy=createdAt&sortOrder=desc&fields=id,name,status
```

## 🚨 HTTP 상태 코드

### 2xx - 성공

| 코드 | 의미 | 사용 예시 |
|------|------|-----------|
| 200 OK | 요청 성공 | GET, PUT, PATCH, DELETE 성공 |
| 201 Created | 리소스 생성 성공 | POST 성공 (새 리소스 생성) |
| 204 No Content | 성공 (본문 없음) | DELETE 성공 (응답 본문 없음) |

### 4xx - 클라이언트 에러

| 코드 | 의미 | 사용 예시 |
|------|------|-----------|
| 400 Bad Request | 잘못된 요청 | 필수 필드 누락, 유효성 검증 실패 |
| 401 Unauthorized | 인증 필요 | 토큰 없음, 토큰 만료 |
| 403 Forbidden | 권한 없음 | 인증은 되었으나 권한 부족 |
| 404 Not Found | 리소스 없음 | 존재하지 않는 ID |
| 409 Conflict | 충돌 | 중복된 리소스 생성 시도 |
| 422 Unprocessable Entity | 처리 불가 | 의미론적 오류 (형식은 맞으나 처리 불가) |
| 429 Too Many Requests | 요청 과다 | Rate limit 초과 |

### 5xx - 서버 에러

| 코드 | 의미 | 사용 예시 |
|------|------|-----------|
| 500 Internal Server Error | 서버 내부 에러 | 예상치 못한 서버 오류 |
| 503 Service Unavailable | 서비스 불가 | 서버 점검, 과부하 |

## 🔐 인증/인가

### JWT 기반 인증

```typescript
// 로그인
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": { "id": "...", "email": "..." }
  }
}

// 인증이 필요한 요청
GET /api/platforms
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 미들웨어 구조

```typescript
// 인증 미들웨어
app.use('/api/platforms', authenticate, platformRoutes);

// 권한 확인 미들웨어
app.use('/api/admin', authenticate, authorize(['admin']), adminRoutes);
```

### 에러 응답

```typescript
// 401 Unauthorized
{
  "success": false,
  "error": "Authentication required"
}

// 403 Forbidden
{
  "success": false,
  "error": "Insufficient permissions"
}
```

## 🎨 리소스 설계 패턴

### 단일 리소스 CRUD

```typescript
// Platforms 리소스
GET    /api/platforms           // 전체 조회
GET    /api/platforms/{id}      // 단일 조회
POST   /api/platforms           // 생성
PUT    /api/platforms/{id}      // 전체 수정
PATCH  /api/platforms/{id}      // 부분 수정
DELETE /api/platforms/{id}      // 삭제
```

### 중첩 리소스

```typescript
// Platform의 Projects (하위 리소스)
GET /api/platforms/{platformId}/projects
GET /api/platforms/{platformId}/projects/{projectId}
POST /api/platforms/{platformId}/projects
PUT /api/platforms/{platformId}/projects/{projectId}
DELETE /api/platforms/{platformId}/projects/{projectId}
```

**대안: 독립 리소스**
```typescript
// 프로젝트를 독립 리소스로 처리
GET /api/projects
GET /api/projects/{id}
POST /api/projects                    // body에 platformId 포함
PUT /api/projects/{id}
DELETE /api/projects/{id}

// 필터링으로 특정 플랫폼의 프로젝트 조회
GET /api/projects?platformId=ubuntu-dev
```

### 컨트롤러 액션 (비-CRUD 작업)

리소스에 대한 액션이 CRUD로 표현하기 어려운 경우:

```typescript
// ✅ 하위 리소스로 표현
POST /api/platforms/{id}/start       // 플랫폼 시작
POST /api/platforms/{id}/stop        // 플랫폼 중지
POST /api/projects/{id}/deploy       // 프로젝트 배포
POST /api/projects/{id}/restart      // 프로젝트 재시작

// ✅ 상태 업데이트로 표현 (선호)
PATCH /api/platforms/{id}
{
  "status": "running"
}

PATCH /api/projects/{id}
{
  "deploymentStatus": "deploying"
}
```

## 🔧 에러 처리

### 에러 응답 형식

**기본 에러**:
```json
{
  "success": false,
  "error": "Platform not found"
}
```

**상세 에러**:
```typescript
interface DetailedErrorResponse {
  success: false;
  error: {
    code: string;          // 에러 코드 (예: "PLATFORM_NOT_FOUND")
    message: string;       // 사용자 친화적 메시지
    details?: any;         // 추가 정보
    timestamp: string;     // 에러 발생 시각
    path: string;         // 요청 경로
  };
}
```

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "name": "Name is required",
      "githubUser": "Invalid GitHub username format"
    },
    "timestamp": "2024-10-19T10:30:00Z",
    "path": "/api/platforms"
  }
}
```

### 유효성 검증 에러

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ]
  }
}
```

### 에러 처리 미들웨어

```typescript
// Express 에러 핸들러
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);

  // 개발 환경에서는 스택 트레이스 포함
  const errorResponse = {
    success: false,
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  };

  res.status(500).json(errorResponse);
});
```

## 📖 API 문서화 (Swagger/OpenAPI)

### Swagger 설정

```typescript
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Platform Manager API',
      version: '1.0.0',
      description: 'Platform and Project Management API',
    },
    servers: [
      {
        url: 'http://localhost:20101',
        description: 'Development server'
      }
    ],
  },
  apis: ['./src/routes/*.ts'], // 주석으로 문서화할 파일들
};

const specs = swaggerJsdoc(options);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(specs));
```

### 라우트 문서화

```typescript
/**
 * @swagger
 * /api/platforms:
 *   get:
 *     summary: Get all platforms
 *     tags: [Platforms]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *     responses:
 *       200:
 *         description: List of platforms
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
router.get('/', async (req, res) => {
  // 구현
});

/**
 * @swagger
 * /api/platforms:
 *   post:
 *     summary: Create a new platform
 *     tags: [Platforms]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreatePlatformRequest'
 *     responses:
 *       201:
 *         description: Platform created successfully
 *       400:
 *         description: Validation error
 */
router.post('/', async (req, res) => {
  // 구현
});
```

### 스키마 정의

```typescript
/**
 * @swagger
 * components:
 *   schemas:
 *     Platform:
 *       type: object
 *       required:
 *         - id
 *         - name
 *         - githubUser
 *       properties:
 *         id:
 *           type: string
 *           description: Platform unique identifier
 *         name:
 *           type: string
 *           description: Platform name
 *         description:
 *           type: string
 *           description: Platform description
 *         githubUser:
 *           type: string
 *           description: GitHub username
 *         status:
 *           type: string
 *           enum: [active, inactive, archived]
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */
```

## 🏗️ 파일 구조

```
src/
├── index.ts                    # 애플리케이션 진입점
├── routes/                     # 라우트 핸들러
│   ├── platforms.ts            # Platform 엔드포인트
│   ├── projects.ts             # Project 엔드포인트
│   ├── databases.ts            # Database 엔드포인트
│   ├── servers.ts              # Server 엔드포인트
│   ├── gitusers.ts             # Git User 엔드포인트
│   └── scripts.ts              # Script 엔드포인트
├── services/                   # 비즈니스 로직
│   ├── platformService.ts      # Platform 서비스
│   ├── projectService.ts       # Project 서비스
│   └── portService.ts          # Port 할당 서비스
├── types/                      # TypeScript 타입 정의
│   └── index.ts                # 공통 타입
├── utils/                      # 유틸리티 함수
│   ├── fileStorage.ts          # 파일 저장소 유틸
│   └── helpers.ts              # 헬퍼 함수
├── middleware/                 # 미들웨어
│   ├── auth.ts                 # 인증 미들웨어
│   ├── validate.ts             # 유효성 검증
│   └── errorHandler.ts         # 에러 핸들러
└── swagger/                    # API 문서화
    └── config.ts               # Swagger 설정
```

## 🧪 테스트

### 엔드포인트 테스트 (Jest + Supertest)

```typescript
import request from 'supertest';
import app from '../src/index';

describe('Platform API', () => {
  describe('GET /api/platforms', () => {
    it('should return all platforms', async () => {
      const response = await request(app)
        .get('/api/platforms')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get('/api/platforms?page=1&limit=10')
        .expect(200);

      expect(response.body.pagination).toBeDefined();
      expect(response.body.pagination.limit).toBe(10);
    });
  });

  describe('POST /api/platforms', () => {
    it('should create a new platform', async () => {
      const newPlatform = {
        name: 'test-platform',
        description: 'Test platform',
        githubUser: 'testuser'
      };

      const response = await request(app)
        .post('/api/platforms')
        .send(newPlatform)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(newPlatform.name);
    });

    it('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/platforms')
        .send({ name: 'test' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });
  });

  describe('GET /api/platforms/:id', () => {
    it('should return platform by id', async () => {
      const response = await request(app)
        .get('/api/platforms/ubuntu-dev')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe('ubuntu-dev');
    });

    it('should return 404 for non-existent platform', async () => {
      const response = await request(app)
        .get('/api/platforms/non-existent')
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/platforms/:id', () => {
    it('should update platform', async () => {
      const updates = {
        description: 'Updated description'
      };

      const response = await request(app)
        .put('/api/platforms/ubuntu-dev')
        .send(updates)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.description).toBe(updates.description);
    });
  });

  describe('DELETE /api/platforms/:id', () => {
    it('should delete platform', async () => {
      const response = await request(app)
        .delete('/api/platforms/test-platform')
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });
});
```

## 🔒 보안 Best Practices

### 1. 입력 유효성 검증

```typescript
import { body, param, query, validationResult } from 'express-validator';

// 유효성 검증 규칙
const createPlatformValidation = [
  body('name')
    .isString()
    .trim()
    .isLength({ min: 3, max: 50 })
    .matches(/^[a-z0-9-]+$/)
    .withMessage('Name must be lowercase alphanumeric with hyphens'),
  body('githubUser')
    .isString()
    .trim()
    .isLength({ min: 1, max: 39 }),
  body('description')
    .optional()
    .isString()
    .trim()
    .isLength({ max: 500 })
];

// 라우트에 적용
router.post('/', createPlatformValidation, async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        details: errors.array()
      }
    });
  }

  // 처리 로직
});
```

### 2. CORS 설정

```typescript
import cors from 'cors';

// 환경별 CORS 설정
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));
```

### 3. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// API rate limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100, // 최대 100개 요청
  message: {
    success: false,
    error: 'Too many requests, please try again later.'
  }
});

app.use('/api/', apiLimiter);

// 더 엄격한 제한 (로그인 등)
const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5
});

app.use('/api/auth/login', strictLimiter);
```

### 4. Helmet (보안 헤더)

```typescript
import helmet from 'helmet';

// 프로덕션 환경에서만 활성화
if (process.env.NODE_ENV === 'production') {
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"]
      }
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    }
  }));
}
```

### 5. 요청 크기 제한

```typescript
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
```

## 📊 성능 최적화

### 1. 캐싱

```typescript
import NodeCache from 'node-cache';

// 메모리 캐시
const cache = new NodeCache({ stdTTL: 600 }); // 10분 TTL

router.get('/platforms', async (req, res) => {
  const cacheKey = 'platforms:all';

  // 캐시 확인
  const cached = cache.get(cacheKey);
  if (cached) {
    return res.json({
      success: true,
      data: cached,
      cached: true
    });
  }

  // 데이터 조회
  const platforms = await PlatformService.getAllPlatforms();

  // 캐시 저장
  cache.set(cacheKey, platforms);

  res.json({ success: true, data: platforms });
});
```

### 2. 압축

```typescript
import compression from 'compression';

app.use(compression());
```

### 3. 데이터베이스 최적화

```typescript
// 필요한 필드만 선택
router.get('/platforms', async (req, res) => {
  const fields = req.query.fields?.split(',') || ['id', 'name', 'status'];
  const platforms = await PlatformService.getAllPlatforms(fields);
  res.json({ success: true, data: platforms });
});
```

## 🔗 관련 문서

- [GraphQL API 설계 가이드](./01-graphql-design.kr.md) - GraphQL API 설계 원칙
- [코딩 컨벤션](../guidelines/04-coding-conventions.kr.md) - TypeScript 코딩 표준
- [개발 워크플로우](../guidelines/02-development-workflow.kr.md) - API 개발 프로세스
- [메타데이터 스키마](../architecture/02-metadata-schema.kr.md) - 메타데이터 기반 설계

## 📚 참고 자료

- [REST API Design Best Practices](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/)
- [HTTP Status Codes](https://httpstatuses.com/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Express.js Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)

---

**최종 업데이트**: 2024-10-19
**버전**: 1.0.0

> **참고**: 이 문서는 REST API 설계의 표준 가이드입니다.
> _manager API 구현을 참고하여 작성되었습니다.
