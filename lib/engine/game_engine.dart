import 'dart:math';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/trick_model.dart';
import '../models/game_state.dart';
import 'bot_ai.dart';

class GameEngine {
  final Random _random = Random();
  final BotAI botAI = BotAI();

  // Players
  late List<Player> players;
  
  // Deck
  List<PlayingCard> deck = [];

  // Match State
  int teamUserMarks = 0;
  int teamOpponentMarks = 0;
  final int marksToWin = 6;

  // Round State
  GamePhase currentPhase = GamePhase.dealingFirstBatch;
  int targetBid = 160;
  PlayerPosition? highestBidder;
  PlayerPosition currentBidderTurn = PlayerPosition.south;
  int consecutivePasses = 0;
  
  PlayingCard? hiddenTrumpCard;
  bool isTrumpOpen = false;
  PlayerPosition? trumpRevealedBy;
  int? trumpRevealedAtTrick;

  // Tricks & Points
  int currentTrickIndex = 0; // 0 to 7 (8 tricks)
  Trick? currentTrick;
  List<Trick> completedTricks = [];
  int teamUserPoints = 0;
  int teamOpponentPoints = 0;
  PlayerPosition currentTurn = PlayerPosition.south;

  // Captured major cards for recap
  List<PlayingCard> majorCardsCapturedByUserTeam = [];

  GameRoundSummary? lastRoundSummary;

  String userPlayerName = 'You';

  GameEngine({String playerName = 'You'}) : userPlayerName = playerName {
    initPlayers();
  }

  void initPlayers() {
    players = [
      Player(
        id: 'p_south',
        name: userPlayerName,
        position: PlayerPosition.south,
        isBot: false,
      ),
      Player(
        id: 'p_west',
        name: 'Bot 1',
        position: PlayerPosition.west,
        isBot: true,
      ),
      Player(
        id: 'p_north',
        name: 'Partner Bot',
        position: PlayerPosition.north,
        isBot: true,
      ),
      Player(
        id: 'p_east',
        name: 'Bot 2',
        position: PlayerPosition.east,
        isBot: true,
      ),
    ];
  }

  Player getPlayer(PlayerPosition position) => players[position.index];
  Player get userPlayer => players[PlayerPosition.south.index];
  Player get northPlayer => players[PlayerPosition.north.index];
  Player get westPlayer => players[PlayerPosition.west.index];
  Player get eastPlayer => players[PlayerPosition.east.index];

  Suit? get trumpSuit => isTrumpOpen ? hiddenTrumpCard?.suit : null;

  /// Generates the 32-card subset (J, 9, A, 10, K, Q, 8, 7 for all 4 suits)
  /// Point values: J=30, 9=20, A=11, 10=10, K=3, Q=2, 8=0, 7=0. Total = 304.
  List<PlayingCard> initDeck() {
    final List<PlayingCard> newDeck = [];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        newDeck.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return newDeck;
  }

  /// Starts a new round
  void startNewRound() {
    deck = initDeck();
    deck.shuffle(_random);

    for (final player in players) {
      player.hand.clear();
      player.currentBid = null;
      player.hasPassed = false;
      player.lastActionText = null;
    }

    targetBid = 160;
    highestBidder = null;
    currentBidderTurn = PlayerPosition.south;
    consecutivePasses = 0;
    hiddenTrumpCard = null;
    isTrumpOpen = false;
    trumpRevealedBy = null;
    trumpRevealedAtTrick = null;

    currentTrickIndex = 0;
    currentTrick = null;
    completedTricks.clear();
    teamUserPoints = 0;
    teamOpponentPoints = 0;
    majorCardsCapturedByUserTeam.clear();
    lastRoundSummary = null;

    dealFirstBatch();
    currentPhase = GamePhase.bidding;
  }

  /// Deals 4 cards to each player
  void dealFirstBatch() {
    for (int i = 0; i < 4; i++) {
      for (final player in players) {
        player.hand.add(deck.removeLast());
      }
    }
    for (final player in players) {
      player.sortHand();
    }
    currentPhase = GamePhase.bidding;
  }

