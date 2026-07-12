# 📱 Smart Transit System - Passenger App

This repository contains the Passenger Mobile Application for the Smart Transit System, built with **Flutter**. This cross-platform app empowers commuters to effortlessly purchase digital tickets, top up their wallets, and track their transit vehicles in real time.

## 🚀 Features
- **Live Bus Tracking:** Real-time map interface using `flutter_map` and WebSockets to show exact bus locations and headings.
- **Dynamic QR Ticketing:** Generate secure, time-sensitive QR codes for boarding, utilizing `qr_flutter`.
- **Wallet & Payments:** Top up your transit wallet or purchase tickets directly using the native **Stripe Payment Sheet**.
- **Push Notifications:** Receive instant alerts regarding route changes, arrival times, and payment confirmations via **Firebase Cloud Messaging (FCM)**.
- **State Management:** Robust and predictable state handling using **BLoC / Cubit**.

## 💻 Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** BLoC (`flutter_bloc`)
- **Networking/Real-time:** Dio, Socket.io-client
- **Maps:** flutter_map, latlong2
- **Integrations:** Stripe (`flutter_stripe`), Firebase Core & Messaging

## 🛠️ Installation & Setup

1. **Clone the repository**
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Environment Variables**
   Create a `.env` file in the root directory to store your backend URL and Stripe publishable keys.
4. **Run the application**
   ```bash
   flutter run
   ```
