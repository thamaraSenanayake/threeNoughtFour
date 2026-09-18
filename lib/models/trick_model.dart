import 'card_model.dart';
import 'player_model.dart';

class PlayedCard {
  final PlayerPosition player;
  final PlayingCard card;

  const PlayedCard({
    required this.player,
    required this.card,
  });

  @override
  String toString() => '${player.shortCode}: $card';
}

class Trick {
  final int trickNumber; // 1 to 8
  final PlayerPosition leadPlayer;
  final List<PlayedCard> playedCards;
  PlayerPosition? winnerPlayer;
  PlayingCard? winningCard;
  int trickPoints;

  Trick({
    required this.trickNumber,
    required this.leadPlayer,
    List<PlayedCard>? playedCards,
    this.winnerPlayer,
    this.winningCard,
    this.trickPoints = 0,
  }) : playedCards = playedCards ?? [];

  Suit? get leadSuit => playedCards.isNotEmpty ? playedCards.first.card.suit : null;

  bool get isComplete => playedCards.length == 4;

  void addCard(PlayerPosition player, PlayingCard card) {
    playedCards.add(PlayedCard(player: player, card: card));
    trickPoints += card.points;
  }
}
