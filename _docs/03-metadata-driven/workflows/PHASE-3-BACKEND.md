# Phase 3: Backend 개발 - Claude Code 프롬프트

> TypeScript + GraphQL 백엔드 개발 단계

## 3.1 코드 생성 스크립트 작성

### 프롬프트 3-1: 코드 생성 시스템 구축

```
메타데이터 기반 코드 생성 시스템을 구축해주세요:

참고 문서:
/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/CODE-GENERATION-TEMPLATES.md

요구사항:
1. Generator 클래스 구현
   - BaseGenerator (공통 기능)
   - DatabaseGenerator (DDL 생성)
   - GraphQLSchemaGenerator (GraphQL 스키마)
   - TypeScriptGenerator (TypeScript 타입)
   - ResolverGenerator (GraphQL 리졸버)

2. 생성 스크립트
   - scripts/generators/base-generator.ts
   - scripts/generators/database-generator.ts
   - scripts/generators/graphql-generator.ts
   - scripts/generators/typescript-generator.ts
   - scripts/generators/resolver-generator.ts
   - scripts/generate-all.ts

3. 메타데이터 서비스
   - scripts/services/metadata-service.ts (원격 PostgreSQL 연결)

4. 실행 스크립트
   - package.json에 scripts 추가

환경:
- 메타데이터 DB: 원격 PostgreSQL (${METADATA_DB_HOST})
- 생성 대상: backend/src/generated/

코드를 생성해주세요.
```

**예상 Claude 응답:**

```typescript
// scripts/services/metadata-service.ts
import { Pool } from 'pg';

export class MetadataService {
  private pool: Pool;

  constructor() {
    this.pool = new Pool({
      host: process.env.METADATA_DB_HOST,
      port: parseInt(process.env.METADATA_DB_PORT || '5432'),
      database: process.env.METADATA_DB_NAME,
      user: process.env.METADATA_DB_USER,
      password: process.env.METADATA_DB_PASSWORD,
      ssl: { rejectUnauthorized: false }
    });
  }

  async getProjectTables(projectId: string): Promise<TableMetadata[]> {
    const result = await this.pool.query(`
      SELECT
        t.*,
        array_agg(json_build_object(
          'id', c.id,
          'pgColumn', c.pg_column,
          'pgType', c.pg_type,
          'graphqlField', c.graphql_field,
          'graphqlType', c.graphql_type,
          'label', c.label,
          'isRequired', c.is_required,
          'isUnique', c.is_unique,
          'isPrimaryKey', c.is_primary_key,
          'validationRules', c.validation_rules,
          'enumOptions', c.enum_options
        )) as columns
      FROM _metadata.mappings_table t
      LEFT JOIN mappings_column c ON t.id = c.table_id
      WHERE t.schema_name = 'public'
      GROUP BY t.id
      ORDER BY t.table_name
    `);

    return result.rows;
  }

  async getRelations(): Promise<RelationMetadata[]> {
    const result = await this.pool.query(`
      SELECT * FROM _metadata.mappings_relation
      ORDER BY from_table, to_table
    `);

    return result.rows;
  }
}
```

---

## 3.2 데이터베이스 스키마 생성

### 프롬프트 3-2: DDL 생성 및 마이그레이션

```
메타데이터를 기반으로 실제 데이터베이스 스키마를 생성해주세요:

작업:
1. 코드 생성 실행
   npm run generate:db

2. 생성된 DDL 확인
   backend/src/generated/schema.sql

3. 원격 PostgreSQL에 적용
   - 데이터베이스: auth_db
   - 호스트: ${APP_DB_HOST}

4. 마이그레이션 파일 생성
   - database/migrations/001_initial_schema.sql
   - UP/DOWN 스크립트 포함

5. 마이그레이션 실행 스크립트
   - scripts/db/migrate.ts

요청사항:
- 생성된 DDL이 메타데이터와 일치하는지 검증
- 인덱스 생성 확인
- Foreign Key 제약 조건 확인
- Trigger 생성 확인 (updated_at 자동 갱신)
```

