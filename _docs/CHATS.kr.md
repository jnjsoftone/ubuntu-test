/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/docs/guidelines/coding-conventions/graphql.md 의 영어 버전과 한글 버전을 2개로 만들어놓는 것은 어떤가요? docs 의 markdown 문서들을 2개 언어 버전으로 관리하면, AI는 영어 버전을 참고하고, 개발자(한국인)은 한글 버전으로 보면 좋을 것 같아요.
[file-name]_kr.md, [file_name]_en.md 와 같이 파일 단위로 관리하는 게 좋을까요? 아니면 docs/en/*, docs/kr/* 와 같이 언어별로 폴더를 별도로 하는 게 좋을까요?

===

● 좋은 질문입니다! 두 가지 접근 방식을 비교해보겠습니다.

  1. 파일 단위 접근 방식 ([name]_kr.md, [name]_en.md)

  docs/guidelines/coding-conventions/
  ├── graphql_en.md
  ├── graphql_kr.md
  ├── typescript_en.md
  ├── typescript_kr.md
  ├── react_en.md
  └── react_kr.md

  장점:
  - 같은 주제의 문서가 물리적으로 가까이 위치
  - 한 문서를 수정할 때 다른 언어 버전을 바로 찾기 쉬움
  - 파일 탐색기에서 정렬 시 관련 문서가 함께 보임

  단점:
  - 파일 수가 2배로 증가
  - 언어별로 전체 문서를 한번에 보기 어려움
  - glob 패턴으로 특정 언어만 선택하기 번거로움 (**/*_en.md)

  2. 폴더 단위 접근 방식 (docs/en/, docs/kr/)

  docs/
  ├── en/
  │   └── guidelines/
  │       └── coding-conventions/
  │           ├── graphql.md
  │           ├── typescript.md
  │           └── react.md
  └── kr/
      └── guidelines/
          └── coding-conventions/
              ├── graphql.md
              ├── typescript.md
              └── react.md

  장점:
  - 언어별로 완전히 분리된 네임스페이스
  - 파일명이 깔끔 (언어 접미사 불필요)
  - 언어별 전체 문서 구조를 한눈에 파악 가능
  - 다국어 웹사이트 구조와 일치 (Docusaurus, VuePress 등)
  - CI/CD에서 언어별 처리 용이
  - 향후 다른 언어 추가 시 확장성 좋음

  단점:
  - 폴더 구조가 중복됨
  - 한 문서의 다른 언어 버전을 찾으려면 경로 이동 필요

  3. 하이브리드 접근 방식 (추천 ⭐)

  docs/
  ├── guidelines/
  │   └── coding-conventions/
  │       ├── graphql.md          # 기본 영어 버전
  │       ├── graphql.kr.md       # 한글 번역
  │       ├── typescript.md
  │       ├── typescript.kr.md
  │       └── README.md           # 언어 가이드

  규칙:
  - 기본 파일(.md)은 영어로 작성 - AI가 주로 참조
  - 한글 버전은 .kr.md 접미사 사용
  - 필요시 .ja.md, .zh.md 등 확장 가능

  장점:
  - 영어가 기본이므로 AI가 자연스럽게 영어 버전 우선 참조
  - 파일명이 직관적이고 간단
  - 한글 버전이 선택적 (모든 문서를 번역하지 않아도 됨)
  - 같은 폴더에서 관리하여 동기화 용이
  - 추가 언어 확장 가능

  단점:
  - 언어별 완전 분리는 아님

  추천: 하이브리드 방식

  제 추천은 하이브리드 방식입니다. 이유는:

  1. AI 친화적: 기본 .md 파일이 영어이므로 AI가 자연스럽게 영어 문서 참조
  2. 개발자 친화적: .kr.md 파일명으로 한글 버전을 명확히 구분
  3. 선택적 번역: 모든 문서를 번역할 필요 없이 중요한 문서만 .kr.md 생성 가능
  4. 단순성: 폴더 구조 중복 없이 깔끔하게 관리
  5. 확장성: 나중에 일본어(.ja.md), 중국어(.zh.md) 등 추가 용이

  현재 상황에 적용하시겠습니까? 다음과 같이 진행하면 됩니다:

  # 현재 한글 파일을 .kr.md로 변경
  mv graphql.md graphql.kr.md

  # 영어 버전을 기본 파일로 생성
  # (영어 버전 작성)

  어떤 방식을 선호하시나요?


===

/var/services/homes/jungsam/dev/dockers/_manager/docs/genspark/40. Meta 데이터관리.md 파일에 있는 meta 데이터를 사용한 개발을 개발 워크플로우를 고려하고, postgresql, graphql, typescript, nextjs를 사용한다는 전제하에 개발시 사용할 범용 워크플로우 및 가이드라인 등을 만들어주세요.

---

 📚 생성된 문서

  1. META-DRIVEN-DEVELOPMENT-WORKFLOW.md

  메타데이터 기반 개발의 전체 워크플로우를 다룹니다:
  - 개요 및 핵심 개념
  - 데이터베이스 스키마 (메타데이터 테이블 구조)
  - 5단계 개발 워크플로우:
    - Phase 1: 프로젝트 초기화
    - Phase 2: 메타데이터 정의
    - Phase 3: 코드 생성
    - Phase 4: 동기화 모드 (자동/수동)
    - Phase 5: 개발 및 커스터마이징
  - 코드 생성 시스템
  - 프로젝트 관리
  - Best Practices

  2. META-DRIVEN-DEVELOPMENT-GUIDELINES.md

  실전 개발 가이드라인:
  - 개발 환경 설정 (Node.js, PostgreSQL, 패키지 설치)
  - 메타데이터 정의 가이드 (명명 규칙, 패턴)
  - 다양한 필드 타입별 메타데이터 정의 예시
  - 코드 생성 및 커스터마이징 전략
  - TypeScript 타입 시스템
  - GraphQL 스키마 설계
  - React 컴포넌트 패턴
  - 테스트 전략
  - 배포 및 CI/CD
  - 트러블슈팅

  3. CODE-GENERATION-TEMPLATES.md

  코드 생성 템플릿 모음:
  - Generator 기본 구조 (BaseGenerator)
  - Database DDL Generator
  - GraphQL Schema Generator
  - TypeScript Types Generator
  - Resolver Generator
  - React Form Generator
  - React Table Generator
  - Migration Generator

  🎯 주요 특징

  1. PostgreSQL + GraphQL + TypeScript + Next.js 스택에 최적화
  2. 단일 진실 공급원(Single Source of Truth) 기반
  3. 자동/수동 동기화 모드 지원
  4. 생성 코드와 커스텀 코드 분리 전략
  5. 완전한 TypeScript 타입 안정성
  6. 실전 예제 및 템플릿 포함

  📍 문서 위치

  /var/services/homes/jungsam/dev/dockers/_manager/docs/
  ├── META-DRIVEN-DEVELOPMENT-WORKFLOW.md      # 워크플로우 가이드
  ├── META-DRIVEN-DEVELOPMENT-GUIDELINES.md    # 개발 가이드라인
  └── CODE-GENERATION-TEMPLATES.md             # 코드 생성 템플릿

  이 문서들을 통해 메타데이터 기반 개발 시스템을 구축하고 활용할 수 있습니다!

===

