import 'package:flutter_test/flutter_test.dart';
import 'package:three_note_four/engine/bot_ai.dart';
import 'package:three_note_four/engine/game_engine.dart';
import 'package:three_note_four/models/card_model.dart';
import 'package:three_note_four/models/player_model.dart';
import 'package:three_note_four/models/trick_model.dart';
import 'package:three_note_four/models/game_state.dart';

void main() {
  group('304 Solo Play Engine Tests', () {
    late GameEngine engine;
    late BotAI botAI;

    setUp(() {
      engine = GameEngine();
      botAI = BotAI();
    });

    test('initDeck generates 32 cards with total 304 points', () {
      final deck = engine.initDeck();
      expect(deck.length, 32);

      int totalPoints = deck.fold<int>(0, (sum, c) => sum + c.points);
      expect(totalPoints, 304);

      // Verify card count per suit
      for (final suit in Suit.values) {
        final suitCards = deck.where((c) => c.suit == suit).toList();
        expect(suitCards.length, 8);

        // Jack=30, 9=20, A=11, 10=10, K=3, Q=2, 8=0, 7=0 = 76 pts per suit
        int suitPoints = suitCards.fold<int>(0, (sum, c) => sum + c.points);
        expect(suitPoints, 76);
      }
    });

    test('dealFirstBatch deals 4 cards to each player', () {
      engine.startNewRound();
      for (final player in engine.players) {
        expect(player.hand.length, 4);
      }
      expect(engine.deck.length, 16);
      expect(engine.currentPhase, GamePhase.bidding);
    });

    test('BotAI evaluateBiddingPotential calculates realistic bids for strong hands', () {
      // Hand with Jack (30) and 9 (20) in Spades -> Top 2 trumps in 304!
      final strongTrumpHand = [
        const PlayingCard(suit: Suit.spades, rank: Rank.jack),
        const PlayingCard(suit: Suit.spades, rank: Rank.nine),
        const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        const PlayingCard(suit: Suit.diamonds, rank: Rank.seven),
      ];
      final strongPotential = botAI.evaluateBiddingPotential(strongTrumpHand);
      expect(strongPotential, greaterThanOrEqualTo(230));

      // Hand with Jack (30) and Ace (11)
      final jackHand = [
        const PlayingCard(suit: Suit.hearts, rank: Rank.jack),
        const PlayingCard(suit: Suit.hearts, rank: Rank.eight),
        const PlayingCard(suit: Suit.spades, rank: Rank.ace),
        const PlayingCard(suit: Suit.diamonds, rank: Rank.king),
      ];
      final jackPotential = botAI.evaluateBiddingPotential(jackHand);
      expect(jackPotential, greaterThanOrEqualTo(200));

      // Weak hand: 8s and 7s
      final weakHand = [
        const PlayingCard(suit: Suit.hearts, rank: Rank.eight),
        const PlayingCard(suit: Suit.hearts, rank: Rank.seven),
        const PlayingCard(suit: Suit.spades, rank: Rank.eight),
        const PlayingCard(suit: Suit.diamonds, rank: Rank.queen),
      ];
      final weakPotential = botAI.evaluateBiddingPotential(weakHand);
      expect(weakPotential, 0); // Passes
    });

    test('Bot outbids opponent when holding stronger hand than current bid', () {
      final strongHand = [
        const PlayingCard(suit: Suit.spades, rank: Rank.jack),
        const PlayingCard(suit: Suit.spades, rank: Rank.nine),
        const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        const PlayingCard(suit: Suit.diamonds, rank: Rank.seven),
      ];

      // Opponent bid 170. Bot can and will outbid with 180!
      final decidedBid = botAI.decideBid(
        hand: strongHand,
        currentHighestBid: 170,
        minAllowedBid: 180,
        isPartnerLeading: false,
      );
      expect(decidedBid, 180);

      // Opponent bid 200. Bot can outbid with 210!
      final higherBid = botAI.decideBid(
        hand: strongHand,
        currentHighestBid: 200,
        minAllowedBid: 210,
        isPartnerLeading: false,
      );
      expect(higherBid, 210);
    });

    test('handleBidding and setTrumpCard transitions to trick play with 8 cards dealt', () {
      engine.startNewRound();
      
      // South bids 170
      final result = engine.handleBidding(
        playerPos: PlayerPosition.south,
        bid: 170,
      );
      expect(result, true);
      expect(engine.targetBid, 170);
      expect(engine.highestBidder, PlayerPosition.south);

      // All other players pass
      engine.handleBidding(playerPos: PlayerPosition.west, bid: null);
      engine.handleBidding(playerPos: PlayerPosition.north, bid: null);
      engine.handleBidding(playerPos: PlayerPosition.east, bid: null);

      expect(engine.currentPhase, GamePhase.trumpSelection);

      // South sets trump card
      final trumpCard = engine.userPlayer.hand.first;
      engine.setTrumpCard(trumpCard);

      expect(engine.hiddenTrumpCard, trumpCard);
      expect(engine.isTrumpOpen, false);
      expect(engine.currentPhase, GamePhase.playingTrick);

      // Verify 8 cards dealt
      for (final player in engine.players) {
        expect(player.hand.length, 8);
      }
    });

    test('validateCardPlay enforces following lead suit', () {
      final hand = [
        const PlayingCard(suit: Suit.spades, rank: Rank.jack),
        const PlayingCard(suit: Suit.spades, rank: Rank.seven),
        const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
      ];

      // Leading suit is spades
      expect(
        engine.validateCardPlay(
          const PlayingCard(suit: Suit.spades, rank: Rank.jack),
          hand,
          Suit.spades,
        ),
        true,
      );

      // Playing hearts when holding spades is illegal
      expect(
        engine.validateCardPlay(
          const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
          hand,
          Suit.spades,
        ),
        false,
      );

      // Void in clubs -> can play hearts or spades
      expect(
        engine.validateCardPlay(
          const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
          hand,
          Suit.clubs,
        ),
        true,
      );
    });

    test('evaluateTrickWinner evaluates lead suit ranking correctly before trump open', () {
      engine.startNewRound();
      engine.hiddenTrumpCard = const PlayingCard(suit: Suit.hearts, rank: Rank.jack);
      engine.isTrumpOpen = false;
      engine.startNextTrick();

      final trickCards = [
        const PlayedCard(
          player: PlayerPosition.south,
          card: PlayingCard(suit: Suit.spades, rank: Rank.ace), // 11 pts, rank 6
        ),
        const PlayedCard(
          player: PlayerPosition.west,
          card: PlayingCard(suit: Suit.spades, rank: Rank.jack), // 30 pts, rank 8 (Highest!)
        ),
        const PlayedCard(
          player: PlayerPosition.north,
          card: PlayingCard(suit: Suit.spades, rank: Rank.nine), // 20 pts, rank 7
        ),
        const PlayedCard(
          player: PlayerPosition.east,
          card: PlayingCard(suit: Suit.spades, rank: Rank.seven), // 0 pts, rank 1
        ),
      ];

      final winner = engine.evaluateTrickWinner(trickCards, Suit.hearts, false);
      expect(winner.winner, PlayerPosition.west);
      expect(winner.winningCard.rank, Rank.jack);
      expect(winner.pointsWon, 61); // 11 + 30 + 20 + 0
    });

    test('evaluateTrickWinner gives trump precedence after trump is revealed', () {
      engine.startNewRound();
      engine.hiddenTrumpCard = const PlayingCard(suit: Suit.hearts, rank: Rank.seven);
      engine.isTrumpOpen = true;
      engine.startNextTrick();

      final trickCards = [
        const PlayedCard(
          player: PlayerPosition.south,
          card: PlayingCard(suit: Suit.spades, rank: Rank.jack), // Jack of spades (non-trump)
        ),
        const PlayedCard(
          player: PlayerPosition.west,
          card: PlayingCard(suit: Suit.hearts, rank: Rank.seven), // 7 of Hearts (Trump!)
        ),
        const PlayedCard(
          player: PlayerPosition.north,
          card: PlayingCard(suit: Suit.spades, rank: Rank.nine),
        ),
        const PlayedCard(
          player: PlayerPosition.east,
          card: PlayingCard(suit: Suit.spades, rank: Rank.ace),
        ),
      ];

      final winner = engine.evaluateTrickWinner(trickCards, Suit.hearts, true);
      // West trumps with 7 of hearts
      expect(winner.winner, PlayerPosition.west);
      expect(winner.winningCard.suit, Suit.hearts);
    });

    test('checkTrumpRevealRequest opens trump when void in lead suit', () {
      engine.startNewRound();
      engine.hiddenTrumpCard = const PlayingCard(suit: Suit.diamonds, rank: Rank.jack);
      engine.isTrumpOpen = false;
      engine.startNextTrick();

      // Lead trick with Spades
      engine.currentTrick!.addCard(
        PlayerPosition.north,
        const PlayingCard(suit: Suit.spades, rank: Rank.ace),
      );

      // South has no spades
      engine.userPlayer.hand = [
        const PlayingCard(suit: Suit.hearts, rank: Rank.nine),
        const PlayingCard(suit: Suit.diamonds, rank: Rank.jack),
      ];

      expect(engine.canRequestTrumpReveal(PlayerPosition.south), true);
      final revealed = engine.checkTrumpRevealRequest(PlayerPosition.south);
      expect(revealed, true);
      expect(engine.isTrumpOpen, true);
      expect(engine.trumpRevealedBy, PlayerPosition.south);
    });
  });
}
