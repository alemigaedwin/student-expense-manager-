import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_insights_service.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';

class _ChatEntry {
  final String text;
  final bool isUser;
  _ChatEntry(this.text, this.isUser);
}

class AiInsightsScreen extends StatefulWidget {
  AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final _askController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _chat = [];

  static final _suggestions = [
    'How much did I spend today?',
    'What is my top expense this month?',
    'How much have I saved this month?',
    "What's my budget status?",
  ];

  @override
  void dispose() {
    _askController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ask(String text) {
    final question = text.trim();
    if (question.isEmpty) return;
    final service = AiInsightsService(context.read<AppState>());
    setState(() {
      _chat.add(_ChatEntry(question, true));
      _chat.add(_ChatEntry(service.answer(question), false));
      _askController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final insights = AiInsightsService(app).generate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 22),
            SizedBox(width: 8),
            Text('AI Insights'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
              children: [
                Text('Your money coach',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'Computed on your device from your own transactions - '
                  'nothing is sent anywhere.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                SizedBox(height: 12),
                ...insights.map((i) => _InsightCard(insight: i)),
                SizedBox(height: 16),
                Divider(color: AppColors.border),
                SizedBox(height: 8),
                Text('Ask your AI money coach',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map((s) => ActionChip(
                            backgroundColor: AppColors.surfaceLight,
                            label: Text(s,
                                style: TextStyle(
                                    color: AppColors.textPrimary, fontSize: 12)),
                            onPressed: () => _ask(s),
                          ))
                      .toList(),
                ),
                SizedBox(height: 12),
                ..._chat.map((c) => _ChatBubble(entry: c)),
                SizedBox(height: 60),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _askController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. How much did I spend on food?',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                      ),
                      onSubmitted: _ask,
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _ask(_askController.text),
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
}

class _InsightCard extends StatelessWidget {
  final Insight insight;
  _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: insight.color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: insight.color.withOpacity(0.15),
            child: Icon(insight.icon, color: insight.color, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                SizedBox(height: 3),
                Text(insight.message,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatEntry entry;
  _ChatBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: entry.isUser ? AppColors.accent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(entry.text,
            style: TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}
