import '../models/comment_model.dart';

abstract class CommentEvent {}

class LoadComments extends CommentEvent {}

class AddComment extends CommentEvent {
  final String text;
  AddComment(this.text);
}

class DeleteComment extends CommentEvent {
  final String id;
  DeleteComment(this.id);
}

class SetReplyTarget extends CommentEvent {
  final Comment? targetComment;
  SetReplyTarget(this.targetComment);
}

class LoginRequested extends CommentEvent {
  final String username;
  final String password;
  LoginRequested(this.username, this.password);
}

class RegisterRequested extends CommentEvent {
  final String username;
  final String password;
  RegisterRequested(this.username, this.password);
}

class LogoutRequested extends CommentEvent {}

class ExpandComment extends CommentEvent {
  final String parentId;
  ExpandComment(this.parentId);
}

// MỚI: Sự kiện thu gọn bình luận
class CollapseComment extends CommentEvent {
  final String parentId;
  CollapseComment(this.parentId);
}