  /// Handles a bid or pass by the current player
  bool handleBidding({required PlayerPosition playerPos, required int? bid}) {
    final player = getPlayer(playerPos);

    if (bid == null) {
      // Player passes
      player.hasPassed = true;
      player.lastActionText = 'Pass';
      consecutivePasses++;
    } else {
      if (bid < targetBid && highestBidder != null) {
        return false; // Invalid bid
      }
      player.currentBid = bid;
      player.lastActionText = 'Bid $bid';
      targetBid = bid;
      highestBidder = playerPos;
      consecutivePasses = 0;
    }

    // Check if bidding is concluded
    final activeBidders = players.where((p) => !p.hasPassed).toList();
    if (activeBidders.length <= 1 && highestBidder != null) {
      // Highest bidder is locked in
      currentPhase = GamePhase.trumpSelection;
      return true;
    }

    if (consecutivePasses >= 4 && highestBidder == null) {
      // All passed: Default to dealer or South takes 160
      highestBidder = PlayerPosition.south;
      targetBid = 160;
      currentPhase = GamePhase.trumpSelection;
      return true;
    }

    // Advance to next active bidder
    var nextPos = playerPos.next;
    while (getPlayer(nextPos).hasPassed) {
      nextPos = nextPos.next;
    }
    currentBidderTurn = nextPos;
    return true;
  }

  /// Automatically run bot bids until it's the human's turn or bidding finishes
  void advanceBotBiddingIfNeeded() {
    while (currentPhase == GamePhase.bidding && currentBidderTurn != PlayerPosition.south) {
      final bot = getPlayer(currentBidderTurn);
      final decidedBid = botAI.decideBid(
        hand: bot.hand,
        currentHighestBid: targetBid,
        minAllowedBid: highestBidder == null ? 160 : targetBid + 10,
      );
      handleBidding(playerPos: currentBidderTurn, bid: decidedBid);
    }

    if (currentPhase == GamePhase.trumpSelection && highestBidder != PlayerPosition.south) {
      // Bot chooses trump
      final bot = getPlayer(highestBidder!);
      final trumpChoice = botAI.chooseTrumpCard(bot.hand);
      setTrumpCard(trumpChoice);
    }
  }

  /// Stores the highest bidder's trump choice face-down in the center slot
  void setTrumpCard(PlayingCard card) {
    hiddenTrumpCard = card;
    isTrumpOpen = false;
    dealSecondBatch();
    currentPhase = GamePhase.playingTrick;
    currentTurn = highestBidder ?? PlayerPosition.south;
    startNextTrick();
  }

  /// Deals the remaining 4 cards to complete 8-card hands
  void dealSecondBatch() {
    for (int i = 0; i < 4; i++) {
      for (final player in players) {
        player.hand.add(deck.removeLast());
      }
    }
    for (final player in players) {
      player.sortHand(trumpSuit: isTrumpOpen ? hiddenTrumpCard?.suit : null);
    }
    currentPhase = GamePhase.playingTrick;
  }

  /// Starts a new trick
  void startNextTrick() {
    if (currentTrickIndex >= 8) {
      finishRound();
      return;
    }
    currentTrick = Trick(
      trickNumber: currentTrickIndex + 1,
      leadPlayer: currentTurn,
    );
  }

  /// Validates whether a card can be played given hand and leading suit
  bool validateCardPlay(PlayingCard card, List<PlayingCard> hand, Suit? leadingSuit) {
    if (!hand.contains(card)) return false;
    if (leadingSuit == null) return true; // Leading card can be anything

    final hasLeadSuit = hand.any((c) => c.suit == leadingSuit);
    if (hasLeadSuit) {
      return card.suit == leadingSuit;
    }
    // Void in leading suit: can play any card
    return true;
  }

  /// Returns list of valid playable cards for a player
  List<PlayingCard> getValidCardsForPlayer(PlayerPosition pos) {
    final player = getPlayer(pos);
    if (currentTrick == null) return player.hand;
    final leadSuit = currentTrick!.leadSuit;
    if (leadSuit == null) return player.hand;

    final hasLeadSuit = player.hasSuit(leadSuit);
    if (hasLeadSuit) {
      return player.hand.where((c) => c.suit == leadSuit).toList();
    }
    return player.hand;
  }

