import 'package:flutter/material.dart';
import '../../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'table_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController(text: 'Player 1');
  final SoundService _soundService = SoundService();
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _soundService.init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startGame() {
    _soundService.playButtonClick();
    final name = _nameController.text.trim().isEmpty
        ? 'You'
        : _nameController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TableScreen(playerName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.feltGreen,
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.3,
              colors: [
                Color(0xFF075E45),
                Color(0xFF064E3B),
                Color(0xFF02231A),
                Color(0xFF01140E),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Top sound toggle & help
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x66022C22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x4410B981)),
                      ),
                      child: const Row(
                        children: [
                          Text('🇱🇰 ', style: TextStyle(fontSize: 12)),
                          Text(
                            'SRI LANKAN CLASSIC',
                            style: TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
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
                            color: AppTheme.gold,
                            size: 22,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showRulesDialog(),
                          icon: const Icon(
                            Icons.help_outline,
                            color: Color(0xFF6EE7B7),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Crown & Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFDE047), Color(0xFFCA8A04)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      color: Color(0xFF062D24),
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  '304 ARENA',
                  style: TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Traditional Sri Lankan Trick-Taking Card Game',
                  style: TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Four suits banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSuitIcon('♠', AppTheme.suitBlack),
                    const SizedBox(width: 12),
                    _buildSuitIcon('♥', AppTheme.suitRed),
                    const SizedBox(width: 12),
                    _buildSuitIcon('♦', AppTheme.suitRed),
                    const SizedBox(width: 12),
                    _buildSuitIcon('♣', AppTheme.suitBlack),
                  ],
                ),

                const SizedBox(height: 32),

                // Player Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.modalBg.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.8), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.gold, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'ENTER PLAYER NAME',
                            style: TextStyle(
                              color: AppTheme.goldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Your name (e.g. Kasun)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF03221B),
                          prefixIcon: const Icon(Icons.badge, color: AppTheme.gold),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF10B981)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Feature badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFeatureChip('🤖 3 Autonomous Bots'),
                          _buildFeatureChip('🃏 32-Card Deck (304 Pts)'),
                          _buildFeatureChip('🔒 Secret Hidden Trump'),
                          _buildFeatureChip('🎯 First to 6 Marks'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Start Game Button
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: AppTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withOpacity(0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ENTER 304 ARENA',
                            style: TextStyle(
                              color: Color(0xFF062D24),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF062D24), size: 26),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Footer version / credits
                const Text(
                  '304 Point values: J=30, 9=20, A=11, 10=10, K=3, Q=2, 8=0, 7=0',
                  style: TextStyle(
                    color: Color(0x99A7F3D0),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuitIcon(String symbol, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x66022C22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x4410B981)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD1FAE5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