**예상 생성 DDL:**

```sql
-- Generated DDL from metadata

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Enums
CREATE TYPE role_name_enum AS ENUM ('admin', 'manager', 'user');

-- Tables
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar_url VARCHAR(500),
    email_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT check_users_email CHECK (email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
);

COMMENT ON TABLE users IS '사용자';
COMMENT ON COLUMN users.email IS '이메일';
COMMENT ON COLUMN users.first_name IS '이름';

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_first_name ON users(first_name) WHERE first_name IS NOT NULL;
CREATE INDEX idx_users_last_name ON users(last_name) WHERE last_name IS NOT NULL;
CREATE INDEX idx_users_is_active ON users(is_active);

-- (나머지 테이블들...)

-- Foreign Keys
ALTER TABLE user_roles
ADD CONSTRAINT fk_user_roles_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Triggers
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 3.3 GraphQL 스키마 생성

### 프롬프트 3-3: GraphQL 스키마 자동 생성

```
메타데이터를 기반으로 GraphQL 스키마를 생성해주세요:

작업:
1. 스키마 생성 실행
   npm run generate:graphql

2. 생성 파일 확인
   - backend/src/generated/schema.graphql
   - backend/src/generated/types.ts

3. 추가 요구사항
   - Authentication 관련 커스텀 타입 추가
     - AuthPayload
     - LoginInput
     - RegisterInput
     - ChangePasswordInput
     - ResetPasswordInput

4. 커스텀 스칼라
   - DateTime
   - JSON

다음 커스텀 스키마를 추가해주세요:
backend/src/custom/auth-schema.graphql
```

**예상 생성 스키마:**

```graphql
# backend/src/generated/schema.graphql
# Auto-generated from metadata

scalar DateTime
scalar JSON

enum RoleName {
  admin
  manager
  user
}

type User {
  id: ID!
  email: String!
  firstName: String!
  lastName: String!
  phone: String
  avatarUrl: String
  emailVerified: Boolean!
  isActive: Boolean!
  lastLoginAt: DateTime
  createdAt: DateTime!
  updatedAt: DateTime!

  # Relations
  userRoles: [UserRole!]!
  refreshTokens: [RefreshToken!]!
}

type Role {
  id: ID!
  name: RoleName!
  description: String
  createdAt: DateTime!
  updatedAt: DateTime!

  # Relations
  userRoles: [UserRole!]!
  permissions: [Permission!]!
}

type Permission {
  id: ID!
  name: String!
  resource: String!
  action: String!
  description: String
  createdAt: DateTime!
}

input UserInput {
  email: String!
  firstName: String!
  lastName: String!
  phone: String
  avatarUrl: String
  isActive: Boolean
}

input UserFilter {
  email: String
  firstName: String
  lastName: String
  isActive: Boolean
  search: String
}

type Query {
  # User queries
  user(id: ID!): User
  users(
    filter: UserFilter
    sort: SortInput
    limit: Int = 20
    offset: Int = 0
  ): [User!]!
  usersCount(filter: UserFilter): Int!

  # Role queries
  role(id: ID!): Role
  roles: [Role!]!

  # Permission queries
  permissions: [Permission!]!
}

type Mutation {
  # User mutations
  createUser(input: UserInput!): User!
  updateUser(id: ID!, input: UserInput!): User!
  deleteUser(id: ID!): Boolean!
}
```

**커스텀 스키마:**

```graphql
# backend/src/custom/auth-schema.graphql

extend type Query {
  # Authentication
  me: User
  verifyToken: Boolean!
}

extend type Mutation {
  # Authentication
  register(input: RegisterInput!): AuthPayload!
  login(input: LoginInput!): AuthPayload!
  logout: Boolean!
  refreshToken(token: String!): AuthPayload!

  # Password management
  changePassword(input: ChangePasswordInput!): Boolean!
  requestPasswordReset(email: String!): Boolean!
  resetPassword(input: ResetPasswordInput!): Boolean!

  # Email verification
  verifyEmail(token: String!): Boolean!
  resendVerificationEmail: Boolean!
}

