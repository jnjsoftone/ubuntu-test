# ${PLATFORM_NAME} Platform Documentation

Comprehensive documentation for ${PLATFORM_NAME} platform development with AI collaboration (Claude Code, Codex CLI, Gemini CLI) and metadata-driven development environment.

> **Language**: This documentation is available in multiple languages. For Korean version, see [README.kr.md](./README.kr.md)

## 📌 Documentation Scope

**This is PLATFORM-LEVEL documentation** - shared guidelines and standards applicable to ALL projects.

**Key Characteristics**:
- **Universal**: Standards that apply across entire platform ecosystem
- **Stable**: Changes infrequently, only when platform-wide patterns evolve
- **AI-Optimized**: English version (`.md`) written concisely for AI (Claude Code) consumption
- **Developer-Friendly**: Korean version (`.kr.md`) detailed and easy to understand
- **Copied on Platform Creation**: This `_docs/` directory is copied when creating new platforms via `cu.sh`

**Relationship to Project Documentation**:
- Platform docs (here) = **General standards and guidelines**
- Project docs (`ubuntu-project/_docs/`) = **Project-specific implementation details**
- See [CLAUDE.md](/volume1/homes/jungsam/dockers/CLAUDE.md) for complete documentation architecture

## 📚 Documentation Structure

```
_docs/
├── README.md                        # This document (documentation index)
├── 00-getting-started/              # NEW: Quick start and workflows
│   ├── README.md
│   └── development-workflow.md / .kr.md
├── 01-standards/                    # NEW: All coding standards (consolidated)
│   ├── README.md
│   ├── graphql.md / .kr.md         # GraphQL (design + naming consolidated)
│   ├── rest-api.md / .kr.md        # REST API standards
│   ├── typescript.md               # TypeScript conventions
│   ├── nextjs.md                   # Next.js best practices
│   └── database.md / .kr.md        # Database standards
├── 02-architecture/                 # Platform architecture (renamed)
│   ├── platform-overview.md / .kr.md
│   └── metadata-schema.md / .kr.md
├── 03-metadata-driven/              # Metadata-driven development (renamed)
│   ├── concepts/
│   ├── guides/
│   └── workflows/
├── 04-ai-collaboration/             # AI collaboration guides (moved)
│   ├── README.md
│   └── claude-code.md / .kr.md
├── 05-examples/                     # Practical examples (renumbered)
│   ├── README.md
│   └── simple-crud.md / .kr.md
├── 06-troubleshooting/              # Troubleshooting (renumbered)
│   ├── README.md
│   └── common-issues.md / .kr.md
└── 99-chats/                        # Chat archives (renamed)
    └── claude/
```

---

## 🚀 Quick Start

### For Beginners

1. **Understand the Platform**
   - [Platform Architecture Overview](./02-architecture/platform-overview.md) 📖
   - Core concepts: Domain isolation, automatic port allocation, metadata-driven development

2. **Setup Development Environment**
   - [Development Workflow](./00-getting-started/development-workflow.md) 🔄
   - Project creation, environment setup, code generation

3. **Review Coding Standards**
   - [All Standards](./01-standards/) - TypeScript, GraphQL, Next.js, Database
   - Start with [GraphQL](./01-standards/graphql.md) or [REST API](./01-standards/rest-api.md)

4. **Create Your First Project**
   - [Simple CRUD API Example](./05-examples/simple-crud.md) ✨
   - Complete process from metadata definition to deployment

### For Experienced Developers

- **Quick Reference**:
  - [Standards Overview](./01-standards/) - All coding standards in one place
  - [GraphQL Standards](./01-standards/graphql.md) - Complete GraphQL guide
  - [Database Standards](./01-standards/database.md) - Schema, migrations, TypeORM

- **AI Utilization**:
  - [Claude Code Guide](./04-ai-collaboration/claude-code.md) - AI-assisted development

---

## 📖 Documentation by Category

### 0️⃣ Getting Started

Quick start and development workflows

| Document | Description | Audience |
|----------|-------------|----------|
| [Development Workflow](./00-getting-started/development-workflow.md) | Complete development process | All developers |

**Start here**: Essential for all new platform users

### 1️⃣ Standards

All coding standards consolidated

| Standard | Description | Audience |
|----------|-------------|----------|
| [GraphQL](./01-standards/graphql.md) | Complete GraphQL guide (design + naming) | All developers |
| [REST API](./01-standards/rest-api.md) | REST API design patterns | Backend developers |
| [TypeScript](./01-standards/typescript.md) | TypeScript conventions | All developers |
| [Next.js](./01-standards/nextjs.md) | Next.js 15+ best practices | Frontend developers |
| [Database](./01-standards/database.md) | Database schema, TypeORM, migrations | Backend developers |

**Recommended learning order**: TypeScript → GraphQL or REST → Next.js (frontend) or Database (backend)

### 2️⃣ Architecture

Platform structure and design principles

