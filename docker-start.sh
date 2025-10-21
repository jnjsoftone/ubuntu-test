#!/bin/bash

# SSH 설정 적용
echo "Configuring SSH settings..."
echo 'root:'$ROOT_PASSWORD | chpasswd
sed -i 's/^#Port .*/Port '$SSH_PORT'/' /etc/ssh/sshd_config
sed -i 's/^Port .*/Port '$SSH_PORT'/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
service ssh start
echo "SSH service started on port $SSH_PORT"

## cron
### crontab 설정 적용 (파일이 volume으로 마운트됨)
if [ -f "/etc/cron.d/app-crontab" ]; then
    echo "Loading crontab configuration from mounted file..."

    # 마운트된 파일을 임시로 복사하여 수정 (Device or resource busy 오류 방지)
    cp /etc/cron.d/app-crontab /tmp/app-crontab.tmp
    chmod 0644 /tmp/app-crontab.tmp

    # 파일 끝에 빈 줄 추가 (필수)
    sed -i -e '$a\' /tmp/app-crontab.tmp

    # crontab 설치
    echo "Installing crontab from /etc/cron.d/app-crontab"
    crontab /tmp/app-crontab.tmp

    # crontab 설정 확인
    echo "Current crontab configuration:"
    crontab -l

    # cron 서비스 시작
    echo "Starting cron service..."
    service cron start

    # cron 로그 설정 (Docker 환경에서는 stdout으로 출력)
    echo "Setting up cron logging to /exposed/logs/cron.log..."
    mkdir -p /exposed/logs
    touch /exposed/logs/cron.log

    # cron을 foreground로 실행하기 위한 설정
    # Docker에서는 cron 로그가 stdout으로 자동 출력됨

    echo "Cron setup completed!"
else
    echo "No cron jobs to set up. Crontab file not found."
fi


## nodejs
export PATH=/root/.nvm/versions/node/v22.20.0/bin:$PATH
export NODE_PATH=/root/.nvm/versions/node/v22.20.0/lib/node_modules:/root/.n8n/node_modules

## npm install -g
# npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli n8n jna-cli jnu-abc jnu-doc jnu-cloud jnu-web &&

##  n8n start
### bashrc 환경변수 로드 (n8n, nvm 등 모든 환경변수 포함)
if [ -f "/root/.bashrc" ]; then
    echo "Loading environment variables from /root/.bashrc..."
    source /root/.bashrc
fi

### nvm 환경 로드
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# n8n
echo "Starting n8n..."

# n8n config 파일 사전 생성 및 권한 설정 (보안 강화)
if [ -f "/root/.n8n/config" ]; then
    chmod 600 /root/.n8n/config
fi

exec n8n start