# Custom types
type AuthPayload {
  user: User!
  accessToken: String!
  refreshToken: String!
  expiresIn: Int!
}

input RegisterInput {
  email: String!
  password: String!
  firstName: String!
  lastName: String!
  phone: String
}

input LoginInput {
  email: String!
  password: String!
}

input ChangePasswordInput {
  oldPassword: String!
  newPassword: String!
}

input ResetPasswordInput {
  token: String!
  newPassword: String!
}
```

---

## 3.4 TypeScript 타입 생성

### 프롬프트 3-4: TypeScript 타입 자동 생성

```
GraphQL 스키마를 기반으로 TypeScript 타입을 생성해주세요:

작업:
1. GraphQL Code Generator 설정
   - codegen.yml 생성
   - 플러그인 설치

2. 타입 생성
   npm run generate:types

3. 생성 파일
   - backend/src/generated/graphql.ts

4. 추가 타입 정의
   - backend/src/types/context.ts (GraphQL Context)
   - backend/src/types/auth.ts (JWT Payload 등)

요청사항:
- GraphQL 스키마 → TypeScript 타입 매핑
- Resolvers 타입 정의
- Context 타입 정의
```

**codegen.yml:**

```yaml
# codegen.yml
schema:
  - ./backend/src/generated/schema.graphql
  - ./backend/src/custom/auth-schema.graphql
generates:
  ./backend/src/generated/graphql.ts:
    plugins:
      - typescript
      - typescript-resolvers
    config:
      useIndexSignature: true
      contextType: ../types/context#GraphQLContext
      mappers:
        User: ../types/models#UserModel
        Role: ../types/models#RoleModel
```

**생성된 타입:**

```typescript
// backend/src/generated/graphql.ts
export type User = {
  id: Scalars['ID'];
  email: Scalars['String'];
  firstName: Scalars['String'];
  lastName: Scalars['String'];
  phone?: Maybe<Scalars['String']>;
  avatarUrl?: Maybe<Scalars['String']>;
  emailVerified: Scalars['Boolean'];
  isActive: Scalars['Boolean'];
  lastLoginAt?: Maybe<Scalars['DateTime']>;
  createdAt: Scalars['DateTime'];
  updatedAt: Scalars['DateTime'];
  userRoles: Array<UserRole>;
  refreshTokens: Array<RefreshToken>;
};

export type Resolvers<ContextType = GraphQLContext> = {
  User?: UserResolvers<ContextType>;
  Role?: RoleResolvers<ContextType>;
  Query?: QueryResolvers<ContextType>;
  Mutation?: MutationResolvers<ContextType>;
};
```

**커스텀 타입:**

```typescript
// backend/src/types/context.ts
import { Pool } from 'pg';
import DataLoader from 'dataloader';

export interface GraphQLContext {
  user?: UserModel;
  db: Pool;
  services: {
    user: UserService;
    auth: AuthService;
    role: RoleService;
    permission: PermissionService;
  };
  loaders: {
    userById: DataLoader<string, UserModel>;
    roleById: DataLoader<string, RoleModel>;
  };
}

