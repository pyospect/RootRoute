# RootRoute - TestFlight 업로드 가이드

## 📱 앱 정보
- **앱 이름**: RootRoute
- **Bundle ID**: com.pyospect.RootRoute
- **Version**: 1.0
- **Build**: 1
- **최소 iOS 버전**: 26.0
- **지원 기기**: iPhone (세로 모드 전용)

---

## ✅ 완료된 기능

### 핵심 기능
1. ✅ 여행 생성/편집/삭제
2. ✅ 날짜별 일정 자동 생성
3. ✅ 장소 검색 (Google Places API)
4. ✅ 장소 추가/편집/삭제/순서 변경
5. ✅ 도보/대중교통 경로 계산
6. ✅ 자동 시간 연쇄 업데이트
7. ✅ 예약 정보 관리
8. ✅ 지도 뷰 (번호 핀 + 점선 경로)
9. ✅ 설정 (하루 시작 시간)
10. ✅ 데이터 영구 저장 (UserDefaults)

### UI/UX
- ✅ Light Mode 고정
- ✅ HIG 준수
- ✅ Accessibility 지원
- ✅ 한글 전용

---

## ⚠️ 업로드 전 필수 작업

### 1. **App Icon 추가** (필수)
현재 App Icon이 비어있습니다.

**추가 방법**:
1. 1024x1024 PNG 이미지 준비 (투명도 없음)
2. Xcode에서 `RootRoute/RootRoute/Assets.xcassets/AppIcon.appiconset` 열기
3. 이미지를 "iOS" 1024x1024 슬롯에 드래그

**또는 임시로**:
- SF Symbols의 `map.fill` 아이콘을 사용한 심플 아이콘 생성
- 또는 무료 아이콘 생성 도구 사용:
  - https://www.appicon.co
  - https://icon.kitchen

### 2. **App Privacy 정보 추가** (선택)
현재 위치 권한 설명이 설정되어 있습니다:
- `NSLocationWhenInUseUsageDescription`: "여행 중 주변 장소를 검색하고 경로를 계산하기 위해 위치 정보가 필요합니다"

**App Store Connect에서 추가 필요**:
- Data Collection: None (현재 위치 데이터를 수집하지 않음)
- Third-party Tracking: No

---

## 🛠️ 아카이브 및 업로드 방법

### 1. Xcode에서 아카이브
```bash
# 터미널에서 (자동화)
cd /Users/pyospect/pyodev/RootRoute
xcodebuild -project RootRoute/RootRoute.xcodeproj \
  -scheme RootRoute \
  -sdk iphoneos \
  -configuration Release \
  archive -archivePath build/RootRoute.xcarchive
```

**또는 Xcode GUI에서**:
1. Xcode 상단 메뉴: `Product` → `Destination` → `Any iOS Device (arm64)`
2. `Product` → `Archive`
3. 아카이브 완료 후 Organizer 창이 자동으로 열림

### 2. App Store Connect 업로드
1. Organizer에서 아카이브 선택
2. `Distribute App` 클릭
3. `App Store Connect` 선택
4. `Upload` 선택
5. 서명 옵션: `Automatically manage signing` 선택
6. 업로드 완료 대기 (5-10분)

### 3. App Store Connect에서 TestFlight 설정
1. https://appstoreconnect.apple.com 로그인
2. `My Apps` → `RootRoute` (없으면 새로 생성)
3. `TestFlight` 탭 클릭
4. 업로드된 빌드가 "Processing" 상태로 표시됨 (5-30분 소요)
5. "Ready to Submit" 상태가 되면 테스트 가능

---

## 📝 알려진 제한사항

1. **Google Maps API 키**
   - 코드에 하드코딩되어 있음
   - 개인 프로젝트이므로 문제없으나, 공개 시 환경 변수로 분리 권장

2. **일본 대중교통**
   - Google Directions API가 일본 대중교통을 지원하지 않음
   - 해결책: 도보 시간 계산 후, 사용자가 수동으로 대중교통 시간 입력 or Google Maps 앱으로 연결

3. **데이터 백업**
   - UserDefaults만 사용하므로 앱 삭제 시 데이터 손실
   - 추후 iCloud 동기화 추가 권장

---

## 🎯 TestFlight 테스트 체크리스트

### 기본 흐름
- [ ] 앱 설치 및 첫 실행
- [ ] 여행 생성
- [ ] 장소 검색 및 추가
- [ ] 경로 계산 (도보/대중교통)
- [ ] 지도 뷰 확인
- [ ] 여행 편집 (이름, 날짜)
- [ ] 여행 삭제
- [ ] 앱 종료 후 재실행 (데이터 유지 확인)

### Edge Cases
- [ ] 장소 없을 때 지도 버튼 비활성화
- [ ] 도보 20분 이상일 때 자동 대중교통 전환
- [ ] 수동으로 도보로 전환 시 유지
- [ ] 시간 연쇄 업데이트
- [ ] 예약 정보 저장

---

## 📧 문의
- 개발자: pyospect
- Bundle ID: com.pyospect.RootRoute

---

## 버전 히스토리
- **1.0 (Build 1)**: 초기 릴리스
  - 여행 계획 핵심 기능
  - 뚜벅이 친화적 경로 계산
  - 지도 시각화

