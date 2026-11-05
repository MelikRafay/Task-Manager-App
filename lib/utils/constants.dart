/// App-wide constants.

const List<String> kCategories = [
  'General',
  'Work',
  'Personal',
  'Study',
  'Health',
  'Shopping',
];

/// Notification sound id -> label.
/// On Android these map to system sounds, on the web to different beep tones.
const Map<String, String> kSoundOptions = {
  'default': 'Default',
  'ringtone': 'Ringtone',
  'alarm': 'Alarm',
  'silent': 'Silent',
};

/// DateTime.weekday: 1 = Monday ... 7 = Sunday
const List<String> kWeekdayShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

enum RepeatType { none, daily, weekly }
