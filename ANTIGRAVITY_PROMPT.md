# ⚡ ANTIGRAVITY PROMPT — Custom Phone Dialer App (Android)
# Motorola Edge 50 Neo · No Root · Jetpack Compose · Full Featured

---

You are a senior Android engineer and UI/UX architect with 12+ years of experience building system-level Android applications. You have deep expertise in:
- Android Telecom Framework (TelecomManager, InCallService, ConnectionService)
- Jetpack Compose (Material 3, animations, custom layouts)
- Android system permissions and privilege escalation without root
- ContactsContract, CallLog, MediaRecorder APIs
- Foreground services, BroadcastReceivers, WorkManager
- Clean Architecture (MVVM + Repository + Use Cases)
- Kotlin Coroutines + Flow + StateFlow

---

## 🎯 PROJECT MISSION

Build a COMPLETE, PRODUCTION-GRADE, INSTALLABLE Phone Dialer Android app named **"Phone"** for the **Motorola Edge 50 Neo** (Android 14, no root). The app must replace the default dialer completely, handle all call states natively, and feel INDISTINGUISHABLE from a first-party system app.

This is NOT a demo. This is NOT a prototype. Every feature must WORK.

---

## 📐 TECHNICAL STACK

```
Language         : Kotlin 1.9+
UI Framework     : Jetpack Compose (Material 3)
Architecture     : MVVM + Clean Architecture
DI               : Hilt
Async            : Kotlin Coroutines + Flow
Navigation       : Compose Navigation
Database         : Room (for recordings metadata, blocked numbers)
Build            : Gradle (Kotlin DSL)
Min SDK          : 26 (Android 8)
Target SDK       : 34 (Android 14)
Compile SDK      : 34
```

---

## 🏗 PROJECT STRUCTURE

```
com.phone.dialer/
├── MainActivity.kt                    ← Single activity, Compose host
├── PhoneApplication.kt                ← Hilt app class
│
├── telecom/
│   ├── PhoneCallService.kt            ← InCallService implementation
│   ├── PhoneConnectionService.kt      ← ConnectionService implementation
│   ├── CallReceiver.kt                ← BroadcastReceiver for call states
│   └── CallStateManager.kt            ← Singleton call state tracker
│
├── ui/
│   ├── theme/
│   │   ├── Theme.kt                   ← Dark Material 3 theme
│   │   ├── Color.kt                   ← Full color palette
│   │   └── Type.kt                    ← Typography
│   │
│   ├── screens/
│   │   ├── SplashScreen.kt
│   │   ├── DialerScreen.kt            ← Main keypad screen
│   │   ├── RecentsScreen.kt           ← Call history
│   │   ├── ContactsScreen.kt          ← Contact list
│   │   ├── ContactDetailScreen.kt
│   │   ├── AddContactScreen.kt
│   │   ├── IncomingCallScreen.kt      ← Full-screen incoming UI
│   │   ├── ActiveCallScreen.kt        ← In-call controls
│   │   ├── RecordingsScreen.kt
│   │   └── SettingsScreen.kt
│   │
│   ├── components/
│   │   ├── DialKey.kt                 ← Individual key composable
│   │   ├── ContactAvatar.kt
│   │   ├── CallLogItem.kt
│   │   ├── FavoritesRow.kt
│   │   ├── SnackbarWithUndo.kt
│   │   └── BottomNavBar.kt
│   │
│   └── navigation/
│       └── NavGraph.kt
│
├── data/
│   ├── contacts/
│   │   ├── ContactRepository.kt
│   │   └── ContactRepositoryImpl.kt
│   ├── calllog/
│   │   ├── CallLogRepository.kt
│   │   └── CallLogRepositoryImpl.kt
│   ├── recordings/
│   │   ├── RecordingRepository.kt
│   │   └── RecordingRepositoryImpl.kt
│   └── db/
│       ├── AppDatabase.kt
│       ├── RecordingDao.kt
│       └── BlockedNumberDao.kt
│
├── domain/
│   ├── model/
│   │   ├── Contact.kt
│   │   ├── CallLogEntry.kt
│   │   └── Recording.kt
│   └── usecase/
│       ├── GetContactsUseCase.kt
│       ├── GetCallLogsUseCase.kt
│       ├── SaveContactUseCase.kt
│       └── DeleteCallLogUseCase.kt
│
└── viewmodel/
    ├── DialerViewModel.kt
    ├── RecentsViewModel.kt
    ├── ContactsViewModel.kt
    └── CallViewModel.kt
```

---

## 📋 COMPLETE FEATURE REQUIREMENTS

