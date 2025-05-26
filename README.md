# VocabFlash: Master Your Words - A Flutter Language Learning Companion 🚀

## Overview

VocabFlash is a modern, intuitive Flutter mobile application designed to empower language learners by providing a dynamic and personalized platform for vocabulary acquisition and practice. Built with a focus on user engagement and seamless performance, this app transforms the journey of expanding your lexicon into an enjoyable and rewarding experience.

---

## Features

### Engage & Learn 📖

* **Interactive Flashcards**: Dive deep into vocabulary with beautifully presented flashcards, each featuring the word, its precise definition, helpful synonyms, and a contextual example sentence.
  * **Effortless Progression**: Navigate through words with simple swipes; mark words as 'viewed' or 'learned' to track your progress.
  * **Personalized Study**: Easily add challenging words to your favorites and enhance pronunciation skills with integrated text-to-speech functionality.

<img src="https://github.com/towhaEL/Vocab-Flash/blob/main/assets/screenshots/flashcards.jpg" alt="Flashcards Screen" width="300"/>

---

### Practice & Perfect 📝

* **Dynamic Quizzes**: Reinforce your learning through a variety of randomized multiple-choice quizzes.
  * **Customized Challenges**: Tailor your practice sessions by selecting specific letter categories, adjusting the number of questions, and setting difficulty levels.
  * **Performance Tracking**: Your quiz results are meticulously saved in Firestore, allowing you to monitor your improvement over time.

<img src="https://github.com/towhaEL/Vocab-Flash/blob/main/assets/screenshots/practice_quiz.jpg" alt="Practice Quiz Screen" width="300"/>

---

### Motivate & Track 📈

* **Competitive Leaderboards**: Stay inspired and challenge yourself by comparing your progress with others.
  * **Global Standings**: See how you rank among all users, with your position highlighted on the global leaderboard.
  * **Friendly Rivalry**: Connect with friends, add them to your network, and compare your vocabulary mastery scores directly.

<img src="https://github.com/towhaEL/Vocab-Flash/blob/main/assets/screenshots/leaderboards.jpg" alt="Leaderboards Screen" width="300"/>

* **Rewarding Achievements**: Celebrate every milestone in your language journey by unlocking achievements.
  * **Unlock Milestones**: Earn achievements for various accomplishments, including words learned, quizzes completed, daily streaks, and perfect quiz scores.
  * **Point System**: Gain points based on the difficulty of words mastered and challenges overcome, visually unlocking new achievements.

<img src="https://github.com/towhaEL/Vocab-Flash/blob/main/assets/screenshots/achievements.jpg" alt="Achievements Screen" width="300"/>

* **Comprehensive Profile**: Your personal hub for tracking language growth.
  * **Customizable Identity**: Personalize your profile with an editable picture and name.
  * **Detailed Statistics**: Gain insights into your learning with data on words learned, quizzes completed, and average scores.
  * **Visual Progress**: Maintain your learning momentum with a daily streak tracker, visually represented on a weekly calendar.

---

### Seamless Experience ✨

* **Robust Backend**: Powered by Firebase, the app ensures a secure and smooth user experience with seamless integration.
  * **Secure Authentication**: Enjoy streamlined login and signup processes with support for both email/password and Google authentication.
  * **Account Management**: Convenient features for password reset and user profile management within Firestore.

* **User-Centric Settings**:
  * **Customizable Interface**: Toggle between light and dark modes for optimal viewing comfort.
  * **Dedicated Support**: Access a comprehensive FAQ section and direct contact support. Options to reset progress or delete your account are also available.

<img src="https://github.com/towhaEL/Vocab-Flash/blob/main/assets/screenshots/settings.jpg" alt="Settings Screen" width="300"/>

---

## Technologies Used

* **Frontend**: Flutter 💙  
* **Backend**: Google Firebase (Authentication, Firestore) 🔥

---

## Getting Started

To get started with VocabFlash locally, follow these steps:

1. **Clone the repository**:
    ```bash
    git clone [Your-GitHub-Repo-URL]
    cd vocabulary-mastery-app
    ```

2. **Install dependencies**:
    ```bash
    flutter pub get
    ```

3. **Firebase Setup**:
    * Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/).
    * Add Android and iOS apps to your Firebase project.
    * Download `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) and place them in the correct directories (`android/app/` and `ios/Runner/` respectively).
    * Enable Firebase Authentication (Email/Password and Google Sign-In) and Firestore in your Firebase project.

4. **Run the application**:
    ```bash
    flutter run
    ```

---

## Contributing

We welcome contributions to VocabFlash! If you'd like to contribute, please fork the repository and create a pull request with your changes. See our `CONTRIBUTING.md` for more details.

---

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
