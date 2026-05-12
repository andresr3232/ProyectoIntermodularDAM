import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, {this.code = ''});

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream para escuchar cambios en la autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _firebaseAuth.currentUser;

  // Login con email y contraseña
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthException(e), code: e.code);
    } catch (e) {
      throw AuthException('Error desconocido al iniciar sesión.');
    }
  }

  // Registro con email y contraseña
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthException(e), code: e.code);
    } catch (e) {
      throw AuthException('Error desconocido al registrar usuario.');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Obtener perfil del usuario desde Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .get();

      return doc.data();
    } catch (e) {
      throw AuthException('Error al obtener perfil del usuario.');
    }
  }

  // Stream de perfil del usuario (para actualizaciones en tiempo real)
  Stream<Map<String, dynamic>?> getUserProfileStream() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return data;
        });
  }

  /// Buscar usuarios por nombre, nombre de usuario o correo (case-insensitive)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance.collection('Usuarios').get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        })
        .where((data) {
          final nombre = (data['nombre'] ?? '').toString().toLowerCase();
          final nombreUsuario = (data['nombreUsuario'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return nombre.contains(q) || nombreUsuario.contains(q) || email.contains(q);
        })
        .toList();
  }

Future<Map<String, dynamic>?> getUserProfileByUid(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uid)
        .get();

    return doc.data();
  } catch (e) {
    throw AuthException('Error al obtener perfil del usuario.');
  }
}

  Stream<Map<String, dynamic>?> getUserProfileStreamByUid(String uid) {
  return FirebaseFirestore.instance
      .collection("Usuarios")
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data());
}

  Future<bool> isAdmin() async {
    final profile = await getUserProfile();
    if (profile == null) return false;
    return (profile['rol'] as String?)?.toLowerCase() == 'administrador';
  }

  // Recuperar contraseña
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthException(e), code: e.code);
    } catch (e) {
      throw AuthException('Error desconocido al solicitar recuperación de contraseña.');
    }
  }

  // Manejar excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos de inicio de sesión. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return e.message ?? 'Error de autenticación.';
    }
  }

Future<String> getUsuarioDocId() async {
  final user = currentUser;
  if (user == null) throw Exception('Usuario no autenticado');

  return user.uid;
}
}