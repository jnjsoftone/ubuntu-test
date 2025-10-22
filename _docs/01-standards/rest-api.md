# REST API Design Guide

This document defines REST API design principles and patterns for the ${PLATFORM_NAME} platform.

## 🎯 Design Principles

### 1. RESTful Architecture
- Resource-based URL structure
- Semantic use of HTTP methods (GET, POST, PUT, DELETE, PATCH)
- Stateless communication
- Layered system architecture

### 2. Consistency
- Standardized response format
- Consistent error handling
- Unified naming conventions
- Version management strategy

### 3. Clarity
- Self-explanatory endpoint names
- Clear HTTP status code usage
- Comprehensive API documentation (Swagger/OpenAPI)

## 📐 URL Structure

### Basic Pattern

```
{protocol}://{host}:{port}/api/{version}/{resource}/{identifier}/{sub-resource}
```

**Examples**:
```
http://localhost:20101/api/v1/platforms
http://localhost:20101/api/v1/platforms/ubuntu-ilmac
http://localhost:20101/api/v1/platforms/ubuntu-ilmac/projects
http://localhost:20101/api/v1/projects/my-web-app
```

### URL Naming Conventions

**Resource Names**:
- Use plural nouns (`/platforms`, `/projects`, `/users`)
- Lowercase with hyphens (`/git-users`, `/database-configs`)
- No verbs (`/createUser` ❌ → `/users` ✅)

**Path Parameters**:
- Use kebab-case (`platform-id`, `project-name`)
- Clear identifiers (`/platforms/{id}`, `/projects/{projectId}`)

**Query Parameters**:
- Use camelCase (`?pageSize=20`, `?sortOrder=desc`)
- For filtering, sorting, and pagination

## 🌐 HTTP Methods

### GET - Read
```typescript
// List all resources
GET /api/platforms
Response: 200 OK
{
  "success": true,
  "data": [...]
}

// Get single resource
GET /api/platforms/{id}
Response: 200 OK
{
  "success": true,
  "data": { "id": "...", "name": "..." }
}

// Get sub-resources
GET /api/platforms/{id}/projects
Response: 200 OK
{
  "success": true,
  "data": [...]
}

// Resource not found
GET /api/platforms/{id}
Response: 404 Not Found
{
  "success": false,
  "error": "Platform not found"
}
```

### POST - Create
```typescript
// Create new resource
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

// Validation failure
Response: 400 Bad Request
{
  "success": false,
  "error": "Name and githubUser are required"
}

// Duplicate resource
Response: 409 Conflict
{
  "success": false,
  "error": "Platform with this name already exists"
}
```

### PUT - Full Update
```typescript
// Replace entire resource
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

// Resource not found
Response: 404 Not Found
{
  "success": false,
  "error": "Platform not found"
}
```

### PATCH - Partial Update
```typescript
// Update specific fields
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

### DELETE - Remove
```typescript
// Delete resource
DELETE /api/platforms/{id}

Response: 200 OK
{
  "success": true,
  "message": "Platform deleted successfully"
}

// Or 204 No Content (no body)
Response: 204 No Content

// Resource not found
Response: 404 Not Found
{
  "success": false,
  "error": "Platform not found"
}
```

## 📊 Response Format

### Standard Response Structure

All API responses follow a consistent format:

```typescript
interface ApiResponse<T = any> {
  success: boolean;      // Request success status
  data?: T;             // Response data (on success)
  error?: string;       // Error message (on failure)
  message?: string;     // Success message (optional)
}
```

**Success Response**:
```json
{
  "success": true,
  "data": {
    "id": "platform-1",
    "name": "ubuntu-dev"
  }
}
```

**Error Response**:
```json
{
  "success": false,
  "error": "Resource not found"
}
```

**Creation Success Response**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Resource created successfully"
}
```

### Paginated Response

```typescript
interface PaginatedResponse<T> {
  success: boolean;
  data: T[];
  pagination: {
    page: number;         // Current page (1-based)
    limit: number;        // Items per page
    total: number;        // Total items
    totalPages: number;   // Total pages
  };
}
```

**Example**:
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

## 🔍 Query Parameters

### Pagination

```
GET /api/platforms?page=1&limit=20
```

**Parameters**:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `offset`: Offset (alternative: `offset=0&limit=20`)

### Sorting

