# vibelibe

A Flutter mobile application that helps users sort music into existing Spotify playlists based on "vibe" (BPM, energy, mood).

## Features

- **Input Methods**: Manual song search via the Spotify API, and "Share to App" extraction from Instagram Reels using OCR/Audio Analysis.
- **The Vibe Engine**: Uses Vector Embeddings (ChromaDB or Supabase Vector) to map user playlists and compare new songs to "Vibe Profiles."
- **Spotify Integration**: View recommendations with a "Match %" overlay and easily add them to your playlists.
- **Library Audit (Upcoming)**: A deep-scan tool to reorganize and optimize existing playlists.

## UI Flow

1. **Login Page**: Supabase Auth using the Spotify Provider.
2. **Home/Search**: Minimalist search and link-pasting interface.
3. **Recommendation Card**: Overlay showing "Match %" and an "Add" button.

## Technology Stack

- **Frontend**: Flutter / Material 3
- **Backend & Database**: Supabase PostgreSQL (with explicit table grants for enhanced security)
- **Authentication**: Supabase Auth handles OAuth and Session Refresh; the app retrieves the `provider_token` for Spotify API calls.
- **Edge Functions**: Used for backend logic and processing.

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

- Flutter SDK (latest version)
- Supabase Project setup with Spotify OAuth provider

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Set up your Supabase credentials in the appropriate environment variables/configuration.
4. Run the app using `flutter run`

### Resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Supabase Flutter Quickstart](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