| Document | Description | Audience |
|----------|-------------|----------|
| [Platform Overview](./02-architecture/platform-overview.md) | Architecture, port allocation, tech stack | All developers |
| [Metadata Schema](./02-architecture/metadata-schema.md) | Metadata definitions, code generation | Backend developers |

**Must Read**: Platform Overview is required for all developers

### 3️⃣ Metadata-Driven Development

Metadata-driven development concepts and workflows

| Section | Description |
|---------|-------------|
| Concepts | Core concepts of metadata-driven development |
| Guides | Step-by-step guides |
| Workflows | Common workflows and patterns |

### 4️⃣ AI Collaboration

Working with AI assistants

| Document | Description | Audience |
|----------|-------------|----------|
| [Claude Code](./04-ai-collaboration/claude-code.md) | Using Claude Code for development | All developers |

**Recommended**: Learn to leverage AI for faster development

### 5️⃣ Examples

Practical implementation examples

| Document | Description | Level |
|----------|-------------|-------|
| [Simple CRUD API](./05-examples/simple-crud.md) | Complete blog CRUD implementation | ⭐ Beginner |

**Recommended**: Follow examples for your first project

### 6️⃣ Troubleshooting

Common issues and solutions

| Document | Description | Level |
|----------|-------------|-------|
| [Common Issues](./06-troubleshooting/common-issues.md) | Ports, DB, Docker, environment variables | ⭐ Beginner |

**Tip**: Use Ctrl+F to search for error messages

---

## 🎯 Guides by Scenario

### 📝 Scenario 1: Starting New Project
```
1. Understand platform architecture
   └─ 02-architecture/platform-overview.md

2. Learn development workflow
   └─ 00-getting-started/development-workflow.md

3. Review coding standards
   └─ 01-standards/

4. Follow example
   └─ 05-examples/simple-crud.md

5. Define metadata
   └─ 02-architecture/metadata-schema.md

6. Generate code with AI
   └─ 04-ai-collaboration/claude-code.md
```

### 🔧 Scenario 2: Database Design
```
1. Learn metadata schema
   └─ 02-architecture/metadata-schema.md

2. Database standards
   └─ 01-standards/database.md

3. Check GraphQL or REST design
   └─ 01-standards/graphql.md or rest-api.md

4. If issues occur
   └─ 06-troubleshooting/common-issues.md
```

### 🤖 Scenario 3: AI-Assisted Development
```
1. Learn Claude Code usage
   └─ 04-ai-collaboration/claude-code.md

2. Review coding standards (AI follows these)
   └─ 01-standards/

3. Use metadata-driven development
   └─ 03-metadata-driven/

4. Practical application
   └─ 05-examples/
```

### 🐛 Scenario 4: Troubleshooting
```
1. Check common issues
   └─ 06-troubleshooting/common-issues.md

2. Refer to relevant documentation
   ├─ Port issues: 02-architecture/platform-overview.md
   ├─ DB issues: 01-standards/database.md
   └─ API issues: 01-standards/graphql.md or rest-api.md

3. Use AI assistance
   └─ 04-ai-collaboration/claude-code.md

4. If still unresolved
   └─ Contact platform administrator
```

---

## 🔑 Core Concepts

### Metadata-Driven Development
- **Define Metadata** → **Auto-generate Code** → **Add Custom Logic**
- Automate 80%+ of boilerplate code
- Ensure consistent code quality

### Automatic Port Allocation
- 200 ports per platform (SN × 200)
- 20 ports per project (Production 10 + Development 10)
- Collision prevention system

### AI Collaboration
- **Claude Code**: Complex architecture, refactoring
- **Codex CLI**: Quick code snippet generation
- **Gemini CLI**: Documentation, test cases

---

## 📊 Tech Stack

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
- N8N (Workflow automation)
- Nginx (Reverse Proxy)

---

## 🌐 Language Support

This documentation is available in multiple languages:

- **English** (`.md` files) - Default, AI-friendly
- **한국어/Korean** (`.kr.md` files) - For Korean developers

**Naming Convention**:
- Base file (`.md`): English version (for AI)
- Korean version: `.kr.md` suffix

**Examples**:
- `graphql.md` - English version (AI reads this)
- `graphql.kr.md` - Korean version (Korean developers read this)

---

## 📞 Help

### For Documentation Questions
- Cannot understand documentation content
- Need more detailed explanation
- Examples not working

### Using AI Tools
```bash
# Read documentation with Claude Code
claude-code "Read docs/architecture/01-platform-overview.md and summarize"

# Ask specific questions
claude-code "Explain port allocation system (refer to docs/architecture/01-platform-overview.md)"
```

### Platform Administrator
- Technical issues
- Platform configuration changes
- Permission-related issues

---

## 🌟 Next Steps

After reading the documentation:

1. ✅ Follow [Simple CRUD API](./examples/01-simple-crud.md) example
2. ✅ Define metadata for your own project
3. ✅ Generate code with AI tools
4. ✅ Add custom logic
5. ✅ Share knowledge with other developers

**Happy Coding! 🚀**

---

**Last Updated**: 2024-10-19
**Version**: 1.0.0
