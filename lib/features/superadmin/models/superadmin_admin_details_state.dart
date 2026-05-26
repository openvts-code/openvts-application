import '../../superadmin/models/superadmin_payments_model.dart';
import 'superadmin_admin_details_model.dart';

enum SuperadminAdminDetailsTab {
  profile,
  creditHistory,
  payments,
  documents,
  vehicles,
  adminActivity,
}

class SuperadminAdminDetailsState {
  const SuperadminAdminDetailsState({
    required this.adminId,
    required this.admin,
    required this.selectedTab,
    required this.creditLogs,
    required this.transactions,
    required this.transactionAnalytics,
    required this.paymentsPage,
    required this.paymentsHasMore,
    required this.paymentsFrom,
    required this.paymentsTo,
    required this.documents,
    required this.documentTypes,
    required this.vehicles,
    required this.activityLogs,
    required this.activityNextCursorId,
    required this.activityHasMore,
    required this.activitySearch,
    required this.activityActionPrefix,
    required this.activityFrom,
    required this.activityTo,
    required this.isLoadingAdmin,
    required this.isSavingProfile,
    required this.isUpdatingStatus,
    required this.isChangingPassword,
    required this.isSavingCompany,
    required this.isLoadingCredits,
    required this.isUpdatingCredits,
    required this.isLoadingPayments,
    required this.isLoadingMorePayments,
    required this.isRecordingPayment,
    required this.isLoadingDocuments,
    required this.isLoadingDocumentTypes,
    required this.isUploadingDocument,
    required this.isDeletingDocument,
    required this.isLoadingVehicles,
    required this.isLoadingActivity,
    required this.isLoadingMoreActivity,
    required this.isDeletingAdmin,
    required this.errorMessage,
    required this.sectionErrorMessage,
  });

  SuperadminAdminDetailsState.initial({required this.adminId})
      : admin = null,
        selectedTab = SuperadminAdminDetailsTab.profile,
        creditLogs = const <SuperadminCreditLog>[],
        transactions = const <SuperadminTransaction>[],
        transactionAnalytics = null,
        paymentsPage = 1,
        paymentsHasMore = false,
        paymentsFrom = null,
        paymentsTo = null,
        documents = const <SuperadminAdminDocument>[],
        documentTypes = const <SuperadminDocumentTypeOption>[],
        vehicles = const <SuperadminAdminVehicle>[],
        activityLogs = const <SuperadminAdminActivityLog>[],
        activityNextCursorId = null,
        activityHasMore = false,
        activitySearch = '',
        activityActionPrefix = '',
        activityFrom = null,
        activityTo = null,
        isLoadingAdmin = false,
        isSavingProfile = false,
        isUpdatingStatus = false,
        isChangingPassword = false,
        isSavingCompany = false,
        isLoadingCredits = false,
        isUpdatingCredits = false,
        isLoadingPayments = false,
        isLoadingMorePayments = false,
        isRecordingPayment = false,
        isLoadingDocuments = false,
        isLoadingDocumentTypes = false,
        isUploadingDocument = false,
        isDeletingDocument = false,
        isLoadingVehicles = false,
        isLoadingActivity = false,
        isLoadingMoreActivity = false,
        isDeletingAdmin = false,
        errorMessage = null,
        sectionErrorMessage = null;

  static const Object _unset = Object();

  final String adminId;
  final SuperadminAdminDetails? admin;
  final SuperadminAdminDetailsTab selectedTab;
  final List<SuperadminCreditLog> creditLogs;
  final List<SuperadminTransaction> transactions;
  final SuperadminTransactionsAnalytics? transactionAnalytics;
  final int paymentsPage;
  final bool paymentsHasMore;
  final DateTime? paymentsFrom;
  final DateTime? paymentsTo;
  final List<SuperadminAdminDocument> documents;
  final List<SuperadminDocumentTypeOption> documentTypes;
  final List<SuperadminAdminVehicle> vehicles;
  final List<SuperadminAdminActivityLog> activityLogs;
  final int? activityNextCursorId;
  final bool activityHasMore;
  final String activitySearch;
  final String activityActionPrefix;
  final DateTime? activityFrom;
  final DateTime? activityTo;
  final bool isLoadingAdmin;
  final bool isSavingProfile;
  final bool isUpdatingStatus;
  final bool isChangingPassword;
  final bool isSavingCompany;
  final bool isLoadingCredits;
  final bool isUpdatingCredits;
  final bool isLoadingPayments;
  final bool isLoadingMorePayments;
  final bool isRecordingPayment;
  final bool isLoadingDocuments;
  final bool isLoadingDocumentTypes;
  final bool isUploadingDocument;
  final bool isDeletingDocument;
  final bool isLoadingVehicles;
  final bool isLoadingActivity;
  final bool isLoadingMoreActivity;
  final bool isDeletingAdmin;
  final String? errorMessage;
  final String? sectionErrorMessage;

