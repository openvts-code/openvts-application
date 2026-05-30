// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OpenVTS';

  @override
  String get settings => 'Configuración';

  @override
  String get localization => 'Localización';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get dateFormat => 'Formato de fecha';

  @override
  String get timeFormat => 'Formato de hora';

  @override
  String get timezone => 'Zona horaria';

  @override
  String get use24Hour => 'Hora de 24 horas';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get search => 'Buscar';

  @override
  String get delete => 'Eliminar';

  @override
  String get reset => 'Restablecer';

  @override
  String get close => 'Cerrar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get prev => 'Anterior';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get warning => 'Advertencia';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get en => 'Inglés';

  @override
  String get hi => 'Hindi';

  @override
  String get ar => 'Árabe';

  @override
  String get es => 'Español';

  @override
  String get fr => 'Francés';

  @override
  String get pt => 'Portugués';

  @override
  String get profile => 'Perfil';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get administrators => 'Administradores';

  @override
  String get payments => 'Pagos';

  @override
  String get support => 'Soporte';

  @override
  String get tickets => 'Entradas';

  @override
  String get home => 'Inicio';

  @override
  String get dashboard => 'Panel';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get discardChanges => 'Descartar cambios';

  @override
  String get unsavedChanges => 'Cambios no guardados';

  @override
  String get refresh => 'Actualizar';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get selectTheme => 'Seleccionar tema';

  @override
  String get selectDateFormat => 'Seleccionar formato de fecha';

  @override
  String get selectTimeFormat => 'Seleccionar formato de hora';

  @override
  String get selectTimezone => 'Seleccionar zona horaria';

  @override
  String previewDate(String date) {
    return 'Vista previa: $date';
  }

  @override
  String previewTime(String time) {
    return 'Vista previa: $time';
  }

  @override
  String get settingsUpdated => 'Configuración actualizada';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get localizationUpdated => 'Configuración de localización actualizada';

  @override
  String get failedToUpdate =>
      'Error al actualizar. Por favor, intente de nuevo.';

  @override
  String get noData => 'No hay datos disponibles';

  @override
  String get retry => 'Reintentar';

  @override
  String get confirmDiscard => '¿Descartar cambios no guardados?';

  @override
  String confirmDiscardMessage(String tab) {
    return '$tab tiene ediciones sin guardar. Descartar perderá estos cambios.';
  }
}
