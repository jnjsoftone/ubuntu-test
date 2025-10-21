# Example: Simple CRUD API

This example demonstrates creating a simple blog CRUD API based on metadata.

## 📋 Requirements

- User Management (User)
- Post Management (Post)
- Comment Management (Comment)
- GraphQL API
- PostgreSQL Database

## 🚀 Step 1: Define Metadata

### users.json
```json
{
  "tableName": "users",
  "description": "User information",
  "timestamps": true,
  "softDelete": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid",
      "comment": "Unique user ID"
    },
    {
      "name": "email",
      "type": "varchar",
      "length": 255,
      "unique": true,
      "nullable": false,
      "validation": { "email": true },
      "comment": "Email address"
    },
    {
      "name": "password",
      "type": "varchar",
      "length": 255,
      "nullable": false,
      "exclude": ["graphql", "api"],
      "comment": "Encrypted password"
    },
    {
      "name": "name",
      "type": "varchar",
      "length": 100,
      "nullable": false,
      "comment": "User name"
    },
    {
      "name": "role",
      "type": "enum",
      "enum": ["USER", "ADMIN"],
      "default": "USER",
      "nullable": false,
      "comment": "User role"
    }
  ],
  "indexes": [
    {
      "name": "idx_users_email",
      "columns": ["email"],
      "unique": true
    }
  ],
  "graphql": {
    "queries": {
      "findOne": "user",
      "findMany": "users",
      "count": "userCount"
    },
    "mutations": {
      "create": "createUser",
      "update": "updateUser",
      "delete": "deleteUser"
    },
    "exclude": ["password"]
  }
}
```

### posts.json
```json
{
  "tableName": "posts",
  "description": "Blog posts",
  "timestamps": true,
  "softDelete": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid"
    },
    {
      "name": "title",
      "type": "varchar",
      "length": 200,
      "nullable": false,
      "validation": { "minLength": 1, "maxLength": 200 }
    },
    {
      "name": "content",
      "type": "text",
      "nullable": false,
      "validation": { "minLength": 1 }
    },
    {
      "name": "status",
      "type": "enum",
      "enum": ["DRAFT", "PUBLISHED"],
      "default": "DRAFT",
      "nullable": false
    },
    {
      "name": "user_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "users",
        "column": "id",
        "onDelete": "CASCADE"
      }
    }
  ],
  "indexes": [
    { "columns": ["user_id"] },
    { "columns": ["status"] }
  ]
}
```

### comments.json
```json
{
  "tableName": "comments",
  "description": "Post comments",
  "timestamps": true,
  "softDelete": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid"
    },
    {
      "name": "content",
      "type": "text",
      "nullable": false,
      "validation": { "minLength": 1, "maxLength": 1000 }
    },
    {
      "name": "post_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "posts",
        "column": "id",
        "onDelete": "CASCADE"
      }
    },
    {
      "name": "user_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "users",
        "column": "id",
        "onDelete": "CASCADE"
      }
    }
  ],
  "indexes": [
    { "columns": ["post_id"] },
    { "columns": ["user_id"] }
  ]
}
```

### Relationship Definition (user-posts.json)
```json
{
  "name": "user-posts",
  "type": "one-to-many",
  "from": {
    "table": "users",
    "relation": "posts"
  },
  "to": {
    "table": "posts",
    "column": "user_id",
    "relation": "author"
  },
  "cascade": {
    "delete": true
  }
}
```

## 🛠️ Step 2: Auto-Generate Code

```bash
# 1. Validate metadata
npm run metadata:validate

# 2. Generate all code
npm run generate:all

# Output:
# ✓ Entities generated (3 files)
# ✓ GraphQL schemas generated (3 files)
# ✓ Resolvers generated (3 files)
# ✓ Services generated (3 files)
# ✓ Migrations generated (1 file)
```

### Generated File Structure
```
src/
├── entities/
│   ├── User.ts
│   ├── Post.ts
│   └── Comment.ts
├── schema/
│   ├── user.graphql
│   ├── post.graphql
│   └── comment.graphql
├── resolvers/
│   ├── user.resolver.ts
│   ├── post.resolver.ts
│   └── comment.resolver.ts
└── services/
    ├── user.service.ts
    ├── post.service.ts
    └── comment.service.ts

migrations/
└── 1634567890123-CreateTables.ts
```

## 🔄 Step 3: Run Migrations

```bash
# 1. Create database (if not exists)
npm run db:create

# 2. Run migrations
npm run migration:run

# Output:
# ✓ CreateUsersTable migration executed
# ✓ CreatePostsTable migration executed
# ✓ CreateCommentsTable migration executed
```

## 🚀 Step 4: Start Server

```bash
# Start in development mode
npm run dev

# Output:
# 🚀 Server ready at http://localhost:${PROJECT_API_PORT}/graphql
# 📊 Database connected
```

## 📝 Step 5: Test GraphQL Queries

GraphQL Playground: `http://localhost:${PROJECT_API_PORT}/graphql`

### Create User
```graphql
mutation CreateUser {
  createUser(input: {
    email: "john@example.com"
    password: "password123"
    name: "John Doe"
    role: USER
  }) {
    id
    email
    name
    role
    createdAt
  }
}
```

**Response:**
```json
{
  "data": {
    "createUser": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "john@example.com",
      "name": "John Doe",
      "role": "USER",
      "createdAt": "2024-10-19T00:00:00.000Z"
    }
  }
}
```

### Create Post
```graphql
mutation CreatePost {
  createPost(input: {
    title: "My First Post"
    content: "This is the content of my first post."
    status: PUBLISHED
    userId: "550e8400-e29b-41d4-a716-446655440000"
  }) {
    id
    title
    content
    status
    author {
      id
      name
    }
    createdAt
  }
}
```

