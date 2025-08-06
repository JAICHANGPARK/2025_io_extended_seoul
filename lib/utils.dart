import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_interface/dartantic_interface.dart';

import 'main.dart';

Future<void> singleMcpServer() async {
  print('\nSingle MCP Server');
  final huggingFace = McpClient.remote(
    'huggingface',
    url: Uri.parse('https://huggingface.co/mcp'),
    headers: {"Authorization": "Bearer ${huggingfaceKey}"},
  );

  final hgTools = await huggingFace.listTools();
  dumpTools('huggingface', hgTools);

  final obsidian = McpClient.local(
    'mcp-obsidian',
    command: "uvx",
    args: ["mcp-obsidian"],
    environment: {
      "OBSIDIAN_API_KEY": obsidianKey,
      "OBSIDIAN_HOST": "https://127.0.0.1",
      "OBSIDIAN_PORT": "27124",
    },
  );
  final obsidianTools = await obsidian.listTools();
  dumpTools('mcp-obsidian', obsidianTools);

  final provider = Providers.google;
  final agent = Agent.forProvider(
    provider,
    chatModelName: modelName,
    tools: [...obsidianTools, ...hgTools],
  );

  const query = '한국의 대표 llm 모델에 대해 정리해주고 이를 옵시디언에 문서로 저장해줘.';
  final result = await agent.send(
    query,
    // history: [ChatMessage.system('Be concise, reply with one sentence.')],
  );

  print(result.output);
}

void dumpTools(String name, Iterable<Tool> tools) {
  print('\n# $name');
  for (final tool in tools) {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(jsonDecode(tool.inputSchema.toJson()));
    print('\n## Tool');
    print('- name: ${tool.name}');
    print('- description: ${tool.description}');
    print('- inputSchema: $json');
  }
}
