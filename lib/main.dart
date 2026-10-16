import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const PokeKawaiiApp());
}

// 1. Modelo de datos avanzado con Estadísticas, Doble Tipo y Sprites Normal/Shiny
class PokemonModel {
  final int id;
  final String name;
  final double height; // En metros
  final double weight; // En kilogramos
  final String normalImageUrl;
  final String shinyImageUrl;
  final List<String> types;
  final List<String> abilities;
  final Map<String, int> stats;
  String description;

  int get totalStats => stats.values.fold(0, (a, b) => a + b);

  PokemonModel({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.normalImageUrl,
    required this.shinyImageUrl,
    required this.types,
    required this.abilities,
    required this.stats,
    this.description = 'Cargando descripción en español...',
  });

  factory PokemonModel.fromJson(Map<String, dynamic> json) {
    List<String> loadedTypes = (json['types'] as List)
        .map((t) => t['type']['name'].toString())
        .toList();

    List<String> loadedAbilities = (json['abilities'] as List)
        .map((a) => a['ability']['name'].toString())
        .toList();

    Map<String, int> loadedStats = {};
    for (var s in (json['stats'] as List)) {
      String statName = s['stat']['name'];
      int statVal = s['base_stat'];
      loadedStats[statName] = statVal;
    }

    double heightMeters = (json['height'] ?? 0) / 10.0;
    double weightKg = (json['weight'] ?? 0) / 10.0;

    String normalSprite = json['sprites']['other']['official-artwork']['front_default'] ??
        json['sprites']['front_default'] ??
        '';
        
    String shinySprite = json['sprites']['other']['official-artwork']['front_shiny'] ??
        json['sprites']['front_shiny'] ??
        normalSprite;

    return PokemonModel(
      id: json['id'],
      name: json['name'],
      height: heightMeters,
      weight: weightKg,
      normalImageUrl: normalSprite,
      shinyImageUrl: shinySprite,
      types: loadedTypes,
      abilities: loadedAbilities,
      stats: loadedStats,
    );
  }
}

class PokeKawaiiApp extends StatefulWidget {
  const PokeKawaiiApp({super.key});

  @override
  State<PokeKawaiiApp> createState() => _PokeKawaiiAppState();
}

class _PokeKawaiiAppState extends State<PokeKawaiiApp> {
  bool _isDarkMode = false; // Modo Día / Noche Global

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pandidex 🐼🌸',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _isDarkMode ? Colors.deepPurpleAccent : Colors.pinkAccent,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(isDarkMode: _isDarkMode, onToggleTheme: _toggleTheme),
    );
  }
}