// backend/src/types/auth.ts
export interface JWTPayload {
  userId: string;
  email: string;
  roles: string[];
  type: 'access' | 'refresh';
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
```

---

## 3.5 Resolver 생성

### 프롬프트 3-5: GraphQL Resolver 자동 생성

```
메타데이터 기반으로 GraphQL Resolver를 생성해주세요:

작업:
1. 생성된 Resolver 확인
   - backend/src/generated/resolvers/user-resolvers.ts
   - backend/src/generated/resolvers/role-resolvers.ts
   - backend/src/generated/resolvers/permission-resolvers.ts
   - backend/src/generated/resolvers/index.ts

2. 커스텀 Resolver 작성
   - backend/src/custom/resolvers/auth-resolvers.ts
   - backend/src/custom/resolvers/me-resolvers.ts

3. Resolver 병합
   - backend/src/resolvers/index.ts

다음 기능을 포함:
- CRUD 기본 리졸버 (자동 생성)
- 권한 체크 데코레이터
- DataLoader를 통한 N+1 해결
- 에러 핸들링
```

**생성된 Resolver:**

```typescript
// backend/src/generated/resolvers/user-resolvers.ts
import type { Resolvers } from '../graphql';
import type { GraphQLContext } from '../../types/context';

export const userResolvers: Resolvers = {
  Query: {
    async user(parent, { id }, context: GraphQLContext) {
      return await context.services.user.findById(id);
    },

    async users(parent, { filter, sort, limit, offset }, context: GraphQLContext) {
      return await context.services.user.findAll({
        filter,
        sort,
        pagination: { limit, offset }
      });
    },

    async usersCount(parent, { filter }, context: GraphQLContext) {
      return await context.services.user.count(filter);
    }
  },

  Mutation: {
    async createUser(parent, { input }, context: GraphQLContext) {
      return await context.services.user.create(input);
    },

    async updateUser(parent, { id, input }, context: GraphQLContext) {
      return await context.services.user.update(id, input);
    },

    async deleteUser(parent, { id }, context: GraphQLContext) {
      return await context.services.user.delete(id);
    }
  },

  User: {
    async userRoles(parent, args, context: GraphQLContext) {
      return await context.loaders.userRolesByUserId.load(parent.id);
    },

    async refreshTokens(parent, args, context: GraphQLContext) {
      return await context.loaders.refreshTokensByUserId.load(parent.id);
    }
  }
};
```

**커스텀 Resolver:**

```typescript
// backend/src/custom/resolvers/auth-resolvers.ts
import { GraphQLError } from 'graphql';
import type { Resolvers } from '../../generated/graphql';
import type { GraphQLContext } from '../../types/context';

export const authResolvers: Resolvers = {
  Query: {
    async me(parent, args, context: GraphQLContext) {
      if (!context.user) {
        throw new GraphQLError('Not authenticated', {
          extensions: { code: 'UNAUTHENTICATED' }
        });
      }

      return context.user;
    },

    async verifyToken(parent, args, context: GraphQLContext) {
      return !!context.user;
    }
  },

  Mutation: {
    async register(parent, { input }, context: GraphQLContext) {
      // 이메일 중복 체크
      const existingUser = await context.services.user.findByEmail(input.email);
      if (existingUser) {
        throw new GraphQLError('Email already exists', {
          extensions: { code: 'EMAIL_ALREADY_EXISTS' }
        });
      }

      // 비밀번호 해싱
      const passwordHash = await context.services.auth.hashPassword(input.password);

      // 사용자 생성
      const user = await context.services.user.create({
        ...input,
        passwordHash,
        emailVerified: false,
        isActive: true
      });

      // 기본 역할 할당 (user)
      await context.services.role.assignRole(user.id, 'user');

      // 이메일 인증 토큰 생성 및 발송
      await context.services.auth.sendVerificationEmail(user);

      // JWT 토큰 생성
      const tokens = await context.services.auth.generateTokens(user);

      return {
        user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn
      };
    },

    async login(parent, { input }, context: GraphQLContext) {
      // 사용자 조회
      const user = await context.services.user.findByEmail(input.email);
      if (!user) {
        throw new GraphQLError('Invalid credentials', {
          extensions: { code: 'INVALID_CREDENTIALS' }
        });
      }

      // 비밀번호 검증
      const isValid = await context.services.auth.verifyPassword(
        input.password,
        user.passwordHash
      );
      if (!isValid) {
        throw new GraphQLError('Invalid credentials', {
          extensions: { code: 'INVALID_CREDENTIALS' }
        });
      }

      // 활성 상태 체크
      if (!user.isActive) {
        throw new GraphQLError('Account is disabled', {
          extensions: { code: 'ACCOUNT_DISABLED' }
        });
      }

      // 마지막 로그인 시간 업데이트
      await context.services.user.updateLastLogin(user.id);

      // 활동 로그 기록
      await context.services.user.logActivity(user.id, 'login', {
        ipAddress: context.req.ip,
        userAgent: context.req.headers['user-agent']
      });

      // JWT 토큰 생성
      const tokens = await context.services.auth.generateTokens(user);

      return {
        user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn
      };
    },

    async logout(parent, args, context: GraphQLContext) {
      if (!context.user) {
        throw new GraphQLError('Not authenticated', {
          extensions: { code: 'UNAUTHENTICATED' }
        });
      }

      // Refresh Token 무효화
      await context.services.auth.revokeRefreshTokens(context.user.id);

      // 활동 로그 기록
      await context.services.user.logActivity(context.user.id, 'logout');

      return true;
    },

    async refreshToken(parent, { token }, context: GraphQLContext) {
      // Refresh Token 검증
      const payload = await context.services.auth.verifyRefreshToken(token);

      // 새 토큰 생성
      const user = await context.services.user.findById(payload.userId);
      if (!user) {
        throw new GraphQLError('User not found', {
          extensions: { code: 'USER_NOT_FOUND' }
        });
      }

      const tokens = await context.services.auth.generateTokens(user);

      return {
        user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn
      };
    },

    async changePassword(parent, { input }, context: GraphQLContext) {
      if (!context.user) {
        throw new GraphQLError('Not authenticated', {
          extensions: { code: 'UNAUTHENTICATED' }
        });
      }

      // 현재 비밀번호 검증
      const user = await context.services.user.findById(context.user.id);
      const isValid = await context.services.auth.verifyPassword(
        input.oldPassword,
        user.passwordHash
      );

      if (!isValid) {
        throw new GraphQLError('Invalid password', {
          extensions: { code: 'INVALID_PASSWORD' }
        });
      }

      // 새 비밀번호 해싱
      const newPasswordHash = await context.services.auth.hashPassword(input.newPassword);

      // 비밀번호 업데이트
      await context.services.user.updatePassword(context.user.id, newPasswordHash);

      // 모든 Refresh Token 무효화
      await context.services.auth.revokeRefreshTokens(context.user.id);

      // 활동 로그 기록
      await context.services.user.logActivity(context.user.id, 'password_change');

      return true;
    },

    async requestPasswordReset(parent, { email }, context: GraphQLContext) {
      const user = await context.services.user.findByEmail(email);

      // 보안상 사용자가 있든 없든 같은 응답 (타이밍 공격 방지)
      if (user) {
        await context.services.auth.sendPasswordResetEmail(user);
      }

      return true;
    },

    async resetPassword(parent, { input }, context: GraphQLContext) {
      // 토큰 검증
      const tokenData = await context.services.auth.verifyPasswordResetToken(input.token);

      // 새 비밀번호 해싱
      const newPasswordHash = await context.services.auth.hashPassword(input.newPassword);

      // 비밀번호 업데이트
      await context.services.user.updatePassword(tokenData.userId, newPasswordHash);

      // 토큰 사용 처리
      await context.services.auth.markTokenAsUsed(input.token);

      // 모든 Refresh Token 무효화
      await context.services.auth.revokeRefreshTokens(tokenData.userId);

      // 활동 로그 기록
      await context.services.user.logActivity(tokenData.userId, 'password_reset');

      return true;
    },

    async verifyEmail(parent, { token }, context: GraphQLContext) {
      // 토큰 검증
      const tokenData = await context.services.auth.verifyEmailToken(token);

      // 이메일 인증 처리
      await context.services.user.markEmailAsVerified(tokenData.userId);

      // 활동 로그 기록
      await context.services.user.logActivity(tokenData.userId, 'email_verified');

      return true;
    },

    async resendVerificationEmail(parent, args, context: GraphQLContext) {
      if (!context.user) {
        throw new GraphQLError('Not authenticated', {
          extensions: { code: 'UNAUTHENTICATED' }
        });
      }

      if (context.user.emailVerified) {
        throw new GraphQLError('Email already verified', {
          extensions: { code: 'EMAIL_ALREADY_VERIFIED' }
        });
      }

      await context.services.auth.sendVerificationEmail(context.user);

      return true;
    }
  }
};
```

---

## 3.6 Service 레이어 작성

### 프롬프트 3-6: Service 클래스 구현

```
다음 Service 클래스들을 구현해주세요:

1. UserService (generated 확장)
   - backend/src/custom/services/user-service.ts
   - 메서드:
     - findByEmail(email)
     - updateLastLogin(userId)
     - updatePassword(userId, hash)
     - markEmailAsVerified(userId)
     - logActivity(userId, action, metadata)

2. AuthService
   - backend/src/custom/services/auth-service.ts
   - 메서드:
     - hashPassword(password)
     - verifyPassword(password, hash)
     - generateTokens(user)
     - verifyAccessToken(token)
     - verifyRefreshToken(token)
     - revokeRefreshTokens(userId)
     - sendVerificationEmail(user)
     - sendPasswordResetEmail(user)
     - verifyEmailToken(token)
     - verifyPasswordResetToken(token)

3. RoleService
   - backend/src/custom/services/role-service.ts
   - 메서드:
     - assignRole(userId, roleName)
     - removeRole(userId, roleName)
     - getUserRoles(userId)
     - getRolePermissions(roleId)

4. PermissionService
   - backend/src/custom/services/permission-service.ts
   - 메서드:
     - checkPermission(userId, resource, action)
     - getUserPermissions(userId)

요구사항:
- TypeScript strict mode
- 에러 처리 (custom error classes)
- 로깅 (winston)
- 트랜잭션 지원
```

**예시 구현:**

```typescript
// backend/src/custom/services/auth-service.ts
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';
import { GraphQLError } from 'graphql';
import type { UserModel } from '../../types/models';
import type { JWTPayload, TokenPair } from '../../types/auth';

export class AuthService {
  constructor(private db: Pool) {}

