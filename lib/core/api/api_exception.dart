enum Failure {
  network,
  timeout,
  auth,
  rate,
  server,
  json,
  config,
  unknown,
  storage,
}

class ApiException implements Exception {
  const ApiException(this.failure);
  final Failure failure;
}
