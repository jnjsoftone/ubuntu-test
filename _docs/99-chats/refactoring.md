/var/services/homes/jungsam/dev/dockers/create-ubuntu.sh 를 실행할 때,

/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/.env.sample 에 있는 PLATFORM_PORT_START=${PLATFORM_PORT_START} + 5 를 적용해서
.env 파일의 값을 'PLATFORM_PORT_START' 의 값을 치환할 때 ${PLATFORM_PORT_START} + 5 와 같이 5를 더해서 넣을 수 있나요?

/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/docker-compose.yml 파일에 있는 'PLATFORM_PORT_START' 의 값을 치환할 때 ${PLATFORM_PORT_START} + 5 와 같이 5를 더해서 넣을 수 있나요?

PLATFORM_PORT_START=${PLATFORM_PORT_START} + 5