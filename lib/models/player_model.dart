import 'card_model.dart';

enum PlayerPosition {
  south('You (South)', 'S'),
  west('Bot 1 (West)', 'W'),
  north('Partner Bot (North)', 'N'),
  east('Bot 2 (East)', 'E');

  final String displayName;
  final String shortCode;

  const PlayerPosition(this.displayName, this.shortCode);

  PlayerPosition get next {
    return PlayerPosition.values[(index + 1) % 4];
  }

  PlayerPosition get partner {
    return PlayerPosition.values[(index + 2) % 4];
  }

  Team get team => (this == PlayerPosition.south || this == PlayerPosition.north)
      ? Team.teamUserPartner
      : Team.teamOpponents;
}

enum Team {
  teamUserPartner('You & Partner', 'team_ns'),
  teamOpponents('Opponents (E/W)', 'team_ew');

  final String displayName;
  final String code;

  const Team(this.displayName, this.code);

  Team get opposite =>
      this == Team.teamUserPartner ? Team.teamOpponents : Team.teamUserPartner;
}

class Player {
  final String id;
  final String name;
  final PlayerPosition position;
  final bool isBot;
  List<PlayingCard> hand;
  int? currentBid;
  bool hasPassed;
  String? lastActionText;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.isBot,
    List<PlayingCard>? hand,
    this.currentBid,
    this.hasPassed = false,
    this.lastActionText,
  }) : hand = hand ?? [];

  Team get team => position.team;

  void sortHand({Suit? trumpSuit}) {
    hand.sort((a, b) {
      if (a.suit != b.suit) {
        return a.suit.index.compareTo(b.suit.index);
      }
      return b.hierarchyRank.compareTo(a.hierarchyRank);
    });
  }

  bool hasSuit(Suit suit) {
    return hand.any((c) => c.suit == suit);
  }
}
