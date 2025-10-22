/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven 의 내용을 실제 개발에서 claude code를  사용한다고 했을 때, 기획, 모델링, backend(typescript, graphql 등), frontend(nextjs) 개발 단계별로 개발자가 해야 하는 선택.결정 및 claude code에서 제시할 지침, 프롬프트를 구체적으로 알려주세요. 사용자/권한/인증 등에 대한 fullstack 개발을 예로 들어주세요.
postgresql은 원격 서버에 접속하여 사용합니다. 

===

프로젝트 개발시에 사용하는 디렉토리 구조는 /var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project 와 같습니다. 메타데이터 드리븐 방식을 적용하는데, 상용할 코드는 /var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/backend/nodejs 에서 어디에 넣어야 할까요?

===

/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows 에서 특정한 프로젝트의 모델링 전에 생성해야 하는 postgresql (메타)테이블들 목록과 테이블 생성 sql, 테이블 생성 스크립트의 내용을 /var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/backend/nodejs 를 참고하여 /var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/meta-data-driven/workflows 에 문서로 만들어주세요
