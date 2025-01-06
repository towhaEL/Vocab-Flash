# Vocabulary Flashcard App  

A feature-rich mobile application designed to help users enhance their vocabulary through interactive flashcards, practice quizzes, and achievements. This app leverages Firebase for seamless backend integration, providing scalability, user authentication, and progress tracking.  

---

## Features  

### 1. **User Authentication**  
- Login via Email/Password and Google Authentication (Firebase).  
- Signup with profile creation.  
- Password reset functionality.  

### 2. **Home Screen**  
- **Categories**: Select vocabulary by alphabet initials.  
- **Profile**: View user details and learning statistics.  
- **More**:  
  - App theme toggle (light/dark mode).  
  - Help & Support section.  
  - Account settings (reset progress, delete account).  

### 3. **Flashcards**  
- Display vocabulary word with definition, synonyms, example sentence, and pronunciation (Text-to-Speech).  
- Swipe gestures:  
  - Left: Mark as viewed.  
  - Right: Mark as learned.  
- Add to Favorites and save progress to Firestore.  

### 4. **Practice Section**  
- Randomly generated quizzes with customizable settings:  
  - Select letters.  
  - Set question count.  
  - Choose difficulty (Easy, Medium, Hard).  
- Feedback on answers and quiz results saved in Firestore.  

### 5. **Profile Section**  
- Editable user profile.  
- Track learning statistics:  
  - Words learned and viewed.  
  - Quizzes completed.  
  - Daily streaks.  

### 6. **Leaderboard**  
- Global and Friends leaderboards to compare scores.  
- Add friends by email.  

### 7. **Achievements**  
- Milestones for learning progress, quizzes, and streaks.  
- Points system based on quiz difficulty.  

### 8. **Backend**  
- Firebase Authentication and Firestore integration for data storage.  
- Real-time progress tracking and user management.  

---

## Technologies Used  
- **Frontend**: Flutter  
- **Backend**: Firebase (Authentication, Firestore)  
- **State Management**: Provider  
- **Payment Gateway Integration**: Secure and reliable payment processing.  

---

## Installation  

1. Clone the repository:  
   ```bash  
   git clone https://github.com/yourusername/vocabulary-flashcard-app.git

2. Navigate to the project directory:

```bash
cd vocabulary-flashcard-app
'''


3. Install dependencies:

flutter pub get


4. Set up Firebase:

Create a Firebase project at Firebase Console.

Add your app to the Firebase project.

Download the google-services.json file (for Android) or GoogleService-Info.plist file (for iOS) and place them in the respective directories of your Flutter project.

Enable Authentication and Firestore in your Firebase project.



5. Run the app:

flutter run




---

Screenshots



---

Future Enhancements

Vocabulary search functionality.

Offline mode for flashcards and quizzes.

Advanced analytics for learning progress.

Integration with additional languages.

Enhanced payment gateway features for premium content.



---

Contribution

Contributions are welcome!

1. Fork the repository.


2. Create a feature branch:

git checkout -b feature-name


3. Commit your changes:

git commit -m "Add feature-name"


4. Push to the branch:

git push origin feature-name


5. Submit a pull request.




---

License

This project is licensed under the MIT License.


---

Contact

For any queries or support, feel free to reach out via LinkedIn.



