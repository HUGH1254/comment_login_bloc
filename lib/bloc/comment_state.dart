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
  // THUẬT TOÁN LÀM PHẲNG CÂY (FIX: ĐỘC LẬP TỪNG TẦNG - MỖI TẦNG 1 NÚT RIÊNG BIỆT)
  // =========================================================================
  List<CommentNode> get flattenedComments {
    List<CommentNode> result = [];
    
    // Xóa bỏ hoàn toàn chế độ Bubble-up và forceExpand để các tầng không dính líu đến nhau
    void traverse(String? parentId, int depth) {
      final children = comments.where((c) => c.parentId == parentId).toList();
      if (children.isEmpty) return; 
      
      String nodeKey = parentId ?? 'root';
      
      // Chỉ kiểm tra đúng ID của tầng này, không ép con cháu phải mở theo
      bool isExpanded = expandedParentIds.contains(nodeKey);
      
      int displayCount = children.length;
      bool isTruncated = false;
      int hiddenCount = 0;

      // ÁP DỤNG LUẬT GIỚI HẠN (Nếu tầng NÀY chưa được bấm mở rộng)
      if (!isExpanded) {
        if (parentId != null && depth >= 4) {
          // Vượt quá độ sâu (Tầng 4 trở đi) -> Giấu hết con
          displayCount = 0;
          isTruncated = true;
          hiddenCount = children.length;
        } else if (children.length > 3) {
          // Dài quá 3 bình luận -> Chỉ hiện 3
          displayCount = 3;
          isTruncated = true;
          hiddenCount = children.length - 3; 
        }
      }

      // VẼ BÌNH LUẬN CON
      for (int i = 0; i < displayCount; i++) {
        final child = children[i];
        result.add(CommentNode(comment: child, depth: depth));
        
        // Gọi đệ quy: Mỗi thằng con sẽ tự quản lý nhánh của nó hoàn toàn độc lập
        traverse(child.id, depth + 1); 
      }

      // VẼ NÚT XEM THÊM (CỦA RIÊNG TẦNG NÀY)
      if (isTruncated) {
        result.add(CommentNode(
          comment: Comment(id: 'view_more_$nodeKey', author: '', text: ''),
          depth: depth,
          isViewMore: true,
          hiddenCount: hiddenCount,
          targetParentId: parentId,
        ));
      } 
      // VẼ NÚT THU GỌN (CỦA RIÊNG TẦNG NÀY)
      else if (isExpanded) {
        // Chỉ vẽ nút Thu Gọn nếu bản thân nhánh này LÚC BÌNH THƯỜNG bị quá tải
        bool needsCollapseButton = (parentId != null && depth >= 4) || (children.length > 3);
        
        if (needsCollapseButton) {
          result.add(CommentNode(
            comment: Comment(id: 'collapse_$nodeKey', author: '', text: ''),
            depth: depth,
            isCollapse: true,
            targetParentId: parentId,
          ));
        }
      }
    }
    
    traverse(null, 0);
    return result;
  }
}
