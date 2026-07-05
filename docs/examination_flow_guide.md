# Examination Flow — Developer Guide

**Project:** KidCare Pro (Doctor App)  
**Framework:** Flutter + GetX  
**Branch:** `feat/examination-flow`

---

## Overview

The examination flow lets a doctor conduct a full patient session in two steps:

1. **Diagnosis Tab** — Clinical diagnosis (required), doctor notes (optional), and growth measurements (optional).
2. **Prescription Tab** — Medications (optional) and lab/imaging requests (optional).

The doctor must complete step 1 before step 2 becomes usable. After finishing, the app clears the navigation stack and returns to the home screen.

---

## File Structure

```
lib/
├── controllers/
│   └── examination/
│       └── examination_controller.dart   ← all state and business logic
├── core/
│   ├── apis/
│   │   └── examination/
│   │       └── examination_api.dart      ← raw HTTP calls to the backend
│   └── repos/
│       └── examination/
│           └── examination_repo.dart     ← parses raw JSON into typed models
├── models/
│   └── examination/
│       ├── diagnosis_record_model.dart   ← model for the saved diagnosis
│       └── medication_model.dart         ← model for a saved medication
└── views/
    └── examination/
        └── examination_view.dart         ← the full examination screen UI
```

---

## Architecture Pattern

```
View  →  Controller  →  Repo  →  API  →  Backend
```

- **View** never calls the backend. It only reads reactive state from the controller with `Obx()` and calls controller methods on user actions.
- **Controller** holds all state and coordinates the flow. It calls the repo, not the API directly.
- **Repo** receives raw response strings from the API, parses the JSON, and returns typed Dart models.
- **API** makes the actual HTTP requests and returns the raw response body as a `String`.

This separation means the view never needs to know about JSON, and the API never needs to know about models.

### Route Binding (main.dart)

GetX requires dependencies to be registered before the screen opens. This is done in `main.dart` using `BindingsBuilder`:

```dart
GetPage(
  name: '/examination',
  page: () => const ExaminationView(),
  binding: BindingsBuilder(() {
    Get.lazyPut<ExaminationApi>(() => ExaminationApi());
    Get.lazyPut<ExaminationRepo>(() => ExaminationRepo(api: Get.find()));
    Get.lazyPut<ExaminationController>(() => ExaminationController(repo: Get.find()));
  }),
)
```

`lazyPut` means the object is only created when first accessed, not when the route is registered. Each dependency is injected into the next layer via the constructor — the repo receives the API, the controller receives the repo.

---

## Navigation Into the Screen

Two ways to open the examination screen:

**1. With a patient (from the home screen):**
```dart
Get.toNamed('/examination', arguments: patientModel);
```
The controller's `onInit()` checks `Get.arguments`. If a `PatientModel` is found, it is used directly and no API call is made.

**2. Without a patient:**
The controller calls `fetchNextPatient()` automatically. This hits `GET /api/doctor/next-patient` and loads whoever is next in the queue.

Why support both? The home screen already has the patient data — there is no reason to fetch it again from the backend. The fallback exists for cases where the screen is opened directly without passing data.

---

## PatientModel (used in the examination header)

Defined in `lib/models/home/doctor_dashboard_model.dart` (shared with the home feature).

| Flutter field | Type | JSON key read | Backend field | Shown in UI as |
|---|---|---|---|---|
| `id` | `int` | `id` | `child.id` — the child's personal ID | Formatted as `PT-{year}-{0001}` |
| `appointmentId` | `int` | `appointment_id` | `appointment.id` — used in all API calls | Not shown directly |
| `name` | `String` | `name` | `child.first_name + last_name` | Patient name |
| `age` | `int` | `age` | Calculated from `child.birth_date` | "X Yrs" |
| `gender` | `String` | `gender` | `child.gender` | Translated via `.tr` |
| `image` | `String` | `image` | `child.image` | Avatar (network image or person icon fallback) |
| `appointmentTime` | `String` | `appointment_time` | `appointment.time` | Not shown in examination UI |

### Why `id` and `appointmentId` are separate

The backend `nextPatient()` returns two different IDs:

```php
return response()->json([
    'appointment_id' => $appointment->id,        // e.g. 42 — the appointment
    'id'             => $appointment->child->id, // e.g. 9  — the child
    ...
]);
```

- `id` (child ID = 9) is used for display — the `PT-2026-0009` patient code in the header.
- `appointmentId` (appointment ID = 42) is used in every API call URL — `saveDiagnosis`, `saveGrowth`, `saveMedicalRequests`, `completeAppointment` all expect the appointment ID in their path.

The controller always uses `patient.value?.appointmentId`, never `patient.value?.id`, for API calls:

```dart
final appointmentId = patient.value?.appointmentId ?? 0; // correctly = 42
```

