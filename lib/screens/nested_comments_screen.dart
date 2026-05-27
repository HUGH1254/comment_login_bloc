import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/comment_model.dart';
import '../bloc/comment_bloc.dart';
import '../bloc/comment_event.dart';
import '../bloc/comment_state.dart';

class NestedCommentsScreen extends StatefulWidget {
  const NestedCommentsScreen({super.key});

  @override
  State<NestedCommentsScreen> createState() => _NestedCommentsScreenState();
}

class _NestedCommentsScreenState extends State<NestedCommentsScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment(BuildContext context) {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    context.read<CommentBloc>().add(AddComment(text));
    _commentCtrl.clear();
    _focusNode.unfocus();
  }

  void _showAuthDialog(BuildContext screenContext) {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isPasswordHidden = true;

    showDialog(
      context: screenContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Xác thực tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên tài khoản',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: isPasswordHidden, 
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setStateDialog(() {
                            isPasswordHidden = !isPasswordHidden;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () {
                    final u = usernameCtrl.text.trim();
                    final p = passwordCtrl.text.trim();
                    if (u.isNotEmpty && p.isNotEmpty) {
                      screenContext.read<CommentBloc>().add(RegisterRequested(u, p));
                      Navigator.pop(dialogContext); 
                    }
                  },
                  child: const Text('Đăng ký mới', style: TextStyle(color: Colors.teal)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final u = usernameCtrl.text.trim();
                    final p = passwordCtrl.text.trim();
                    if (u.isNotEmpty && p.isNotEmpty) {
                      screenContext.read<CommentBloc>().add(LoginRequested(u, p));
                      Navigator.pop(dialogContext); 
                    }
                  },
                  child: const Text('Đăng nhập'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments API'),
        actions: [
          BlocBuilder<CommentBloc, CommentState>(
            builder: (context, state) {
              if (state is CommentLoaded) {
                if (state.currentUser == null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAuthDialog(context),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Đăng nhập'),
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        'Chào, ${state.currentUser}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: 'Đăng xuất',
                        onPressed: () => context.read<CommentBloc>().add(LogoutRequested()),
                      )
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<CommentBloc, CommentState>(
        listener: (context, state) {
          if (state is CommentLoaded && state.authMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.authMessage!),
                backgroundColor: state.isAuthSuccess ? Colors.green : Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<CommentBloc, CommentState>(
          builder: (context, state) {
            if (state is CommentLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CommentLoaded) {
              final treeList = state.flattenedComments;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: treeList.length,
                      itemBuilder: (context, index) {
                        final node = treeList[index];
                        
                        // 1. Nếu là Node Xem Thêm
                        if (node.isViewMore) {
                          return Padding(
                            padding: EdgeInsets.only(left: node.depth * 24.0 + 16.0, top: 4, bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => context.read<CommentBloc>().add(ExpandComment(node.targetParentId!)),
                                child: Text(
                                  '↪ Xem thêm ${node.hiddenCount} bình luận',
                                  style: const TextStyle(
                                    color: Colors.blue, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // 2. MỚI: Nếu là Node Thu Gọn
                        if (node.isCollapse) {
                          return Padding(
                            padding: EdgeInsets.only(left: node.depth * 24.0 + 16.0, top: 4, bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => context.read<CommentBloc>().add(CollapseComment(node.targetParentId!)),
                                child: const Text(
                                  '↶ Thu gọn',
                                  style: TextStyle(
                                    color: Colors.grey, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // 3. Nếu là bình luận bình thường
                        return _buildCommentItem(context, node.comment, node.depth, state.currentUser);
                      },
                    ),
                  ),
                  _buildInputForm(context, state),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment, int depth, String? currentUser) {
    bool isMyComment = currentUser == comment.author;

    return Container(
      margin: EdgeInsets.only(left: depth * 24.0 + 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        border: depth > 0 ? Border(left: BorderSide(color: Colors.grey.shade300, width: 2)) : null,
      ),
      padding: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade100,
                child: Text(comment.author.isNotEmpty ? comment.author[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 8),
              Text(comment.author, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.text, style: const TextStyle(fontSize: 15)),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  context.read<CommentBloc>().add(SetReplyTarget(comment));
                  _focusNode.requestFocus();
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: const Text('Phản hồi', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              
              if (isMyComment)
                TextButton(
                  onPressed: () => context.read<CommentBloc>().add(DeleteComment(comment.id)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, CommentLoaded state) {
    final replyingTo = state.replyingTo;
    final currentUser = state.currentUser;
    final bool isGuest = currentUser == null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade300, offset: const Offset(0, -1), blurRadius: 4)],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đang phản hồi: ${replyingTo.author}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.teal),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.read<CommentBloc>().add(SetReplyTarget(null)),
                      child: const Icon(Icons.close, size: 20, color: Colors.teal),
                    )
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    focusNode: _focusNode,
                    readOnly: isGuest, 
                    decoration: InputDecoration(
                      hintText: isGuest 
                          ? 'Vui lòng đăng nhập để bình luận...' 
                          : (replyingTo == null ? 'Bình luận dưới tên $currentUser...' : 'Viết phản hồi...'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: isGuest ? Colors.grey.shade300 : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isGuest ? Colors.grey : Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: isGuest ? null : () => _submitComment(context),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}