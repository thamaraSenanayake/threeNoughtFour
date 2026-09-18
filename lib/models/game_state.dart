import 'card_model.dart';
import 'player_model.dart';
import 'trick_model.dart';

enum GamePhase {
  dealingFirstBatch,
  bidding,
  trumpSelection,
  dealingSecondBatch,
  playingTrick,
  trickWonDisplay,
  roundSummary,
  matchGameOver,
}

class GameRoundSummary {
  final bool isWinForUserTeam;
  final int teamPoints;
  final int opponentPoints;
  final int targetBid;
  final PlayerPosition bidderPosition;
  final Team biddingTeam;
  final int marksAwarded;
  final Team marksWinnerTeam;
  final int teamTricksWon;
  final int opponentTricksWon;
  final int? trumpRevealedAtTrick;
  final PlayerPosition? trumpRevealedBy;
  final Suit? trumpSuit;
  final List<PlayingCard> majorCardsCapturedByUserTeam;

  const GameRoundSummary({
    required this.isWinForUserTeam,
    required this.teamPoints,
    required this.opponentPoints,
    required this.targetBid,
    required this.bidderPosition,
    required this.biddingTeam,
    required this.marksAwarded,
    required this.marksWinnerTeam,
    required this.teamTricksWon,
    required this.opponentTricksWon,
    this.trumpRevealedAtTrick,
    this.trumpRevealedBy,
    this.trumpSuit,
    required this.majorCardsCapturedByUserTeam,
  });
}
