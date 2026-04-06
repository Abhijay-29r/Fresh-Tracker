# 🍃 Fresh-Tracker
> **Smart Pantry & Expiry Tracking**
> A mobile application designed to reduce household food waste through automated inventory management and intelligent restocking logic.

---

## 📱 Project Overview
**FreshTrack** is a cross-platform mobile solution that helps users manage household food supplies. It tracks expiry dates, provides consumption analytics, and bridges the gap between the pantry and the shopping list to ensure efficient kitchen management.

### ✨ Key Features
* **🔍 Barcode Integration:** Powered by the **Open Food Facts API** for instant product identification and data retrieval.
* **🔔 Intelligent Alerts:** Push notifications triggered by custom expiry logic to prevent food spoilage.
* **🔄 Automated Shopping Loop:** Logic-driven workflow that suggests restocking items as they are consumed or wasted.
* **📊 Efficiency Analytics:** Visual dashboard tracking food utilization rates and waste metrics.
* **🌑 Offline-First Architecture:** Utilizing **Hive NoSQL** for high-performance local data persistence without requiring an internet connection.

---

## 🛠️ Tech Stack

| Component | Technology |
| :--- | :--- |
| **Framework** | Flutter (Dart) |
| **Database** | Hive (NoSQL / Local) |
| **External API** | Open Food Facts |
| **Notifications** | Flutter Local Notifications |
| **Scanning** | Mobile Barcode Scanner |

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (v3.0.0+)
* Dart SDK (v3.0.0+)

### Installation
1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/username/fresh_track.git](https://github.com/username/fresh_track.git)
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Generate Adapters:**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
4.  **Launch App:**
    ```bash
    flutter run
    ```

---

## 🏗️ Architecture
The project follows a modular structure to separate concerns:
* `lib/models/`: Data schemas and TypeAdapters for local storage.
* `lib/services/`: Independent modules for API communication, database management, and notification scheduling.
* `lib/screens/`: Feature-specific UI components.

---

## 📄 License
This project is licensed under the **MIT License**. See the `LICENSE` file for full details.
