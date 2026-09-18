import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import '../../models/trick_model.dart';
import '../theme/app_theme.dart';
import 'playing_card_widget.dart';

class TrickArenaWidget extends StatelessWidget {
  final Trick? currentTrick;
  final PlayingCard? hiddenTrumpCard;
  final bool isTrumpOpen;
  final PlayerPosition currentTurn;
  final VoidCallback? onTrumpSlotTap;

  const TrickArenaWidget({
    super.key,
    required this.currentTrick,
    required this.hiddenTrumpCard,
    required this.isTrumpOpen,
    required this.currentTurn,
    this.onTrumpSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    PlayedCard? northCard;
    PlayedCard? westCard;
    PlayedCard? eastCard;
    PlayedCard? southCard;

    if (currentTrick != null) {
      for (final pc in currentTrick!.playedCards) {
        if (pc.player == PlayerPosition.north) northCard = pc;
        if (pc.player == PlayerPosition.west) westCard = pc;
        if (pc.player == PlayerPosition.east) eastCard = pc;
        if (pc.player == PlayerPosition.south) southCard = pc;
      }
    }

    final isUserTurn = currentTurn == PlayerPosition.south && southCard == null;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Felt ring pattern
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.15),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.08),
                width: 1,
              ),
            ),
          ),

          // Hidden Trump Slot (Left Position)
          Positioned(
            left: 8,
            child: _buildHiddenTrumpSlot(),
          ),

          // Center Trick Play Arena
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lead Suit Pill (Center)
                  if (currentTrick?.leadSuit != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xEE021E17),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5), width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 4)
                        ],
                      ),
                      child: Text(
                        'Suit: ${currentTrick!.leadSuit!.symbol} ${currentTrick!.leadSuit!.label}',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // North Card (Top)
                  Positioned(
                    top: 0,
                    child: _buildTrickSlot(
                      playedCard: northCard,
                      positionLabel: 'N',
                      badgeColor: Colors.cyan,
                      rotation: -0.05,
                    ),
                  ),

                  // West Card (Left)
                  Positioned(
                    left: 6,
                    child: _buildTrickSlot(
                      playedCard: westCard,
                      positionLabel: 'W',
                      badgeColor: const Color(0xFFF43F5E),
                      rotation: -0.15,
                    ),
                  ),

                  // East Card (Right)
                  Positioned(
                    right: 6,
                    child: _buildTrickSlot(
                      playedCard: eastCard,
                      positionLabel: 'E',
                      badgeColor: Colors.purpleAccent,
                      rotation: 0.15,
                    ),
                  ),

                  // South Card / Empty Drop Slot (Bottom)
                  Positioned(
                    bottom: 0,
                    child: isUserTurn
                        ? _buildUserTurnEmptySlot()
                        : _buildTrickSlot(
                            playedCard: southCard,
                            positionLabel: 'S',
                            badgeColor: AppTheme.gold,
                            rotation: 0.03,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenTrumpSlot() {
    return GestureDetector(
      onTap: onTrumpSlotTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (isTrumpOpen && hiddenTrumpCard != null)
                PlayingCardWidget(
                  card: hiddenTrumpCard,
                  width: 38,
                  height: 56,
                  showPointBadge: true,
                )
              else
                Container(
                  width: 38,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: AppTheme.cardBackGradient,
                    border: Border.all(color: AppTheme.gold, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xDD451A03),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 11,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                ),
              if (!isTrumpOpen)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3.5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            isTrumpOpen ? 'Trump Suit' : 'Hidden Trump',
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isTrumpOpen && hiddenTrumpCard != null)
            Text(
              '${hiddenTrumpCard!.suit.symbol} ${hiddenTrumpCard!.suit.label}',
              style: TextStyle(
                color: hiddenTrumpCard!.isRed
                    ? const Color(0xFFFCA5A5)
                    : Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrickSlot({
    required PlayedCard? playedCard,
    required String positionLabel,
    required Color badgeColor,
    required double rotation,
  }) {
    if (playedCard == null) {
      return const SizedBox(width: 44, height: 64);
    }

    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PlayingCardWidget(
            card: playedCard.card,
            width: 44,
            height: 64,
            showPointBadge: true,
          ),
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xEE0F172A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: badgeColor.withOpacity(0.6), width: 1),
              ),
              child: Text(
                positionLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTurnEmptySlot() {
    return Container(
      width: 46,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0x33064E3B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.gold,
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_upward, size: 14, color: AppTheme.gold),
          SizedBox(height: 2),
          Text(
            'YOUR\nTURN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFEF08A),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
