// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'OpenVTS';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get localization => 'स्थानीयकरण';

  @override
  String get language => 'भाषा';

  @override
  String get theme => 'थीम';

  @override
  String get dateFormat => 'तारीख प्रारूप';

  @override
  String get timeFormat => 'समय प्रारूप';

  @override
  String get timezone => 'समय क्षेत्र';

  @override
  String get use24Hour => '24-घंटे का समय';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get search => 'खोज';

  @override
  String get delete => 'हटाएं';

  @override
  String get reset => 'रीसेट करें';

  @override
  String get close => 'बंद करें';

  @override
  String get back => 'पीछे';

  @override
  String get next => 'अगला';

  @override
  String get prev => 'पिछला';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफल';

  @override
  String get warning => 'चेतावनी';

  @override
  String get light => 'हल्का';

  @override
  String get dark => 'गहरा';

  @override
  String get system => 'सिस्टम';

  @override
  String get en => 'अंग्रेजी';

  @override
  String get hi => 'हिंदी';

  @override
  String get ar => 'अरबी';

  @override
  String get es => 'स्पेनिश';

  @override
  String get fr => 'फ्रेंच';

  @override
  String get pt => 'पुर्तगाली';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get login => 'लॉगिन';

  @override
  String get register => 'पंजीकरण';

  @override
  String get administrators => 'प्रशासक';

  @override
  String get payments => 'भुगतान';

  @override
  String get support => 'समर्थन';

  @override
  String get tickets => 'टिकट';

  @override
  String get home => 'होम';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get keepEditing => 'संपादन जारी रखें';

  @override
  String get discardChanges => 'परिवर्तन हटाएं';

  @override
  String get unsavedChanges => 'बिना सहेजे गए परिवर्तन';

  @override
  String get refresh => 'ताज़ा करें';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get selectTheme => 'थीम चुनें';

  @override
  String get selectDateFormat => 'तारीख प्रारूप चुनें';

  @override
  String get selectTimeFormat => 'समय प्रारूप चुनें';

  @override
  String get selectTimezone => 'समय क्षेत्र चुनें';

  @override
  String previewDate(String date) {
    return 'पूर्वावलोकन: $date';
  }

  @override
  String previewTime(String time) {
    return 'पूर्वावलोकन: $time';
  }

  @override
  String get settingsUpdated => 'सेटिंग्स अपडेट की गई';

  @override
  String get profileUpdated => 'प्रोफाइल अपडेट की गई';

  @override
  String get localizationUpdated => 'स्थानीयकरण सेटिंग्स अपडेट की गई';

  @override
  String get failedToUpdate => 'अपडेट करने में विफल। कृपया दोबारा प्रयास करें।';

  @override
  String get noData => 'कोई डेटा उपलब्ध नहीं है';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get confirmDiscard => 'बिना सहेजे गए परिवर्तन हटाएं?';

  @override
  String confirmDiscardMessage(String tab) {
    return '$tab के अनसेव किए गए संपादन हैं। हटाने से ये परिवर्तन खो जाएंगे।';
  }
}
