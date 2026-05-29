import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;

import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'cooking_gallery_screen.dart';
import 'recipe_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = speech_to_text.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String? _voiceError;

  @override
  void dispose() {
    _speech.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(RecipeProvider provider) async {
    final text = _messageController.text;
    _messageController.clear();
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available =
        _speechReady ||
        await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            setState(() => _isListening = status == 'listening');
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _voiceError = error.errorMsg;
            });
          },
        );

    if (!available) {
      setState(() => _voiceError = 'Voice input is not available.');
      return;
    }

    setState(() {
      _speechReady = true;
      _isListening = true;
      _voiceError = null;
    });

    await _speech.listen(
      listenOptions: speech_to_text.SpeechListenOptions(
        listenMode: speech_to_text.ListenMode.dictation,
      ),
      onResult: (result) {
        _messageController.text = result.recognizedWords;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        final themeProvider = context.watch<ThemeProvider>();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'PantryPal ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: themeProvider.toggleDarkMode,
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
              ),
              IconButton(
                tooltip: 'Saved recipes',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(RecipeResultScreen.routeName),
                icon: const Icon(Icons.favorite),
              ),
              IconButton(
                tooltip: 'Cooking gallery',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(CookingGalleryScreen.routeName),
                icon: const Icon(Icons.photo_library_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount:
                            provider.messages.length +
                            (provider.isLoading ? 1 : 0) +
                            1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _PromptSuggestions(
                              onSelected: (prompt) {
                                _messageController.text = prompt;
                                _sendMessage(provider);
                              },
                            );
                          }

                          final messageIndex = index - 1;
                          if (messageIndex == provider.messages.length) {
                            return const TypingIndicator();
                          }

                          final message = provider.messages[messageIndex];
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: ChatBubble(
                              key: ValueKey(message.createdAt),
                              message: message,
                              onFavorite: message.recipe == null
                                  ? () {}
                                  : () => provider.toggleFavorite(
                                      message.recipe!,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (provider.errorMessage != null)
                  _StatusBanner(
                    icon: Icons.error_outline,
                    message: provider.errorMessage!,
                    isError: true,
                  ),
                if (_voiceError != null)
                  _StatusBanner(
                    icon: Icons.mic_off,
                    message: _voiceError!,
                    isError: true,
                  ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: _Composer(
                      controller: _messageController,
                      isLoading: provider.isLoading,
                      isListening: _isListening,
                      onVoice: _toggleVoiceInput,
                      onSend: () => _sendMessage(provider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PromptSuggestions extends StatelessWidget {
  const _PromptSuggestions({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final prompts = const [
      'I have eggs, onions, and tomatoes',
      'Make a quick rice dinner',
      'Suggest a high-protein breakfast',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: prompts.map((prompt) {
          return ActionChip(
            avatar: Icon(Icons.auto_awesome, color: colorScheme.primary),
            label: Text(prompt),
            onPressed: () => onSelected(prompt),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.isError,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isLoading,
    required this.isListening,
    required this.onVoice,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isListening;
  final VoidCallback onVoice;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Ask for a recipe with eggs, onions, tomatoes...',
                labelText: 'Message',
              ),
              onSubmitted: (_) {
                if (!isLoading) onSend();
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: IconButton.outlined(
              tooltip: isListening ? 'Stop voice input' : 'Start voice input',
              onPressed: isLoading ? null : onVoice,
              style: IconButton.styleFrom(
                foregroundColor: isListening
                    ? colorScheme.error
                    : colorScheme.primary,
                side: BorderSide(
                  color: isListening ? colorScheme.error : colorScheme.primary,
                ),
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  key: ValueKey(isListening),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: IconButton.filled(
              tooltip: 'Send',
              onPressed: isLoading ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colorScheme.primaryContainer,
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
