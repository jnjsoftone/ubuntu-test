/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/coding-conventions 에 typescript 에 대한 코드 컨벤션을 작성해주세요. 아래의 내용을 포함해주세요.

- arrow function 사용
- export 는 파일 하단에 일괄적으로 처리

===

/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/coding-conventions 에 nextjs 에 대한 코드 컨벤션을 작성해주세요.

nextjs 컨벤션에 아래의 내용도 반영해주세요.

- ui 는 shadcn 과 tailwind 를 사용합니다.
- component는 shadcn을 사용하되 계층적 구조와 variant를 고려하였으면 좋겠네요. shadcn에서 제공하는 기본 컴포넌트는 ui 폴더에, 페이지 레이아웃 섹션인 header, footer, sidebar 등은 layout 폴더에, 기능별 페이지 컴포넌트는 features에 넣습니다. 그런데, 기본 컴포넌트(variant) 여러 개가 모여서 만들어지는 template 을 위한 폴더가 있으면 좋을 것 같네요. 
예를 들어, 테이블 상단에 검색, 버튼들이 포함되어 있는 action-bar 와 같은 경우나, help 버튼과 버튼 클릭시에 슬라이드로 열리는 help 내용이 있는 help-slider 와 같은 것들은 features 에 넣는 것보다는 templates에 넣는 게 좋지 않을까요?


===

nextjs 에서 graphql 을 사용할 때는 graphql query 들을 별도의 폴더에서 관리하는 게 좋은가요? nextjs에서 graphql의 사용에 대한 컨벤션을 추천해주세요.