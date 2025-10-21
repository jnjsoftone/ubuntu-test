# TypeScript 코딩 컨벤션

> 일관성 있고 유지보수 가능한 TypeScript 코드 작성을 위한 가이드라인

## 📋 목차

1. [기본 원칙](#기본-원칙)
2. [함수 정의](#함수-정의)
3. [Export/Import 규칙](#exportimport-규칙)
4. [타입 정의](#타입-정의)
5. [명명 규칙](#명명-규칙)
6. [코드 구조](#코드-구조)
7. [주석 및 문서화](#주석-및-문서화)
8. [Best Practices](#best-practices)

---

## 기본 원칙

### 1. 명확성과 일관성
- 코드는 명확하고 읽기 쉬워야 합니다
- 프로젝트 전체에서 일관된 스타일을 유지합니다
- 암묵적 타입보다 명시적 타입을 선호합니다

### 2. 타입 안정성
- `any` 타입 사용을 최소화합니다
- 가능한 한 구체적인 타입을 정의합니다
- 제네릭을 적극 활용합니다

---

## 함수 정의

### ✅ Arrow Function 사용 (권장)

**모든 함수는 Arrow Function으로 정의합니다.**

#### 기본 함수

```typescript
// ✅ Good: Arrow function 사용
const getUserById = async (userId: string): Promise<User | null> => {
  const result = await db.findOne('users', { where: { id: userId } });
  return result.data;
};

// ❌ Bad: 일반 function 키워드
async function getUserById(userId: string): Promise<User | null> {
  const result = await db.findOne('users', { where: { id: userId } });
  return result.data;
}
```

#### 여러 매개변수

```typescript
// ✅ Good
const createUser = async (
  name: string,
  email: string,
  role: UserRole
): Promise<User> => {
  const user = await db.create('users', { name, email, role });
  return user.data;
};
```

#### 콜백 함수

```typescript
// ✅ Good: 인라인 arrow function
const userIds = users.map((user) => user.id);

const filteredUsers = users.filter((user) => user.isActive);

// 복잡한 로직은 별도 함수로 분리
const isActiveUser = (user: User): boolean => {
  return user.isActive && user.emailVerified && !user.deletedAt;
};

const activeUsers = users.filter(isActiveUser);
```

#### 단일 표현식

```typescript
// ✅ Good: 중괄호 생략 가능
const double = (n: number): number => n * 2;

const getFullName = (user: User): string => `${user.firstName} ${user.lastName}`;

// 객체 반환 시 괄호 사용
const createResponse = (data: any): Response => ({
  success: true,
  data,
  timestamp: new Date(),
});
```

#### 클래스 메서드

```typescript
// ✅ Good: 클래스 내부에서도 arrow function 사용
class UserService {
  // Arrow function으로 정의하면 this 바인딩 자동
  getUserById = async (userId: string): Promise<User | null> => {
    return this.repository.findOne(userId);
  };

  createUser = async (userData: CreateUserDto): Promise<User> => {
    return this.repository.create(userData);
  };

  // Private 메서드도 동일
  private validateEmail = (email: string): boolean => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };
}
```

#### 고차 함수 (Higher-Order Functions)

```typescript
// ✅ Good: Arrow function 반환
const createLogger = (prefix: string) => (message: string): void => {
  console.log(`[${prefix}] ${message}`);
};

const errorLogger = createLogger('ERROR');
errorLogger('Something went wrong'); // [ERROR] Something went wrong

// 복잡한 경우
const withAuth = (handler: RequestHandler) => async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const token = req.headers.authorization;
    if (!token) {
      throw new Error('Unauthorized');
    }
    await handler(req, res, next);
  } catch (error) {
    next(error);
  }
};
```

### ❌ 피해야 할 패턴

```typescript
// ❌ Bad: function 키워드 사용
function processData(data: any) {
  return data.map(function (item) {
    return item.value;
  });
}

// ✅ Good: Arrow function으로 변경
const processData = (data: DataItem[]): number[] => {
  return data.map((item) => item.value);
};
```

---

## Export/Import 규칙

### ✅ Export는 파일 하단에 일괄 처리 (권장)

**파일 내 모든 export를 파일 하단에 모아서 관리합니다.**

#### 기본 패턴

```typescript
// ✅ Good: Export는 파일 하단에 일괄 처리

// 1. Import 섹션
import { Postgres } from 'jnu-db';
import { User, UserRole } from '../types';

// 2. 타입 정의
interface UserRepository {
  findById: (id: string) => Promise<User | null>;
  create: (data: CreateUserDto) => Promise<User>;
}

interface CreateUserDto {
  name: string;
  email: string;
  role: UserRole;
}

// 3. 함수 구현
const getUserById = async (userId: string): Promise<User | null> => {
  const result = await db.findOne('users', { where: { id: userId } });
  return result.data;
};

const createUser = async (userData: CreateUserDto): Promise<User> => {
  const user = await db.create('users', userData);
  return user.data;
};

const updateUser = async (
  userId: string,
  updates: Partial<User>
): Promise<User> => {
  const user = await db.update('users', { where: { id: userId }, data: updates });
  return user.data;
};

const deleteUser = async (userId: string): Promise<void> => {
  await db.delete('users', { id: userId });
};

// 4. Export 섹션 (파일 하단)
export {
  // Types
  UserRepository,
  CreateUserDto,

  // Functions
  getUserById,
  createUser,
  updateUser,
  deleteUser,
};
```

#### 클래스 Export

```typescript
// ✅ Good: 클래스도 하단에서 export

import { Pool } from 'pg';
import { DatabaseConfig } from '../types';

// 클래스 정의
class DatabaseService {
  private pool: Pool;

  constructor(config: DatabaseConfig) {
    this.pool = new Pool(config);
  }

  connect = async (): Promise<void> => {
    await this.pool.connect();
  };

  disconnect = async (): Promise<void> => {
    await this.pool.end();
  };
}

class UserService {
  private db: DatabaseService;

  constructor(db: DatabaseService) {
    this.db = db;
  }

  getUsers = async (): Promise<User[]> => {
    return this.db.query('SELECT * FROM users');
  };
}

// Export 섹션
export {
  DatabaseService,
  UserService,
};
```

#### Default Export (사용 최소화)

```typescript
// ⚠️ Default export는 특별한 경우에만 사용

// React 컴포넌트
const UserProfile = ({ user }: { user: User }) => {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
};

// 하단에서 default export
export default UserProfile;

// Named export와 혼용 가능
export { UserProfile };
```

#### Re-export 패턴

```typescript
// ✅ Good: index.ts에서 re-export

// services/user/userService.ts
const getUserById = async (id: string): Promise<User> => { /* ... */ };
const createUser = async (data: CreateUserDto): Promise<User> => { /* ... */ };

export { getUserById, createUser };

// services/user/userValidator.ts
const validateEmail = (email: string): boolean => { /* ... */ };
const validatePassword = (password: string): boolean => { /* ... */ };

export { validateEmail, validatePassword };

// services/user/index.ts (re-export)
export { getUserById, createUser } from './userService';
export { validateEmail, validatePassword } from './userValidator';
export type { User, CreateUserDto } from './types';
```

#### 파일 구조 예시

```typescript
// ✅ Good: 완전한 파일 구조

/* ============================================
 * File: src/services/userService.ts
 * Description: User 관련 비즈니스 로직
 * ============================================ */

// 1. External imports
import { Postgres } from 'jnu-db';
import bcrypt from 'bcrypt';

// 2. Internal imports
import { User, UserRole } from '../types/user';
import { DatabaseError } from '../errors';
import { logger } from '../utils/logger';

// 3. Type definitions
interface CreateUserDto {
  name: string;
  email: string;
  password: string;
  role?: UserRole;
}

interface UpdateUserDto {
  name?: string;
  email?: string;
  password?: string;
  role?: UserRole;
}

interface UserFilters {
  role?: UserRole;
  isActive?: boolean;
  search?: string;
}

// 4. Constants
const SALT_ROUNDS = 10;
const DEFAULT_ROLE: UserRole = 'user';

// 5. Private helper functions
const hashPassword = async (password: string): Promise<string> => {
  return bcrypt.hash(password, SALT_ROUNDS);
};

const validateUserData = (data: CreateUserDto): void => {
  if (!data.email || !data.password) {
    throw new Error('Email and password are required');
  }
};

// 6. Public functions
const getUserById = async (userId: string): Promise<User | null> => {
  try {
    const result = await db.findOne<User>('users', {
      where: { id: userId },
    });
    return result.data;
  } catch (error) {
    logger.error('Failed to get user', { userId, error });
    throw new DatabaseError('Failed to get user');
  }
};

const getUsers = async (filters?: UserFilters): Promise<User[]> => {
  const where: Record<string, any> = {};

  if (filters?.role) {
    where.role = filters.role;
  }

  if (filters?.isActive !== undefined) {
    where.isActive = filters.isActive;
  }

  const result = await db.find<User>('users', { where });
  return result.data || [];
};

const createUser = async (userData: CreateUserDto): Promise<User> => {
  validateUserData(userData);

  const hashedPassword = await hashPassword(userData.password);

  const result = await db.create<User>('users', {
    ...userData,
    password: hashedPassword,
    role: userData.role || DEFAULT_ROLE,
  });

  return result.data;
};

const updateUser = async (
  userId: string,
  updates: UpdateUserDto
): Promise<User> => {
  if (updates.password) {
    updates.password = await hashPassword(updates.password);
  }

  const result = await db.update<User>('users', {
    where: { id: userId },
    data: updates,
  });

  return result.data;
};

const deleteUser = async (userId: string): Promise<void> => {
  await db.delete('users', { id: userId });
};

// 7. Export section (파일 하단)
export {
  // Types
  CreateUserDto,
  UpdateUserDto,
  UserFilters,

  // Functions
  getUserById,
  getUsers,
  createUser,
  updateUser,
  deleteUser,
};
```

### ❌ 피해야 할 패턴

```typescript
// ❌ Bad: Export와 함수 정의를 함께 사용
export const getUserById = async (userId: string): Promise<User | null> => {
  return db.findOne('users', { where: { id: userId } });
};

export const createUser = async (data: CreateUserDto): Promise<User> => {
  return db.create('users', data);
};

// ❌ Bad: 여러 곳에 흩어진 export
export const getUserById = async (userId: string): Promise<User | null> => {
  // ...
};

const createUser = async (data: CreateUserDto): Promise<User> => {
  // ...
};

export const updateUser = async (userId: string, data: any): Promise<User> => {
  // ...
};

export { createUser }; // 중간에 export
```

---

## 타입 정의

### Interface vs Type

```typescript
// ✅ Good: 객체 구조는 interface 사용
interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
}

// ✅ Good: Union, Intersection은 type 사용
type UserRole = 'admin' | 'user' | 'guest';
type ID = string | number;

// ✅ Good: Function signature는 type 사용
type AsyncHandler = (req: Request, res: Response) => Promise<void>;
```

### 제네릭 사용

```typescript
// ✅ Good: 제네릭으로 타입 안정성 확보
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

const fetchUser = async (id: string): Promise<ApiResponse<User>> => {
  try {
    const user = await db.findOne<User>('users', { where: { id } });
    return {
      success: true,
      data: user.data,
    };
  } catch (error) {
    return {
      success: false,
      error: (error as Error).message,
    };
  }
};

// 제네릭 함수
const findById = async <T>(
  table: string,
  id: string
): Promise<T | null> => {
  const result = await db.findOne<T>(table, { where: { id } });
  return result.data;
};
```

### Utility Types 활용

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// ✅ Good: Utility types 활용
type CreateUserDto = Omit<User, 'id' | 'createdAt'>;
type UpdateUserDto = Partial<Omit<User, 'id' | 'createdAt'>>;
type PublicUser = Omit<User, 'password'>;
type UserKeys = keyof User;
```

---

## 명명 규칙

### 변수 및 함수

```typescript
// ✅ Good: camelCase
const userName = 'John';
const isActive = true;
const getUserById = async (id: string) => { /* ... */ };

// ❌ Bad
const UserName = 'John';  // PascalCase는 타입/클래스용
const user_name = 'John'; // snake_case 사용 금지
```

### 타입 및 인터페이스

```typescript
// ✅ Good: PascalCase
interface User { /* ... */ }
type UserRole = 'admin' | 'user';
class UserService { /* ... */ }

// ❌ Bad
interface user { /* ... */ }
type userRole = 'admin' | 'user';
```

### 상수

```typescript
// ✅ Good: UPPER_SNAKE_CASE for constants
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';
const DEFAULT_PAGE_SIZE = 20;

// ✅ Good: camelCase for config objects
const dbConfig = {
  host: 'localhost',
  port: 5432,
};
```

### Boolean 변수

```typescript
// ✅ Good: is, has, should 접두사 사용
const isActive = true;
const hasPermission = false;
const shouldRetry = true;

// ❌ Bad
const active = true;
const permission = false;
```

### 함수명

```typescript
// ✅ Good: 동사 + 명사
const getUser = async (id: string) => { /* ... */ };
const createUser = async (data: CreateUserDto) => { /* ... */ };
const updateUser = async (id: string, data: UpdateUserDto) => { /* ... */ };
const deleteUser = async (id: string) => { /* ... */ };
const validateEmail = (email: string) => { /* ... */ };
const isValidPassword = (password: string) => { /* ... */ };

// ❌ Bad
const user = async (id: string) => { /* ... */ };        // 명사만
const doSomething = async () => { /* ... */ };            // 불명확
const data = async () => { /* ... */ };                   // 너무 일반적
```

---

## 코드 구조

### 파일 구성 순서

```typescript
/* ============================================
 * 1. File header comment
 * ============================================ */

/* ============================================
 * 2. External imports
 * ============================================ */
import { Postgres } from 'jnu-db';
import express from 'express';

/* ============================================
 * 3. Internal imports
 * ============================================ */
import { User } from '../types';
import { logger } from '../utils/logger';

/* ============================================
 * 4. Type definitions
 * ============================================ */
interface UserService {
  getUser: (id: string) => Promise<User>;
}

/* ============================================
 * 5. Constants
 * ============================================ */
const MAX_USERS = 1000;

/* ============================================
 * 6. Helper functions (private)
 * ============================================ */
const validateUser = (user: User): boolean => {
  return !!user.email && !!user.name;
};

/* ============================================
 * 7. Main functions (public)
 * ============================================ */
const getUser = async (id: string): Promise<User> => {
  // ...
};

/* ============================================
 * 8. Export section
 * ============================================ */
export {
  UserService,
  getUser,
};
```

### 함수 길이 제한

```typescript
// ✅ Good: 함수는 한 가지 일만 수행 (20-30줄 이내)
const createUser = async (userData: CreateUserDto): Promise<User> => {
  validateUserData(userData);
  const hashedPassword = await hashPassword(userData.password);
  const user = await saveUser({ ...userData, password: hashedPassword });
  await sendWelcomeEmail(user.email);
  return user;
};

// 각 단계를 별도 함수로 분리
const validateUserData = (data: CreateUserDto): void => {
  if (!data.email) throw new Error('Email is required');
  if (!data.password) throw new Error('Password is required');
};

const hashPassword = async (password: string): Promise<string> => {
  return bcrypt.hash(password, 10);
};

const saveUser = async (data: any): Promise<User> => {
  const result = await db.create('users', data);
  return result.data;
};

const sendWelcomeEmail = async (email: string): Promise<void> => {
  await emailService.send({
    to: email,
    template: 'welcome',
  });
};
```

---

## 주석 및 문서화

### JSDoc 스타일

```typescript
/**
 * 사용자를 ID로 조회합니다.
 *
 * @param userId - 조회할 사용자의 ID
 * @returns 사용자 객체 또는 null
 * @throws {DatabaseError} 데이터베이스 오류 발생 시
 *
 * @example
 * ```typescript
 * const user = await getUserById('user-123');
 * if (user) {
 *   console.log(user.name);
 * }
 * ```
 */
const getUserById = async (userId: string): Promise<User | null> => {
  try {
    const result = await db.findOne<User>('users', { where: { id: userId } });
    return result.data;
  } catch (error) {
    throw new DatabaseError('Failed to get user');
  }
};
```

### 인라인 주석

```typescript
// ✅ Good: 복잡한 로직에 대한 설명
const calculateDiscount = (price: number, userLevel: number): number => {
  // VIP 회원(레벨 5 이상)은 30% 할인
  if (userLevel >= 5) {
    return price * 0.7;
  }

  // 일반 회원(레벨 3-4)은 20% 할인
  if (userLevel >= 3) {
    return price * 0.8;
  }

  // 신규 회원(레벨 1-2)은 10% 할인
  return price * 0.9;
};

// ❌ Bad: 자명한 코드에 불필요한 주석
const sum = (a: number, b: number): number => {
  // a와 b를 더함
  return a + b;
};
```

---

## Best Practices

### 1. async/await 사용

```typescript
// ✅ Good: async/await
const getUsers = async (): Promise<User[]> => {
  const result = await db.find<User>('users', {});
  return result.data || [];
};

// ❌ Bad: Promise chains
const getUsers = (): Promise<User[]> => {
  return db.find('users', {}).then((result) => {
    return result.data || [];
  });
};
```

### 2. 에러 처리

```typescript
// ✅ Good: Try-catch with typed error
const createUser = async (data: CreateUserDto): Promise<User> => {
  try {
    const user = await db.create<User>('users', data);
    return user.data;
  } catch (error) {
    if (error instanceof DatabaseError) {
      logger.error('Database error:', error);
      throw error;
    }
    throw new Error('Unknown error occurred');
  }
};
```

### 3. Optional Chaining & Nullish Coalescing

```typescript
// ✅ Good: Optional chaining
const userName = user?.profile?.name ?? 'Anonymous';

// ❌ Bad: 중첩된 조건문
const userName = user && user.profile && user.profile.name
  ? user.profile.name
  : 'Anonymous';
```

### 4. Destructuring

```typescript
// ✅ Good: Destructuring
const createUser = async ({ name, email, role }: CreateUserDto): Promise<User> => {
  const user = await db.create('users', { name, email, role });
  return user.data;
};

// Array destructuring
const [first, second, ...rest] = users;
```

### 5. Template Literals

```typescript
// ✅ Good: Template literals
const message = `Hello, ${user.name}! Your email is ${user.email}`;

// ❌ Bad: String concatenation
const message = 'Hello, ' + user.name + '! Your email is ' + user.email;
```

### 6. Immutability

```typescript
// ✅ Good: Spread operator
const updatedUser = { ...user, name: 'New Name' };
const newUsers = [...users, newUser];

// ❌ Bad: Mutation
user.name = 'New Name';
users.push(newUser);
```

---

## 체크리스트

프로젝트에 적용할 때 확인사항:

- [ ] 모든 함수를 Arrow Function으로 작성했는가?
- [ ] Export는 파일 하단에 일괄 처리했는가?
- [ ] 타입 정의가 명시적으로 되어 있는가?
- [ ] 명명 규칙을 일관되게 적용했는가?
- [ ] 파일 구조가 정해진 순서를 따르는가?
- [ ] 복잡한 로직에 적절한 주석이 있는가?
- [ ] async/await를 사용하고 있는가?
- [ ] 에러 처리가 적절히 되어 있는가?

---

## 도구 설정

### ESLint 설정 (.eslintrc.json)

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "prefer-arrow-callback": "error",
    "func-style": ["error", "expression"],
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

### Prettier 설정 (.prettierrc)

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "arrowParens": "always"
}
```

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/coding-conventions/`

**버전**: 1.0.0

**작성일**: 2024-10-19
