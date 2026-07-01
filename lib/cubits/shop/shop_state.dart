import 'package:equatable/equatable.dart';
import '../../data/models/shop_item.dart';

abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object?> get props => [];
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopLoaded extends ShopState {
  final List<ShopItem> items;
  const ShopLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);
  @override
  List<Object?> get props => [message];
}
