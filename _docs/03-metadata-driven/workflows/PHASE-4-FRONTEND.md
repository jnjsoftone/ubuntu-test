# Phase 4: Frontend 개발 - Claude Code 프롬프트

> Next.js 15 + React 19 프론트엔드 개발 단계

## 4.1 Apollo Client 설정

### 프롬프트 4-1: GraphQL Client 설정

```
Next.js 15 App Router에서 Apollo Client를 설정해주세요:

요구사항:
1. Apollo Client 설정
   - frontend/src/lib/apollo-client.ts
   - SSR 지원
   - 인증 토큰 헤더 추가
   - 에러 처리

2. Apollo Provider
   - frontend/src/providers/apollo-provider.tsx

3. GraphQL Code Generator 설정
   - codegen.yml
   - 타입 생성 설정

4. 환경 변수
   - .env.local
   - NEXT_PUBLIC_GRAPHQL_URL

GraphQL 서버: ${NEXT_PUBLIC_GRAPHQL_URL}
```

**예상 생성 파일:**

```typescript
// frontend/src/lib/apollo-client.ts
import { ApolloClient, InMemoryCache, createHttpLink, from } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { onError } from '@apollo/client/link/error';

const httpLink = createHttpLink({
  uri: process.env.NEXT_PUBLIC_GRAPHQL_URL || 'http://localhost:4000/graphql',
});

// 인증 토큰 추가
const authLink = setContext((_, { headers }) => {
  const token = typeof window !== 'undefined'
    ? localStorage.getItem('accessToken')
    : null;

  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : '',
    }
  };
});

// 에러 처리
const errorLink = onError(({ graphQLErrors, networkError }) => {
  if (graphQLErrors) {
    graphQLErrors.forEach(({ message, extensions }) => {
      if (extensions?.code === 'UNAUTHENTICATED') {
        // 토큰 만료 시 처리
        if (typeof window !== 'undefined') {
          localStorage.removeItem('accessToken');
          localStorage.removeItem('refreshToken');
          window.location.href = '/login';
        }
      }
      console.error(`[GraphQL error]: ${message}`);
    });
  }

  if (networkError) {
    console.error(`[Network error]: ${networkError}`);
  }
});

export const client = new ApolloClient({
  link: from([errorLink, authLink, httpLink]),
  cache: new InMemoryCache(),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network',
    },
  },
});

// frontend/src/providers/apollo-provider.tsx
'use client';

import { ApolloProvider as Provider } from '@apollo/client';
import { client } from '@/lib/apollo-client';

export function ApolloProvider({ children }: { children: React.ReactNode }) {
  return <Provider client={client}>{children}</Provider>;
}

// frontend/src/app/layout.tsx
import { ApolloProvider } from '@/providers/apollo-provider';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        <ApolloProvider>
          {children}
        </ApolloProvider>
      </body>
    </html>
  );
}
```

---

## 4.2 React 컴포넌트 생성

### 프롬프트 4-2: Form/Table 컴포넌트 자동 생성

```
메타데이터 기반으로 React 컴포넌트를 생성해주세요:

작업:
1. React Form Generator 실행
   npm run generate:react:forms

2. React Table Generator 실행
   npm run generate:react:tables

3. 생성 파일 확인
   - frontend/src/generated/forms/user-form.tsx
   - frontend/src/generated/forms/role-form.tsx
   - frontend/src/generated/tables/user-table.tsx
   - frontend/src/generated/tables/role-table.tsx

4. GraphQL Hooks 생성
   - frontend/src/generated/hooks/use-users.ts
   - frontend/src/generated/hooks/use-roles.ts

참고:
/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/CODE-GENERATION-TEMPLATES.md
```

**생성된 컴포넌트 예시는 이전에 작성한 템플릿 참조**

---

## 4.3 인증 관련 커스텀 컴포넌트

### 프롬프트 4-3: 회원가입 페이지 구현

```
회원가입 페이지를 구현해주세요:

파일: frontend/src/app/(auth)/register/page.tsx

요구사항:
1. RegisterInput 폼
   - email (이메일 검증)
   - password (최소 8자, 대소문자+숫자+특수문자)
   - confirmPassword (비밀번호 확인)
   - firstName
   - lastName
   - phone (선택)
   - 이용약관 동의 (필수)
   - 개인정보 처리방침 동의 (필수)

2. GraphQL Mutation 사용
   - REGISTER mutation

3. 에러 처리
   - 이메일 중복
   - 비밀번호 불일치
   - 유효성 검증 실패

4. 성공 시
   - 이메일 인증 안내 메시지
   - 로그인 페이지로 리다이렉트

UI 라이브러리: shadcn/ui
```

