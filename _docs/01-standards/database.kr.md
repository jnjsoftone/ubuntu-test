# 데이터베이스 관리 가이드라인

이 문서는 ${PLATFORM_NAME} 플랫폼에서의 데이터베이스 관리 가이드라인입니다.

## 🗄️ 데이터베이스 아키텍처

### 공유 데이터베이스 인스턴스
- **PostgreSQL**: 플랫폼 전체에서 하나의 PostgreSQL 인스턴스 공유
- **MySQL**: 플랫폼 전체에서 하나의 MySQL 인스턴스 공유 (선택적)
- **포트**: `${PLATFORM_POSTGRES_PORT}`, `${PLATFORM_MYSQL_PORT}`

### 프로젝트별 데이터베이스
각 프로젝트는 독립적인 데이터베이스를 사용:
```
PostgreSQL Instance (포트 ${PLATFORM_POSTGRES_PORT})
├── platform_metadata     # 플랫폼 메타데이터
├── user_mgmt_db         # 프로젝트 1: user-mgmt
├── blog_db              # 프로젝트 2: blog
└── ecommerce_db         # 프로젝트 3: ecommerce
```

**네이밍 규칙**: `{project_snake_case}_db`
- 프로젝트명만 사용 (플랫폼명 미포함)
- snake_case 변환
- `_db` suffix 추가

## 🚀 데이터베이스 초기 설정

### 1. 프로젝트 데이터베이스 생성
```bash
# 자동 생성 (프로젝트 생성 시 자동 실행됨)
npm run db:create

# 수동 생성 (프로젝트명을 snake_case로 변환 후 _db 추가)
# 예: my-ecommerce → my_ecommerce_db
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER} -c "CREATE DATABASE my_ecommerce_db;"
```

### 2. 연결 설정 확인
```bash
# .env 파일에서 DATABASE_URL 확인
cat .env | grep DATABASE_URL

# 예시 (프로젝트명: my-ecommerce):
# DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${BASE_IP}:${PLATFORM_POSTGRES_PORT}/my_ecommerce_db?schema=public
```

### 3. 데이터베이스 연결 테스트
```bash
# TypeORM CLI로 연결 테스트
npm run db:check

# psql로 직접 연결
psql "${DATABASE_URL}"
```

## 📋 스키마 설계

### 메타데이터 기반 설계
메타데이터 파일로 테이블 정의:

```
metadata/tables/
├── users.json
├── posts.json
├── comments.json
└── categories.json
```

### 테이블 메타데이터 예시
```json
{
  "tableName": "posts",
  "description": "블로그 포스트",
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
      "name": "content",
      "type": "text",
      "nullable": false,
      "comment": "포스트 본문"
    },
    {
      "name": "status",
      "type": "enum",
      "enum": ["DRAFT", "PUBLISHED", "ARCHIVED"],
      "default": "DRAFT",
      "comment": "포스트 상태"
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
      "name": "created_at",
      "type": "timestamp",
      "default": "now()",
      "nullable": false
    },
    {
      "name": "updated_at",
      "type": "timestamp",
      "default": "now()",
      "onUpdate": "now()",
      "nullable": false
    }
  ],
  "indexes": [
    {
      "name": "idx_posts_user_id",
      "columns": ["user_id"]
    },
    {
      "name": "idx_posts_status",
      "columns": ["status"]
    },
    {
      "name": "idx_posts_created_at",
      "columns": ["created_at"],
      "order": "DESC"
    }
  ],
  "uniqueConstraints": [
    {
      "name": "uq_posts_title_user",
      "columns": ["title", "user_id"]
    }
  ]
}
```

### 관계 메타데이터 예시
```json
{
  "name": "user-posts",
  "type": "one-to-many",
  "from": {
    "table": "users",
    "column": "id",
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
  }
}
```

### 데이터 타입 가이드

| 메타데이터 타입 | PostgreSQL | TypeORM | 용도 |
|--------------|-----------|---------|------|
| `uuid` | UUID | `uuid` | 고유 식별자 |
| `varchar` | VARCHAR | `varchar` | 짧은 문자열 |
| `text` | TEXT | `text` | 긴 문자열 |
| `int` | INTEGER | `int` | 정수 |
| `bigint` | BIGINT | `bigint` | 큰 정수 |
| `decimal` | DECIMAL | `decimal` | 정확한 소수 |
| `float` | DOUBLE PRECISION | `float` | 부동소수점 |
| `boolean` | BOOLEAN | `boolean` | 참/거짓 |
| `date` | DATE | `date` | 날짜 |
| `timestamp` | TIMESTAMP | `timestamp` | 날짜+시간 |
| `json` | JSONB | `jsonb` | JSON 데이터 |
| `enum` | ENUM | `enum` | 열거형 |

## 🔄 마이그레이션 관리

### 마이그레이션 자동 생성
```bash
# 메타데이터 변경 감지 후 자동 생성
npm run migration:generate -- -n DescriptiveName

# 예시
npm run migration:generate -- -n CreatePostsTable
npm run migration:generate -- -n AddUserIdToComments
```

