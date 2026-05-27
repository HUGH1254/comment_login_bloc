class Comment {
  final String id;
  final String author;
  final String text;
  final String? parentId;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    this.parentId,
  });
}

class CommentNode {
  final Comment comment;
  final int depth;
  
  final bool isViewMore; 
  final bool isCollapse; // MỚI: Cờ hiệu nhận diện nút Thu Gọn
  final int hiddenCount; 
  final String? targetParentId; 

  CommentNode({
    required this.comment,
    required this.depth,
    this.isViewMore = false,
    this.isCollapse = false, // MỚI
    this.hiddenCount = 0,
    this.targetParentId,
  });
}