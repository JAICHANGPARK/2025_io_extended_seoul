import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mcp_dartantic/prompt.dart';

import '../main.dart';
import '../model/mcp_tool_item.dart';
import '../ui/chat_bubble.dart';
import '../ui/chat_loading_indicator.dart';
import '../ui/dialog/add_tool_dialog.dart';
import '../ui/token_usage_widget.dart';
import '../ui/tool_management_widget.dart';
import '../utils.dart';

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

  // Tab controller for right panel
  late TabController _tabController;

  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();
  final history = <ChatMessage>[ChatMessage.system(systemPrompt)];

  // Tool management
  final List<McpToolItem> availableTools = [];
  final Map<String, McpClient> mcpClients = {};

  bool isLoading = false;

  // Token usage tracking
  int currentPromptTokens = 0;
  int currentResponseTokens = 0;
  int currentTotalTokens = 0;
  int cumulativePromptTokens = 0;
  int cumulativeResponseTokens = 0;
  int cumulativeTotalTokens = 0;

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

  @override
  void initState() {
    super.initState();

    // Initialize tab controller for right panel
    _tabController = TabController(length: 2, vsync: this);

    // Initialize agent and tools
    /// TODO: [STEP01] init
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  Future initSetup() async {
    // Enable default logging
    /// TODO: [STEP01] Agents
  }

  Future initDefaultTools() async {
    /// TODO: [STEP01] 기본 툴 초기화
    // Initialize HuggingFace client
  }

  Future initTools() async {
    print('\nInitializing MCP Tools');

    // Clear existing tools
    setState(() {
      availableTools.clear();
      mcpClients.clear();
    });

    /// TODO: [STEP01] 기본 툴 초기화

    // Return active tools for agent initialization
    return getActiveTools();
  }

  Future initAgent(List<Tool> tools) async {
    /// TODO: [STEP01] Agents 초기화

    return agent;
  }

  // Get list of active tools
  List<Tool> getActiveTools() {
    /// TODO: [STEP01] 사용 가능한 툴 목록 확인
    return [];
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
            /// TODO: [STEP02] MCP Remote 추가
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
            /// TODO: [STEP02] MCP local 추가
          }
        }

        /// TODO: [STEP02] MCP mcpClients 추가
        if (newClient != null) {
          // Get tools from the new client

          /// TODO: [STEP02] agent 업데이트
          // Update agent with new tools
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding tool source: $e')));
      }
    }
  }

  // Update agent with current active tools
  /// TODO: [STEP02] updateAgent
  Future<void> updateAgent() async {
    setState(() {}); // Refresh UI after agent is updated
  }

  // Toggle tool active state
  void toggleTool(McpToolItem tool, bool isActive) {
    setState(() {
      tool.isActive = isActive;
    });
    updateAgent();
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
    /// TODO: [STEP01] SEND MESSAGE

    print('[result.output] ${result?.output}');

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

  void _incrementCounter() async {
    // await singleMcpServer();
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

                  /// TODO: [STEP01] 대화 내용 UI 추가
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

            /// TODO: [STEP02] 탭바 위젯 추가
            // Right panel with tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [Placeholder(), Placeholder()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
