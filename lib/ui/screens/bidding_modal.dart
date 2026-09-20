import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import '../theme/app_theme.dart';
import '../widgets/playing_card_widget.dart';

class BiddingModal extends StatefulWidget {
  final int currentHighestBid;
  final PlayerPosition? currentLeadBidder;
  final List<PlayingCard> firstBatchHand;
  final bool isFinalTrumpSelection;
  final Function(int bid, PlayingCard trumpCard) onPlaceBidAndSetTrump;
  final VoidCallback onPass;

  const BiddingModal({
    super.key,
    required this.currentHighestBid,
    required this.currentLeadBidder,
    required this.firstBatchHand,
    this.isFinalTrumpSelection = false,
    required this.onPlaceBidAndSetTrump,
    required this.onPass,
  });

  @override
  State<BiddingModal> createState() => _BiddingModalState();
}

class _BiddingModalState extends State<BiddingModal> {
  late int _selectedBid;
  PlayingCard? _selectedTrumpCard;

  @override
  void initState() {
    super.initState();
    // Default bid: at least 160 or 10 points above current highest bid
    _selectedBid = widget.currentLeadBidder == null
        ? 160
        : widget.currentHighestBid + 10;
    if (_selectedBid < 160) _selectedBid = 160;
    if (_selectedBid > 304) _selectedBid = 304;

    if (widget.firstBatchHand.isNotEmpty) {
      _selectedTrumpCard = widget.firstBatchHand.first;
    }
  }

  void _increaseBid() {
    setState(() {
      if (_selectedBid < 300) {
        _selectedBid = ((_selectedBid ~/ 10) + 1) * 10;
      } else if (_selectedBid < 304) {
        _selectedBid = 304;
      }
    });
  }

  void _decreaseBid() {
    final minBid = widget.currentLeadBidder == null
        ? 160
        : widget.currentHighestBid + 10;
    setState(() {
      if (_selectedBid > minBid) {
        if (_selectedBid == 304) {
          _selectedBid = 300;
        } else {
          _selectedBid = ((_selectedBid ~/ 10) - 1) * 10;
        }
      }
    });
  }

  void _setBid(int bid) {
    setState(() {
      _selectedBid = bid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minBid = widget.currentLeadBidder == null
        ? 160
        : widget.currentHighestBid + 10;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppTheme.modalBg.withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.gold, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: AppTheme.modalHeaderGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border(
                    bottom: BorderSide(color: Color(0x33047857), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👑 ', style: TextStyle(fontSize: 16)),
                        Text(
                          widget.isFinalTrumpSelection
                              ? 'Set Hidden Trump'
                              : 'Bidding Round',
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xDD022C22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.isFinalTrumpSelection
                                    ? 'Winning Target: '
                                    : 'Current Lead: ',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '${widget.currentHighestBid}',
                                style: const TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.currentLeadBidder != null && !widget.isFinalTrumpSelection) ...[
                                const Text(' • ',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 10)),
                                Text(
                                  widget.currentLeadBidder!.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stepper Section (Only shown during bidding)
              if (!widget.isFinalTrumpSelection)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Stepper Dial
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF065F46), Color(0xFF021E17)],
                          ),
                          border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Minus Button
                            Positioned(
                              left: 4,
                              child: IconButton(
                                onPressed: _selectedBid > minBid ? _decreaseBid : null,
                                icon: const Icon(Icons.remove_circle),
                                color: AppTheme.gold,
                                disabledColor: Colors.white24,
                                iconSize: 28,
                              ),
                            ),
                            // Center Bid Value
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'YOUR BID',
                                  style: TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '$_selectedBid',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const Text(
                                  'POINTS',
                                  style: TextStyle(
                                    color: Color(0xFFFDE68A),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0x88047857),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Min: $minBid • Max: 304',
                                    style: const TextStyle(
                                      color: Color(0xFFA7F3D0),
                                      fontSize: 7.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Plus Button
                            Positioned(
                              right: 4,
                              child: IconButton(
                                onPressed: _selectedBid < 304 ? _increaseBid : null,
                                icon: const Icon(Icons.add_circle),
                                color: AppTheme.gold,
                                disabledColor: Colors.white24,
                                iconSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Quick Bid Chips
                      const Text(
                        'QUICK BID JUMPS',
                        style: TextStyle(
                          color: Color(0x996EE7B7),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [170, 180, 190, 200, 304].map((bid) {
                          final isCapot = bid == 304;
                          final isSelected = _selectedBid == bid;
                          final isEnabled = bid >= minBid;
                          return ChoiceChip(
                            label: Text(
                              isCapot ? 'Capot (304)' : '$bid',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF062D24)
                                    : isEnabled
                                        ? Colors.white
                                        : Colors.white30,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.gold,
                            backgroundColor: const Color(0xFF042E24),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.gold
                                  : isEnabled
                                      ? const Color(0xFF059669)
                                      : Colors.white12,
                            ),
                            onSelected: isEnabled ? (_) => _setBid(bid) : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // Trump Selection Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF03221B),
                  border: Border(
                    top: BorderSide(color: Color(0x33047857), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECT TRUMP CARD',
                                style: TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Choose suit from your first 4 cards',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x66451A03),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppTheme.gold.withOpacity(0.4)),
                          ),
                          child: const Text(
                            '🔒 Placed Face-Down',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // First 4 Cards Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widget.firstBatchHand.map((c) {
                        final isSelected = _selectedTrumpCard == c;
                        return PlayingCardWidget(
                          card: c,
                          width: 54,
                          height: 80,
                          isSelected: isSelected,
                          showPointBadge: true,
                          onTap: () {
                            setState(() {
                              _selectedTrumpCard = c;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    // Selected Trump Preview Bar
                    if (_selectedTrumpCard != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xCC022C22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.cardBackGradient,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: AppTheme.gold, width: 1),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.lock,
                                          size: 10, color: AppTheme.gold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trump: ${_selectedTrumpCard!.suit.label} (${_selectedTrumpCard!.suit.symbol})',
                                          style: TextStyle(
                                            color: _selectedTrumpCard!.isRed
                                                ? const Color(0xFFFCA5A5)
                                                : Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'Secret until Trump Reveal call',
                                          style: TextStyle(
                                            color: Color(0xFF6EE7B7),
                                            fontSize: 8.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.gold),
                              ),
                              child: Text(
                                '${_selectedTrumpCard!.rank.symbol} ${_selectedTrumpCard!.suit.symbol}',
                                style: TextStyle(
                                  color: _selectedTrumpCard!.isRed
                                      ? AppTheme.suitRed
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Action Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF021E17),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
                ),
                child: Row(
                  children: [
                    // Pass Button (Only if not in final trump confirmation)
                    if (!widget.isFinalTrumpSelection) ...[
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: widget.onPass,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 14),
                              SizedBox(width: 4),
                              Text('Pass Bid',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Bid / Set Trump Button
                    Expanded(
                      flex: widget.isFinalTrumpSelection ? 10 : 6,
                      child: ElevatedButton(
                        onPressed: _selectedTrumpCard != null
                            ? () {
                                widget.onPlaceBidAndSetTrump(
                                  _selectedBid,
                                  _selectedTrumpCard!,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: const Color(0xFF062D24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isFinalTrumpSelection
                              ? 'Set Trump & Deal Cards ➔'
                              : 'Bid $_selectedBid ➔',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
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
}