### 마이그레이션 수동 작성
```bash
# 빈 마이그레이션 파일 생성
npm run migration:create -- -n CustomMigration
```

**마이그레이션 파일 예시 (migrations/1634567890123-CreatePostsTable.ts)**:
```typescript
import { MigrationInterface, QueryRunner, Table, TableForeignKey, TableIndex } from 'typeorm';

export class CreatePostsTable1634567890123 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 테이블 생성
    await queryRunner.createTable(
      new Table({
        name: 'posts',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          { name: 'title', type: 'varchar', length: '200', isNullable: false },
          { name: 'content', type: 'text', isNullable: false },
          {
            name: 'status',
            type: 'enum',
            enum: ['DRAFT', 'PUBLISHED', 'ARCHIVED'],
            default: "'DRAFT'",
          },
          { name: 'user_id', type: 'uuid', isNullable: false },
          { name: 'created_at', type: 'timestamp', default: 'now()' },
          { name: 'updated_at', type: 'timestamp', default: 'now()' },
        ],
      }),
      true
    );

    // 외래키 생성
    await queryRunner.createForeignKey(
      'posts',
      new TableForeignKey({
        columnNames: ['user_id'],
        referencedTableName: 'users',
        referencedColumnNames: ['id'],
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      })
    );

    // 인덱스 생성
    await queryRunner.createIndex(
      'posts',
      new TableIndex({
        name: 'idx_posts_user_id',
        columnNames: ['user_id'],
      })
    );

    await queryRunner.createIndex(
      'posts',
      new TableIndex({
        name: 'idx_posts_created_at',
        columnNames: ['created_at'],
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('posts');
  }
}
```

### 마이그레이션 실행
```bash
# 마이그레이션 상태 확인
npm run migration:show

# 마이그레이션 실행 (모두)
npm run migration:run

# 마이그레이션 롤백 (1개)
npm run migration:revert

# 특정 마이그레이션까지 실행
npm run migration:run -- --transaction all
```

### 마이그레이션 베스트 프랙티스

#### ✅ DO (권장)
1. **명확한 이름 사용**
   ```bash
   ✅ CreateUsersTable
   ✅ AddEmailIndexToUsers
   ✅ AlterPostsAddPublishedAt
   ❌ Migration1
   ❌ Update
   ```

2. **원자적 변경**
   - 하나의 마이그레이션은 하나의 논리적 변경만 수행
   - 테이블 생성, 컬럼 추가, 인덱스 추가 등을 분리

3. **항상 down() 구현**
   ```typescript
   public async down(queryRunner: QueryRunner): Promise<void> {
     // 롤백 로직 필수
   }
   ```

4. **데이터 마이그레이션 시 백업**
   ```typescript
   public async up(queryRunner: QueryRunner): Promise<void> {
     // 백업 테이블 생성
     await queryRunner.query(`CREATE TABLE users_backup AS SELECT * FROM users`);

     // 데이터 변경
     await queryRunner.query(`UPDATE users SET ...`);
   }
   ```

#### ❌ DON'T (비권장)
1. **이미 적용된 마이그레이션 수정 금지**
2. **프로덕션 데이터 직접 삭제 금지**
3. **트랜잭션 없이 복잡한 변경 금지**

## 🔍 쿼리 최적화

### 인덱스 전략

#### 인덱스가 필요한 경우
- WHERE 절에 자주 사용되는 컬럼
- JOIN 조건에 사용되는 컬럼 (외래키)
- ORDER BY에 사용되는 컬럼
- GROUP BY에 사용되는 컬럼

#### 인덱스 생성 예시
```typescript
// 단일 컬럼 인덱스
@Index()
@Column()
email: string;

// 복합 인덱스 (순서 중요!)
@Index(['user_id', 'created_at'])

// 유니크 인덱스
@Index({ unique: true })
@Column()
username: string;

// 부분 인덱스 (PostgreSQL)
@Index({ where: `status = 'PUBLISHED'` })
```

### N+1 쿼리 문제 해결

#### ❌ 문제: N+1 쿼리
```typescript
// 1번의 쿼리 (모든 포스트)
const posts = await postRepository.find();

// N번의 쿼리 (각 포스트의 작성자)
for (const post of posts) {
  post.user = await userRepository.findOne(post.user_id); // N번 실행!
}
```

#### ✅ 해결: Eager Loading
```typescript
// 1번의 쿼리로 모든 데이터 가져오기
const posts = await postRepository.find({
  relations: ['user'], // JOIN으로 한번에 조회
});
```

#### ✅ 해결: QueryBuilder
```typescript
const posts = await postRepository
  .createQueryBuilder('post')
  .leftJoinAndSelect('post.user', 'user')
  .where('post.status = :status', { status: 'PUBLISHED' })
  .orderBy('post.created_at', 'DESC')
  .getMany();
```

### 쿼리 성능 분석
```typescript
// TypeORM 로깅 활성화 (ormconfig.json)
{
  "logging": ["query", "error"],
  "maxQueryExecutionTime": 1000 // 1초 이상 걸리는 쿼리 로그
}

// 느린 쿼리 분석
const result = await queryRunner.query(`
  EXPLAIN ANALYZE
  SELECT * FROM posts WHERE user_id = $1
