# RootRoute 🚶‍♂️

뚜벅이를 위한 여행 계획 앱

## 주요 기능

### ✨ 핵심 기능
- 📅 **여행 워크스페이스**: 날짜 지정으로 n일차 자동 생성
- 🗺️ **장소 검색**: Google Places API로 장소 검색 및 추가
- 📍 **Queue 기반 일정**: 드래그 앤 드롭으로 순서 변경 가능
- 🚇 **대중교통 & 도보**: 뚜벅이 친화적 경로 안내 (렌터카 제외)
- ⏰ **시간 충돌 감지**: 순서 변경 시 자동으로 시간 충돌 체크
- 🎫 **예약 관리**: 예약 필요 경로 표시 및 정보 관리

### 🎨 UI/UX 특징
- 라이트 모드 고정 (야외 사용 최적화)
- 세로 모드 전용
- 깨끗하고 직관적인 인터페이스
- 사용자 친화적인 디자인

## 기술 스택

- **언어**: Swift
- **프레임워크**: SwiftUI
- **최소 버전**: iOS 26.0
- **API**: Google Maps, Google Places, Google Directions

## 프로젝트 구조

```
RootRoute/
├── Models/              # 데이터 모델
│   ├── Trip.swift
│   ├── DayPlan.swift
│   ├── PlaceItem.swift
│   ├── Route.swift
│   ├── ReservationInfo.swift
│   └── TimeConflict.swift
├── Views/               # 메인 화면
│   ├── TripListView.swift
│   ├── TripWorkspaceView.swift
│   └── PlaceSearchView.swift
├── ViewModels/          # 비즈니스 로직
│   ├── TripListViewModel.swift
│   ├── TripWorkspaceViewModel.swift
│   └── PlaceSearchViewModel.swift
├── Services/            # API 서비스
│   ├── GooglePlacesService.swift
│   ├── DirectionsService.swift
│   └── LocationManager.swift
├── Components/          # 재사용 UI 컴포넌트
│   ├── PlaceRow.swift
│   ├── RouteCard.swift
│   ├── ReservationInfoSheet.swift
│   ├── TimeConflictBanner.swift
│   └── DayTab.swift
└── Utils/              # 유틸리티
    ├── Constants.swift
    ├── TimeConflictValidator.swift
    └── PolylineDecoder.swift
```

## 설정 방법

### 1. Google Maps API 키 설정

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트 생성
2. 다음 API 활성화:
   - Maps SDK for iOS
   - Places API
   - Directions API
3. API 키 생성
4. `Constants.swift` 파일에서 API 키 교체:

```swift
static let googleMapsAPIKey = "YOUR_API_KEY_HERE"
```

### 2. Xcode 설정

1. 프로젝트를 Xcode에서 엽니다
2. **파일 그룹 정리** (중요!):
   - Models 폴더의 모든 파일을 Xcode 프로젝트에 추가
   - Views, ViewModels, Services, Components, Utils 폴더도 동일하게 추가
   - 그룹 구조가 폴더 구조와 일치하도록 정리

3. **타겟 설정 확인**:
   - General → Deployment Info
   - Minimum Deployments: iOS 26.0
   - Supported Orientations: Portrait만 체크

### 3. 빌드 및 실행

```bash
# 프로젝트 빌드
⌘ + B

# 실행
⌘ + R
```

## 사용 방법

### 여행 만들기
1. 앱 실행 후 "+" 버튼 탭
2. 여행 이름, 시작일, 종료일 입력
3. 생성 버튼 → n일차 자동 생성

### 장소 추가
1. 워크스페이스에서 "+" 버튼
2. 장소 검색
3. 선택하면 Queue에 추가
4. 자동으로 경로 계산

### 경로 관리
- 경로 카드 길게 눌러 컨텍스트 메뉴에서 "예약 필요" 토글
- 예약 필요 경로는 주황색으로 표시
- 카드 탭하여 예약 정보 입력

### 시간 설정
- 각 장소의 도착/출발 시간 설정
- 순서 변경 시 자동으로 충돌 감지
- "조정" 버튼으로 자동 시간 조정

## 주의사항

⚠️ **Google Maps API 무료 한도**
- 월 $200 크레딧 무료
- Places API: 약 28,500 요청
- Directions API: 약 40,000 요청

초기 개발 및 테스트에는 충분하지만, 상용 서비스 시 비용 확인 필요!

## 개발 환경

- Xcode 16.0+
- macOS 15.0+ (Sequoia)
- Swift 6.0+

## 라이선스

개인 프로젝트

---

Made with ❤️ by pyospect

