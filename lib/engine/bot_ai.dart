import 'dart:math';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/trick_model.dart';

class BotAI {
  final Random _random = Random();

  /// Evaluates hand for bidding power based on 304 card hierarchy & points:
  /// Jack (30), Nine (20), Ace (11), Ten (10), King (3), Queen (2), 8 (0), 7 (0).
  /// Total deck has 304 points. Initial hand has 4 cards.
  int evaluateBiddingPotential(List<PlayingCard> hand) {
    if (hand.isEmpty) return 0;

    final int totalHandPoints = hand.fold<int>(0, (sum, c) => sum + c.points);
    final jacks = hand.where((c) => c.rank == Rank.jack).toList();
    final nines = hand.where((c) => c.rank == Rank.nine).toList();
    final aces = hand.where((c) => c.rank == Rank.ace).toList();
    final tens = hand.where((c) => c.rank == Rank.ten).toList();

    // Group cards by suit
    final Map<Suit, List<PlayingCard>> suitCards = {
      Suit.spades: [],
      Suit.hearts: [],
      Suit.diamonds: [],
      Suit.clubs: [],
    };
    for (final card in hand) {
      suitCards[card.suit]!.add(card);
    }

    int bestTrumpScore = 0;

    for (final entry in suitCards.entries) {
      final cards = entry.value;
      if (cards.isEmpty) continue;

      final count = cards.length;
      final suitPoints = cards.fold<int>(0, (sum, c) => sum + c.points);
      final hasJack = cards.any((c) => c.rank == Rank.jack);
      final hasNine = cards.any((c) => c.rank == Rank.nine);
      final hasAce = cards.any((c) => c.rank == Rank.ace);
      final hasTen = cards.any((c) => c.rank == Rank.ten);

      int suitTrumpValue = 0;

      if (hasJack && hasNine) {
        // Jack + Nine in same suit: The two top trumps in 304 (guaranteed 50+ pts & 2 tricks)
        suitTrumpValue = 210 + (count * 10) + (suitPoints - 50);
      } else if (hasJack) {
        // Jack in suit (top trump)
        suitTrumpValue = 175 + (count * 10) + (suitPoints - 30);
        if (hasAce || hasTen) suitTrumpValue += 10;
      } else if (hasNine && (hasAce || hasTen || count >= 3)) {
        // 9 in suit with backup high cards or suit length
        suitTrumpValue = 165 + (count * 8) + (suitPoints - 20);
      } else if (hasAce && hasTen && count >= 2) {
        // Ace + Ten with suit support
        suitTrumpValue = 160 + (count * 8) + suitPoints ~/ 2;
      }

      if (suitTrumpValue > bestTrumpScore) {
        bestTrumpScore = suitTrumpValue;
      }
    }

    if (bestTrumpScore == 0) {
      return 0; // Hand is too weak to bid (less than standard minimum)
    }

    // High cards outside the chosen trump suit also win tricks / capture points
    int maxBid = bestTrumpScore + (totalHandPoints * 0.35).toInt();

    // Bonuses for multiple top honor holdings across suits
    if (jacks.length >= 2) maxBid += 25; // Multiple Jacks give massive trick control
    if (nines.length >= 2) maxBid += 15;
    if (aces.length >= 2) maxBid += 10;
    if (jacks.length + nines.length >= 3) maxBid += 20;

    // Round to nearest multiple of 10
    maxBid = ((maxBid + 4) ~/ 10) * 10;
    return maxBid.clamp(160, 304);
  }

