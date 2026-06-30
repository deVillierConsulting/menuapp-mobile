import 'package:equatable/equatable.dart';

abstract class CreateGroupState extends Equatable {
  const CreateGroupState();
  @override
  List<Object?> get props => [];
}

class CreateGroupIdle extends CreateGroupState {
  final String name;

  const CreateGroupIdle({this.name = ''});

  bool get canSubmit => name.trim().isNotEmpty;

  CreateGroupIdle copyWith({String? name}) => CreateGroupIdle(
        name: name ?? this.name,
      );

  @override
  List<Object?> get props => [name];
}

class CreateGroupSubmitting extends CreateGroupState {
  const CreateGroupSubmitting();
}

class CreateGroupSuccess extends CreateGroupState {
  final int groupId;
  const CreateGroupSuccess(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class CreateGroupError extends CreateGroupState {
  final String message;
  const CreateGroupError(this.message);
  @override
  List<Object?> get props => [message];
}
