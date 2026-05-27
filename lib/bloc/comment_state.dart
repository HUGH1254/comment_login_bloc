import '../models/comment_model.dart';

abstract class CommentState {}

class CommentLoading extends CommentState {}

class CommentLoaded extends CommentState {
  final List<Comment> comments;
  final Comment? replyingTo;
  
  final String? currentUser; 
  final String? authMessage; 
  final bool isAuthSuccess;  
  
  final Set<String> expandedParentIds;

  CommentLoaded({
    required this.comments,
    this.replyingTo,
    this.currentUser, 
    this.authMessage,
    this.isAuthSuccess = true,
    this.expandedParentIds = const {},
  });

  CommentLoaded copyWith({
    List<Comment>? comments,
    Comment? replyingTo,
    String? currentUser,
    String? authMessage,
    bool? isAuthSuccess,
    Set<String>? expandedParentIds,
    bool clearReply = false,
    bool clearUser = false, 
    bool clearMessage = false, 
  }) {
    return CommentLoaded(
      comments: comments ?? this.comments,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      authMessage: clearMessage ? null : (authMessage ?? this.authMessage),
      isAuthSuccess: isAuthSuccess ?? this.isAuthSuccess,
      expandedParentIds: expandedParentIds ?? this.expandedParentIds,
    );
  }

  List<CommentNode> get flattenedComments {
    List<CommentNode> result = [];
    
    void traverse(String? parentId, int depth) {
      final children = comments.where((c) => c.parentId == parentId).toList();
      
      bool isExpanded = parentId == null || expandedParentIds.contains(parentId);
      
      int displayCount = isExpanded ? children.length : (children.length > 3 ? 3 : children.length);

      for (int i = 0; i < displayCount; i++) {
        final child = children[i];
        result.add(CommentNode(comment: child, depth: depth));
        traverse(child.id, depth + 1); 
      }

      // Nếu CHƯA mở rộng và có dư comment -> Vẽ nút XEM THÊM
      if (!isExpanded && children.length > 3) {
        final hiddenCount = children.length - 3;
        result.add(CommentNode(
          comment: Comment(id: 'view_more', author: '', text: ''),
          depth: depth,
          isViewMore: true,
          hiddenCount: hiddenCount,
          targetParentId: parentId,
        ));
      } 
      // MỚI: Nếu ĐÃ mở rộng và nhánh này (không phải gốc) có trên 3 comment -> Vẽ nút THU GỌN ở cuối
      else if (isExpanded && children.length > 3 && parentId != null) {
        result.add(CommentNode(
          comment: Comment(id: 'collapse', author: '', text: ''),
          depth: depth,
          isCollapse: true, // Kích hoạt cờ Thu gọn
          targetParentId: parentId,
        ));
      }
    }
    
    traverse(null, 0);
    return result;
  }
}