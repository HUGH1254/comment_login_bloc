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

  // Thuật toán làm phẳng cây dữ liệu (CẬP NHẬT: Gộp cả 2 Luật giới hạn)
  List<CommentNode> get flattenedComments {
    List<CommentNode> result = [];
    
    void traverse(String? parentId, int depth) {
      final children = comments.where((c) => c.parentId == parentId).toList();
      if (children.isEmpty) return; // Tối ưu: Không có con thì dừng luôn cho nhẹ máy
      
      // Kiểm tra nhánh này đã được bấm mở rộng hay chưa
      bool isExpanded = parentId == null || expandedParentIds.contains(parentId);
      
      // ==========================================
      // LUẬT 1: GIỚI HẠN TẦNG (Gốc=0, Con=1, Cháu=2)
      // ==========================================
      // Từ tầng Chắt (depth >= 3) trở đi, nếu CHƯA được mở rộng -> Giấu toàn bộ 
      // và thay bằng 1 cái Node giả "Xem thêm"
      if (depth >= 3 && !isExpanded) {
        result.add(CommentNode(
          comment: Comment(id: 'view_more_depth_$parentId', author: '', text: ''),
          depth: depth,
          isViewMore: true,
          hiddenCount: children.length, // Số lượng bị giấu là Toàn bộ danh sách cháu chắt
          targetParentId: parentId,
        ));
        return; // Lệnh Return này sẽ chặt đứt đệ quy, không cho máy đào sâu thêm nữa
      }

      // ==========================================
      // LUẬT 2: GIỚI HẠN SỐ LƯỢNG ANH EM
      // ==========================================
      // Dù ở tầng nào, nếu chưa mở rộng thì cũng chỉ cho hiện tối đa 3 bình luận
      int displayCount = isExpanded ? children.length : (children.length > 3 ? 3 : children.length);

      // Tiến hành nhét bình luận vào danh sách hiển thị
      for (int i = 0; i < displayCount; i++) {
        final child = children[i];
        result.add(CommentNode(comment: child, depth: depth));
        traverse(child.id, depth + 1); // Tiếp tục đệ quy đào xuống
      }

      // ==========================================
      // VẼ NÚT BẤM (XEM THÊM / THU GỌN) Ở ĐÁY CỦA NHÁNH
      // ==========================================
      if (!isExpanded && children.length > 3) {
        // Nút Xem thêm (Cho trường hợp dư anh em)
        result.add(CommentNode(
          comment: Comment(id: 'view_more_sib_$parentId', author: '', text: ''),
          depth: depth,
          isViewMore: true,
          hiddenCount: children.length - 3, // Trừ đi 3 đứa đã hiện
          targetParentId: parentId,
        ));
      } 
      else if (isExpanded && parentId != null && (depth >= 3 || children.length > 3)) {
        // Nút Thu gọn (Hiện ra nếu nhánh đó vừa được mở rộng do luật 1 hoặc luật 2)
        result.add(CommentNode(
          comment: Comment(id: 'collapse_$parentId', author: '', text: ''),
          depth: depth,
          isCollapse: true,
          targetParentId: parentId,
        ));
      }
    }
    
    traverse(null, 0);
    return result;
  }
}