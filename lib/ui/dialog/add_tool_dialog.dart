
// Dialog for adding a new tool source
import 'package:flutter/material.dart';

class AddToolSourceDialog extends StatefulWidget {
  @override
  _AddToolSourceDialogState createState() => _AddToolSourceDialogState();
}

class _AddToolSourceDialogState extends State<AddToolSourceDialog> {
  String sourceType = 'remote';
  final nameController = TextEditingController();
  final urlController = TextEditingController();
  final authTokenController = TextEditingController();
  final commandController = TextEditingController();
  final List<TextEditingController> argsControllers = [];
  final envVarsControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    authTokenController.dispose();
    commandController.dispose();
    for (final controller in argsControllers) {
      controller.dispose();
    }
    for (final controller in envVarsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void addEnvVar() {
    final key = 'env_${envVarsControllers.length}';
    setState(() {
      envVarsControllers[key] = TextEditingController();
    });
  }

  void addArg() {
    setState(() {
      argsControllers.add(TextEditingController());
    });
  }

  void removeArg(int index) {
    setState(() {
      argsControllers[index].dispose();
      argsControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Tool Source'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source type selection
            const Text('Source Type:'),
            Row(
              children: [
                Radio<String>(
                  value: 'remote',
                  groupValue: sourceType,
                  onChanged: (value) {
                    setState(() {
                      sourceType = value!;
                    });
                  },
                ),
                const Text('Remote'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'local',
                  groupValue: sourceType,
                  onChanged: (value) {
                    setState(() {
                      sourceType = value!;
                    });
                  },
                ),
                const Text('Local'),
              ],
            ),
            const SizedBox(height: 16),

            // Source name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Source Name',
                hintText: 'Enter a name for this tool source',
              ),
            ),
            const SizedBox(height: 16),

            // Remote source fields
            if (sourceType == 'remote') ...[
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'Enter the URL of the MCP server',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authTokenController,
                decoration: const InputDecoration(
                  labelText: 'Auth Token (optional)',
                  hintText: 'Enter the authentication token',
                ),
              ),
            ],

            // Local source fields
            if (sourceType == 'local') ...[
              TextField(
                controller: commandController,
                decoration: const InputDecoration(
                  labelText: 'Command',
                  hintText: 'Enter the command to run the MCP server',
                ),
              ),
              const SizedBox(height: 16),

              // Arguments section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Arguments:'),
                  TextButton.icon(
                    onPressed: addArg,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Argument'),
                  ),
                ],
              ),
              if (argsControllers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No arguments added. Click "Add Argument" to add command arguments.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...argsControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Argument ${index + 1}',
                            hintText: 'e.g., -y, --verbose, mcp-tool-name',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => removeArg(index),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        tooltip: 'Remove this argument',
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Environment variables
              const Text('Environment Variables:'),
              ...envVarsControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Variable ${entry.key.substring(4)}',
                      hintText: 'KEY=VALUE',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: addEnvVar,
                icon: const Icon(Icons.add),
                label: const Text('Add Environment Variable'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate inputs
            if (nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Source name is required')),
              );
              return;
            }

            if (sourceType == 'remote' && urlController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL is required for remote sources'),
                ),
              );
              return;
            }

            if (sourceType == 'local' && commandController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command is required for local sources'),
                ),
              );
              return;
            }

            // Prepare result
            final config = <String, String>{};

            if (sourceType == 'remote') {
              config['url'] = urlController.text;
              config['authToken'] = authTokenController.text;
            } else {
              config['command'] = commandController.text;

              // Collect arguments from individual controllers
              final argsList = argsControllers
                  .map((controller) => controller.text.trim())
                  .where((arg) => arg.isNotEmpty)
                  .toList();
              config['args'] = argsList.join(
                '|',
              ); // Use | as separator to avoid space conflicts

              // Add environment variables
              for (final entry in envVarsControllers.entries) {
                final text = entry.value.text;
                if (text.isNotEmpty) {
                  final parts = text.split('=');
                  if (parts.length == 2) {
                    config['env_${parts[0].trim()}'] = parts[1].trim();
                  }
                }
              }
            }

            Navigator.of(context).pop({
              'type': sourceType,
              'name': nameController.text,
              'config': config,
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