**예상 구현:**

```typescript
// frontend/src/app/(auth)/register/page.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useMutation, gql } from '@apollo/client';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { toast } from 'sonner';

import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
  FormDescription,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const REGISTER_MUTATION = gql`
  mutation Register($input: RegisterInput!) {
    register(input: $input) {
      user {
        id
        email
        firstName
        lastName
      }
      accessToken
      refreshToken
    }
  }
`;

const registerSchema = z.object({
  email: z.string()
    .email('올바른 이메일 형식이 아닙니다')
    .min(1, '이메일을 입력하세요'),
  password: z.string()
    .min(8, '비밀번호는 최소 8자 이상이어야 합니다')
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
      '비밀번호는 대소문자, 숫자, 특수문자를 포함해야 합니다'
    ),
  confirmPassword: z.string(),
  firstName: z.string()
    .min(2, '이름은 최소 2자 이상이어야 합니다')
    .max(100, '이름은 최대 100자까지 입력 가능합니다'),
  lastName: z.string()
    .min(2, '성은 최소 2자 이상이어야 합니다')
    .max(100, '성은 최대 100자까지 입력 가능합니다'),
  phone: z.string().optional(),
  agreeToTerms: z.boolean().refine(val => val === true, {
    message: '이용약관에 동의해주세요'
  }),
  agreeToPrivacy: z.boolean().refine(val => val === true, {
    message: '개인정보 처리방침에 동의해주세요'
  }),
}).refine(data => data.password === data.confirmPassword, {
  message: '비밀번호가 일치하지 않습니다',
  path: ['confirmPassword'],
});

type RegisterFormValues = z.infer<typeof registerSchema>;

export default function RegisterPage() {
  const router = useRouter();
  const [register, { loading }] = useMutation(REGISTER_MUTATION);

  const form = useForm<RegisterFormValues>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      email: '',
      password: '',
      confirmPassword: '',
      firstName: '',
      lastName: '',
      phone: '',
      agreeToTerms: false,
      agreeToPrivacy: false,
    }
  });

  const onSubmit = async (data: RegisterFormValues) => {
    try {
      const { data: result } = await register({
        variables: {
          input: {
            email: data.email,
            password: data.password,
            firstName: data.firstName,
            lastName: data.lastName,
            phone: data.phone,
          }
        }
      });

      // 토큰 저장
      localStorage.setItem('accessToken', result.register.accessToken);
      localStorage.setItem('refreshToken', result.register.refreshToken);

      toast.success('회원가입이 완료되었습니다!', {
        description: '이메일 인증을 진행해주세요.'
      });

      router.push('/verify-email');
    } catch (error: any) {
      if (error.graphQLErrors?.[0]?.extensions?.code === 'EMAIL_ALREADY_EXISTS') {
        form.setError('email', {
          message: '이미 사용 중인 이메일입니다'
        });
      } else {
        toast.error('회원가입에 실패했습니다', {
          description: error.message
        });
      }
    }
  };

  return (
    <div className="container max-w-md mx-auto py-10">
      <Card>
        <CardHeader>
          <CardTitle>회원가입</CardTitle>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              {/* Email */}
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>이메일 *</FormLabel>
                    <FormControl>
                      <Input
                        {...field}
                        type="email"
                        placeholder="user@example.com"
                        disabled={loading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Password */}
              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>비밀번호 *</FormLabel>
                    <FormControl>
                      <Input
                        {...field}
                        type="password"
                        placeholder="••••••••"
                        disabled={loading}
                      />
                    </FormControl>
                    <FormDescription>
                      최소 8자, 대소문자+숫자+특수문자 포함
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Confirm Password */}
              <FormField
                control={form.control}
                name="confirmPassword"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>비밀번호 확인 *</FormLabel>
                    <FormControl>
                      <Input
                        {...field}
                        type="password"
                        placeholder="••••••••"
                        disabled={loading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* First Name */}
              <FormField
                control={form.control}
                name="firstName"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>이름 *</FormLabel>
                    <FormControl>
                      <Input
                        {...field}
                        placeholder="길동"
                        disabled={loading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Last Name */}
              <FormField
                control={form.control}
                name="lastName"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>성 *</FormLabel>
                    <FormControl>
                      <Input
                        {...field}
                        placeholder="홍"
                        disabled={loading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Phone */}
              <FormField
                control={form.control}
                name="phone"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>전화번호</FormLabel>
                    <FormControl>
                      <Input
                        {...field}
                        type="tel"
                        placeholder="010-1234-5678"
                        disabled={loading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Terms Agreement */}
              <FormField
                control={form.control}
                name="agreeToTerms"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                    <FormControl>
                      <Checkbox
                        checked={field.value}
                        onCheckedChange={field.onChange}
                        disabled={loading}
                      />
                    </FormControl>
                    <div className="space-y-1 leading-none">
                      <FormLabel>
                        이용약관에 동의합니다 *
                      </FormLabel>
                      <FormMessage />
                    </div>
                  </FormItem>
                )}
              />

              {/* Privacy Agreement */}
              <FormField
                control={form.control}
                name="agreeToPrivacy"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                    <FormControl>
                      <Checkbox
                        checked={field.value}
                        onCheckedChange={field.onChange}
                        disabled={loading}
                      />
                    </FormControl>
                    <div className="space-y-1 leading-none">
                      <FormLabel>
                        개인정보 처리방침에 동의합니다 *
                      </FormLabel>
                      <FormMessage />
                    </div>
                  </FormItem>
                )}
              />

              <Button type="submit" className="w-full" disabled={loading}>
                {loading ? '처리 중...' : '회원가입'}
              </Button>

              <div className="text-center text-sm text-gray-600">
                이미 계정이 있으신가요?{' '}
                <a href="/login" className="text-blue-600 hover:underline">
                  로그인
                </a>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  );
}
```

