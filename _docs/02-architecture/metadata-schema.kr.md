# 메타데이터 스키마 정의

이 문서는 메타데이터 기반 코드 생성의 핵심인 메타데이터 스키마를 정의합니다.

## 📋 메타데이터 파일 구조

```
metadata/
├── tables/              # 테이블 정의
│   ├── users.json
│   ├── posts.json
│   ├── comments.json
│   └── categories.json
├── relationships/       # 관계 정의
│   ├── user-posts.json
│   ├── post-comments.json
│   └── post-categories.json
├── apis/               # API 정의 (선택적)
│   └── custom-queries.json
└── config.json         # 전역 설정
```

## 🗂️ 테이블 메타데이터 스키마

### 기본 구조
```typescript
interface TableMetadata {
  tableName: string;                    // 테이블명 (snake_case)
  description?: string;                 // 테이블 설명
  columns: ColumnDefinition[];          // 컬럼 정의
  indexes?: IndexDefinition[];          // 인덱스 정의
  uniqueConstraints?: UniqueConstraint[]; // 유니크 제약조건
  checks?: CheckConstraint[];           // 체크 제약조건
  softDelete?: boolean;                 // 소프트 삭제 여부
  timestamps?: boolean;                 // created_at, updated_at 자동 추가
  auditing?: boolean;                   // created_by, updated_by 추가
  graphql?: GraphQLConfig;              // GraphQL 설정
}
```

### 전체 예시
```json
{
  "tableName": "posts",
  "description": "블로그 포스트 테이블",
  "timestamps": true,
  "softDelete": true,
  "auditing": true,
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "primaryKey": true,
      "generated": "uuid",
      "comment": "고유 식별자"
    },
    {
      "name": "title",
      "type": "varchar",
      "length": 200,
      "nullable": false,
      "comment": "포스트 제목"
    },
    {
      "name": "slug",
      "type": "varchar",
      "length": 250,
      "nullable": false,
      "unique": true,
      "comment": "URL 친화적 제목"
    },
    {
      "name": "content",
      "type": "text",
      "nullable": false,
      "comment": "포스트 본문 (Markdown)"
    },
    {
      "name": "excerpt",
      "type": "varchar",
      "length": 500,
      "nullable": true,
      "comment": "요약"
    },
    {
      "name": "status",
      "type": "enum",
      "enum": ["DRAFT", "PUBLISHED", "ARCHIVED"],
      "default": "DRAFT",
      "nullable": false,
      "comment": "포스트 상태"
    },
    {
      "name": "view_count",
      "type": "int",
      "default": 0,
      "nullable": false,
      "comment": "조회수"
    },
    {
      "name": "published_at",
      "type": "timestamp",
      "nullable": true,
      "comment": "발행 일시"
    },
    {
      "name": "user_id",
      "type": "uuid",
      "nullable": false,
      "foreignKey": {
        "table": "users",
        "column": "id",
        "onDelete": "CASCADE",
        "onUpdate": "CASCADE"
      },
      "comment": "작성자 ID"
    },
    {
      "name": "category_id",
      "type": "uuid",
      "nullable": true,
      "foreignKey": {
        "table": "categories",
        "column": "id",
        "onDelete": "SET NULL",
        "onUpdate": "CASCADE"
      },
      "comment": "카테고리 ID"
    },
    {
      "name": "metadata",
      "type": "jsonb",
      "nullable": true,
      "default": "{}",
      "comment": "추가 메타데이터 (태그, SEO 등)"
    }
  ],
  "indexes": [
    {
      "name": "idx_posts_user_id",
      "columns": ["user_id"],
      "comment": "작성자별 조회 최적화"
    },
    {
      "name": "idx_posts_status",
      "columns": ["status"],
      "comment": "상태별 필터링 최적화"
    },
    {
      "name": "idx_posts_published_at",
      "columns": ["published_at"],
      "order": "DESC",
      "where": "status = 'PUBLISHED'",
      "comment": "발행된 포스트 정렬 최적화"
    },
    {
      "name": "idx_posts_slug",
      "columns": ["slug"],
      "unique": true,
      "comment": "Slug 중복 방지 및 조회 최적화"
    }
  ],
  "uniqueConstraints": [
    {
      "name": "uq_posts_title_user",
      "columns": ["title", "user_id"],
      "comment": "사용자당 동일 제목 중복 방지"
    }
  ],
  "checks": [
    {
      "name": "chk_posts_view_count",
      "expression": "view_count >= 0",
      "comment": "조회수는 0 이상이어야 함"
    }
  ],
  "graphql": {
    "queries": {
      "findOne": true,
      "findMany": true,
      "count": true
    },
    "mutations": {
      "create": true,
      "update": true,
      "delete": true
    },
    "subscriptions": {
      "onCreate": true,
      "onUpdate": false,
      "onDelete": false
    }
  }
}
```

