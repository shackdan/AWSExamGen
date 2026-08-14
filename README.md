# AWS Exam Prep

A simple iOS/macOS SwiftUI app for studying AWS certification questions.

Features
- Browse and take quizzes generated from JSON question banks.
- View progress and review answers.

Getting started

Requirements
- Xcode 15 or later
- Swift 5.9+ (use the version bundled with Xcode)

Open the project
- Open the Xcode project/workspace: [AWSExamPrep.xcodeproj](AWSExamPrep.xcodeproj) or the workspace if you use Swift packages.

Run
- Select a simulator or a connected device and press Run (⌘R) in Xcode.

Question banks
- Add or update question files in the `question_bank/` folder. The app loads JSON files placed there at runtime. Example files are already present:
  - `question_bank/SAA-C03_119q_20260811T203925.json`

Project layout (important files)
- [AWSExamPrep/Models/Questions.swift](AWSExamPrep/Models/Questions.swift): question models
- [AWSExamPrep/Services/QuestionBankService.swift](AWSExamPrep/Services/QuestionBankService.swift): loads and parses question JSON files
- [AWSExamPrep/Views/QuizView.swift](AWSExamPrep/Views/QuizView.swift): quiz UI

Contributing
- Drop additional JSON files into `question_bank/` and open the app to use them. If you add new features, please follow the existing SwiftUI patterns.

License
- See the LICENSE file at [AWSExamPrep/LICENSE](AWSExamPrep/LICENSE).

Questions or issues
- Open an issue or contact the repository owner.