### Get Posts with Author
```graphql
query GetPosts {
  posts(limit: 10, offset: 0) {
    items {
      id
      title
      content
      status
      author {
        id
        name
        email
      }
      createdAt
    }
    total
    hasMore
  }
}
```

### Create Comment
```graphql
mutation CreateComment {
  createComment(input: {
    content: "Great post!"
    postId: "post-id-here"
    userId: "user-id-here"
  }) {
    id
    content
    post {
      title
    }
    author {
      name
    }
    createdAt
  }
}
```

### Get Post with Comments
```graphql
query GetPostWithComments($id: ID!) {
  post(id: $id) {
    id
    title
    content
    author {
      name
    }
    comments {
      id
      content
      author {
        name
      }
      createdAt
    }
  }
}
```

## 🎨 Step 6: Add Custom Logic

### Add Password Hashing
```typescript
// src/custom/services/user.service.custom.ts
import { UserService } from '../../services/user.service';
import { CreateUserInput, UpdateUserInput } from '../../types/inputs';
import * as bcrypt from 'bcrypt';

export class UserServiceCustom extends UserService {
  async create(input: CreateUserInput): Promise<User> {
    // Hash password
    const hashedPassword = await bcrypt.hash(input.password, 10);

    return super.create({
      ...input,
      password: hashedPassword,
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.repository.findOne({ where: { email } });
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password);
  }
}
```

### Add Login Functionality
```typescript
// src/custom/resolvers/auth.resolver.ts
import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { UserServiceCustom } from '../services/user.service.custom';
import { AuthenticationError } from 'apollo-server';
import * as jwt from 'jsonwebtoken';

@Resolver()
export class AuthResolver {
  constructor(private userService: UserServiceCustom) {}

  @Mutation()
  async login(
    @Args('email') email: string,
    @Args('password') password: string
  ): Promise<{ token: string; user: User }> {
    const user = await this.userService.findByEmail(email);

    if (!user) {
      throw new AuthenticationError('Invalid credentials');
    }

    const valid = await this.userService.validatePassword(user, password);

    if (!valid) {
      throw new AuthenticationError('Invalid credentials');
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET!,
      { expiresIn: '24h' }
    );

    return { token, user };
  }
}
```

### Extend GraphQL Schema
```graphql
# src/custom/schema/auth.graphql
type AuthPayload {
  token: String!
  user: User!
}

extend type Mutation {
  login(email: String!, password: String!): AuthPayload!
}
```

## 🧪 Step 7: Testing

### Unit Tests
```typescript
// tests/unit/user.service.spec.ts
import { UserServiceCustom } from '../../src/custom/services/user.service.custom';

describe('UserServiceCustom', () => {
  let service: UserServiceCustom;

  beforeEach(() => {
    // Setup
  });

  it('should hash password on create', async () => {
    const input = {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
    };

    const user = await service.create(input);

    expect(user.password).not.toBe('password123');
    expect(user.password).toHaveLength(60); // bcrypt hash length
  });

  it('should validate password', async () => {
    const user = await service.create({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
    });

    const valid = await service.validatePassword(user, 'password123');
    const invalid = await service.validatePassword(user, 'wrongpassword');

    expect(valid).toBe(true);
    expect(invalid).toBe(false);
  });
});
```

### Integration Tests
```typescript
// tests/integration/auth.spec.ts
import { executeQuery } from '../helpers';

describe('Authentication', () => {
  it('should login with valid credentials', async () => {
    // 1. Create user
    await executeQuery(`
      mutation {
        createUser(input: {
          email: "test@example.com"
          password: "password123"
          name: "Test User"
        }) { id }
      }
    `);

    // 2. Login
    const result = await executeQuery(`
      mutation {
        login(email: "test@example.com", password: "password123") {
          token
          user { id email name }
        }
      }
    `);

    expect(result.data.login.token).toBeDefined();
    expect(result.data.login.user.email).toBe('test@example.com');
  });
});
```

## 📊 Complete API

### Available Queries
```graphql
type Query {
  # Users
  user(id: ID!): User
  users(limit: Int, offset: Int): PaginatedUsers!

  # Posts
  post(id: ID!): Post
  posts(limit: Int, offset: Int, filter: PostFilter): PaginatedPosts!

  # Comments
  comment(id: ID!): Comment
  comments(postId: ID!, limit: Int, offset: Int): PaginatedComments!
}
```

### Available Mutations
```graphql
type Mutation {
  # Auth
  login(email: String!, password: String!): AuthPayload!

  # Users
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!

  # Posts
  createPost(input: CreatePostInput!): Post!
  updatePost(id: ID!, input: UpdatePostInput!): Post!
  deletePost(id: ID!): Boolean!
  publishPost(id: ID!): Post!

  # Comments
  createComment(input: CreateCommentInput!): Comment!
  updateComment(id: ID!, input: UpdateCommentInput!): Comment!
  deleteComment(id: ID!): Boolean!
}
```

## 🎯 Next Steps

1. **Enhance Authentication/Authorization**: Add role-based access control
2. **Improve Pagination**: Implement cursor-based pagination
3. **Add Search**: Full-text search functionality
4. **File Upload**: Image upload capability
5. **Real-time Updates**: Implement subscriptions

## 🔗 Related Examples

- [Authentication/Authorization System](./02-authentication.md)
- [File Upload](./03-file-upload.md)
- [Real-time Features (Subscriptions)](./04-subscriptions.md)
- [Search and Filtering](./05-search-filter.md)
