import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Koneksi ke server timeout. Silakan periksa jaringan Anda.',
        );
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          final data = response.data;
          String msg = 'Terjadi kesalahan pada server (${response.statusCode}).';
          Map<String, dynamic>? errors;

          if (data is Map<String, dynamic>) {
            if (data.containsKey('message') && data['message'] is String) {
              msg = data['message'];
            }
            if (data.containsKey('errors') && data['errors'] is Map) {
              errors = Map<String, dynamic>.from(data['errors']);
              // If message is generic, get first error
              if (errors.isNotEmpty) {
                final firstErr = errors.values.first;
                if (firstErr is List && firstErr.isNotEmpty) {
                  msg = firstErr.first.toString();
                }
              }
            }
          }
          return ApiException(
            message: msg,
            statusCode: response.statusCode,
            errors: errors,
          );
        }
        return ApiException(message: 'Respon server tidak valid.');
      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Gagal terhubung ke server backend. Pastikan server aktif dan alamat IP sudah sesuai.',
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Permintaan dibatalkan.');
      default:
        return ApiException(
          message: error.message ?? 'Terjadi kesalahan tak terduga.',
        );
    }
  }

  @override
  String toString() => message;
}