  /// Decide bot's bid given current highest bid and partner's status
  int? decideBid({
    required List<PlayingCard> hand,
    required int currentHighestBid,
    required int minAllowedBid,
    bool isPartnerLeading = false,
  }) {
    final potential = evaluateBiddingPotential(hand);
    if (potential < minAllowedBid) {
      return null; // Cannot meet minimum required bid
    }

    if (isPartnerLeading) {
      // If partner is currently leading the bid:
      // Only raise if bot has a much stronger hand to upgrade trump (potential >= lead + 30)
      if (potential >= currentHighestBid + 30 && currentHighestBid <= 200) {
        final nextBid = max(minAllowedBid, ((currentHighestBid ~/ 10) + 1) * 10);
        if (nextBid <= potential) return nextBid;
      }
      return null; // Partner already leads, so pass to support partner
    }

    // Opponent is leading or no bid yet placed:
    final nextBid = max(minAllowedBid, ((currentHighestBid ~/ 10) + 1) * 10);
    if (nextBid <= potential && nextBid <= 304) {
      return nextBid;
    }
    return null; // Pass
  }

  /// Chooses the optimal trump card from the first 4 cards
  PlayingCard chooseTrumpCard(List<PlayingCard> hand) {
    if (hand.isEmpty) throw ArgumentError('Hand is empty');

    // Group cards by suit and find suit with best strength
    Suit? bestSuit;
    int maxSuitScore = -1;

    for (final suit in Suit.values) {
      final suitCards = hand.where((c) => c.suit == suit).toList();
      if (suitCards.isEmpty) continue;

      int score = 0;
      if (suitCards.any((c) => c.rank == Rank.jack)) score += 100;
      if (suitCards.any((c) => c.rank == Rank.nine)) score += 60;
      if (suitCards.any((c) => c.rank == Rank.ace)) score += 30;
      if (suitCards.any((c) => c.rank == Rank.ten)) score += 20;
      score += suitCards.length * 15;

      if (score > maxSuitScore) {
        maxSuitScore = score;
        bestSuit = suit;
      }
    }

    final targetSuitCards = hand.where((c) => c.suit == bestSuit).toList();
    if (targetSuitCards.isNotEmpty) {
      // Pick highest ranking card in that suit
      targetSuitCards.sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));
      return targetSuitCards.first;
    }

    // Fallback: pick Jack or 9
    final jacks = hand.where((c) => c.rank == Rank.jack).toList();
    if (jacks.isNotEmpty) return jacks.first;

    final nines = hand.where((c) => c.rank == Rank.nine).toList();
    if (nines.isNotEmpty) return nines.first;

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
      final highCards = validCards.where((c) => c.rank == Rank.jack || c.rank == Rank.nine || c.rank == Rank.ace).toList();
      if (highCards.isNotEmpty) {
        highCards.sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));
        return highCards.first;
      }
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

      final currentWinning = _getWinningCard(currentTrick.playedCards, trumpSuit, isTrumpOpen);
      final partnerPlayedWinning = currentWinning != null && currentWinning.player == botPosition.partner;

      if (partnerPlayedWinning) {
        final pointCards = followCards.where((c) => c.points > 0).toList();
        if (pointCards.isNotEmpty) {
          pointCards.sort((a, b) => b.points.compareTo(a.points));
          return pointCards.last;
        }
        return followCards.last;
      } else {
        if (currentWinning != null && currentWinning.card.suit == leadSuit) {
          final winningFollowCards = followCards
              .where((c) => c.hierarchyRank > currentWinning.card.hierarchyRank)
              .toList();
          if (winningFollowCards.isNotEmpty) {
            return winningFollowCards.first;
          }
        }
        return followCards.last;
      }
    } else {
      if (isTrumpOpen && trumpSuit != null) {
        final trumpCards = validCards.where((c) => c.suit == trumpSuit).toList();
        if (trumpCards.isNotEmpty) {
          trumpCards.sort((a, b) => b.hierarchyRank.compareTo(a.hierarchyRank));
          final currentWinning = _getWinningCard(currentTrick.playedCards, trumpSuit, isTrumpOpen);
          final partnerWinning = currentWinning != null && currentWinning.player == botPosition.partner;
          if (!partnerWinning) {
            return trumpCards.first;
          }
        }
      }

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
