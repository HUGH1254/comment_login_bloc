import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/comment_model.dart';
import 'comment_event.dart';
import 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final Map<String, String> _mockDatabase = {
    'admin': '123456'
  };

  CommentBloc() : super(CommentLoading()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<DeleteComment>(_onDeleteComment);
    on<SetReplyTarget>(_onSetReplyTarget);
    
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    
    on<ExpandComment>(_onExpandComment);
    on<CollapseComment>(_onCollapseComment); // ĐĂNG KÝ MỚI
  }

  void _onLoadComments(LoadComments event, Emitter<CommentState> emit) {
    final initialComments = [
      Comment(id: '1', author: 'Người dùng A', text: 'Bài viết này rất hữu ích!'),
      Comment(id: '2', author: 'Tác giả', text: 'Cảm ơn bạn.', parentId: '1'),
      Comment(id: '3', author: 'Người dùng B', text: 'Tuyệt vời.', parentId: '1'),
      Comment(id: '4', author: 'Người dùng C', text: 'Đồng ý.', parentId: '1'),
      Comment(id: '5', author: 'Người dùng D', text: 'Bình luận bị ẩn số 1', parentId: '1'),
      Comment(id: '6', author: 'Người dùng E', text: 'Bình luận bị ẩn số 2', parentId: '1'),
    ];
    emit(CommentLoaded(comments: initialComments));
  }
void _onExpandComment(ExpandComment event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      // Nếu parentId là null (Bình luận gốc), dùng chữ 'root' để thay thế
      final key = event.parentId ?? 'root';
      final newExpanded = Set<String>.from(currentState.expandedParentIds)..add(key);
      emit(currentState.copyWith(expandedParentIds: newExpanded, clearMessage: true));
    }
  }

  void _onCollapseComment(CollapseComment event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final newExpanded = Set<String>.from(currentState.expandedParentIds);

      void removeDescendants(String? id) {
        newExpanded.remove(id ?? 'root'); 
        final children = currentState.comments.where((c) => c.parentId == id);
        for (var child in children) {
          removeDescendants(child.id);
        }
      }

      removeDescendants(event.parentId);
      emit(currentState.copyWith(expandedParentIds: newExpanded, clearMessage: true));
    }
  }
  void _onLogin(LoginRequested event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      var newState = currentState.copyWith(clearMessage: true); 

      if (!_mockDatabase.containsKey(event.username)) {
        emit(newState.copyWith(authMessage: 'Tài khoản không tồn tại!', isAuthSuccess: false));
      } else if (_mockDatabase[event.username] != event.password) {
        emit(newState.copyWith(authMessage: 'Sai mật khẩu!', isAuthSuccess: false));
      } else {
        emit(newState.copyWith(
          currentUser: event.username, 
          authMessage: 'Đăng nhập thành công!', 
          isAuthSuccess: true
        ));
      }
    }
  }

  void _onRegister(RegisterRequested event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      var newState = currentState.copyWith(clearMessage: true);

      if (_mockDatabase.containsKey(event.username)) {
        emit(newState.copyWith(authMessage: 'Tên tài khoản đã tồn tại!', isAuthSuccess: false));
      } else {
        _mockDatabase[event.username] = event.password;
        emit(newState.copyWith(
          currentUser: event.username, 
          authMessage: 'Đăng ký thành công!', 
          isAuthSuccess: true
        ));
      }
    }
  }

  void _onLogout(LogoutRequested event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      emit(currentState.copyWith(clearUser: true, clearReply: true, clearMessage: true));
    }
  }

void _onAddComment(AddComment event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded && currentState.currentUser != null) {
      
      String? rootId;
      String finalText = event.text;

      // KIỂM TRA XEM ĐANG TRẢ LỜI AI
      if (currentState.replyingTo != null) {
        final target = currentState.replyingTo!;
        
        // MỚI: BẤT KỂ LÀ TRẢ LỜI GỐC HAY CON, ĐỀU GẮN HASHTAG @TÊN VÀO ĐẦU CÂU
        finalText = '@${target.author} $finalText'; 

        if (target.parentId == null) {
          // Trả lời Bình luận Gốc -> Nhận thằng Gốc này làm cha
          rootId = target.id;
        } else {
          // Trả lời Bình luận Con -> Ép về ngang hàng (nhận cha của thằng con làm cha)
          rootId = target.parentId;
        }
      }

      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        author: currentState.currentUser!,
        text: finalText,
        parentId: rootId, 
      );

      final updatedComments = List<Comment>.from(currentState.comments)..add(newComment);
      
      // Tự động mở rộng nhánh khi vừa bình luận
      final newExpanded = Set<String>.from(currentState.expandedParentIds);
      if (rootId != null) newExpanded.add(rootId);

      emit(currentState.copyWith(
        comments: updatedComments,
        clearReply: true,
        clearMessage: true,
        expandedParentIds: newExpanded,
      ));
    }
  }
  void _onSetReplyTarget(SetReplyTarget event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      if (event.targetComment == null) {
        emit(currentState.copyWith(clearReply: true, clearMessage: true));
      } else {
        emit(currentState.copyWith(replyingTo: event.targetComment, clearMessage: true));
      }
    }
  }

  void _onDeleteComment(DeleteComment event, Emitter<CommentState> emit) {
    final currentState = state;
    if (currentState is CommentLoaded) {
      List<String> idsToDelete = [event.id];
      bool changed = true;

      while (changed) {
        changed = false;
        for (var c in currentState.comments) {
          if (idsToDelete.contains(c.parentId) && !idsToDelete.contains(c.id)) {
            idsToDelete.add(c.id);
            changed = true;
          }
        }
      }

      final updatedComments = List<Comment>.from(currentState.comments)
        ..removeWhere((c) => idsToDelete.contains(c.id));

      bool clearReply = false;
      if (currentState.replyingTo != null && idsToDelete.contains(currentState.replyingTo!.id)) {
        clearReply = true;
      }

      emit(currentState.copyWith(comments: updatedComments, clearReply: clearReply, clearMessage: true));
    }
  }
}