## 📊 컬럼 정의 스키마

### ColumnDefinition
```typescript
interface ColumnDefinition {
  name: string;                     // 컬럼명 (snake_case)
  type: DataType;                   // 데이터 타입
  length?: number;                  // 길이 (varchar, char 등)
  precision?: number;               // 정밀도 (decimal)
  scale?: number;                   // 소수점 자릿수 (decimal)
  primaryKey?: boolean;             // 기본키 여부
  generated?: GenerationType;       // 자동 생성 타입
  nullable?: boolean;               // NULL 허용 (기본: true)
  unique?: boolean;                 // 유니크 여부
  default?: any;                    // 기본값
  enum?: string[];                  // Enum 값 목록
  foreignKey?: ForeignKeyDefinition; // 외래키 정의
  onUpdate?: string;                // UPDATE 시 동작
  comment?: string;                 // 컬럼 설명
  exclude?: ExcludeTarget[];        // 제외 대상 (graphql, api 등)
  validation?: ValidationRules;      // 검증 규칙
}
```

### 데이터 타입
```typescript
type DataType =
  // 숫자형
  | 'int' | 'integer' | 'bigint' | 'smallint'
  | 'decimal' | 'numeric' | 'float' | 'double'

  // 문자열
  | 'varchar' | 'char' | 'text'

  // UUID
  | 'uuid'

  // 날짜/시간
  | 'date' | 'time' | 'timestamp' | 'datetime'

  // Boolean
  | 'boolean' | 'bool'

  // JSON
  | 'json' | 'jsonb'

  // Binary
  | 'bytea' | 'blob'

  // Enum
  | 'enum'

  // Array (PostgreSQL)
  | 'text[]' | 'int[]' | 'uuid[]';
```

### 자동 생성 타입
```typescript
type GenerationType =
  | 'uuid'        // UUID 자동 생성
  | 'increment'   // 자동 증가 (AUTO_INCREMENT)
  | 'identity'    // IDENTITY (PostgreSQL 10+)
  | 'rowid';      // ROWID (Oracle)
```

### 외래키 정의
```typescript
interface ForeignKeyDefinition {
  table: string;          // 참조 테이블
  column: string;         // 참조 컬럼
  onDelete?: ReferentialAction;  // 삭제 시 동작
  onUpdate?: ReferentialAction;  // 업데이트 시 동작
}

type ReferentialAction =
  | 'CASCADE'      // 연쇄 동작
  | 'SET NULL'     // NULL로 설정
  | 'SET DEFAULT'  // 기본값으로 설정
  | 'RESTRICT'     // 제한 (오류 발생)
  | 'NO ACTION';   // 동작 없음
```

### 검증 규칙
```typescript
interface ValidationRules {
  min?: number;              // 최소값 (숫자)
  max?: number;              // 최대값 (숫자)
  minLength?: number;        // 최소 길이 (문자열)
  maxLength?: number;        // 최대 길이 (문자열)
  pattern?: string;          // 정규식 패턴
  email?: boolean;           // 이메일 형식 검증
  url?: boolean;             // URL 형식 검증
  custom?: string;           // 커스텀 검증 함수명
}
```

