import 'package:flutter/material.dart';
import '../routes/rutas.dart';
import '../pages/pantalla_principal_busqueda.dart';
import '../services/auth_service.dart';
import '../pages/pantalla_principal_encargos.dart';
import '../pages/pantalla_principal_mensajes.dart';
import '../pages/pantalla_principal_perfil.dart';
import '../pages/pantalla_promociones.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indexActual = 0;

  final List<Widget> _pantallas = const [
    PantallaBusqueda(),
    PantallaEncargos(),
    PantallaMensajes(),
    PantallaPerfil(),
    PantallaPromociones(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indexActual,
        children: _pantallas,
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _indexActual,
        onTap: (index) {
          setState(() {
            _indexActual = index;
          });
        },
      ),
    );
  }
}

class AppBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomBar({super.key, required this.currentIndex, this.onTap});

  @override
  State<AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<AppBottomBar> {
  final AuthService _authService = AuthService();
  bool _esAdmin = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _chequearAdmin();
  }

  Future<void> _chequearAdmin() async {
    try {
      final isAdmin = await _authService.isAdmin();
      setState(() {
        _esAdmin = isAdmin;
        _cargando = false;
      });
    } catch (_) {
      setState(() {
        _esAdmin = false;
        _cargando = false;
      });
    }
  }

  void _defaultNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Rutas.busqueda);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Rutas.encargos);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Rutas.mensajes);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Rutas.perfil);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, Rutas.promociones);
        break;
      case 5:
        Navigator.pushReplacementNamed(context, Rutas.administracionUsuarios);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Búsqueda',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: 'Encargos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Mensajes',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.star),
        label: 'Promociones',
      ),
    ];

    if (_esAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Administración',
        ),
      );
    }

    // Ajuste para que no falle si currentIndex es mayor que items-1.
    final currentIndex = widget.currentIndex < items.length
        ? widget.currentIndex
        : 0;

    return BottomNavigationBar(
      currentIndex: _cargando ? 0 : currentIndex,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (widget.onTap != null) {
          widget.onTap!(index);
        } else {
          _defaultNavigate(context, index);
        }
      },
      items: items,
    );
  }
}