```
GET /api/platforms?sortBy=createdAt&sortOrder=desc
```

**Parameters**:
- `sortBy`: Sort field
- `sortOrder`: Sort direction (`asc`, `desc`)

**Multiple Sort**:
```
GET /api/platforms?sort=name:asc,createdAt:desc
```

### Filtering

```
GET /api/platforms?status=active&githubUser=myuser
GET /api/projects?platformId=ubuntu-dev&status=production
```

**Operators**:
```
GET /api/platforms?createdAt[gte]=2024-01-01&createdAt[lte]=2024-12-31
```

Supported operators:
- `eq`: equals (default)
- `ne`: not equals
- `gt`: greater than
- `gte`: greater than or equal
- `lt`: less than
- `lte`: less than or equal
- `in`: in array
- `like`: partial match

### Search

```
GET /api/platforms?search=ubuntu
GET /api/projects?q=web-app
```

### Field Selection

```
GET /api/platforms?fields=id,name,status
GET /api/projects?include=platform,database
```

### Combined Example

```
GET /api/projects?platformId=ubuntu-dev&status=active&page=1&limit=10&sortBy=createdAt&sortOrder=desc&fields=id,name,status
```

## 🚨 HTTP Status Codes

### 2xx - Success

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 OK | Success | GET, PUT, PATCH, DELETE success |
| 201 Created | Resource created | POST success (new resource) |
| 204 No Content | Success (no body) | DELETE success (no response body) |

### 4xx - Client Errors

| Code | Meaning | Use Case |
|------|---------|----------|
| 400 Bad Request | Invalid request | Missing required fields, validation failure |
| 401 Unauthorized | Authentication required | No token, expired token |
| 403 Forbidden | Insufficient permissions | Authenticated but not authorized |
| 404 Not Found | Resource not found | Non-existent ID |
| 409 Conflict | Conflict | Duplicate resource creation |
| 422 Unprocessable Entity | Semantic error | Valid format but unprocessable |
| 429 Too Many Requests | Rate limit exceeded | Too many requests |

### 5xx - Server Errors

| Code | Meaning | Use Case |
|------|---------|----------|
| 500 Internal Server Error | Server error | Unexpected server error |
| 503 Service Unavailable | Service unavailable | Maintenance, overload |

## 🔐 Authentication/Authorization

### JWT-based Authentication

```typescript
// Login
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

// Authenticated request
GET /api/platforms
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Middleware Structure

```typescript
// Authentication middleware
app.use('/api/platforms', authenticate, platformRoutes);

// Authorization middleware
app.use('/api/admin', authenticate, authorize(['admin']), adminRoutes);
```

### Error Responses

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

## 🎨 Resource Design Patterns

### Single Resource CRUD

```typescript
// Platforms resource
GET    /api/platforms           // List all
GET    /api/platforms/{id}      // Get one
POST   /api/platforms           // Create
PUT    /api/platforms/{id}      // Full update
PATCH  /api/platforms/{id}      // Partial update
DELETE /api/platforms/{id}      // Delete
```

### Nested Resources

```typescript
// Platform's Projects (sub-resource)
GET /api/platforms/{platformId}/projects
GET /api/platforms/{platformId}/projects/{projectId}
POST /api/platforms/{platformId}/projects
PUT /api/platforms/{platformId}/projects/{projectId}
DELETE /api/platforms/{platformId}/projects/{projectId}
```

**Alternative: Independent Resource**
```typescript
// Projects as independent resource
GET /api/projects
GET /api/projects/{id}
POST /api/projects                    // include platformId in body
PUT /api/projects/{id}
DELETE /api/projects/{id}

// Filter by platform
GET /api/projects?platformId=ubuntu-dev
```

### Controller Actions (Non-CRUD Operations)

For actions that don't fit CRUD:

```typescript
// ✅ As sub-resource
POST /api/platforms/{id}/start       // Start platform
POST /api/platforms/{id}/stop        // Stop platform
POST /api/projects/{id}/deploy       // Deploy project
POST /api/projects/{id}/restart      // Restart project

// ✅ As status update (preferred)
PATCH /api/platforms/{id}
{
  "status": "running"
}

