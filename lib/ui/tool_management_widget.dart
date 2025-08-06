// Widget to display and manage MCP tools
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mcp_dartantic/model/mcp_tool_item.dart';
import 'package:mcp_dart/mcp_dart.dart' as tool;

class ToolManagementWidget extends StatelessWidget {
  final List<McpToolItem> tools;
  final Map<String, McpClient> clients;
  final Function(McpToolItem, bool) onToolToggle;
  final VoidCallback onAddToolSource;
  final Function(String) onRemoveToolSource;

  const ToolManagementWidget({
    super.key,
    required this.tools,
    required this.clients,
    required this.onToolToggle,
    required this.onAddToolSource,
    required this.onRemoveToolSource,
  });

  @override
  Widget build(BuildContext context) {
    // Group tools by source
    final toolsBySource = <String, List<McpToolItem>>{};
    for (final tool in tools) {
      if (!toolsBySource.containsKey(tool.source)) {
        toolsBySource[tool.source] = [];
      }
      toolsBySource[tool.source]!.add(tool);
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MCP Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: onAddToolSource,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tool Source'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: toolsBySource.isEmpty
                  ? const Center(child: Text('No tools available'))
                  : ListView.builder(
                      itemCount: toolsBySource.length,
                      itemBuilder: (context, index) {
                        final source = toolsBySource.keys.elementAt(index);
                        final sourceTools = toolsBySource[source]!;
                        return _buildToolSourceSection(
                          context,
                          source,
                          sourceTools,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSourceSection(
    BuildContext context,
    String source,
    List<McpToolItem> tools,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(source, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onRemoveToolSource(source),
              tooltip: 'Remove this tool source',
            ),
          ],
        ),
        initiallyExpanded: true,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return ListTile(
                title: Text(tool.tool.name),
                subtitle: Text(
                  tool.tool.description ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Switch(
                  value: tool.isActive,
                  onChanged: (value) => onToolToggle(tool, value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
