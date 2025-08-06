
// Widget to display token usage information
import 'package:flutter/material.dart';

class TokenUsageWidget extends StatelessWidget {
  final int promptTokens;
  final int responseTokens;
  final int totalTokens;
  final int cumulativePromptTokens;
  final int cumulativeResponseTokens;
  final int cumulativeTotalTokens;

  const TokenUsageWidget({
    super.key,
    required this.promptTokens,
    required this.responseTokens,
    required this.totalTokens,
    required this.cumulativePromptTokens,
    required this.cumulativeResponseTokens,
    required this.cumulativeTotalTokens,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Conversation Usage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUsageRow('Input tokens:', promptTokens),
            _buildUsageRow('Output tokens:', responseTokens),
            _buildUsageRow('Total tokens:', totalTokens),
            const Divider(height: 32),
            const Text(
              'Cumulative Usage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUsageRow('Input tokens:', cumulativePromptTokens),
            _buildUsageRow('Output tokens:', cumulativeResponseTokens),
            _buildUsageRow('Total tokens:', cumulativeTotalTokens),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}