The image URL can be a full URL (`https://...`) or a relative path. The view handles both:
```dart
patient.image.startsWith('http')
    ? patient.image
    : '$baseUrl/${patient.image}'
```
Why: the backend returns a relative path like `storage/images/photo.jpg`, so the app prepends `baseUrl` to make it a valid network image URL.

---

## Models

### `DiagnosisRecordModel`
**File:** [lib/models/examination/diagnosis_record_model.dart](lib/models/examination/diagnosis_record_model.dart)

This model represents what the backend returns after saving the diagnosis.

| Flutter field | Type | JSON key | Notes |
|---|---|---|---|
| `id` | `int` | `id` | This becomes `recordId` in the controller — required for adding medications |
| `appointmentId` | `int` | `appointment_id` | The same appointment ID that was sent in the request |
| `diagnosis` | `String` | `diagnosis` | The clinical diagnosis text |
| `doctorNotes` | `String` | `doctor_notes` | Doctor's general notes (may be empty string if none were given) |

The most important field here is `id`. After saving the diagnosis, the backend creates a **medical record** and returns its ID. Medications are linked to this record — not to the appointment directly. This is why `recordId` is stored separately in the controller.

Both `id` and `appointmentId` use safe parsing:
```dart
id: json['id'] is int
    ? json['id']
    : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
```
Why: the backend occasionally returns numbers as strings (`"id": "5"` instead of `"id": 5`). This pattern handles both without crashing.

---

### `MedicationModel`
**File:** [lib/models/examination/medication_model.dart](lib/models/examination/medication_model.dart)

Represents a single medication returned by the backend after it is saved.

| Flutter field | Type | JSON key | What the doctor enters |
|---|---|---|---|
| `id` | `int` | `id` | Auto-generated by backend |
| `recordId` | `int` | `record_id` | Linked to the diagnosis record, not the appointment |
| `name` | `String` | `name` | Medicine name (e.g. "Amoxicillin") |
| `dosage` | `String` | `dosage` | Dose amount (e.g. "500mg") |
| `frequency` | `String` | `frequency` | **Quantity** in the UI — how many times (e.g. "3 times/day") |
| `timing` | `String` | `timing` | **Instructions** in the UI — when to take it (e.g. "After meals") |
| `duration` | `String` | `duration` | How long (e.g. "7 days") |

**Important naming mismatch:** The UI label says "Quantity" and "Instructions", but the backend fields are `frequency` and `timing`. The controller maps them as:
- `frequencyController` → `frequency` → sent as `frequency` to the backend → displayed as "Quantity" label in the UI
- `timingController` → `timing` → sent as `timing` to the backend → displayed as "Instructions" label in the UI

This is not a bug — it was a deliberate choice to use the backend's field names in the code while showing friendlier labels in the UI.

---

## API Layer

**File:** [lib/core/apis/examination/examination_api.dart](lib/core/apis/examination/examination_api.dart)

Every request includes these headers, built by `_getHeaders()`:

```dart
{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Accept-Language': currentLocale,   // 'en' or 'ar'
  'Authorization': 'Bearer $token',
}
```

The token is read from secure storage (not from memory) on every request, so it always reflects the latest stored value.

`Accept-Language` is sent so the backend can return error messages in the correct language matching the app's current locale.

### Endpoints

| Method | HTTP | URL | Body fields sent | Returns |
|---|---|---|---|---|
| `getNextPatient()` | GET | `/api/doctor/next-patient` | none | raw JSON string |
| `saveDiagnosis()` | POST | `/api/doctor/{appointmentId}/diagnosis` | `diagnosis`, `doctor_notes` | raw JSON string |
| `saveGrowth()` | POST | `/api/doctor/{appointmentId}/growth` | `height`, `weight` | raw JSON string |
| `addMedication()` | POST | `/api/doctor/{recordId}/medications` | `name`, `dosage`, `frequency`, `timing`, `duration` | raw JSON string |
| `saveMedicalRequests()` | POST | `/api/doctor/{appointmentId}/medicalRequests` | `required_tests`, `required_imaging` | raw JSON string |
| `completeAppointment()` | GET | `/api/doctors/{appointmentId}/completeAppointment` | none | raw JSON string |

**Why all methods return a raw `String`:** The API layer is kept dumb on purpose. It only sends the request and returns whatever the backend gives back. Parsing is the repo's job.

**Why a 15-second timeout on POST requests but not GET requests:** POST requests write data and are more likely to involve backend processing. A timeout prevents the UI from being stuck loading forever if the backend hangs. The GET requests (`getNextPatient`, `completeAppointment`) have no explicit timeout and rely on the OS default.

**Critical URL difference:** `completeAppointment` uses `/api/doctors/` (plural) while all other endpoints use `/api/doctor/` (singular). This matches the backend routing — if you change it, the request will return a 404.

