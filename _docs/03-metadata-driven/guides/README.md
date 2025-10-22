# 실전 가이드 및 템플릿 (Practical Guides & Templates)

> 실제 개발에 필요한 상세 가이드라인, 구현 예제, 코드 템플릿을 제공합니다.

## 📘 개요

이 디렉토리는 메타데이터 기반 개발을 실제로 구현하기 위한 구체적인 가이드와 템플릿을 제공합니다. 개념을 이해한 후, 이 가이드를 참고하여 실제 프로젝트에 적용할 수 있습니다.

---

## 📚 문서 목록

### 1. [개발 가이드라인](./META-DRIVEN-DEVELOPMENT-GUIDELINES.md)

실전 개발을 위한 상세한 가이드라인과 예제를 제공합니다.

**주요 내용:**

#### 개발 환경 설정
```bash
# Node.js 20 LTS 설치 확인
node --version  # v20.x.x

# PostgreSQL 14+ 설치 확인
psql --version  # PostgreSQL 14.x

# pnpm 설치 (권장)
npm install -g pnpm

# 프로젝트 초기화
pnpm init
pnpm add typescript @types/node tsx
```

#### 메타데이터 정의 가이드
- **명명 규칙**
  - Database: `snake_case` (예: `user_profiles`)
  - GraphQL: `PascalCase` (예: `UserProfile`)
  - TypeScript: `camelCase` (예: `userProfile`)

- **필드 타입별 정의 예시**
  - 문자열 필드 (email, name, etc.)
  - 숫자 필드 (age, price, etc.)
  - 날짜/시간 필드
  - Boolean 필드
  - JSON/JSONB 필드
  - 관계 필드 (Foreign Key)

- **관계 정의 패턴**
  - One-to-One
  - One-to-Many
  - Many-to-Many
  - Self-referencing

#### 코드 생성 및 커스터마이징
- 생성 코드 vs 커스텀 코드 구분
- 디렉토리 구조 규칙
  ```
  src/
  ├── generated/        # 자동 생성 (수정 금지)
  │   ├── types.ts
  │   ├── resolvers/
  │   └── services/
  └── custom/           # 커스텀 코드 (여기에 작성)
      ├── resolvers/
      ├── services/
      └── middleware/
  ```
- 확장 패턴 (상속, Composition)

#### TypeScript 타입 시스템
- 자동 생성되는 타입
- 타입 확장 패턴
- Generic 활용

#### GraphQL 스키마 설계
- Schema-First vs Code-First
- Resolver 패턴
- DataLoader 활용

#### React 컴포넌트 패턴
- Form 컴포넌트
- Table 컴포넌트
- Custom Hook

#### 테스트 전략
- Unit Test (Jest)
- Integration Test
- E2E Test (Playwright)

#### 배포 및 CI/CD
- Docker 배포
- GitHub Actions
- 환경별 설정

#### 트러블슈팅
- 자주 발생하는 문제
- 해결 방법
- 디버깅 팁

**읽어야 할 사람:**
- 백엔드 개발자 (필수)
- 프론트엔드 개발자 (필수)
- DevOps 엔지니어 (배포 섹션)

---

### 2. [코드 생성 템플릿](./CODE-GENERATION-TEMPLATES.md)

실제 코드를 생성하는 Generator 구현 템플릿을 제공합니다.

**주요 내용:**

#### Generator 기본 구조
```typescript
// generators/base-generator.ts
import prettier from 'prettier';
import { MetadataService } from '../services/metadata-service';
import type { TableMetadata } from '../types/metadata';

export abstract class BaseGenerator {
  protected metadata: MetadataService;

  constructor(metadata: MetadataService) {
    this.metadata = metadata;
  }

  abstract generate(tableName: string): Promise<string>;

  protected async format(code: string): Promise<string> {
    return prettier.format(code, {
      parser: 'typescript',
      semi: true,
      singleQuote: true,
      trailingComma: 'all',
    });
  }
}
```

#### Database DDL Generator
- CREATE TABLE 생성
- ALTER TABLE 생성
- INDEX 생성
- CONSTRAINT 생성

#### GraphQL Schema Generator
- Type 정의 생성
- Input 정의 생성
- Query/Mutation 생성
- Subscription 생성

#### TypeScript Types Generator
- Interface 생성
- Type Alias 생성
- Enum 생성
- Generic Type 생성

#### Resolver Generator
- Query Resolver
- Mutation Resolver
- Field Resolver
- DataLoader 통합

#### React Form Generator
- React Hook Form 통합
- Zod Validation
- 필드별 Input 컴포넌트
- Submit Handler

#### React Table Generator
- TanStack Table 통합
- 정렬/필터링
- 페이지네이션
- 선택 기능

#### Migration Generator
- Up/Down 마이그레이션
- 스키마 변경 감지
- 롤백 지원

**읽어야 할 사람:**
- 백엔드 개발자 (필수)
- 시스템 아키텍트 (필수)
- 프론트엔드 개발자 (React Generator 부분)

---

## 🛠️ 실전 예제

### 예제 1: 사용자 테이블 정의

```sql
-- 메타데이터 정의
INSERT INTO mappings_table (
  schema_name, table_name, graphql_type,
  label, description
) VALUES (
  'public', 'users', 'User',
  '사용자', '시스템 사용자 정보'
);

-- 컬럼 정의
INSERT INTO mappings_column (
  table_id, schema_name, table_name,
  pg_column, pg_type, graphql_field, graphql_type,
  label, form_type, is_required
) VALUES
  ((SELECT id FROM mappings_table WHERE table_name = 'users'),
   'public', 'users',
   'email', 'VARCHAR(255)', 'email', 'String',
   '이메일', 'email', true),
  ((SELECT id FROM mappings_table WHERE table_name = 'users'),
   'public', 'users',
   'name', 'VARCHAR(100)', 'name', 'String',
   '이름', 'text', true);
```