  async hashPassword(password: string): Promise<string> {
    const saltRounds = 10;
    return await bcrypt.hash(password, saltRounds);
  }

  async verifyPassword(password: string, hash: string): Promise<boolean> {
    return await bcrypt.compare(password, hash);
  }

  async generateTokens(user: UserModel): Promise<TokenPair> {
    const accessTokenPayload: JWTPayload = {
      userId: user.id,
      email: user.email,
      roles: await this.getUserRoles(user.id),
      type: 'access'
    };

    const refreshTokenPayload: JWTPayload = {
      userId: user.id,
      email: user.email,
      roles: [],
      type: 'refresh'
    };

    const accessToken = jwt.sign(
      accessTokenPayload,
      process.env.JWT_ACCESS_SECRET!,
      { expiresIn: '15m' }
    );

    const refreshToken = jwt.sign(
      refreshTokenPayload,
      process.env.JWT_REFRESH_SECRET!,
      { expiresIn: '7d' }
    );

    // Refresh Token DB에 저장
    await this.db.query(
      `INSERT INTO refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '7 days')`,
      [user.id, refreshToken]
    );

    return {
      accessToken,
      refreshToken,
      expiresIn: 15 * 60 // 15 minutes in seconds
    };
  }

  async verifyAccessToken(token: string): Promise<JWTPayload> {
    try {
      const payload = jwt.verify(
        token,
        process.env.JWT_ACCESS_SECRET!
      ) as JWTPayload;

      if (payload.type !== 'access') {
        throw new GraphQLError('Invalid token type');
      }

      return payload;
    } catch (error) {
      throw new GraphQLError('Invalid or expired token', {
        extensions: { code: 'INVALID_TOKEN' }
      });
    }
  }