---

### 프롬프트 4-4: 로그인 페이지 구현

```
로그인 페이지를 구현해주세요:

파일: frontend/src/app/(auth)/login/page.tsx

요구사항:
1. LoginInput 폼
   - email
   - password
   - remember me (선택)

2. GraphQL Mutation
   - LOGIN mutation

3. 성공 시
   - 토큰 저장 (localStorage)
   - 대시보드로 리다이렉트

4. 추가 링크
   - 비밀번호 찾기
   - 회원가입

UI: shadcn/ui
```

---

### 프롬프트 4-5: 사용자 프로필 페이지 구현

```
로그인한 사용자의 프로필 페이지를 구현해주세요:

파일: frontend/src/app/(app)/profile/page.tsx

요구사항:
1. ME Query로 현재 사용자 정보 조회

2. 표시 정보
   - 프로필 이미지
   - 이름 (firstName + lastName)
   - 이메일
   - 전화번호
   - 가입일
   - 역할 (roles)

3. 편집 기능
   - 프로필 정보 수정
   - 비밀번호 변경 (별도 폼)

4. 인증 확인
   - 로그인하지 않은 경우 로그인 페이지로 리다이렉트

컴포넌트:
- ProfileCard
- EditProfileForm
- ChangePasswordForm
```

**예상 구현:**

```typescript
// frontend/src/app/(app)/profile/page.tsx
'use client';

import { useQuery, useMutation, gql } from '@apollo/client';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

import { ProfileCard } from '@/components/profile/profile-card';
import { EditProfileForm } from '@/components/profile/edit-profile-form';
import { ChangePasswordForm } from '@/components/profile/change-password-form';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Skeleton } from '@/components/ui/skeleton';

const ME_QUERY = gql`
  query Me {
    me {
      id
      email
      firstName
      lastName
      phone
      avatarUrl
      emailVerified
      isActive
      createdAt
      userRoles {
        role {
          name
          description
        }
      }
    }
  }
