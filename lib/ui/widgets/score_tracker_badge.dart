import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../theme/app_theme.dart';

class ScoreTrackerBadge extends StatelessWidget {
  final int targetBid;
  final Team biddingTeam;
  final int teamUserPoints;
  final int teamOpponentPoints;

  const ScoreTrackerBadge({
    super.key,
    required this.targetBid,
    required this.biddingTeam,
    required this.teamUserPoints,
    required this.teamOpponentPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD022C22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes, size: 12, color: AppTheme.gold),
                  const SizedBox(width: 4),
                  const Text(
                    'Target Bid: ',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$targetBid',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                ),
                child: Text(
                  biddingTeam.displayName,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0x33047857)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.cyanAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Team: ',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$teamUserPoints',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 12,
                color: const Color(0x44047857),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFB7185),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Opponents: ',
                    style: TextStyle(
                      color: Color(0xFFA7F3D0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$teamOpponentPoints',
                    style: const TextStyle(
                      color: Color(0xFFFECDD3),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
