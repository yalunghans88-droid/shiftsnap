# ShiftSnap

## Overview

ShiftSnap is a Flutter mobile app for nurses and call center agents with rotating
schedules. It turns a printed duty roster into a digital calendar: the user
photographs the roster, Google's Gemini API extracts shift details (title, date,
start/end time), and the user reviews, edits, and confirms each shift before
saving. ShiftSnap also schedules local reminders so users never miss a shift.

## Setup and Installation

### Prerequisites

- Flutter SDK: **3.47.5** (stable channel)
- Dart SDK: **3.13.4**
- Android Studio (for Android builds) or Xcode (for iOS builds)
- A Google Gemini API key — get one at https://ai.google.dev/

### Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/yalunghans88-droid/shiftsnap.git
   cd shiftsnap
