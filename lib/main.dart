import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameData.instance.load();
  runApp(const TheSystemApp());
}

const Color kBlue = Color(0xFF3FA9FF);
const Color kBg = Color(0xFF050A18);

class Quest {
  final String id;
  final String name;
  final String emoji;
  final String stat;
  final int xp;
  const Quest(this.id, this.name, this.emoji, this.stat, this.xp);
}

const List<Quest> kQuests = [
  Quest('workout', 'تمرين', '🏋️', 'STR', 50),
  Quest('sleep', 'نوم 8 ساعات', '😴', 'VIT', 40),
  Quest('study', 'مذاكرة ساعة', '📚', 'INT', 60),
  Quest('work', 'شغل 4 ساعات', '💼', 'PER', 50),
  Quest('prayer', 'الصلوات الخمس', '🕌', 'SPI', 30),
];

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class GameData extends ChangeNotifier {
  static final GameData instance = GameData._();
  GameData._();

  int level = 1;
  int xp = 0;
  int streak = 0;
  String lastDate = '';
  Set<String> completedToday = {};
  Map<String, int> stats = {'STR': 0, 'VIT': 0, 'INT': 0, 'PER': 0, 'SPI': 0};

  int get xpToNext => 100 + (level - 1) * 50;
  int get completedCount => completedToday.length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    level = prefs.getInt('level') ?? 1;
    xp = prefs.getInt('xp') ?? 0;
    streak = prefs.getInt('streak') ?? 0;
    lastDate = prefs.getString('lastDate') ?? '';
    completedToday = (prefs.getStringList('completedToday') ?? []).toSet();
    final s = prefs.getString('stats');
    if (s != null) {
      stats = Map<String, int>.from(jsonDecode(s));
    }
    // Reset if new day
    final today = _dateStr(DateTime.now());
    if (lastDate != today) {
      final yesterday =
          _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate.isNotEmpty && lastDate != yesterday) {
        streak = 0;
      }
      completedToday = {};
      lastDate = today;
      await _save();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', level);
    await prefs.setInt('xp', xp);
    await prefs.setInt('streak', streak);
    await prefs.setString('lastDate', lastDate);
    await prefs.setStringList('completedToday', completedToday.toList());
    await prefs.setString('stats', jsonEncode(stats));
  }

  Future<bool> completeQuest(Quest q) async {
    if (completedToday.contains(q.id)) return false;
    final today = _dateStr(DateTime.now());
    if (lastDate != today) {
      final yesterday =
          _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday) {
        streak += 1;
      } else {
        streak = 1;
      }
      lastDate = today;
      completedToday = {};
    } else if (streak == 0) {
      streak = 1;
    }
    completedToday.add(q.id);
    stats[q.stat] = (stats[q.stat] ?? 0) + 1;
    xp += q.xp;
    bool leveled = false;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      level += 1;
      leveled = true;
    }
    await _save();
    notifyListeners();
    return leveled;
  }

  Future<void> resetAll() async {
    level = 1;
    xp = 0;
    streak = 0;
    stats = {'STR': 0, 'VIT': 0, 'INT': 0, 'PER': 0, 'SPI': 0};
    completedToday = {};
    lastDate = _dateStr(DateTime.now());
    await _save();
    notifyListeners();
  }
}

class TheSystemApp extends StatelessWidget {
  const TheSystemApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        primaryColor: kBlue,
        fontFamily: 'monospace',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameData.instance,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: idx,
              children: const [StatusScreen(), QuestsScreen()],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF0A1226),
            selectedItemColor: kBlue,
            unselectedItemColor: Colors.white38,
            currentIndex: idx,
            onTap: (i) => setState(() => idx = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'الحالة'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt), label: 'المهام'),
            ],
          ),
        );
      },
    );
  }
}

Widget _glowBox({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: kBlue, width: 1.5),
      boxShadow: [
        BoxShadow(color: kBlue.withOpacity(0.35), blurRadius: 16),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GameData.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _glowBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('S T A T U S',
                  style: TextStyle(
                      color: kBlue,
                      fontSize: 22,
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text('الاسم: لاعب',
                style: TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rank: ${_rank(g.level)}',
                    style: const TextStyle(color: Colors.white70)),
                Text('Level: ${g.level}',
                    style: const TextStyle(
                        color: kBlue, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _bar(
              value: g.xp,
              max: g.xpToNext,
              color: kBlue,
              label: 'XP  ${g.xp} / ${g.xpToNext}',
            ),
            const SizedBox(height: 8),
            _bar(
              value: g.completedCount,
              max: kQuests.length,
              color: Colors.greenAccent,
              label:
                  'اليوم  ${g.completedCount} / ${kQuests.length}',
            ),
            const SizedBox(height: 18),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            ...g.stats.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _statRow(e.key, e.value),
              );
            }),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔥 Streak: ${g.streak} يوم',
                    style: const TextStyle(color: Colors.orangeAccent)),
                TextButton(
                  onPressed: () => _confirmReset(context),
                  child: const Text('إعادة تعيين',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _rank(int lvl) {
    if (lvl >= 50) return 'S';
    if (lvl >= 35) return 'A';
    if (lvl >= 25) return 'B';
    if (lvl >= 15) return 'C';
    if (lvl >= 8) return 'D';
    return 'E';
  }

  Widget _bar(
      {required int value,
      required int max,
      required Color color,
      required String label}) {
    final pct = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.6), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statRow(String name, int value) {
    return Row(
      children: [
        SizedBox(
            width: 44,
            child: Text(name,
                style: const TextStyle(
                    color: kBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13))),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (value / 30).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
            width: 28,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A1226),
        title: const Text('تأكيد', style: TextStyle(color: kBlue)),
        content: const Text('هتفقد كل التقدم. متأكد؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              GameData.instance.resetAll();
              Navigator.pop(context);
            },
            child: const Text('نعم',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GameData.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _glowBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('D A I L Y   Q U E S T S',
                  style: TextStyle(
                      color: kBlue,
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ...kQuests.map((q) => _tile(context, q, g)),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Quest q, GameData g) {
    final done = g.completedToday.contains(q.id);
    return Opacity(
      opacity: done ? 0.45 : 1,
      child: InkWell(
        onTap: done
            ? null
            : () async {
                final leveled = await g.completeQuest(q);
                if (leveled && context.mounted) {
                  _showLevelUp(context, g.level);
                } else if (context.mounted) {
                  _showQuestDone(context, q);
                }
              },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
                color: done ? Colors.white24 : kBlue.withOpacity(0.5)),
            color: done ? Colors.white10 : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(q.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('+${q.xp} XP   •   ${q.stat}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? Colors.greenAccent : kBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuestDone(BuildContext context, Quest q) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF0A1226),
      content: Text('تم: ${q.name}  +${q.xp} XP',
          style: const TextStyle(color: kBlue)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showLevelUp(BuildContext context, int newLevel) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kBg,
            border: Border.all(color: kBlue, width: 2),
            boxShadow: [
              BoxShadow(color: kBlue.withOpacity(0.6), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠  N O T I F I C A T I O N',
                  style: TextStyle(
                      color: kBlue, letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 20),
              const Text('L E V E L   U P !',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 12),
              Text('وصلت إلى المستوى $newLevel',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً', style: TextStyle(color: kBlue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
