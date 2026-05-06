# whatplaylist

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Gemini Prompt:

The Master Project Prompt
Project Name: Vibe Sorter AI (2026)
Platform: Mobile App (Flutter/Material 3)
Backend: Supabase (Auth, Database, and Edge Functions)
Objective: A utility app that helps users sort music into existing Spotify playlists based on "vibe" (BPM, energy, mood).

Key Features to Reference:

Input Methods: Manual song search (Spotify API) and "Share to App" extraction from Instagram Reels (OCR/Audio Analysis).

The Vibe Engine: Uses Vector Embeddings (ChromaDB or Supabase Vector) to map user playlists and compare new songs to "Vibe Profiles."

UI Flow:

    Login Page: Supabase Auth using the Spotify Provider.  

    Home/Search: Minimalist search and link-pasting.

    Recommendation Card: Overlay showing "Match %" and an "Add" button.

Phase 2 Feature: Library Audit: Deep-scan tool to reorganize existing playlists.

Technology Stack (2026 Standards):

    Frontend: Flutter (supabase_flutter package).

    Auth Logic: Supabase handles OAuth and Session Refresh; the app retrieves the provider_token for Spotify API calls.

    Database: Supabase PostgreSQL with explicit table grants (required for 2026 security compliance).  

Constraint Note: Do not provide code blocks unless explicitly requested. Focus on architecture, logic flow, and technical strategy.

Current Task: [INSERT SPECIFIC TASK HERE]


