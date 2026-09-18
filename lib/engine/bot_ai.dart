import 'dart:math';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/trick_model.dart';

class BotAI {
  final Random _random = Random();

  /// Evaluates hand for bidding power based on J (30), 9 (20), A (11), 10 (10)
  int evaluateBiddingPotential(List<PlayingCard> hand) {
    int score = 0;
    final Map<Suit, int> suitPoints = {
      Suit.spades: 0,
      Suit.hearts: 0,
      Suit.diamonds: 0,
      Suit.clubs: 0,
    };
    final Map<Suit, int> suitCounts = {
      Suit.spades: 0,
      Suit.hearts: 0,
      Suit.diamonds: 0,
      Suit.clubs: 0,
    };

    for (final card in hand) {
      suitPoints[card.suit] = (suitPoints[card.suit] ?? 0) + card.points;
      suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
    }

    // Find best potential trump suit
    Suit? bestSuit;
    int maxSuitScore = -1;
    for (final suit in Suit.values) {
      final pts = suitPoints[suit] ?? 0;
      final count = suitCounts[suit] ?? 0;
      final suitScore = pts + (count * 10);
      if (suitScore > maxSuitScore) {
        maxSuitScore = suitScore;
        bestSuit = suit;
      }
    }

    // Calculate maximum safe bid
    final totalPoints = hand.fold<int>(0, (sum, c) => sum + c.points);
    final hasJackInBestSuit = hand.any((c) => c.suit == bestSuit && c.rank == Rank.jack);
    final hasNineInBestSuit = hand.any((c) => c.suit == bestSuit && c.rank == Rank.nine);

    if (hasJackInBestSuit && hasNineInBestSuit) {
      score = 200 + totalPoints ~/ 2;
    } else if (hasJackInBestSuit) {
      score = 170 + totalPoints ~/ 3;
    } else if (hasNineInBestSuit && totalPoints >= 30) {
      score = 160;
    } else {
      score = 0; // Pass
    }

    return score;
  }

  /// Decide bot's bid given current highest bid
  int? decideBid({
    required List<PlayingCard> hand,
    required int currentHighestBid,
    required int minAllowedBid,
  }) {
    final potential = evaluateBiddingPotential(hand);
    if (potential >= minAllowedBid) {
      // Step up by 10 points or match minimum
      final nextBid = max(minAllowedBid, ((currentHighestBid ~/ 10) + 1) * 10);
      if (nextBid <= potential && nextBid <= 250) {
        return nextBid;
      }
    }
    return null; // Pass
  }