**Why `addMedication` uses `recordId` not `appointmentId`:** The backend stores medications under a medical record, not directly under an appointment. The record is created when the diagnosis is saved. This is the backend's data model — medications belong to a record, not an appointment.

**Why `saveMedicalRequests` sends comma-separated strings:** The backend expects `required_tests` and `required_imaging` as free-text strings, not arrays. The frontend collects individual items and joins them:
```
"CBC, Blood Sugar"        → required_tests
"Chest X-Ray, MRI Brain"  → required_imaging
```

---

## Repository Layer

**File:** [lib/core/repos/examination/examination_repo.dart](lib/core/repos/examination/examination_repo.dart)

### `_cleanJson()` utility

```dart
String _cleanJson(String response) {
  if (response.contains('{')) return response.substring(response.indexOf('{'));
  if (response.contains('[')) return response.substring(response.indexOf('['));
  return response;
}
```

Why this exists: the backend sometimes returns a BOM (byte order mark) or extra whitespace characters before the JSON starts. `jsonDecode()` fails if the string doesn't start exactly with `{` or `[`. This utility strips whatever comes before the first valid JSON character, making parsing resilient to that issue.

### Method mapping

| Method | Calls API | JSON key parsed | Returns |
|---|---|---|---|
| `getNextPatient()` | `getNextPatient()` | checks `decoded['message']` first | `PatientModel?` (null if no patients) |
| `saveDiagnosis()` | `saveDiagnosis()` | `decoded['record']` | `DiagnosisRecordModel` |
| `saveGrowth()` | `saveGrowth()` | `decoded['message']` | `String` |
| `addMedication()` | `addMedication()` | `decoded['medication']` | `MedicationModel` |
| `saveMedicalRequests()` | `saveMedicalRequests()` | `decoded['message']` | `String` |
| `completeAppointment()` | `completeAppointment()` | `decoded['message']` | `String` |

`getNextPatient()` returns `null` (not an exception) when the backend message is `"No upcoming patients"`. This is intentional — no patients is a valid state, not an error.

---

## Controller

**File:** [lib/controllers/examination/examination_controller.dart](lib/controllers/examination/examination_controller.dart)

`ExaminationController` extends `BaseController`, which provides:
- `showLoading()` / `hideLoading()` — toggles `isLoading` (used to disable buttons and show spinners)
- `showSuccess(message)` — green snackbar at the top
- `showInfo(message)` — grey snackbar at the top (used for validation messages)
- `handleError(e)` — parses the error, shows a red snackbar at the bottom; if the error is 401, clears the token and redirects to login

### State variables

| Variable | Type | Initial value | Purpose |
|---|---|---|---|
| `selectedTab` | `RxInt` | `0` | `0` = Diagnosis tab, `1` = Prescription tab |
| `measurementsExpanded` | `RxBool` | `false` | Controls whether the measurements card is open |
| `patient` | `Rxn<PatientModel>` | `null` | The patient being examined |
| `recordId` | `int?` | `null` | Set after saving diagnosis; gates the prescription step |
| `diagnosisController` | `TextEditingController` | empty | Clinical diagnosis text input |
| `doctorNotesController` | `TextEditingController` | empty | Doctor notes text input |
| `heightController` | `TextEditingController` | empty | Height input (numeric) |
| `weightController` | `TextEditingController` | empty | Weight input (numeric) |
| `medications` | `RxList<MedicationFormData>` | 1 empty entry | List of medication forms |
| `labRequests` | `RxList<LabRequestItem>` | empty | List of added lab/imaging requests |
| `remainingSeconds` | `RxInt` | `930` (15:30) | Countdown timer — display only |

### Helper classes

**`MedicationFormData`**  
Holds 5 `TextEditingController`s for one medication entry. Has two computed getters:
- `isEmpty` → true only if ALL 5 fields are blank → this form is silently skipped on save
- `isComplete` → true only if ALL 5 fields are filled → this form is saved to the backend

Why have both: a completely empty form means the doctor hasn't started filling it yet (safe to ignore). A partially filled form means something was started but not finished (must be flagged as an error).

**`LabRequestItem`**  
A simple data container: a `LabRequestType` enum value (`test` or `imaging`) and a `String` value entered by the doctor.

**`LabRequestType` enum**  
Two values: `test` (lab tests like CBC) and `imaging` (scans like X-Ray). Determines which backend field the value goes into (`required_tests` or `required_imaging`).

### `onInit()`

```dart
void onInit() {
  super.onInit();
  final args = Get.arguments;
  if (args is PatientModel) {
    patient.value = args;
  } else {
    fetchNextPatient();
  }
  _startTimer();
}
```

Checks if a `PatientModel` was passed. If yes, uses it directly. If no, fetches from the backend. The timer starts regardless.

### `formattedPatientId`

