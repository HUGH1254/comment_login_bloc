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

// =========================================================================
  // THUẬT TOÁN 1 TẦNG (KIỂU FACEBOOK): TỰ ĐỘNG LÀM PHẲNG MỌI BÌNH LUẬN
  // =========================================================================
  List<CommentNode> get flattenedComments {
    List<CommentNode> result = [];

    // 1. Lọc lấy TẤT CẢ bình luận Gốc (Tầng 0)
    final rootComments = comments.where((c) => c.parentId == null).toList();

    for (var root in rootComments) {
      // Vẽ thằng Gốc
      result.add(CommentNode(comment: root, depth: 0));

      // 2. Lọc lấy TẤT CẢ bình luận Con của thằng Gốc này (Tầng 1)
      final children = comments.where((c) => c.parentId == root.id).toList();
      if (children.isEmpty) continue; // Không có con thì bỏ qua

      bool isExpanded = expandedParentIds.contains(root.id);
      
      // Tính toán hiển thị (Quá 3 đứa thì giấu)
      int displayCount = isExpanded ? children.length : (children.length > 3 ? 3 : children.length);
      bool isTruncated = !isExpanded && children.length > 3;

      // 3. Vẽ đám Con (Tất cả đều nằm chung 1 độ sâu depth = 1)
      for (int i = 0; i < displayCount; i++) {
        result.add(CommentNode(comment: children[i], depth: 1));
      }

      // 4. Nút Xem Thêm / Thu Gọn (Gọn gàng nhất có thể)
      if (isTruncated) {
        result.add(CommentNode(
          comment: Comment(id: 'view_more_${root.id}', author: '', text: ''),
          depth: 1,
          isViewMore: true,
          hiddenCount: children.length - 3,
          targetParentId: root.id,
        ));
      } else if (isExpanded && children.length > 3) {
        result.add(CommentNode(
          comment: Comment(id: 'collapse_${root.id}', author: '', text: ''),
          depth: 1,
          isCollapse: true,
          targetParentId: root.id,
        ));
      }
    }
    
    return result;
  }
}
