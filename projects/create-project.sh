#!/bin/bash

# Create new project from ubuntu-project template
# Usage: ./create-project.sh -p <platform-name> -n <project-name> -u <github-user-name> -d "<project-description>" -l <target location> -t <template directory>

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables from .env (go up 3 levels from projects/ to reach docker-platforms/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../.. && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Use DEV_ROOT_PATH (priority) or DOCKER_ROOT_PATH, or fallback to default
if [ -n "$DEV_ROOT_PATH" ]; then
    DOCKER_ROOT_PATH="$DEV_ROOT_PATH/dockers"
elif [ -z "$DOCKER_ROOT_PATH" ]; then
    DOCKER_ROOT_PATH="/var/services/homes/jungsam/dev/dockers"
fi

# Set DEV_ROOT_PATH if not already set
if [ -z "$DEV_ROOT_PATH" ]; then
    DEV_ROOT_PATH="/var/services/homes/jungsam/dev"
fi

# Scripts directory
SCRIPTS_DIR="$DEV_ROOT_PATH/_manager/scripts"
CREATE_DB_SCRIPT="$SCRIPTS_DIR/create-project-db.js"
UPDATE_REPO_SCRIPT="$SCRIPTS_DIR/update-repositories.js"
PORT_ALLOCATOR="$SCRIPTS_DIR/port-allocator.js"

# Manager data directory
MANAGER_DATA_DIR="$DEV_ROOT_PATH/_manager/data"
PLATFORMS_JSON="$MANAGER_DATA_DIR/platforms.json"
PROJECTS_JSON="$MANAGER_DATA_DIR/projects.json"

# Default values
TARGET_LOCATION="./"
TEMPLATE_DIRECTORY="$DOCKER_ROOT_PATH/_templates/docker/ubuntu-project"
PLATFORM_NAME=""
PROJECT_NAME=""
GITHUB_USER=""
PROJECT_DESCRIPTION=""
GIT_ENABLED="true"

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Convert string to snake_case
to_snake_case() {
    echo "$1" | sed 's/-/_/g' | sed 's/\([A-Z]\)/_\1/g' | tr '[:upper:]' '[:lower:]' | sed 's/^_//'
}

# 사용법 출력
show_usage() {
    echo "Usage: $0 -p <platform-name> -n <project-name> [-u <github-user-name>] [-d \"<project-description>\"] [-l <target-location>] [-t <template-directory>]"
    echo ""
    echo "Create a new project from ubuntu-project template"
    echo ""
    echo "Options:"
    echo "  -p  Platform name (required)"
    echo "  -n  Project name (required)"
    echo "  -u  GitHub username (default: current user)"
    echo "  -d  Project description (default: <project-name>)"
    echo "  -l  Target location (default: ./)"
    echo "  -t  Template directory (default: $DOCKER_ROOT_PATH/_templates/ubuntu-project)"
    echo "  -g  Initialize Git repository (true|false, default: true)"
    echo "  -h  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -p ubuntu-sam -n my-ecommerce"
    echo "  $0 -p ubuntu-sam -n blog-platform -u myuser -d \"My Blog Platform\""
}

# Parse command line arguments
while getopts "p:n:u:d:l:t:g:h" opt; do
    case $opt in
        p)
            PLATFORM_NAME="$OPTARG"
            ;;
        n)
            PROJECT_NAME="$OPTARG"
            ;;
        u)
            GITHUB_USER="$OPTARG"
            ;;
        d)
            PROJECT_DESCRIPTION="$OPTARG"
            ;;
        l)
            TARGET_LOCATION="$OPTARG"
            ;;
        t)
            TEMPLATE_DIRECTORY="$OPTARG"
            ;;
        g)
            GIT_ENABLED="$OPTARG"
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            log_error "Invalid option: -$OPTARG"
            show_usage
            exit 1
            ;;
        :)
            log_error "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done

GIT_ENABLED=$(echo "$GIT_ENABLED" | tr "[:upper:]" "[:lower:]")
if [ "$GIT_ENABLED" != "true" ] && [ "$GIT_ENABLED" != "false" ]; then
    log_error "Invalid value for -g. Use true or false."
    exit 1
fi