  /// Whether player can request Trump Reveal (must be void in lead suit & trump not yet open)
  bool canRequestTrumpReveal(PlayerPosition pos) {
    if (isTrumpOpen || hiddenTrumpCard == null) return false;
    if (currentTrick == null || currentTrick!.leadSuit == null) return false;
    final player = getPlayer(pos);
    return !player.hasSuit(currentTrick!.leadSuit!);
  }

  /// Triggers when a player cannot follow suit and requests the hidden card to be flipped face-up
  bool checkTrumpRevealRequest(PlayerPosition requestingPlayer) {
    if (!canRequestTrumpReveal(requestingPlayer)) return false;
    isTrumpOpen = true;
    trumpRevealedBy = requestingPlayer;
    trumpRevealedAtTrick = currentTrickIndex + 1;
    
    // Resort hands now that trump is known
    for (final player in players) {
      player.sortHand(trumpSuit: hiddenTrumpCard?.suit);
    }
    return true;
  }

  /// Plays a card for the current player
  bool playCard(PlayerPosition playerPos, PlayingCard card) {
    if (currentPhase != GamePhase.playingTrick) return false;
    if (currentTurn != playerPos) return false;
    if (currentTrick == null) return false;

    final player = getPlayer(playerPos);
    if (!validateCardPlay(card, player.hand, currentTrick!.leadSuit)) {
      return false;
    }

    player.hand.remove(card);
    currentTrick!.addCard(playerPos, card);

    if (currentTrick!.isComplete) {
      // Evaluate trick winner
      evaluateTrickWinner(
        currentTrick!.playedCards,
        hiddenTrumpCard?.suit,
        isTrumpOpen,
      );
      currentPhase = GamePhase.trickWonDisplay;
      return true;
    } else {
      currentTurn = playerPos.next;
      return true;
    }
  }

  /// Compares the 4 cards played in the trick, identifies winning card based on rank/trump,
  /// awards points to team, and sets lead for next trick.
  TrickWinner evaluateTrickWinner(
    List<PlayedCard> trickCards,
    Suit? tSuit,
    bool trumpOpen,
  ) {
    if (trickCards.isEmpty) {
      throw ArgumentError('No cards in trick');
    }

    final leadSuit = trickCards.first.card.suit;
    PlayedCard winningPlayedCard = trickCards.first;

    for (int i = 1; i < trickCards.length; i++) {
      final challenger = trickCards[i];
      if (trumpOpen && tSuit != null) {
        if (challenger.card.suit == tSuit && winningPlayedCard.card.suit != tSuit) {
          winningPlayedCard = challenger;
        } else if (challenger.card.suit == tSuit && winningPlayedCard.card.suit == tSuit) {
          if (challenger.card.hierarchyRank > winningPlayedCard.card.hierarchyRank) {
            winningPlayedCard = challenger;
          }
        } else if (winningPlayedCard.card.suit != tSuit && challenger.card.suit == leadSuit) {
          if (challenger.card.hierarchyRank > winningPlayedCard.card.hierarchyRank) {
            winningPlayedCard = challenger;
          }
        }
      } else {
        if (challenger.card.suit == leadSuit &&
            challenger.card.hierarchyRank > winningPlayedCard.card.hierarchyRank) {
          winningPlayedCard = challenger;
        }
      }
    }

    final winnerPos = winningPlayedCard.player;
    final winnerPlayer = getPlayer(winnerPos);
    final trickPts = trickCards.fold<int>(0, (sum, pc) => sum + pc.card.points);

    currentTrick!.winnerPlayer = winnerPos;
    currentTrick!.winningCard = winningPlayedCard.card;

    // Award points
    if (winnerPlayer.team == Team.teamUserPartner) {
      teamUserPoints += trickPts;
      for (final pc in trickCards) {
        if (pc.card.rank == Rank.jack || pc.card.rank == Rank.nine || pc.card.rank == Rank.ace) {
          majorCardsCapturedByUserTeam.add(pc.card);
        }
      }
    } else {
      teamOpponentPoints += trickPts;
    }

    return TrickWinner(
      winner: winnerPos,
      winningCard: winningPlayedCard.card,
      pointsWon: trickPts,
    );
  }

