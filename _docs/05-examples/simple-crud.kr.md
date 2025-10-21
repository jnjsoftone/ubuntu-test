# 예제: 간단한 CRUD API

이 예제는 메타데이터 기반으로 간단한 블로그 CRUD API를 만드는 과정을 보여줍니다.

## 📋 요구사항

- 사용자 관리 (User)
- 포스트 관리 (Post)
- 댓글 관리 (Comment)
- GraphQL API
- PostgreSQL 데이터베이스

## 🚀 Step 1: 메타데이터 정의

### users.json
```json
{
  "tableName": "users",
  "description": "사용자 정보",
  "timestamps": true,
  "softDelete": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid",
      "comment": "사용자 고유 ID"
    },
    {
      "name": "email",
      "type": "varchar",
      "length": 255,
      "unique": true,
      "nullable": false,
      "validation": { "email": true },
      "comment": "이메일 주소"
    },
    {
      "name": "password",
      "type": "varchar",
      "length": 255,
      "nullable": false,
      "exclude": ["graphql", "api"],
      "comment": "암호화된 비밀번호"
    },
    {
      "name": "name",
      "type": "varchar",
      "length": 100,
      "nullable": false,
      "comment": "사용자 이름"
    },
    {
      "name": "role",
      "type": "enum",
      "enum": ["USER", "ADMIN"],
      "default": "USER",
      "nullable": false,
      "comment": "사용자 권한"
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
  "description": "블로그 포스트",
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
  "description": "포스트 댓글",
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

### 관계 정의 (user-posts.json)
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

## 🛠️ Step 2: 코드 자동 생성

```bash
# 1. 메타데이터 검증
npm run metadata:validate

# 2. 전체 코드 생성
npm run generate:all

# 출력:
# ✓ Entities generated (3 files)
# ✓ GraphQL schemas generated (3 files)
# ✓ Resolvers generated (3 files)
# ✓ Services generated (3 files)
# ✓ Migrations generated (1 file)
```

### 생성된 파일 구조
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

## 🔄 Step 3: 마이그레이션 실행

```bash
# 1. 데이터베이스 생성 (아직 없다면)
npm run db:create

# 2. 마이그레이션 실행
npm run migration:run

# 출력:
# ✓ CreateUsersTable migration executed
# ✓ CreatePostsTable migration executed
# ✓ CreateCommentsTable migration executed
```

## 🚀 Step 4: 서버 시작

```bash
# 개발 모드로 시작
npm run dev

# 출력:
# 🚀 Server ready at http://localhost:${PROJECT_API_PORT}/graphql
# 📊 Database connected
```

## 📝 Step 5: GraphQL 쿼리 테스트

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

## 🎨 Step 6: 커스텀 로직 추가

### 비밀번호 해싱 추가
```typescript
// src/custom/services/user.service.custom.ts
import { UserService } from '../../services/user.service';
import { CreateUserInput, UpdateUserInput } from '../../types/inputs';
import * as bcrypt from 'bcrypt';

export class UserServiceCustom extends UserService {
  async create(input: CreateUserInput): Promise<User> {
    // 비밀번호 해싱
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

### 로그인 기능 추가
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

### GraphQL Schema 확장
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

## 🧪 Step 7: 테스트

### 단위 테스트
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

### 통합 테스트
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

## 📊 완성된 API

### 사용 가능한 쿼리
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

### 사용 가능한 뮤테이션
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

## 🎯 다음 단계

1. **인증/인가 강화**: Role-based access control 추가
2. **페이지네이션 개선**: Cursor-based pagination 구현
3. **검색 기능**: Full-text search 추가
4. **파일 업로드**: 이미지 업로드 기능
5. **실시간 업데이트**: Subscriptions 구현

## 🔗 관련 예제

- [인증/인가 시스템](./02-authentication.md)
- [파일 업로드](./03-file-upload.md)
- [실시간 기능 (Subscriptions)](./04-subscriptions.md)
- [검색 및 필터링](./05-search-filter.md)
