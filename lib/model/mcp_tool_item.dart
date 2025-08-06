// Class to represent an MCP tool with active state


import 'package:dartantic_interface/dartantic_interface.dart';

class McpToolItem {
  final Tool tool;
  final String source;
  bool isActive;

  McpToolItem({required this.tool, required this.source, this.isActive = true});
}