### 예제 2: 관계 정의 (One-to-Many)

```sql
-- 사용자 → 게시글 (1:N)
INSERT INTO mappings_relation (
  from_table_id, from_column,
  to_table_id, to_column,
  relation_type, relation_name
) VALUES (
  (SELECT id FROM mappings_table WHERE table_name = 'users'),
  'id',
  (SELECT id FROM mappings_table WHERE table_name = 'posts'),
  'user_id',
  'ONE_TO_MANY',
  'posts'
);
```

### 예제 3: 코드 생성 실행

```bash
# 전체 생성
npm run generate:all

# 특정 테이블만
npm run generate:table -- users

# GraphQL만
npm run generate:graphql

# React 컴포넌트만
npm run generate:react -- users
```

### 예제 4: 커스텀 로직 추가

```typescript
// custom/services/user-service.ts
import { UserService as GeneratedUserService } from '@/generated/services';
import { hashPassword, comparePassword } from '@/utils/crypto';

export class UserService extends GeneratedUserService {
  // 생성된 메서드들은 자동으로 상속됨
  // - findById(id: string)
  // - findAll(filter?: UserFilter)
  // - create(input: CreateUserInput)
  // - update(id: string, input: UpdateUserInput)
  // - delete(id: string)

  // 커스텀 메서드 추가
  async register(email: string, password: string, name: string) {
    const hashedPassword = await hashPassword(password);
    return this.create({
      email,
      password: hashedPassword,
      name,
      role: 'USER',
    });
  }

  async login(email: string, password: string) {
    const user = await this.findByEmail(email);
    if (!user) {
      throw new Error('User not found');
    }

    const valid = await comparePassword(password, user.password);
    if (!valid) {
      throw new Error('Invalid password');
    }

    return user;
  }

  private async findByEmail(email: string) {
    const users = await this.findAll({ email });
    return users[0] || null;
  }
}
```

---

## 📖 템플릿 사용 가이드

### 1. Generator 커스터마이징

기본 Generator를 확장하여 프로젝트에 맞게 수정할 수 있습니다:

```typescript
// custom-generators/my-resolver-generator.ts
import { ResolverGenerator } from '../generators/resolver-generator';

export class MyResolverGenerator extends ResolverGenerator {
  // 템플릿 오버라이드
  protected getQueryTemplate(tableName: string): string {
    const template = super.getQueryTemplate(tableName);
    // 커스텀 로직 추가
    return template + '\n// Custom code here';
  }
}
```

### 2. 템플릿 엔진 활용

Handlebars, EJS 등의 템플릿 엔진을 사용하여 더 유연한 코드 생성 가능:

```typescript
import Handlebars from 'handlebars';

const template = Handlebars.compile(`
export interface {{typeName}} {
  {{#each fields}}
  {{name}}: {{type}};
  {{/each}}
}
`);

const code = template({
  typeName: 'User',
  fields: [
    { name: 'id', type: 'string' },
    { name: 'email', type: 'string' },
  ],
});
```

### 3. 점진적 도입

메타데이터 기반 개발을 점진적으로 도입할 수 있습니다:

1. **Phase 1**: 기존 코드는 그대로 두고 새 테이블만 메타데이터로 관리
2. **Phase 2**: CRUD 작업만 메타데이터 기반으로 전환
3. **Phase 3**: 복잡한 비즈니스 로직도 확장 패턴으로 관리

---

## ✅ 체크리스트

### 개발 환경 설정 완료
- [ ] Node.js 20+ 설치
- [ ] PostgreSQL 14+ 설치
- [ ] pnpm 설치
- [ ] 프로젝트 초기화
- [ ] 메타데이터 DB 생성

### 메타데이터 정의 완료
- [ ] 명명 규칙 문서 작성
- [ ] 모든 테이블 메타데이터 정의
- [ ] 모든 컬럼 메타데이터 정의
- [ ] 관계 메타데이터 정의
- [ ] Validation 규칙 정의

### 코드 생성 시스템 구축 완료
- [ ] Generator 구현
- [ ] 테스트 작성
- [ ] CI/CD 통합
- [ ] 문서 작성

### 커스터마이징 완료
- [ ] 확장 패턴 적용
- [ ] 비즈니스 로직 구현
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성

---

## 🔗 관련 문서

- [상위 문서로 돌아가기](../README.md)
- [개발 워크플로우](../workflows/README.md)
- [핵심 개념](../concepts/README.md)
- [Backend 디렉토리 구조](/var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/backend/nodejs/METADATA-DRIVEN-STRUCTURE.md)

---

## 📚 참고 자료

### 코드 생성 도구
- [TypeScript Compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API)
- [GraphQL Code Generator](https://the-guild.dev/graphql/codegen)
- [Prisma Generator](https://www.prisma.io/docs/concepts/components/prisma-schema/generators)

### Template Engines
- [Handlebars](https://handlebarsjs.com/)
- [EJS](https://ejs.co/)
- [Mustache](https://mustache.github.io/)

### Code Formatting
- [Prettier](https://prettier.io/)
- [ESLint](https://eslint.org/)

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/guides/`

**버전**: 1.0.0