### 1. CORE DIALER UI (DialerScreen.kt)
- Full numeric keypad (0-9, *, #) with letter labels (ABC, DEF…)
- Large number display with formatted spacing
- Backspace with long-press to clear all
- T9 contact search — as user types, match contacts by name OR number
- Matched contact shown above number input with avatar
- Favorites horizontal scroll row always visible at top
- Three action buttons: Add Contact shortcut | Call button (green, glowing) | Video Call
- Call button animates/pulses when number is valid
- Haptic feedback on every key press (HapticFeedbackConstants.KEYBOARD_TAP)

### 2. INCOMING CALL SCREEN (IncomingCallScreen.kt)
- Launched via full-screen notification Intent (no activity needed)
- Screen WAKES UP via PowerManager.WakeLock + WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
- Shows: caller photo (from ContactsContract) | name | number | carrier
- Three expanding pulse ring animations (infinite, staggered)
- Bottom action: Swipe-up to Answer (green), Swipe-down or tap X to Decline
- Slide-up quick replies: "Can't talk", "Call you later", "On my way"
- Silence ringer button (volume icon)
- All implemented using a transparent Activity launched over lock screen

### 3. ACTIVE CALL SCREEN (ActiveCallScreen.kt)
- Live call timer (counting up, MM:SS format)
- Caller info + photo
- 6 action grid:
  - Mute / Unmute (toggle mic)
  - Keypad (overlay dialpad for DTMF)
  - Speaker / Earpiece / Bluetooth toggle (3-state)
  - Add Call
  - Hold / Resume
  - Video upgrade (if supported)
- Large red End Call button at bottom center
- Call state shown: Connecting → Connected → On Hold
- Recording indicator pill (if auto-record is on)
- All actions connected to InCallService via real Telecom API calls

### 4. CALL HISTORY (RecentsScreen.kt)
- Pull from CallLog.Calls content provider
- Group by: Today / Yesterday / Earlier
- Each item: avatar | name or number | call type icon (color-coded) | time | duration
- Missed calls highlighted in red
- Long press → context menu: Call Back | Send SMS | Copy Number | Delete | Block
- NO swipe-to-delete
- Tap → Contact Detail Screen
- Tap phone icon on right → immediate call
- Delete shows Snackbar with UNDO (3.5 seconds)
- Filter tabs: All | Missed

### 5. CONTACTS (ContactsScreen.kt)
- Read from ContactsContract.Contacts
- Alphabetically indexed list with sticky section headers (A, B, C…)
- Search bar with real-time filter by name or number
- FAB (+) → Add Contact screen
- Each row: avatar | name | number | favorite star
- Long press → Quick actions: Call | SMS | Edit | Delete

### 6. CONTACT DETAIL (ContactDetailScreen.kt)
- Large hero section: photo | name | company
- Action pills: Call | SMS | WhatsApp (intent check) | Video
- All phone numbers listed (mobile, home, work)
- All emails listed
- Recent calls section (last 5 from CallLog for this contact)
- Edit button → EditContactScreen
- Favorite toggle (star)
- WhatsApp: use `Intent("android.intent.action.VIEW", Uri.parse("whatsapp://send?phone=NUMBER"))`
- Check if WhatsApp installed: `packageManager.getInstalledPackages(0).any { it.packageName == "com.whatsapp" }`

### 7. ADD / EDIT CONTACT (AddContactScreen.kt)
- Photo picker (camera or gallery)
- Fields: First name, Last name, Phone (multiple), Email (multiple), Company, Notes
- Save To selector: Phone / Google Account (list accounts via AccountManager)
- Uses ContentResolver + ContactsContract.RawContacts properly
- Form validation with inline errors

### 8. FAVORITES
- Mark/unmark from Contact Detail or Contacts list
- Stored in ContactsContract.Contacts.STARRED column
- Displayed in horizontal chip/avatar scroll on both DialerScreen and RecentsScreen
- Tap favorite → immediate call popup

### 9. SETTINGS (SettingsScreen.kt)
- SIM Settings: default SIM for calls (via SubscriptionManager)
- Call Forwarding: opens system intent `Intent(Intent.ACTION_CALL, Uri.parse("tel:**21*NUMBER#"))`
- Call Waiting: toggle (USSD-based)
- Default Dialer: button to set app as default via `TelecomManager.ACTION_CHANGE_DEFAULT_DIALER`
- Ringtone: `RingtoneManager.ACTION_RINGTONE_PICKER` intent
- Vibrate on Ring: toggle (AudioManager)
- Video Call: toggle
- Auto Call Recording: toggle (persisted to DataStore)
- Recording Storage Path: directory picker
- Blocked Numbers: list screen with add/remove

### 10. CALL RECORDING (PhoneCallService.kt + RecordingsScreen.kt)
- Auto recording using MediaRecorder inside InCallService
- Recording starts on call CONNECT, stops on DISCONNECT
- Output: AAC/M4A format, stored in user-selected or default /Recordings/ directory
- File naming: `YYYY-MM-DD_HH-mm_ContactName.m4a`
- RecordingsScreen: list all recordings from Room DB + file system scan
- Each item: waveform visualization (static bars, amplitude-like) | play/pause | share | delete
- MediaPlayer integration for playback within app
- Share via Intent.ACTION_SEND with FileProvider URI
- Delete → Snackbar with UNDO

### 11. NOTIFICATIONS & RINGING
- Incoming call: full-screen notification (NotificationCompat.Builder with fullScreenIntent)
- Uses NotificationChannel with IMPORTANCE_HIGH
- Shows Accept / Decline actions even on lock screen
- Ringing: RingtoneManager.getRingtone().play() in foreground service
- Vibration pattern: longArrayOf(0, 500, 200, 500)
- Screen wake: PowerManager.FULL_WAKE_LOCK + acquire/release

### 12. GESTURES & INTERACTIONS
- Key press: scale animation 0.95 on press, 1.0 on release
- Screen transitions: Compose Navigation with slide animations
- IncomingCall answer: vertical swipe gesture (draggable) OR tap button
- Delete: long-press ONLY (no swipe-to-delete anywhere)
- Smooth spring animations for all state changes
- Micro-interactions: button glow on call connect, pulse on incoming

### 13. UI / THEME
- Dark only (no light mode needed)
- Colors:
  - Background: #0A0A0F
  - Surface: #13131A
  - SurfaceHigh: #1C1C27
  - Accent Blue: #4F8EF7
  - Green (accept): #34C97B
  - Red (decline): #FF4C6A
  - Amber (missed): #F5A623
  - Text Primary: #F0F0F8
  - Text Sub: #8888AA
- Typography: system default (no custom fonts needed)
- Corner radius: keys=16dp, cards=20dp, avatars=full circle
- Elevation: surfaces use subtle shadow + border (rgba white 7%)

### 14. BRANDING
- App name: "Phone"
- Launcher icon: stylized phone handset in gradient circle (blue→purple)
- Splash: logo + app name, fade in, 2 second delay, then main screen
- No ads, no analytics, no trackers

---

## 🔑 CRITICAL ANDROID MANIFEST DECLARATIONS

```xml
<!-- Required permissions -->
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.WRITE_CONTACTS"/>
<uses-permission android:name="android.permission.READ_CALL_LOG"/>
<uses-permission android:name="android.permission.WRITE_CALL_LOG"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.ANSWER_PHONE_CALLS"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.MANAGE_OWN_CALLS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS"/>
<uses-permission android:name="android.permission.PROCESS_OUTGOING_CALLS"/>

<!-- Services and Receivers -->
<service android:name=".telecom.PhoneCallService"
    android:permission="android.permission.BIND_INCALL_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.telecom.InCallService"/>
    </intent-filter>
    <meta-data android:name="android.telecom.IN_CALL_SERVICE_UI" android:value="true"/>
</service>

<receiver android:name=".telecom.CallReceiver" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.PHONE_STATE"/>
        <action android:name="android.intent.action.NEW_OUTGOING_CALL"/>
    </intent-filter>
</receiver>
```

---

## ⚙️ BUILD.GRADLE DEPENDENCIES

```kotlin
dependencies {
    // Compose BOM
    implementation(platform("androidx.compose:compose-bom:2024.04.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.9.0")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51")
    kapt("com.google.dagger:hilt-compiler:2.51")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // Coil (image loading for contact photos)
    implementation("io.coil-kt:coil-compose:2.6.0")

    // Lifecycle
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0")

    // Accompanist (permissions)
    implementation("com.google.accompanist:accompanist-permissions:0.34.0")
}
```

---

## 🔥 GENERATION INSTRUCTIONS FOR AI

When generating code for this project:

1. **NEVER use placeholder comments** like `// TODO` or `// implement later` — generate REAL, WORKING code for every function
2. **Every screen must be fully functional** — no empty composables
3. **Use real Android APIs** — ContactsContract, CallLog, TelecomManager, etc.
4. **Handle permissions at runtime** — use accompanist-permissions, request before accessing protected APIs
5. **Error handling everywhere** — try/catch on ContentResolver queries, null-safe contact photo loading
6. **StateFlow + ViewModel** — all UI state managed via ViewModels, never in Composables directly
7. **Generate file by file** — start with: Theme → Models → Database → Repositories → ViewModels → Screens
8. **Test on API 26-34** — handle version differences explicitly with Build.VERSION.SDK_INT checks
9. **Animations must be real** — use `animate*AsState`, `AnimatedVisibility`, `InfiniteTransition` not fake delays
10. **Recording must actually work** — MediaRecorder properly initialized, started, stopped, released in correct lifecycle order

---

## 📦 DELIVERABLE ORDER

Generate in this exact order:
1. `AndroidManifest.xml` (complete)
2. `build.gradle.kts` (app module, complete)
3. `Color.kt` + `Theme.kt` + `Type.kt`
4. All domain models (`Contact.kt`, `CallLogEntry.kt`, `Recording.kt`)
5. Room database + DAOs
6. All Repositories (interface + impl)
7. All ViewModels
8. `PhoneCallService.kt` (InCallService — most critical)
9. `CallReceiver.kt`
10. All UI Screens (in order listed above)
11. `NavGraph.kt`
12. `MainActivity.kt`
13. `PhoneApplication.kt`

---

*This prompt was designed for maximum code generation accuracy. Feed it to any frontier AI coding model (Claude, GPT-4o, Gemini Ultra) to generate the full Android project.*
