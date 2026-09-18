enum Suit {
  spades('♠', 'Spades', true),
  hearts('♥', 'Hearts', false),
  diamonds('♦', 'Diamonds', false),
  clubs('♣', 'Clubs', true);

  final String symbol;
  final String label;
  final bool isBlack;

  const Suit(this.symbol, this.label, this.isBlack);
}

enum Rank {
  jack('J', 'Jack', 30, 8),
  nine('9', 'Nine', 20, 7),
  ace('A', 'Ace', 11, 6),
  ten('10', 'Ten', 10, 5),
  king('K', 'King', 3, 4),
  queen('Q', 'Queen', 2, 3),
  eight('8', 'Eight', 0, 2),
  seven('7', 'Seven', 0, 1);

  final String symbol;
  final String label;
  final int points;
  final int hierarchyRank; // Higher is stronger

  const Rank(this.symbol, this.label, this.points, this.hierarchyRank);
}

class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard({
    required this.suit,
    required this.rank,
  });

  String get id => '${rank.symbol}_${suit.name}';
  int get points => rank.points;
  int get hierarchyRank => rank.hierarchyRank;
  bool get isRed => !suit.isBlack;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => '${rank.symbol}${suit.symbol}';
}