  /// Collects trick and moves to next trick or ends round
  void collectTrick() {
    if (currentTrick != null) {
      completedTricks.add(currentTrick!);
      currentTurn = currentTrick!.winnerPlayer ?? PlayerPosition.south;
      currentTrickIndex++;
    }

    if (currentTrickIndex >= 8) {
      finishRound();
    } else {
      currentPhase = GamePhase.playingTrick;
      startNextTrick();
    }
  }

  /// Automated bot turn play
  PlayingCard? playBotTurn() {
    if (currentPhase != GamePhase.playingTrick) return null;
    final bot = getPlayer(currentTurn);
    if (!bot.isBot) return null;

    // Decide whether bot wants to reveal trump (if void in suit and trump not open)
    if (canRequestTrumpReveal(currentTurn) && bot.position.team != (highestBidder?.team)) {
      // 50% chance opponent bot reveals trump when void
      if (_random.nextBool()) {
        checkTrumpRevealRequest(currentTurn);
      }
    }

    final validCards = getValidCardsForPlayer(currentTurn);
    final chosenCard = botAI.decideCardToPlay(
      hand: bot.hand,
      validCards: validCards,
      currentTrick: currentTrick!,
      trumpSuit: hiddenTrumpCard?.suit,
      isTrumpOpen: isTrumpOpen,
      botPosition: currentTurn,
    );

    playCard(currentTurn, chosenCard);
    return chosenCard;
  }

  /// Completes round and calculates marks
  void finishRound() {
    final bidder = highestBidder ?? PlayerPosition.south;
    final bTeam = bidder.team;
    final bidderTeamPoints = (bTeam == Team.teamUserPartner) ? teamUserPoints : teamOpponentPoints;
    final isBidSuccess = bidderTeamPoints >= targetBid;

    // Calculate marks
    int marks = 1;
    if (targetBid >= 200 && targetBid < 250) {
      marks = 2;
    } else if (targetBid >= 250 && targetBid < 304) {
      marks = 3;
    } else if (targetBid >= 304) {
      marks = 4; // Capot
    }

    final winningMarksTeam = isBidSuccess ? bTeam : bTeam.opposite;

    if (winningMarksTeam == Team.teamUserPartner) {
      teamUserMarks += marks;
    } else {
      teamOpponentMarks += marks;
    }

    final teamTricks = completedTricks.where((t) => getPlayer(t.winnerPlayer!).team == Team.teamUserPartner).length;
    final oppTricks = completedTricks.length - teamTricks;

    lastRoundSummary = GameRoundSummary(
      isWinForUserTeam: isBidSuccess ? (bTeam == Team.teamUserPartner) : (bTeam != Team.teamUserPartner),
      teamPoints: teamUserPoints,
      opponentPoints: teamOpponentPoints,
      targetBid: targetBid,
      bidderPosition: bidder,
      biddingTeam: bTeam,
      marksAwarded: marks,
      marksWinnerTeam: winningMarksTeam,
      teamTricksWon: teamTricks,
      opponentTricksWon: oppTricks,
      trumpRevealedAtTrick: trumpRevealedAtTrick,
      trumpRevealedBy: trumpRevealedBy,
      trumpSuit: hiddenTrumpCard?.suit,
      majorCardsCapturedByUserTeam: List.from(majorCardsCapturedByUserTeam),
    );

    if (teamUserMarks >= marksToWin || teamOpponentMarks >= marksToWin) {
      currentPhase = GamePhase.matchGameOver;
    } else {
      currentPhase = GamePhase.roundSummary;
    }
  }

  void resetMatch() {
    teamUserMarks = 0;
    teamOpponentMarks = 0;
    startNewRound();
  }
}

class TrickWinner {
  final PlayerPosition winner;
  final PlayingCard winningCard;
  final int pointsWon;

  const TrickWinner({
    required this.winner,
    required this.winningCard,
    required this.pointsWon,
  });
}
