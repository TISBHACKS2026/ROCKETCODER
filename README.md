# TISB Swap

TISB Swap is a community-driven marketplace application designed specifically for the students and faculty of The International School Bangalore (TISB). The project, developed for TISB Hacks 2026, aims to promote sustainability and a circular economy within the school community by facilitating the swapping and resale of pre-owned items.

## Overview

The application provides a secure platform for users to list items they no longer need, browse for items listed by others, and communicate directly within the app to arrange swaps or purchases. By encouraging reuse, TISB Swap helps reduce waste and the environmental footprint of the school community.

## Key Features

- Marketplace: A central feed where users can browse listed items across various categories.
- Item Listing: Easy-to-use form for users to list their items with descriptions, categories, and images.
- Real-time Chat: Integrated messaging system for users to communicate and coordinate swaps.
- Lost and Found: A dedicated section for reporting and finding lost items within the school campus.
- Sustainability Tracking: Impact badges and statistics that highlight the environmental benefits of swapping items (e.g., CO2 saved, water conserved).
- User Profiles: Personalized profiles managing user listings, active chats, and sustainability stats.
- Secure Authentication: User verification and account management powered by Supabase.

## Technical Stack

- Frontend: Flutter (Dart)
- Backend: Supabase (Authentication, Database, and Storage)
- State Management: Provider / Flutter built-in mechanisms
- Theme: Material 3 with Google Fonts (Inter)
- Logic/Utilities: flutter_dotenv for environment management, image_picker for media handling, and intl for formatting.

## Project Structure

The codebase follows a modular and clean architecture, ensuring scalability and maintainability for the future.

### lib/

- `main.dart`: The entry point of the application. It handles the initialization of Supabase, environment variables, and defines the global theme and routing.
- `models/`: Contains data models that define the structure of the application's data.
    - `item.dart`: Represents a marketplace or lost/found item.
    - `message.dart`: Defines the structure for chat messages.
    - `user_profile.dart`: Manages user-related data and statistics.
- `screens/`: Contains the full-page UI components.
    - `welcome_screen.dart`: The initial onboarding and login page.
    - `marketplace_screen.dart`: The main item discovery feed.
    - `item_details_screen.dart`: Detailed view of a specific item.
    - `list_item_screen.dart`: Interface for creating new listings.
    - `chat_list_screen.dart`: Overview of all active conversations.
    - `chat_screen.dart`: Individual messaging interface.
    - `lost_found_screen.dart`: Feed for lost and found items.
    - `profile_screen.dart`: User settings and activity hub.
    - `report_item_screen.dart`: Utility for reporting problematic content or items.
- `services/`: Contains logic for external communications.
    - `supabase_service.dart`: A centralized service handling all interactions with Supabase, including database queries, authentication requests, and file uploads.
- `utils/`: Includes helper classes and constants.
    - `colors.dart`: Defines the application's color palette (e.g., primary greens, grays).
    - `constants.dart`: Stores layout constants, text styles, and reusable configuration values.
- `widgets/`: Contains reusable UI components used across multiple screens.
    - `item_card.dart`: The preview card for marketplace listings.
    - `lost_found_card.dart`: Specialized card for lost/found items.
    - `custom_button.dart`: Standardized button component.
    - `impact_badge.dart`: Visual indicator for environmental impact.
    - `stat_card.dart`: Displays user metrics on the profile page.
    - `category_chip.dart`: Interactive filters for browsing items.

## Development and Contributions

This project was developed for the TISB Hacks 2026 competition. All code is structured to facilitate collaborative development and future feature expansions. This is a solo project by me(Ayansh Paliwal)