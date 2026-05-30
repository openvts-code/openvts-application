// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OpenVTS';

  @override
  String get settings => 'Configurações';

  @override
  String get localization => 'Localização';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get dateFormat => 'Formato de Data';

  @override
  String get timeFormat => 'Formato de Hora';

  @override
  String get timezone => 'Fuso Horário';

  @override
  String get use24Hour => 'Hora em 24 Horas';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get search => 'Pesquisar';

  @override
  String get delete => 'Excluir';

  @override
  String get reset => 'Redefinir';

  @override
  String get close => 'Fechar';

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Próximo';

  @override
  String get prev => 'Anterior';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get warning => 'Aviso';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get system => 'Sistema';

  @override
  String get en => 'Inglês';

  @override
  String get hi => 'Hindi';

  @override
  String get ar => 'Árabe';

  @override
  String get es => 'Espanhol';

  @override
  String get fr => 'Francês';

  @override
  String get pt => 'Português';

  @override
  String get profile => 'Perfil';

  @override
  String get logout => 'Sair';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Registrar';

  @override
  String get administrators => 'Administradores';

  @override
  String get payments => 'Pagamentos';

  @override
  String get support => 'Suporte';

  @override
  String get tickets => 'Tickets';

  @override
  String get home => 'Início';

  @override
  String get dashboard => 'Painel';

  @override
  String get keepEditing => 'Continuar Editando';

  @override
  String get discardChanges => 'Descartar Alterações';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String get refresh => 'Atualizar';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get selectTheme => 'Selecionar Tema';

  @override
  String get selectDateFormat => 'Selecionar Formato de Data';

  @override
  String get selectTimeFormat => 'Selecionar Formato de Hora';

  @override
  String get selectTimezone => 'Selecionar Fuso Horário';

  @override
  String previewDate(String date) {
    return 'Visualizar: $date';
  }

  @override
  String previewTime(String time) {
    return 'Visualizar: $time';
  }

  @override
  String get settingsUpdated => 'Configurações atualizadas';

  @override
  String get profileUpdated => 'Perfil atualizado';

  @override
  String get localizationUpdated => 'Configurações de localização atualizadas';

  @override
  String get failedToUpdate => 'Falha ao atualizar. Tente novamente.';

  @override
  String get noData => 'Nenhum dado disponível';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get confirmDiscard => 'Descartar alterações não salvas?';

  @override
  String confirmDiscardMessage(String tab) {
    return '$tab tem edições não salvas. Descartar perderá essas alterações.';
  }
}
