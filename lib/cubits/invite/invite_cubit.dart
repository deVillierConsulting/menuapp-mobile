import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api_client.dart';
import '../../data/invite_data_source.dart';
import 'invite_state.dart';

class InviteCubit extends Cubit<InviteState> {
  final InviteDataSource _invites;
  final String _token;

  InviteCubit({required InviteDataSource invites, required String token})
      : _invites = invites,
        _token = token,
        super(const InviteLoading());

  Future<void> load() async {
    emit(const InviteLoading());
    try {
      final preview = await _invites.preview(_token);
      emit(InvitePreviewLoaded(preview));
    } on ApiException catch (e) {
      emit(InviteError(kind: _kindFromStatus(e.statusCode), message: e.message));
    } catch (e) {
      emit(InviteError(kind: InviteErrorKind.network, message: e.toString()));
    }
  }

  Future<void> join() async {
    final current = state;
    if (current is! InvitePreviewLoaded) return;
    emit(InviteJoining(current.preview));
    try {
      await _invites.join(_token);
      emit(InviteJoined(current.preview.groupId));
    } on ApiException catch (e) {
      emit(InviteError(kind: _kindFromStatus(e.statusCode), message: e.message));
    } catch (e) {
      // Roll back to preview so the user can retry.
      emit(InvitePreviewLoaded(current.preview));
    }
  }

  static InviteErrorKind _kindFromStatus(int status) => switch (status) {
        404 => InviteErrorKind.notFound,
        409 => InviteErrorKind.alreadyMember,
        410 => InviteErrorKind.expired,
        _ => InviteErrorKind.network,
      };
}
