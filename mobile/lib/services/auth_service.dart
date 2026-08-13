class AuthService {
  static String? accessToken;

  static void saveToken(String token) {
    accessToken = token;
  }

  static void clearToken() {
    accessToken = null;
  }

  static bool get isLoggedIn {
    return accessToken != null;
  }
}