`;

export default function ProfilePage() {
  const router = useRouter();
  const { data, loading, error } = useQuery(ME_QUERY);

  useEffect(() => {
    if (error && error.graphQLErrors[0]?.extensions?.code === 'UNAUTHENTICATED') {
      router.push('/login');
    }
  }, [error, router]);

  if (loading) {
    return (
      <div className="container max-w-4xl mx-auto py-10">
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  if (!data?.me) {
    return null;
  }

  const user = data.me;

  return (
    <div className="container max-w-4xl mx-auto py-10">
      <h1 className="text-3xl font-bold mb-6">내 프로필</h1>

      <Tabs defaultValue="profile" className="space-y-6">
        <TabsList>
          <TabsTrigger value="profile">프로필 정보</TabsTrigger>
          <TabsTrigger value="edit">프로필 수정</TabsTrigger>
          <TabsTrigger value="password">비밀번호 변경</TabsTrigger>
        </TabsList>

        <TabsContent value="profile">
          <ProfileCard user={user} />
        </TabsContent>

        <TabsContent value="edit">
          <EditProfileForm user={user} />
        </TabsContent>

        <TabsContent value="password">
          <ChangePasswordForm />
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

---

## 4.4 관리자 페이지

### 프롬프트 4-6: 사용자 관리 페이지 구현

```
관리자용 사용자 관리 페이지를 구현해주세요:

파일: frontend/src/app/(admin)/admin/users/page.tsx

요구사항:
1. 사용자 목록 조회 (USERS Query)
   - 필터링 (이름, 이메일, 상태)
   - 정렬
   - 페이지네이션

2. 생성된 UserTable 컴포넌트 사용
   - frontend/src/generated/tables/user-table.tsx

3. 기능
   - 사용자 추가
   - 사용자 수정
   - 사용자 삭제
   - 역할 할당

4. 권한 체크
   - admin 역할만 접근 가능
   - 권한 없는 경우 403 페이지

커스텀 Hook:
- useAuth() - 현재 사용자 및 권한 확인
- useUsers() - 사용자 CRUD
```

**예상 구현:**

```typescript
// frontend/src/app/(admin)/admin/users/page.tsx
'use client';

import { useState } from 'react';
import { useQuery, gql } from '@apollo/client';
import { useRouter } from 'next/navigation';

import { UserTable } from '@/generated/tables/user-table';
import { Button } from '@/components/ui/button';
import { PlusIcon } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { Forbidden } from '@/components/errors/forbidden';

const USERS_QUERY = gql`
  query Users($filter: UserFilter, $limit: Int, $offset: Int) {
    users(filter: $filter, limit: $limit, offset: $offset) {
      id
      email
      firstName
      lastName
      isActive
      emailVerified
      createdAt
      userRoles {
        role {
          name
        }
      }
    }
    usersCount(filter: $filter)
  }
`;

export default function AdminUsersPage() {
  const router = useRouter();
  const { user, hasRole } = useAuth();
  const [filter, setFilter] = useState({});
  const [pagination, setPagination] = useState({ limit: 20, offset: 0 });

  const { data, loading, refetch } = useQuery(USERS_QUERY, {
    variables: {
      filter,
      ...pagination
    }
  });

  // 권한 체크
  if (!hasRole('admin')) {
    return <Forbidden />;
  }

  return (
    <div className="container mx-auto py-10">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">사용자 관리</h1>

        <Button onClick={() => router.push('/admin/users/new')}>
          <PlusIcon className="mr-2 h-4 w-4" />
          새 사용자
        </Button>
      </div>

      <UserTable
        data={data?.users || []}
        loading={loading}
        onRowClick={(user) => router.push(`/admin/users/${user.id}`)}
      />
    </div>
  );
}
```

---

## 4.5 인증 Hook

### 프롬프트 4-7: useAuth Hook 구현

```
인증 관련 커스텀 Hook을 구현해주세요:

파일: frontend/src/hooks/use-auth.ts

기능:
1. useAuth()
   - 현재 로그인 사용자 정보
   - 로그인 상태
   - 역할 확인 (hasRole)
   - 권한 확인 (hasPermission)

2. useLogin()
   - 로그인 Mutation
   - 토큰 저장
   - 리다이렉트

3. useLogout()
   - 로그아웃 Mutation
   - 토큰 삭제
   - 리다이렉트

4. useRegister()
   - 회원가입 Mutation

Context 사용:
- AuthContext로 전역 상태 관리
- AuthProvider 구현
```

**예상 구현:**

```typescript
// frontend/src/contexts/auth-context.tsx
'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { useQuery, useMutation, gql } from '@apollo/client';

const ME_QUERY = gql`
  query Me {
    me {
      id
      email
      firstName
      lastName
      emailVerified
      userRoles {
        role {
          name
          permissions {
            name
            resource
            action
          }
        }
      }
    }
  }
`;

