# Next.js 코딩 컨벤션

> Next.js 15.5+ (App Router) 및 React 19 기반 프로젝트의 코딩 규칙

## 📋 목차

1. [기본 원칙](#기본-원칙)
2. [프로젝트 구조](#프로젝트-구조)
3. [컴포넌트 계층 구조](#컴포넌트-계층-구조)
4. [컴포넌트 작성](#컴포넌트-작성)
5. [Server Components vs Client Components](#server-components-vs-client-components)
6. [라우팅 및 페이지](#라우팅-및-페이지)
7. [데이터 Fetching](#데이터-fetching)
8. [GraphQL 사용](#graphql-사용)
9. [상태 관리](#상태-관리)
10. [스타일링](#스타일링)
11. [명명 규칙](#명명-규칙)
12. [Best Practices](#best-practices)

---

## 기본 원칙

### 1. App Router 사용
- Next.js 15.5+에서는 **App Router**를 기본으로 사용합니다
- Pages Router는 레거시로 간주합니다
- Server Components를 우선적으로 사용합니다

### 2. TypeScript 필수
- 모든 파일을 TypeScript로 작성합니다
- `any` 타입 사용을 최소화합니다
- Props 타입을 명시적으로 정의합니다

### 3. 함수형 컴포넌트
- 모든 컴포넌트를 **Arrow Function**으로 작성합니다
- 클래스 컴포넌트는 사용하지 않습니다

### 4. UI 라이브러리
- **shadcn/ui**를 기본 컴포넌트 라이브러리로 사용합니다
- **Tailwind CSS**를 스타일링 프레임워크로 사용합니다
- shadcn 컴포넌트는 복사하여 `components/ui/`에 배치합니다 (npm 패키지 아님)

---

## 프로젝트 구조

### 표준 디렉토리 구조

```
src/
├── app/                          # App Router (Next.js 15.5+)
│   ├── (auth)/                   # Route Group (레이아웃 공유)
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── register/
│   │       └── page.tsx
│   ├── (dashboard)/              # Route Group
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── users/
│   │       ├── page.tsx
│   │       └── [id]/
│   │           └── page.tsx
│   ├── api/                      # API Routes
│   │   └── users/
│   │       └── route.ts
│   ├── layout.tsx                # Root Layout
│   ├── page.tsx                  # Home Page
│   ├── loading.tsx               # Loading UI
│   ├── error.tsx                 # Error UI
│   └── not-found.tsx             # 404 Page
│
├── components/                   # 재사용 가능한 컴포넌트
│   ├── ui/                       # shadcn 기본 컴포넌트 (atoms)
│   │   ├── button.tsx            # shadcn button
│   │   ├── card.tsx              # shadcn card
│   │   ├── input.tsx             # shadcn input
│   │   ├── select.tsx            # shadcn select
│   │   ├── dialog.tsx            # shadcn dialog
│   │   └── ...                   # 기타 shadcn 컴포넌트
│   │
│   ├── templates/                # 조합 컴포넌트 (molecules)
│   │   ├── action-bar.tsx        # 검색 + 버튼 조합
│   │   ├── help-slider.tsx       # help 버튼 + 슬라이드 패널
│   │   ├── data-table.tsx        # 테이블 + 페이지네이션
│   │   ├── search-filter.tsx     # 검색 + 필터 조합
│   │   └── form-section.tsx      # 폼 필드 그룹
│   │
│   ├── layout/                   # 페이지 레이아웃 섹션 (organisms)
│   │   ├── header.tsx            # 페이지 상단 헤더
│   │   ├── footer.tsx            # 페이지 하단 푸터
│   │   ├── sidebar.tsx           # 사이드바 네비게이션
│   │   └── nav-bar.tsx           # 네비게이션 바
│   │
│   └── features/                 # 기능별 페이지 컴포넌트 (templates/pages)
│       ├── user-profile.tsx      # 사용자 프로필 페이지 컴포넌트
│       ├── user-list.tsx         # 사용자 목록 페이지 컴포넌트
│       └── dashboard-stats.tsx   # 대시보드 통계 컴포넌트
│
├── lib/                          # 유틸리티 및 라이브러리
│   ├── api/                      # API 클라이언트
│   │   ├── client.ts
│   │   └── users.ts
│   ├── utils/                    # 헬퍼 함수
│   │   ├── format.ts
│   │   └── validation.ts
│   └── hooks/                    # Custom Hooks
│       ├── use-user.ts
│       └── use-auth.ts
│
├── types/                        # TypeScript 타입 정의
│   ├── user.ts
│   ├── api.ts
│   └── common.ts
│
├── styles/                       # 전역 스타일
│   ├── globals.css
│   └── variables.css
│
└── config/                       # 설정 파일
    ├── site.ts
    └── env.ts
```

### 컴포넌트 계층 구조

컴포넌트는 **Atomic Design 패턴**을 기반으로 계층적으로 구성합니다:

#### 1. `components/ui/` - 기본 컴포넌트 (Atoms)

**shadcn/ui 컴포넌트를 배치하는 디렉토리**

- shadcn에서 제공하는 기본 UI 컴포넌트
- 더 이상 쪼갤 수 없는 최소 단위
- variant 및 props를 통한 스타일 변경 지원
- **재사용성**: 전체 프로젝트에서 사용

**예시**:
```typescript
// components/ui/button.tsx (shadcn)
<Button variant="default">클릭</Button>
<Button variant="outline">취소</Button>
<Button variant="destructive">삭제</Button>
```

**대표 컴포넌트**: Button, Input, Select, Card, Dialog, Badge, Avatar 등

---

#### 2. `components/templates/` - 조합 컴포넌트 (Molecules)

**여러 기본 컴포넌트(atoms)가 조합되어 만들어진 재사용 가능한 템플릿**

- 2개 이상의 `ui/` 컴포넌트가 결합된 구조
- 특정 기능을 수행하지만 비즈니스 로직은 최소화
- 여러 페이지/기능에서 재사용 가능
- **재사용성**: 여러 features에서 공통으로 사용

**예시**:

```typescript
// components/templates/action-bar.tsx
// (검색 Input + 필터 Select + 액션 Button 조합)
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';

interface ActionBarProps {
  onSearch: (query: string) => void;
  onFilter: (filter: string) => void;
  onAdd?: () => void;
}

const ActionBar = ({ onSearch, onFilter, onAdd }: ActionBarProps) => {
  return (
    <div className="flex gap-4 items-center p-4 bg-gray-50 rounded-lg">
      <Input
        placeholder="검색..."
        onChange={(e) => onSearch(e.target.value)}
      />
      <Select onValueChange={onFilter}>
        <option value="all">전체</option>
        <option value="active">활성</option>
      </Select>
      {onAdd && (
        <Button onClick={onAdd}>추가</Button>
      )}
    </div>
  );
};

export default ActionBar;
```

```typescript
// components/templates/help-slider.tsx
// (Help Button + Sheet/Drawer 조합)
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';

interface HelpSliderProps {
  content: React.ReactNode;
}

const HelpSlider = ({ content }: HelpSliderProps) => {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <Button variant="outline" size="icon">?</Button>
      </SheetTrigger>
      <SheetContent>
        <div className="mt-8">{content}</div>
      </SheetContent>
    </Sheet>
  );
};

export default HelpSlider;
```

**대표 컴포넌트**: ActionBar, HelpSlider, DataTable, SearchFilter, FormSection, Pagination 등

---

#### 3. `components/layout/` - 레이아웃 섹션 (Organisms)

**페이지의 주요 구조를 구성하는 레이아웃 컴포넌트**

- 페이지 전체 또는 섹션의 레이아웃을 담당
- Header, Footer, Sidebar 등 페이지 골격 요소
- `templates/` 컴포넌트를 포함할 수 있음
- **재사용성**: 전체 앱의 레이아웃 구조

**예시**:

```typescript
// components/layout/header.tsx
import { Button } from '@/components/ui/button';
import { Avatar } from '@/components/ui/avatar';

const Header = () => {
  return (
    <header className="h-16 border-b flex items-center justify-between px-6">
      <div className="flex items-center gap-4">
        <Logo />
        <NavBar />
      </div>
      <div className="flex items-center gap-4">
        <NotificationButton />
        <Avatar />
      </div>
    </header>
  );
};

export default Header;
```

**대표 컴포넌트**: Header, Footer, Sidebar, NavBar, MainLayout 등

---

#### 4. `components/features/` - 기능별 페이지 컴포넌트 (Templates/Pages)

**특정 페이지나 기능에 특화된 컴포넌트**

- 비즈니스 로직이 포함된 복잡한 컴포넌트
- `ui/`, `templates/`, `layout/` 컴포넌트를 조합하여 구성
- 페이지 단위의 기능 구현
- **재사용성**: 특정 페이지/기능에서만 사용

**예시**:

```typescript
// components/features/user-list.tsx
import { ActionBar } from '@/components/templates/action-bar';
import { DataTable } from '@/components/templates/data-table';
import { Card } from '@/components/ui/card';

interface UserListProps {
  users: User[];
}

const UserList = ({ users }: UserListProps) => {
  const handleSearch = (query: string) => {
    // 비즈니스 로직: 사용자 검색
  };

  const handleAdd = () => {
    // 비즈니스 로직: 사용자 추가
  };

  return (
    <Card>
      <ActionBar
        onSearch={handleSearch}
        onFilter={handleFilter}
        onAdd={handleAdd}
      />
      <DataTable
        data={users}
        columns={userColumns}
      />
    </Card>
  );
};

export default UserList;
```

**대표 컴포넌트**: UserList, UserProfile, DashboardStats, OrderForm 등

---

### 컴포넌트 배치 가이드라인

| 컴포넌트 유형 | 디렉토리 | 설명 | 예시 |
|--------------|---------|------|------|
| **shadcn 기본 컴포넌트** | `ui/` | shadcn에서 가져온 컴포넌트 | Button, Input, Select |
| **재사용 조합 템플릿** | `templates/` | 여러 ui 컴포넌트의 조합 | ActionBar, HelpSlider, DataTable |
| **레이아웃 구조** | `layout/` | 페이지 골격 요소 | Header, Footer, Sidebar |
| **페이지 기능 컴포넌트** | `features/` | 특정 기능에 특화된 컴포넌트 | UserList, DashboardStats |

**판단 기준**:
- shadcn 컴포넌트인가? → `ui/`
- 여러 ui 컴포넌트를 조합한 재사용 가능한 템플릿인가? → `templates/`
- 페이지 레이아웃/구조 요소인가? → `layout/`
- 비즈니스 로직이 포함된 페이지 컴포넌트인가? → `features/`

---

## 컴포넌트 작성

### ✅ Arrow Function 컴포넌트 (필수)

**모든 컴포넌트는 Arrow Function으로 작성합니다.**

#### Server Component (기본)

```typescript
// ✅ Good: Arrow Function + TypeScript

// src/components/features/user-profile.tsx

import { User } from '@/types/user';

interface UserProfileProps {
  user: User;
  showEmail?: boolean;
}

const UserProfile = ({ user, showEmail = true }: UserProfileProps) => {
  return (
    <div className="user-profile">
      <h1>{user.name}</h1>
      {showEmail && <p>{user.email}</p>}
    </div>
  );
};

export default UserProfile;
```

#### Client Component

```typescript
// ✅ Good: Client Component with 'use client' directive

// src/components/features/user-form.tsx
'use client';

import { useState } from 'react';
import { User } from '@/types/user';

interface UserFormProps {
  initialData?: Partial<User>;
  onSubmit: (data: User) => Promise<void>;
}

const UserForm = ({ initialData, onSubmit }: UserFormProps) => {
  const [formData, setFormData] = useState(initialData || {});
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await onSubmit(formData as User);
    } catch (error) {
      console.error('Failed to submit:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      <button type="submit" disabled={isLoading}>
        {isLoading ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
};

export default UserForm;
```

#### 작은 컴포넌트 (인라인)

```typescript
// ✅ Good: 간단한 컴포넌트도 Arrow Function

// src/components/ui/badge.tsx

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'success' | 'error';
}

const Badge = ({ children, variant = 'default' }: BadgeProps) => (
  <span className={`badge badge-${variant}`}>
    {children}
  </span>
);

export default Badge;
```

### ❌ 피해야 할 패턴

```typescript
// ❌ Bad: function 키워드 사용
function UserProfile({ user }: UserProfileProps) {
  return <div>{user.name}</div>;
}

// ❌ Bad: 클래스 컴포넌트
class UserProfile extends React.Component<UserProfileProps> {
  render() {
    return <div>{this.props.user.name}</div>;
  }
}

// ❌ Bad: export와 정의를 분리
const UserProfile = ({ user }: UserProfileProps) => {
  return <div>{user.name}</div>;
};

export { UserProfile }; // ❌ 컴포넌트는 default export 사용
```

---

## Server Components vs Client Components

### Server Components (기본)

**기본적으로 모든 컴포넌트는 Server Component입니다.**

```typescript
// ✅ Good: Server Component (async 지원)

// src/app/users/page.tsx

import { Suspense } from 'react';
import { getUsers } from '@/lib/api/users';
import UserList from '@/components/features/user-list';

const UsersPage = async () => {
  // Server Component에서 직접 데이터 fetch
  const users = await getUsers();

  return (
    <div>
      <h1>Users</h1>
      <Suspense fallback={<div>Loading...</div>}>
        <UserList users={users} />
      </Suspense>
    </div>
  );
};

export default UsersPage;
```

**Server Component 사용 시기:**
- ✅ 데이터 fetching이 필요한 경우
- ✅ 백엔드 리소스 직접 접근
- ✅ 민감한 정보 처리 (API keys, tokens)
- ✅ 큰 의존성 라이브러리 사용 (서버에만 유지)

### Client Components

**`'use client'` 지시어를 파일 상단에 추가합니다.**

```typescript
// ✅ Good: Client Component

// src/components/features/search-box.tsx
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface SearchBoxProps {
  placeholder?: string;
}

const SearchBox = ({ placeholder = 'Search...' }: SearchBoxProps) => {
  const [query, setQuery] = useState('');
  const router = useRouter();

  useEffect(() => {
    // Client-side effect
    const timer = setTimeout(() => {
      if (query) {
        router.push(`/search?q=${query}`);
      }
    }, 500);

    return () => clearTimeout(timer);
  }, [query, router]);

  return (
    <input
      type="text"
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      placeholder={placeholder}
    />
  );
};

export default SearchBox;
```

**Client Component 사용 시기:**
- ✅ 이벤트 리스너 필요 (onClick, onChange 등)
- ✅ State, Effects 사용 (useState, useEffect)
- ✅ Browser API 사용 (window, localStorage 등)
- ✅ React Hooks 사용
- ✅ 실시간 상호작용 필요

### Composition Pattern (조합)

```typescript
// ✅ Good: Server Component + Client Component 조합

// src/app/dashboard/page.tsx (Server Component)

import { getUser } from '@/lib/api/users';
import ProfileEditor from '@/components/features/profile-editor'; // Client Component

const DashboardPage = async () => {
  const user = await getUser();

  return (
    <div>
      <h1>Dashboard</h1>
      {/* Server에서 가져온 데이터를 Client Component에 전달 */}
      <ProfileEditor user={user} />
    </div>
  );
};

export default DashboardPage;
```

---

## 라우팅 및 페이지

### Page 컴포넌트

```typescript
// ✅ Good: Page component

// src/app/users/[id]/page.tsx

import { notFound } from 'next/navigation';
import { getUser } from '@/lib/api/users';
import UserProfile from '@/components/features/user-profile';

interface PageProps {
  params: {
    id: string;
  };
  searchParams: {
    tab?: string;
  };
}

const UserPage = async ({ params, searchParams }: PageProps) => {
  const user = await getUser(params.id);

  if (!user) {
    notFound();
  }

  return (
    <div>
      <UserProfile user={user} activeTab={searchParams.tab} />
    </div>
  );
};

// Metadata 생성 (SEO)
export const generateMetadata = async ({ params }: PageProps) => {
  const user = await getUser(params.id);

  return {
    title: user?.name || 'User Not Found',
    description: `Profile of ${user?.name}`,
  };
};

export default UserPage;
```

### Layout 컴포넌트

```typescript
// ✅ Good: Layout component

// src/app/(dashboard)/layout.tsx

import { ReactNode } from 'react';
import Sidebar from '@/components/layout/sidebar';
import Header from '@/components/layout/header';

interface LayoutProps {
  children: ReactNode;
}

const DashboardLayout = ({ children }: LayoutProps) => {
  return (
    <div className="dashboard-layout">
      <Header />
      <div className="dashboard-content">
        <Sidebar />
        <main>{children}</main>
      </div>
    </div>
  );
};

export default DashboardLayout;
```

### Loading UI

```typescript
// ✅ Good: Loading component

// src/app/users/loading.tsx

const Loading = () => {
  return (
    <div className="loading-container">
      <div className="spinner" />
      <p>Loading users...</p>
    </div>
  );
};

export default Loading;
```

### Error Boundary

```typescript
// ✅ Good: Error boundary

// src/app/error.tsx
'use client';

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

const Error = ({ error, reset }: ErrorProps) => {
  return (
    <div className="error-container">
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
};

export default Error;
```

### Route Groups

```typescript
// ✅ Good: Route groups로 레이아웃 구분

// 폴더 구조:
// app/
//   (auth)/           # 인증 관련 페이지 (레이아웃 공유)
//     layout.tsx
//     login/page.tsx
//     register/page.tsx
//   (dashboard)/      # 대시보드 페이지 (다른 레이아웃)
//     layout.tsx
//     page.tsx

// src/app/(auth)/layout.tsx
const AuthLayout = ({ children }: { children: ReactNode }) => {
  return (
    <div className="auth-layout">
      <div className="auth-container">{children}</div>
    </div>
  );
};

export default AuthLayout;
```

---

## 데이터 Fetching

### Server Component에서 Fetch

```typescript
// ✅ Good: Server Component에서 직접 fetch

// src/app/posts/page.tsx

import { Post } from '@/types/post';

const getPosts = async (): Promise<Post[]> => {
  const res = await fetch('https://api.example.com/posts', {
    // Next.js 15+ 캐싱 옵션
    next: { revalidate: 3600 }, // 1시간마다 재검증
  });

  if (!res.ok) {
    throw new Error('Failed to fetch posts');
  }

  return res.json();
};

const PostsPage = async () => {
  const posts = await getPosts();

  return (
    <div>
      <h1>Posts</h1>
      {posts.map((post) => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.content}</p>
        </article>
      ))}
    </div>
  );
};

export default PostsPage;
```

### Parallel Data Fetching

```typescript
// ✅ Good: 병렬 데이터 fetching

const DashboardPage = async () => {
  // 병렬로 실행
  const [users, posts, stats] = await Promise.all([
    getUsers(),
    getPosts(),
    getStats(),
  ]);

  return (
    <div>
      <Stats data={stats} />
      <UserList users={users} />
      <PostList posts={posts} />
    </div>
  );
};

export default DashboardPage;
```

### Sequential Data Fetching

```typescript
// ✅ Good: 순차적 데이터 fetching (의존성이 있는 경우)

const UserPostsPage = async ({ params }: { params: { id: string } }) => {
  // 1. 먼저 사용자 정보 가져오기
  const user = await getUser(params.id);

  // 2. 사용자 정보를 기반으로 게시글 가져오기
  const posts = await getUserPosts(user.id);

  return (
    <div>
      <UserProfile user={user} />
      <PostList posts={posts} />
    </div>
  );
};

export default UserPostsPage;
```

### Client에서 Fetch (SWR 또는 React Query)

```typescript
// ✅ Good: Client Component에서 SWR 사용

// src/components/features/live-users.tsx
'use client';

import useSWR from 'swr';
import { User } from '@/types/user';

const fetcher = (url: string) => fetch(url).then((res) => res.json());

const LiveUsers = () => {
  const { data, error, isLoading } = useSWR<User[]>('/api/users', fetcher, {
    refreshInterval: 5000, // 5초마다 갱신
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading users</div>;

  return (
    <div>
      {data?.map((user) => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  );
};

export default LiveUsers;
```

---

## GraphQL 사용

Next.js에서 GraphQL을 사용할 때는 **Apollo Client** 또는 **urql**을 권장하며, query와 mutation을 별도 폴더에서 체계적으로 관리합니다.

### 프로젝트 구조 (GraphQL 포함)

```
src/
├── app/                          # Next.js App Router
│   └── ...
│
├── graphql/                      # GraphQL 관련 파일
│   ├── queries/                  # Query 정의
│   │   ├── users.ts
│   │   ├── posts.ts
│   │   └── index.ts              # queries export
│   │
│   ├── mutations/                # Mutation 정의
│   │   ├── createUser.ts
│   │   ├── updateUser.ts
│   │   └── index.ts              # mutations export
│   │
│   ├── fragments/                # GraphQL Fragment
│   │   ├── userFragment.ts
│   │   └── index.ts
│   │
│   ├── types/                    # 타입 정의
│   │   └── generated.ts          # graphql-codegen 자동 생성
│   │
│   ├── client.ts                 # Apollo Client 설정
│   └── provider.tsx              # Apollo Provider (Client Component)
│
├── components/
│   └── ...
│
└── lib/
    └── ...
```

---

### 1. Apollo Client 설치 및 설정

#### 설치

```bash
npm install @apollo/client graphql
npm install -D @graphql-codegen/cli @graphql-codegen/typescript @graphql-codegen/typescript-operations
```

#### Apollo Client 설정

```typescript
// src/graphql/client.ts

import { ApolloClient, InMemoryCache, HttpLink } from '@apollo/client';
import { registerApolloClient } from '@apollo/experimental-nextjs-app-support/rsc';

// Server Components용 클라이언트
const makeClient = () => {
  const httpLink = new HttpLink({
    uri: process.env.NEXT_PUBLIC_GRAPHQL_ENDPOINT || 'http://localhost:4000/graphql',
    fetchOptions: { cache: 'no-store' }, // SSR에서 캐시 비활성화
  });

  return new ApolloClient({
    cache: new InMemoryCache(),
    link: httpLink,
  });
};

// Server Components에서 사용
const { getClient } = registerApolloClient(makeClient);

export { getClient };
```

#### Apollo Provider (Client Components용)

```typescript
// src/graphql/provider.tsx
'use client';

import { ApolloClient, InMemoryCache, ApolloProvider, HttpLink } from '@apollo/client';
import { ReactNode } from 'react';

const createClient = () => {
  return new ApolloClient({
    link: new HttpLink({
      uri: process.env.NEXT_PUBLIC_GRAPHQL_ENDPOINT || 'http://localhost:4000/graphql',
    }),
    cache: new InMemoryCache(),
  });
};

interface GraphQLProviderProps {
  children: ReactNode;
}

const GraphQLProvider = ({ children }: GraphQLProviderProps) => {
  const client = createClient();

  return <ApolloProvider client={client}>{children}</ApolloProvider>;
};

export default GraphQLProvider;
```

```typescript
// src/app/layout.tsx
import GraphQLProvider from '@/graphql/provider';

const RootLayout = ({ children }: { children: ReactNode }) => {
  return (
    <html lang="ko">
      <body>
        <GraphQLProvider>
          {children}
        </GraphQLProvider>
      </body>
    </html>
  );
};

export default RootLayout;
```

---

### 2. Query 정의 (TypeScript 파일)

**권장 방식**: `.ts` 파일에 `gql` 태그로 정의하고 타입 안정성 확보

```typescript
// src/graphql/queries/users.ts

import { gql } from '@apollo/client';

// Query 정의 (Arrow Function + Export 일괄 처리)
const GET_USERS = gql`
  query GetUsers {
    users {
      id
      name
      email
      createdAt
    }
  }
`;

const GET_USER_BY_ID = gql`
  query GetUserById($id: ID!) {
    user(id: $id) {
      id
      name
      email
      posts {
        id
        title
      }
    }
  }
`;

// Export 일괄 처리
export {
  GET_USERS,
  GET_USER_BY_ID,
};
```

```typescript
// src/graphql/queries/index.ts

// Query 재export (편의성)
export * from './users';
export * from './posts';
```

---

### 3. Mutation 정의

```typescript
// src/graphql/mutations/createUser.ts

import { gql } from '@apollo/client';

const CREATE_USER = gql`
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) {
      id
      name
      email
    }
  }
`;

const UPDATE_USER = gql`
  mutation UpdateUser($id: ID!, $input: UpdateUserInput!) {
    updateUser(id: $id, input: $input) {
      id
      name
      email
    }
  }
`;

const DELETE_USER = gql`
  mutation DeleteUser($id: ID!) {
    deleteUser(id: $id) {
      id
    }
  }
`;

export {
  CREATE_USER,
  UPDATE_USER,
  DELETE_USER,
};
```

---

### 4. Fragment 사용 (재사용성)

```typescript
// src/graphql/fragments/userFragment.ts

import { gql } from '@apollo/client';

const USER_FIELDS = gql`
  fragment UserFields on User {
    id
    name
    email
    createdAt
  }
`;

export { USER_FIELDS };
```

```typescript
// src/graphql/queries/users.ts (Fragment 사용)

import { gql } from '@apollo/client';
import { USER_FIELDS } from '../fragments/userFragment';

const GET_USERS = gql`
  ${USER_FIELDS}
  query GetUsers {
    users {
      ...UserFields
    }
  }
`;

export { GET_USERS };
```

---

### 5. Server Components에서 GraphQL 사용

**Server Components는 async 함수로 작성하고 `getClient()`를 사용합니다.**

```typescript
// src/app/users/page.tsx (Server Component)

import { getClient } from '@/graphql/client';
import { GET_USERS } from '@/graphql/queries';
import UserList from '@/components/features/user-list';

interface User {
  id: string;
  name: string;
  email: string;
}

const UsersPage = async () => {
  const client = getClient();

  const { data } = await client.query<{ users: User[] }>({
    query: GET_USERS,
  });

  return (
    <div>
      <h1>사용자 목록</h1>
      <UserList users={data.users} />
    </div>
  );
};

export default UsersPage;
```

**Query with Variables:**

```typescript
// src/app/users/[id]/page.tsx

import { getClient } from '@/graphql/client';
import { GET_USER_BY_ID } from '@/graphql/queries';

interface PageProps {
  params: {
    id: string;
  };
}

const UserDetailPage = async ({ params }: PageProps) => {
  const client = getClient();

  const { data } = await client.query({
    query: GET_USER_BY_ID,
    variables: { id: params.id },
  });

  return (
    <div>
      <h1>{data.user.name}</h1>
      <p>{data.user.email}</p>
    </div>
  );
};

export default UserDetailPage;
```

---

### 6. Client Components에서 GraphQL 사용 (Hooks)

**Client Components는 `useQuery`, `useMutation` hooks를 사용합니다.**

```typescript
// src/components/features/user-list-interactive.tsx
'use client';

import { useQuery, useMutation } from '@apollo/client';
import { GET_USERS } from '@/graphql/queries';
import { DELETE_USER } from '@/graphql/mutations';
import { Button } from '@/components/ui/button';

const UserListInteractive = () => {
  const { data, loading, error, refetch } = useQuery(GET_USERS);
  const [deleteUser] = useMutation(DELETE_USER);

  const handleDelete = async (id: string) => {
    await deleteUser({
      variables: { id },
      // 삭제 후 목록 다시 가져오기
      onCompleted: () => refetch(),
    });
  };

  if (loading) return <div>로딩 중...</div>;
  if (error) return <div>에러: {error.message}</div>;

  return (
    <div>
      {data?.users.map((user) => (
        <div key={user.id} className="flex items-center gap-4">
          <span>{user.name}</span>
          <Button
            variant="destructive"
            onClick={() => handleDelete(user.id)}
          >
            삭제
          </Button>
        </div>
      ))}
    </div>
  );
};

export default UserListInteractive;
```

**Mutation 예시:**

```typescript
// src/components/features/user-form.tsx
'use client';

import { useState } from 'react';
import { useMutation } from '@apollo/client';
import { CREATE_USER } from '@/graphql/mutations';
import { GET_USERS } from '@/graphql/queries';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

const UserForm = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const [createUser, { loading }] = useMutation(CREATE_USER, {
    // 생성 후 사용자 목록 다시 가져오기
    refetchQueries: [{ query: GET_USERS }],
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    await createUser({
      variables: {
        input: { name, email },
      },
    });

    setName('');
    setEmail('');
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        placeholder="이름"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      <Input
        type="email"
        placeholder="이메일"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <Button type="submit" disabled={loading}>
        {loading ? '생성 중...' : '사용자 추가'}
      </Button>
    </form>
  );
};

export default UserForm;
```

---

### 7. TypeScript 타입 자동 생성 (graphql-codegen)

#### codegen.yml 설정

```yaml
# codegen.yml
schema: 'http://localhost:4000/graphql'  # GraphQL 서버 URL
documents: 'src/graphql/**/*.ts'         # Query/Mutation 파일 경로
generates:
  src/graphql/types/generated.ts:
    plugins:
      - typescript
      - typescript-operations
    config:
      skipTypename: false
      withHooks: true
      withHOC: false
      withComponent: false
```

#### package.json 스크립트

```json
{
  "scripts": {
    "codegen": "graphql-codegen --config codegen.yml",
    "codegen:watch": "graphql-codegen --config codegen.yml --watch"
  }
}
```

#### 타입 자동 생성 실행

```bash
# 한 번 생성
npm run codegen

# 파일 변경 감지하여 자동 재생성
npm run codegen:watch
```

#### 생성된 타입 사용

```typescript
// src/components/features/typed-user-list.tsx
'use client';

import { useQuery } from '@apollo/client';
import { GET_USERS } from '@/graphql/queries';
import { GetUsersQuery } from '@/graphql/types/generated';

const TypedUserList = () => {
  // 자동 생성된 타입 사용
  const { data, loading, error } = useQuery<GetUsersQuery>(GET_USERS);

  if (loading) return <div>로딩 중...</div>;
  if (error) return <div>에러: {error.message}</div>;

  return (
    <div>
      {data?.users.map((user) => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  );
};

export default TypedUserList;
```

---

### 8. GraphQL 사용 가이드라인

#### ✅ DO (권장)

```typescript
// ✅ Query/Mutation을 graphql/ 폴더에서 관리
import { GET_USERS } from '@/graphql/queries';

// ✅ Fragment로 재사용 가능한 필드 정의
import { USER_FIELDS } from '@/graphql/fragments';

// ✅ Server Components에서 getClient() 사용
const client = getClient();
const { data } = await client.query({ query: GET_USERS });

// ✅ Client Components에서 hooks 사용
const { data } = useQuery(GET_USERS);

// ✅ graphql-codegen으로 타입 자동 생성
const { data } = useQuery<GetUsersQuery>(GET_USERS);

// ✅ refetchQueries로 캐시 업데이트
useMutation(CREATE_USER, {
  refetchQueries: [{ query: GET_USERS }],
});
```

#### ❌ DON'T (비권장)

```typescript
// ❌ 컴포넌트 파일 안에 Query 정의 (재사용 불가)
const GET_USERS = gql`...`;

// ❌ Server Component에서 hooks 사용 (에러 발생)
const { data } = useQuery(GET_USERS); // ❌ 'use client' 필요

// ❌ Client Component에서 getClient() 사용 (Provider 사용 필요)
const client = getClient(); // ❌ Server Components 전용

// ❌ any 타입 사용
const { data } = useQuery<any>(GET_USERS); // ❌ 타입 안정성 상실

// ❌ 하드코딩된 GraphQL endpoint
uri: 'http://localhost:4000/graphql' // ❌ 환경변수 사용
```

---

### 9. 환경변수 설정

```env
# .env.local
NEXT_PUBLIC_GRAPHQL_ENDPOINT=http://localhost:4000/graphql

# .env.production
NEXT_PUBLIC_GRAPHQL_ENDPOINT=https://api.production.com/graphql
```

---

### 10. 정리: GraphQL 사용 체크리스트

- [ ] Apollo Client 설치 및 설정 완료
- [ ] `graphql/` 폴더 구조 생성 (queries, mutations, fragments)
- [ ] GraphQL Provider를 root layout에 추가
- [ ] Query/Mutation을 별도 파일로 분리
- [ ] Fragment로 재사용 가능한 필드 정의
- [ ] Server Components에서 `getClient()` 사용
- [ ] Client Components에서 hooks 사용
- [ ] graphql-codegen으로 타입 자동 생성 설정
- [ ] 환경변수로 GraphQL endpoint 관리
- [ ] Export 일괄 처리 규칙 준수

---

## 상태 관리

### Local State (useState)

```typescript
// ✅ Good: Component local state

'use client';

import { useState } from 'react';

const Counter = () => {
  const [count, setCount] = useState(0);

  const increment = () => setCount((prev) => prev + 1);
  const decrement = () => setCount((prev) => prev - 1);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  );
};

export default Counter;
```

### URL State (useSearchParams)

```typescript
// ✅ Good: URL을 상태로 활용

'use client';

import { useSearchParams, useRouter, usePathname } from 'next/navigation';

const FilterPanel = () => {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const updateFilter = (key: string, value: string) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set(key, value);
    router.push(`${pathname}?${params.toString()}`);
  };

  return (
    <div>
      <button onClick={() => updateFilter('category', 'tech')}>
        Tech
      </button>
      <button onClick={() => updateFilter('category', 'life')}>
        Life
      </button>
    </div>
  );
};

export default FilterPanel;
```

### Global State (Context API)

```typescript
// ✅ Good: Context for global state

// src/lib/contexts/theme-context.tsx
'use client';

import { createContext, useContext, useState, ReactNode } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

interface ThemeProviderProps {
  children: ReactNode;
}

const ThemeProvider = ({ children }: ThemeProviderProps) => {
  const [theme, setTheme] = useState<Theme>('light');

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
};

export { ThemeProvider, useTheme };
```

사용:

```typescript
// src/app/layout.tsx

import { ThemeProvider } from '@/lib/contexts/theme-context';

const RootLayout = ({ children }: { children: ReactNode }) => {
  return (
    <html>
      <body>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
};

export default RootLayout;
```

---

## 스타일링

### shadcn/ui + Tailwind CSS (필수)

**프로젝트의 모든 UI는 shadcn/ui와 Tailwind CSS를 사용합니다.**

#### shadcn/ui 설치 및 설정

```bash
# 1. Tailwind CSS 설치 (Next.js 프로젝트 생성 시 자동 설치됨)
npx create-next-app@latest my-app --typescript --tailwind --app

# 2. shadcn/ui 초기화
npx shadcn@latest init

# 선택 옵션:
# ✔ Would you like to use TypeScript? … yes
# ✔ Which style would you like to use? › New York
# ✔ Which color would you like to use as base color? › Slate
# ✔ Where is your global CSS file? … src/styles/globals.css
# ✔ Would you like to use CSS variables for colors? … yes
# ✔ Where is your tailwind.config.js located? … tailwind.config.ts
# ✔ Configure the import alias for components: … @/components
# ✔ Configure the import alias for utils: … @/lib/utils
```

#### shadcn 컴포넌트 추가

```bash
# 필요한 컴포넌트를 개별적으로 추가 (components/ui/에 복사됨)
npx shadcn@latest add button
npx shadcn@latest add input
npx shadcn@latest add card
npx shadcn@latest add dialog
npx shadcn@latest add select
npx shadcn@latest add sheet
npx shadcn@latest add table

# 또는 여러 개 한번에 추가
npx shadcn@latest add button input card dialog select
```

#### shadcn 컴포넌트 사용

```typescript
// ✅ Good: shadcn 컴포넌트 사용

// components/ui/에 추가된 shadcn 컴포넌트 import
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';

const LoginForm = () => {
  return (
    <Card className="w-96">
      <CardHeader>
        <CardTitle>로그인</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-4">
          <Input type="email" placeholder="이메일" />
          <Input type="password" placeholder="비밀번호" />
          <Button type="submit" className="w-full">
            로그인
          </Button>
        </form>
      </CardContent>
    </Card>
  );
};

export default LoginForm;
```

#### shadcn 컴포넌트 커스터마이징

shadcn 컴포넌트는 `components/ui/`에 복사되므로 자유롭게 수정 가능합니다:

```typescript
// ✅ Good: shadcn 컴포넌트 variant 추가

// components/ui/button.tsx (shadcn에서 복사된 파일)
import { cva, type VariantProps } from 'class-variance-authority';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'underline-offset-4 hover:underline text-primary',
        // ✨ 커스텀 variant 추가
        success: 'bg-green-600 text-white hover:bg-green-700',
      },
      size: {
        default: 'h-10 py-2 px-4',
        sm: 'h-9 px-3 rounded-md',
        lg: 'h-11 px-8 rounded-md',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

// 사용
<Button variant="success">성공</Button>
```

---

### Tailwind CSS (권장)

```typescript
// ✅ Good: Tailwind CSS 사용

const Button = ({ children, variant = 'primary' }: ButtonProps) => {
  const baseStyles = 'px-4 py-2 rounded-lg font-medium transition-colors';

  const variantStyles = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300',
    danger: 'bg-red-600 text-white hover:bg-red-700',
  };

  return (
    <button className={`${baseStyles} ${variantStyles[variant]}`}>
      {children}
    </button>
  );
};

export default Button;
```

### CSS Modules

```typescript
// ✅ Good: CSS Modules

// src/components/ui/card.module.css
.card {
  padding: 1rem;
  border-radius: 0.5rem;
  background: white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.cardTitle {
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

// src/components/ui/card.tsx
import styles from './card.module.css';

interface CardProps {
  title: string;
  children: ReactNode;
}

const Card = ({ title, children }: CardProps) => {
  return (
    <div className={styles.card}>
      <h3 className={styles.cardTitle}>{title}</h3>
      {children}
    </div>
  );
};

export default Card;
```

### clsx/cn 유틸리티

```typescript
// ✅ Good: 조건부 클래스 처리

// src/lib/utils/cn.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

const cn = (...inputs: ClassValue[]) => {
  return twMerge(clsx(inputs));
};

export { cn };

// 사용
import { cn } from '@/lib/utils/cn';

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  isLoading?: boolean;
  children: ReactNode;
}

const Button = ({ variant = 'primary', isLoading, children }: ButtonProps) => {
  return (
    <button
      className={cn(
        'px-4 py-2 rounded-lg font-medium',
        variant === 'primary' && 'bg-blue-600 text-white',
        variant === 'secondary' && 'bg-gray-200 text-gray-900',
        isLoading && 'opacity-50 cursor-not-allowed'
      )}
      disabled={isLoading}
    >
      {children}
    </button>
  );
};

export default Button;
```

---

## 명명 규칙

### 파일명

```bash
# ✅ Good: kebab-case for files
user-profile.tsx
use-auth.ts
api-client.ts

# Page components
page.tsx
layout.tsx
loading.tsx
error.tsx
not-found.tsx

# ❌ Bad
UserProfile.tsx      # PascalCase 사용 금지
user_profile.tsx     # snake_case 사용 금지
```

### 컴포넌트명

```typescript
// ✅ Good: PascalCase for components
const UserProfile = () => { /* ... */ };
const DataTable = () => { /* ... */ };
const SearchBox = () => { /* ... */ };

// ❌ Bad
const userProfile = () => { /* ... */ };  // camelCase
const user_profile = () => { /* ... */ };  // snake_case
```

### Props 인터페이스

```typescript
// ✅ Good: ComponentNameProps 패턴
interface UserProfileProps {
  user: User;
  showEmail?: boolean;
}

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  children: ReactNode;
}

// ❌ Bad
interface Props { /* ... */ }              // 너무 일반적
interface IUserProfile { /* ... */ }       // I 접두사 사용 금지
```

### Custom Hooks

```typescript
// ✅ Good: use 접두사

// src/lib/hooks/use-user.ts
'use client';

import { useState, useEffect } from 'react';
import { User } from '@/types/user';

const useUser = (userId: string) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const response = await fetch(`/api/users/${userId}`);
        const data = await response.json();
        setUser(data);
      } catch (error) {
        console.error('Failed to fetch user:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUser();
  }, [userId]);

  return { user, isLoading };
};

export { useUser };
```

### Event Handlers

```typescript
// ✅ Good: handle 접두사
const handleClick = () => { /* ... */ };
const handleSubmit = (e: FormEvent) => { /* ... */ };
const handleChange = (e: ChangeEvent<HTMLInputElement>) => { /* ... */ };

// ❌ Bad
const onClick = () => { /* ... */ };      // 이벤트 prop과 혼동
const click = () => { /* ... */ };        // 동사만
const doClick = () => { /* ... */ };      // do 접두사
```

---

## Best Practices

### 1. Import 경로 alias 사용

```typescript
// ✅ Good: @ alias 사용
import { User } from '@/types/user';
import { getUsers } from '@/lib/api/users';
import Button from '@/components/ui/button';

// ❌ Bad: 상대 경로
import { User } from '../../../types/user';
import { getUsers } from '../../lib/api/users';
```

tsconfig.json 설정:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

### 2. 환경 변수

```typescript
// ✅ Good: 환경 변수 타입 정의

// src/config/env.ts
const env = {
  apiUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
  nodeEnv: process.env.NODE_ENV,
} as const;

export { env };

// 사용
import { env } from '@/config/env';

const response = await fetch(`${env.apiUrl}/users`);
```

.env.local:

```bash
NEXT_PUBLIC_API_URL=https://api.example.com
DATABASE_URL=postgresql://localhost:5432/mydb
```

**중요:**
- `NEXT_PUBLIC_` 접두사: 클라이언트에서 접근 가능
- 접두사 없음: 서버에서만 접근 가능

### 3. TypeScript 타입 Import

```typescript
// ✅ Good: type-only import
import type { User } from '@/types/user';
import type { FC, ReactNode } from 'react';

// 또는 inline
import { type User, type Post } from '@/types';
```

### 4. Dynamic Import (코드 분할)

```typescript
// ✅ Good: Heavy component 동적 로딩

import dynamic from 'next/dynamic';

// Loading fallback과 함께
const HeavyChart = dynamic(() => import('@/components/features/heavy-chart'), {
  loading: () => <div>Loading chart...</div>,
  ssr: false, // 클라이언트에서만 렌더링
});

const DashboardPage = () => {
  return (
    <div>
      <h1>Dashboard</h1>
      <HeavyChart />
    </div>
  );
};

export default DashboardPage;
```

### 5. Image Optimization

```typescript
// ✅ Good: next/image 사용

import Image from 'next/image';

const UserAvatar = ({ user }: { user: User }) => {
  return (
    <Image
      src={user.avatarUrl}
      alt={user.name}
      width={100}
      height={100}
      className="rounded-full"
      priority={false} // LCP가 아닌 경우
    />
  );
};

export default UserAvatar;
```

### 6. Metadata API (SEO)

```typescript
// ✅ Good: Metadata 정의

// src/app/users/[id]/page.tsx

import type { Metadata } from 'next';

interface PageProps {
  params: { id: string };
}

export const generateMetadata = async ({ params }: PageProps): Promise<Metadata> => {
  const user = await getUser(params.id);

  return {
    title: `${user.name} - User Profile`,
    description: `Profile page of ${user.name}`,
    openGraph: {
      title: user.name,
      description: user.bio,
      images: [user.avatarUrl],
    },
  };
};

const UserPage = async ({ params }: PageProps) => {
  // ...
};

export default UserPage;
```

### 7. Server Actions

```typescript
// ✅ Good: Server Actions 사용

// src/app/actions/user.ts
'use server';

import { revalidatePath } from 'next/cache';
import { createUser as createUserDB } from '@/lib/db/users';

const createUser = async (formData: FormData) => {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  try {
    await createUserDB({ name, email });
    revalidatePath('/users');
    return { success: true };
  } catch (error) {
    return { success: false, error: 'Failed to create user' };
  }
};

export { createUser };

// src/components/features/user-create-form.tsx
'use client';

import { createUser } from '@/app/actions/user';

const UserCreateForm = () => {
  const handleSubmit = async (formData: FormData) => {
    const result = await createUser(formData);

    if (result.success) {
      alert('User created!');
    }
  };

  return (
    <form action={handleSubmit}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit">Create</button>
    </form>
  );
};

export default UserCreateForm;
```

### 8. Error Handling

```typescript
// ✅ Good: 에러 바운더리 + try-catch

// src/app/users/[id]/page.tsx

import { notFound } from 'next/navigation';

const UserPage = async ({ params }: PageProps) => {
  try {
    const user = await getUser(params.id);

    if (!user) {
      notFound(); // 404 페이지로 이동
    }

    return <UserProfile user={user} />;
  } catch (error) {
    // error.tsx가 처리
    throw error;
  }
};

export default UserPage;
```

### 9. Performance: Suspense Streaming

```typescript
// ✅ Good: Suspense로 점진적 렌더링

import { Suspense } from 'react';

const DashboardPage = () => {
  return (
    <div>
      {/* 즉시 렌더링 */}
      <h1>Dashboard</h1>

      {/* 비동기 컴포넌트 - 준비되면 렌더링 */}
      <Suspense fallback={<div>Loading stats...</div>}>
        <Stats />
      </Suspense>

      <Suspense fallback={<div>Loading users...</div>}>
        <UserList />
      </Suspense>

      <Suspense fallback={<div>Loading posts...</div>}>
        <PostList />
      </Suspense>
    </div>
  );
};

// 각 컴포넌트는 독립적으로 데이터 fetch
const Stats = async () => {
  const stats = await getStats();
  return <div>{/* Render stats */}</div>;
};

export default DashboardPage;
```

---

## 체크리스트

### 컴포넌트 작성 시

- [ ] Arrow Function으로 작성했는가?
- [ ] Props 타입을 명시했는가?
- [ ] Server/Client Component 구분이 명확한가?
- [ ] `'use client'`가 필요한 곳에만 사용했는가?
- [ ] default export를 사용했는가?

### 페이지 작성 시

- [ ] Page Props 타입을 정의했는가?
- [ ] Metadata를 정의했는가? (SEO)
- [ ] Loading UI를 제공했는가?
- [ ] Error boundary를 구현했는가?

### 데이터 Fetching

- [ ] Server Component에서 가능한 한 fetch했는가?
- [ ] 캐싱 전략을 고려했는가?
- [ ] 에러 처리를 했는가?

### 성능

- [ ] 불필요한 Client Component 사용을 피했는가?
- [ ] Dynamic import로 큰 컴포넌트를 분할했는가?
- [ ] Image 컴포넌트를 사용했는가?
- [ ] Suspense로 점진적 렌더링을 구현했는가?

---

## 도구 설정

### ESLint (.eslintrc.json)

```json
{
  "extends": [
    "next/core-web-vitals",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
    "prefer-arrow-callback": "error",
    "react/function-component-definition": [
      "error",
      {
        "namedComponents": "arrow-function",
        "unnamedComponents": "arrow-function"
      }
    ]
  }
}
```

### Prettier (.prettierrc)

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "arrowParens": "always",
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

---

**문서 위치**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/coding-conventions/`

**버전**: 1.0.0

**작성일**: 2024-10-19
