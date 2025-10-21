# Platform _docs Refactoring Plan

## Current Structure Analysis

### Current Folders
```
_docs/
├── api/                           # API design guides (GraphQL, REST)
├── architecture/                  # Platform architecture and metadata schema
├── chats/                        # AI collaboration history
├── examples/                     # Practical examples
├── guidelines/
│   ├── ai-collaboration/         # AI usage guidelines
│   ├── coding-conventions/       # Code standards (general, GraphQL, TypeScript, Next.js)
│   ├── database-management/      # Database guidelines
│   └── development/              # Development workflow
├── meta-data-driven/             # Metadata-driven development concepts
└── troubleshooting/              # Common issues
```

### Identified Issues

1. **Duplication/Overlap**:
   - GraphQL content split between `api/` and `guidelines/coding-conventions/`
   - REST content only in `api/`, missing coding conventions
   - General coding conventions overlap with specific technology conventions

2. **Unclear Categorization**:
   - `api/` focuses on design patterns
   - `guidelines/coding-conventions/` focuses on naming and code style
   - Users may not know where to look

3. **Development Phase Consideration**:
   - Not organized by when developers need the information
   - Mix of "what to do" and "how to do it"

## Proposed New Structure

### Reorganized by Development Workflow + Domain

```
_docs/
├── 00-getting-started/           # NEW: Quick start for platform usage
│   ├── README.md                 # Platform overview and navigation
│   ├── setup-checklist.md        # Initial setup steps
│   └── development-workflow.md   # MOVED from guidelines/development/
│
├── 01-standards/                 # NEW: All coding standards consolidated
│   ├── README.md                 # Standards overview
│   ├── typescript.md             # MOVED from guidelines/coding-conventions/TYPESCRIPT-CONVENTIONS.md
│   ├── nextjs.md                 # MOVED from guidelines/coding-conventions/NEXTJS-CONVENTIONS.md
│   ├── graphql.md                # CONSOLIDATED from api/ + guidelines/coding-conventions/
│   ├── rest-api.md               # MOVED from api/02-rest-design.md
│   ├── database.md               # MOVED from guidelines/database-management/
│   ├── file-naming.md            # NEW: File and folder naming conventions
│   └── code-style.md             # NEW: General code style (extracted from 01-coding-conventions.md)
│
├── 02-architecture/              # KEEP: Platform architecture
│   ├── README.md
│   ├── platform-overview.md      # RENAMED from 01-platform-overview.md
│   ├── metadata-schema.md        # RENAMED from 02-metadata-schema.md
│   └── port-allocation.md        # NEW: Detailed port allocation guide (extract from platform-overview)
│
├── 03-metadata-driven/           # RENAMED from meta-data-driven/
│   ├── README.md
│   ├── concepts/                 # KEEP
│   ├── guides/                   # KEEP
│   └── workflows/                # KEEP
│
├── 04-ai-collaboration/          # MOVED from guidelines/ai-collaboration/
│   ├── README.md
│   ├── claude-code.md            # NEW: Claude Code specific guide
│   ├── best-practices.md         # NEW: AI collaboration best practices
│   └── prompts/                  # NEW: Reusable prompt templates
│
├── 05-examples/                  # KEEP: Practical examples
│   ├── README.md
│   ├── simple-crud.md            # MOVED from examples/01-simple-crud.md
│   ├── graphql-api.md            # NEW: GraphQL API example
│   └── rest-api.md               # NEW: REST API example
│
├── 06-troubleshooting/           # KEEP: Common issues
│   ├── README.md
│   ├── common-issues.md          # MOVED from troubleshooting/01-common-issues.md
│   ├── database.md               # NEW: Database-specific troubleshooting
│   └── docker.md                 # NEW: Docker-specific troubleshooting
│
├── 99-chats/                     # RENAMED from chats/ (archives)
│   └── claude/
│
├── README.md                     # UPDATED: New structure navigation
└── QUICK-REFERENCE.md            # NEW: One-page cheat sheet
```

## Key Changes

### 1. Consolidation

**Standards (01-standards/)**:
- **GraphQL**: Merge `api/01-graphql-design.md` + `guidelines/coding-conventions/graphql.md`
  - Structure: Design Principles → Schema Patterns → Naming Conventions → Best Practices
- **REST**: Move `api/02-rest-design.md` → `01-standards/rest-api.md`
- **Database**: Move `guidelines/database-management/` → `01-standards/database.md`
- **TypeScript/Next.js**: Keep as separate files but move to standards

### 2. Better Discovery

**Getting Started (00-getting-started/)**:
- New folder for newcomers
- Contains workflow that was buried in guidelines
- Quick setup checklist

### 3. Clearer Categories

- **00-getting-started/**: "How do I start?"
- **01-standards/**: "How should I write code?"
- **02-architecture/**: "How is the platform structured?"
- **03-metadata-driven/**: "How do I use metadata?"
- **04-ai-collaboration/**: "How do I work with AI?"
- **05-examples/**: "Show me working examples"
- **06-troubleshooting/**: "Something's broken, help!"

### 4. Numbered Prefixes

- Indicates recommended learning/reference order
- Makes it clear this is platform-level documentation
- Aligns with project-level numbering (01-requirements, 02-design, etc.)

## Migration Strategy

### Phase 1: Create New Structure
1. Create new folders
2. Move files to new locations
3. Consolidate duplicated content

### Phase 2: Update Cross-References
1. Update all internal links
2. Update README.md with new structure
3. Update CLAUDE.md references

### Phase 3: Create New Content
1. Write QUICK-REFERENCE.md
2. Create setup-checklist.md
3. Split examples into separate files

### Phase 4: Update Both Language Versions
1. Apply same changes to .kr.md files
2. Ensure consistency

## Benefits

1. **Easier Navigation**: Numbered folders guide users
2. **No Duplication**: One place for each topic
3. **Development-Aligned**: Organized by when/how used
4. **Scalable**: Easy to add new standards or guides
5. **Consistent**: Mirrors project-level structure pattern

## File Consolidation Details

### graphql.md (consolidated)

**Sections to merge**:
- From `api/01-graphql-design.md`:
  - Design Principles
  - Schema Structure
  - Query/Mutation Patterns
  - Error Handling
  - Pagination
  - Performance Optimization

- From `guidelines/coding-conventions/graphql.md`:
  - Naming Conventions (Domain-Centric approach)
  - File Naming Rules
  - Query & Mutation Naming Rules
  - Examples by Domain

**New structure**:
```markdown
# GraphQL Standards

## 1. Design Principles
## 2. Schema Design Patterns
## 3. Naming Conventions
   - Domain-Centric Approach
   - File Naming
   - Query/Mutation Naming
## 4. Query & Mutation Patterns
## 5. Error Handling
## 6. Performance & Optimization
## 7. Examples
```

### database.md (consolidated)

**Merge**:
- `guidelines/database-management/01-database-management.md` → `01-standards/database.md`
- Add sections from architecture if database-specific

**Structure**:
```markdown
# Database Standards

## 1. Schema Design Principles
## 2. Naming Conventions
## 3. Migration Management
## 4. TypeORM Best Practices
## 5. Performance Optimization
## 6. Backup & Recovery
```

## Timeline

- **Planning**: This document
- **Execution**: ~2-3 hours
- **Validation**: Test all links, verify content

---

**Status**: Proposal
**Date**: 2024-10-20
**Approved by**: Pending