const LOGIN_MUTATION = gql`
  mutation Login($input: LoginInput!) {
    login(input: $input) {
      user {
        id
        email
      }
      accessToken
      refreshToken
    }
  }
`;

const LOGOUT_MUTATION = gql`
  mutation Logout {
    logout
  }
`;

interface AuthContextValue {
  user: any | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  hasRole: (role: string) => boolean;
  hasPermission: (resource: string, action: string) => boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<any | null>(null);
  const { data, loading, refetch } = useQuery(ME_QUERY, {
    skip: typeof window === 'undefined' || !localStorage.getItem('accessToken')
  });

  const [loginMutation] = useMutation(LOGIN_MUTATION);
  const [logoutMutation] = useMutation(LOGOUT_MUTATION);

  useEffect(() => {
    if (data?.me) {
      setUser(data.me);
    }
  }, [data]);

  const login = async (email: string, password: string) => {
    const { data } = await loginMutation({
      variables: { input: { email, password } }
    });

    localStorage.setItem('accessToken', data.login.accessToken);
    localStorage.setItem('refreshToken', data.login.refreshToken);

    await refetch();
  };

  const logout = async () => {
    await logoutMutation();

    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');

    setUser(null);
  };

  const hasRole = (role: string): boolean => {
    if (!user) return false;
    return user.userRoles.some((ur: any) => ur.role.name === role);
  };

  const hasPermission = (resource: string, action: string): boolean => {
    if (!user) return false;

    return user.userRoles.some((ur: any) =>
      ur.role.permissions.some((p: any) =>
        p.resource === resource && p.action === action
      )
    );
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, hasRole, hasPermission }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

// frontend/src/hooks/use-auth.ts
export { useAuth } from '@/contexts/auth-context';
```

---

## 4.6 Protected Route

### 프롬프트 4-8: Protected Route 컴포넌트 구현

```
인증이 필요한 페이지를 위한 Protected Route를 구현해주세요:

파일:
- frontend/src/components/auth/protected-route.tsx
- frontend/src/components/auth/role-guard.tsx

기능:
1. ProtectedRoute
   - 로그인 확인
   - 미인증 시 로그인 페이지로 리다이렉트

2. RoleGuard
   - 특정 역할 확인
   - 권한 없는 경우 403 페이지

사용 예시:
```tsx
// 로그인 필요
<ProtectedRoute>
  <ProfilePage />
</ProtectedRoute>

// Admin 역할 필요
<RoleGuard roles={['admin']}>
  <AdminPage />
</RoleGuard>
```
```

---

## 4.7 UI 컴포넌트 라이브러리

### 프롬프트 4-9: shadcn/ui 컴포넌트 설치 및 커스터마이징

```
프로젝트에 필요한 shadcn/ui 컴포넌트를 설치하고 커스터마이징해주세요:

필요한 컴포넌트:
- form (폼 관련)
- input, textarea, select, checkbox
- button
- card
- table
- dialog (모달)
- toast (알림)
- tabs
- skeleton (로딩)
- badge
- dropdown-menu
- avatar

설치:
npx shadcn@latest add <component-name>

커스터마이징:
- 컬러 테마 설정 (tailwind.config.ts)
- 다크 모드 지원
```

---

## 체크리스트

Frontend 개발 단계 완료 전 확인사항:

- [ ] Apollo Client 설정 완료
- [ ] GraphQL Code Generator 설정 완료
- [ ] React 컴포넌트 자동 생성 완료
  - [ ] Forms
  - [ ] Tables
- [ ] 인증 페이지 구현 완료
  - [ ] 회원가입
  - [ ] 로그인
  - [ ] 비밀번호 찾기
  - [ ] 이메일 인증
- [ ] 사용자 프로필 페이지 완료
- [ ] 관리자 페이지 완료
  - [ ] 사용자 관리
  - [ ] 역할 관리
  - [ ] 권한 관리
- [ ] 인증/권한 시스템 완료
  - [ ] useAuth Hook
  - [ ] AuthContext
  - [ ] ProtectedRoute
  - [ ] RoleGuard
- [ ] UI 컴포넌트 설치 완료
- [ ] 반응형 디자인 확인
- [ ] 다크 모드 지원 (선택)
- [ ] 에러 처리 확인
- [ ] 로딩 상태 처리 확인
