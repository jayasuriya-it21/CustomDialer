Below is a **complete professional documentation** for your project — structured like a real production system document. You can directly use this as:

*   ✅ README.md
*   ✅ Project documentation
*   ✅ Knowledge transfer (KT) document
*   ✅ Portfolio project description

***

# 🌟 **Candidate Management System – Full Documentation**

***

# 📌 1. **Project Overview**

The **Candidate Management System** is a web-based recruitment workflow application designed to manage candidate lifecycle stages including:

*   Candidate viewing
*   Filtering & searching
*   Status transitions (Shortlist → Select → Reject → Remove)
*   Resume handling (view & download)
*   Skill and experience filtering

***

## 🎯 **Primary Goal**

To provide a **centralized, scalable, and efficient system** for managing candidates across hiring stages with a consistent UI and reusable architecture.

***

# 🏗️ 2. **Technology Stack**

## 🔷 Frontend

*   Flutter Web
*   Dart
*   BLoC (State Management)

## 🔷 Backend

*   Spring Boot (Java)
*   REST APIs

## 🔷 Other Concepts

*   RESTful architecture
*   JWT authentication
*   MVC pattern (backend)
*   BLoC pattern (frontend)

***

# 🧩 3. **Project Architecture**

***

## 🔹 Frontend Architecture (Flutter)

    lib/
    │
    ├── core/
    │   ├── models/
    │   ├── constant/
    │   ├── network/
    │   └── utils/
    │
    ├── features/
    │   └── view_candidates/
    │       ├── bloc/
    │       ├── screen/
    │       └── widget/

***

## 🔹 Key Layers

### ✅ UI Layer

*   Screens
*   Reusable Widgets

### ✅ Business Logic Layer

*   BLoC (Events → State updates)

### ✅ Data Layer

*   API service
*   Models

***

# 🔄 4. **Candidate Workflow Lifecycle**

    ACTIVE
       ↓
    SHORTLISTED
       ↓
    SELECTED   ✅ NEW
       ↓
    FINAL (Optional)

    OR

    SHORTLISTED → REJECTED
    ANY STATUS → REMOVED
    REMOVED → RESTORED (ACTIVE)

***

# 📄 5. **Pages in Application**

***

## 🔷 1. Explore / View Page

*   Displays all candidates
*   Supports filters
*   Shows status badge
*   Allows:
    *   Shortlist
    *   Reject
    *   Remove
*   Hides ACTIVE badge (UX decision)

***

## 🔷 2. Shortlisted Page

*   Displays only SHORTLISTED candidates
*   Actions:
    *   ✅ Select (NEW)
    *   Reject
    *   Remove

***

## 🔷 3. Selected Page ✅ NEW

*   Displays SELECTED candidates
*   Actions:
    *   Reject
    *   Remove
*   Includes:
    *   Filter panel
    *   Search bar

***

## 🔷 4. Rejected Page

*   Displays rejected candidates
*   Actions:
    *   Restore
    *   Remove

***

## 🔷 5. Removed Page

*   Displays deleted candidates
*   Actions:
    *   Restore

***

# 🧱 6. **Reusable Components**

***

## ✅ CandidateCard

A common UI component used across all pages.

### Features:

*   Status badge
*   Dynamic button layout
*   View/Download resume
*   Delete icon
*   Vertical / horizontal actions
*   Confirmation dialogs

***

## ✅ SearchWidget

Reusable search bar:

### Features:

*   Searches:
    *   candidate name
    *   candidate email
*   Clear button support
*   Backward compatible API

***

## ✅ FilterCard

Reusable filter panel:

### Filters:

*   Experience (Min/Max)
*   Skills

### Features:

*   Dynamic dropdown validation
*   Reset filters support
*   Responsive UI

***

# 🧠 7. **State Management (BLoC)**

***

## 🔷 BLoC Structure

    Event → Bloc → State → UI

***

## 🔷 Key Events

