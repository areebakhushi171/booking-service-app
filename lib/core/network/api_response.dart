/// Parsed API response. [data] is the decoded JSON body
/// (Map, List or null for 204 responses).
class ApiResponse {
  final int statusCode;
  final dynamic data;

  const ApiResponse(this.statusCode, this.data);

  Map<String, dynamic> get asMap => data is Map<String, dynamic>
      ? data as Map<String, dynamic>
      : const <String, dynamic>{};

  List<dynamic> get asList => data is List ? data as List<dynamic> : const [];
}
