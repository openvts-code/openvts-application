import 'admin_user_details_model.dart';

enum AdminUserDetailsTab {
  profile,
  vehicles,
  drivers,
  documents,
  tickets,
  payments,
  logs,
}

class AdminUserDetailsState {
  const AdminUserDetailsState({
    required this.userId,
    required this.user,
    required this.initialUser,
    required this.selectedTab,
    required this.linkedVehicles,
    required this.availableVehicles,
    required this.linkedDrivers,
    required this.availableDrivers,
    required this.documents,
    required this.documentTypes,
    required this.tickets,
    required this.selectedTicket,
    required this.payments,
    required this.paymentsPage,
    required this.logs,
    required this.logsNextCursorId,
    required this.logsHasMore,
    required this.logSearch,
    required this.logActionPrefix,
    required this.logFrom,
    required this.logTo,
    required this.isLoadingProfile,
    required this.isLoadingVehicles,
    required this.isLoadingDrivers,
    required this.isLoadingDocuments,
    required this.isLoadingDocumentTypes,
    required this.isLoadingTickets,
    required this.isLoadingTicketDetails,
    required this.isLoadingPayments,
    required this.isLoadingLogs,
    required this.isLoadingMoreLogs,
    required this.isSavingProfile,
    required this.isUpdatingStatus,
    required this.isChangingPassword,
    required this.isSavingCompany,
    required this.isLinkingVehicle,
    required this.isUnlinkingVehicle,
    required this.isLinkingDriver,
    required this.isUnlinkingDriver,
    required this.isUploadingDocument,
    required this.isUpdatingDocument,
    required this.isDeletingDocument,
    required this.isCreatingTicket,
    required this.isReplyingTicket,
    required this.isUpdatingTicketStatus,
    required this.isRenewingPayment,
    required this.errorMessage,
    required this.sectionErrorMessage,
  });

  AdminUserDetailsState.initial({
    required this.userId,
    this.initialUser,
  })  : user = null,
        selectedTab = AdminUserDetailsTab.profile,
        linkedVehicles = const <AdminUserVehicle>[],
        availableVehicles = const <AdminUserVehicle>[],
        linkedDrivers = const <AdminUserDriver>[],
        availableDrivers = const <AdminUserDriver>[],
        documents = const <AdminUserDocument>[],
        documentTypes = const <AdminDocumentTypeOption>[],
        tickets = const <AdminUserTicket>[],
        selectedTicket = null,
        payments = const <AdminUserPayment>[],
        paymentsPage = null,
        logs = const <AdminUserActivityLog>[],
        logsNextCursorId = null,
        logsHasMore = false,
        logSearch = '',
        logActionPrefix = '',
        logFrom = null,
        logTo = null,
        isLoadingProfile = false,
        isLoadingVehicles = false,
        isLoadingDrivers = false,
        isLoadingDocuments = false,
        isLoadingDocumentTypes = false,
        isLoadingTickets = false,
        isLoadingTicketDetails = false,
        isLoadingPayments = false,
        isLoadingLogs = false,
        isLoadingMoreLogs = false,
        isSavingProfile = false,
        isUpdatingStatus = false,
        isChangingPassword = false,
        isSavingCompany = false,
        isLinkingVehicle = false,
        isUnlinkingVehicle = false,
        isLinkingDriver = false,
        isUnlinkingDriver = false,
        isUploadingDocument = false,
        isUpdatingDocument = false,
        isDeletingDocument = false,
        isCreatingTicket = false,
        isReplyingTicket = false,
        isUpdatingTicketStatus = false,
        isRenewingPayment = false,
        errorMessage = null,
        sectionErrorMessage = null;

  static const Object _unset = Object();

