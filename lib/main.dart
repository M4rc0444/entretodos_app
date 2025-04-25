import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(EntretodosApp());
}

class EntretodosApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entre Todos - Alumno',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
    String password = _passwordController.text.trim(); // SIN hash por ahora

    Database db = await DBHelper.openDB();

    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM alumnos WHERE correo = ?", [email]);

    if (result.isNotEmpty) {
      String dbPassword = result[0]['contrasena'] ?? '';

      // Solo comparar directo, sin hash, solo para probar
      if (dbPassword == password) {
        String nombres = result[0]['nombres'] ?? '';
        String apellidoPaterno = result[0]['apellido_paterno'] ?? '';
        int alumnoId = result[0]['id'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CursosAlumno(
              alumnoId: alumnoId,
              alumnoNombre: "$nombres $apellidoPaterno",
            ),
          ),
        );
      } else {
        setState(() {
          _mensajeError = "Contraseña incorrecta.";
        });
      }
    } else {
      setState(() {
        _mensajeError = "Correo no encontrado.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Correo electrónico"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginAlumno,
              child: Text("Ingresar"),
            ),
            SizedBox(height: 20),
            if (_mensajeError != null)
              Text(_mensajeError!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class CursosAlumno extends StatelessWidget {
  final int alumnoId;
  final String alumnoNombre;

  CursosAlumno({required this.alumnoId, required this.alumnoNombre});

  Future<List<Map<String, dynamic>>> _getCursos() async {
    Database db = await DBHelper.openDB();
    return await db.rawQuery('''
      SELECT c.nombre_curso AS nombre, 'Curso' AS tipo FROM cursos c
      JOIN inscripciones i ON i.curso_id = c.id
      WHERE i.alumno_id = ?
      UNION
      SELECT t.nombre_taller AS nombre, 'Taller' AS tipo FROM talleres t
      JOIN inscripciones i ON i.taller_id = t.id
      WHERE i.alumno_id = ?
      UNION
      SELECT d.nombre_diplomado AS nombre, 'Diplomado' AS tipo FROM diplomados d
      JOIN inscripciones i ON i.diplomado_id = d.id
      WHERE i.alumno_id = ?
    ''', [alumnoId, alumnoId, alumnoId]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inscripciones de $alumnoNombre")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCursos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty)
            return Center(child: Text("No tiene inscripciones."));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var curso = snapshot.data![index];
              return ListTile(
                title: Text(curso['nombre']),
                subtitle: Text(curso['tipo']),
              );
            },
          );
        },
      ),
    );
  }
}
