part of flutter_data;

class DataException implements Exception {
  final Object errors;
  final int status;
  const DataException([this.errors = const [], this.status]);

  @override
  String toString() {
    return 'DataException: [HTTP $status] ${errors is Iterable ? (errors as Iterable).map((e) => e is JsonApiError ? e.toJson() : e.toString()).join(', ') : errors}';
  }
}
