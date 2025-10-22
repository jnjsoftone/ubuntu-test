# GraphQL Standards

Complete GraphQL standards for the ${PLATFORM_NAME} platform, covering design principles, naming conventions, schema patterns, and best practices.

> **Language**: For Korean version, see [graphql.kr.md](./graphql.kr.md)

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Naming Conventions](#naming-conventions)
4. [Schema Design Patterns](#schema-design-patterns)
5. [Query Design](#query-design)
6. [Mutation Design](#mutation-design)
7. [File Organization](#file-organization)
8. [Examples by Domain](#examples-by-domain)
9. [Error Handling](#error-handling)
10. [Authentication & Authorization](#authentication--authorization)
11. [Performance Optimization](#performance-optimization)
12. [Documentation](#documentation)
13. [Testing](#testing)
14. [Migration Strategy](#migration-strategy)

---

## Overview

This platform uses a **Domain-Centric + Functional Pattern** approach for GraphQL development. This approach balances:
- **Developer experience**: Intuitive naming for both frontend and backend teams
- **Maintainability**: Predictable patterns and organized by business domains
- **GraphQL philosophy**: API consumer convenience over backend implementation details

**Key Principle**: Domain name + Entity + Action pattern (`{domain}{Entity}{Action}`)

---

## Design Principles

### 1. Consistency
- All APIs follow the same naming conventions
- Unified error response format
- Standardized pagination patterns
- Domain-centric organization

### 2. Clarity
- Type and field names must be self-explanatory
- No unnecessary abbreviations
- Clear documentation with examples
- Self-documenting operation names

### 3. Scalability
- Use Input types for interface stability
- Consider versioning (utilize deprecated fields)
- Maintain backward compatibility
- Predictable patterns for new features

### 4. Domain-Driven
- Organize by business domains, not database tables
- Focus on API consumer needs
- Group related functionality together
- Maintain domain specificity even in consolidated files

---

## Naming Conventions

### Core Pattern

```
{domainName}{Entity}{Action}
```

**Examples**:
```graphql
# Notices domain
noticesAll              # notices(domain) + All(action)
noticesOne(id: ID!)     # notices(domain) + One(action)
noticesByCategory       # notices(domain) + By{Criteria}(action)
noticeCreate            # notice(singular) + Create(action)

# User bids domain
myBidsAll               # bids(domain) + All(action)
bidsByStatus            # bids(domain) + By{Criteria}(action)
bidCreate               # bid(singular) + Create(action)

# Boards domain
boardsPostsAll          # boards(domain) + Posts(entity) + All(action)
boardsPostOne           # boards(domain) + Post(entity) + One(action)
boardPostCreate         # board(singular) + Post(entity) + Create(action)
```

### Standard Action Suffixes

| Action | Suffix | Description | Example |
|--------|--------|-------------|---------|
| **Queries** |
| List all records | `All` | Retrieve all records | `noticesAll` |
| Get single record | `One` | Retrieve by ID/key | `noticesOne` |
| Filter by criteria | `By{Criteria}` | Retrieve filtered records | `noticesByCategory` |
| Search | `Search` | Full-text or keyword search | `noticesSearch` |
| Count | `Count` | Get count | `noticesCount` |
| **Mutations** |
| Create new record | `Create` | Insert new record | `bidCreate` |
| Update existing | `Update` | Modify existing record | `bidUpdate` |
| Insert or update | `Upsert` | Auto insert/update | `settingsNoticeListUpsert` |
| Delete record | `Delete` | Remove record | `bidDelete` |

### Consistency Rules

1. **All list queries** must end with `All`
2. **All single-record queries** must end with `One`
3. **All filter queries** must use `By{Criteria}` format
4. **All create mutations** must end with `Create`
5. **All update mutations** must end with `Update`
6. **All upsert mutations** must end with `Upsert`
7. **All delete mutations** must end with `Delete`

### Type Naming

```graphql
# ✅ PascalCase
type User { }
type Post { }
type UserProfile { }
type PostComment { }

# ❌ Incorrect
type user { }           # lowercase
type UserType { }       # unnecessary "Type" suffix
type TUser { }          # Hungarian notation
```

### Field Naming

```graphql
type User {
  # ✅ camelCase
  id: ID!
  email: String!
  firstName: String!
  createdAt: DateTime!

  # ❌ Incorrect
  FirstName: String!    # PascalCase
  first_name: String!   # snake_case
  fName: String!        # abbreviation
}
```

### Input Type Naming

```graphql
# ✅ PascalCase + "Input" suffix
input CreateUserInput { }
input UpdateUserInput { }
input PostFilterInput { }

# ❌ Incorrect
input UserInput { }          # no Create/Update distinction
input createUserInput { }    # camelCase
```

### Parameter Naming

```graphql
# ✅ camelCase for all parameters
noticesByCategory(category: String!)
boardsPostsAll(board: String!)
settingsNoticeListOne(oid: Int!)

# ❌ Avoid
noticesByCategory(Category: String!)    # PascalCase
boardsPostsAll(Board: String!)
```

---

## Schema Design Patterns

### Basic Structure

```graphql
# Scalars
scalar DateTime
scalar JSON
scalar Upload

# Enums
enum UserRole {
  USER
  ADMIN
  MODERATOR
}

enum PostStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}

# Types
type User {
  id: ID!
  email: String!
  role: UserRole!
  profile: UserProfile
  posts: [Post!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Post {
  id: ID!
  title: String!
  content: String!
  status: PostStatus!
  author: User!
  comments: [Comment!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

# Inputs
input CreateUserInput {
  email: String!
  password: String!
  role: UserRole
}

input UpdateUserInput {
  email: String
  password: String
  role: UserRole
}

# Filters
input PostFilter {
  status: PostStatus
  authorId: ID
  createdAfter: DateTime
  createdBefore: DateTime
}

# Pagination
input PaginationInput {
  limit: Int = 20
  offset: Int = 0
}

type PaginatedPosts {
  items: [Post!]!
  total: Int!
  hasMore: Boolean!
}

# Root Types
type Query {
  # Single resource
  user(id: ID!): User
  post(id: ID!): Post

  # List resources
  users(pagination: PaginationInput, filter: UserFilter): PaginatedUsers!
  posts(pagination: PaginationInput, filter: PostFilter): PaginatedPosts!

  # Search
  searchPosts(query: String!, limit: Int = 10): [Post!]!
}

type Mutation {
  # User mutations
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!

  # Post mutations
  createPost(input: CreatePostInput!): Post!
  updatePost(id: ID!, input: UpdatePostInput!): Post!
  deletePost(id: ID!): Boolean!
  publishPost(id: ID!): Post!
}

type Subscription {
  postCreated: Post!
  postUpdated(id: ID!): Post!
}
```

---

## Query Design

### Single Resource Query

```graphql
type Query {
  # Query by ID
  user(id: ID!): User

  # Support multiple identifiers
  user(id: ID, email: String): User

  # ⚠️ Need error handling if both optional
  user(id: ID, email: String): User  # What if both missing?
}

# ✅ Recommended: Clarify identifier with Union
input UserIdentifier {
  id: ID
  email: String
}

type Query {
  user(identifier: UserIdentifier!): User
}
```

### List Query with Pagination

```graphql
# ✅ Offset-based Pagination
type Query {
  posts(
    limit: Int = 20
    offset: Int = 0
    orderBy: PostOrderBy
    filter: PostFilter
  ): PaginatedPosts!
}

type PaginatedPosts {
  items: [Post!]!
  total: Int!
  limit: Int!
  offset: Int!
  hasMore: Boolean!
}

# ✅ Cursor-based Pagination (infinite scroll)
type Query {
  posts(
    first: Int = 20
    after: String
    filter: PostFilter
  ): PostConnection!
}

type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PostEdge {
  node: Post!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

### Sorting

```graphql
# ✅ Define sort options with Enum
enum PostOrderBy {
  CREATED_AT_ASC
  CREATED_AT_DESC
  TITLE_ASC
  TITLE_DESC
  VIEW_COUNT_DESC
}

type Query {
  posts(orderBy: PostOrderBy): [Post!]!
}

# ✅ Support multiple sort fields
input OrderByInput {
  field: String!
  direction: OrderDirection!
}

enum OrderDirection {
  ASC
  DESC
}

type Query {
  posts(orderBy: [OrderByInput!]): [Post!]!
}
```

### Filtering

```graphql
# ✅ Explicit Filter Input
input PostFilter {
  status: PostStatus
  authorId: ID
  categoryId: ID
  tags: [String!]
  createdAfter: DateTime
  createdBefore: DateTime
  search: String
}

type Query {
  posts(filter: PostFilter): [Post!]!
}

# ✅ Complex conditions (AND/OR)
input PostFilterInput {
  AND: [PostFilterInput!]
  OR: [PostFilterInput!]
  status: PostStatus
  authorId: ID
  createdAfter: DateTime
}

type Query {
  posts(where: PostFilterInput): [Post!]!
}

# Usage example:
# query {
#   posts(where: {
#     OR: [
#       { status: PUBLISHED, authorId: "user-1" },
#       { status: DRAFT, createdAfter: "2024-01-01" }
#     ]
#   })
# }
```

---

## Mutation Design

### Create

```graphql
# ✅ Use Input type
input CreatePostInput {
  title: String!
  content: String!
  status: PostStatus = DRAFT
  categoryId: ID
  tags: [String!]
}

type Mutation {
  createPost(input: CreatePostInput!): Post!
}

# ✅ Support nested creation
input CreatePostInput {
  title: String!
  content: String!
  author: CreateUserInput     # Create user together
  comments: [CreateCommentInput!]  # Create comments together
}
```

### Update

```graphql
# ✅ All fields optional (partial update)
input UpdatePostInput {
  title: String
  content: String
  status: PostStatus
  categoryId: ID
  tags: [String!]
}

type Mutation {
  updatePost(id: ID!, input: UpdatePostInput!): Post!
}

# ✅ Distinguish Patch vs Put (optional)
type Mutation {
  # PATCH: partial update
  updatePost(id: ID!, input: UpdatePostInput!): Post!

  # PUT: full replacement
  replacePost(id: ID!, input: CreatePostInput!): Post!
}
```

### Delete

```graphql
# ✅ Return Boolean (soft delete)
type Mutation {
  deletePost(id: ID!): Boolean!
}

# ✅ Return deleted resource
type Mutation {
  deletePost(id: ID!): Post!
}

# ✅ Distinguish soft/hard delete
type Mutation {
  softDeletePost(id: ID!): Post!
  hardDeletePost(id: ID!): Boolean!
  restorePost(id: ID!): Post!
}
```

### Bulk Operations

```graphql
# ✅ Process multiple resources at once
type Mutation {
  createPosts(inputs: [CreatePostInput!]!): [Post!]!
  updatePosts(ids: [ID!]!, input: UpdatePostInput!): [Post!]!
  deletePosts(ids: [ID!]!): Int!  # Return count deleted
}
```

### Input Type Design

```graphql
# ✅ Create: required fields only
input CreatePostInput {
  title: String!
  content: String!
  status: PostStatus = DRAFT
}

# ✅ Update: all optional
input UpdatePostInput {
  title: String
  content: String
  status: PostStatus
}

# ✅ Nested object creation
input CreatePostInput {
  title: String!
  content: String!
  author: CreateUserInput
  comments: [CreateCommentInput!]
}

# ✅ Relationship linking
input CreatePostInput {
  title: String!
  content: String!
  authorId: ID!           # Link existing user
  commentIds: [ID!]       # Link existing comments
}
```

---

## File Organization

### Directory Structure

```
src/
├── typeDefs/
│   ├── notices.ts          # Notices domain
│   ├── bids.ts             # User bids domain
│   ├── boards.ts           # Boards/forum domain
│   ├── settings.ts         # Settings domain (consolidated)
│   └── logs.ts             # Logging domain
└── resolvers/
    ├── notices.ts
    ├── bids.ts
    ├── boards.ts
    ├── settings.ts
    └── logs.ts
```

### File Naming Rules

- Use **plural form** for domain entities
- Use **camelCase** format
- Group related functionality in single files
- Avoid database table name prefixes

### Settings Domain Exception

For settings-related functionality, use a **single consolidated file** (`settings.ts`) but maintain **domain specificity in query/mutation names**:

```typescript
// File: settings.ts
// Queries/Mutations with domain-specific prefixes:
- settingsNoticeListAll
- settingsNoticeListOne
- settingsNoticeDetailAll
- settingsNoticeDetailOne
- settingsNoticeCategoryAll
- settingsNasPathGet
- settingsNasPathUpdate
- settingsAppDefaultGet
- settingsAppDefaultUpdate
```

---

## Examples by Domain

### Bid Notices Domain

**File**: `notices.ts`

```graphql
# Queries
type Query {
  noticesAll: [Notice!]!
  noticesOne(id: ID!): Notice
  noticesByCategory(category: String!): [Notice!]!
  noticesByStatus(status: String!): [Notice!]!
  noticesSearch(keyword: String!): [Notice!]!
}

# Mutations
type Mutation {
  noticeCreate(input: NoticeInput!): Notice!
  noticeUpdate(id: ID!, input: NoticeInput!): Notice!
  noticeDelete(id: ID!): Boolean!
}
```

### User Bids Domain

**File**: `bids.ts`

```graphql
# Queries
type Query {
  myBidsAll: [Bid!]!
  bidsOne(id: ID!): Bid
  bidsByStatus(status: String!): [Bid!]!
  bidsByNotice(noticeId: ID!): [Bid!]!
}

# Mutations
type Mutation {
  bidCreate(input: BidInput!): Bid!
  bidUpdate(id: ID!, input: BidInput!): Bid!
  bidDelete(id: ID!): Boolean!
}
```

### Board/Forum Domain

**File**: `boards.ts`

```graphql
# Queries
type Query {
  boardsAll: [Board!]!
  boardsOne(id: ID!): Board
  boardsPostsAll(board: String!): [Post!]!
  boardsPostOne(id: ID!): Post
  boardsPostsByAuthor(authorId: ID!): [Post!]!
}

# Mutations
type Mutation {
  boardCreate(input: BoardInput!): Board!
  boardUpdate(id: ID!, input: BoardInput!): Board!
  boardPostCreate(input: PostInput!): Post!
  boardPostUpdate(id: ID!, input: PostInput!): Post!
  boardPostDelete(id: ID!): Boolean!
}
```

### Settings Domain (Consolidated)

**File**: `settings.ts`

```graphql
# Notice List Settings
type Query {
  settingsNoticeListAll: [SettingsNoticeList!]!
  settingsNoticeListOne(oid: Int!): SettingsNoticeList
  settingsNoticeDetailAll: [SettingsNoticeDetail!]!
  settingsNoticeDetailOne(oid: Int!): SettingsNoticeDetail

  # Notice Category Settings
  settingsNoticeCategoryAll: [SettingsNoticeCategory!]!
  settingsNoticeCategoryOne(id: ID!): SettingsNoticeCategory

  # NAS Path Settings
  settingsNasPathGet: NasPathSettings!

  # App Default Settings
  settingsAppDefaultGet: AppDefaultSettings!
}

type Mutation {
  # Notice List Settings
  settingsNoticeListUpsert(input: SettingsNoticeListInput!): SettingsNoticeList!
  settingsNoticeDetailUpsert(input: SettingsNoticeDetailInput!): SettingsNoticeDetail!

  # Notice Category Settings
  settingsNoticeCategoryCreate(input: CategoryInput!): SettingsNoticeCategory!
  settingsNoticeCategoryUpdate(id: ID!, input: CategoryInput!): SettingsNoticeCategory!

  # NAS Path Settings
  settingsNasPathUpdate(input: NasPathInput!): NasPathSettings!

  # App Default Settings
  settingsAppDefaultUpdate(input: AppDefaultInput!): AppDefaultSettings!
}
```

---

## Error Handling

### GraphQL Errors

```graphql
# ✅ Clear error codes
enum ErrorCode {
  NOT_FOUND
  UNAUTHORIZED
  FORBIDDEN
  VALIDATION_ERROR
  INTERNAL_ERROR
}

type Error {
  message: String!
  code: ErrorCode!
  path: [String!]
  extensions: JSON
}

# ✅ Distinguish success/failure with Union type
type CreatePostResult {
  success: Boolean!
  post: Post
  errors: [Error!]
}

type Mutation {
  createPost(input: CreatePostInput!): CreatePostResult!
}

# Usage example:
# mutation {
#   createPost(input: { title: "Test" }) {
#     success
#     post { id title }
#     errors { message code }
#   }
# }
```

### Custom Error Types

```typescript
// Error handling in Resolver
import { ApolloError, UserInputError, AuthenticationError } from 'apollo-server';

// ✅ Use specific error types
throw new UserInputError('Invalid email format', {
  code: 'VALIDATION_ERROR',
  field: 'email',
});

throw new AuthenticationError('Unauthorized');

throw new ApolloError('Post not found', 'NOT_FOUND', {
  resourceType: 'Post',
  resourceId: id,
});
```

---

## Authentication & Authorization

### Using Context

```typescript
// GraphQL Context
interface Context {
  user?: User;          // Authenticated user
  token?: string;       // JWT token
  req: Request;
  res: Response;
}

// Resolver
@Query()
async me(@Ctx() context: Context): Promise<User> {
  if (!context.user) {
    throw new AuthenticationError('Not authenticated');
  }
  return context.user;
}
```

### Using Directives

```graphql
# ✅ Define @auth directive
directive @auth(requires: UserRole) on FIELD_DEFINITION | OBJECT

type Query {
  me: User! @auth
  users: [User!]! @auth(requires: ADMIN)
}

type Mutation {
  deleteUser(id: ID!): Boolean! @auth(requires: ADMIN)
}
```

---

## Performance Optimization

### DataLoader (Solve N+1)

```typescript
import DataLoader from 'dataloader';

// ✅ Create DataLoader
const userLoader = new DataLoader(async (userIds: string[]) => {
  const users = await userRepository.findByIds(userIds);
  return userIds.map(id => users.find(u => u.id === id));
});

// Resolver
@ResolveField()
async author(@Parent() post: Post, @Ctx() context: Context): Promise<User> {
  return context.loaders.user.load(post.userId);
}
```

### Field-level Caching

```graphql
type Query {
  # ✅ @cacheControl directive
  posts: [Post!]! @cacheControl(maxAge: 60)
  user(id: ID!): User @cacheControl(maxAge: 300)
}
```

### Subscription Design

```graphql
type Subscription {
  # ✅ Past tense + resource
  postCreated: Post!
  postUpdated(id: ID): Post!    # Specific post update
  postDeleted: ID!

  # ✅ Support filtering
  postCreated(authorId: ID): Post!

  # ❌ Incorrect
  onPostCreate: Post!           # unnecessary "on" prefix
  createPost: Post!             # confusing with Mutation
}
```

---

## Documentation

### Schema Description

```graphql
"""
Represents user information.
"""
type User {
  """
  User unique identifier (UUID)
  """
  id: ID!

  """
  User email address (unique)

  Example: user@example.com
  """
  email: String!
}

"""
Creates a new post.

Example:
\`\`\`graphql
mutation {
  createPost(input: {
    title: "My First Post"
    content: "Hello World"
  }) {
    id
    title
  }
}
\`\`\`
"""
createPost(input: CreatePostInput!): Post!
```

---

## Testing

### Query Testing

```typescript
describe('User Query', () => {
  it('should get user by id', async () => {
    const query = `
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          email
        }
      }
    `;

    const result = await executeQuery(query, { id: 'user-1' });

    expect(result.data.user).toMatchObject({
      id: 'user-1',
      email: 'test@example.com',
    });
  });
});
```

### Mutation Testing

```typescript
describe('Create User Mutation', () => {
  it('should create user', async () => {
    const mutation = `
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          id
          email
        }
      }
    `;

    const result = await executeMutation(mutation, {
      input: {
        email: 'new@example.com',
        password: 'password123',
      },
    });

    expect(result.data.createUser).toHaveProperty('id');
    expect(result.data.createUser.email).toBe('new@example.com');
  });
});
```

---

## Migration Strategy

When migrating existing GraphQL code to this standard:

### Step 1: Audit Current Code

Identify all existing queries and mutations across schema and resolver files.

### Step 2: Create Domain Map

Group operations by business domain:
- Notices: notice retrieval, filtering
- Bids: user bid operations
- Boards: forum/board operations
- Settings: all configuration operations
- Logs: logging operations

### Step 3: Rename Files

Consolidate related operations into domain-based files:
- Multiple notice files → `notices.ts`
- Settings files → `settings.ts` (consolidated)

### Step 4: Rename Operations

Apply naming conventions systematically:
- `posts(board: String!)` → `boardsPostsAll(board: String!)`
- `post(id: ID!)` → `boardsPostOne(id: ID!)`
- `settingsList` → `settingsNoticeListAll`

### Step 5: Update Frontend

Update all GraphQL queries/mutations in frontend code to use new names.

### Step 6: Update Documentation

Ensure API documentation (Swagger, GraphQL Playground) reflects new naming.

---

## Anti-Patterns to Avoid

### ❌ Database Table Names

```graphql
# Bad
notice_list
settings_notice_list

# Good
noticesAll
settingsNoticeListAll
```

### ❌ Inconsistent Action Verbs

```graphql
# Bad
getNotices      # mixing 'get' and no prefix
fetchNotice
retrieveNotices

# Good
noticesAll
noticesOne
```

### ❌ Backend Implementation Details

```graphql
# Bad
serverBidNoticeList
apiGetNotices

# Good
noticesAll
bidCreate
```

### ❌ Unclear Scope

```graphql
# Bad
list          # Too vague
data
get

# Good
noticesAll
settingsNoticeListAll
```

---

## Benefits

### 1. Intuitive

Frontend developers can easily understand and discover available operations without deep backend knowledge.

### 2. Scalable

When adding new features, the naming pattern is predictable and consistent:
- New notice filter? → `noticesByOrganization`
- New settings section? → `settingsWorkflowGet`, `settingsWorkflowUpdate`

### 3. Maintainable

Related functionalities are grouped by domain, making it easy to:
- Find all notice-related queries in `notices.ts`
- Locate all settings operations in `settings.ts`
- Understand operation purpose from naming alone

### 4. GraphQL Philosophy Alignment

Focuses on **API consumer convenience** (frontend developers) rather than backend implementation details.

### 5. Self-Documenting

The naming convention itself serves as documentation:
```typescript
// Clear from name alone:
noticesAll           // Get all notices
noticesOne           // Get one notice
noticesByCategory    // Filter notices by category
noticeCreate         // Create a new notice
```

---

## Summary Checklist

When creating or reviewing GraphQL operations:

- [ ] File name uses plural, camelCase domain name
- [ ] Query names follow `{domain}{Entity}{Action}` pattern
- [ ] Mutation names follow `{domain}{Entity}{Action}` pattern
- [ ] List queries end with `All`
- [ ] Single-record queries end with `One`
- [ ] Filter queries use `By{Criteria}` format
- [ ] Create mutations end with `Create`
- [ ] Update mutations end with `Update`
- [ ] Upsert mutations end with `Upsert`
- [ ] Delete mutations end with `Delete`
- [ ] Settings queries maintain domain specificity (e.g., `settingsNoticeList...`)
- [ ] Parameters use camelCase
- [ ] Input types use PascalCase with `Input` suffix
- [ ] Response types use PascalCase
- [ ] Error handling is implemented
- [ ] Authentication/authorization is considered
- [ ] Performance optimizations (DataLoader) are applied where needed
- [ ] Schema documentation is clear and includes examples

---

## Related Documents

- [TypeScript Standards](./typescript.md) - TypeScript coding standards
- [REST API Standards](./rest-api.md) - REST API design patterns
- [Database Standards](./database.md) - Database schema and query patterns
- [Platform Architecture](../02-architecture/platform-overview.md) - Overall platform architecture
- [Metadata Schema](../02-architecture/metadata-schema.md) - Metadata-based schema design

---

**Last Updated**: 2024-10-20
**Version**: 2.0.0 (Consolidated)

> **Note**: This document consolidates GraphQL API design patterns and naming conventions.
> All projects using this platform must follow these standards.
