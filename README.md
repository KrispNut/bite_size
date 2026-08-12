# Bite Size 🍛

Bite Size is a Flutter-based utility application designed to automate and simplify daily lunch logistics and expense coordination for office teams. It eliminates the chaos of manual group chats by tracking who is participating, predicting if there's enough food with AI, calculating the total bread (roti) count, assigning a Tandoor Runner, and managing daily expense splits.

---

## 🚀 Key Features

*   **Daily Roster:** A daily reset system tracking today's lunch session. Users input their lunch status, specifying the dish they brought (if any), portion size (how many people it feeds), and their personal roti count.
*   **AI Lunch Assessment (Chef AI):** Uses Gemini AI to intelligently compare the number of participants against the total portions and types of curry/salan brought. It generates a detailed analysis and recommendations if there is a deficit.
*   **Bite Size Counter:** A master counter displaying the exact total number of rotis needed for the day in real time.
*   **Tandoor Runner:** Coworkers can claim the "Tandoor Runner" role for the day to fetch the fresh rotis, or an external runner (like the Office Boy) can be assigned. 
*   **Smart Notifications:** Hourly reminders for the admin if no runner is selected, and high-priority alerts sent to everyone when the food arrives.
*   **Roti Ledger & Settle Bill:** The admin can input the daily roti and salan cost, and the app calculates individual shares and logs transactions in the ledger.

---

## 🛠️ Architecture & Tech Stack

*   **Frontend:** Flutter (Mobile).
*   **State Management:** `Provider` paired with `ChangeNotifier` view models (e.g., `DashboardViewModel`, `AuthViewModel`).
*   **Backend:** [Supabase](https://supabase.com/) for real-time Postgres database synchronization, and **Google Sign-In** for authentication.
*   **AI Integration:** Google Gemini AI for the Chef AI feature.
*   **UI/UX:** Animated transitions, Lottie animations, glassmorphism frosted glass overlays, and dynamic theming using `ThemeService`.

---

## ⚙️ Getting Started

### Prerequisites

*   Flutter SDK installed
*   Supabase project configured
*   Google Cloud Console project (for Google Sign-In OAuth credentials)
*   Gemini API Key (for Chef AI)

### Setup & Installation

1.  **Clone & Fetch dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Environment Variables:**
    The project relies on compile-time environment variables for secrets. You will need to provide them via `--dart-define` when running or building the app:
    *   `SUPABASE_URL`
    *   `SUPABASE_ANON_KEY`
    *   `GEMINI_API_KEY`
    *   `GOOGLE_WEB_CLIENT_ID`
    *   `GOOGLE_IOS_CLIENT_ID`

3.  **Run the application:**
    ```bash
    flutter run \
      --dart-define=SUPABASE_URL="..." \
      --dart-define=SUPABASE_ANON_KEY="..." \
      --dart-define=GEMINI_API_KEY="..." \
      --dart-define=GOOGLE_WEB_CLIENT_ID="..." \
      --dart-define=GOOGLE_IOS_CLIENT_ID="..."
    ```