  SuperadminAdminDetailsState copyWith({
    Object? admin = _unset,
    SuperadminAdminDetailsTab? selectedTab,
    List<SuperadminCreditLog>? creditLogs,
    List<SuperadminTransaction>? transactions,
    Object? transactionAnalytics = _unset,
    int? paymentsPage,
    bool? paymentsHasMore,
    Object? paymentsFrom = _unset,
    Object? paymentsTo = _unset,
    List<SuperadminAdminDocument>? documents,
    List<SuperadminDocumentTypeOption>? documentTypes,
    List<SuperadminAdminVehicle>? vehicles,
    List<SuperadminAdminActivityLog>? activityLogs,
    Object? activityNextCursorId = _unset,
    bool? activityHasMore,
    String? activitySearch,
    String? activityActionPrefix,
    Object? activityFrom = _unset,
    Object? activityTo = _unset,
    bool? isLoadingAdmin,
    bool? isSavingProfile,
    bool? isUpdatingStatus,
    bool? isChangingPassword,
    bool? isSavingCompany,
    bool? isLoadingCredits,
    bool? isUpdatingCredits,
    bool? isLoadingPayments,
    bool? isLoadingMorePayments,
    bool? isRecordingPayment,
    bool? isLoadingDocuments,
    bool? isLoadingDocumentTypes,
    bool? isUploadingDocument,
    bool? isDeletingDocument,
    bool? isLoadingVehicles,
    bool? isLoadingActivity,
    bool? isLoadingMoreActivity,
    bool? isDeletingAdmin,
    Object? errorMessage = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return SuperadminAdminDetailsState(
      adminId: adminId,
      admin: identical(admin, _unset) ? this.admin : admin as SuperadminAdminDetails?,
      selectedTab: selectedTab ?? this.selectedTab,
      creditLogs: creditLogs ?? this.creditLogs,
      transactions: transactions ?? this.transactions,
      transactionAnalytics: identical(transactionAnalytics, _unset)
          ? this.transactionAnalytics
          : transactionAnalytics as SuperadminTransactionsAnalytics?,
      paymentsPage: paymentsPage ?? this.paymentsPage,
      paymentsHasMore: paymentsHasMore ?? this.paymentsHasMore,
      paymentsFrom: identical(paymentsFrom, _unset)
          ? this.paymentsFrom
          : paymentsFrom as DateTime?,
      paymentsTo: identical(paymentsTo, _unset)
          ? this.paymentsTo
          : paymentsTo as DateTime?,
      documents: documents ?? this.documents,
      documentTypes: documentTypes ?? this.documentTypes,
      vehicles: vehicles ?? this.vehicles,
      activityLogs: activityLogs ?? this.activityLogs,
      activityNextCursorId: identical(activityNextCursorId, _unset)
          ? this.activityNextCursorId
          : activityNextCursorId as int?,
      activityHasMore: activityHasMore ?? this.activityHasMore,
      activitySearch: activitySearch ?? this.activitySearch,
      activityActionPrefix: activityActionPrefix ?? this.activityActionPrefix,
      activityFrom: identical(activityFrom, _unset)
          ? this.activityFrom
          : activityFrom as DateTime?,
      activityTo:
          identical(activityTo, _unset) ? this.activityTo : activityTo as DateTime?,
      isLoadingAdmin: isLoadingAdmin ?? this.isLoadingAdmin,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isSavingCompany: isSavingCompany ?? this.isSavingCompany,
      isLoadingCredits: isLoadingCredits ?? this.isLoadingCredits,
      isUpdatingCredits: isUpdatingCredits ?? this.isUpdatingCredits,
      isLoadingPayments: isLoadingPayments ?? this.isLoadingPayments,
      isLoadingMorePayments:
          isLoadingMorePayments ?? this.isLoadingMorePayments,
      isRecordingPayment: isRecordingPayment ?? this.isRecordingPayment,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingDocumentTypes:
          isLoadingDocumentTypes ?? this.isLoadingDocumentTypes,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      isDeletingDocument: isDeletingDocument ?? this.isDeletingDocument,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isLoadingActivity: isLoadingActivity ?? this.isLoadingActivity,
      isLoadingMoreActivity:
          isLoadingMoreActivity ?? this.isLoadingMoreActivity,
      isDeletingAdmin: isDeletingAdmin ?? this.isDeletingAdmin,
      errorMessage:
          identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
