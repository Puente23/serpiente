import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'appbar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SERPENT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SnakeGame(),
    );
  }
}

enum Direction {
  up,
  right,
  down,
  left,
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  final int gridSize = 18;
  final int cellSize = 20;
  List<Offset> _snake = [];
  Offset _food = Offset.zero;
  AudioPlayer audioPlayer = AudioPlayer();

  Direction _direction = Direction.up;

  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

//inicio de el juego
  void _startGame() {
    setState(() {
      _snake = [Offset(5, 5)];
      _generateFood();
      _direction = Direction.right;
      _gameOver = false;
      juegosnake();
    });
//velocidad de la posicion de la serpiente
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 200));
      if (_gameOver) {
        return false;
      }
      _updateSnake(_direction);
      return true;
    });
  }

//generacion de la comida de la serpiente
  void _generateFood() {
    final random = Random();
    int x, y;
    do {
      x = random.nextInt(gridSize);
      y = random.nextInt(gridSize);
    } while (_snake.contains(Offset(x.toDouble(), y.toDouble())));
    setState(() {
      _food = Offset(x.toDouble(), y.toDouble());
    });
  }

//juego definicion de la jugabilidad
  void _updateSnake(Direction newDirection) {
    final head = _snake.last;
    final next = _getNextPosition(newDirection);
    if (_isOutOfBounds(next) || _snake.contains(next)) {
      setState(() {
        _gameOver = true;
        juegooff();
      });
      return;
    }
    if (next == _food) {
      setState(() {
        _snake.add(next);
        _generateFood();
      });
    } else {
      setState(() {
        _snake.removeAt(0);
        _snake.add(next);
      });
    }
    _direction = newDirection;
  }

//siguiente posicion de la serpiente
  /*Offset _getNextPosition(Direction direction) {
    final head = _snake.last;
    switch (direction) {
      case Direction.up:
        return Offset(head.dx, head.dy - 1);
      case Direction.right:
        return Offset(head.dx + 1, head.dy);
      case Direction.down:
        return Offset(head.dx, head.dy + 1);
      case Direction.left:
        return Offset(head.dx - 1, head.dy);
      default:
        return head;
    }
  }*/
  Offset _getNextPosition(Direction direction) {
    final head = _snake.last;
    if (direction == Direction.up && _direction == Direction.down) {
      // Si la serpiente intenta moverse hacia arriba mientras se mueve hacia abajo, mantener su dirección actual
      return Offset(head.dx, head.dy + 1);
    } else if (direction == Direction.right && _direction == Direction.left) {
      // Si la serpiente intenta moverse hacia la derecha mientras se mueve hacia la izquierda, mantener su dirección actual
      return Offset(head.dx - 1, head.dy);
    } else if (direction == Direction.down && _direction == Direction.up) {
      // Si la serpiente intenta moverse hacia abajo mientras se mueve hacia arriba, mantener su dirección actual
      return Offset(head.dx, head.dy - 1);
    } else if (direction == Direction.left && _direction == Direction.right) {
      // Si la serpiente intenta moverse hacia la izquierda mientras se mueve hacia la derecha, mantener su dirección actual
      return Offset(head.dx + 1, head.dy);
    } else {
      // Si la serpiente intenta moverse en cualquier otra dirección, calcular su siguiente posición normalmente
      switch (direction) {
        case Direction.up:
          return Offset(head.dx, head.dy - 1);
        case Direction.right:
          return Offset(head.dx + 1, head.dy);
        case Direction.down:
          return Offset(head.dx, head.dy + 1);
        case Direction.left:
          return Offset(head.dx - 1, head.dy);
        default:
          return head;
      }
    }
  }

//comprobaciones de la posicion
  bool _isOutOfBounds(Offset position) {
    return position.dx < 0 ||
        position.dx >= gridSize ||
        position.dy < 0 ||
        position.dy >= gridSize;
  }

  //musica
  juegosnake() async {
    String audioasset = "assets/sounds/juego.mp3";
    ByteData bytes = await rootBundle.load(audioasset); //load audio from assets
    Uint8List audiobytes =
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    int result = await audioPlayer.playBytes(audiobytes);
    if (result == 1) {
      //play success
      print("audio is playing.");
    } else {
      print("Error while playing audio.");
    }
  }

  juegooff() async {
    int result = await audioPlayer.stop();
    if (result == 1) {
      //play success
      print("audio is stopping.");
    } else {
      print("Error while playing audio.");
    }
  }