## 🔗 관계 메타데이터 스키마

### RelationshipMetadata
```typescript
interface RelationshipMetadata {
  name: string;                     // 관계명
  type: RelationType;               // 관계 타입
  from: RelationEndpoint;           // From 엔티티
  to: RelationEndpoint;             // To 엔티티
  cascade?: CascadeOptions;         // Cascade 옵션
  eager?: boolean;                  // Eager loading 여부
  lazy?: boolean;                   // Lazy loading 여부
  nullable?: boolean;               // NULL 허용 여부
  comment?: string;                 // 관계 설명
}

type RelationType =
  | 'one-to-one'
  | 'one-to-many'
  | 'many-to-one'
  | 'many-to-many';

interface RelationEndpoint {
  table: string;        // 테이블명
  column?: string;      // 외래키 컬럼 (many-to-one, one-to-one)
  relation: string;     // 관계 프로퍼티명 (Entity에서 사용)
}

interface CascadeOptions {
  insert?: boolean;     // INSERT 연쇄
  update?: boolean;     // UPDATE 연쇄
  delete?: boolean;     // DELETE 연쇄
}
```

### One-to-Many 예시
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
    "relation": "user"
  },
  "cascade": {
    "insert": false,
    "update": true,
    "delete": true
  },
  "eager": false,
  "comment": "사용자와 포스트의 1:N 관계"
}
```

### Many-to-Many 예시
```json
{
  "name": "posts-tags",
  "type": "many-to-many",
  "from": {
    "table": "posts",
    "relation": "tags"
  },
  "to": {
    "table": "tags",
    "relation": "posts"
  },
  "joinTable": {
    "name": "post_tags",
    "columns": [
      {
        "name": "post_id",
        "type": "uuid",
        "foreignKey": { "table": "posts", "column": "id", "onDelete": "CASCADE" }
      },
      {
        "name": "tag_id",
        "type": "uuid",
        "foreignKey": { "table": "tags", "column": "id", "onDelete": "CASCADE" }
      },
      {
        "name": "created_at",
        "type": "timestamp",
        "default": "now()"
      }
    ]
  },
  "comment": "포스트와 태그의 N:M 관계"
}
```

## ⚙️ 전역 설정 (config.json)

```json
{
  "project": {
    "name": "my-project",
    "version": "1.0.0",
    "description": "My awesome project"
  },
  "database": {
    "type": "postgres",
    "naming": {
      "strategy": "snake_case",
      "tablePrefix": "",
      "columnPrefix": ""
    }
  },
  "graphql": {
    "playground": true,
    "introspection": true,
    "naming": {
      "strategy": "camelCase"
    },
    "pagination": {
      "default": 20,
      "max": 100
    }
  },
  "generation": {
    "overwrite": {
      "entities": true,
      "schema": true,
      "resolvers": false,
      "services": false
    },
    "templates": {
      "entity": "templates/entity.hbs",
      "resolver": "templates/resolver.hbs",
      "service": "templates/service.hbs"
    }
  },
  "features": {
    "softDelete": true,
    "timestamps": true,
    "auditing": false,
    "versioning": false
  }
}
```

## 🎨 GraphQL 설정

### GraphQLConfig
```typescript
interface GraphQLConfig {
  queries?: {
    findOne?: boolean | string;      // true 또는 커스텀 쿼리명
    findMany?: boolean | string;
    count?: boolean | string;
    custom?: CustomQuery[];
  };
  mutations?: {
    create?: boolean | string;
    update?: boolean | string;
    delete?: boolean | string;
    custom?: CustomMutation[];
  };
  subscriptions?: {
    onCreate?: boolean | string;
    onUpdate?: boolean | string;
    onDelete?: boolean | string;
    custom?: CustomSubscription[];
  };
  exclude?: string[];                // 제외할 필드 목록
  rename?: { [key: string]: string }; // 필드명 변경
}
```

### 커스텀 쿼리 예시
```json
{
  "graphql": {
    "queries": {
      "findOne": "post",
      "findMany": "posts",
      "count": "postCount",
      "custom": [
        {
          "name": "publishedPosts",
          "description": "발행된 포스트만 조회",
          "args": [
            { "name": "limit", "type": "Int", "default": 20 },
            { "name": "offset", "type": "Int", "default": 0 }
          ],
          "return": "[Post!]!",
          "filter": { "status": "PUBLISHED" }
        }
      ]
    },
    "mutations": {
      "custom": [
        {
          "name": "publishPost",
          "description": "포스트 발행",
          "args": [{ "name": "id", "type": "ID!" }],
          "return": "Post!",
          "implementation": "custom/mutations/publish-post.ts"
        }
      ]
    },
    "exclude": ["password", "deleted_at"],
    "rename": {
      "user_id": "authorId"
    }
  }
}
```

## 🔍 검증 규칙

메타데이터 정의 시 자동 검증:

### 필수 검증
- ✅ 테이블명 중복 체크
- ✅ 컬럼명 중복 체크 (같은 테이블 내)
- ✅ 외래키 참조 테이블/컬럼 존재 체크
- ✅ 데이터 타입 유효성 체크
- ✅ Enum 값 유효성 체크

### 경고 검증
- ⚠️ 기본키 누락
- ⚠️ 인덱스 누락 (외래키)
- ⚠️ timestamp 필드 누락
- ⚠️ 너무 긴 varchar (성능 고려)

### 검증 명령어
```bash
# 메타데이터 유효성 검사
npm run metadata:validate

