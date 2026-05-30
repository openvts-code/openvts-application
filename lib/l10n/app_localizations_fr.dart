// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'OpenVTS';

  @override
  String get settings => 'Paramètres';

  @override
  String get localization => 'Localisation';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get dateFormat => 'Format de date';

  @override
  String get timeFormat => 'Format de l\'heure';

  @override
  String get timezone => 'Fuseau horaire';

  @override
  String get use24Hour => 'Heure 24 heures';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get edit => 'Modifier';

  @override
  String get search => 'Rechercher';

  @override
  String get delete => 'Supprimer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get prev => 'Précédent';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Avertissement';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get en => 'Anglais';

  @override
  String get hi => 'Hindi';

  @override
  String get ar => 'Arabe';

  @override
  String get es => 'Espagnol';

  @override
  String get fr => 'Français';

  @override
  String get pt => 'Portugais';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Déconnexion';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get administrators => 'Administrateurs';

  @override
  String get payments => 'Paiements';

  @override
  String get support => 'Support';

  @override
  String get tickets => 'Tickets';

  @override
  String get home => 'Accueil';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get keepEditing => 'Continuer la modification';

  @override
  String get discardChanges => 'Abandonner les modifications';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get refresh => 'Actualiser';

  @override
  String get selectLanguage => 'Sélectionner une langue';

  @override
  String get selectTheme => 'Sélectionner un thème';

  @override
  String get selectDateFormat => 'Sélectionner un format de date';

  @override
  String get selectTimeFormat => 'Sélectionner un format d\'heure';

  @override
  String get selectTimezone => 'Sélectionner un fuseau horaire';

  @override
  String previewDate(String date) {
    return 'Aperçu: $date';
  }

  @override
  String previewTime(String time) {
    return 'Aperçu: $time';
  }

  @override
  String get settingsUpdated => 'Paramètres mis à jour';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get localizationUpdated => 'Paramètres de localisation mis à jour';

  @override
  String get failedToUpdate => 'Échec de la mise à jour. Veuillez réessayer.';

  @override
  String get noData => 'Aucune donnée disponible';

  @override
  String get retry => 'Réessayer';

  @override
  String get confirmDiscard => 'Abandonner les modifications non enregistrées?';

  @override
  String confirmDiscardMessage(String tab) {
    return '$tab contient des modifications non enregistrées. L\'abandon perdra ces modifications.';
  }
}
