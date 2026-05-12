import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/promocion.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_bar.dart';

class PlanPromocion {
  final String titulo;
  final String precioTexto;
  final int duracionDias;
  final double monto;
  final Color color;

  PlanPromocion({
    required this.titulo,
    required this.precioTexto,
    required this.duracionDias,
    required this.monto,
    required this.color,
  });
}

int _indexActual = 4;

class PantallaPromociones extends StatefulWidget {
  const PantallaPromociones({super.key});

  @override
  State<PantallaPromociones> createState() => _PantallaPromocionesState();
}

class _PantallaPromocionesState extends State<PantallaPromociones> {
  final AuthService _authService = AuthService();

  final List<PlanPromocion> _planes = [
    PlanPromocion(
      titulo: 'Plan básico',
      precioTexto: '2,99 €',
      duracionDias: 7,
      monto: 0.0,
      color: Colors.orange,
    ),
    PlanPromocion(
      titulo: 'Plan estándar',
      precioTexto: '4,99 €',
      duracionDias: 15,
      monto: 0.0,
      color: Colors.red,
    ),
    PlanPromocion(
      titulo: 'Plan premium',
      precioTexto: '8,99 €',
      duracionDias: 30,
      monto: 0.0,
      color: const Color(0xFF8B0000),
    ),
  ];

  Future<Promocion?> _obtenerPromocionActiva(String usuarioId) async {
    final ahora = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('Promociones')
        .where('usuarioIdEmisor', isEqualTo: usuarioId)
        .where('fechaFin', isGreaterThan: Timestamp.fromDate(ahora))
        .get();

    if (snapshot.docs.isEmpty) return null;

    // Elegimos la promoción con fecha de fin más lejana (si hay varias)
    final docsOrdenados = snapshot.docs.toList()
      ..sort((a, b) {
        final fa = (a.data()['fechaFin'] as Timestamp).toDate();
        final fb = (b.data()['fechaFin'] as Timestamp).toDate();
        return fa.compareTo(fb);
      });

    final doc = docsOrdenados.last;
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = doc.id;
    return Promocion.fromMap(data);
  }

  Future<void> _mostrarDialogoCompra(PlanPromocion plan) async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para crear una promoción.')),
      );
      return;
    }

    final promocionActiva = await _obtenerPromocionActiva(usuario.uid);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Seleccionar ${plan.titulo}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Precio: ${plan.precioTexto} (gratis para probar)'),
              Text('Duración: ${plan.duracionDias} días'),
              const SizedBox(height: 12),
              if (promocionActiva != null) ...[
                Text(
                  'Ya tienes una promoción activa hasta ${promocionActiva.fechaFin.day.toString().padLeft(2, '0')}/${promocionActiva.fechaFin.month.toString().padLeft(2, '0')}/${promocionActiva.fechaFin.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Podrás activar este plan al finalizar la promoción actual.'),
              ] else ...[
                const Text('Al confirmar se activará la promoción en tu cuenta.'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            if (promocionActiva == null) ...[
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ]
          ],
        );
      },
    );

    if (confirmado == true) {
      await _comprarPromocion(plan);
    }
  }

  Future<void> _comprarPromocion(PlanPromocion plan) async {
    final usuario = _authService.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para crear una promoción.')),
      );
      return;
    }

    final inicio = DateTime.now();
    final fin = inicio.add(Duration(days: plan.duracionDias));
    final id = FirebaseFirestore.instance.collection('Promociones').doc().id;

    final promocion = Promocion(
      id: id,
      cantidadPagado: 0.0,
      fechaInicio: inicio,
      fechaFin: fin,
      usuarioIdEmisor: usuario.uid,
    );

    try {
      await FirebaseFirestore.instance.collection('Promociones').doc(id).set(promocion.toMap());

      // Asociar promocion también en subcolección de Usuario (opcional pero pedido explícitamente)
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(usuario.uid)
          .collection('MisPromociones')
          .doc(id)
          .set(promocion.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.titulo} activado correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando promoción: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Promociones', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner superior
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    '¡Destaca entre los demás!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Con una promoción, tus servicios y tu perfil aparecerán primero en los resultados de búsqueda.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              '¿Qué incluye?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _ventaja(Icons.trending_up, 'Apareces primero en búsquedas por categoría'),
            _ventaja(Icons.person_search, 'Tu perfil se muestra antes en la búsqueda de usuarios'),
            _ventaja(Icons.visibility, 'Mayor visibilidad frente a otros usuarios'),
            _ventaja(Icons.timer, 'Duración configurable según el plan elegido'),

            const SizedBox(height: 28),

            const Text(
              'Planes disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            for (final plan in _planes) ...[
              _planCard(plan),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 32),
            const Text(
              'Puedes probar cualquier plan gratis. El seguimiento se guarda como promoción activa en tu perfil.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(currentIndex: _indexActual),
    );
  }

  Widget _ventaja(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _planCard(PlanPromocion plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: plan.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: plan.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, color: plan.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${plan.duracionDias} días', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.precioTexto,
                style: TextStyle(
                  color: plan.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: plan.color,
                    side: BorderSide(color: plan.color),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _mostrarDialogoCompra(plan),
                  child: const Text('Probar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