PATCH /api/projects/{id}
{
  "deploymentStatus": "deploying"
}
```

## 🔧 Error Handling

### Error Response Format

**Basic Error**:
```json
{
  "success": false,
  "error": "Platform not found"
}
```

**Detailed Error**:
```typescript
interface DetailedErrorResponse {
  success: false;
  error: {
    code: string;          // Error code (e.g., "PLATFORM_NOT_FOUND")
    message: string;       // User-friendly message
    details?: any;         // Additional info
    timestamp: string;     // Error timestamp
    path: string;         // Request path
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

### Validation Errors

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

### Error Handler Middleware

```typescript
// Express error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);

  // Include stack trace in development
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

## 📖 API Documentation (Swagger/OpenAPI)

### Swagger Setup

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
  apis: ['./src/routes/*.ts'], // Files to annotate
};

const specs = swaggerJsdoc(options);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(specs));
```

### Route Documentation

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
  // Implementation
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
  // Implementation
});
```

### Schema Definitions

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

## 🏗️ File Structure

```
src/
├── index.ts                    # Application entry point
├── routes/                     # Route handlers
│   ├── platforms.ts            # Platform endpoints
│   ├── projects.ts             # Project endpoints
│   ├── databases.ts            # Database endpoints
│   ├── servers.ts              # Server endpoints
│   ├── gitusers.ts             # Git User endpoints
│   └── scripts.ts              # Script endpoints
├── services/                   # Business logic
│   ├── platformService.ts      # Platform service
│   ├── projectService.ts       # Project service
│   └── portService.ts          # Port allocation service
├── types/                      # TypeScript type definitions
│   └── index.ts                # Common types
├── utils/                      # Utility functions
│   ├── fileStorage.ts          # File storage utils
│   └── helpers.ts              # Helper functions
├── middleware/                 # Middleware
│   ├── auth.ts                 # Authentication middleware
│   ├── validate.ts             # Validation
│   └── errorHandler.ts         # Error handler
└── swagger/                    # API documentation
    └── config.ts               # Swagger configuration
```

## 🧪 Testing

### Endpoint Testing (Jest + Supertest)

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

## 🔒 Security Best Practices

### 1. Input Validation

```typescript
import { body, param, query, validationResult } from 'express-validator';

// Validation rules
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

// Apply to route
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

  // Processing logic
});
```

### 2. CORS Configuration

```typescript
import cors from 'cors';

// Environment-based CORS
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
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // max 100 requests
  message: {
    success: false,
    error: 'Too many requests, please try again later.'
  }
});

app.use('/api/', apiLimiter);

// Stricter limit (login, etc.)
const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5
});

app.use('/api/auth/login', strictLimiter);
```

### 4. Helmet (Security Headers)

```typescript
import helmet from 'helmet';

// Enable only in production
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

### 5. Request Size Limits

```typescript
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
```

## 📊 Performance Optimization

### 1. Caching

```typescript
import NodeCache from 'node-cache';

// Memory cache
const cache = new NodeCache({ stdTTL: 600 }); // 10min TTL

router.get('/platforms', async (req, res) => {
  const cacheKey = 'platforms:all';

  // Check cache
  const cached = cache.get(cacheKey);
  if (cached) {
    return res.json({
      success: true,
      data: cached,
      cached: true
    });
  }

  // Fetch data
  const platforms = await PlatformService.getAllPlatforms();

  // Store in cache
  cache.set(cacheKey, platforms);

  res.json({ success: true, data: platforms });
});
```

### 2. Compression

```typescript
import compression from 'compression';

app.use(compression());
```

### 3. Database Optimization

```typescript
// Select only needed fields
router.get('/platforms', async (req, res) => {
  const fields = req.query.fields?.split(',') || ['id', 'name', 'status'];
  const platforms = await PlatformService.getAllPlatforms(fields);
  res.json({ success: true, data: platforms });
});
```

## 🔗 Related Documents

- [GraphQL API Design Guide](./01-graphql-design.md) - GraphQL API design principles
- [Coding Conventions](../guidelines/04-coding-conventions.md) - TypeScript coding standards
- [Development Workflow](../guidelines/02-development-workflow.md) - API development process
- [Metadata Schema](../architecture/02-metadata-schema.md) - Metadata-based design

## 📚 References

- [REST API Design Best Practices](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/)
- [HTTP Status Codes](https://httpstatuses.com/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Express.js Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)

---

**Last Updated**: 2024-10-19
**Version**: 1.0.0

> **Note**: This document is the standard guide for REST API design.
> Based on the _manager API implementation.
