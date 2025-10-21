# AI Collaboration Guidelines

This document provides guidelines for development using AI tools such as Claude Code, Codex CLI, and Gemini CLI.

> **Language**: For Korean version, see [01-ai-collaboration.kr.md](./01-ai-collaboration.kr.md)

## 🤖 AI Tool Utilization Strategy

### Supported AI Tools
- **Claude Code**: Overall architecture design, complex logic implementation, refactoring
- **Codex CLI**: Quick code snippet generation, function implementation
- **Gemini CLI**: Documentation, code review, test case generation

### AI Tool Selection Criteria

| Task Type | Recommended Tool | Reason |
|-----------|------------------|--------|
| Overall system design | Claude Code | Complex context understanding |
| GraphQL Schema design | Claude Code | Type system understanding and relationship setup |
| CRUD API generation | Codex CLI | Fast generation of repetitive patterns |
| Database migration | Claude Code | Data integrity consideration required |
| Test code writing | Gemini CLI | Diverse edge case generation |
| Documentation | Gemini CLI | Natural documentation writing |
| Debugging | Claude Code | Complex problem analysis capability |

## 📝 Writing Effective Prompts

### Providing Context
Provide sufficient context to AI:

```
This platform is a metadata-driven development environment.
- Tech Stack: Node.js, PostgreSQL, GraphQL, Next.js
- Port Range: ${PLATFORM_PORT_START} - ${PLATFORM_PORT_END}
- Database: PostgreSQL (port ${PLATFORM_POSTGRES_PORT})

Please perform the following task:
[Specific task description]
```

### Referencing Project Structure
```
Refer to the structure in /docs/architecture/ folder,
and create a new project.
- Project name: user-management
- Include GraphQL API
- Auto-generate PostgreSQL schema
```

### Step-by-Step Task Requests
Break complex tasks into steps:

```
Step 1: Define GraphQL schema (User, Role tables)
Step 2: Generate TypeORM entities
Step 3: Implement resolvers
Step 4: Write test code
```

## 🔄 AI Collaboration Workflow

### 1. Design Phase
```bash
# Architecture design using Claude Code
$ claude-code "Design: User authentication system (JWT + PostgreSQL)"
```

**Prompt Example:**
```
Design a JWT-based authentication system for ${PLATFORM_NAME} platform.

Requirements:
1. PostgreSQL users table design
2. JWT token generation/validation logic
3. GraphQL mutations: login, register, refreshToken
4. Environment variable: JWT_SECRET (already configured)

Output format:
- Database schema (SQL)
- GraphQL schema definition
- Folder structure
```

### 2. Implementation Phase
```bash
# Implement code based on generated design
$ claude-code "Implement: Generate code based on /docs/architecture/auth-design.md"
```

### 3. Testing Phase
```bash
# Generate test cases with Gemini
$ gemini "Test: All methods in src/auth/auth.service.ts"
```

### 4. Documentation Phase
```bash
# Auto-generate API documentation
$ gemini "Document: Write API documentation for src/auth/ module"
```

## 🎯 AI Best Practices

### ✅ DO (Recommended)

1. **Specify Clear Constraints**
   ```
   - Port range: 10 ports per project (auto-allocated)
   - Database: PostgreSQL (shared instance)
   - Environment variables must be read from .env
   ```

2. **Reference Existing Patterns**
   ```
   Create a new project following the structure of projects/example-project.
   ```

3. **Specify Output Format**
   ```
   Output:
   1. SQL migration file (migrations/xxx-create-users.sql)
   2. TypeORM Entity (src/entities/User.ts)
   3. GraphQL Schema (src/schema/user.graphql)
   ```

4. **Request Validation**
   ```
   Please validate that the generated code satisfies:
   - TypeScript strict mode compliance
   - GraphQL naming convention compliance
   - No missing environment variables
   ```

### ❌ DON'T (Not Recommended)

1. **Vague Requests**
   ```
   ❌ "Create user management feature"
   ✅ "Generate user CRUD GraphQL API with JWT authentication (User table: id, email, password, role)"
   ```

2. **Questions Without Context**
   ```
   ❌ "Fix this code"
   ✅ "Add password validation logic to the login method in src/auth/auth.service.ts"
   ```

3. **Requesting Hardcoded Ports/Environment Variables**
   ```
   ❌ "Set port to 3000"
   ✅ "Configure server port using environment variable ${PROJECT_API_PORT}"
   ```

## 🔧 Project-Specific AI Context Files

Create `.claude/context.md` file in each project:

```markdown
# Project Context for AI

## Project Info
- Name: user-management
- Platform: ${PLATFORM_NAME}
- Ports: ${PROJECT_PORT_START} - ${PROJECT_PORT_END}

## Tech Stack
- Backend: Node.js + TypeScript + GraphQL
- Database: PostgreSQL (port ${PLATFORM_POSTGRES_PORT})
- Frontend: Next.js (port ${PROJECT_FRONTEND_PORT})

## Database Tables
- users (id, email, password, role, created_at)
- sessions (id, user_id, token, expires_at)

## Environment Variables
- JWT_SECRET: Secret for JWT signing
- DATABASE_URL: PostgreSQL connection string

## Coding Conventions
- GraphQL naming: camelCase for fields, PascalCase for types
- File naming: kebab-case
- Functions: async/await (no callbacks)
```

## 📚 Providing AI Learning Materials

### Reference docs/examples/
Provide example code for AI to learn from:

```bash
docs/examples/
├── graphql-crud/           # GraphQL CRUD example
├── authentication/         # JWT authentication example
├── database-migration/     # Migration example
└── nextjs-integration/     # Next.js integration example
```

### Using Templates
```
Use the template in _templates/project/ to create a new project.
Changes: Add Comment type to GraphQL schema
```

## 🚨 Precautions

### Security
- **NEVER include passwords/tokens in prompts**
- Reference only environment variable names (e.g., `use JWT_SECRET environment variable`)

### Port Collision Prevention
- Always use the automatic port allocation system
- Reference `/manager/scripts/port-allocator.js` for each project

### Database
- NEVER connect directly to production database
- Always apply migrations after review

## 🎓 AI Learning Resources

### Documents for Platform Understanding
Ask AI to read these documents first:
1. `/docs/README.md` - Overall structure understanding
2. `/docs/architecture/platform-overview.md` - Architecture overview
3. `/docs/guidelines/02-development-workflow.md` - Development workflow

### Prompt Example
```
Please first read the following documents:
- /docs/architecture/platform-overview.md
- /docs/guidelines/02-development-workflow.md

Then, create a new GraphQL API project.
```

## 📊 Measuring AI Utilization Performance

### Metrics to Track
- Code generation time vs manual writing time
- Review pass rate of AI-generated code
- Satisfaction by AI tool (1-5 scale)

### Improvement Cycle
1. Use AI → 2. Review results → 3. Improve prompts → 4. Update guidelines

---

**Last Updated**: 2024-10-19
**Version**: 1.0.0
