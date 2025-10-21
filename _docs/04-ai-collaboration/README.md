# AI Collaboration

Guidelines for working with AI assistants on the ${PLATFORM_NAME} platform.

## 📚 Contents

- [Claude Code Guide](./claude-code.md) - Using Claude Code for development

## 🤖 Supported AI Tools

### Claude Code (Primary)
- **File**: [claude-code.md](./claude-code.md)
- **Use for**: Complex architecture, refactoring, code generation
- **Strengths**: Understanding context, following platform standards

### Future AI Tools
- Codex CLI: Quick code snippets
- Gemini CLI: Documentation, test cases

## 💡 Best Practices

### 1. Provide Context
Always reference relevant documentation:
```
"Generate a GraphQL API following the standards in 01-standards/graphql.md"
"Create a Next.js component following 01-standards/nextjs.md conventions"
```

### 2. Use Platform Standards
AI tools automatically follow platform standards when:
- CLAUDE.md is present in repository root
- Standards documents are in `_docs/01-standards/`
- Documentation follows established patterns

### 3. Iterative Development
- Start with high-level structure
- Refine with specific requirements
- Review and adjust AI-generated code

### 4. Code Review
Always review AI-generated code for:
- Adherence to platform standards
- Security considerations
- Performance implications
- Business logic accuracy

## 🔗 Related Documentation

- [Coding Standards](../01-standards/) - Standards AI tools follow
- [Development Workflow](../00-getting-started/development-workflow.md) - Integration with workflow
- [Examples](../05-examples/) - AI-assisted development examples

---

**Last Updated**: 2024-10-20
