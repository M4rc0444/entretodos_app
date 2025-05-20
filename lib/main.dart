import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'splash_screen.dart';


void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(), // <- Aquí cargamos el splash
  ));
}


class EntretodosApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entre Todos - Alumno',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _mensajeError;

  void _loginAlumno() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    Database db = await DBHelper.openDB();
    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM alumno WHERE correo = ?", [email]);

    if (result.isNotEmpty) {
      String dbPassword = result[0]['contrasena'] ?? '';
      if (dbPassword == password) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              alumnoId: result[0]['id'],
              alumnoNombre:
                  "${result[0]['nombres']} ${result[0]['apellido_paterno']}",
              correo: result[0]['correo'],
            ),
          ),
        );
      } else {
        setState(() => _mensajeError = "Contraseña incorrecta.");
      }
    } else {
      setState(() => _mensajeError = "Correo no encontrado.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/fondo_instalaciones.jpg',
            fit: BoxFit.cover,
          ),
          // Filtro oscuro
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          // Formulario
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo-entretoedos.png',
                          height: 100,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Entre Todos - Alumno",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Correo electrónico",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Contraseña",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loginAlumno,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.blue[800],
                            ),
                            child: const Text("Ingresar",
                                style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_mensajeError != null)
                          Text(
                            _mensajeError!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int alumnoId;
  final String alumnoNombre;
  final String correo;

  HomeScreen(
      {required this.alumnoId,
      required this.alumnoNombre,
      required this.correo});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _buildInicio() {
    return Center(
      child: Text(
        "Bienvenido de nuevo ${widget.alumnoNombre}",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getCursos() async {
    Database db = await DBHelper.openDB();
    return await db.rawQuery('''
  SELECT c.nombre_curso AS nombre, 'Curso' AS tipo, c.fecha_inicio, c.fecha_fin, c.grupo, c.hora_inicio, c.hora_fin FROM curso c
  JOIN inscripcion i ON i.curso_id = c.id WHERE i.alumno_id = ?
  UNION
  SELECT t.nombre_taller AS nombre, 'Taller' AS tipo, t.fecha_inicio, t.fecha_fin, t.grupo, t.hora_inicio, t.hora_fin FROM taller t
  JOIN inscripcion i ON i.taller_id = t.id WHERE i.alumno_id = ?
  UNION
  SELECT d.nombre_diplomado AS nombre, 'Diplomado' AS tipo, d.fecha_inicio, d.fecha_fin, d.grupo, d.hora_inicio, d.hora_fin FROM diplomado d
  JOIN inscripcion i ON i.diplomado_id = d.id WHERE i.alumno_id = ?
''', [widget.alumnoId, widget.alumnoId, widget.alumnoId]);
  }

  Widget _buildCursos() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCursos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty)
          return Center(child: Text("No tienes inscripciones."));

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final curso = snapshot.data![index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.school),
                title: Text(curso['nombre']),
                subtitle: Text(
                  "${curso['tipo']} • Grupo: ${curso['grupo']}\nInicio: ${curso['fecha_inicio']} - Fin: ${curso['fecha_fin']}\nHora: ${curso['hora_inicio']} a ${curso['hora_fin']}",
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCuenta() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nombre: ${widget.alumnoNombre}",
              style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text("Correo: ${widget.correo}", style: TextStyle(fontSize: 18)),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              ),
              icon: Icon(Icons.logout),
              label: Text("Cerrar sesión"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_buildInicio(), _buildCursos(), _buildCuenta()];
    return Scaffold(
      appBar: AppBar(title: Text("Entre Todos")),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Cursos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cuenta"),
        ],
      ),
    );
  }
}