# Validate required arguments
if [ -z "$PLATFORM_NAME" ]; then
    log_error "Platform name (-p) is required"
    show_usage
    exit 1
fi

if [ -z "$PROJECT_NAME" ]; then
    log_error "Project name (-n) is required"
    show_usage
    exit 1
fi

# Set default values for optional parameters
if [ -z "$GITHUB_USER" ]; then
    GITHUB_USER="$(whoami)"
    log_info "Using current user as GitHub user: $GITHUB_USER"
fi

if [ -z "$PROJECT_DESCRIPTION" ]; then
    PROJECT_DESCRIPTION="$PROJECT_NAME"
fi

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIRECTORY" ]; then
    log_error "Template directory '$TEMPLATE_DIRECTORY' does not exist"
    exit 1
fi

# 프로젝트명 유효성 검사
validate_project_name() {
    local project_name="$1"

    # 프로젝트명 형식 확인 (영문, 숫자, 하이픈만 허용)
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9-]+$ ]]; then
        log_error "프로젝트명은 영문, 숫자, 하이픈(-)만 사용할 수 있습니다."
        exit 1
    fi

    # 절대 경로로 변환
    TARGET_LOCATION=$(cd "$TARGET_LOCATION" && pwd)

    # 프로젝트 디렉토리가 이미 존재하는지 확인
    if [ -d "$TARGET_LOCATION/$project_name" ]; then
        log_error "프로젝트 '$project_name'가 이미 존재합니다: $TARGET_LOCATION/$project_name"
        exit 1
    fi
}

# Load platform environment variables
load_platform_env() {
    local platform_name="$1"
    local platform_env_file="$DOCKER_ROOT_PATH/platforms/$platform_name/.env"

    if [ ! -f "$platform_env_file" ]; then
        log_error "Platform .env file not found: $platform_env_file"
        exit 1
    fi

    log_info "Loading platform environment from: $platform_env_file"
    source "$platform_env_file"

    # Export required variables
    export MYSQL_HOST
    export MYSQL_PORT
    export MYSQL_USER
    export MYSQL_PASSWORD
    export POSTGRES_HOST
    export POSTGRES_PORT
    export POSTGRES_USER
    export POSTGRES_PASSWORD
    export PLATFORM_PORT_START

    log_success "Platform environment loaded"
    log_info "MySQL: ${MYSQL_HOST}:${MYSQL_PORT}"
    log_info "PostgreSQL: ${POSTGRES_HOST}:${POSTGRES_PORT}"
    log_info "Platform port start: ${PLATFORM_PORT_START}"
}

