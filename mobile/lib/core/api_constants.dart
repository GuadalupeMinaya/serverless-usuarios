class ApiConstants {
  // URL del backend. Por defecto usa AWS (app movil).
  // Para la version web en Kubernetes se compila con:
  //   --dart-define=API_URL=http://localhost
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://okgp3w2mvf.execute-api.us-east-1.amazonaws.com',
  );
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String usuarios = '/api/usuarios';
  static const String upload = '/upload';
  static const String notificationsSend = '/notifications/send';
}
