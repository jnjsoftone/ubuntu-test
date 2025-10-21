# Coding Standards

All coding standards and conventions for the ${PLATFORM_NAME} platform.

> **Purpose**: This folder contains all coding standards that apply across ALL projects in the platform.

## 📚 Standards by Technology

| Standard | Description | Primary Audience |
|----------|-------------|------------------|
| [GraphQL](./graphql.md) | Complete GraphQL standards (design + naming) | All developers |
| [REST API](./rest-api.md) | REST API design patterns and conventions | Backend developers |
| [TypeScript](./typescript.md) | TypeScript coding standards | All developers |
| [Next.js](./nextjs.md) | Next.js 15+ conventions and best practices | Frontend developers |
| [Database](./database.md) | Database schema, TypeORM, migrations | Backend developers |

## 🎯 Quick Reference

### GraphQL Development
- **Naming**: Domain-centric pattern (`{domain}{Entity}{Action}`)
- **Example**: `noticesAll`, `bidCreate`, `boardsPostsAll`
- **File**: [graphql.md](./graphql.md)

### REST API Development
- **Pattern**: `/api/v1/{resource}/{id}`
- **Methods**: Use semantic HTTP verbs (GET, POST, PUT, DELETE, PATCH)
- **File**: [rest-api.md](./rest-api.md)

### TypeScript
- **Strict mode**: Always enabled
- **Naming**: camelCase for variables, PascalCase for types
- **File**: [typescript.md](./typescript.md)

### Next.js
- **Version**: 15.5.4+ (App Router)
- **React**: 19+
- **File**: [nextjs.md](./nextjs.md)

### Database
- **ORM**: TypeORM
- **Naming**: snake_case for tables/columns
- **Migrations**: Always version controlled
- **File**: [database.md](./database.md)

## 🔄 How to Use These Standards

### For New Developers
1. Start with [TypeScript Standards](./typescript.md) - foundation for all code
2. Read [GraphQL Standards](./graphql.md) OR [REST API Standards](./rest-api.md) depending on your API choice
3. If working on frontend: [Next.js Standards](./nextjs.md)
4. If working on backend: [Database Standards](./database.md)

### For Code Reviews
Use these standards as checklists when reviewing pull requests:
- TypeScript code follows type safety rules
- GraphQL queries follow domain-centric naming
- REST endpoints follow URL conventions
- Database migrations are properly versioned

### For AI Assistants (Claude Code)
These documents provide the complete context needed for code generation:
- Claude Code reads these standards before generating code
- All generated code automatically follows these conventions
- Standards are referenced in code comments

## 📖 Language Versions

- **English** (`.md`): Concise, optimized for AI reading
- **Korean** (`.kr.md`): Detailed, for Korean-speaking developers

## 🔗 Related Documentation

- [Platform Architecture](../02-architecture/platform-overview.md) - How the platform is structured
- [Getting Started](../00-getting-started/development-workflow.md) - Development workflow
- [Examples](../05-examples/) - Practical implementation examples

---

**Last Updated**: 2024-10-20
**Version**: 2.0.0 (Reorganized)
