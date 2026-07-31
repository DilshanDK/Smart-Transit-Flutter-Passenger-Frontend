abstract class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String fullName;
  final String password;
  const RegisterRequested({
    required this.email,
    required this.fullName,
    required this.password,
  });
}

class GoogleLoginRequested extends AuthEvent {
  final String idToken;
  const GoogleLoginRequested(this.idToken);
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