```dart
String get formattedPatientId {
  final id = patient.value?.id ?? 0;
  return 'PT-${DateTime.now().year}-${id.toString().padLeft(4, '0')}';
}
```

Formats the patient's appointment ID as a readable patient code, e.g. `PT-2026-0042`. The ID is zero-padded to 4 digits. This is frontend-only formatting — the backend does not know about this format.

### `saveAndContinue()` — Step 1

Called when the doctor taps "Save & Continue" on the Diagnosis tab.

```
1. Diagnosis field empty?
   → showInfo, stay on Diagnosis tab, stop.

2. Only height OR only weight entered (not both)?
   → showInfo, open measurements card, stop.

3. Call repo.saveDiagnosis(appointmentId, diagnosis, doctorNotes?)
   → store returned record.id as recordId

4. Measurements provided (both height and weight)?
   → Call repo.saveGrowth(appointmentId, height, weight)

5. showSuccess("Diagnosis saved successfully")
   → selectedTab = 1  (switch to Prescription tab)
```

Why `doctorNotes` is nullable: the backend accepts it as optional. If the field is empty, `null` is passed instead of an empty string, so the backend doesn't store a blank value.

Why measurements must be both or neither: sending only height without weight (or vice versa) gives the backend incomplete growth data. The validation enforces that they are always stored as a pair.

### `saveAndFinish()` — Step 2

Called when the doctor taps "Save & Finish Examination" on the Prescription tab.

```
1. recordId is null? (diagnosis was never saved)
   → showInfo, switch back to Diagnosis tab, stop.

2. Any medication form is partially filled?
   → showInfo, stop.

3. For each COMPLETE medication form:
   → Call repo.addMedication(recordId, name, dosage, frequency, timing, duration)

4. Any lab requests exist?
   → Join all 'test' values with ", "
   → Join all 'imaging' values with ", "
   → Call repo.saveMedicalRequests(appointmentId, requiredTests?, requiredImaging?)

5. Call repo.completeAppointment(appointmentId)
   → showSuccess(returned message)
   → Get.offAllNamed('/doctor_home')
```

Why medications are sent one by one (not as a batch): the backend endpoint `/medications` accepts a single medication per request. There is no bulk endpoint. Each `addMedication` call is awaited before the next one starts — sequential, not parallel.

Why `Get.offAllNamed` (not `Get.back`): after completing an examination, the doctor should not be able to press back and return to the examination screen. `offAllNamed` clears the entire navigation stack and starts fresh at the home screen.

Why `saveMedicalRequests` is only called if at least one request exists: sending an empty body to the backend is unnecessary. If no lab requests were added, the call is skipped entirely.

### Timer

```dart
final remainingSeconds = (15 * 60 + 30).obs; // 930 seconds = 15:30

void _startTimer() {
  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (remainingSeconds.value > 0) remainingSeconds.value--;
    else _timer?.cancel();
  });
}

String get formattedTime {
  // formats as HH:MM:SS
}
```

The timer starts at 15 minutes 30 seconds and counts down. It is display-only — it does not block saving or prevent any action when it reaches zero. It is cancelled in `onClose()` to avoid memory leaks.

### `onClose()` — cleanup

Cancels the timer and disposes every `TextEditingController` — including all controllers inside `MedicationFormData` entries. Flutter requires controllers to be disposed when no longer needed to free memory.

---

## UI Layer

**File:** [lib/views/examination/examination_view.dart](lib/views/examination/examination_view.dart)

`ExaminationView` extends `GetView<ExaminationController>`, which gives it automatic access to the controller via `controller` without needing `Get.find()` manually.

### Full screen layout

```
AppBar ("Patient Examination")
  - title centered
  - more_vert icon button (no action yet — placeholder)
──────────────────────────────────────
Patient Header
  [CircleAvatar]  [Name]              [HH:MM:SS ●]
                  [Age • Gender]
                  [PT-YYYY-XXXX]
──────────────────────────────────────
Tab Bar (custom — not Flutter's TabBar)
  [ Prescription ]  [ Diagnosis ]
  selected tab: highlighted with primary color background, white text
  unselected tab: transparent background, hint color text
──────────────────────────────────────
Tab Content (scrollable, Obx-driven)

  DIAGNOSIS TAB (selectedTab == 0):
  ┌─────────────────────────────────┐
  │ ✎ Clinical Diagnosis            │
  │   [multiline field, 5 lines,    │
  │    max 500 chars]               │
  └─────────────────────────────────┘
  ┌─────────────────────────────────┐
  │ ☰ General Doctor Notes          │
  │   [multiline field, 4 lines,    │
  │    max 300 chars]               │
  └─────────────────────────────────┘
  ┌─────────────────────────────────┐
  │ ↔ Measurements (Optional)   ▼  │  ← tap to expand
  │   [Height field] | [Weight field]│  ← visible only when expanded
  └─────────────────────────────────┘

  PRESCRIPTION TAB (selectedTab == 1):
  ┌─────────────────────────────────┐
  │ 💊 Medications Prescription + Add│
  │   [Medicine Name field]         │
  │   [Dosage field]                │
  │   [Instructions field]          │
  │   [Quantity field] | [Duration] │
  │   ─────────────────────────────│  ← divider between medications
  │   [+ Add Another Medication]    │
  └─────────────────────────────────┘
  ┌─────────────────────────────────┐
  │ 🔬 Lab & Imaging Requests  + Add│
  │   [🔬 CBC                    ✕]│
  │   [🖼 Chest X-Ray            ✕]│
  │   (empty state: "No requests")  │
  └─────────────────────────────────┘
──────────────────────────────────────
Bottom Button
  Diagnosis tab  → "Save & Continue"     (primary color)
  Prescription   → "Save & Finish Exam"  (green)
```

