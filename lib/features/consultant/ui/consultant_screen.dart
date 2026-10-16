import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
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
        title: const Text('Clear Conversation', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
          'This clears the chat history. Your logged expenses stay safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
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
    final content = BlocConsumer<ConsultantCubit, ConsultantState>(
      bloc: widget.cubit,
      listener: (context, state) => _scrollToBottom(),
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context),
            if (state.errorMessage != null && state.status == ConsultantStatus.error)
              _buildErrorBanner(context, state.errorMessage!),
            Expanded(
              child: state.messages.isEmpty
                  ? _buildWelcome(context, state.suggestedPrompts)
                  : _buildMessageList(context, state.messages),
            ),
            _buildSuggestedChips(context, state),
            _buildComposer(context, state.isStreaming),
          ],
        );
      },
    );

    return Scaffold(
      key: const Key('consultant-screen'),
      body: SafeArea(child: content),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(color: Color(0x0A111111), offset: Offset(0, 1)),
                BoxShadow(color: Color(0x0D111111), blurRadius: 18, offset: Offset(0, 6)),
              ],
        border: isDark ? const Border(bottom: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: const [
                BoxShadow(color: Color(0x4D1F4DD8), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consultant', style: AppType.title.copyWith(fontSize: 17, color: scheme.onSurface)),
                const Text(
                  'Reads your logged expenses',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Clear Chat',
            child: Material(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.background,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _confirmClearChat,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.edit_square, size: 18, color: scheme.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.expenseContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
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

  Widget _buildWelcome(BuildContext context, List<String> suggestedPrompts) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 28, AppSpace.gutter, 20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.fab,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            'Meet Your Expense Consultant',
            textAlign: TextAlign.center,
            style: AppType.title.copyWith(fontSize: 22, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ask about your spending habits, top categories, or how to save more.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Try asking', style: AppType.section.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
          for (final prompt in suggestedPrompts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  onTap: () => _handleSend(prompt),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.raised,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prompt,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: scheme.onSurface),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textMuted),
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

  Widget _buildMessageList(BuildContext context, List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 20, AppSpace.gutter, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildBubble(context, messages[index]),
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isUser ? 12 : 14),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : scheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 20 : 6),
          topRight: const Radius.circular(20),
          bottomLeft: const Radius.circular(20),
          bottomRight: Radius.circular(isUser ? 6 : 20),
        ),
        boxShadow: isUser
            ? const [BoxShadow(color: Color(0x401F4DD8), blurRadius: 16, offset: Offset(0, 6))]
            : (isDark ? null : AppShadows.card),
        border: !isUser && isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.text.isEmpty && message.isStreaming)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Looking at your expenses…',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text('Writing…', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.92),
          ),
          child: bubble,
        ),
      ),
    );
  }

  Widget _buildSuggestedChips(BuildContext context, ConsultantState state) {
    if (state.messages.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: state.suggestedPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = state.suggestedPrompts[index];
          return Material(
            key: Key('consultant-chip-$index'),
            color: isDark ? AppColors.darkSurfaceSubtle : AppColors.background,
            shape: StadiumBorder(
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderStrong),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: state.isStreaming ? null : () => _handleSend(prompt),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    prompt,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer(BuildContext context, bool isStreaming) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 6, AppSpace.gutter, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(color: Color(0x0F111111), blurRadius: 2, offset: Offset(0, 1)),
                  BoxShadow(color: Color(0x1A111111), blurRadius: 28, offset: Offset(0, 10)),
                ],
          border: isDark ? Border.all(color: AppColors.darkBorder) : null,
        ),
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
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isStreaming
                    ? null
                    : const [BoxShadow(color: Color(0x591F4DD8), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Material(
                color: isStreaming ? scheme.primaryContainer : AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('consultant-send-btn'),
                  customBorder: const CircleBorder(),
                  onTap: isStreaming ? null : () => _handleSend(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: isStreaming
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20, semanticLabel: 'Send'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