  final String userId;
  final AdminUserDetails? user;
  final AdminUserDetails? initialUser;
  final AdminUserDetailsTab selectedTab;
  final List<AdminUserVehicle> linkedVehicles;
  final List<AdminUserVehicle> availableVehicles;
  final List<AdminUserDriver> linkedDrivers;
  final List<AdminUserDriver> availableDrivers;
  final List<AdminUserDocument> documents;
  final List<AdminDocumentTypeOption> documentTypes;
  final List<AdminUserTicket> tickets;
  final AdminUserTicket? selectedTicket;
  final List<AdminUserPayment> payments;
  final AdminUserPaymentPage? paymentsPage;
  final List<AdminUserActivityLog> logs;
  final int? logsNextCursorId;
  final bool logsHasMore;
  final String logSearch;
  final String logActionPrefix;
  final DateTime? logFrom;
  final DateTime? logTo;
  final bool isLoadingProfile;
  final bool isLoadingVehicles;
  final bool isLoadingDrivers;
  final bool isLoadingDocuments;
  final bool isLoadingDocumentTypes;
  final bool isLoadingTickets;
  final bool isLoadingTicketDetails;
  final bool isLoadingPayments;
  final bool isLoadingLogs;
  final bool isLoadingMoreLogs;
  final bool isSavingProfile;
  final bool isUpdatingStatus;
  final bool isChangingPassword;
  final bool isSavingCompany;
  final bool isLinkingVehicle;
  final bool isUnlinkingVehicle;
  final bool isLinkingDriver;
  final bool isUnlinkingDriver;
  final bool isUploadingDocument;
  final bool isUpdatingDocument;
  final bool isDeletingDocument;
  final bool isCreatingTicket;
  final bool isReplyingTicket;
  final bool isUpdatingTicketStatus;
  final bool isRenewingPayment;
  final String? errorMessage;
  final String? sectionErrorMessage;

  bool get hasProfile => user != null;
  bool get hasLoadedVehicles => linkedVehicles.isNotEmpty || availableVehicles.isNotEmpty;
  bool get hasLoadedDrivers => linkedDrivers.isNotEmpty || availableDrivers.isNotEmpty;
  bool get hasLoadedDocuments => documents.isNotEmpty || documentTypes.isNotEmpty;
  bool get hasLoadedTickets => tickets.isNotEmpty || selectedTicket != null;
  bool get hasLoadedPayments => paymentsPage != null;
  bool get hasLoadedLogs => logs.isNotEmpty || logsNextCursorId != null;

  /// Resolved isActive that preserves known status from initialUser.
  /// Priority: detail response > initialUser > default true
  bool get effectiveIsActive {
    // If we have detail data, use it
    if (user != null) return user!.isActive;
    // Fallback to initial list item
    if (initialUser != null) return initialUser!.isActive;
    // Default
    return true;
  }

  /// Resolved vehicle count that avoids overwriting known count with 0.
  /// Priority: explicit vehicles tab count > detail response if > 0 > initialUser > linked vehicles count
  int? get resolvedVehicleCount {
    // If vehicles tab has been loaded, use actual count
    if (hasLoadedVehicles) return linkedVehicles.length;
    // If detail has vehicle count > 0, use it
    if (user != null && user!.vehicleCount > 0) return user!.vehicleCount;
    // If initial list item had a count > 0, use it
    if (initialUser != null && initialUser!.vehicleCount > 0) {
      return initialUser!.vehicleCount;
    }
    // Return null if unknown (don't default to 0)
    return null;
  }

  /// Resolved last login from updatedAt.
  /// Priority: detail updatedAt > initialUser updatedAt
  DateTime? get resolvedLastLogin {
    if (user?.updatedAt != null) return user!.updatedAt;
    if (initialUser?.updatedAt != null) return initialUser!.updatedAt;
    return null;
  }

