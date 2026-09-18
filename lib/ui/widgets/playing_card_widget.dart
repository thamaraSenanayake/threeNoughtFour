import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../theme/app_theme.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool isFaceDown;
  final double width;
  final double height;
  final bool isPlayable;
  final bool isSelected;
  final bool showPointBadge;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.isFaceDown = false,
    this.width = 56,
    this.height = 84,
    this.isPlayable = false,
    this.isSelected = false,
    this.showPointBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isFaceDown || card == null) {
      return _buildCardBack();
    }
    return _buildCardFace(context);
  }

  Widget _buildCardBack() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: AppTheme.cardBackGradient,
          border: Border.all(color: const Color(0xFFFEF08A), width: 1.5),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: const Color(0xFFFDE047).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.shield_outlined,
              size: width * 0.35,
              color: const Color(0xFFFACC15).withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(BuildContext context) {
    final c = card!;
    final color = c.isRed ? AppTheme.suitRed : AppTheme.suitBlack;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: isPlayable
            ? Matrix4.translationValues(0, -10, 0)
            : isSelected
                ? Matrix4.translationValues(0, -6, 0)
                : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.gold
                : isPlayable
                    ? AppTheme.gold
                    : const Color(0xFFD1D5DB),
            width: (isPlayable || isSelected) ? 2 : 1,
          ),
          boxShadow: isPlayable
              ? AppTheme.playableGlow
              : isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : AppTheme.cardShadow,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top left rank + suit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.rank.symbol,
                        style: TextStyle(
                          color: color,
                          fontSize: width * 0.22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        c.suit.symbol,
                        style: TextStyle(
                          color: color,
                          fontSize: width * 0.18,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  // Center suit symbol & point badge if requested
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.suit.symbol,
                        style: TextStyle(
                          color: color,
                          fontSize: width * 0.38,
                          height: 1,
                        ),
                      ),
                      if (showPointBadge || c.points > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2.5, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: c.isRed
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${c.points}p',
                            style: TextStyle(
                              color: c.isRed
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF92400E),
                              fontSize: width * 0.14,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Bottom right inverted rank + suit
                  RotatedBox(
                    quarterTurns: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.rank.symbol,
                          style: TextStyle(
                            color: color,
                            fontSize: width * 0.22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          c.suit.symbol,
                          style: TextStyle(
                            color: color,
                            fontSize: width * 0.18,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Playable tag on top
            if (isPlayable)
              Positioned(
                top: -1,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            // Selected checkmark tag
            if (isSelected)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 10,
                      color: Color(0xFF062D24),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
