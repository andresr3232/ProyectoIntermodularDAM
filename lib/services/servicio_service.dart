import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/servicio.dart';
import '../models/intercambio.dart';

class ServicioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUsuarioById(String uid) async {
    final doc = await _firestore.collection('Usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> actualizarServiciosOfrece(List<String> servicios) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Usuario no autenticado.');
    await _firestore.collection('Usuarios').doc(user.uid).update({
      'serviciosOfrece': servicios,
    });
  }

  Future<void> actualizarServiciosBusca(List<String> servicios) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Usuario no autenticado.');
    await _firestore.collection('Usuarios').doc(user.uid).update({
      'serviciosBusca': servicios,
    });
  }

  Future<void> agregarServicioOfrece(String servicio) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Usuario no autenticado.');
    await _firestore.collection('Usuarios').doc(user.uid).update({
      'serviciosOfrece': FieldValue.arrayUnion([servicio]),
    });
  }

  Future<void> eliminarServicioOfrece(String servicio) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Usuario no autenticado.');
    await _firestore.collection('Usuarios').doc(user.uid).update({
      'serviciosOfrece': FieldValue.arrayRemove([servicio]),
    });
  }

  Future<void> agregarServicioBusca(String servicio) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Usuario no autenticado.');
    await _firestore.collection('Usuarios').doc(user.uid).update({
      'serviciosBusca': FieldValue.arrayUnion([servicio]),
    });
  }

  Future<void> eliminarServicioBusca(String servicio) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Usuario no autenticado.');
    await _firestore.collection('Usuarios').doc(user.uid).update({
      'serviciosBusca': FieldValue.arrayRemove([servicio]),
    });
  }

  Future<void> crearServicio(Servicio servicio) async {
    await _firestore
        .collection('Servicios')
        .doc(servicio.id)
        .set(servicio.toMap());
  }

  Future<Servicio?> getServicioById(String servicioId) async {
    final doc = await _firestore.collection('Servicios').doc(servicioId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Servicio.fromMap(data);
  }

  Stream<List<Servicio>> getServiciosUsuarioByDocId(String usuarioDocId) {
    return _firestore
        .collection('Servicios')
        .where('usuarioId', isEqualTo: usuarioDocId)
        .orderBy('fechaPublicacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Servicio.fromMap(data);
            }).toList());
  }

  Stream<List<Servicio>> getServiciosPorCategoria(String categoria) {
    return _firestore
        .collection('Servicios')
        .where('categoria', isEqualTo: categoria)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Servicio.fromMap(data);
            }).toList());
  }

  Future<bool> usuarioTienePromocionActiva(String usuarioId) async {
    final ahora = DateTime.now();

    final snapshot = await _firestore
        .collection('Promociones')
        .where('usuarioIdEmisor', isEqualTo: usuarioId)
        .where('fechaFin', isGreaterThan: Timestamp.fromDate(ahora))
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> cambiarEstadoServicio(String servicioId, bool activo) async {
    await _firestore
        .collection('Servicios')
        .doc(servicioId)
        .update({'activo': activo});
  }

  Future<void> actualizarServicio(Servicio servicio) async {
    await _firestore
        .collection('Servicios')
        .doc(servicio.id)
        .update(servicio.toMap());
  }

  Future<void> eliminarServicio(String servicioId) async {
    await _firestore.collection('Servicios').doc(servicioId).delete();
  }

  Future<void> crearIntercambio({
    required String usuarioIdOfertante,
    required String usuarioIdDemandante,
    required String servicioIdOfertado,
    required String servicioIdDemandado,
  }) async {
    final docRef = _firestore.collection('Intercambios').doc();
    await docRef.set({
      'id': docRef.id,
      'estado': 'pendiente',
      'fechaSolicitud': Timestamp.now(),
      'fechaAceptacion': null,
      'usuarioIdOfertante': usuarioIdOfertante,
      'usuarioIdDemandante': usuarioIdDemandante,
      'servicioIdOfertado': servicioIdOfertado,
      'servicioIdDemandado': servicioIdDemandado,
      'ofertanteConfirmo': false,
      'demandanteConfirmo': false,
      'ofertanteValoro': false,
      'demandanteValoro': false,
    });
  }

  Future<void> actualizarEstadoIntercambio(
      String intercambioId, String nuevoEstado) async {
    final updateData = <String, dynamic>{'estado': nuevoEstado};
    if (nuevoEstado == 'aceptado') {
      updateData['fechaAceptacion'] = Timestamp.now();
    }
    await _firestore
        .collection('Intercambios')
        .doc(intercambioId)
        .update(updateData);
  }

  Stream<List<Intercambio>> getIntercambiosComoOfertante(String uid) {
    return _firestore
        .collection('Intercambios')
        .where('usuarioIdOfertante', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Intercambio.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<Intercambio>> getIntercambiosComoDemandante(String uid) {
    return _firestore
        .collection('Intercambios')
        .where('usuarioIdDemandante', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Intercambio.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> confirmarFinalizacion(String intercambioId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('Intercambios').doc(intercambioId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null) return;

    bool ofertanteConfirmo = data['ofertanteConfirmo'] ?? false;
    bool demandanteConfirmo = data['demandanteConfirmo'] ?? false;

    Map<String, dynamic> update = {};

    if (user.uid == data['usuarioIdOfertante']) {
      ofertanteConfirmo = true;
      update['ofertanteConfirmo'] = true;
    } else {
      demandanteConfirmo = true;
      update['demandanteConfirmo'] = true;
    }

    if (ofertanteConfirmo && demandanteConfirmo) {
      update['estado'] = 'finalizado';
    }

    await docRef.update(update);
  }

  Future<void> crearValoracion({
    required String usuarioReceptorId,
    required int puntuacion,
    required String comentario,
    required String intercambioId,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('Valoraciones').doc();
    await docRef.set({
      'id': docRef.id,
      'usuarioIdEmisor': user.uid,
      'usuarioIdReceptor': usuarioReceptorId,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'intercambioId': intercambioId,
      'fecha': Timestamp.now(),
    });

    final usuarioRef = _firestore.collection('Usuarios').doc(usuarioReceptorId);
    final snapshot = await usuarioRef.get();
    final data = snapshot.data();

    double mediaActual = (data?['mediaValoraciones'] ?? 0).toDouble();
    int totalActual = (data?['totalValoraciones'] ?? 0);
    double nuevaMedia =
        ((mediaActual * totalActual) + puntuacion) / (totalActual + 1);

    await usuarioRef.update({
      'mediaValoraciones': nuevaMedia,
      'totalValoraciones': totalActual + 1,
    });

    final intercambioRef =
        _firestore.collection('Intercambios').doc(intercambioId);
    final intercambio = await intercambioRef.get();
    final dataIntercambio = intercambio.data();

    Map<String, dynamic> update = {};
    if (user.uid == dataIntercambio?['usuarioIdOfertante']) {
      update['ofertanteValoro'] = true;
    } else {
      update['demandanteValoro'] = true;
    }

    await intercambioRef.update(update);
  }
}