  AdminUserDetailsState copyWith({
    Object? user = _unset,
    Object? initialUser = _unset,
    AdminUserDetailsTab? selectedTab,
    List<AdminUserVehicle>? linkedVehicles,
    List<AdminUserVehicle>? availableVehicles,
    List<AdminUserDriver>? linkedDrivers,
    List<AdminUserDriver>? availableDrivers,
    List<AdminUserDocument>? documents,
    List<AdminDocumentTypeOption>? documentTypes,
    List<AdminUserTicket>? tickets,
    Object? selectedTicket = _unset,
    List<AdminUserPayment>? payments,
    Object? paymentsPage = _unset,
    List<AdminUserActivityLog>? logs,
    Object? logsNextCursorId = _unset,
    bool? logsHasMore,
    String? logSearch,
    String? logActionPrefix,
    Object? logFrom = _unset,
    Object? logTo = _unset,
    bool? isLoadingProfile,
    bool? isLoadingVehicles,
    bool? isLoadingDrivers,
    bool? isLoadingDocuments,
    bool? isLoadingDocumentTypes,
    bool? isLoadingTickets,
    bool? isLoadingTicketDetails,
    bool? isLoadingPayments,
    bool? isLoadingLogs,
    bool? isLoadingMoreLogs,
    bool? isSavingProfile,
    bool? isUpdatingStatus,
    bool? isChangingPassword,
    bool? isSavingCompany,
    bool? isLinkingVehicle,
    bool? isUnlinkingVehicle,
    bool? isLinkingDriver,
    bool? isUnlinkingDriver,
    bool? isUploadingDocument,
    bool? isUpdatingDocument,
    bool? isDeletingDocument,
    bool? isCreatingTicket,
    bool? isReplyingTicket,
    bool? isUpdatingTicketStatus,
    bool? isRenewingPayment,
    Object? errorMessage = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return AdminUserDetailsState(
      userId: userId,
      user: identical(user, _unset) ? this.user : user as AdminUserDetails?,
      initialUser:
          identical(initialUser, _unset) ? this.initialUser : initialUser as AdminUserDetails?,
      selectedTab: selectedTab ?? this.selectedTab,
      linkedVehicles: linkedVehicles ?? this.linkedVehicles,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      linkedDrivers: linkedDrivers ?? this.linkedDrivers,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      documents: documents ?? this.documents,
      documentTypes: documentTypes ?? this.documentTypes,
      tickets: tickets ?? this.tickets,
      selectedTicket: identical(selectedTicket, _unset)
          ? this.selectedTicket
          : selectedTicket as AdminUserTicket?,
      payments: payments ?? this.payments,
      paymentsPage: identical(paymentsPage, _unset)
          ? this.paymentsPage
          : paymentsPage as AdminUserPaymentPage?,
      logs: logs ?? this.logs,
      logsNextCursorId:
          identical(logsNextCursorId, _unset) ? this.logsNextCursorId : logsNextCursorId as int?,
      logsHasMore: logsHasMore ?? this.logsHasMore,
      logSearch: logSearch ?? this.logSearch,
      logActionPrefix: logActionPrefix ?? this.logActionPrefix,
      logFrom: identical(logFrom, _unset) ? this.logFrom : logFrom as DateTime?,
      logTo: identical(logTo, _unset) ? this.logTo : logTo as DateTime?,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isLoadingDrivers: isLoadingDrivers ?? this.isLoadingDrivers,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingDocumentTypes: isLoadingDocumentTypes ?? this.isLoadingDocumentTypes,
      isLoadingTickets: isLoadingTickets ?? this.isLoadingTickets,
      isLoadingTicketDetails: isLoadingTicketDetails ?? this.isLoadingTicketDetails,
      isLoadingPayments: isLoadingPayments ?? this.isLoadingPayments,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      isLoadingMoreLogs: isLoadingMoreLogs ?? this.isLoadingMoreLogs,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isSavingCompany: isSavingCompany ?? this.isSavingCompany,
      isLinkingVehicle: isLinkingVehicle ?? this.isLinkingVehicle,
      isUnlinkingVehicle: isUnlinkingVehicle ?? this.isUnlinkingVehicle,
      isLinkingDriver: isLinkingDriver ?? this.isLinkingDriver,
      isUnlinkingDriver: isUnlinkingDriver ?? this.isUnlinkingDriver,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      isUpdatingDocument: isUpdatingDocument ?? this.isUpdatingDocument,
      isDeletingDocument: isDeletingDocument ?? this.isDeletingDocument,
      isCreatingTicket: isCreatingTicket ?? this.isCreatingTicket,
      isReplyingTicket: isReplyingTicket ?? this.isReplyingTicket,
      isUpdatingTicketStatus: isUpdatingTicketStatus ?? this.isUpdatingTicketStatus,
      isRenewingPayment: isRenewingPayment ?? this.isRenewingPayment,
      errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