# Create databases using create-project-db.js
create_databases() {
    local platform_name="$1"
    local project_name="$2"

    if [ ! -f "$CREATE_DB_SCRIPT" ]; then
        log_error "Database creation script not found: $CREATE_DB_SCRIPT"
        exit 1
    fi

    # Generate DB name for display
    local project_snake=$(to_snake_case "$project_name")
    PROJECT_DB_NAME="${project_snake}_db"

    echo ""
    log_info "=========================================="
    log_info "📊 DATABASE CREATION"
    log_info "=========================================="
    log_info "Platform: ${BLUE}$platform_name${NC}"
    log_info "Project: ${BLUE}$project_name${NC}"
    log_info "Expected DB Name: ${BLUE}$PROJECT_DB_NAME${NC}"
    log_info "DB Script: $CREATE_DB_SCRIPT"
    echo ""

    # Display platform database connection info
    log_info "📡 Platform Database Connection Info:"
    log_info "  MySQL Host: ${MYSQL_HOST}"
    log_info "  MySQL Port: ${MYSQL_PORT}"
    log_info "  PostgreSQL Host: ${POSTGRES_HOST}"
    log_info "  PostgreSQL Port: ${POSTGRES_PORT}"
    echo ""

    # Create MySQL database
    echo ""
    log_info "=========================================="
    log_info "🔵 STEP 1: Creating MySQL Database"
    log_info "=========================================="
    log_info "Executing: node create-project-db.js $platform_name $project_name mysql"
    echo ""

    MYSQL_RESULT=$(cd "$DEV_ROOT_PATH/_manager" && node "scripts/create-project-db.js" "$platform_name" "$project_name" mysql 2>&1)
    MYSQL_EXIT_CODE=$?

    # Display full output
    echo "$MYSQL_RESULT"
    echo ""

    if [ $MYSQL_EXIT_CODE -eq 0 ]; then
        # Extract database credentials from output
        MYSQL_DB_NAME=$(echo "$MYSQL_RESULT" | grep "DB_NAME=" | cut -d'=' -f2)
        MYSQL_DB_USER=$(echo "$MYSQL_RESULT" | grep "DB_USER=" | cut -d'=' -f2)
        MYSQL_DB_PASSWORD=$(echo "$MYSQL_RESULT" | grep "DB_PASSWORD=" | cut -d'=' -f2)

        log_success "✅ MySQL database created successfully!"
        log_info "📋 MySQL Credentials:"
        log_info "  Database: ${GREEN}$MYSQL_DB_NAME${NC}"
        log_info "  User: ${GREEN}$MYSQL_DB_USER${NC}"
        log_info "  Password: ${GREEN}$MYSQL_DB_PASSWORD${NC}"
    else
        log_error "❌ Failed to create MySQL database (Exit code: $MYSQL_EXIT_CODE)"
        exit 1
    fi

    # Create PostgreSQL database
    echo ""
    log_info "=========================================="
    log_info "🟣 STEP 2: Creating PostgreSQL Database"
    log_info "=========================================="
    log_info "Executing: node create-project-db.js $platform_name $project_name postgresql"
    echo ""

    PG_RESULT=$(cd "$DEV_ROOT_PATH/_manager" && node "scripts/create-project-db.js" "$platform_name" "$project_name" postgresql 2>&1)
    PG_EXIT_CODE=$?

    # Display full output
    echo "$PG_RESULT"
    echo ""

    if [ $PG_EXIT_CODE -eq 0 ]; then
        # Extract database credentials from output
        POSTGRES_DB_NAME=$(echo "$PG_RESULT" | grep "DB_NAME=" | cut -d'=' -f2)
        POSTGRES_DB_USER=$(echo "$PG_RESULT" | grep "DB_USER=" | cut -d'=' -f2)
        POSTGRES_DB_PASSWORD=$(echo "$PG_RESULT" | grep "DB_PASSWORD=" | cut -d'=' -f2)

        log_success "✅ PostgreSQL database created successfully!"
        log_info "📋 PostgreSQL Credentials:"
        log_info "  Database: ${GREEN}$POSTGRES_DB_NAME${NC}"
        log_info "  User: ${GREEN}$POSTGRES_DB_USER${NC}"
        log_info "  Password: ${GREEN}$POSTGRES_DB_PASSWORD${NC}"
    else
        log_error "❌ Failed to create PostgreSQL database (Exit code: $PG_EXIT_CODE)"
        exit 1
    fi

    # Export all variables
    export MYSQL_DB_NAME
    export MYSQL_DB_USER
    export MYSQL_DB_PASSWORD
    export POSTGRES_DB_NAME
    export POSTGRES_DB_USER
    export POSTGRES_DB_PASSWORD
    export PROJECT_DB_NAME

    # Summary
    echo ""
    log_success "=========================================="
    log_success "✅ ALL DATABASES CREATED SUCCESSFULLY"
    log_success "=========================================="
    echo ""
    log_info "📊 Summary:"
    echo ""
    log_info "MySQL Database:"
    log_info "  └─ ${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB_NAME}"
    log_info "     User: $MYSQL_DB_USER"
    echo ""
    log_info "PostgreSQL Database:"
    log_info "  └─ ${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB_NAME}"
    log_info "     User: $POSTGRES_DB_USER"
    echo ""
}

