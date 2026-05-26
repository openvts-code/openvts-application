class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.data,
    this.message,
    this.timestamp,
  });

  final bool success;
  final T data;
  final String? message;
  final String? timestamp;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) parser,
  ) {
    final status = json['status']?.toString().toLowerCase();
    final rootAction = json['action'];
    final statusIsSuccess = status == 'success' || status == 'ok';
    final statusIsFailure = status == 'error' ||
        status == 'failed' ||
        status == 'fail' ||
        json['success'] == false;
    var success = statusIsSuccess || json['success'] == true;
    if (rootAction is bool) {
      success = statusIsFailure
          ? false
          : (success ? success && rootAction : rootAction);
    }
    final timestamp = json['timestamp']?.toString();

    final envelopeData = json['data'];
    String? message;
    dynamic payload = envelopeData;

    if (envelopeData is Map<String, dynamic>) {
      final action = envelopeData['action'];
      if (action is bool) {
        success = success && action;
      }

      message =
          envelopeData['message']?.toString() ?? json['message']?.toString();
      if (envelopeData.containsKey('data')) {
        payload = envelopeData['data'];
      }
    } else {
      payload ??= json;
      message = json['message']?.toString();
    }

    return ApiResponse<T>(
      success: success,
      data: parser(payload),
      message: message,
      timestamp: timestamp,
    );
  }
}