  async verifyRefreshToken(token: string): Promise<JWTPayload> {
    try {
      // JWT 검증
      const payload = jwt.verify(
        token,
        process.env.JWT_REFRESH_SECRET!
      ) as JWTPayload;

      if (payload.type !== 'refresh') {
        throw new GraphQLError('Invalid token type');
      }

      // DB에서 토큰 확인
      const result = await this.db.query(
        `SELECT * FROM refresh_tokens
         WHERE token = $1 AND expires_at > NOW()`,
        [token]
      );

      if (result.rows.length === 0) {
        throw new GraphQLError('Token not found or expired');
      }

      return payload;
    } catch (error) {
      throw new GraphQLError('Invalid or expired refresh token', {
        extensions: { code: 'INVALID_REFRESH_TOKEN' }
      });
    }
  }

  async revokeRefreshTokens(userId: string): Promise<void> {
    await this.db.query(
      `DELETE FROM refresh_tokens WHERE user_id = $1`,
      [userId]
    );
  }

  private async getUserRoles(userId: string): Promise<string[]> {
    const result = await this.db.query(
      `SELECT r.name
       FROM user_roles ur
       JOIN roles r ON ur.role_id = r.id
       WHERE ur.user_id = $1`,
      [userId]
    );

    return result.rows.map(row => row.name);
  }