### Field details — Diagnosis Tab

| UI label | Widget | Controller field | Backend key | Constraints |
|---|---|---|---|---|
| Clinical Diagnosis | `TextFormField` multiline | `diagnosisController` | `diagnosis` | 5 lines, max 500 chars, required |
| General Doctor Notes | `TextFormField` multiline | `doctorNotesController` | `doctor_notes` | 4 lines, max 300 chars, optional |
| Height | `TextFormField` numeric | `heightController` | `height` | decimal keyboard, optional but paired with weight |
| Weight | `TextFormField` numeric | `weightController` | `weight` | decimal keyboard, optional but paired with height |

### Field details — Prescription Tab (per medication)

| UI label | Controller field inside `MedicationFormData` | Backend key | Notes |
|---|---|---|---|
| Medicine Name | `nameController` | `name` | Free text |
| Dosage | `dosageController` | `dosage` | Free text (e.g. "500mg") |
| Instructions | `timingController` | `timing` | Free text (e.g. "After meals") |
| Quantity | `frequencyController` | `frequency` | Free text (e.g. "3 times/day") |
| Duration | `durationController` | `duration` | Free text (e.g. "7 days") |

The delete (✕) button only appears when there are 2 or more medication entries. The first entry cannot be deleted — only cleared.

### `_AddLabRequestDialog`

A private `StatefulWidget` inside the view file. It is opened via `Get.dialog()` when the doctor taps "Add Request".

| Element | Detail |
|---|---|
| Type selection | Two chips: "Test" (biotech icon) and "Imaging" (image icon). Tapping highlights the chip with the primary color. Default: Test. |
| Request Value field | Auto-focused text input. |
| Cancel button | Closes the dialog, nothing is added. |
| Add button | Calls `widget.onAdd(type, value)` → `controller.addLabRequest()` → closes dialog. Empty value is blocked (button does nothing). |

Why a dialog instead of an inline form: the number of lab requests is unbounded and each one only needs a type + a text value. A dialog keeps the main screen clean and allows a focused input experience.

### Bottom button behavior

The bottom button is wrapped in `Obx()` and re-renders on every tab switch:
- Diagnosis tab → `CustomButton` (shared widget, primary color) calling `saveAndContinue()`
- Prescription tab → raw `ElevatedButton` (green, `Colors.green.shade600`) calling `saveAndFinish()`

Why a raw `ElevatedButton` for the prescription tab: the shared `CustomButton` uses the app's primary color and there is no color parameter on it. Rather than modifying a shared widget just for this one screen, a standalone button was used. It shows a `CircularProgressIndicator` while `isLoading` is true and is disabled during that time.

---

## Full Examination Sequence (Data Flow)

```
Doctor opens /examination
          │
          ▼
    onInit()
    ├── Get.arguments is PatientModel?
    │   ├── YES → patient.value = args (no API call)
    │   └── NO  → fetchNextPatient()
    │               GET /api/doctor/next-patient
    │               Repo: null if "No upcoming patients"
    │                     PatientModel otherwise
    └── _startTimer() (15:30 countdown starts)
          │
          ▼
    Diagnosis Tab shown
    Doctor fills: diagnosis (required), notes (optional)
    Doctor optionally expands Measurements → fills height + weight
          │
          ▼
    "Save & Continue" tapped
    ├── validation passes?
    │   ├── NO → show info message, stop
    │   └── YES →
    │       POST /api/doctor/{appointmentId}/diagnosis
    │         body: { diagnosis, doctor_notes }
    │         response: { record: { id, appointment_id, diagnosis, doctor_notes } }
    │         → recordId = record.id  ← stored in controller
    │
    │       (if height + weight provided)
    │       POST /api/doctor/{appointmentId}/growth
    │         body: { height, weight }
    │
    │       showSuccess → selectedTab = 1
          │
          ▼
    Prescription Tab shown
    Doctor adds medications (optional)
    Doctor adds lab/imaging requests (optional)
          │
          ▼
    "Save & Finish Examination" tapped
    ├── recordId == null? → show info, switch to Diagnosis tab, stop
    ├── any partial medication? → show info, stop
    └── proceed:
        for each complete medication:
          POST /api/doctor/{recordId}/medications
            body: { name, dosage, frequency, timing, duration }
            response: { medication: { id, record_id, name, ... } }

        (if lab requests exist)
        POST /api/doctor/{appointmentId}/medicalRequests
          body: {
            required_tests: "CBC, Blood Sugar",      ← comma-joined test values
            required_imaging: "Chest X-Ray"          ← comma-joined imaging values
          }

        GET /api/doctors/{appointmentId}/completeAppointment
          response: { message: "..." }

        showSuccess(message)
        Get.offAllNamed('/doctor_home')  ← back stack cleared
```