# Get platform SN from platforms.json
get_platform_sn() {
    local platform_name="$1"

    if [ ! -f "$PLATFORMS_JSON" ]; then
        log_error "platforms.json not found: $PLATFORMS_JSON"
        exit 1
    fi

    # Extract platform SN using node
    PLATFORM_SN=$(node -e "
        const fs = require('fs');
        const data = JSON.parse(fs.readFileSync('$PLATFORMS_JSON', 'utf-8'));
        const platform = data.platforms['$platform_name'];
        if (platform && platform.sn !== undefined) {
            console.log(platform.sn);
        } else {
            console.error('Platform not found: $platform_name');
            process.exit(1);
        }
    " 2>&1)

    if [ $? -ne 0 ]; then
        log_error "Failed to get platform SN for: $platform_name"
        exit 1
    fi

    export PLATFORM_SN
    log_info "Platform SN: $PLATFORM_SN"
}

# Calculate port variables using port-allocator
calculate_ports() {
    local platform_name="$1"

    echo ""
    log_info "=========================================="
    log_info "🔌 PORT ALLOCATION"
    log_info "=========================================="

    # Get platform SN
    log_info "📍 Getting Platform SN..."
    get_platform_sn "$platform_name"
    log_success "  Platform SN: ${GREEN}$PLATFORM_SN${NC}"

    # Get next project SN
    if [ ! -f "$PORT_ALLOCATOR" ]; then
        log_error "Port allocator not found: $PORT_ALLOCATOR"
        exit 1
    fi

    log_info "📍 Getting Next Project SN..."
    PROJECT_SN=$(node "$PORT_ALLOCATOR" next-project "$PROJECTS_JSON" "$platform_name" 2>&1 | tr -d $'\r\n')
    if [ -z "$PROJECT_SN" ]; then
        PROJECT_SN=0
    fi
    export PROJECT_SN
    log_success "  Project SN: ${GREEN}$PROJECT_SN${NC}"

    echo ""
    log_info "🧮 Calculating Port Assignments..."
    log_info "  Port Allocator: $PORT_ALLOCATOR"
    log_info "  Formula: BASE_PORT + (Platform_SN × 200) + (Project_SN × 20)"
    echo ""

    # Get project ports from port-allocator
    local port_info=$(node "$PORT_ALLOCATOR" project "$PLATFORM_SN" "$PROJECT_SN")

    if [ $? -ne 0 ]; then
        log_error "Failed to calculate project ports"
        exit 1
    fi

    # Extract base port and individual ports
    BASE_PROJECT_PORT=$(echo "$port_info" | grep -o '"basePort": [0-9]*' | grep -o '[0-9]*')

    # Extract project ports (offsets 0-9)
    BE_NODEJS_PORT=$(echo "$port_info" | grep -A 2 '"beNodejs"' | grep '"port"' | grep -o '[0-9]*')
    BE_PYTHON_PORT=$(echo "$port_info" | grep -A 2 '"bePython"' | grep '"port"' | grep -o '[0-9]*')
    API_GRAPHQL_PORT=$(echo "$port_info" | grep -A 2 '"apiGraphql"' | grep '"port"' | grep -o '[0-9]*')
    API_REST_PORT=$(echo "$port_info" | grep -A 2 '"apiRest"' | grep '"port"' | grep -o '[0-9]*')
    FE_NEXTJS_PORT=$(echo "$port_info" | grep -A 2 '"feNextjs"' | grep '"port"' | grep -o '[0-9]*')
    FE_SVELTEKIT_PORT=$(echo "$port_info" | grep -A 2 '"feSveltekit"' | grep '"port"' | grep -o '[0-9]*')

    # Calculate reserved ports based on base port + offset
    API_RESERVED_PORT=$((BASE_PROJECT_PORT + 4))
    FE_RESERVED_PORT=$((BASE_PROJECT_PORT + 7))
    SYS_RESERVED_PORT=$((BASE_PROJECT_PORT + 8))

    # Export all ports
    export BASE_PROJECT_PORT
    export BE_NODEJS_PORT
    export BE_PYTHON_PORT
    export API_GRAPHQL_PORT
    export API_REST_PORT
    export API_RESERVED_PORT
    export FE_NEXTJS_PORT
    export FE_SVELTEKIT_PORT
    export FE_RESERVED_PORT
    export SYS_RESERVED_PORT

    log_success "✅ Port assignments calculated successfully!"
    echo ""
    log_info "📊 Assigned Ports:"
    log_info "  ┌─ Base Port: ${BLUE}$BASE_PROJECT_PORT${NC}"
    log_info "  ├─ Backend (Node.js): ${BLUE}$BE_NODEJS_PORT${NC}"
    log_info "  ├─ Backend (Python): ${BLUE}$BE_PYTHON_PORT${NC}"
    log_info "  ├─ API (GraphQL): ${BLUE}$API_GRAPHQL_PORT${NC}"
    log_info "  ├─ API (REST): ${BLUE}$API_REST_PORT${NC}"
    log_info "  ├─ Frontend (Next.js): ${BLUE}$FE_NEXTJS_PORT${NC}"
    log_info "  └─ Frontend (SvelteKit): ${BLUE}$FE_SVELTEKIT_PORT${NC}"
    echo ""
}

# 템플릿 복사
copy_template() {
    local project_name="$1"
    local template_path="$2"
    local target_path="$3"

    log_info "Copying project template..."
    log_info "  Template: ${template_path}"
    log_info "  Target: ${target_path}/${project_name}"
    echo ""

    # 대상 디렉토리 생성
    log_info "  Creating project directory..."
    mkdir -p "$target_path/$project_name"
    log_success "  ✓ Directory created"

    # 템플릿 전체 복사
    log_info "  Copying template files..."
    cp -r "$template_path"/* "$target_path/$project_name/"
    log_success "  ✓ Files copied"

    # 숨김 파일들도 복사 (.env, .gitignore 등)
    log_info "  Copying hidden files..."
    cp -r "$template_path"/.[!.]* "$target_path/$project_name/" 2>/dev/null || true
    log_success "  ✓ Hidden files copied"

    echo ""
    log_success "✅ Template copied successfully!"
}

# 변수 치환 실행
substitute_template_variables() {
    local project_name="$1"
    local target_path="$2"

    log_info "Substituting template variables..."
    echo ""

    local project_path="$target_path/$project_name"

    # Function to substitute variables in a single env file
    substitute_env_file() {
        local env_file="$1"
        local file_desc="$2"

        if [ -f "$env_file" ]; then
            log_info "  Processing $file_desc..."

            # Platform database connection variables
            sed -i "s|\${MYSQL_HOST}|$MYSQL_HOST|g" "$env_file"
            sed -i "s|\${MYSQL_PORT}|$MYSQL_PORT|g" "$env_file"
            sed -i "s|\${MYSQL_USER}|$MYSQL_USER|g" "$env_file"
            sed -i "s|\${MYSQL_PASSWORD}|$MYSQL_PASSWORD|g" "$env_file"

            sed -i "s|\${POSTGRES_HOST}|$POSTGRES_HOST|g" "$env_file"
            sed -i "s|\${POSTGRES_PORT}|$POSTGRES_PORT|g" "$env_file"
            sed -i "s|\${POSTGRES_USER}|$POSTGRES_USER|g" "$env_file"
            sed -i "s|\${POSTGRES_PASSWORD}|$POSTGRES_PASSWORD|g" "$env_file"

            # Project database name
            sed -i "s|{PROJECT_DB_NAME}|$PROJECT_DB_NAME|g" "$env_file"

            # Platform and Project SN
            sed -i "s|\${PLATFORM_SN}|$PLATFORM_SN|g" "$env_file"
            sed -i "s|\${PROJECT_SN}|$PROJECT_SN|g" "$env_file"

            # Port variables (new structure - 10 ports total)
            sed -i "s|\${BASE_PROJECT_PORT}|$BASE_PROJECT_PORT|g" "$env_file"
            sed -i "s|\${BE_NODEJS_PORT}|$BE_NODEJS_PORT|g" "$env_file"
            sed -i "s|\${BE_PYTHON_PORT}|$BE_PYTHON_PORT|g" "$env_file"
            sed -i "s|\${API_GRAPHQL_PORT}|$API_GRAPHQL_PORT|g" "$env_file"
            sed -i "s|\${API_REST_PORT}|$API_REST_PORT|g" "$env_file"
            sed -i "s|\${FE_NEXTJS_PORT}|$FE_NEXTJS_PORT|g" "$env_file"
            sed -i "s|\${FE_SVELTEKIT_PORT}|$FE_SVELTEKIT_PORT|g" "$env_file"

            # Port variables (alias - for backward compatibility with ${PORT_1} format)
            sed -i "s|\${PORT_1}|$BE_NODEJS_PORT|g" "$env_file"
            sed -i "s|\${PORT_2}|$BE_PYTHON_PORT|g" "$env_file"
            sed -i "s|\${PORT_3}|$API_GRAPHQL_PORT|g" "$env_file"
            sed -i "s|\${PORT_4}|$API_REST_PORT|g" "$env_file"
            sed -i "s|\${PORT_5}|$API_RESERVED_PORT|g" "$env_file"
            sed -i "s|\${PORT_6}|$FE_NEXTJS_PORT|g" "$env_file"
            sed -i "s|\${PORT_7}|$FE_SVELTEKIT_PORT|g" "$env_file"
            sed -i "s|\${PORT_8}|$FE_RESERVED_PORT|g" "$env_file"
            sed -i "s|\${PORT_9}|$SYS_RESERVED_PORT|g" "$env_file"

            log_success "  ✓ $file_desc configured"
        fi
    }

    # Substitute variables in all .env files
    log_info "  Configuring environment files..."
    substitute_env_file "$project_path/.env" ".env"
    substitute_env_file "$project_path/.env.dev" ".env.dev"
    substitute_env_file "$project_path/.env.prod" ".env.prod"
    echo ""

    # 다른 파일들의 변수 치환
    log_info "  Updating project metadata..."
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s|{projectName}|$project_name|g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s|{projectDescription}|$PROJECT_DESCRIPTION|g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s|{githubUser}|$GITHUB_USER|g" {} \;
    log_success "  ✓ Metadata updated"
    echo ""

    # Substitute {{...}} template variables
    log_info "  Substituting template placeholders..."

    # Substitute {{PROJECT_NAME}} and {{PROJECT_DESCRIPTION}}
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s|{{PROJECT_NAME}}|$project_name|g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" {} \;

    # Substitute port variables in package.json and other files
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s/{{FE_NEXTJS_PORT}}/$FE_NEXTJS_PORT/g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s/{{BE_NODEJS_PORT}}/$BE_NODEJS_PORT/g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s/{{BE_PYTHON_PORT}}/$BE_PYTHON_PORT/g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s/{{API_GRAPHQL_PORT}}/$API_GRAPHQL_PORT/g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s/{{API_REST_PORT}}/$API_REST_PORT/g" {} \;
    find "$project_path" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" \) -exec sed -i "s/{{FE_SVELTEKIT_PORT}}/$FE_SVELTEKIT_PORT/g" {} \;

    log_success "  ✓ Template placeholders substituted"
    echo ""

    # 날짜 변수 치환
    log_info "  Setting current date..."
    local current_date=$(date +%Y-%m-%d)
    find "$project_path" -type f -name "*.md" -exec sed -i "s|{currentDate}|$current_date|g" {} \;
    log_success "  ✓ Date set to $current_date"

    echo ""
    log_success "✅ Template variables substituted successfully!"
}

# .gitignore 파일 생성
create_gitignore() {
    local project_name="$1"
    local target_path="$2"

    log_info "Creating .gitignore file..."

    local project_path="$target_path/$project_name"

    cat > "$project_path/.gitignore" << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build outputs
.next/
dist/
build/

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory
coverage/

# Database
*.sqlite
*.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Project specific
temp/
tmp/
EOF

    log_success "  ✓ .gitignore created"
    echo ""
}

update_repository_records() {
    local mode="$1"
    shift

    if [ ! -f "$UPDATE_REPO_SCRIPT" ]; then
        log_warning "Repositories update script not found: $UPDATE_REPO_SCRIPT"
        return
    fi

    node "$UPDATE_REPO_SCRIPT" "$mode" "$@"
}

update_projects_json() {
    local project_name="$1"
    local platform_name="$2"
    local description="$3"
    local github_user="$4"
    local status="$5"

    local projects_file="$MANAGER_DATA_DIR/projects.json"
    local update_projects_script="$SCRIPTS_DIR/update-projects.js"

    if [ ! -f "$projects_file" ]; then
        log_warning "Projects data file not found: $projects_file"
        return
    fi

    if [ ! -f "$SCRIPTS_DIR/port-allocator.js" ]; then
        log_warning "Port allocator script not found: $SCRIPTS_DIR/port-allocator.js"
        return
    fi

    if [ ! -f "$update_projects_script" ]; then
        log_warning "Projects update script not found: $update_projects_script"
        return
    fi

    local project_sn
    project_sn=$(node "$SCRIPTS_DIR/port-allocator.js" next-project "$projects_file" "$platform_name" 2>/dev/null | tr -d $'\r\n')
    if [ -z "$project_sn" ]; then
        project_sn=0
    fi

    local timestamp
    timestamp=$(date -Iseconds --utc)

    log_info "Updating projects.json..."
    node "$update_projects_script" "$projects_file" "$project_name" "$platform_name" "$description" "$github_user" "$status" "$timestamp" "$project_sn"
}

# Validate project name
validate_project_name "$PROJECT_NAME"

# Load platform environment
load_platform_env "$PLATFORM_NAME"

# Calculate ports
calculate_ports "$PLATFORM_NAME"

# Create databases
create_databases "$PLATFORM_NAME" "$PROJECT_NAME"

echo ""
echo ""
log_info "=========================================="
log_info "🚀 PROJECT CREATION WORKFLOW"
log_info "=========================================="
log_info "Project: ${BLUE}$PROJECT_NAME${NC}"
log_info "Platform: ${BLUE}$PLATFORM_NAME${NC}"
log_info "GitHub user: ${BLUE}$GITHUB_USER${NC}"
log_info "Description: ${BLUE}$PROJECT_DESCRIPTION${NC}"
echo ""
log_info "Target location: $TARGET_LOCATION"
log_info "Template directory: $TEMPLATE_DIRECTORY"
echo ""

# 프로젝트 생성
echo ""
log_info "=========================================="
log_info "📋 STEP 3: Copying Template"
log_info "=========================================="
copy_template "$PROJECT_NAME" "$TEMPLATE_DIRECTORY" "$TARGET_LOCATION"

echo ""
log_info "=========================================="
log_info "🔧 STEP 4: Configuring Project"
log_info "=========================================="
substitute_template_variables "$PROJECT_NAME" "$TARGET_LOCATION"
create_gitignore "$PROJECT_NAME" "$TARGET_LOCATION"

echo ""
log_info "=========================================="
log_info "📦 STEP 5: Installing Dependencies"
log_info "=========================================="

PROJECT_PATH="$TARGET_LOCATION/$PROJECT_NAME"

# Install backend dependencies
if [ -d "$PROJECT_PATH/backend/nodejs" ]; then
    log_info "Installing backend (Node.js) dependencies..."
    cd "$PROJECT_PATH/backend/nodejs" && npm install
    if [ $? -eq 0 ]; then
        log_success "✅ Backend dependencies installed successfully!"
    else
        log_warning "⚠️  Backend dependency installation failed (continuing)"
    fi
    cd - > /dev/null
else
    log_warning "⚠️  Backend directory not found, skipping backend npm install"
fi

echo ""

# Install frontend dependencies
if [ -d "$PROJECT_PATH/frontend/nextjs" ]; then
    log_info "Installing frontend (Next.js) dependencies..."
    cd "$PROJECT_PATH/frontend/nextjs" && npm install
    if [ $? -eq 0 ]; then
        log_success "✅ Frontend dependencies installed successfully!"
    else
        log_warning "⚠️  Frontend dependency installation failed (continuing)"
    fi
    cd - > /dev/null
else
    log_warning "⚠️  Frontend directory not found, skipping frontend npm install"
fi

# Git 저장소 생성 (xgit 사용)
REPO_LOCAL_PATH="platforms/$PLATFORM_NAME/projects/$PROJECT_NAME"

echo ""
log_info "=========================================="
log_info "📦 STEP 6: Git Repository Setup"
log_info "=========================================="

if [ "$GIT_ENABLED" = "true" ]; then
    log_info "Initializing Git repository..."
    log_info "  Repository: ${BLUE}$PROJECT_NAME${NC}"
    log_info "  GitHub User: ${BLUE}$GITHUB_USER${NC}"
    echo ""

    if command -v xgit &> /dev/null; then
        cd "$TARGET_LOCATION/$PROJECT_NAME"
        xgit -e make -u "$GITHUB_USER" -n "$PROJECT_NAME" -d "$PROJECT_DESCRIPTION" || log_warning "Git repository initialization failed (continuing)"
        cd - > /dev/null
        log_success "✅ Git repository created successfully!"
    else
        log_warning "⚠️  xgit command not found. Please initialize Git repository manually."
    fi

    update_repository_records add-github "$PROJECT_NAME" project "$GITHUB_USER" "$PROJECT_DESCRIPTION" "$REPO_LOCAL_PATH"
else
    log_info "⏭️  Skipping Git repository initialization (-g=false)"
    update_repository_records add-nogit "$PROJECT_NAME" project "$PROJECT_DESCRIPTION" "$REPO_LOCAL_PATH"
fi

echo ""
log_info "=========================================="
log_info "📝 STEP 7: Updating Project Registry"
log_info "=========================================="
update_projects_json "$PROJECT_NAME" "$PLATFORM_NAME" "$PROJECT_DESCRIPTION" "$GITHUB_USER" "development"
log_success "✅ Project registered in projects.json"

echo ""
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║  ✅  PROJECT CREATION COMPLETED SUCCESSFULLY! ✅                ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
log_success "Project: ${GREEN}$PROJECT_NAME${NC}"
log_success "Platform: ${GREEN}$PLATFORM_NAME${NC}"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
log_info "📦 ${BLUE}PROJECT DETAILS${NC}"
echo ""
log_info "  Location:"
echo "    ${TARGET_LOCATION}/${PROJECT_NAME}"
echo ""
log_info "  Platform:"
echo "    ${PLATFORM_NAME}"
echo ""
log_info "  Platform SN / Project SN:"
echo "    ${PLATFORM_SN} / ${PROJECT_SN}"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
log_info "🗄️  ${BLUE}DATABASE INFORMATION${NC}"
echo ""
log_info "  MySQL:"
echo "    ├─ Host: ${MYSQL_HOST}"
echo "    ├─ Port: ${MYSQL_PORT}"
echo "    ├─ Database: ${GREEN}${MYSQL_DB_NAME}${NC}"
echo "    ├─ User: ${MYSQL_DB_USER}"
echo "    └─ Password: ${YELLOW}${MYSQL_DB_PASSWORD}${NC}"
echo ""
log_info "  PostgreSQL:"
echo "    ├─ Host: ${POSTGRES_HOST}"
echo "    ├─ Port: ${POSTGRES_PORT}"
echo "    ├─ Database: ${GREEN}${POSTGRES_DB_NAME}${NC}"
echo "    ├─ User: ${POSTGRES_DB_USER}"
echo "    └─ Password: ${YELLOW}${POSTGRES_DB_PASSWORD}${NC}"
echo ""
log_warning "  ⚠️  IMPORTANT: Save these database credentials securely!"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
log_info "🔌 ${BLUE}PORT ASSIGNMENTS${NC}"
echo ""
log_info "  Production Ports:"
echo "    ├─ Base Port: ${BASE_PROJECT_PORT}"
echo "    ├─ Backend (Node.js): ${BE_NODEJS_PORT}"
echo "    ├─ Backend (Python): ${BE_PYTHON_PORT}"
echo "    ├─ API (GraphQL): ${API_GRAPHQL_PORT}"
echo "    ├─ API (REST): ${API_REST_PORT}"
echo "    ├─ Frontend (Next.js): ${FE_NEXTJS_PORT}"
echo "    └─ Frontend (SvelteKit): ${FE_SVELTEKIT_PORT}"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
log_info "📝 ${BLUE}NEXT STEPS${NC}"
echo ""
log_info "  1. Navigate to project directory:"
echo "     ${YELLOW}cd $TARGET_LOCATION/$PROJECT_NAME${NC}"
echo ""
log_info "  2. Review environment variables:"
echo "     ${YELLOW}cat .env${NC}"
echo ""
log_info "  3. Install dependencies:"
echo "     ${YELLOW}npm install${NC}"
echo ""
log_info "  4. Start development:"
echo "     ${YELLOW}npm run dev${NC}"
echo ""
log_info "  5. Access your application:"
echo "     GraphQL API: ${BLUE}http://${MYSQL_HOST}:${API_GRAPHQL_PORT}/graphql${NC}"
echo "     REST API: ${BLUE}http://${MYSQL_HOST}:${API_REST_PORT}${NC}"
echo "     Next.js: ${BLUE}http://${MYSQL_HOST}:${FE_NEXTJS_PORT}${NC}"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
log_success "🎉 Your project is ready to go! Happy coding! 🚀"
echo ""
