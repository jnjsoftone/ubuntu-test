# 일반적인 문제 해결

이 문서는 ${PLATFORM_NAME} 플랫폼 개발 시 자주 발생하는 문제와 해결 방법을 정리합니다.

## 🔍 목차

1. [포트 관련 문제](#포트-관련-문제)
2. [데이터베이스 연결 문제](#데이터베이스-연결-문제)
3. [Docker 관련 문제](#docker-관련-문제)
4. [코드 생성 문제](#코드-생성-문제)
5. [GraphQL 관련 문제](#graphql-관련-문제)
6. [환경변수 문제](#환경변수-문제)
7. [Git/GitHub 문제](#gitgithub-문제)

---

## 포트 관련 문제

### ❌ 문제: "Port already in use" 에러
```
Error: listen EADDRINUSE: address already in use :::21201
```

**원인**: 할당된 포트가 이미 다른 프로세스에서 사용 중

**해결방법**:

```bash
# 1. 포트를 사용 중인 프로세스 확인
lsof -i :21201
# 또는
netstat -tuln | grep 21201

# 2. 프로세스 종료
kill -9 <PID>

# 3. Docker 컨테이너 확인
docker ps | grep 21201

# 4. 해당 컨테이너 중지
docker stop <CONTAINER_ID>

# 5. 사용하지 않는 컨테이너 정리
docker container prune
```

**예방**:
```bash
# 프로젝트 시작 전 포트 확인
npm run port:check

# 자동 할당 시스템 사용 (수동 포트 할당 금지)
node /var/services/homes/jungsam/dev/dockers/_manager/scripts/port-allocator.js project <platform-sn> <project-sn>
```

### ❌ 문제: 포트 번호가 잘못 할당됨

**원인**: 수동으로 포트를 설정하거나 환경변수가 잘못됨

**해결방법**:
```bash
# 1. 할당된 포트 확인
cat .env | grep PORT

# 2. 포트 재계산
node /var/services/homes/jungsam/dev/dockers/_manager/scripts/port-allocator.js project <platform-sn> <project-sn>

# 3. .env 파일 재생성
npm run env:regenerate

# 4. Docker 컨테이너 재시작
docker-compose down
docker-compose up -d
```

---

## 데이터베이스 연결 문제

### ❌ 문제: "Connection refused" 에러
```
Error: connect ECONNREFUSED ${BASE_IP}:${PLATFORM_POSTGRES_PORT}
```

**원인**: PostgreSQL 서버가 실행되지 않았거나 접근 불가

**해결방법**:
```bash
# 1. PostgreSQL 컨테이너 상태 확인
docker ps | grep postgres

# 2. 컨테이너가 없으면 시작
docker-compose up -d postgres

# 3. 로그 확인
docker logs ${PLATFORM_NAME}-postgres

# 4. 연결 테스트
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER}

# 5. 네트워크 확인
docker network ls
docker network inspect ${PLATFORM_NAME}_network
```

**환경변수 확인**:
```bash
# .env 파일에서 데이터베이스 설정 확인
cat .env | grep -E "POSTGRES|DATABASE"

# 예상 출력:
# POSTGRES_HOST=1.231.118.217
# POSTGRES_PORT=21202
# POSTGRES_USER=postgres
# DATABASE_URL=postgresql://postgres:password@1.231.118.217:21202/project_name
```

### ❌ 문제: "Database does not exist" 에러
```
Error: database "project_myproject" does not exist
```

**해결방법**:
```bash
# 1. 데이터베이스 목록 확인
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -l

# 2. 데이터베이스 생성
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE DATABASE project_myproject;"

# 3. 또는 npm 스크립트 사용
npm run db:create

# 4. 마이그레이션 실행
npm run migration:run
```

### ❌ 문제: "Too many connections" 에러

**원인**: 데이터베이스 커넥션 풀 고갈

**해결방법**:
```typescript
// ormconfig.json에서 커넥션 풀 설정
{
  "type": "postgres",
  "extra": {
    "max": 20,              // 최대 연결 수 (기본: 10)
    "idleTimeoutMillis": 30000,  // 유휴 연결 타임아웃
    "connectionTimeoutMillis": 2000
  }
}
```

```bash
# PostgreSQL 현재 연결 수 확인
psql -c "SELECT count(*) FROM pg_stat_activity;"

# 프로젝트별 연결 수
psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# 유휴 연결 종료
psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND state_change < NOW() - INTERVAL '10 minutes';"
```

### ❌ 문제: MySQL "Host '172.31.0.1' is not allowed to connect" 에러
```
❌ MySQL Error: Host '172.31.0.1' is not allowed to connect to this MariaDB server
```

**원인**: MySQL 컨테이너의 데이터 디렉토리가 이전에 다른 비밀번호로 초기화되었거나, root 사용자가 원격 접속 권한이 없음

**증상**:
- `create-project-db.js` 스크립트가 DATABASE CREATION 단계에서 실패
- Docker 컨테이너 IP (172.31.0.x)에서 접속 시도 시 거부됨

**해결방법**:

```bash
# 1. MySQL 컨테이너 중지
cd /var/services/homes/jungsam/dev/dockers/databases/mysql-{domain}
docker-compose down

# 2. 기존 데이터 디렉토리 삭제 (⚠️ 주의: 모든 데이터 손실)
rm -rf mysql_data

# 3. 데이터 디렉토리 재생성
mkdir -p mysql_data

# 4. 컨테이너 재시작 (새로운 비밀번호로 초기화됨)
docker-compose up -d

# 5. 초기화 완료 대기 (약 10-15초)
sleep 15

# 6. 연결 테스트
docker exec {container-name} sh -c 'mariadb -u root -p"{password}" -e "SELECT VERSION();"'

# 7. 사용자 권한 확인
docker exec {container-name} sh -c 'mariadb -u root -p"{password}" -e "SELECT user, host FROM mysql.user WHERE user=\"root\";"'
# 예상 출력:
# User  Host
# root  %        <- 모든 호스트에서 접속 가능
# root  localhost
```

**예방**:
- 플랫폼 생성 시 데이터베이스는 자동으로 올바른 비밀번호로 초기화됨
- 기존 mysql_data 디렉토리가 있는 경우 삭제 후 재생성 필요

### ❌ 문제: PostgreSQL "Permission denied" 초기화 에러
```
mkdir: can't create directory '/var/lib/postgresql/data/pgdata': Permission denied
```

**원인**: postgres_data 디렉토리의 권한이 PostgreSQL 사용자(1059:101)가 쓸 수 없게 설정됨

**증상**:
- PostgreSQL 컨테이너 로그에 반복적인 permission denied 에러
- `create-project-db.js` 스크립트 실행 시 `read ECONNRESET` 에러
- 데이터베이스 서버가 정상적으로 시작되지 않음

**해결방법**:

```bash
# 1. PostgreSQL 컨테이너 중지
cd /var/services/homes/jungsam/dev/dockers/databases/postgres-{domain}
docker-compose down

# 2. 데이터 디렉토리 삭제 (⚠️ 주의: 모든 데이터 손실)
rm -rf postgres_data

# 3. 데이터 디렉토리 재생성 및 권한 설정
mkdir -p postgres_data
chmod 777 postgres_data

# 4. 컨테이너 재시작
docker-compose up -d

# 5. 초기화 완료 대기 (약 5-10초)
sleep 10

# 6. 로그 확인
docker logs {container-name} --tail 20
# 예상 출력 마지막 줄:
# database system is ready to accept connections

# 7. 연결 테스트
docker exec {container-name} psql -U admin -d postgres -c "SELECT version();"
```

**디렉토리 권한 체크리스트**:
```bash
# postgres_data 디렉토리 권한 확인
ls -la postgres_data
# drwxrwxrwx (777) 또는 drwxr-xr-x (755) 이상이어야 함

# 권한이 700 (drwx------) 인 경우 수정
chmod 777 postgres_data
```

**자동화**:
프로젝트 생성 스크립트(`create-project.sh`)는 데이터베이스 컨테이너를 자동으로 시작하고 권한을 설정하지만, 수동으로 데이터베이스를 초기화하는 경우 위 단계를 따라야 합니다.

---

## Docker 관련 문제

### ❌ 문제: "Cannot connect to Docker daemon" 에러
```
Error: Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**해결방법**:
```bash
# 1. Docker 서비스 상태 확인
sudo systemctl status docker

# 2. Docker 서비스 시작
sudo systemctl start docker

# 3. 사용자를 docker 그룹에 추가 (권한 문제)
sudo usermod -aG docker $USER
newgrp docker

# 4. Docker 재시작
sudo systemctl restart docker
```

### ❌ 문제: 컨테이너가 계속 재시작됨
```
docker ps -a
CONTAINER ID   STATUS
abc123         Restarting (1) 5 seconds ago
```

**해결방법**:
```bash
# 1. 컨테이너 로그 확인
docker logs <container-id>

# 2. 마지막 100줄만 보기
docker logs --tail 100 <container-id>

# 3. 실시간 로그 보기
docker logs -f <container-id>

# 4. 컨테이너 내부 진입 (디버깅)
docker exec -it <container-id> /bin/bash

# 5. 문제 파악 후 컨테이너 중지
docker stop <container-id>

# 6. 설정 수정 후 재시작
docker-compose up -d
```

### ❌ 문제: "No space left on device" 에러

**원인**: Docker 이미지/볼륨이 디스크를 가득 채움

**해결방법**:
```bash
# 1. Docker 디스크 사용량 확인
docker system df

# 2. 사용하지 않는 이미지 삭제
docker image prune -a

# 3. 사용하지 않는 컨테이너 삭제
docker container prune

# 4. 사용하지 않는 볼륨 삭제
docker volume prune

# 5. 전체 정리 (주의!)
docker system prune -a --volumes

# 6. 특정 이미지만 삭제
docker rmi <image-id>
```

---

## 코드 생성 문제

### ❌ 문제: 메타데이터 검증 실패
```
Error: Invalid metadata: Foreign key references non-existent table 'categories'
```

**해결방법**:
```bash
# 1. 메타데이터 유효성 검사
npm run metadata:validate

# 2. 참조 테이블 확인
ls -la metadata/tables/

# 3. 누락된 테이블 메타데이터 생성
vim metadata/tables/categories.json

# 4. 다시 검증
npm run metadata:validate
```

### ❌ 문제: 코드 생성 후 TypeScript 컴파일 에러
```
Error: Cannot find name 'User'. Did you mean 'UserRole'?
```

**해결방법**:
```bash
# 1. 생성된 파일 확인
ls -la src/entities/
ls -la src/schema/

# 2. Import 경로 확인
grep -r "from.*User" src/

# 3. 전체 재생성
npm run generate:clean
npm run generate:all

# 4. TypeScript 컴파일
npm run build
```

### ❌ 문제: 자동 생성 파일이 덮어씌워짐

**원인**: 자동 생성 파일을 직접 수정함

**해결방법**:
```bash
# 1. 커스텀 코드는 별도 디렉토리에 작성
mkdir -p src/custom/services
mkdir -p src/custom/resolvers

# 2. 확장 패턴 사용
# src/custom/services/user.service.custom.ts
import { UserService } from '../../services/user.service';

export class UserServiceCustom extends UserService {
  // 커스텀 메서드 추가
  async findByEmail(email: string) {
    return this.repository.findOne({ where: { email } });
  }
}
```

---

## GraphQL 관련 문제

### ❌ 문제: "Cannot return null for non-nullable field" 에러
```
Error: Cannot return null for non-nullable field User.email
```

**해결방법**:
```typescript
// ✅ nullable 필드로 변경
type User {
  email: String  # nullable
}

// ✅ 또는 기본값 반환
@ResolveField()
email(@Parent() user: User): string {
  return user.email || '';
}

// ✅ 데이터베이스에서 NOT NULL 확인
// metadata/tables/users.json
{
  "name": "email",
  "type": "varchar",
  "nullable": false  // DB 레벨에서 NOT NULL
}
```

### ❌ 문제: N+1 쿼리 문제
```
Query executed 101 times for fetching users' posts
```

**해결방법**:
```typescript
// ❌ N+1 발생
@Query()
async users(): Promise<User[]> {
  return this.userRepository.find();  // 1번
}

@ResolveField()
async posts(@Parent() user: User): Promise<Post[]> {
  return this.postRepository.find({ userId: user.id });  // N번!
}

// ✅ DataLoader 사용
import DataLoader from 'dataloader';

const postLoader = new DataLoader(async (userIds: string[]) => {
  const posts = await postRepository.find({
    where: { userId: In(userIds) }
  });

  // userId별로 그룹화
  const postsByUser = groupBy(posts, 'userId');
  return userIds.map(id => postsByUser[id] || []);
});

@ResolveField()
async posts(@Parent() user: User, @Ctx() ctx: Context): Promise<Post[]> {
  return ctx.loaders.post.load(user.id);  // 배치로 조회
}

// ✅ 또는 Eager Loading
@Query()
async users(): Promise<User[]> {
  return this.userRepository.find({
    relations: ['posts']  // JOIN으로 한번에 조회
  });
}
```

### ❌ 문제: GraphQL Playground 접속 불가

**해결방법**:
```typescript
// src/index.ts
const server = new ApolloServer({
  schema,
  playground: true,           // 개발 환경에서 활성화
  introspection: true,        // 스키마 조회 허용
  context: ({ req, res }) => ({ req, res }),
});

// 환경별 설정
const server = new ApolloServer({
  schema,
  playground: process.env.NODE_ENV !== 'production',
  introspection: process.env.NODE_ENV !== 'production',
});
```

---

## 환경변수 문제

### ❌ 문제: 환경변수가 undefined
```
Error: DATABASE_URL is not defined
```

**해결방법**:
```bash
# 1. .env 파일 존재 확인
ls -la .env

# 2. .env 파일 내용 확인
cat .env | grep DATABASE_URL

# 3. .env가 없으면 샘플에서 복사
cp .env.sample .env

# 4. 환경변수 로드 확인 (dotenv)
# src/index.ts
import 'dotenv/config';  // 최상단에 추가

console.log('DATABASE_URL:', process.env.DATABASE_URL);

# 5. Docker에서 환경변수 전달 확인
# docker-compose.yml
services:
  app:
    env_file:
      - .env
    environment:
      - DATABASE_URL=${DATABASE_URL}
```

### ❌ 문제: Docker 컨테이너 내부에서 환경변수 다름

**해결방법**:
```bash
# 1. 컨테이너 내부 환경변수 확인
docker exec <container-id> env | grep DATABASE_URL

# 2. docker-compose.yml 확인
# env_file 사용
services:
  app:
    env_file:
      - .env

# 또는 environment 사용
services:
  app:
    environment:
      DATABASE_URL: ${DATABASE_URL}

# 3. 컨테이너 재시작 (환경변수 변경 후)
docker-compose down
docker-compose up -d
```

---

## Git/GitHub 문제

### ❌ 문제: "Permission denied (publickey)" 에러

**해결방법**:
```bash
# 1. SSH 키 확인
ls -la ~/.ssh/
# id_rsa, id_rsa.pub 파일이 있어야 함

# 2. SSH 키가 없으면 생성
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 3. SSH 키를 GitHub에 등록
cat ~/.ssh/id_rsa.pub
# 출력된 내용을 GitHub Settings > SSH Keys에 추가

# 4. SSH 연결 테스트
ssh -T git@github.com
```

### ❌ 문제: Git push 실패 (대용량 파일)
```
Error: File node_modules/... is 150.00 MB; this exceeds GitHub's file size limit of 100.00 MB
```

**해결방법**:
```bash
# 1. .gitignore 확인
cat .gitignore

# 2. node_modules가 .gitignore에 있는지 확인
echo "node_modules/" >> .gitignore

# 3. 이미 커밋된 파일 제거
git rm -r --cached node_modules/
git commit -m "Remove node_modules from git"

# 4. Git 히스토리에서 완전 제거 (BFG 사용)
# https://rtyley.github.io/bfg-repo-cleaner/

# 5. 또는 Git filter-branch 사용
git filter-branch --tree-filter 'rm -rf node_modules' HEAD
```

### ❌ 문제: xgit 명령어 실패
```
Error: xgit: command not found
```

**해결방법**:
```bash
# 1. xgit 설치 확인
which xgit

# 2. xgit PATH 확인
echo $PATH

# 3. xgit가 없으면 설치 (시스템 관리자에게 문의)

# 4. 수동으로 GitHub repo 생성
# GitHub 웹사이트에서 수동 생성 후:
git remote add origin git@github.com:username/repo-name.git
git push -u origin main
```

---

## 🧹 정리 스크립트

### 전체 환경 초기화
```bash
#!/bin/bash
# scripts/reset-environment.sh

echo "=== 환경 초기화 시작 ==="

# 1. Docker 컨테이너 중지
docker-compose down

# 2. Node modules 삭제
rm -rf node_modules

# 3. 빌드 결과물 삭제
rm -rf dist

# 4. 재설치
npm install

# 5. 데이터베이스 재생성
npm run db:drop
npm run db:create
npm run migration:run

# 6. Docker 재시작
docker-compose up -d

echo "=== 환경 초기화 완료 ==="
```

### 포트 충돌 해결
```bash
#!/bin/bash
# scripts/fix-port-conflicts.sh

echo "=== 포트 충돌 해결 ==="

# 프로젝트 포트 범위
START_PORT=${PROJECT_PORT_START}
END_PORT=${PROJECT_PORT_END}

for port in $(seq $START_PORT $END_PORT); do
  PID=$(lsof -t -i:$port)
  if [ ! -z "$PID" ]; then
    echo "Port $port is used by PID $PID. Killing..."
    kill -9 $PID
  fi
done

echo "=== 포트 정리 완료 ==="
```

## 🆘 추가 도움말

문제가 해결되지 않으면:

1. **로그 확인**:
   ```bash
   # 애플리케이션 로그
   docker-compose logs -f app

   # 데이터베이스 로그
   docker-compose logs -f postgres

   # 모든 로그
   docker-compose logs -f
   ```

2. **AI 도구 활용**:
   ```bash
   # Claude Code에 에러 메시지와 함께 요청
   claude-code "에러 해결: [에러 메시지 붙여넣기]"

   # 컨텍스트 제공
   claude-code "다음 로그를 분석해주세요: $(docker logs container-id)"
   ```

3. **문서 참조**:
   - [개발 워크플로우](/docs/guidelines/02-development-workflow.md)
   - [데이터베이스 관리](/docs/guidelines/03-database-management.md)
   - [포트 할당 시스템](/docs/architecture/03-port-allocation.md)

4. **플랫폼 관리자에게 문의**

## 🔗 관련 문서

- [데이터베이스 트러블슈팅](./02-database-issues.md)
- [Docker 트러블슈팅](./03-docker-issues.md)
- [GraphQL 트러블슈팅](./04-graphql-issues.md)
