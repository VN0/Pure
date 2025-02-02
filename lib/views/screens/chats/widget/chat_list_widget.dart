import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/bloc.dart';
import '../../../../model/chat/chat_model.dart';
import '../../../../model/pure_user_model.dart';
import '../../../widgets/message_widget.dart';
import '../../../widgets/progress_indicator.dart';
import '../../../widgets/user_profile_provider.dart';
import 'group_card.dart';
import 'load_more_chats_widget.dart';
import 'one_to_one_card.dart';
import 'unread_message_provider.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final _controller = ScrollController();
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = CurrentUser.currentUserId;
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void loadMoreListener(BuildContext context, ChatState state) {
    if (state is ChatsLoaded) {
      context.read<ChatCubit>().addOldChats(state);
    }
  }

  void _onScroll() async {
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.offset;
    if (maxScroll - currentScroll <= 50 && !_controller.position.outOfRange) {
      _fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoadMoreChatsCubit, ChatState>(
      listener: loadMoreListener,
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          if (state is ChatsLoaded) {
            final chats = state.chatsModel.chats;
            if (chats.isEmpty)
              return MessageDisplay(
                fontSize: 20.0,
                title: "No Chats here yet...",
                description: "Start converation with your connections now",
                buttonTitle: "",
              );
            else
              return ListView.custom(
                controller: _controller,
                padding: const EdgeInsets.symmetric(vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                childrenDelegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    if (chats.length == index)
                      return LoadMoreChatsWidget(
                        onTap: () => _fetchMore(tryAgain: true),
                      );
                    else {
                      final chat = chats[index];
                      if (chat.type == ChatType.Group) {
                        return KeepAlive(
                          key: ValueKey<String>(chat.chatId),
                          keepAlive: true,
                          child: GroupMembersProvider(
                            key: ValueKey(chat.members.length),
                            members: chat.members,
                            child: UnreadMessageProvider(
                              child: GroupCard(
                                key: ValueKey(chat.chatId),
                                chat: chat,
                                showSeparator: index < (chats.length - 1),
                              ),
                            ),
                          ),
                        );
                      } else {
                        final userId = chat.getReceipient(currentUserId)!;
                        return KeepAlive(
                          key: ValueKey<String>(chat.chatId),
                          keepAlive: true,
                          child: ProfileProvider(
                            userId: userId,
                            child: UnreadMessageProvider(
                              child: OneToOneCard(
                                key: ValueKey(chat.chatId),
                                userId: userId,
                                chat: chat,
                                showSeparator: index < (chats.length - 1),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  childCount: chats.length + 1,
                  findChildIndexCallback: (Key key) {
                    final ValueKey<String> valueKey = key as ValueKey<String>;
                    final String data = valueKey.value;
                    return chats.map((e) => e.chatId).toList().indexOf(data);
                  },
                ),
              );
          }
          return Center(child: const CustomProgressIndicator());
        },
      ),
    );
  }

  Future<void> loadAgain(final ChatsModel model) async {
    if (model.lastDoc != null) {
      await context
          .read<LoadMoreChatsCubit>()
          .loadMoreChats(currentUserId, model.lastDoc!);
    }
  }

  Future<void> _fetchMore({bool tryAgain = false}) async {
    final state = context.read<ChatCubit>().state;
    if (state is ChatsLoaded) {
      if (tryAgain)
        loadAgain(state.chatsModel);
      else {
        final loadMoreState = context.read<LoadMoreChatsCubit>().state;
        if (loadMoreState is! LoadingChats &&
            state is! ChatsFailed &&
            state.hasMore) {
          loadAgain(state.chatsModel);
        }
      }
    }
  }
}
