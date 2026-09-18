import 'dart:async';
import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';
import '../../models/card_model.dart';
import '../../models/game_state.dart';
import '../../models/player_model.dart';
import '../../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/player_avatar_widget.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/score_tracker_badge.dart';
import '../widgets/trick_arena_widget.dart';
import 'bidding_modal.dart';
import 'round_summary_modal.dart';

class TableScreen extends StatefulWidget {
  final String playerName;

  const TableScreen({
    super.key,
    this.playerName = 'You',
  });

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late final GameEngine _engine;
  final SoundService _soundService = SoundService();
  Timer? _botTurnTimer;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(playerName: widget.playerName);
    _soundService.init();
    _startFreshGame();
  }

  @override
  void dispose() {
    _botTurnTimer?.cancel();
    super.dispose();
  }

  void _startFreshGame() {
    _soundService.playCardDeal();
    _engine.startNewRound();
    _checkPhaseTransitions();
  }

  void _checkPhaseTransitions() {
    if (!mounted) return;

    if (_engine.currentPhase == GamePhase.bidding) {
      if (_engine.currentBidderTurn == PlayerPosition.south) {
        // Show Bidding Modal for User
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBiddingModal();
        });
      } else {
        // Advance bot bids
        _botTurnTimer?.cancel();
        _botTurnTimer = Timer(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _engine.advanceBotBiddingIfNeeded();
            _soundService.playBid();
          });
          _checkPhaseTransitions();
        });
      }
    } else if (_engine.currentPhase == GamePhase.trumpSelection) {
      if (_engine.highestBidder == PlayerPosition.south) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBiddingModal();
        });
      } else {
        _botTurnTimer?.cancel();
        _botTurnTimer = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _engine.advanceBotBiddingIfNeeded();
            _soundService.playCardDeal();
          });
          _checkPhaseTransitions();
        });
      }
    } else if (_engine.currentPhase == GamePhase.playingTrick) {
      if (_engine.currentTurn != PlayerPosition.south) {
        _botTurnTimer?.cancel();
        _botTurnTimer = Timer(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            _engine.playBotTurn();
            _soundService.playCardPlay();
          });
          _checkPhaseTransitions();
        });
      }
    } else if (_engine.currentPhase == GamePhase.trickWonDisplay) {
      _soundService.playTrickWin();
      _botTurnTimer?.cancel();
      _botTurnTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _engine.collectTrick();
        });
        _checkPhaseTransitions();
      });
    } else if (_engine.currentPhase == GamePhase.roundSummary ||
        _engine.currentPhase == GamePhase.matchGameOver) {
      if (_engine.lastRoundSummary?.isWinForUserTeam == true) {
        _soundService.playRoundWin();
      } else {
        _soundService.playRoundLose();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRoundSummaryModal();
      });
    }
  }

  void _showBiddingModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BiddingModal(
        currentHighestBid: _engine.targetBid,
        currentLeadBidder: _engine.highestBidder,
        firstBatchHand: _engine.userPlayer.hand.take(4).toList(),
        onPlaceBidAndSetTrump: (bid, trumpCard) {
          _soundService.playBid();
          Navigator.of(ctx).pop();
          setState(() {
            _engine.handleBidding(
              playerPos: PlayerPosition.south,
              bid: bid,
            );
            if (_engine.currentPhase == GamePhase.trumpSelection ||
                _engine.highestBidder == PlayerPosition.south) {
              _engine.setTrumpCard(trumpCard);
              _soundService.playCardDeal();
            }
          });
          _checkPhaseTransitions();
        },
        onPass: () {
          _soundService.playPass();
          Navigator.of(ctx).pop();
          setState(() {
            _engine.handleBidding(
              playerPos: PlayerPosition.south,
              bid: null,
            );
          });
          _checkPhaseTransitions();
        },
      ),
    );
  }

  void _showRoundSummaryModal() {
    if (!mounted || _engine.lastRoundSummary == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoundSummaryModal(
        summary: _engine.lastRoundSummary!,
        teamUserMarks: _engine.teamUserMarks,
        teamOpponentMarks: _engine.teamOpponentMarks,
        marksToWin: _engine.marksToWin,
        onDealNextRound: () {
          _soundService.playButtonClick();
          Navigator.of(ctx).pop();
          setState(() {
            if (_engine.currentPhase == GamePhase.matchGameOver) {
              _engine.resetMatch();
            } else {
              _engine.startNewRound();
            }
            _soundService.playCardDeal();
          });
          _checkPhaseTransitions();
        },
      ),
    );
  }

  void _onUserCardTap(PlayingCard card) {
    if (_engine.currentPhase != GamePhase.playingTrick) return;
    if (_engine.currentTurn != PlayerPosition.south) return;

    final validCards = _engine.getValidCardsForPlayer(PlayerPosition.south);
    if (!validCards.contains(card)) {
      _soundService.playPass();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Must follow suit (${_engine.currentTrick?.leadSuit?.symbol} ${_engine.currentTrick?.leadSuit?.label})!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF991B1B),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    _soundService.playCardPlay();
    setState(() {
      _engine.playCard(PlayerPosition.south, card);
    });
    _checkPhaseTransitions();
  }

  void _onTrumpRevealRequest() {
    if (_engine.canRequestTrumpReveal(PlayerPosition.south)) {
      _soundService.playTrumpReveal();
      setState(() {
        _engine.checkTrumpRevealRequest(PlayerPosition.south);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trump Revealed! Trump suit is ${_engine.trumpSuit?.symbol} ${_engine.trumpSuit?.label}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF065F46),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _soundService.playPass();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trump Reveal can only be requested when you have no cards of the led suit.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF854D0E),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validCards = _engine.getValidCardsForPlayer(PlayerPosition.south);
    final canRevealTrump = _engine.canRequestTrumpReveal(PlayerPosition.south);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.feltGreen,
            gradient: RadialGradient(
              center: Alignment(0, -0.1),
              radius: 1.2,
              colors: [
                Color(0xFF065F46),
                Color(0xFF064E3B),
                Color(0xFF022C22),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _soundService.playButtonClick();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppTheme.gold,
                            size: 18,
                          ),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '👑 304 ARENA',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0x99022C22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: const Text(
                            'SOLO',
                            style: TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _soundService.toggleSound();
                            });
                          },
                          icon: Icon(
                            _soundService.isSoundEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: const Color(0xFFA7F3D0),
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          onPressed: () => _showRulesDialog(),
                          icon: const Icon(
                            Icons.info_outline,
                            color: Color(0xFFA7F3D0),
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. North Section: Partner Bot
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerAvatarWidget(
                    player: _engine.northPlayer,
                    isCurrentTurn: _engine.currentTurn == PlayerPosition.north,
                    speechBubbleText: _engine.northPlayer.lastActionText,
                  ),
                  const SizedBox(height: 3),
                  // Partner Bot Cards (Face-down cards)
                  SizedBox(
                    height: 44,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _engine.northPlayer.hand.length,
                          (index) => const Align(
                            widthFactor: 0.65,
                            child: PlayingCardWidget(
                              isFaceDown: true,
                              width: 30,
                              height: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Middle Section: West Bot, Center Table Arena, East Bot
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // West Bot (Left)
                      SizedBox(
                        width: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerAvatarWidget(
                              player: _engine.westPlayer,
                              isCurrentTurn:
                                  _engine.currentTurn == PlayerPosition.west,
                              speechBubbleText: _engine.westPlayer.lastActionText,
                            ),
                            const SizedBox(height: 4),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _engine.westPlayer.hand.length,
                                (index) => const Align(
                                  heightFactor: 0.4,
                                  child: PlayingCardWidget(
                                    isFaceDown: true,
                                    width: 38,
                                    height: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_engine.westPlayer.hand.length} cards',
                              style: const TextStyle(
                                color: Color(0x996EE7B7),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center Table Area
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Score & Bid Tracker Badge
                            ScoreTrackerBadge(
                              targetBid: _engine.targetBid,
                              biddingTeam: _engine.highestBidder?.team ??
                                  Team.teamUserPartner,
                              teamUserPoints: _engine.teamUserPoints,
                              teamOpponentPoints: _engine.teamOpponentPoints,
                            ),
                            const SizedBox(height: 4),

                            // Trick Play Arena & Hidden Trump Slot
                            TrickArenaWidget(
                              currentTrick: _engine.currentTrick,
                              hiddenTrumpCard: _engine.hiddenTrumpCard,
                              isTrumpOpen: _engine.isTrumpOpen,
                              currentTurn: _engine.currentTurn,
                              onTrumpSlotTap: () {
                                if (_engine.isTrumpOpen &&
                                    _engine.hiddenTrumpCard != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Trump Suit is ${_engine.trumpSuit?.symbol} ${_engine.trumpSuit?.label}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: const Color(0xFF065F46),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // East Bot (Right)
                      SizedBox(
                        width: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerAvatarWidget(
                              player: _engine.eastPlayer,
                              isCurrentTurn:
                                  _engine.currentTurn == PlayerPosition.east,
                              speechBubbleText: _engine.eastPlayer.lastActionText,
                            ),
                            const SizedBox(height: 4),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _engine.eastPlayer.hand.length,
                                (index) => const Align(
                                  heightFactor: 0.4,
                                  child: PlayingCardWidget(
                                    isFaceDown: true,
                                    width: 38,
                                    height: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_engine.eastPlayer.hand.length} cards',
                              style: const TextStyle(
                                color: Color(0x996EE7B7),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Section: Player Hand & Controls
              Container(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xEE021E17)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Action Pill: 'Request Trump Reveal 🔓'
                    if (!_engine.isTrumpOpen && _engine.hiddenTrumpCard != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ElevatedButton(
                          onPressed: canRevealTrump ? _onTrumpRevealRequest : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            disabledBackgroundColor:
                                const Color(0x44FACC15),
                            foregroundColor: const Color(0xFF062D24),
                            disabledForegroundColor: Colors.white30,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: canRevealTrump ? 8 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Request Trump Reveal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(canRevealTrump ? '🔓' : '🔒',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),

                    // User status tip
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 13, color: AppTheme.gold),
                              const SizedBox(width: 4),
                              Text(
                                '${_engine.userPlayer.name} (South)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_engine.currentTrick?.leadSuit != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.gold.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Must follow suit (${_engine.currentTrick!.leadSuit!.symbol})',
                                style: const TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Horizontal Fan of Player's Cards
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _engine.userPlayer.hand.map((card) {
                              final isPlayable = _engine.currentPhase ==
                                      GamePhase.playingTrick &&
                                  _engine.currentTurn == PlayerPosition.south &&
                                  validCards.contains(card);

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                child: PlayingCardWidget(
                                  card: card,
                                  width: 54,
                                  height: 84,
                                  isPlayable: isPlayable,
                                  showPointBadge: true,
                                  onTap: () => _onUserCardTap(card),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog() {
    _soundService.playButtonClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.modalBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.gold, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: AppTheme.gold),
            SizedBox(width: 8),
            Text(
              '304 Card Game Rules',
              style: TextStyle(
                color: AppTheme.goldLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            '• Total 32 Cards (8 per suit).\n'
            '• Point Values:\n'
            '  Jack (J) = 30 pts\n'
            '  Nine (9) = 20 pts\n'
            '  Ace (A) = 11 pts\n'
            '  Ten (10) = 10 pts\n'
            '  King (K) = 3 pts\n'
            '  Queen (Q) = 2 pts\n'
            '  Eight (8) = 0 pts\n'
            '  Seven (7) = 0 pts\n'
            '  Total = 304 pts.\n\n'
            '• Ranking hierarchy: J > 9 > A > 10 > K > Q > 8 > 7.\n\n'
            '• Deal & Play:\n'
            '  1. 4 cards dealt first. Bidding starts at 160.\n'
            '  2. Highest bidder places secret Trump face-down.\n'
            '  3. Remaining 4 cards dealt (8 cards total).\n'
            '  4. Must follow suit. If void in suit, you can request Trump Reveal 🔓.\n'
            '  5. First team to 6 Marks wins the match!',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _soundService.playButtonClick();
              Navigator.of(ctx).pop();
            },
            child: const Text('Got it', style: TextStyle(color: AppTheme.gold)),
          )
        ],
      ),
    );
  }
}
