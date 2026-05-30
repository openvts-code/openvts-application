// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'OpenVTS';

  @override
  String get settings => 'الإعدادات';

  @override
  String get localization => 'التوطين';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get dateFormat => 'تنسيق التاريخ';

  @override
  String get timeFormat => 'تنسيق الوقت';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get use24Hour => 'وقت 24 ساعة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get edit => 'تحرير';

  @override
  String get search => 'بحث';

  @override
  String get delete => 'حذف';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get prev => 'السابق';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get warning => 'تحذير';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get en => 'الإنجليزية';

  @override
  String get hi => 'الهندية';

  @override
  String get ar => 'العربية';

  @override
  String get es => 'الإسبانية';

  @override
  String get fr => 'الفرنسية';

  @override
  String get pt => 'البرتغالية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'التسجيل';

  @override
  String get administrators => 'المسؤولون';

  @override
  String get payments => 'المدفوعات';

  @override
  String get support => 'الدعم';

  @override
  String get tickets => 'التذاكر';

  @override
  String get home => 'الصفحة الرئيسية';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get keepEditing => 'مواصلة التحرير';

  @override
  String get discardChanges => 'تجاهل التغييرات';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get refresh => 'تحديث';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get selectTheme => 'اختر المظهر';

  @override
  String get selectDateFormat => 'اختر تنسيق التاريخ';

  @override
  String get selectTimeFormat => 'اختر تنسيق الوقت';

  @override
  String get selectTimezone => 'اختر المنطقة الزمنية';

  @override
  String previewDate(String date) {
    return 'معاينة: $date';
  }

  @override
  String previewTime(String time) {
    return 'معاينة: $time';
  }

  @override
  String get settingsUpdated => 'تم تحديث الإعدادات';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get localizationUpdated => 'تم تحديث إعدادات التوطين';

  @override
  String get failedToUpdate => 'فشل التحديث. يرجى المحاولة مرة أخرى.';

  @override
  String get noData => 'لا توجد بيانات متاحة';

  @override
  String get retry => 'إعادة محاولة';

  @override
  String get confirmDiscard => 'تجاهل التغييرات غير المحفوظة؟';

  @override
  String confirmDiscardMessage(String tab) {
    return '$tab يحتوي على تعديلات غير محفوظة. التجاهل سيفقدك هذه التغييرات.';
  }
}