# 특정 파일만 검증
npm run metadata:validate -- metadata/tables/users.json

# 상세 리포트 생성
npm run metadata:validate -- --verbose
```

## 📖 예제 모음

### 사용자 테이블 (users.json)
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
      "generated": "uuid"
    },
    {
      "name": "email",
      "type": "varchar",
      "length": 255,
      "unique": true,
      "nullable": false,
      "validation": { "email": true }
    },
    {
      "name": "password",
      "type": "varchar",
      "length": 255,
      "nullable": false,
      "exclude": ["graphql", "api"]
    },
    {
      "name": "role",
      "type": "enum",
      "enum": ["USER", "ADMIN", "MODERATOR"],
      "default": "USER",
      "nullable": false
    },
    {
      "name": "profile",
      "type": "jsonb",
      "default": "{}",
      "comment": "프로필 정보 (이름, 아바타 등)"
    }
  ],
  "graphql": {
    "queries": { "findOne": true, "findMany": true },
    "mutations": { "create": true, "update": true, "delete": true },
    "exclude": ["password"]
  }
}
```

### 댓글 테이블 (comments.json)
```json
{
  "tableName": "comments",
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
      "validation": { "minLength": 1, "maxLength": 5000 }
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
    },
    {
      "name": "parent_id",
      "type": "uuid",
      "nullable": true,
      "foreignKey": {
        "table": "comments",
        "column": "id",
        "onDelete": "CASCADE"
      },
      "comment": "대댓글을 위한 부모 댓글 ID"
    }
  ],
  "indexes": [
    { "columns": ["post_id"] },
    { "columns": ["user_id"] }
  ]
}
```

## 🔄 마이그레이션 생성

메타데이터 변경 시 자동 마이그레이션 생성:

```bash
# 메타데이터 변경 감지 및 마이그레이션 생성
npm run migration:generate -- -n AddProfileToUsers

# 생성된 마이그레이션 파일 확인
cat migrations/1634567890123-AddProfileToUsers.ts
```

## 📚 관련 문서

- [개발 워크플로우](../guidelines/02-development-workflow.md)
- [데이터베이스 관리](../guidelines/03-database-management.md)
- [GraphQL API 설계](../api/01-graphql-design.md)
