import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/playing_card_widget.dart';

class RoundSummaryModal extends StatelessWidget {
  final GameRoundSummary summary;
  final int teamUserMarks;
  final int teamOpponentMarks;
  final int marksToWin;
  final VoidCallback onDealNextRound;
  final VoidCallback? onViewTrickHistory;

  const RoundSummaryModal({
    super.key,
    required this.summary,
    required this.teamUserMarks,
    required this.teamOpponentMarks,
    this.marksToWin = 6,
    required this.onDealNextRound,
    this.onViewTrickHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isWon = summary.isWinForUserTeam;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppTheme.modalBg.withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isWon ? AppTheme.gold : Colors.redAccent.shade400,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 35,
              spreadRadius: 5,
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWon
                        ? const Color(0xDD064E3B)
                        : const Color(0xDD7F1D1D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isWon
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isWon ? Colors.greenAccent : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isWon
                            ? 'Bid Succeeded (${summary.targetBid} Cleared)'
                            : 'Bid Failed',
                        style: TextStyle(
                          color: isWon
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFFECDD3),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Main Headline
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isWon ? '👑 ' : '💔 ', style: const TextStyle(fontSize: 22)),
                    Text(
                      isWon ? 'Round Won!' : 'Round Lost',
                      style: TextStyle(
                        color: isWon ? AppTheme.goldLight : Colors.red.shade200,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(isWon ? ' 🎉' : ' ⚔️', style: const TextStyle(fontSize: 22)),
                  ],
                ),

                const SizedBox(height: 4),

                // Subtitle
                Text(
                  'You & Kasun scored ${summary.teamPoints} points (Target was ${summary.targetBid})',
                  style: const TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Quick Points Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSummaryPill(
                      label: 'Target:',
                      value: '${summary.targetBid}',
                      valueColor: AppTheme.goldLight,
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryPill(
                      label: 'Won:',
                      value: '${summary.teamPoints}',
                      valueColor: const Color(0xFF34D399),
                      tag: (summary.teamPoints > summary.targetBid)
                          ? '+${summary.teamPoints - summary.targetBid} Extra'
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Match Marks Race
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF032019),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('🎯 ', style: TextStyle(fontSize: 11)),
                              Text(
                                'Match Progress (First to 6 Marks)',
                                style: TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Best of 11',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Team N/S Status
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF062D24),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.gold.withOpacity(0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'You & N',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$teamUserMarks / $marksToWin',
                                        style: const TextStyle(
                                          color: AppTheme.gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMarksChips(
                                    count: teamUserMarks,
                                    total: marksToWin,
                                    fillColor: AppTheme.gold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Opponents E/W Status
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF062D24),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0x3310B981)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Opp (E/W)',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$teamOpponentMarks / $marksToWin',
                                        style: const TextStyle(
                                          color: Color(0xFFFCA5A5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMarksChips(
                                    count: teamOpponentMarks,
                                    total: marksToWin,
                                    fillColor: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Detailed Breakdown Table
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF032019),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF021812),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(13)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text(
                                'CATEGORY / METRIC',
                                style: TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'YOU & KASUN',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'KAMAL & SUNIL',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Row 1: Points Won
                      _buildTableRow(
                        icon: '🃏',
                        title: 'Card Points Won',
                        subtitle: 'Sum: 304 Card Total',
                        teamVal: '${summary.teamPoints}',
                        teamPct:
                            '${(summary.teamPoints / 304 * 100).toStringAsFixed(1)}%',
                        oppVal: '${summary.opponentPoints}',
                        oppPct:
                            '${(summary.opponentPoints / 304 * 100).toStringAsFixed(1)}%',
                      ),
                      const Divider(height: 1, color: Color(0x2210B981)),
                      // Row 2: Marks Earned
                      _buildTableRow(
                        icon: '🪙',
                        title: 'Round Marks',
                        subtitle: '${summary.targetBid} bid evaluated',
                        teamVal: summary.marksWinnerTeam.index == 0
                            ? '+${summary.marksAwarded} Marks'
                            : '0 Marks',
                        oppVal: summary.marksWinnerTeam.index == 1
                            ? '+${summary.marksAwarded} Marks'
                            : '0 Marks',
                      ),
                      const Divider(height: 1, color: Color(0x2210B981)),
                      // Row 3: Tricks Won
                      _buildTableRow(
                        icon: '✋',
                        title: 'Tricks Taken (8 Total)',
                        subtitle: '',
                        teamVal: '${summary.teamTricksWon} tricks',
                        oppVal: '${summary.opponentTricksWon} tricks',
                      ),
                      const Divider(height: 1, color: Color(0x2210B981)),
                      // Row 4: Trump Reveal
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text('🔓 ', style: TextStyle(fontSize: 10)),
                                Text(
                                  'Trump Revealed',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              summary.trumpRevealedAtTrick != null
                                  ? 'Trick ${summary.trumpRevealedAtTrick} by ${summary.trumpRevealedBy?.displayName.split(' ').first ?? ''} (${summary.trumpSuit?.symbol ?? ''})'
                                  : 'Not Revealed',
                              style: const TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Major Cards Captured Strip
                if (summary.majorCardsCapturedByUserTeam.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF031C15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('✨ ', style: TextStyle(fontSize: 10)),
                            Text(
                              'Major Cards Captured (Your Team)',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: summary.majorCardsCapturedByUserTeam
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: PlayingCardWidget(
                                        card: c,
                                        width: 44,
                                        height: 64,
                                        showPointBadge: true,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Footer
                Row(
                  children: [
                    if (onViewTrickHistory != null)
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: onViewTrickHistory,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6EE7B7),
                            side: const BorderSide(color: Color(0xFF059669)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 14),
                              SizedBox(width: 4),
                              Text('Tricks (8)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    if (onViewTrickHistory != null) const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: onDealNextRound,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: const Color(0xFF062D24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Deal Next Round',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPill({
    required String label,
    required String value,
    required Color valueColor,
    String? tag,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF031C15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          if (tag != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0x88451A03),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: AppTheme.goldLight,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarksChips({
    required int count,
    required int total,
    required Color fillColor,
  }) {
    return Row(
      children: List.generate(total, (i) {
        final isFilled = i < count;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isFilled ? fillColor : const Color(0xFF021812),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isFilled
                    ? fillColor
                    : const Color(0xFF10B981).withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTableRow({
    required String icon,
    required String title,
    required String subtitle,
    required String teamVal,
    String? teamPct,
    required String oppVal,
    String? oppPct,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  teamVal,
                  style: const TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (teamPct != null)
                  Text(
                    teamPct,
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  oppVal,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (oppPct != null)
                  Text(
                    oppPct,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