---

## Validation Rules

| Trigger | Condition | What happens |
|---|---|---|
| "Save & Continue" | Diagnosis field is empty | Info snackbar, stays on Diagnosis tab |
| "Save & Continue" | Only height OR only weight entered | Info snackbar, measurements card auto-expanded |
| "Save & Finish" | `recordId` is null (diagnosis not yet saved) | Info snackbar, switches back to Diagnosis tab |
| "Save & Finish" | A medication form is partially filled | Info snackbar, does not proceed |
| "Save & Finish" | A medication form is completely empty | Silently ignored, not sent to backend |
| "Add Request" dialog | Request value field is empty | Add button does nothing |
| `addLabRequest()` | Value is empty or whitespace | Returns early, nothing added to the list |

---

## Localization

All UI strings use `.tr` and are defined in both `en_US` and `ar_SY` in [lib/core/localization/app_translations.dart](lib/core/localization/app_translations.dart).

The `Accept-Language` header sent with every API request matches the current app locale (`en` or `ar`), so backend error messages also come back in the correct language.

Examination-related keys:

| Key | English | Arabic |
|---|---|---|
| `Patient Examination` | Patient Examination | فحص المريض |
| `Diagnosis` | Diagnosis | التشخيص |
| `Prescription` | Prescription | الوصفة |
| `Clinical Diagnosis` | Clinical Diagnosis | التشخيص السريري |
| `General Doctor Notes` | General Doctor Notes | ملاحظات الطبيب |
| `Measurements` | Measurements | القياسات |
| `Optional` | Optional | اختياري |
| `Height` | Height | الطول |
| `Weight` | Weight | الوزن |
| `Medications Prescription` | Medications Prescription | وصفة الأدوية |
| `Add Medication` | Add Medication | إضافة دواء |
| `Add Another Medication` | Add Another Medication | إضافة دواء آخر |
| `Medicine Name` | Medicine Name | اسم الدواء |
| `Dosage` | Dosage | الجرعة |
| `Instructions` | Instructions | التعليمات |
| `Quantity` | Quantity | الكمية |
| `Duration` | Duration | المدة |
| `Lab & Imaging Requests` | Lab & Imaging Requests | طلبات التحاليل والأشعة |
| `Add Request` | Add Request | إضافة طلب |
| `No requests added` | No requests added | لم تتم إضافة طلبات |
| `Test` | Test | تحليل |
| `Imaging` | Imaging | أشعة |
| `Request Value` | Request Value | قيمة الطلب |
| `Save & Continue` | Save & Continue | حفظ ومتابعة |
| `Save & Finish Examination` | Save & Finish Examination | حفظ وإنهاء المعاينة |
| `Diagnosis saved successfully` | Diagnosis saved successfully | تم حفظ التشخيص بنجاح |
| `Please enter the diagnosis` | Please enter the diagnosis | يرجى إدخال التشخيص |
| `Please enter both height and weight` | Please enter both height and weight | يرجى إدخال الطول والوزن معاً |
| `Please save the diagnosis first` | Please save the diagnosis first | يرجى حفظ التشخيص أولاً |
| `Please complete all medication fields` | Please complete all medication fields | يرجى إكمال جميع حقول الدواء |

---

# Wallet Screen — Developer Guide

## Overview

The Wallet screen gives the doctor a financial summary: total monthly income, total paid visits, a day-by-day revenue chart for the current month, and a list of recent transactions.

---

## File Structure

```
lib/
├── controllers/
│   └── revenue/
│       └── revenue_controller.dart   ← state and data fetching
├── core/
│   ├── apis/
│   │   └── revenue/
│   │       └── revenue_api.dart      ← HTTP placeholders (not yet wired)
│   └── repos/
│       └── revenue/
│           └── revenue_repo.dart     ← mock data; swap bodies for real API calls
├── models/
│   └── revenue/
│       └── transaction_model.dart    ← model for a single transaction row
└── views/
    └── revenue/
        └── revenue_view.dart         ← full Wallet screen UI + custom chart painter
```

