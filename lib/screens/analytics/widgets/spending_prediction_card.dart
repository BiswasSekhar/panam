import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/ai/spending_predictor.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/ai_settings_provider.dart';
import '../../../widgets/common/glassmorphic_card.dart';

class SpendingPredictionCard extends StatelessWidget {
  const SpendingPredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiSettings = context.watch<AISettingsProvider>();
    
    // Only show if AI predictions are enabled
    if (!aiSettings.predictionsEnabled) {
      return const SizedBox.shrink();
    }

    final txProvider = context.watch<TransactionProvider>();
    final prediction = SpendingPredictor.predictNextMonth(txProvider.transactions);

    if (prediction == null) {
      return _buildNotEnoughDataCard(context, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights_rounded, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Spending Prediction',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassmorphicCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Predicted Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${prediction.predictedAmount.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrendChip(context, prediction),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Predicted spending next month',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Confidence meter
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Confidence',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: prediction.confidence,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: _getConfidenceColor(prediction.confidence, theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Explanation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prediction.explanation,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // View insights button
                TextButton.icon(
                  onPressed: () => _showInsightsDialog(context),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('View Spending Insights'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNotEnoughDataCard(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights_rounded, color: theme.colorScheme.outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Spending Prediction',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassmorphicCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.hourglass_empty_rounded,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not enough data yet',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add more transactions over 2+ months to enable AI predictions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTrendChip(BuildContext context, SpendingPrediction prediction) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color color;
    String text;

    switch (prediction.trend) {
      case 'increasing':
        icon = Icons.trending_up_rounded;
        color = theme.colorScheme.error;
        text = '+${prediction.percentageChange.abs().toStringAsFixed(0)}%';
      case 'decreasing':
        icon = Icons.trending_down_rounded;
        color = Colors.green;
        text = '-${prediction.percentageChange.abs().toStringAsFixed(0)}%';
      default:
        icon = Icons.trending_flat_rounded;
        color = theme.colorScheme.outline;
        text = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence, ThemeData theme) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return theme.colorScheme.error;
  }

  void _showInsightsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = context.read<TransactionProvider>();
    final insights = SpendingPredictor.getSpendingInsights(txProvider.transactions);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Spending Insights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About AI Predictions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Predictions are based on weighted moving averages and trend analysis '
                    'of your past transactions. The more data you have, the more accurate '
                    'the predictions become. All analysis is done locally on your device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
