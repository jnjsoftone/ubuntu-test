# Platform Architecture Overview

> **Language**: For Korean version, see [01-platform-overview.kr.md](./01-platform-overview.kr.md)

## 🏗️ Overall Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ${PLATFORM_NAME} Platform                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │  Project 1    │  │  Project 2    │  │  Project 3    │      │
│  │  (Ports:      │  │  (Ports:      │  │  (Ports:      │      │
│  │  21XXX-21XXX) │  │  21XXX-21XXX) │  │  21XXX-21XXX) │      │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘      │
│          │                  │                  │                │
│  ────────┴──────────────────┴──────────────────┴────────        │
│          │           Shared Infrastructure     │                │
│  ────────┴──────────────────────────────────────────────        │
│          │                                     │                │
│  ┌───────▼───────┐  ┌──────────────┐  ┌───────▼───────┐       │
│  │  PostgreSQL   │  │     N8N      │  │     MySQL     │       │
│  │  (${PLATFORM_POSTGRES_PORT})  │  │  (${PLATFORM_N8N_PORT}) │  │  (${PLATFORM_MYSQL_PORT})  │       │
│  └───────────────┘  └──────────────┘  └───────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Core Concepts

### 1. Domain-Based Isolation
- Each domain (area) is configured as an independent platform
- Each platform has dedicated database servers and N8N instance
- Examples: `ubuntu-ilmac`, `ubuntu-jnj`, `ubuntu-kmc`

### 2. Project Isolation
- Each project is assigned an independent port range (20 ports)
- Dedicated database per project (within shared DB server)
- Independent Git repository

### 3. Automated Port Management
- Platform: 200 port range
- Project: 20 ports (Production 10 + Development 10)
- Auto-allocation system to prevent conflicts

## 📊 Port Allocation System

### Platform Level
```
Platform SN = 0, 1, 2, ...
Base Port = 21000 + (SN × 200)

Examples:
- Platform 0: 21000-21199
- Platform 1: 21200-21399
- Platform 2: 21400-21599
```

### Project Level
```
Project SN = 0, 1, 2, ... (within platform)
Project Base Port = Platform Base Port + (Project SN × 20)

Example (Platform 1, Project 0):
- Base: 21200 + (0 × 20) = 21200
- Ports: 21200-21219
  - Production: 21200-21209
  - Development: 21210-21219
```

### Port Offsets by Service

**Production (0-9)**:
- 0: SSH
- 1: Backend Node.js
- 2: Backend Python
- 3: API GraphQL
- 4: API REST
- 5: API Reserved
- 6: Frontend Next.js
- 7: Frontend SvelteKit
- 8: Frontend Reserved
- 9: System Reserved

**Development (10-19)**: Production + 10

## 🗃️ Database Architecture

### Shared Instance Strategy
```
┌─────────────────────────────────────┐
│   PostgreSQL Instance               │
│   (Port: ${PLATFORM_POSTGRES_PORT}) │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────────────────────┐  │
│  │ platform_metadata            │  │  ← Platform metadata
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ project_user_management      │  │  ← Project 1 DB
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ project_blog                 │  │  ← Project 2 DB
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ project_ecommerce            │  │  ← Project 3 DB
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### Database Naming Convention
- Platform metadata: `platform_metadata`
- Project DB: `project_${PROJECT_NAME}`
- Examples: `project_user_management`, `project_blog`

## 🔄 Metadata-Driven Development Flow

```mermaid
graph LR
    A[Define Metadata] --> B[Auto-generate Code]
    B --> C[TypeORM Entities]
    B --> D[GraphQL Schema]
    B --> E[Resolvers]
    B --> F[Services]
    B --> G[Migrations]
    C --> H[Add Custom Logic]
    D --> H
    E --> H
    F --> H
    H --> I[Test]
    I --> J[Deploy]