---

## Architecture Pattern

Same layered architecture as the examination flow:

```
View  →  Controller  →  Repo  →  API  →  Backend
```

The repo currently returns **mock data** directly. Each method body has a commented-out `await api.*()` call that shows where the real HTTP call goes. Swapping mock for real requires only uncommenting those lines and implementing the API class — nothing else changes.

### Route Binding (main.dart)

```dart
GetPage(
  name: '/revenue',
  page: () => const RevenueView(),
  binding: BindingsBuilder(() {
    Get.lazyPut<RevenueApi>(() => RevenueApi());
    Get.lazyPut<RevenueRepo>(() => RevenueRepo(api: Get.find()));
    Get.lazyPut<RevenueController>(() => RevenueController(repo: Get.find()));
  }),
)
```

---

## Model

### `TransactionModel`
**File:** [lib/models/revenue/transaction_model.dart](lib/models/revenue/transaction_model.dart)

| Flutter field | Type | JSON key | Notes |
|---|---|---|---|
| `id` | `int` | `id` | Row identifier |
| `patientName` | `String` | `patient_name` | Displayed in the transaction row |
| `date` | `String` | `date` | Pre-formatted by the backend (e.g. "12 مايو 2024") |
| `amount` | `double` | `amount` | Parsed with `double.tryParse` — handles string or number from backend |
| `paymentMethod` | `String` | `payment_method` | Shown as a badge (e.g. "stripe") |

`amount` uses `double.tryParse(json['amount']?.toString() ?? '0')` for the same reason as the examination models — the backend may return it as a string.

---

## API Layer

**File:** [lib/core/apis/revenue/revenue_api.dart](lib/core/apis/revenue/revenue_api.dart)

Currently all stubs — no HTTP calls are wired yet. Planned endpoints:

| Method | HTTP | URL |
|---|---|---|
| `getMonthlyRevenue()` | GET | `/api/doctor/revenue/monthly` |
| `getTotalPaidVisits()` | GET | `/api/doctor/revenue/visits` |
| `getRevenueChartData()` | GET | `/api/doctor/revenue/chart` |
| `getTransactions()` | GET | `/api/doctor/revenue/transactions` |

All methods return `String` (raw response body), following the same contract as the examination API.

---

## Repository Layer

**File:** [lib/core/repos/revenue/revenue_repo.dart](lib/core/repos/revenue/revenue_repo.dart)

| Method | Returns | Mock value |
|---|---|---|
| `getMonthlyRevenue()` | `double` | `15600` |
| `getTotalPaidVisits()` | `int` | `156` |
| `getRevenueChartData()` | `List<double>` | 29 daily values (1 500 → 15 600, trending upward) |
| `getTransactions()` | `List<TransactionModel>` | 5 hardcoded rows |

The chart data has exactly **29 values** — one per day of the month. Each value is the cumulative or daily revenue for that day; the series trends upward and peaks at the monthly total shown in the header card.

---

## Controller

**File:** [lib/controllers/revenue/revenue_controller.dart](lib/controllers/revenue/revenue_controller.dart)

Extends `BaseController` (same as `ExaminationController`).

### State variables

| Variable | Type | Purpose |
|---|---|---|
| `monthlyRevenue` | `RxDouble` | Shown in the blue income card |
| `totalPaidVisits` | `RxInt` | Shown in the paid-visits card |
| `chartData` | `RxList<double>` | Drives the custom line chart painter |
| `transactions` | `RxList<TransactionModel>` | Drives the transactions list |

### `fetchAllRevenueData()`

All four data sources are fetched in parallel using `Future.wait`. Each call is wrapped in a private `_run()` helper that swallows individual errors with a `debugPrint`, so a single failing endpoint does not block the others from loading.

```dart
await Future.wait([
  _run(() async => monthlyRevenue.value = await repo.getMonthlyRevenue()),
  _run(() async => totalPaidVisits.value = await repo.getTotalPaidVisits()),
  _run(() async => chartData.assignAll(await repo.getRevenueChartData())),
  _run(() async => transactions.assignAll(await repo.getTransactions())),
]);
```

`showLoading()` / `hideLoading()` wrap the whole block, so the spinner covers all four requests.

---

## UI Layer

**File:** [lib/views/revenue/revenue_view.dart](lib/views/revenue/revenue_view.dart)

### Screen layout