| Event                   | Purpose                  |
| ----------------------- | ------------------------ |
| FetchCandidates         | Load all candidates      |
| FetchCandidatesByStatus | Load filtered candidates |
| UpdateSearch            | Search query             |
| ToggleSkill             | Filter by skill          |
| UpdateExperience        | Filter by experience     |
| SelectCandidate         | ✅ Move to SELECTED       |
| ShortlistCandidate      | Move to shortlist        |
| RejectCandidate         | Reject                   |
| RemoveCandidate         | Delete                   |
| ActivateCandidate       | Restore                  |

***

## 🔷 State Fields

*   entireCandidateList
*   filteredCandidateList
*   selectedSkillFilters
*   searchKeyword
*   experience range
*   loading status
*   user message

***

# 🔍 8. **Filtering Logic**

***

### ✅ Search

Search works on:

```dart
candidateFullName + candidateEmailAddress
```

***

### ✅ Skill Filter

*   Case-insensitive
*   Multiple selection

***

### ✅ Experience Filter

Rules:

*   Max must be greater than Min
*   Automatically resets invalid max values

***

### ✅ Reset Filters

Resets:

*   Search
*   Skills
*   Experience
*   Email filters

***

# 📄 9. **Resume Handling**

***

## ✅ Download Resume

*   Supports all formats:
    *   PDF
    *   DOC
    *   DOCX
    *   PPT
    *   PPTX

### Backend Fix:

```java
Files.probeContentType(path)
```

***

## ✅ View Resume

*   Only PDFs are viewable
*   Non-PDF:
    *   View button disabled

***

## ✅ Data Model

```dart
candidateResumeFileName
candidateResumeFilePath
```

***

# 🔐 10. **Authentication Handling**

***

## ✅ JWT-based API calls

Every request uses:

```dart
Authorization: Bearer <token>
```

***

## ✅ Auto Logout (401)

Handled globally:

*   Show session expired message
*   Clear token
*   Navigate to login page
*   Prevent further API calls

***

# ⚙️ 11. **UI Enhancements**

***

✅ Dynamic button width  
✅ Disabled button styling (white/grey)  
✅ Status badge improvements  
✅ PDF-only view icon  
✅ Consistent color coding

***

# 🧪 12. **Error Handling**

***

### ✅ Network Errors

*   Logged via debug logs
*   Handled in UI

***

### ✅ API Failures

*   Graceful UI fallback
*   Snackbar notifications

***

### ✅ Hot Reload Web Issue

Solved:

*   avoid stale HTTP connection reuse
*   improved CORS handling

***

# 🎨 13. **UI/UX Improvements**

***

✅ Vertical button layout for View page  
✅ Unified design system  
✅ Responsive layout  
✅ Clear icon states  
✅ Better tagging system

***

# 🗺️ 14. **Routing**

```dart
AppRouter.selectedCandidate
```

Navigation available from:

*   Home page cards
*   Menu (optional)

***

# 🧩 15. **Home Dashboard Integration**

```dart
HomeModel(
  homeTitle: AppStrings.selectedCandidates,
  homeMainIcon: Icons.verified_user_rounded,
  homeRoute: AppRouter.selectedCandidate,
)
```

***

# ✅ 16. **Final System Capabilities**

***

✔ Candidate Listing  
✔ Advanced Filtering  
✔ Status Workflow  
✔ Resume Management  
✔ UI Reusability  
✔ Backend Integration  
✔ Authentication Safety  
✔ Scalable Architecture

***

# 🚀 17. **Future Enhancements (Optional)**

***

*   Interview scheduling module
*   Candidate rating system
*   Analytics dashboard
*   Pagination / infinite scroll
*   Role-based access
*   Export candidates (CSV/PDF)

***

# 🎯 **Conclusion**

This system is now a **production-ready recruitment pipeline module** with:

*   Clean architecture
*   Reusable components
*   Strong state management
*   Robust API integration
*   Excellent UI consistency

***
