import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../theme/app_theme.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final String? speechBubbleText;
  final int cardCount;
  final Axis cardOrientation;

  const PlayerAvatarWidget({
    super.key,
    required this.player,
    this.isCurrentTurn = false,
    this.speechBubbleText,
    this.cardCount = 8,
    this.cardOrientation = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    Color avatarBorderColor;
    IconData avatarIcon;

    switch (player.position) {
      case PlayerPosition.north:
        avatarBorderColor = Colors.cyan;
        avatarIcon = Icons.smart_toy;
        break;
      case PlayerPosition.west:
        avatarBorderColor = const Color(0xFFF43F5E);
        avatarIcon = Icons.sports_kabaddi;
        break;
      case PlayerPosition.east:
        avatarBorderColor = Colors.purpleAccent;
        avatarIcon = Icons.psychology;
        break;
      case PlayerPosition.south:
        avatarBorderColor = AppTheme.gold;
        avatarIcon = Icons.person;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech Bubble
        if (speechBubbleText != null && speechBubbleText!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  speechBubbleText!,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Avatar Icon Circle with compass badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentTurn ? AppTheme.gold : avatarBorderColor.withOpacity(0.8),
                  width: isCurrentTurn ? 2.5 : 1.5,
                ),
                boxShadow: isCurrentTurn
                    ? [
                        BoxShadow(
                          color: AppTheme.gold.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 4,
                        )
                      ],
                color: const Color(0xFF0F172A),
              ),
              child: Icon(
                avatarIcon,
                size: 18,
                color: avatarBorderColor,
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: player.position == PlayerPosition.south ||
                          player.position == PlayerPosition.north
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF064E3B), width: 1),
                ),
                child: Text(
                  player.position.shortCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        // Name
        Text(
          player.name,
          style: const TextStyle(
            color: Color(0xFFD1FAE5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Position / Ally note
        Text(
          player.position == PlayerPosition.north
              ? 'North • Ally'
              : player.position == PlayerPosition.west
                  ? '(West)'
                  : player.position == PlayerPosition.east
                      ? '(East)'
                      : 'You',
          style: TextStyle(
            color: (player.position == PlayerPosition.north ||
                    player.position == PlayerPosition.south)
                ? const Color(0xFF6EE7B7)
                : const Color(0xFFFDA4AF),
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
