# PBPR 앱 디자인 스펙

**날짜:** 2026-05-31  
**Phase:** 1 (MVP)  
**플랫폼:** Flutter (iOS / Android)  
**언어:** 한국어 UI

---

## 1. 앱 개요

러닝·크로스핏 사용자가 최대 6가지 운동 항목의 PR(Personal Record) / PB(Personal Best)를 기록하고 공유하는 앱.

---

## 2. 기술 스택

| 영역 | 선택 |
|------|------|
| 상태 관리 | Riverpod (flutter_riverpod) |
| 로컬 DB | sqflite |
| 이미지 캡처 | screenshot (또는 repaint_boundary) |
| 공유 | share_plus |
| 기타 UI | flutter_slidable (카드 삭제), Google Fonts |

---

## 3. 데이터 모델

### 3-1. `exercises` 테이블

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER PK | 자동 증가 |
| name | TEXT | 운동 이름 (예: "스쿼트") |
| type | TEXT | `weight` / `time` / `distance` |
| order_index | INTEGER | 홈 화면 카드 순서 (0-5) |
| created_at | INTEGER | Unix timestamp |

### 3-2. `records` 테이블

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER PK | 자동 증가 |
| exercise_id | INTEGER FK | exercises.id |
| value | REAL | 기준 단위 저장: 무게=kg, 시간=초, 거리=km |
| recorded_at | INTEGER | 날짜 Unix timestamp |
| note | TEXT | 선택적 메모 (nullable, Phase 1 UI에는 미노출) |

**최고 기록 판정:**
- `weight`, `distance`: value 높을수록 PB
- `time`: value 낮을수록 PB

**내부 저장 단위 (불변):**
- 무게: kg (화면 표시 시 lbs 변환)
- 시간: 초 (화면 표시 시 H:MM:SS 또는 MM:SS)
- 거리: km (화면 표시 시 mi 변환)

### 3-3. 단위 설정 (앱 상태)

Riverpod `StateProvider`로 관리, SharedPreferences에 영속화.

| 키 | 값 | 기본값 |
|----|----|--------|
| `weightUnit` | `kg` / `lbs` | `kg` |
| `distanceUnit` | `km` / `mi` | `km` |

변환식:
- `lbs = kg × 2.20462`
- `mi = km × 0.621371`

---

## 4. 화면 구성

### 4-1. 홈 화면 (메인)

```
┌─────────────────────────────────┐
│ PBPR             [KG⇄LBS] [KM⇄MI] │
├─────────────────────────────────┤
│ ┌─ 운동 카드 ─────────────────┐  │
│ │ SQUAT            weight      │  │
│ │ 142.5 kg                     │  │
│ │ +3일              ★ 최고기록 │  │
│ │ [기록 추가] [히스토리]        │  │
│ └──────────────────────────────┘  │
│ (탭 시 1RM 패널 펼쳐짐)           │
│ ┌─ 1RM % 패널 ────────────────┐  │
│ │ ●────────────── 85%         │  │
│ │ 슬라이더 (0~120%)  → 121 kg │  │
│ └──────────────────────────────┘  │
│ ...카드 최대 6개...               │
│                                   │
│        [+ 운동 추가]              │
└─────────────────────────────────┘
```

- 카드 최대 6개. 6개 도달 시 [+ 운동 추가] 버튼 숨김.
- 카드 길게 누르기 → 삭제 확인 다이얼로그 (Phase 1에서는 드래그 순서 변경 미지원).
- 1RM % 패널은 `weight` 타입 카드에만 표시.

### 4-2. 기록 입력 화면

- 운동 이름 표시 (수정 불가)
- 날짜 선택 (기본: 오늘, DatePicker)
- 값 입력:
  - `weight`: 숫자 + 현재 단위 표시 (kg/lbs)
  - `time`: HH:MM:SS 형식 (시간 0이면 MM:SS만 표시)
  - `distance`: 숫자 + 현재 단위 표시 (km/mi)
- [저장] → PB 갱신 여부 판정 → PB면 축하 팝업

### 4-3. 기록 히스토리 화면

- 해당 운동의 기록 날짜 내림차순 리스트
- 각 항목: 날짜, 기록값, PB 표시
- 스와이프 또는 길게 누르기로 삭제

### 4-4. 공유/내보내기 화면

- Clean 스타일 미리보기 + Rough 스타일 미리보기 (탭으로 전환)
- [이미지 저장] → 갤러리 저장
- [공유] → 기기 공유 시트 (카카오톡, 인스타그램 등)
- 이미지 비율: 9:16 (Instagram Stories)

---

## 5. 주요 기능 상세

### 5-1. 1RM % 패널

- 슬라이더 범위: 0% ~ 120%, 1% 단위
- 실시간 계산: `계산값 = 현재 1RM × (슬라이더 % / 100)`
- 현재 1RM = 해당 운동의 최고 기록 value
- 결과는 현재 단위 토글 상태에 맞게 표시

### 5-2. PR 달성 축하 팝업

트리거: 기록 저장 시 새 value가 기존 최고값보다 좋을 때

내용:
- 운동 이름
- 새 기록
- 이전 기록 대비 차이 (`▲ +2.5 kg` 또는 `▼ -00:15`)
- [닫기] [공유하기] 버튼

### 5-3. +N일 표시

`오늘 날짜 - 마지막 기록의 recorded_at` (일 단위)

### 5-4. 내보내기 프레임 스타일

**Clean:**
- 배경: `#1A1A1A`
- 타이포그래피 중심, 여백 넉넉
- PBPR 로고, 운동명, 기록값, 날짜

**Rough:**
- 배경: `#1A1A1A`
- 대형 "PR" 배경 텍스트 (장식)
- `#FF6B35` 오렌지 강조, 날짜 + 갱신 일수 표시

---

## 6. 디자인 시스템

| 항목 | 값 |
|------|----|
| 배경색 | `#1A1A1A` |
| 카드 배경 | `#2C2C2C` |
| 강조색 | `#FF6B35` (오렌지) |
| 텍스트 (기본) | `#FFFFFF` |
| 텍스트 (서브) | `#888888` |
| 폰트 | Google Fonts — Inter 또는 Space Grotesk |
| 느낌 | 모던, 스포티, 다크 & 오렌지 |

---

## 7. 파일 구조 (예상)

```
lib/
  main.dart
  app.dart
  core/
    database/
      database_helper.dart      # sqflite 초기화, 마이그레이션
    models/
      exercise.dart
      record.dart
    utils/
      unit_converter.dart       # kg↔lbs, km↔mi, 초↔HH:MM:SS
  features/
    home/
      home_screen.dart
      exercise_card.dart
      one_rm_panel.dart
      unit_toggle.dart
    record_input/
      record_input_screen.dart
      pr_celebration_dialog.dart
    history/
      history_screen.dart
    export/
      export_screen.dart
      clean_frame.dart
      rough_frame.dart
  providers/
    exercises_provider.dart
    records_provider.dart
    unit_settings_provider.dart
```

---

## 8. MVP 범위 외 (Phase 2 이후)

- 클라우드 동기화
- 운동 기록 그래프/차트
- 알림 (PR 도전 리마인더)
- 다크/라이트 테마 전환 (현재는 다크 고정)
