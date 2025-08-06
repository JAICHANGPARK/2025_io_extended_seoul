import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter/material.dart';

import 'model/mcp_tool_item.dart';
import 'ui/chat_bubble.dart';
import 'ui/chat_loading_indicator.dart';
import 'ui/dialog/add_tool_dialog.dart';
import 'ui/token_usage_widget.dart';
import 'ui/tool_management_widget.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: const MyHomePage(title: '2025 I/O Extended Seoul'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  Agent? agent;
  TextEditingController textEditingController = TextEditingController();
  final history = <ChatMessage>[
    ChatMessage.system("""<ROLE>
You are a helpful and professional AI assistant. You have access to a set of tools to find specific, real-time, or local information. Your main goal is to provide the most accurate and helpful answer to the user's question.
</ROLE>

----

<INSTRUCTIONS>
Step 1: Analyze the user's question.
- Understand the user's core intent.

Step 2: Decide whether to use a tool.
- First, check if any of your available tools are directly relevant to answering the question. For example, use a local file search tool for questions about personal notes.
- **If no tool is suitable for the question, answer it directly using your general knowledge.** Do not try to force the use of an irrelevant tool.
- If a tool is relevant, pick the best one to use.

Step 3: Formulate the answer.
- If you used a tool, base your answer primarily on the information from the tool's output.
- If you did not use a tool, provide a comprehensive and helpful answer based on your own knowledge.
- Always answer in the same language as the user's question. Your tone should be polite and professional.

Step 4: Provide the source (only if you used a tool).
- If you used a tool and it provided a valid URL, list it under a "**Source**" heading.
</INSTRUCTIONS>

----

<OUTPUT_FORMAT>
(concise and helpful answer to the question)

**Source**(if applicable)
- (source1: valid URL)
- (source2: valid URL)
- ...
</OUTPUT_FORMAT>
"""),
  ];
  bool isLoading = false;

  // Tool management
  final List<McpToolItem> availableTools = [];
  final Map<String, McpClient> mcpClients = {};

  // Tab controller for right panel
  late TabController _tabController;

  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();

  // Auto-scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Token usage tracking
  int currentPromptTokens = 0;
  int currentResponseTokens = 0;
  int currentTotalTokens = 0;
  int cumulativePromptTokens = 0;
  int cumulativeResponseTokens = 0;
  int cumulativeTotalTokens = 0;

  Future initSetup() async {
    // Enable default logging
    Agent.loggingOptions = const LoggingOptions();

    Agent.environment['GEMINI_API_KEY'] =
    "AIzaSyBWNL-t4Wlcmvix3lubenRYq7p8OFWc050";
  }

  Future initTools() async {
    print('\nInitializing MCP Tools');

    // Clear existing tools
    setState(() {
      availableTools.clear();
      mcpClients.clear();
    });

    // Initialize HuggingFace client
    final huggingFace = McpClient.remote(
      'huggingface',
      url: Uri.parse('https://huggingface.co/mcp'),
      headers: {
        "Authorization": "Bearer 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",
      },
    );
    mcpClients['huggingface'] = huggingFace;

    // Get HuggingFace tools
    final hgTools = await huggingFace.listTools();
    dumpTools('huggingface', hgTools);

    // Add HuggingFace tools to available tools
    for (final tool in hgTools) {
      availableTools.add(McpToolItem(tool: tool, source: 'huggingface'));
    }

    // Initialize Obsidian client
    final obsidian = McpClient.local(
      'mcp-obsidian',
      command: "uvx",
      args: ["mcp-obsidian"],
      environment: {
        "OBSIDIAN_API_KEY":
        "78af999c43b94cd902168b1fe869e52166bdbcf4c51ae5ebb6e3f823e64b2c0b",
        "OBSIDIAN_HOST": "https://127.0.0.1",
        "OBSIDIAN_PORT": "27124",
      },
    );
    mcpClients['mcp-obsidian'] = obsidian;

    // Get Obsidian tools
    final obsidianTools = await obsidian.listTools();
    dumpTools('mcp-obsidian', obsidianTools);

    // Add Obsidian tools to available tools
    for (final tool in obsidianTools) {
      availableTools.add(McpToolItem(tool: tool, source: 'mcp-obsidian'));
    }

    // Return active tools for agent initialization
    return getActiveTools();
  }

  // Get list of active tools
  List<Tool> getActiveTools() {
    return availableTools
        .where((toolItem) => toolItem.isActive)
        .map((toolItem) => toolItem.tool)
        .toList();
  }

  // Update agent with current active tools
  Future<void> updateAgent() async {
    final activeTools = getActiveTools();
    agent = await initAgent(activeTools);
    setState(() {}); // Refresh UI after agent is updated
  }

  // Toggle tool active state
  void toggleTool(McpToolItem tool, bool isActive) {
    setState(() {
      tool.isActive = isActive;
    });
    updateAgent();
  }

  // Add a new MCP tool source
  Future<void> addToolSource(BuildContext context) async {
    // Show dialog to get tool source information
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddToolSourceDialog(),
    );

    if (result != null) {
      final String sourceType = result['type'];
      final String sourceName = result['name'];
      final Map<String, String> sourceConfig = result['config'];

      // Create and initialize the new MCP client
      McpClient? newClient;

      try {
        if (sourceType == 'remote') {
          final url = sourceConfig['url'];
          final headers = <String, String>{};

          if (sourceConfig.containsKey('authToken') &&
              sourceConfig['authToken']!.isNotEmpty) {
            headers['Authorization'] = 'Bearer ${sourceConfig['authToken']}';
          }

          if (url != null && url.isNotEmpty) {
            newClient = McpClient.remote(
              sourceName,
              url: Uri.parse(url),
              headers: headers,
            );
          }
        } else if (sourceType == 'local') {
          final command = sourceConfig['command'];
          // Parse arguments - handle both new pipe-separated format and old space-separated format
          final argsString = sourceConfig['args'] ?? '';
          final args = argsString.isEmpty
              ? <String>[]
              : argsString.contains('|')
              ? argsString.split('|').where((arg) => arg.isNotEmpty).toList()
              : argsString.split(' ').where((arg) => arg.isNotEmpty).toList();
          final environment = <String, String>{};

          // Parse environment variables
          sourceConfig.forEach((key, value) {
            if (key.startsWith('env_') && value.isNotEmpty) {
              environment[key.substring(4)] = value;
            }
          });

          if (command != null && command.isNotEmpty) {
            newClient = McpClient.local(
              sourceName,
              command: command,
              args: args,
              environment: environment,
            );
          }
        }

        if (newClient != null) {
          // Get tools from the new client
          final newTools = await newClient.listTools();

          setState(() {
            // Add client to the map
            mcpClients[sourceName] = newClient!;

            // Add tools to the available tools list
            for (final tool in newTools) {
              availableTools.add(McpToolItem(tool: tool, source: sourceName));
            }
          });

          // Update agent with new tools
          await updateAgent();
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding tool source: $e')));
      }
    }
  }

  // Remove a tool source
  void removeToolSource(String sourceName) {
    setState(() {
      // Remove tools from this source
      availableTools.removeWhere((tool) => tool.source == sourceName);

      // Remove client
      mcpClients.remove(sourceName);
    });

    // Update agent with remaining tools
    updateAgent();
  }

  Future initAgent(List<Tool> tools) async {
    final provider = Providers.google;
    final agent = Agent.forProvider(
      provider,
      chatModelName: 'gemini-2.5-flash',
      tools: tools,
    );
    return agent;
  }

  Future sendMessage(String query) async {
    // Add user message to history immediately
    final userMessage = ChatMessage.user(query);
    setState(() {
      history.add(userMessage);
      isLoading = true;
      textEditingController.clear();
    });

    // Scroll to bottom after adding user message
    _scrollToBottom();

    // Send message to agent
    var result = await agent?.send(
      query,
      history: history.sublist(0, history.length - 1),
    );

    print('[result?.output] ${result?.output}');



    // Update token usage if available
    if (result?.usage != null) {
      print('Input tokens: ${result?.usage.promptTokens}');
      print('Output tokens: ${result?.usage.responseTokens}');
      print('Total tokens: ${result?.usage.totalTokens}');
    }

    // Add response to history and update UI
    setState(() {
      history.removeLast();
      history.addAll(result?.messages ?? []);
      isLoading = false;

      // Update token usage statistics
      if (result?.usage != null) {
        // Get non-nullable values with defaults
        final promptTokens = result!.usage.promptTokens != null
            ? result.usage.promptTokens!
            : 0;
        final responseTokens = result.usage.responseTokens != null
            ? result.usage.responseTokens!
            : 0;
        final totalTokens = result.usage.totalTokens != null
            ? result.usage.totalTokens!
            : 0;

        // Update current conversation usage
        currentPromptTokens = promptTokens;
        currentResponseTokens = responseTokens;
        currentTotalTokens = totalTokens;

        // Update cumulative usage
        cumulativePromptTokens += promptTokens;
        cumulativeResponseTokens += responseTokens;
        cumulativeTotalTokens += totalTokens;
      }
    });

    // Scroll to bottom after adding AI response
    _scrollToBottom();
  }

  @override
  void initState() {
    super.initState();

    // Initialize tab controller for right panel
    _tabController = TabController(length: 2, vsync: this);

    // Initialize agent and tools
    initSetup().then((_) async {
      final tools = await initTools();
      agent = await initAgent(tools);
      setState(() {}); // Refresh UI after tools are loaded
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void _incrementCounter() async {
    await singleMcpServer();
  }

  Future<void> singleMcpServer() async {
    print('\nSingle MCP Server');
    final huggingFace = McpClient.remote(
      'huggingface',
      url: Uri.parse('https://huggingface.co/mcp'),
      headers: {
        "Authorization": "Bearer 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",
      },
    );

    final hgTools = await huggingFace.listTools();
    dumpTools('huggingface', hgTools);

    final obsidian = McpClient.local(
      'mcp-obsidian',
      command: "uvx",
      args: ["mcp-obsidian"],
      environment: {
        "OBSIDIAN_API_KEY":
        "78af999c43b94cd902168b1fe869e52166bdbcf4c51ae5ebb6e3f823e64b2c0b",
        "OBSIDIAN_HOST": "https://127.0.0.1",
        "OBSIDIAN_PORT": "27124",
      },
    );
    final obsidianTools = await obsidian.listTools();
    dumpTools('mcp-obsidian', obsidianTools);

    final provider = Providers.google;
    final agent = Agent.forProvider(
      provider,
      chatModelName: 'gemini-2.5-flash',
      tools: [...obsidianTools, ...hgTools],
    );

    const query = '한국의 대표 llm 모델에 대해 정리해주고 이를 옵시디언에 문서로 저장해줘.';
    final result = await agent.send(
      query,
      // history: [ChatMessage.system('Be concise, reply with one sentence.')],
    );

    print(result.output); // Output: one sentence on the origin of "hello world"
    // await agent.sendStream(query).forEach((r) => print(r.output));
    // stdout.writeln();
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

  @override
  Widget build(BuildContext context) {
    final displayHistory = history.where((message) {
      // ChatMessage.system()은 'system' 역할을 가집니다.
      // ChatMessage.user()는 'user' 역할을 가집니다.
      // ChatMessage.model()은 'model' 역할을 가집니다.
      print('[message.role]: ${message.role}');
      return message.role.name != 'system';
    }).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 24,
          children: [
            Expanded(
              child: Column(
                spacing: 12,
                children: [
                  OverflowBar(
                    alignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // 시스템 프롬프트(첫 번째 메시지)만 남기고 나머지 삭제
                            if (history.isNotEmpty) {
                              final systemMessage = history.first;
                              history.clear();
                              history.add(systemMessage);
                            }

                            // 토큰 사용량도 초기화
                            currentPromptTokens = 0;
                            currentResponseTokens = 0;
                            currentTotalTokens = 0;
                            cumulativePromptTokens = 0;
                            cumulativeResponseTokens = 0;
                            cumulativeTotalTokens = 0;
                          });
                        },
                        child: Text("대화 초기화"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        // Show regular message from the filtered list
                        if (index < displayHistory.length) {
                          // displayHistory를 사용하도록 수정
                          return ChatBubble(message: displayHistory[index]);
                        }
                        // Show loading indicator
                        else {
                          return const ChatLoadingIndicator();
                        }
                      },
                      // itemCount를 displayHistory.length 기준으로 수정
                      itemCount: isLoading
                          ? displayHistory.length + 1
                          : displayHistory.length,
                    ),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          decoration: InputDecoration(
                            hintText: "프롬프트 입력",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (text) {
                            if (text.isEmpty) return;

                            sendMessage(text.trim());
                          },
                        ),
                      ),
                      CircleAvatar(
                        radius: 28,
                        child: IconButton(
                          onPressed: () {
                            if (textEditingController.text.isEmpty) return;
                            final query = textEditingController.text.trim();
                            sendMessage(query);
                          },
                          icon: Icon(Icons.send),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right panel with tabs
            Expanded(
              child: Column(
                children: [
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.analytics), text: 'Token Usage'),
                      Tab(icon: Icon(Icons.build), text: 'MCP Tools'),
                    ],
                  ),
                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Token usage tab
                        TokenUsageWidget(
                          promptTokens: currentPromptTokens,
                          responseTokens: currentResponseTokens,
                          totalTokens: currentTotalTokens,
                          cumulativePromptTokens: cumulativePromptTokens,
                          cumulativeResponseTokens: cumulativeResponseTokens,
                          cumulativeTotalTokens: cumulativeTotalTokens,
                        ),
                        // Tool management tab
                        ToolManagementWidget(
                          tools: availableTools,
                          clients: mcpClients,
                          onToolToggle: toggleTool,
                          onAddToolSource: () => addToolSource(context),
                          onRemoveToolSource: removeToolSource,
                        ),
                      ],
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