  async sendVerificationEmail(user: UserModel): Promise<void> {
    // 토큰 생성
    const token = crypto.randomUUID();

    // DB에 저장
    await this.db.query(
      `INSERT INTO email_verification_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '24 hours')`,
      [user.id, token]
    );

    // 이메일 발송 (실제 구현 필요)
    const verificationLink = `${process.env.APP_URL}/verify-email?token=${token}`;
    console.log(`Verification link for ${user.email}: ${verificationLink}`);

    // TODO: 실제 이메일 발송 로직
  }

  async verifyEmailToken(token: string): Promise<{ userId: string }> {
    const result = await this.db.query(
      `SELECT user_id FROM email_verification_tokens
       WHERE token = $1 AND expires_at > NOW()`,
      [token]
    );

    if (result.rows.length === 0) {
      throw new GraphQLError('Invalid or expired verification token', {
        extensions: { code: 'INVALID_VERIFICATION_TOKEN' }
      });
    }

    // 토큰 삭제
    await this.db.query(
      `DELETE FROM email_verification_tokens WHERE token = $1`,
      [token]
    );

    return { userId: result.rows[0].user_id };
  }

  // 비밀번호 재설정 관련 메서드들...
}
```

---

## 3.7 Middleware 작성

### 프롬프트 3-7: 인증/권한 Middleware 구현

```
다음 Middleware들을 구현해주세요:

1. Authentication Middleware
   - backend/src/middleware/auth.ts
   - JWT 토큰 검증
   - Context에 user 정보 추가

2. Authorization Middleware
   - backend/src/middleware/authorization.ts
   - 권한 체크 데코레이터
   - @RequireAuth(), @RequireRole('admin')

3. Rate Limiting
   - backend/src/middleware/rate-limit.ts
   - IP 기반 요청 제한

4. Logging
   - backend/src/middleware/logger.ts
   - 요청/응답 로깅

5. Error Handling
   - backend/src/middleware/error-handler.ts
   - GraphQL 에러 포맷팅
```

**예시 구현:**

```typescript
// backend/src/middleware/auth.ts
import type { GraphQLContext } from '../types/context';
import { AuthService } from '../custom/services/auth-service';

export async function authMiddleware(
  req: any,
  db: Pool
): Promise<Partial<GraphQLContext>> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { user: undefined };
  }

  const token = authHeader.substring(7);

  try {
    const authService = new AuthService(db);
    const payload = await authService.verifyAccessToken(token);

    // 사용자 정보 조회
    const result = await db.query(
      `SELECT * FROM users WHERE id = $1 AND is_active = true`,
      [payload.userId]
    );

    if (result.rows.length === 0) {
      return { user: undefined };
    }

    return { user: result.rows[0] };
  } catch (error) {
    return { user: undefined };
  }
}

// backend/src/middleware/authorization.ts
import { GraphQLError } from 'graphql';
import type { GraphQLContext } from '../types/context';

