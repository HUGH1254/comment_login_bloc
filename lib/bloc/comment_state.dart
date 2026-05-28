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
  // THUẬT TOÁN LÀM PHẲNG CÂY (FIX: CHỈ HIỆN THU GỌN KHI > 3 CON HOẶC QUÁ SÂU)
  // =========================================================================
  List<CommentNode> get flattenedComments {
    List<CommentNode> result = [];
    
    void traverse(String? parentId, int depth) {
      final children = comments.where((c) => c.parentId == parentId).toList();
      if (children.isEmpty) return; 
      
      String nodeKey = parentId ?? 'root';
      bool isExpanded = expandedParentIds.contains(nodeKey);
      
      int displayCount = children.length;
      bool isTruncated = false;
      int hiddenCount = 0;

      // 1. LUẬT KIỂM TRA ĐỂ GIẤU BỚT BÌNH LUẬN (Nếu chưa bấm mở rộng)
      if (!isExpanded) {
        if (parentId != null && depth >= 3) { 
          // Giới hạn tầng: Từ tầng 3 trở đi sẽ bị giấu sạch
          displayCount = 0;
          isTruncated = true;
          hiddenCount = children.length;
        } else if (children.length > 3) {
          // Giới hạn số lượng: Đông hơn 3 đứa thì chỉ hiện 3 đứa đầu
          displayCount = 3;
          isTruncated = true;
          hiddenCount = children.length - 3; 
        }
      }

      // 2. VẼ DANH SÁCH BÌNH LUẬN 
      for (int i = 0; i < displayCount; i++) {
        final child = children[i];
        result.add(CommentNode(comment: child, depth: depth));
        
        // Mỗi nhánh con tự quản lý độc lập
        traverse(child.id, depth + 1); 
      }

      // 3. VẼ NÚT XEM THÊM (Của riêng tầng này)
      if (isTruncated) {
        result.add(CommentNode(
          comment: Comment(id: 'view_more_$nodeKey', author: '', text: ''),
          depth: depth,
          isViewMore: true,
          hiddenCount: hiddenCount,
          targetParentId: parentId,
        ));
      } 
      // 4. VẼ NÚT THU GỌN (Của riêng tầng này)
      else if (isExpanded) {
        // ĐIỀU KIỆN QUYẾT ĐỊNH: 
        // Nút Thu gọn CHỈ hiện ra nếu số lượng con > 3 HOẶC nhánh này nằm ở tầng bị giới hạn
        bool needsCollapse = (children.length > 3) || (parentId != null && depth >= 3);
        
        if (needsCollapse) {
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
