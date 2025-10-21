
/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs 와 /var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/_docs 에서
- ubuntu platform에 전체에 적용되는 문서들은 /var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs 에 생성하고, 모든 프로젝트에서 공용 지침으로 사용하고,
- 개별 프로젝트에서 지속적으로 업데이트하는 문서들은 /var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/_docs 에 문서 template 들을 생성해두고, 개발 과정에서 지속적으로 업데이트하면서 agile 한 개발을 하려고 해요.
- 영문 문서는 ai(claude code)에게 지침 및 현재 개발 단계의 상황을 소통하기 위해 최대한 핵심 부분만으로 작성하고, 한글 문서는 개발자들을 위해 쉽고 구체적으로 작성했으면 해요.
- 또한 ai에게 필요한 코딩이나 명령어 지침의 경우 CLAUDE.md 및 해당 폴더/파일에 넣어두고, ai가 프롬프팅 없이도 언제나 준수하도록 하고, 개발 단계에서 agile하게 이루어지는 변경들에 대해 각 단계와 코드 변경 사항의 내용을 파악해서 /var/services/homes/jungsam/dev/dockers/_templates/docker/ubuntu-project/_docs 에 있는 각 폴더의 파일(문서)를 업데이트할 수 있도록 문서 생성/변경에 대한 지침도 CLAUDE.md 및 해당 폴더/파일 등에 적시했으면 좋겠어요. 


/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/api 와 /var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/coding-conventions 에 있는 내용들은 중복된 것들도 있는 것 같아요. /var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs 에 있는 폴더 구조를 개발 단계를 고려하고 각 도메인별 ubuntu project에서 공통으로 사용할 지침으로 효율적으로 쓰이도록 리팩토링해주세요.