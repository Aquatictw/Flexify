# Flexify

Flex on people with this swanky, lightning-quick gym tracker!

> **Note**: This project is a heavily modified fork of [brandonp2412/Flexify](https://github.com/brandonp2412/Flexify). While it maintains the core functionality of the original Flexify app, it has been extensively customized with new features and modifications.

## Features

- 💪 **Strength**: Log your reps and weights with ease.
- 📵 **Offline**: Flexify doesn't use the internet at all.
- 📈 **Graphs**: Visualize your progress over time with intuitive graphs.
- 🏃 **Cardio**: Record your progress with cardio types.
- ⏱️ **Timers**: Stay focused with alarms after resting.
- ⚙️ **Custom**: Toggle features on/off and swap between light/dark theme.

## About This Fork

This fork includes various enhancements and customizations to the original Flexify app. For the official release version, visit the [original Flexify repository](https://github.com/brandonp2412/Flexify).

## Screenshots

<p float="left">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/1_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/4_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/5_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/6_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/7_en-US.png" height="600">
    <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/8_en-US.png" height="600">
</p>

## Getting Started

To get started with Flexify, follow these steps:

1. **Clone the Repository**: Clone this repository to your local machine using Git:

   ```bash
   git clone https://github.com/Aquatictw/Flexify flexify
   ```

2. **Install Dependencies**: Navigate to the project directory and install the necessary dependencies:

   ```bash
   cd flexify
   flutter pub get
   ```

3. **Run the App**: Launch the Flexify app on your Android device or emulator:

   ```bash
   flutter run
   ```

## Migrations

If you edit any of the models in the `lib/database` directory you probably need to create migrations. E.g. assume the version starts at `1`.

1. Bump the `schemaVersion`
   `lib/database/database.dart`

```dart
  int get schemaVersion => 2;
```

2. Run database migrations

```sh
./scripts/migrate.sh
```

3. Add the migration step
   `lib/database/database.dart`

```dart
from1To2: (Migrator m, Schema2 schema) async {
  await m.addColumn(schema.myTable, schema.myTable.myColumn);
},
```

## License

Flexify is licensed under the [MIT License](LICENSE.md).