//dibujo de la interfaz del juego
  @override
  Widget build(BuildContext context) {
    // juegosnake();
    return Scaffold(
        appBar: AnimatedAppBar(),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/fondo.png'), // Ruta de la imagen de fondo
              fit: BoxFit.cover, // Ajuste de la imagen al contenedor
            ),
          ),
          child: Center(
              //deteccion de los movimiento del game
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (TapUpDetails details) {
                    if (_gameOver) {
                      _startGame();
                    }
                  },
                  //movimientos de la serpiente
                  /*onHorizontalDragUpdate: (DragUpdateDetails details) {
                    if (_direction == Direction.left && details.delta.dx > 0) {
                      _updateSnake(Direction.right);
                      print("izquierda");
                    } else if (_direction == Direction.right &&
                        details.delta.dx < 0) {
                      _updateSnake(Direction.left);
                      print("derecha");
                    }
                  },
                  onVerticalDragUpdate: (DragUpdateDetails details) {
                    print("vertical");
                    print("${details.delta.dy}");
                    if (_direction == Direction.up && details.delta.dy > 0) {
                      print("arriba");
                      _updateSnake(Direction.down);
                    } else if (_direction == Direction.down &&
                        details.delta.dy < 0) {
                      print("abajo");
                      _updateSnake(Direction.up);
                    }
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    if (_direction == Direction.left && details.delta.dx > 0) {
                      _direction = Direction.right;
                    } else if (_direction == Direction.right &&
                        details.delta.dx < 0) {
                      _direction = Direction.left;
                    }
                  },
                  onVerticalDragUpdate: (DragUpdateDetails details) {
                    if (_direction == Direction.up && details.delta.dy > 0) {
                      _direction = Direction.down;
                    } else if (_direction == Direction.down &&
                        details.delta.dy < 0) {
                      _direction = Direction.up;
                    }
                  },*/

                  //Gesture eventos de la serpiente en la pantalla
                  /* onPanUpdate: (DragUpdateDetails details) {
                    Offset delta = details.delta;
                    if (delta.dx > 0 && _direction != Direction.left) {
                      _direction = Direction.right;
                    } else if (delta.dx < 0 && _direction != Direction.right) {
                      _direction = Direction.left;
                    } else if (delta.dy > 0 && _direction != Direction.up) {
                      _direction = Direction.down;
                    } else if (delta.dy < 0 && _direction != Direction.down) {
                      _direction = Direction.up;
                    }
                  },*/
                  onPanUpdate: (DragUpdateDetails details) {
                    Offset delta = details.delta;
                    if (delta.dx > 0 && _direction != Direction.left) {
                      _direction = Direction.right;
                    } else if (delta.dx < 0 && _direction != Direction.right) {
                      _direction = Direction.left;
                    } else if (delta.dy > 0 && _direction != Direction.up) {
                      _direction = Direction.down;
                    } else if (delta.dy < 0 && _direction != Direction.down) {
                      _direction = Direction.up;
                    } else {
                      // Si la serpiente intenta cambiar de dirección en sentido opuesto, no permitirlo
                      return;
                    }
                  },

                  ///caja de la serpiente
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      width: gridSize * cellSize.toDouble(),
                      height: gridSize * cellSize.toDouble(),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.grey),
                      ),
                      child: Stack(children: [
                        //serpiente dibujo verde
                        for (final position in _snake)
                          Positioned(
                            left: position.dx * cellSize,
                            top: position.dy * cellSize,
                            child: Container(
                              width: cellSize.toDouble(),
                              height: cellSize.toDouble(),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                border:
                                    Border.all(width: 1.0, color: Colors.white),
                              ),
                            ),
                          ),

                        ///comida de la serpiente
                        Positioned(
                          left: _food.dx * cellSize,
                          top: _food.dy * cellSize,
                          child: Container(
                            width: cellSize.toDouble(),
                            height: cellSize.toDouble(),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(width: 1.0, color: Colors.white),
                            ),
                          ),
                        ),

                        ///condicional de reinicio
                        if (_gameOver)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Game Over',
                                      style: TextStyle(
                                        fontSize: 32.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16.0),
                                    TextButton(
                                      onPressed: _startGame,
                                      child: Text(
                                        'Restart',
                                        style: TextStyle(
                                          fontSize: 24.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                      ]),
                    ),
                  ))),
        ));
  }
}
