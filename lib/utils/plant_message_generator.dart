/// Generate a random plant message based on farm mood
String generatePlantMessage(String mood) {
  final random = DateTime.now().microsecond;
  mood = mood.toLowerCase().trim();

  switch (mood) {
    case 'happy':
      final happyMessages = [
        "Hey boss 😎 everything is perfect here!",
        "Sun, water, vibes… I'm thriving 🌱✨",
      ];
      return happyMessages[random % happyMessages.length];

    case 'good':
      final goodMessages = [
        "Not bad… but I could use a little boost 👀",
        "I'm okay 👍 just don't forget me 😅",
      ];
      return goodMessages[random % goodMessages.length];

    case 'stressed':
      final stressedMessages = [
        "Uhh… I'm kinda struggling here 😬",
        "Water please 💧 I'm not feeling great",
      ];
      return stressedMessages[random % stressedMessages.length];

    case 'critical':
      final criticalMessages = [
        "HELP 😭 I'm dying out here",
        "Too much stress!! Fix me ASAP 🚨",
      ];
      return criticalMessages[random % criticalMessages.length];

    default:
      return "Hey there! 🌱 How am I looking?";
  }
}
