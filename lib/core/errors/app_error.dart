class AppError {
  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  final String message;
  final String? code;
  final Object? originalError;
}