  /// Chooses the optimal trump card from the first 4 cards
  PlayingCard chooseTrumpCard(List<PlayingCard> hand) {
    if (hand.isEmpty) throw ArgumentError('Hand is empty');

    // Prefer Jack, then 9, then highest rank in the suit with most cards/points
    final jacks = hand.where((c) => c.rank == Rank.jack).toList();
    if (jacks.isNotEmpty) return jacks.first;

    final nines = hand.where((c) => c.rank == Rank.nine).toList();
    if (nines.isNotEmpty) return nines.first;

    final aces = hand.where((c) => c.rank == Rank.ace).toList();
    if (aces.isNotEmpty) return aces.first;

    // Highest rank card
    final sorted = List<PlayingCard>.from(hand)
      ..sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));
    return sorted.first;
  }

  /// Decide which card to play from hand
  PlayingCard decideCardToPlay({
    required List<PlayingCard> hand,
    required List<PlayingCard> validCards,
    required Trick currentTrick,
    required Suit? trumpSuit,
    required bool isTrumpOpen,
    required PlayerPosition botPosition,
  }) {
    if (validCards.length == 1) return validCards.first;

    // If leading the trick
    if (currentTrick.playedCards.isEmpty) {
      // If we hold top Jack / Nine / Ace of non-trump or trump (if open), lead it to win trick
      final highCards = validCards.where((c) => c.rank == Rank.jack || c.rank == Rank.nine || c.rank == Rank.ace).toList();
      if (highCards.isNotEmpty) {
        highCards.sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));
        return highCards.first;
      }
      // Otherwise lead a low card (7 or 8)
      final lowCards = validCards.where((c) => c.points == 0).toList();
      if (lowCards.isNotEmpty) {
        return lowCards[_random.nextInt(lowCards.length)];
      }
      return validCards[_random.nextInt(validCards.length)];
    }

    final leadSuit = currentTrick.leadSuit!;
    final canFollowSuit = validCards.any((c) => c.suit == leadSuit);

    if (canFollowSuit) {
      final followCards = validCards.where((c) => c.suit == leadSuit).toList();
      followCards.sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));

      // Check current winning card in trick
      final currentWinning = _getWinningCard(currentTrick.playedCards, trumpSuit, isTrumpOpen);
      final partnerPlayedWinning = currentWinning != null && currentWinning.player == botPosition.partner;

      if (partnerPlayedWinning) {
        // Partner is currently winning: feed points (Jack, 9, 10, Ace) or discard low
        final pointCards = followCards.where((c) => c.points > 0).toList();
        if (pointCards.isNotEmpty) {
          pointCards.sort((a, b) => b.points.compareTo(a.points));
          return pointCards.last; // Feed moderate/high points
        }
        return followCards.last; // Lowest
      } else {
        // Partner is NOT winning: try to beat current winning card if possible
        if (currentWinning != null && currentWinning.card.suit == leadSuit) {
          final winningFollowCards = followCards
              .where((c) => c.hierarchyRank > currentWinning.card.hierarchyRank)
              .toList();
          if (winningFollowCards.isNotEmpty) {
            // Play highest winning card
            return winningFollowCards.first;
          }
        }
        // Cannot win or partner winning: play lowest card
        return followCards.last;
      }
    } else {
      // Cannot follow suit (void in leadSuit)
      if (isTrumpOpen && trumpSuit != null) {
        final trumpCards = validCards.where((c) => c.suit == trumpSuit).toList();
        if (trumpCards.isNotEmpty) {
          trumpCards.sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));
          // Trump if partner isn't already winning
          final currentWinning = _getWinningCard(currentTrick.playedCards, trumpSuit, isTrumpOpen);
          final partnerWinning = currentWinning != null && currentWinning.player == botPosition.partner;
          if (!partnerWinning) {
            return trumpCards.first; // Trump high
          }
        }
      }

      // Discard lowest value card
      final sortedByPoints = List<PlayingCard>.from(validCards)
        ..sort((a, b) => a.points.compareTo(b.points));
      return sortedByPoints.first;
    }
  }

  PlayedCard? _getWinningCard(List<PlayedCard> playedCards, Suit? trumpSuit, bool isTrumpOpen) {
    if (playedCards.isEmpty) return null;
    final leadSuit = playedCards.first.card.suit;

    PlayedCard winner = playedCards.first;
    for (int i = 1; i < playedCards.length; i++) {
      final challenger = playedCards[i];
      if (isTrumpOpen && trumpSuit != null) {
        if (challenger.card.suit == trumpSuit && winner.card.suit != trumpSuit) {
          winner = challenger;
        } else if (challenger.card.suit == trumpSuit && winner.card.suit == trumpSuit) {
          if (challenger.card.hierarchyRank > winner.card.hierarchyRank) {
            winner = challenger;
          }
        } else if (winner.card.suit != trumpSuit && challenger.card.suit == leadSuit) {
          if (challenger.card.hierarchyRank > winner.card.hierarchyRank) {
            winner = challenger;
          }
        }
      } else {
        if (challenger.card.suit == leadSuit && challenger.card.hierarchyRank > winner.card.hierarchyRank) {
          winner = challenger;
        }
      }
    }
    return winner;
  }
}
