// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenVTS';

  @override
  String get settings => 'Settings';

  @override
  String get localization => 'Localization';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get timezone => 'Timezone';

  @override
  String get use24Hour => '24-Hour Time';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get delete => 'Delete';

  @override
  String get reset => 'Reset';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get prev => 'Previous';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get en => 'English';

  @override
  String get hi => 'Hindi';

  @override
  String get ar => 'Arabic';

  @override
  String get es => 'Spanish';

  @override
  String get fr => 'French';

  @override
  String get pt => 'Portuguese';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get administrators => 'Administrators';

  @override
  String get payments => 'Payments';

  @override
  String get support => 'Support';

  @override
  String get tickets => 'Tickets';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get discardChanges => 'Discard Changes';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get refresh => 'Refresh';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get selectDateFormat => 'Select Date Format';

  @override
  String get selectTimeFormat => 'Select Time Format';

  @override
  String get selectTimezone => 'Select Timezone';

  @override
  String previewDate(String date) {
    return 'Preview: $date';
  }

  @override
  String previewTime(String time) {
    return 'Preview: $time';
  }

  @override
  String get settingsUpdated => 'Settings updated';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get localizationUpdated => 'Localization settings updated';

  @override
  String get failedToUpdate => 'Failed to update. Please try again.';

  @override
  String get noData => 'No data available';

  @override
  String get retry => 'Retry';

  @override
  String get confirmDiscard => 'Discard unsaved changes?';

  @override
  String confirmDiscardMessage(String tab) {
    return '$tab has unsaved edits. Discarding will lose these changes.';
  }
}
