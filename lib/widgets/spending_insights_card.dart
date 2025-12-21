import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/transaction.dart';
import '../features/ai/ai_insights_service.dart';
import '../providers/ai_settings_provider.dart';

/// A card that displays AI-powered psychological spending insights
class SpendingInsightsCard extends StatefulWidget {
  final List<Transaction> transactions;

  const SpendingInsightsCard({
    super.key,
    required this.transactions,
  });

  @override
  State<SpendingInsightsCard> createState() => _SpendingInsightsCardState();
}

class _SpendingInsightsCardState extends State<SpendingInsightsCard> {
  final AIInsightsService _insightsService = AIInsightsService();
  SpendingInsights? _insights;
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _generateInsights();
  }

  @override
  void didUpdateWidget(SpendingInsightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions.length != oldWidget.transactions.length) {
      _generateInsights();
    }
  }

  Future<void> _generateInsights() async {
    if (widget.transactions.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final insights = await _insightsService.generateInsights(
        transactions: widget.transactions,
        periodDays: 30,
      );
      
      if (mounted) {
        setState(() {
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiSettings = context.watch<AISettingsProvider>();
    
    if (!aiSettings.smartCategorizationEnabled || widget.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'AI-powered analysis of your spending',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              
              if (_isExpanded && _insights != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Spending Personality
                _buildSection(
                  context,
                  icon: Icons.person_outline,
                  title: 'Your Spending Personality',
                  content: _insights!.spendingPersonality,
                  color: Colors.blue,
                ),
                
                const SizedBox(height: 16),
                
                // Financial Health
                _buildSection(
                  context,
                  icon: Icons.favorite_outline,
                  title: 'Financial Health Score',
                  content: _insights!.financialHealth,
                  color: _getHealthColor(_insights!.healthScore),
                  trailing: _buildHealthBadge(_insights!.healthScore),
                ),
                
                const SizedBox(height: 16),
                
                // Behavior Patterns
                if (_insights!.behaviorPatterns.isNotEmpty) ...[
                  _buildPatternsList(context),
                  const SizedBox(height: 16),
                ],
                
                // Recommendations
                if (_insights!.recommendations.isNotEmpty) ...[
                  _buildRecommendationsList(context),
                ],
                
                const SizedBox(height: 12),
                
                // Refresh button
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _generateInsights,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh Insights'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildHealthBadge(double score) {
    final color = _getHealthColor(score);
    final label = score >= 80 
        ? 'Excellent' 
        : score >= 60 
            ? 'Good' 
            : score >= 40 
                ? 'Fair' 
                : 'Needs Work';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${score.toInt()}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsList(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, size: 18, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'Behavior Patterns',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_insights!.behaviorPatterns.take(3).map((pattern) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pattern,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ))),
      ],
    );
  }

  Widget _buildRecommendationsList(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Text(
              'Recommendations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_insights!.recommendations.take(3).map((rec) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ))),
      ],
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// A compact widget showing quick spending tips
class QuickSpendingTips extends StatelessWidget {
  final List<Transaction> transactions;

  const QuickSpendingTips({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final tips = AIInsightsService().getQuickTips(transactions);
    if (tips.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tip = tips.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tip',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tip,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
