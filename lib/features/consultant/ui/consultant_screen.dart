import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../cubit/consultant_cubit.dart';
import '../cubit/consultant_state.dart';
import '../models/chat_message.dart';

/// Interactive conversational AI Expense Consultant powered by Google Gemini.
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

    if (textToSend == null) {
      _textController.clear();
    }
    _cubit.sendMessage(text);
    _scrollToBottom();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text(
          'Clear Conversation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to clear the current chat history? Your logged expenses will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget screenContent = BlocConsumer<ConsultantCubit, ConsultantState>(
      bloc: widget.cubit,
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        final messages = state.messages;
        final isStreaming = state.isStreaming;

        return Column(
          children: [
            if (state.errorMessage != null && state.status == ConsultantStatus.error)
              _buildErrorBanner(context, state.errorMessage!),
            Expanded(
              child: messages.isEmpty
                  ? _buildWelcomeHero(context, isDark, state.suggestedPrompts)
                  : _buildMessageList(context, isDark, messages),
            ),
            _buildSuggestedChips(context, isDark, state),
            _buildInputBar(context, isDark, isStreaming),
          ],
        );
      },
    );

    return Scaffold(
      key: const Key('consultant-screen'),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('AI Consultant'),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                ),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: IconButton(
                tooltip: 'Clear Chat',
                icon: Icon(
                  Icons.refresh_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _confirmClearChat,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: screenContent,
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.expenseContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.expense,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.expense,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _cubit.retryLastMessage(),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHero(
    BuildContext context,
    bool isDark,
    List<String> suggestedPrompts,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.balanceCard,
              boxShadow: AppShadows.heroCard,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Meet Your Expense Consultant',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ask any question about your spending habits, top categories, or how to save more effectively.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Questions',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestedPrompts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final prompt = suggestedPrompts[index];
              return InkWell(
                onTap: () => _handleSend(prompt),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                    ),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    bool isDark,
    List<ChatMessage> messages,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(context, isDark, message);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    bool isDark,
    ChatMessage message,
  ) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.primaryLight,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.primarySubtle,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(isUser ? AppRadius.md : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadius.md),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                      ),
                boxShadow: isUser ? AppShadows.fab : AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.text.isEmpty && message.isStreaming)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Analyzing spending data...',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  else
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isUser
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                      ),
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'streaming...',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips(
    BuildContext context,
    bool isDark,
    ConsultantState state,
  ) {
    if (state.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final prompts = state.suggestedPrompts;
    final isStreaming = state.isStreaming;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ActionChip(
            key: Key('consultant-chip-$index'),
            avatar: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            label: Text(
              prompt,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            onPressed: isStreaming ? null : () => _handleSend(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, bool isStreaming) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                ),
              ),
              child: TextField(
                key: const Key('consultant-input-field'),
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: isStreaming ? null : (val) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Ask your consultant...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('consultant-send-btn'),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: isStreaming ? null : () => _handleSend(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isStreaming
                      ? (isDark ? AppColors.darkSurfaceSubtle : AppColors.primarySubtle)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: isStreaming ? null : AppShadows.fab,
                ),
                child: isStreaming
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