```

### Metadata Structure
```json
{
  "tableName": "users",
  "columns": [
    { "name": "id", "type": "uuid", "primaryKey": true },
    { "name": "email", "type": "varchar", "unique": true },
    { "name": "role", "type": "enum", "enum": ["USER", "ADMIN"] }
  ],
  "relationships": [
    { "type": "one-to-many", "target": "posts", "foreignKey": "user_id" }
  ]
}
```

### Auto-Generated Code
1. **TypeORM Entities**: Database models
2. **GraphQL Schema**: API schema definition
3. **Resolvers**: GraphQL query/mutation handlers
4. **Services**: Business logic (CRUD)
5. **Migrations**: DB schema migrations

## 🛠️ Tech Stack

### Backend
- **Runtime**: Node.js (TypeScript)
- **API**: GraphQL (Apollo Server)
- **ORM**: TypeORM
- **Database**: PostgreSQL (primary), MySQL (optional)

### Frontend
- **Framework**: Next.js (App Router)
- **UI**: React 19
- **Styling**: Tailwind CSS 4

### Infrastructure
- **Containerization**: Docker
- **Automation**: N8N
- **Reverse Proxy**: Nginx (platform level)
- **SSL**: Certbot (platform level)

### Development Tools
- **AI Assistants**: Claude Code, Codex CLI, Gemini CLI
- **IDE**: VS Code / Cursor (persistent server config)
- **Version Control**: Git + GitHub

## 📁 Directory Structure

### Platform Level
```
platforms/${PLATFORM_NAME}/
├── docker-compose.yml        # Infrastructure service definition
├── .env                      # Platform environment variables
├── configs/                  # Configuration files
│   ├── .bashrc
│   ├── ide/                 # VS Code/Cursor server settings
│   ├── n8n_data/            # N8N workflow data
│   └── google-chrome/       # Chrome user data
├── projects/                 # Projects
│   ├── cp.sh                # Project creation script
│   ├── project-1/
│   ├── project-2/
│   └── project-3/
├── scripts/                  # Automation scripts
├── docs/                     # Documentation
└── README.md
```

### Project Level
```
projects/${PROJECT_NAME}/
├── .env                      # Project environment variables
├── docker-compose.yml        # Project services (if needed)
├── backend/
│   ├── nodejs/              # Node.js backend
│   │   ├── src/
│   │   │   ├── entities/    # TypeORM entities
│   │   │   ├── schema/      # GraphQL schemas
│   │   │   ├── resolvers/   # GraphQL resolvers
│   │   │   ├── services/    # Business logic
│   │   │   └── index.ts
│   │   ├── tests/
│   │   └── package.json
│   └── python/              # Python backend (optional)
├── frontend/
│   └── nextjs/              # Next.js frontend
│       ├── src/
│       │   ├── app/         # App Router
│       │   ├── components/  # React components
│       │   └── lib/         # Utilities
│       └── package.json
├── migrations/              # Database migrations
├── metadata/                # Metadata definitions
│   ├── tables/
│   │   ├── users.json
│   │   └── posts.json
│   └── schema.json
└── README.md
```

## 🚀 Key Features

### 1. Automatic Port Allocation
- No manual port configuration needed
- Collision prevention
- Consistent port mapping across environments

### 2. Metadata-Driven Code Generation
- Define schema once, generate code everywhere
- 80%+ boilerplate code automation
- Consistent code quality

### 3. AI-Powered Development
- Claude Code for architecture design
- Codex CLI for rapid code generation
- Gemini CLI for documentation and testing

### 4. Isolated Development Environments
- Each project completely isolated
- Independent dependencies
- No version conflicts

### 5. Shared Infrastructure
- Cost-effective resource usage
- Centralized database management
- Platform-wide automation (N8N)

## 🔐 Environment Variables

### Platform Level (`.env`)
```bash
# Platform Info
PLATFORM_NAME=ubuntu-ilmac
PLATFORM_SN=1
BASE_PLATFORM_PORT=21200

# Database
PLATFORM_POSTGRES_PORT=21203
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Infrastructure
PLATFORM_N8N_PORT=21205
PLATFORM_MYSQL_PORT=21207
```

### Project Level (`.env`)
```bash
# Project Info
PROJECT_NAME=user-management
PROJECT_SN=0
BASE_PROJECT_PORT=21200

# Service Ports (Production)
SSH_PORT_PROD=21200
BE_NODEJS_PORT_PROD=21201
BE_PYTHON_PORT_PROD=21202
API_GRAPHQL_PORT_PROD=21203
API_REST_PORT_PROD=21204
FE_NEXTJS_PORT_PROD=21206

# Service Ports (Development)
SSH_PORT_DEV=21210
BE_NODEJS_PORT_DEV=21211
BE_PYTHON_PORT_DEV=21212
API_GRAPHQL_PORT_DEV=21213
API_REST_PORT_DEV=21214
FE_NEXTJS_PORT_DEV=21216

# Database
DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@localhost:${PLATFORM_POSTGRES_PORT}/project_user_management

# Security
JWT_SECRET=${JWT_SECRET}
```

## 📈 Scalability

### Vertical Scaling (Per Platform)
- Up to 10 projects per platform (200 ports / 20 ports per project)
- Shared database server handles multiple project databases
- N8N handles platform-wide automation

### Horizontal Scaling (Multiple Platforms)
- Up to 45 platforms (21000-30000 port range / 200 ports per platform)
- Each platform completely independent
- Cross-platform communication via API

## 🔄 Development Workflow

1. **Create Platform** → `./cu.sh -n platform-name`
2. **Create Project** → `./cp.sh -n project-name`
3. **Define Metadata** → `metadata/tables/*.json`
4. **Generate Code** → AI tools + automation scripts
5. **Develop Custom Logic** → Add business logic
6. **Test** → Unit + Integration tests
7. **Deploy** → Docker containers

## 🎯 Design Principles

1. **Separation of Concerns**: Clear boundaries between platform and projects
2. **Convention over Configuration**: Standardized structure and naming
3. **Automation First**: Minimize manual configuration
4. **AI Collaboration**: Leverage AI for repetitive tasks
5. **Developer Experience**: Focus on writing business logic, not boilerplate

---

**Last Updated**: 2024-10-19
**Version**: 1.0.0

> **See Also**:
> - [Metadata Schema](./02-metadata-schema.md) - Detailed metadata structure
> - [Development Workflow](../guidelines/02-development-workflow.md) - Complete development process
