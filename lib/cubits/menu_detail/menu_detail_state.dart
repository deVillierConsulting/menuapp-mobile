import 'package:equatable/equatable.dart';
import '../../data/models/menu_detail.dart';

abstract class MenuDetailState extends Equatable {
  const MenuDetailState();
  @override
  List<Object?> get props => [];
}

class MenuDetailLoading extends MenuDetailState {
  const MenuDetailLoading();
}

class MenuDetailLoaded extends MenuDetailState {
  final MenuDetail menu;
  const MenuDetailLoaded(this.menu);
  @override
  List<Object?> get props => [menu];
}

class MenuDetailError extends MenuDetailState {
  final String message;
  const MenuDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