`, [userId]);
```

## 🔐 데이터베이스 보안

### 1. 연결 보안
```bash
# .env 파일 권한 설정
chmod 600 .env

# 절대 git에 커밋하지 말 것
echo ".env" >> .gitignore
```

### 2. SQL Injection 방지
```typescript
// ❌ 위험: 문자열 직접 삽입
const query = `SELECT * FROM users WHERE email = '${email}'`;

// ✅ 안전: 파라미터 바인딩
const user = await repository.findOne({ where: { email } });

// ✅ 안전: QueryBuilder
const user = await repository
  .createQueryBuilder('user')
  .where('user.email = :email', { email })
  .getOne();
```

### 3. 권한 관리
```sql
-- 애플리케이션 전용 사용자 생성
CREATE USER app_user WITH PASSWORD 'secure_password';

-- 필요한 권한만 부여
GRANT CONNECT ON DATABASE my_ecommerce_db TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- 민감한 권한은 제외
REVOKE DROP, TRUNCATE ON ALL TABLES IN SCHEMA public FROM app_user;
```

### 4. 민감 데이터 암호화
```typescript
import * as bcrypt from 'bcrypt';

// 비밀번호 해싱
@BeforeInsert()
@BeforeUpdate()
async hashPassword() {
  if (this.password) {
    this.password = await bcrypt.hash(this.password, 10);
  }
}

// 민감 데이터 제외 (GraphQL/API)
@Column()
@Exclude({ toPlainOnly: true }) // API 응답에서 제외
password: string;
```

## 🔄 백업 및 복구

### 자동 백업 설정
```bash
# cron 작업 등록
crontab -e

# 매일 새벽 3시 백업
0 3 * * * /var/services/homes/jungsam/dev/dockers/platforms/${PLATFORM_NAME}/scripts/backup-db.sh
```

### 백업 스크립트 (scripts/backup-db.sh)
```bash
#!/bin/bash
BACKUP_DIR="/volume1/backups/${PLATFORM_NAME}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# 프로젝트명을 snake_case로 변환 (예: my-ecommerce → my_ecommerce_db)
DB_NAME="my_ecommerce_db"

mkdir -p ${BACKUP_DIR}

# PostgreSQL 백업
pg_dump -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} \
  -U ${POSTGRES_USER} -d ${DB_NAME} \
  -F c -f ${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump

# 7일 이상 된 백업 삭제
find ${BACKUP_DIR} -name "*.dump" -mtime +7 -delete

echo "Backup completed: ${DB_NAME}_${TIMESTAMP}.dump"
```

### 복구
```bash
# 복구 전 현재 데이터베이스 백업
npm run db:backup

# 백업 파일에서 복구
pg_restore -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} \
  -U ${POSTGRES_USER} -d ${DB_NAME} \
  --clean --if-exists \
  /volume1/backups/${PLATFORM_NAME}/${DB_NAME}_20241019_030000.dump
```

## 📊 모니터링

### 연결 수 모니터링
```sql
-- 현재 연결 수 확인
SELECT count(*) FROM pg_stat_activity WHERE datname = 'my_ecommerce_db';

-- 연결 상세 정보
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE datname = 'my_ecommerce_db';
```

### 테이블 크기 모니터링
```sql
-- 테이블별 크기
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 느린 쿼리 모니터링
```sql
-- postgresql.conf 설정
log_min_duration_statement = 1000  # 1초 이상 쿼리 로그

-- pg_stat_statements 확장 설치
CREATE EXTENSION pg_stat_statements;

-- 느린 쿼리 조회
SELECT query, calls, mean_exec_time, max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## 🧹 유지보수

### VACUUM
```sql
-- 자동 vacuum 설정 확인
SHOW autovacuum;

-- 수동 vacuum
VACUUM ANALYZE posts;

-- 전체 vacuum
VACUUM ANALYZE;
```

### 통계 업데이트
```sql
-- 통계 정보 업데이트 (쿼리 최적화에 중요)
ANALYZE posts;
```

### 인덱스 재구성
```sql
-- 인덱스 재구성 (조각화 해소)
REINDEX TABLE posts;

-- 전체 인덱스 재구성
REINDEX DATABASE my_ecommerce_db;
```

## 🚨 트러블슈팅

### 연결 실패
```bash
# PostgreSQL 프로세스 확인
docker ps | grep postgres

# 연결 테스트
psql -h ${BASE_IP} -p ${PLATFORM_POSTGRES_PORT} -U ${POSTGRES_USER}

# 로그 확인
docker logs ${PLATFORM_NAME}-postgres
```

### 마이그레이션 실패
```bash
# 마이그레이션 상태 확인
npm run migration:show

# 수동 롤백
npm run migration:revert

# 마이그레이션 테이블 확인
psql -c "SELECT * FROM migrations;"
```

### 데드락
```sql
-- 데드락 발생 프로세스 확인
SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';

-- 프로세스 종료
SELECT pg_terminate_backend(pid);
```

자세한 내용은 `/docs/troubleshooting/database.md` 참조.