// ==========================================
// PANTALLA 1: INICIO AVANZADO (PARALLAX & SHINY)
// ==========================================
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _rainController;
  late AnimationController _transitionController;
  late AnimationController _shakeController;
  
  late Animation<double> _zoomAnimation;
  late Animation<double> _flashAnimation;
  late Animation<double> _shakeAnimation;

  final List<FallingItem> _items = [];
  final Random _random = Random();
  bool _isOpening = false;

  double _mouseX = 0.0;
  double _mouseY = 0.0;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 12.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOutBack),
    );

    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    for (int i = 0; i < 22; i++) {
      _items.add(FallingItem(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 24.0 + _random.nextDouble() * 22.0,
        isPokeball: _random.nextBool(),
      ));
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _transitionController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerPokeballTransition() {
    if (_isOpening) return;
    
    _shakeController.forward().then((_) {
      setState(() {
        _isOpening = true;
      });
      _transitionController.forward().then((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MainMenuScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final strokeColor = widget.isDarkMode ? const Color(0xFF3B1E54) : const Color(0xFF881446);
    final textColor = widget.isDarkMode ? const Color(0xFF00FFCC) : const Color(0xFFFFD700);

    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          final size = MediaQuery.of(context).size;
          setState(() {
            _mouseX = (event.position.dx / size.width) * 2 - 1;
            _mouseY = (event.position.dy / size.height) * 2 - 1;
          });
        },
        child: Stack(
          children: [
            VerticalStripesBackground(isDarkMode: widget.isDarkMode),
            AnimatedBuilder(
              animation: _rainController,
              builder: (context, child) {
                return Stack(
                  children: _items.map((item) {
                    item.y += 0.003 * item.speed;
                    if (item.y > 1.1) {
                      item.y = -0.1;
                      item.x = _random.nextDouble();
                    }

                    double offsetX = item.x * MediaQuery.of(context).size.width + (_mouseX * 15 * item.speed);
                    double offsetY = item.y * MediaQuery.of(context).size.height + (_mouseY * 15 * item.speed);

                    return Positioned(
                      left: offsetX,
                      top: offsetY,
                      child: Opacity(
                        opacity: widget.isDarkMode ? 0.9 : 0.85,
                        child: item.isPokeball
                            ? CustomPokeball(size: item.size, isShiny: widget.isDarkMode)
                            : Text('🐼', style: TextStyle(fontSize: item.size)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 25,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: widget.isDarkMode ? Colors.deepPurple.shade300 : Colors.pink.shade200,
                onPressed: widget.onToggleTheme,
                child: Text(widget.isDarkMode ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_transitionController, _shakeController]),
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(-_mouseY * 0.08)
                      ..rotateY(_mouseX * 0.08),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _zoomAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: (widget.isDarkMode ? Colors.purpleAccent : const Color(0xFFC71585)).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                widget.isDarkMode ? '✨ MODO SHINY NOCTURNO ✨' : '✨ CREADO POR PANDIGAEL ✨',
                                style: TextStyle(color: widget.isDarkMode ? Colors.purpleAccent : const Color(0xFF8B0000), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ),
                            const SizedBox(height: 25),
                            Stack(
                              children: [
                                Text(
                                  'Pandidex',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 8
                                      ..color = strokeColor,
                                  ),
                                ),
                                Text(
                                  'Pandidex',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.isDarkMode ? 'Tu universo Pokémon en versión estelar nocturna 🌌' : 'Tu universo Pokémon con un toque tierno y divertido 🌸',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: widget.isDarkMode ? Colors.white70 : const Color(0xFF6B1D3F), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 40),
                            if (!_isOpening)
                              Transform.translate(
                                offset: Offset(_shakeAnimation.value, 0),
                                child: GestureDetector(
                                  onTap: _triggerPokeballTransition,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Column(
                                      children: [
                                        CustomPokeball(size: 90, isShiny: widget.isDarkMode),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: widget.isDarkMode ? Colors.deepPurpleAccent : const Color(0xFF881446),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            '¡Toca para Atrapar!',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                if (_flashAnimation.value == 0.0) return const SizedBox.shrink();
                return Container(
                  color: Colors.white.withOpacity(_flashAnimation.value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CustomPokeball extends StatelessWidget {
  final double size;
  final bool isShiny;

  const CustomPokeball({super.key, required this.size, required this.isShiny});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isShiny
              ? [Colors.deepPurple, Colors.purpleAccent, Colors.white, Colors.white]
              : [Colors.red, Colors.redAccent, Colors.white, Colors.white],
          stops: const [0.0, 0.48, 0.52, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isShiny ? Colors.purpleAccent : Colors.black).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.32,
          height: size * 0.32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black87, width: 2),
          ),
          child: Center(
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isShiny ? Colors.cyanAccent : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FallingItem {
  double x;
  double y;
  double speed;
  double size;
  bool isPokeball;

  FallingItem({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.isPokeball,
  });
}

class VerticalStripesBackground extends StatelessWidget {
  final bool isDarkMode;
  const VerticalStripesBackground({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: StripesPainter(isDarkMode: isDarkMode),
    );
  }
}

class StripesPainter extends CustomPainter {
  final bool isDarkMode;
  StripesPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    double stripeWidth = 40.0;
    int count = (size.width / stripeWidth).ceil();

    for (int i = 0; i < count; i++) {
      if (isDarkMode) {
        paint.color = i % 2 == 0 ? const Color(0xFF1F1635) : const Color(0xFF2C1E4A);
      } else {
        paint.color = i % 2 == 0 ? const Color(0xFFFFC0CB) : const Color(0xFFFFB6C1);
      }
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// PANTALLA 2: MENÚ PRINCIPAL EVOLUCIONADO
// ==========================================
class MainMenuScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainMenuScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _rainController;
  final List<FallingItem> _items = [];
  final Random _random = Random();
  
  int _randomPokemonId = 25; // Inicia con Pikachu

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    for (int i = 0; i < 18; i++) {
      _items.add(FallingItem(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 20.0 + _random.nextDouble() * 18.0,
        isPokeball: _random.nextBool(),
      ));
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    super.dispose();
  }

  void _cambiarPokemonAleatorio() {
    setState(() {
      _randomPokemonId = _random.nextInt(300) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text('Menú Pandidex 🌟', style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : const Color(0xFF4A355F))),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.pink.shade100,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Text(widget.isDarkMode ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      body: Stack(
        children: [
          VerticalStripesBackground(isDarkMode: widget.isDarkMode),
          AnimatedBuilder(
            animation: _rainController,
            builder: (context, child) {
              return Stack(
                children: _items.map((item) {
                  item.y += 0.003 * item.speed;
                  if (item.y > 1.1) {
                    item.y = -0.1;
                    item.x = _random.nextDouble();
                  }

                  return Positioned(
                    left: item.x * MediaQuery.of(context).size.width,
                    top: item.y * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: 0.8,
                      child: item.isPokeball
                          ? CustomPokeball(size: item.size, isShiny: widget.isDarkMode)
                          : Text('🐼', style: TextStyle(fontSize: item.size)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'Pokédex',
                          subtitle: 'Explora y busca Pokémon',
                          icon: Icons.catching_pokemon,
                          color: widget.isDarkMode ? Colors.deepPurple.shade400 : Colors.pink.shade300,
                          destination: PokedexScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme, initialId: 1),
                        ),
                        const SizedBox(height: 18),
                        _buildMenuCard(
                          context,
                          title: 'Minijuegos',
                          subtitle: 'Retos y diversión',
                          icon: Icons.sports_esports,
                          color: Colors.purple.shade300,
                          destination: MiniGamesMenuScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme),
                        ),
                        const SizedBox(height: 18),
                        _buildMenuCard(
                          context,
                          title: 'Créditos',
                          subtitle: 'Creador pandiGael',
                          icon: Icons.favorite,
                          color: Colors.orange.shade300,
                          destination: CreditsScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PokedexScreen(
                                  isDarkMode: widget.isDarkMode,
                                  onToggleTheme: widget.onToggleTheme,
                                  initialId: _randomPokemonId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: (widget.isDarkMode ? const Color(0xFF241838) : Colors.white).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.pink.shade300, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '✨ Pokémon Destacado ✨',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.pinkAccent : Colors.pink, fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Image.network(
                                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$_randomPokemonId.png',
                                  height: 220,
                                  width: 220,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      height: 220,
                                      width: 220,
                                      child: Center(child: CircularProgressIndicator(color: Colors.pink)),
                                    );
                                  },
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton.icon(
                                  onPressed: _cambiarPokemonAleatorio,
                                  icon: const Icon(Icons.shuffle, size: 18),
                                  label: const Text('Cambiar Pokémon'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.isDarkMode ? Colors.deepPurpleAccent : Colors.pinkAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required Widget destination}) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => destination,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE MINIJUEGOS (4 BOTONES CUADRADOS EN FILA HORIZONTAL)
// ==========================================
class MiniGamesMenuScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MiniGamesMenuScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<MiniGamesMenuScreen> createState() => _MiniGamesMenuScreenState();
}

class _MiniGamesMenuScreenState extends State<MiniGamesMenuScreen> {
  void _mostrarSelectorDificultad(BuildContext context, String tituloJuego, bool esCarrera) {
    String dificultadSeleccionada = 'Fácil';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨ Selecciona Reto ✨', style: TextStyle(fontSize: 13, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                tituloJuego,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF4A355F),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!esCarrera) ...[
                  const Text('Dificultad:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chipDificultad('Fácil', Colors.green, dificultadSeleccionada, (val) => setStateDialog(() => dificultadSeleccionada = val)),
                      const SizedBox(width: 6),
                      _chipDificultad('Medio', Colors.orange, dificultadSeleccionada, (val) => setStateDialog(() => dificultadSeleccionada = val)),
                      const SizedBox(width: 6),
                      _chipDificultad('Difícil', Colors.red, dificultadSeleccionada, (val) => setStateDialog(() => dificultadSeleccionada = val)),
                    ],
                  ),
                ] else ...[
                  const Text('Modo Supervivencia por Distancia\n(Dificultad Única)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _iniciarJuegoSeleccionado(context, tituloJuego, esCarrera ? 'Única' : dificultadSeleccionada);
                    },
                    child: const Text('¡Comenzar a Jugar!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipDificultad(String label, Color color, String actual, Function(String) onSelect) {
    bool seleccionado = actual == label;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      selectedColor: color,
      labelStyle: TextStyle(color: seleccionado ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (bool selected) {
        if (selected) onSelect(label);
      },
    );
  }

  void _iniciarJuegoSeleccionado(BuildContext context, String juego, String dificultad) {
    Widget pantallaJuego;
    if (juego == '¿Quién es ese Pokémon?') {
      pantallaJuego = QuizSiluetaScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme, dificultad: dificultad);
    } else if (juego == 'Adivina Quién') {
      pantallaJuego = QuizDescripcionScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme, dificultad: dificultad);
    } else if (juego == '¿Cuál Gana?') {
      pantallaJuego = QuizStatsScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme, dificultad: dificultad);
    } else {
      pantallaJuego = CorredorPokemonScreen(isDarkMode: widget.isDarkMode, onToggleTheme: widget.onToggleTheme);
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CountdownGameScreen(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
          tituloJuego: juego,
          dificultad: dificultad,
          pantallaJuegoDestino: pantallaJuego,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text('Minijuegos Pandidex 🎮', style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.purple.shade100,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Text(widget.isDarkMode ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      body: Stack(
        children: [
          VerticalStripesBackground(isDarkMode: widget.isDarkMode),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¡Elige tu desafío Pokémon!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildSquareGameCard(context, title: '¿Quién es ese Pokémon?', icon: Icons.help_outline, color: Colors.purple.shade300, esCarrera: false)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildSquareGameCard(context, title: 'Adivina Quién', icon: Icons.book, color: Colors.pink.shade300, esCarrera: false)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildSquareGameCard(context, title: '¿Cuál Gana?', icon: Icons.flash_on, color: Colors.amber.shade700, esCarrera: false)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildSquareGameCard(context, title: 'Corredor Pokémon', icon: Icons.directions_run, color: Colors.teal.shade400, esCarrera: true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareGameCard(BuildContext context, {required String title, required IconData icon, required Color color, required bool esCarrera}) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _mostrarSelectorDificultad(context, title, esCarrera),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE TRANSICIÓN Y CUENTA REGRESIVA (3, 2, 1)
// ==========================================
class CountdownGameScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String tituloJuego;
  final String dificultad;
  final Widget pantallaJuegoDestino;

  const CountdownGameScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.tituloJuego,
    required this.dificultad,
    required this.pantallaJuegoDestino,
  });

  @override
  State<CountdownGameScreen> createState() => _CountdownGameScreenState();
}

class _CountdownGameScreenState extends State<CountdownGameScreen> with TickerProviderStateMixin {
  late AnimationController _rainController;
  final List<FallingItem> _items = [];
  final Random _random = Random();
  
  int _contador = 3;
  bool _listoParaJugar = false;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    for (int i = 0; i < 25; i++) {
      _items.add(FallingItem(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.4 + _random.nextDouble() * 0.6,
        size: 24.0 + _random.nextDouble() * 20.0,
        isPokeball: true,
      ));
    }

    _iniciarCuentaRegresiva();
  }

  void _iniciarCuentaRegresiva() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _contador = 2);

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _contador = 1);

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _contador = 0;
      _listoParaJugar = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.pantallaJuegoDestino),
    );
  }

  @override
  void dispose() {
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _rainController,
            builder: (context, child) {
              return Stack(
                children: _items.map((item) {
                  item.y += 0.004 * item.speed;
                  if (item.y > 1.1) {
                    item.y = -0.1;
                    item.x = _random.nextDouble();
                  }

                  return Positioned(
                    left: item.x * MediaQuery.of(context).size.width,
                    top: item.y * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: 0.9,
                      child: CustomPokeball(size: item.size, isShiny: false),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.tituloJuego,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Nivel: ${widget.dificultad}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                  _listoParaJugar
                      ? const Text(
                          '¡A JUGAR! 🚀',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF00FFCC)),
                        )
                      : Column(
                          children: [
                            const Text(
                              '¡Prepárate!',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              '$_contador',
                              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.amber),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MINIJUEGO 1: ¿QUIÉN ES ESE POKÉMON? (SILUETA)
// ==========================================
class QuizSiluetaScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String dificultad;

  const QuizSiluetaScreen({super.key, required this.isDarkMode, required this.onToggleTheme, required this.dificultad});

  @override
  State<QuizSiluetaScreen> createState() => _QuizSiluetaScreenState();
}

class _QuizSiluetaScreenState extends State<QuizSiluetaScreen> {
  bool _cargando = true;
  String _imageUrl = '';
  String _nombreCorrecto = '';
  List<String> _opciones = [];
  int _puntaje = 0;
  int _rachaActual = 0;
  int _metaRacha = 5;
  final Random _random = Random();

  final List<String> _bancoNombres = [
    'Bulbasaur', 'Charmander', 'Squirtle', 'Pikachu', 'Jigglypuff', 'Meowth', 'Psyduck', 'Snorlax', 'Gengar', 'Eevee',
    'Charizard', 'Blastoise', 'Venusaur', 'Machop', 'Abra', 'Gastly', 'Onix', 'Cubone', 'Rhydon', 'Chansey'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.dificultad == 'Fácil') _metaRacha = 5;
    if (widget.dificultad == 'Medio') _metaRacha = 12;
    if (widget.dificultad == 'Difícil') _metaRacha = 30;
    _cargarNuevaPregunta();
  }

  void _cargarNuevaPregunta() async {
    setState(() => _cargando = true);
    int idAleatorio = _random.nextInt(150) + 1;
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$idAleatorio/'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String nombreReal = data['name'];
      nombreReal = nombreReal[0].toUpperCase() + nombreReal.substring(1);
      String sprite = data['sprites']['other']['official-artwork']['front_default'] ?? data['sprites']['front_default'];

      List<String> opcionesTemp = [nombreReal];
      while (opcionesTemp.length < 4) {
        String distractor = _bancoNombres[_random.nextInt(_bancoNombres.length)];
        if (!opcionesTemp.contains(distractor)) {
          opcionesTemp.add(distractor);
        }
      }
      opcionesTemp.shuffle();

      setState(() {
        _nombreCorrecto = nombreReal;
        _imageUrl = sprite;
        _opciones = opcionesTemp;
        _cargando = false;
      });
    }
  }

  void _verificarRespuesta(String seleccion) {
    if (seleccion == _nombreCorrecto) {
      setState(() {
        _rachaActual++;
        _puntaje += 100 * _rachaActual;
      });
      if (_rachaActual >= _metaRacha) {
        _mostrarFinJuego(true);
      } else {
        _cargarNuevaPregunta();
      }
    } else {
      _mostrarFinJuego(false);
    }
  }

  void _mostrarFinJuego(bool ganado) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.white,
        title: Text(ganado ? '🎉 ¡Victoria Pokémon! 🎉' : '💥 ¡Game Over! 💥', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Puntaje final: $_puntaje\nRacha alcanzada: $_rachaActual/$_metaRacha', textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver al Menú'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('¿Quién es ese Pokémon? ❓', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.purple.shade100,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Racha: $_rachaActual / $_metaRacha  |  Puntaje: $_puntaje', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                  const SizedBox(height: 20),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.shade200, width: 3),
                    ),
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                        child: Image.network(_imageUrl, height: 180, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ..._opciones.map((opcion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade300,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () => _verificarRespuesta(opcion),
                            child: Text(opcion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// MINIJUEGO 2: ADIVINA QUIÉN (DESCRIPCIÓN POKÉDEX)
// ==========================================
class QuizDescripcionScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String dificultad;

  const QuizDescripcionScreen({super.key, required this.isDarkMode, required this.onToggleTheme, required this.dificultad});

  @override
  State<QuizDescripcionScreen> createState() => _QuizDescripcionScreenState();
}

class _QuizDescripcionScreenState extends State<QuizDescripcionScreen> {
  bool _cargando = true;
  String _descripcion = '';
  String _nombreCorrecto = '';
  List<String> _opciones = [];
  int _puntaje = 0;
  int _rachaActual = 0;
  int _metaRacha = 5;
  final Random _random = Random();

  final List<String> _bancoNombres = [
    'Bulbasaur', 'Charmander', 'Squirtle', 'Pikachu', 'Jigglypuff', 'Meowth', 'Psyduck', 'Snorlax', 'Gengar', 'Eevee',
    'Charizard', 'Blastoise', 'Venusaur', 'Machop', 'Abra', 'Gastly', 'Onix', 'Cubone', 'Rhydon', 'Chansey'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.dificultad == 'Fácil') _metaRacha = 5;
    if (widget.dificultad == 'Medio') _metaRacha = 12;
    if (widget.dificultad == 'Difícil') _metaRacha = 30;
    _cargarNuevaPregunta();
  }

  void _cargarNuevaPregunta() async {
    setState(() => _cargando = true);
    int idAleatorio = _random.nextInt(100) + 1;
    try {
      final speciesResponse = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$idAleatorio/'));
      if (speciesResponse.statusCode == 200) {
        var speciesData = jsonDecode(speciesResponse.body);
        String nombreReal = speciesData['name'];
        nombreReal = nombreReal[0].toUpperCase() + nombreReal.substring(1);

        List entries = speciesData['flavor_text_entries'];
        var entry = entries.firstWhere((e) => e['language']['name'] == 'es', orElse: () => entries[0]);
        String desc = entry['flavor_text'].replaceAll('\n', ' ').replaceAll('\f', ' ');

        List<String> opcionesTemp = [nombreReal];
        while (opcionesTemp.length < 4) {
          String distractor = _bancoNombres[_random.nextInt(_bancoNombres.length)];
          if (!opcionesTemp.contains(distractor)) {
            opcionesTemp.add(distractor);
          }
        }
        opcionesTemp.shuffle();

        setState(() {
          _nombreCorrecto = nombreReal;
          _descripcion = desc;
          _opciones = opcionesTemp;
          _cargando = false;
        });
      }
    } catch (e) {
      _cargarNuevaPregunta();
    }
  }

  void _verificarRespuesta(String seleccion) {
    if (seleccion == _nombreCorrecto) {
      setState(() {
        _rachaActual++;
        _puntaje += 100 * _rachaActual;
      });
      if (_rachaActual >= _metaRacha) {
        _mostrarFinJuego(true);
      } else {
        _cargarNuevaPregunta();
      }
    } else {
      _mostrarFinJuego(false);
    }
  }

  void _mostrarFinJuego(bool ganado) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.white,
        title: Text(ganado ? '🎉 ¡Victoria Pokémon! 🎉' : '💥 ¡Game Over! 💥', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Puntaje final: $_puntaje\nRacha alcanzada: $_rachaActual/$_metaRacha', textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver al Menú'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('Adivina Quién 📖', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.pink.shade100,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Racha: $_rachaActual / $_metaRacha  |  Puntaje: $_puntaje', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pink.shade200, width: 3),
                    ),
                    child: Text(
                      '"$_descripcion"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ..._opciones.map((opcion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade300,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () => _verificarRespuesta(opcion),
                            child: Text(opcion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// MINIJUEGO 3: ¿CUÁL GANA? (ESTADÍSTICAS OCULTAS)
// ==========================================
class QuizStatsScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String dificultad;

  const QuizStatsScreen({super.key, required this.isDarkMode, required this.onToggleTheme, required this.dificultad});

  @override
  State<QuizStatsScreen> createState() => _QuizStatsScreenState();
}

class _QuizStatsScreenState extends State<QuizStatsScreen> {
  bool _cargando = true;
  PokemonModel? _p1;
  PokemonModel? _p2;
  int _puntaje = 0;
  int _rachaActual = 0;
  int _metaRacha = 5;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.dificultad == 'Fácil') _metaRacha = 5;
    if (widget.dificultad == 'Medio') _metaRacha = 12;
    if (widget.dificultad == 'Difícil') _metaRacha = 30;
    _cargarDuelo();
  }

  void _cargarDuelo() async {
    setState(() => _cargando = true);
    int id1 = _random.nextInt(150) + 1;
    int id2 = _random.nextInt(150) + 1;
    while (id1 == id2) {
      id2 = _random.nextInt(150) + 1;
    }

    final res1 = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id1/'));
    final res2 = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id2/'));

    if (res1.statusCode == 200 && res2.statusCode == 200) {
      setState(() {
        _p1 = PokemonModel.fromJson(jsonDecode(res1.body));
        _p2 = PokemonModel.fromJson(jsonDecode(res2.body));
        _cargando = false;
      });
    }
  }

  void _elegir(PokemonModel elegido, PokemonModel otro) {
    if (elegido.totalStats >= otro.totalStats) {
      setState(() {
        _rachaActual++;
        _puntaje += 150 * _rachaActual;
      });
      if (_rachaActual >= _metaRacha) {
        _mostrarFinJuego(true);
      } else {
        _cargarDuelo();
      }
    } else {
      _mostrarFinJuego(false);
    }
  }

  void _mostrarFinJuego(bool ganado) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.white,
        title: Text(ganado ? '🎉 ¡Victoria Pokémon! 🎉' : '💥 ¡Game Over! 💥', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Puntaje final: $_puntaje\nRacha alcanzada: $_rachaActual/$_metaRacha', textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver al Menú'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('¿Cuál Gana? ⚡', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.amber.shade200,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Racha: $_rachaActual / $_metaRacha  |  Puntaje: $_puntaje', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 10),
                  const Text('¿Cuál tiene más estadísticas totales?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _tarjetaDuelo(_p1!, () => _elegir(_p1!, _p2!))),
                      const SizedBox(width: 15),
                      Expanded(child: _tarjetaDuelo(_p2!, () => _elegir(_p2!, _p1!))),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tarjetaDuelo(PokemonModel p, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade600, width: 3),
        ),
        child: Column(
          children: [
            Image.network(p.normalImageUrl, height: 140, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('¡Elige este!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MINIJUEGO 4: CORREDOR POKÉMON (PIXEL ART & TECLADO)
// ==========================================
class CorredorPokemonScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const CorredorPokemonScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<CorredorPokemonScreen> createState() => _CorredorPokemonScreenState();
}

class _CorredorPokemonScreenState extends State<CorredorPokemonScreen> with SingleTickerProviderStateMixin {
  double _posicionY = 0.0;
  bool _saltando = false;
  double _obstaculoX = 400.0;
  int _distancia = 0;
  bool _enJuego = true;
  late AnimationController _gameController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_actualizarJuego)
      ..repeat();
  }

  @override
  void dispose() {
    _gameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _actualizarJuego() {
    if (!_enJuego) return;
    setState(() {
      _distancia++;
      _obstaculoX -= 7.0;
      if (_obstaculoX < -40) {
        _obstaculoX = 450.0;
      }

      if (_obstaculoX < 60 && _obstaculoX > 20 && _posicionY < 30) {
        _enJuego = false;
        _gameController.stop();
        _mostrarGameOver();
      }
    });
  }

  void _saltar() {
    if (_saltando || !_enJuego) return;
    setState(() => _saltando = true);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _posicionY = 120.0);
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted) {
          setState(() {
            _posicionY = 0.0;
            _saltando = false;
          });
        }
      });
    });
  }

  void _mostrarGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('💥 ¡Te tropezaste! 💥', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Distancia recorrida: $_distancia metros', textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver al Menú'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.space) {
            _saltar();
          }
        }
      },
      child: Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFFE8F8E8),
        appBar: AppBar(
          title: const Text('Corredor Pokémon 🏃‍♂️', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : Colors.teal.shade300,
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: _saltar,
          child: Stack(
            children: [
              Positioned(
                top: 50,
                left: 20,
                child: Text('Distancia: $_distancia m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
              Positioned(
                bottom: 120,
                left: 50,
                child: Transform.translate(
                  offset: Offset(0, -_posicionY),
                  child: Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/25.gif',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: _obstaculoX,
                child: const Text('🪨', style: TextStyle(fontSize: 40)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  color: Colors.teal.shade700,
                  child: const Center(
                    child: Text('¡Toca la pantalla o usa la Flecha Arriba / Espacio para saltar!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA 3: POKÉDEX ESTILO RETO / GBA
// ==========================================
class PokedexScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final int initialId;

  const PokedexScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.initialId = 1,
  });

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late int _pokemonId;
  late Future<PokemonModel> _pokemonFuture;
  final TextEditingController _searchController = TextEditingController();
  bool _showShiny = false;

  final List<String> _pokemonNombres = [
    'Bulbasaur', 'Ivysaur', 'Venusaur', 'Charmander', 'Charmeleon', 'Charizard', 'Squirtle', 'Wartortle', 'Blastoise', 'Caterpie',
    'Metapod', 'Butterfree', 'Weedle', 'Kakuna', 'Beedrill', 'Pidgey', 'Pidgeotto', 'Pidgeot', 'Rattata', 'Raticate',
    'Spearow', 'Fearow', 'Ekans', 'Arbok', 'Pikachu', 'Raichu', 'Sandshrew', 'Sandslash', 'Nidoran♀', 'Nidorina',
    'Nidoqueen', 'Nidoran♂', 'Nidorino', 'Nidoking', 'Clefairy', 'Clefable', 'Vulpix', 'Ninetales', 'Jigglypuff', 'Wigglytuff',
    'Zubat', 'Golbat', 'Oddish', 'Gloom', 'Vileplume', 'Paras', 'Parasect', 'Venonat', 'Venomoth', 'Diglett',
    'Dugtrio', 'Meowth', 'Persian', 'Psyduck', 'Golduck', 'Mankey', 'Primeape', 'Growlithe', 'Arcanine', 'Poliwag',
    'Poliwhirl', 'Poliwrath', 'Abra', 'Kadabra', 'Alakazam', 'Machop', 'Machoke', 'Machamp', 'Bellsprout', 'Weepinbell',
    'Victreebel', 'Tentacool', 'Tentacruel', 'Geodude', 'Graveler', 'Golem', 'Ponyta', 'Rapidash', 'Slowpoke', 'Slowbro',
    'Magnemite', 'Magneton', 'Farfetch\'d', 'Doduo', 'Dodrio', 'Seel', 'Dewgong', 'Grimer', 'Muk', 'Shellder',
    'Cloyster', 'Gastly', 'Haunter', 'Gengar', 'Onix', 'Drowzee', 'Hypno', 'Krabby', 'Kingler', 'Voltorb',
    'Electrode', 'Exeggcute', 'Exeggutor', 'Cubone', 'Marowak', 'Hitmonlee', 'Hitmonchan', 'Lickitung', 'Koffing', 'Weezing',
    'Rhyhorn', 'Rhydon', 'Chansey', 'Tangela', 'Kangaskhan', 'Horsea', 'Seadra', 'Goldeen', 'Seaking', 'Staryu',
    'Starmie', 'Mr. Mime', 'Scyther', 'Jynx', 'Electabuzz', 'Magmar', 'Pinsir', 'Tauros', 'Magikarp', 'Gyarados',
    'Lapras', 'Ditto', 'Eevee', 'Vaporeon', 'Jolteon', 'Flareon', 'Porygon', 'Omanyte', 'Omastar', 'Kabuto',
    'Kabutops', 'Aerodactyl', 'Snorlax', 'Articuno', 'Zapdos', 'Moltres', 'Dratini', 'Dragonair', 'Dragonite', 'Mewtwo', 'Mew'
  ];

  @override
  void initState() {
    super.initState();
    _pokemonId = widget.initialId;
    _pokemonFuture = fetchPokemonAndSpecies(_pokemonId);
  }

  Future<PokemonModel> fetchPokemonAndSpecies(int id) async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id/'));
    if (response.statusCode == 200) {
      var pokemon = PokemonModel.fromJson(jsonDecode(response.body));

      try {
        final speciesResponse = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$id/'));
        if (speciesResponse.statusCode == 200) {
          var speciesData = jsonDecode(speciesResponse.body);
          List entries = speciesData['flavor_text_entries'];
          var entry = entries.firstWhere(
            (e) => e['language']['name'] == 'es',
            orElse: () => entries[0],
          );
          pokemon.description = entry['flavor_text'].replaceAll('\n', ' ').replaceAll('\f', ' ');
        }
      } catch (e) {
        pokemon.description = 'Un tierno Pokémon listo para la aventura.';
      }

      return pokemon;
    } else {
      throw Exception('Pokémon no encontrado');
    }
  }

  void _seleccionarPokemon(int id) {
    setState(() {
      _pokemonId = id;
      if (_pokemonId < 1) _pokemonId = 1;
      if (_pokemonId > 1010) _pokemonId = 1010;
      _showShiny = false;
      _pokemonFuture = fetchPokemonAndSpecies(_pokemonId);
    });
  }

  void _buscarPokemonPorTexto() {
    if (_searchController.text.isNotEmpty) {
      int? idOrSearch = int.tryParse(_searchController.text.trim().toLowerCase());
      if (idOrSearch != null) {
        _seleccionarPokemon(idOrSearch);
      } else {
        String query = _searchController.text.trim().toLowerCase();
        http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$query/')).then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            _seleccionarPokemon(data['id']);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡No se encontró ese Pokémon!')),
              );
            }
          }
        });
      }
    }
  }

  Color _obtenerColorTipo(String type) {
    switch (type) {
      case 'grass': return Colors.green.shade600;
      case 'fire': return Colors.deepOrange.shade600;
      case 'water': return Colors.blue.shade600;
      case 'electric': return Colors.amber.shade700;
      case 'psychic': return Colors.purple.shade600;
      case 'poison': return Colors.purple.shade400;
      case 'bug': return Colors.lightGreen.shade700;
      case 'normal': return Colors.brown.shade300;
      case 'rock': return Colors.brown.shade500;
      case 'ghost': return Colors.indigo.shade400;
      case 'dragon': return Colors.indigo.shade700;
      case 'fairy': return Colors.pink.shade300;
      case 'fighting': return Colors.red.shade800;
      case 'ice': return Colors.cyan.shade400;
      case 'steel': return Colors.blueGrey;
      case 'dark': return Colors.black87;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF181028) : const Color(0xFF387A54);
    final panelColor = widget.isDarkMode ? const Color(0xFF241838) : const Color(0xFFD8EED8);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1E4531);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('POKÉDEX PANDIDEX 🌿', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C1E4A) : const Color(0xFF1E4531),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Text(widget.isDarkMode ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.isDarkMode ? Colors.purpleAccent : const Color(0xFF1E4531), width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: FutureBuilder<PokemonModel>(
                  future: _pokemonFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar Pokémon'));
                    } else if (snapshot.hasData) {
                      final pokemon = snapshot.data!;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('N°. ${pokemon.id.toString().padLeft(3, '0')}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                                Row(
                                  children: pokemon.types.map((t) => Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Chip(
                                      label: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      backgroundColor: _obtenerColorTipo(t),
                                      padding: EdgeInsets.zero,
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? const Color(0xFF1F1635) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: widget.isDarkMode ? Colors.purpleAccent : const Color(0xFF1E4531), width: 2),
                                  ),
                                  child: Center(
                                    child: Image.network(
                                      _showShiny ? pokemon.shinyImageUrl : pokemon.normalImageUrl,
                                      fit: BoxFit.contain,
                                      height: 140,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showShiny = !_showShiny;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _showShiny ? Colors.amber : Colors.grey.shade200,
                                      foregroundColor: _showShiny ? Colors.black : Colors.black87,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(_showShiny ? '✨ Shiny' : 'Normal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pokemon.name.toUpperCase(),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Altura: ${pokemon.height} m', style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                Text('Peso: ${pokemon.weight} kg', style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode ? const Color(0xFF1F1635) : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estadísticas Base:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
                                  const SizedBox(height: 4),
                                  ...pokemon.stats.entries.map((stat) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 70, child: Text(stat.key.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white60 : Colors.black54))),
                                          Text('${stat.value}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: (stat.value / 200).clamp(0.0, 1.0),
                                              color: _obtenerColorTipo(pokemon.types[0]),
                                              backgroundColor: Colors.grey.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode ? const Color(0xFF1F1635) : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '"${pokemon.description}"',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF241838) : const Color(0xFFE8F8E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.isDarkMode ? Colors.purpleAccent : const Color(0xFF1E4531), width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Nombre o ID (ej. charizard, 6)',
                              filled: true,
                              fillColor: widget.isDarkMode ? const Color(0xFF1F1635) : Colors.white,
                              hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _buscarPokemonPorTexto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isDarkMode ? Colors.deepPurpleAccent : const Color(0xFF1E4531),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('BUSCAR'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('LISTA POKÉDEX NACIONAL (1-1000+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                    const Divider(color: Color(0xFF1E4531), thickness: 2),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 1010,
                        itemBuilder: (context, index) {
                          int id = index + 1;
                          bool isSelected = _pokemonId == id;
                          
                          String nombrePokemon = (id <= _pokemonNombres.length)
                              ? _pokemonNombres[id - 1]
                              : 'Pokémon #$id';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? (widget.isDarkMode ? Colors.deepPurpleAccent : const Color(0xFF1E4531)) : (widget.isDarkMode ? const Color(0xFF1F1635) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const Text('🔴', style: TextStyle(fontSize: 14)),
                              title: Text(
                                'N°. ${id.toString().padLeft(3, '0')}   $nombrePokemon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              trailing: Icon(Icons.arrow_right, color: isSelected ? Colors.white : Colors.grey),
                              onTap: () => _seleccionarPokemon(id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA 5: CRÉDITOS (PANDIGAEL)
// ==========================================
class CreditsScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const CreditsScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF181028) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text('Créditos 💖', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
        backgroundColor: isDarkMode ? const Color(0xFF2C1E4A) : Colors.orange.shade100,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: Text(isDarkMode ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF241838) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.pinkAccent,
                  child: Text('🐼', style: TextStyle(fontSize: 45)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Desarrollador Principal:',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'pandiGael',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF881446)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ángel Gael Rodríguez Castañeda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : const Color(0xFF4A355F)),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                const Text(
                  'Creador de Pandidex, la app móvil definitiva de Pokémon con estilo kawaii.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.deepPurple.shade900 : Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    '✨ Hecho con amor y Flutter 🐼',
                    style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}