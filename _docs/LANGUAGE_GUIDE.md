# Documentation Language Guide

## Overview

This documentation uses a **hybrid multilingual approach** to serve both AI tools and human developers effectively.

## Naming Convention

### File Structure

```
docs/
├── README.md                   # English (AI-friendly)
├── README.kr.md                # Korean (developer-friendly)
├── guidelines/
│   ├── graphql.md             # English
│   ├── graphql.kr.md          # Korean
│   ├── workflow.md            # English
│   └── workflow.kr.md         # Korean
```

### Rules

1. **Base file (`.md`)**: English version
   - Primary version for AI tools (Claude Code, Copilot, etc.)
   - Default for international developers
   - Always maintained and up-to-date

2. **Localized file (`.kr.md`, `.ja.md`, etc.)**: Translated version
   - For native language speakers
   - Optional (not all documents need translation)
   - Language code follows ISO 639-1 standard

### Language Codes

| Language | Code | Example |
|----------|------|---------|
| English | (none) | `graphql.md` |
| Korean | `kr` | `graphql.kr.md` |
| Japanese | `ja` | `graphql.ja.md` |
| Chinese | `zh` | `graphql.zh.md` |

## Usage Guidelines

### For AI Tools

AI tools should **always prefer English (`.md`) files**:

```bash
# Good - AI reads English version
claude-code "Read docs/guidelines/graphql.md and explain"

# Avoid - AI reading Korean version
claude-code "Read docs/guidelines/graphql.kr.md"
```

**Reason**:
- English documentation is more compatible with AI training data
- Reduces hallucinations and errors
- Provides more accurate technical translations

### For Developers

Developers should read their preferred language:

**Korean Developers**:
```bash
# Read Korean version for better understanding
cat docs/guidelines/graphql.kr.md

# Or use AI to explain in Korean
claude-code "docs/guidelines/graphql.md를 읽고 한글로 설명해줘"
```

**International Developers**:
```bash
# Read English version
cat docs/guidelines/graphql.md
```

## Creating New Documents

### Step 1: Write English Version

Always create the English version first:

```bash
# Create new document
touch docs/guidelines/new-feature.md

# Write content in English
vim docs/guidelines/new-feature.md
```

### Step 2: Create Translations (Optional)

Create translations for important documents:

```bash
# Create Korean version
touch docs/guidelines/new-feature.kr.md

# Translate content
vim docs/guidelines/new-feature.kr.md
```

### Step 3: Add Cross-References

Add language links in both versions:

**English version (`new-feature.md`)**:
```markdown
# New Feature Guide

> **Language**: For Korean version, see [new-feature.kr.md](./new-feature.kr.md)

[Content...]
```

**Korean version (`new-feature.kr.md`)**:
```markdown
# 새 기능 가이드

> **언어**: 영어 버전은 [new-feature.md](./new-feature.md)를 참조하세요

[Content...]
```

## Translation Priority

Not all documents need translation. Prioritize based on:

### High Priority (Must Translate)

- ✅ **README.md** - Main entry point
- ✅ **Quick Start Guides** - Critical for beginners
- ✅ **Coding Conventions** - Frequently referenced
- ✅ **Troubleshooting** - When developers are stuck

### Medium Priority (Should Translate)

- ⚠️ **Architecture Overviews** - Conceptual understanding
- ⚠️ **Development Workflow** - Daily reference
- ⚠️ **API Design Guidelines** - Important patterns

### Low Priority (Optional)

- ⭕ **Detailed API References** - Technical specs (English is clear)
- ⭕ **Code Examples** - Code is language-agnostic
- ⭕ **Internal Technical Docs** - AI-generated content

## Maintenance

### Keeping Translations in Sync

When updating English version:

1. Update the English file first
2. Mark translation as outdated (optional)
3. Update translation when possible

**Example marker for outdated translation**:

```markdown
# 새 기능 가이드

> **⚠️ Notice**: This Korean version may be outdated. Last synced: 2024-10-15
> **언어**: 영어 버전은 [new-feature.md](./new-feature.md)를 참조하세요 (최신)

[Content...]
```

### Version Tracking

Add version markers in both files:

```markdown
---

**Last Updated**: 2024-10-19
**Version**: 1.0.0
**Translation Last Synced**: 2024-10-19 (for .kr.md files)
```

## Benefits of Hybrid Approach

### For AI Tools
- ✅ Consistent English documentation for accurate AI processing
- ✅ Reduced hallucinations and translation errors
- ✅ Better code generation based on conventions

### For Developers
- ✅ Native language support for easier understanding
- ✅ English fallback always available
- ✅ Gradual translation (important docs first)

### For Maintenance
- ✅ No folder structure duplication
- ✅ Easy to identify missing translations
- ✅ Clear file relationships (`.md` + `.kr.md`)

## Best Practices

### 1. AI Always Uses English

```bash
# ✅ Good
claude-code "Read docs/api/graphql.md and generate code"

# ❌ Bad
claude-code "Read docs/api/graphql.kr.md and generate code"
```

### 2. Developers Choose Language

```bash
# Korean developer
$ cat docs/api/graphql.kr.md

# International developer
$ cat docs/api/graphql.md
```

### 3. Link Between Versions

Always add cross-reference at the top of each document:

```markdown
> **Language**: This document is also available in [Korean](./file.kr.md)
```

### 4. Translate Important Parts First

Focus on:
- Introductions and overviews
- Key concepts and principles
- Common issues and solutions

Technical details (code, configurations) can remain in English.

### 5. Use AI for Translation

```bash
# Use Claude Code for translation
claude-code "Translate docs/new-feature.md to Korean and save as docs/new-feature.kr.md"
```

## Examples

### Example 1: GraphQL Conventions

✅ **Correct structure**:
```
docs/guidelines/coding-conventions/
├── graphql.md          # English (AI reads this)
└── graphql.kr.md       # Korean (developers read this)
```

### Example 2: Platform README

✅ **Correct structure**:
```
docs/
├── README.md           # English (primary)
└── README.kr.md        # Korean (translation)
```

### Example 3: Code Example (No Translation Needed)

```
docs/examples/
└── crud-api.md         # English only (code is universal)
```

## FAQ

### Q: Should all documents be translated?

**A**: No. Focus on high-priority documents that developers frequently reference. Technical specifications and code examples can remain in English.

### Q: What if translation is outdated?

**A**: Add a notice at the top of the Korean version pointing to the English version as the source of truth.

### Q: Can AI use Korean documents?

**A**: Yes, but it's not recommended. AI performs better with English technical documentation.

### Q: How to handle screenshots and diagrams?

**A**: Use English for technical diagrams and screenshots. Add Korean captions if necessary.

### Q: What about comments in code examples?

**A**: Keep code comments in English for consistency. Add Korean explanations in the surrounding text.

---

## Summary

| Aspect | English (`.md`) | Korean (`.kr.md`) |
|--------|-----------------|-------------------|
| **Purpose** | AI-friendly, primary | Developer-friendly, translation |
| **AI Tools** | ✅ Preferred | ❌ Avoid |
| **Developers** | ✅ Always available | ✅ Optional, easier reading |
| **Maintenance** | ✅ Always updated first | ⚠️ Updated when possible |
| **Priority** | 🔥 Critical | 📝 Nice to have |

---

**Last Updated**: 2024-10-19
**Version**: 1.0.0
