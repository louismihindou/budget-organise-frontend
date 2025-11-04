class ApiResponse {
  final bool success;
  final String? message;
  final int? code;
  final data;

  ApiResponse({required this.success, this.message,this.code,this.data});
}