```
AppBar ("Wallet")
  - white background (colorScheme.surface)
  - back chevron + more_vert icon (colorScheme.onSurface — theme-aware, no hardcoded colors)
──────────────────────────────────────
[Blue income card]
  Total Monthly Income label
  15,600 SAR (large bold)
  Compact sparkline (white line, no dots, no grid)

[White paid-visits card]
  Total Paid Visits label
  156 Visit

[White chart card]
  "Revenue Overview" title
  Line chart (180 px tall):
    Y-axis labels: SAR unit + 5 value ticks (0 K → axisMax)
    Chart area: grid lines, filled area under line, dots at each point,
                emphasized last dot, tooltip bubble at peak
    X-axis labels: day markers at days 1, 8, 15, 22, 29 (pinned to edges)

[White transactions card]
  "Recent Transactions" title
  Transaction rows (divider between each):
    [payment badge] [patient name + date]  [amount SAR]
  "View All Transactions" link (primary color)
──────────────────────────────────────
Pull-to-refresh → re-calls fetchAllRevenueData()
```

### AppBar theming

The AppBar uses `colorScheme.surface` for its background (resolves to white in light theme, dark surface in dark theme) and `colorScheme.onSurface` for all icons and the title. No `Colors.white` or `Colors.black` hardcoded values anywhere in the AppBar.

### Card decoration

All content cards share `_cardDecoration()`:
- `color: context.theme.cardColor` — theme-aware card background
- `borderRadius: 18`
- `boxShadow` using `primaryColor.withValues(alpha: 0.06)` — a very subtle tinted shadow

### Number formatting

`_formatThousands(double)` converts `15600` → `"15,600"` by inserting commas every 3 digits. Used in the income card, chart tooltip, and transaction amounts.

`_niceCeil(double)` rounds a value up to a clean chart ceiling (e.g. `15600` → `20000`) so Y-axis ticks read as round numbers like `5K / 10K / 15K / 20K`.

---

## Custom Chart Painter (`_LineChartPainter`)

**File:** [lib/views/revenue/revenue_view.dart](lib/views/revenue/revenue_view.dart) (private class at bottom of file)

A `CustomPainter` used in two modes:

| Mode | Where used | `showDots` | `showGrid` | `axisMax` | `fillOpacity` |
|---|---|---|---|---|---|
| Sparkline | Blue income card (90×50) | `false` | `false` | `null` (self-normalizes) | `0.18` |
| Full chart | Chart card (full width × 180) | `true` | `true` | `_niceCeil(dataMax)` | `0.08` |

### Key implementation details

**`size: Size.infinite` on the full chart's `CustomPaint`**
The `CustomPaint` sits inside `Expanded` inside a `Column`. Without `size: Size.infinite`, `CustomPaint` reports zero width to the painter, making `xStep = 0` and collapsing all 29 data points onto the same X coordinate (appearing as a vertical line). `size: Size.infinite` tells Flutter to expand the canvas to fill the available constraints.

**Y normalization**
- Full chart: `yMin = 0`, `yMax = axisMax` (the nice ceiling). This matches the Y-axis labels exactly.
- Sparkline: `yMin = dataMin`, `yMax = dataMax` (self-computes from data). Used for the compact in-card view where axis labels are not shown.

**X spacing**
`xStep = size.width / (data.length - 1)`. Point `i` is drawn at `x = i * xStep`, so the first point sits at the left edge and the last at the right edge.

**Tooltip bubble**
Drawn above the last data point (the peak). Clamped to stay within canvas bounds. Only rendered when both `tooltip` and `tooltipBg` are non-null (full chart mode only).

**Dots**
Small hollow circles (white fill + colored ring) at every point. The last point gets an emphasized solid dot with a white center. Only rendered when `showDots = true`.

---

## Data Flow

```
RevenueView opens (/revenue)
        │
        ▼
  RevenueController.onInit()
  └── fetchAllRevenueData()
        ├── showLoading()
        ├── Future.wait([
        │     getMonthlyRevenue()  → monthlyRevenue
        │     getTotalPaidVisits() → totalPaidVisits
        │     getRevenueChartData() → chartData (29 values)
        │     getTransactions()    → transactions (list)
        │   ])
        └── hideLoading()
        │
        ▼
  Obx() re-renders all cards with live data
  Pull-to-refresh → fetchAllRevenueData() again
```

---

## Localization Keys (Wallet Screen)

| Key | English | Arabic |
|---|---|---|
| `Wallet` | Wallet | المحفظة |
| `Total Monthly Income` | Total Monthly Income | إجمالي الدخل الشهري |
| `SAR` | SAR | ر.س |
| `Total Paid Visits` | Total Paid Visits | إجمالي الزيارات المدفوعة |
| `Visit` | Visit | زيارة |
| `Revenue Overview` | Revenue Overview | نظرة عامة على الإيرادات |
| `Recent Transactions` | Recent Transactions | المعاملات الأخيرة |
| `View All Transactions` | View All Transactions | عرض جميع المعاملات |
| `No transactions yet` | No transactions yet | لا توجد معاملات بعد |
| `No data` | No data | لا توجد بيانات |
| `May` | May | مايو |