export function requireAuth() {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const context: GraphQLContext = args[2];

      if (!context.user) {
        throw new GraphQLError('Authentication required', {
          extensions: { code: 'UNAUTHENTICATED' }
        });
      }

      return originalMethod.apply(this, args);
    };

    return descriptor;
  };
}

export function requireRole(...roles: string[]) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const context: GraphQLContext = args[2];

      if (!context.user) {
        throw new GraphQLError('Authentication required', {
          extensions: { code: 'UNAUTHENTICATED' }
        });
      }

      const userRoles = await context.services.role.getUserRoles(context.user.id);
      const hasRole = roles.some(role => userRoles.includes(role));

      if (!hasRole) {
        throw new GraphQLError('Insufficient permissions', {
          extensions: { code: 'FORBIDDEN' }
        });
      }

      return originalMethod.apply(this, args);
    };

    return descriptor;
  };
}
```

---

## 3.8 서버 설정

### 프롬프트 3-8: Apollo Server 설정

```
Apollo Server를 설정하고 모든 구성 요소를 통합해주세요:

파일:
- backend/src/index.ts

요구사항:
1. Apollo Server 설정
2. Context 생성
3. Middleware 적용
4. DataLoader 설정
5. Error formatting
6. CORS 설정
7. Health check endpoint

포트: ${BACKEND_PORT || 4000}
```

**예시 구현:**

```typescript
// backend/src/index.ts
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import express from 'express';
import cors from 'cors';
import { readFileSync } from 'fs';
import { join } from 'path';
import { Pool } from 'pg';
import DataLoader from 'dataloader';

import { resolvers } from './resolvers';
import { authMiddleware } from './middleware/auth';
import { createServices } from './services';
import { createLoaders } from './loaders';

// GraphQL Schema 로드
const typeDefs = [
  readFileSync(join(__dirname, 'generated/schema.graphql'), 'utf-8'),
  readFileSync(join(__dirname, 'custom/auth-schema.graphql'), 'utf-8')
];

// Database Pool
const db = new Pool({
  host: process.env.APP_DB_HOST,
  port: parseInt(process.env.APP_DB_PORT || '5432'),
  database: process.env.APP_DB_NAME,
  user: process.env.APP_DB_USER,
  password: process.env.APP_DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
  max: 20
});

// Apollo Server 설정
const server = new ApolloServer({
  typeDefs,
  resolvers,
  formatError: (error) => {
    console.error('GraphQL Error:', error);
    return error;
  },
  introspection: process.env.NODE_ENV !== 'production',
});

// Express 앱
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Apollo Server 시작
await server.start();

// GraphQL endpoint
app.use(
  '/graphql',
  expressMiddleware(server, {
    context: async ({ req }) => {
      // Authentication
      const authContext = await authMiddleware(req, db);

      // Services
      const services = createServices(db);

      // DataLoaders
      const loaders = createLoaders(db);

      return {
        ...authContext,
        db,
        services,
        loaders,
        req
      };
    }
  })
);

// 서버 시작
const PORT = process.env.BACKEND_PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 Server ready at http://localhost:${PORT}/graphql`);
});
```

---

## 체크리스트

Backend 개발 단계 완료 전 확인사항:

- [ ] 코드 생성 시스템 구축 완료
- [ ] Database DDL 생성 및 적용 완료
- [ ] GraphQL 스키마 생성 완료
- [ ] TypeScript 타입 생성 완료
- [ ] Resolver 구현 완료 (CRUD + Auth)
- [ ] Service 레이어 구현 완료
  - [ ] UserService
  - [ ] AuthService
  - [ ] RoleService
  - [ ] PermissionService
- [ ] Middleware 구현 완료
  - [ ] Authentication
  - [ ] Authorization
  - [ ] Rate Limiting
  - [ ] Logging
  - [ ] Error Handling
- [ ] Apollo Server 설정 완료
- [ ] 원격 PostgreSQL 연결 테스트 완료
- [ ] API 테스트 (Postman/Insomnia)
- [ ] 에러 처리 검증
- [ ] 로깅 확인
