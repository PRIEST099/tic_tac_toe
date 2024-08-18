import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class GameState with ChangeNotifier {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String _winner = '';
  bool _isSinglePlayer = true;

  List<String> get board => _board;
  String get currentPlayer => _currentPlayer;
  String get winner => _winner;
  bool get isSinglePlayer => _isSinglePlayer;

  void toggleMode() {
    _isSinglePlayer = !_isSinglePlayer;
    resetGame();
  }

  void playMove(int index) async {
    if (_board[index] == '' && _winner == '') {
      _board[index] = _currentPlayer;
      if (_checkWinner()) {
        _winner = _currentPlayer;
      } else if (_board.contains('')) {
        _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        notifyListeners();
        if (_isSinglePlayer && _currentPlayer == 'O') {
          await Future.delayed(Duration(milliseconds: 500));
          _playComputerMove();
        }
      } else {
        _winner = 'Draw';
      }
      notifyListeners();
    }
  }

  void _playComputerMove() {
    int bestMove = _minimax(_board, _currentPlayer)['index'];
    playMove(bestMove);
  }

  Map<String, dynamic> _minimax(List<String> newBoard, String player) {
    List<int> availSpots = [];
    for (int i = 0; i < newBoard.length; i++) {
      if (newBoard[i] == '') {
        availSpots.add(i);
      }
    }

    if (_checkWinnerForMinimax(newBoard, 'X')) {
      return {'score': -10};
    } else if (_checkWinnerForMinimax(newBoard, 'O')) {
      return {'score': 10};
    } else if (availSpots.isEmpty) {
      return {'score': 0};
    }

    List<Map<String, dynamic>> moves = [];

    for (var i = 0; i < availSpots.length; i++) {
      Map<String, dynamic> move = {};
      move['index'] = availSpots[i];
      newBoard[availSpots[i]] = player;

      if (player == 'O') {
        var result = _minimax(newBoard, 'X');
        move['score'] = result['score'];
      } else {
        var result = _minimax(newBoard, 'O');
        move['score'] = result['score'];
      }

      newBoard[availSpots[i]] = '';
      moves.add(move);
    }

    int bestMove = 0;
    if (player == 'O') {
      int bestScore = -10000;
      for (var i = 0; i < moves.length; i++) {
        if (moves[i]['score'] > bestScore) {
          bestScore = moves[i]['score'];
          bestMove = i;
        }
      }
    } else {
      int bestScore = 10000;
      for (var i = 0; i < moves.length; i++) {
        if (moves[i]['score'] < bestScore) {
          bestScore = moves[i]['score'];
          bestMove = i;
        }
      }
    }

    return moves[bestMove];
  }

  bool _checkWinnerForMinimax(List<String> board, String player) {
    const List<List<int>> winningCombinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combination in winningCombinations) {
      if (board[combination[0]] == player &&
          board[combination[0]] == board[combination[1]] &&
          board[combination[1]] == board[combination[2]]) {
        return true;
      }
    }
    return false;
  }

  bool _checkWinner() {
    const List<List<int>> winningCombinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combination in winningCombinations) {
      if (_board[combination[0]] != '' &&
          _board[combination[0]] == _board[combination[1]] &&
          _board[combination[1]] == _board[combination[2]]) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    _board = List.filled(9, '');
    _currentPlayer = 'X';
    _winner = '';
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 40, 38, 38),
          textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        ),
        home: TicTacToeScreen(),
      ),
    );
  }
}

class TicTacToeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic Tac Toe'),
        backgroundColor: const Color.fromARGB(255, 29, 146, 255),
        actions: [
          Text("Single/Multiplayer"),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () => context.read<GameState>().toggleMode(),
            tooltip: 'Switch Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerIndicator(),
                SizedBox(height: 20),
                Board(),
                SizedBox(height: 20),
                Consumer<GameState>(
                  builder: (context, gameState, child) {
                    return ElevatedButton(
                      onPressed: () => gameState.resetGame(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Restart', style: TextStyle(fontSize: 20)),
                    );
                  },
                ),
              ],
            ),
          ),
          WinnerDialog(),
        ],
      ),
    );
  }
}

class PlayerIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPlayerIndicator('X', gameState),
            SizedBox(width: 50),
            _buildPlayerIndicator('O', gameState),
          ],
        );
      },
    );
  }

  Widget _buildPlayerIndicator(String player, GameState gameState) {
    bool isCurrent = gameState.currentPlayer == player;
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.deepPurple : Colors.black54,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.6),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Text(
        'Player $player',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class Board extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: gameState.winner.isEmpty
                    ? () => gameState.playMove(index)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: Text(
                        gameState.board[index],
                        key: ValueKey<String>(gameState.board[index]),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class WinnerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (gameState.winner.isNotEmpty) {
          return Center(
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gameState.winner == 'Draw'
                            ? "It's a Draw!"
                            : 'Winner: ${gameState.winner}',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.read<GameState>().resetGame(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            Text('Play Again', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
