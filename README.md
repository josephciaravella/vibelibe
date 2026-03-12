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
Objective: A utility app that helps users sort music into existing Spotify playlists based on "vibe" (audio features like BPM, energy, and mood) rather than just genre.

Key Features to Reference:

Input Methods: Manual song search via Spotify API and a "Share to App" feature to extract song titles from Instagram Reel URLs (handling multiple songs per Reel).

The Vibe Engine: A system that analyzes the user's existing playlists to create "Vibe Profiles" (Vector Embeddings) and compares new songs to these profiles to find the best match.

UI Flow: * Login Page: Spotify OAuth (Auth Code Flow with PKCE) and Refresh Token logic.

Home/Search: A minimalist screen for searching or pasting links.

Recommendation Card: A pop-up card that appears when a song is selected, showing a "Match %" for a specific playlist and a button to add it directly.

Technology Stack (2026 Standards): * Frontend: Flutter (using dio, flutter_appauth, and receive_sharing_intent).

AI Logic: Open-source models (Llama 3/4 Mini for logic, Essentia for audio analysis) and ChromaDB for local vector storage.

API: Spotify Web API (specifically handling the 2026 deprecation of legacy audio features).

Constraint Note: Do not provide code blocks unless explicitly requested. Focus on architecture, logic flow, visual design descriptions, and technical strategy.

Current Task: [INSERT SPECIFIC TASK HERE, e.g., "Helping me design the visual layout of the Recommendation Card"]