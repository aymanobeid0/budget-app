import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../cubit/consultant_cubit.dart';
import '../cubit/consultant_state.dart';
import '../models/chat_message.dart';

/// Conversational AI Expense Consultant powered by Google Gemini.
class ConsultantScreen extends StatefulWidget {
  const ConsultantScreen({super.key, this.cubit});

  final ConsultantCubit? cubit;

  @override
  State<ConsultantScreen> createState() => _ConsultantScreenState();
}

class _ConsultantScreenState extends State<ConsultantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  ConsultantCubit get _cubit => widget.cubit ?? context.read<ConsultantCubit>();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? textToSend]) {
    final text = textToSend ?? _textController.text;
    if (text.trim().isEmpty) return;
    if (textToSend == null) _textController.clear();
    _cubit.sendMessage(text);
    _scrollToBottom();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Conversation', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This clears the chat history. Your logged expenses stay safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () {
              _cubit.clearChat();
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('consultant-screen'),
      body: SafeArea(
        child: BlocConsumer<ConsultantCubit, ConsultantState>(
          bloc: widget.cubit,
          listener: (context, state) => _scrollToBottom(),
          builder: (context, state) {
            return Column(
              children: [
                ScreenHeader(
                  title: 'Consultant',
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.auto_awesome, size: 21, color: scheme.onPrimaryContainer),
                  ),
                  trailing: SquareIconButton(
                    icon: Icons.edit_square,
                    tooltip: 'Clear Chat',
                    onTap: _confirmClearChat,
                  ),
                ),
                if (state.errorMessage != null && state.status == ConsultantStatus.error)
                  _buildErrorBanner(state.errorMessage!),
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildWelcome(state.suggestedPrompts)
                      : _buildMessageList(state.messages),
                ),
                _buildSuggestedChips(state),
                _buildComposer(state.isStreaming),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpace.gutter, 14, AppSpace.gutter, 0),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.expenseContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.expense),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.expense),
            ),
          ),
          TextButton(
            onPressed: () => _cubit.retryLastMessage(),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(List<String> prompts) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 28, AppSpace.gutter, 20),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              boxShadow: isDarkOf(context) ? null : AppShadows.fab,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            'Meet Your Expense Consultant',
            textAlign: TextAlign.center,
            style: AppType.title.copyWith(fontSize: 22, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask about your spending habits, top categories, or how to save more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Try asking', style: AppType.fieldLabel.copyWith(color: scheme.onSurface)),
            ),
          ),
          for (final prompt in prompts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: raisedColor(context),
                elevation: raisedElevation(context),
                shadowColor: raisedShadowColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  onTap: () => _handleSend(prompt),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SolidIconTile(icon: Icons.chat_bubble_rounded, color: scheme.primary, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prompt,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: scheme.onSurface),
                          ),
                        ),
                        const Chevron(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 18, AppSpace.gutter, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildBubble(messages[index]),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isUser ? 12 : 14),
      decoration: BoxDecoration(
        color: isUser ? scheme.primary : (isDarkOf(context) ? AppColors.darkSurfaceSubtle : const Color(0xFFF7F8FC)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 18 : 4),
          topRight: const Radius.circular(18),
          bottomLeft: const Radius.circular(18),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.text.isEmpty && message.isStreaming)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Looking at your expenses…', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              ],
            )
          else
            SelectableText(
              message.text,
              style: AppType.body.copyWith(color: isUser ? Colors.white : scheme.onSurface),
            ),
          if (message.isStreaming && message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Writing…', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.9)),
          child: bubble,
        ),
      ),
    );
  }

  Widget _buildSuggestedChips(ConsultantState state) {
    if (state.messages.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: state.suggestedPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final first = index == 0;
          return Material(
            key: Key('consultant-chip-$index'),
            color: first ? scheme.primaryContainer : raisedColor(context),
            elevation: first ? 0 : raisedElevation(context),
            shadowColor: raisedShadowColor,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: state.isStreaming ? null : () => _handleSend(state.suggestedPrompts[index]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(
                    state.suggestedPrompts[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: first ? FontWeight.w600 : FontWeight.w500,
                      color: first ? scheme.onPrimaryContainer : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer(bool isStreaming) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 6, AppSpace.gutter, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('consultant-input-field'),
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: isStreaming ? null : (_) => _handleSend(),
              style: TextStyle(fontSize: 15, color: scheme.onSurface),
              decoration: const InputDecoration(
                hintText: 'Ask about your spending…',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: isStreaming || isDarkOf(context) ? null : AppShadows.fab,
            ),
            child: Material(
              color: isStreaming ? scheme.primaryContainer : scheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                key: const Key('consultant-send-btn'),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: isStreaming ? null : () => _handleSend(),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: isStreaming
                      ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 21, semanticLabel: 'Send'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
