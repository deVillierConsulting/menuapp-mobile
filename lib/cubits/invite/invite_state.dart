import 'package:equatable/equatable.dart';
import '../../data/models/invite_preview.dart';

enum InviteErrorKind { expired, alreadyMember, notFound, network }

sealed class InviteState extends Equatable {
  const InviteState();
  @override
  List<Object?> get props => [];
}

class InviteLoading extends InviteState {
  const InviteLoading();
}

class InvitePreviewLoaded extends InviteState {
  final InvitePreview preview;
  const InvitePreviewLoaded(this.preview);
  @override
  List<Object?> get props => [preview];
}

class InviteJoining extends InviteState {
  final InvitePreview preview;
  const InviteJoining(this.preview);
  @override
  List<Object?> get props => [preview];
}

class InviteJoined extends InviteState {
  final int groupId;
  const InviteJoined(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class InviteError extends InviteState {
  final InviteErrorKind kind;
  final String message;
  const InviteError({required this.kind, required this.message});
  @override
  List<Object?> get props => [kind, message];
}
