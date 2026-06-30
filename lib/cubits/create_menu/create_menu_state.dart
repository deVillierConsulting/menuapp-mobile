import 'package:equatable/equatable.dart';

abstract class CreateMenuState extends Equatable {
  const CreateMenuState();
  @override
  List<Object?> get props => [];
}

class CreateMenuIdle extends CreateMenuState {
  final String? name; // null = use server-generated default
  final DateTime startDate;
  final DateTime endDate;
  final int plannedMealCount;

  const CreateMenuIdle({
    this.name,
    required this.startDate,
    required this.endDate,
    required this.plannedMealCount,
  });

  int get dayCount => endDate.difference(startDate).inDays + 1;

  // Mirror the server's default name so the placeholder stays in sync with the date picker.
  String get defaultName {
    const ordinals = ['First', 'Second', 'Third', 'Fourth', 'Fifth'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final week = (startDate.day - 1) ~/ 7;
    return '${ordinals[week]} week of ${months[startDate.month - 1]}';
  }

  CreateMenuIdle copyWith({
    String? name,
    bool clearName = false,
    DateTime? startDate,
    DateTime? endDate,
    int? plannedMealCount,
  }) =>
      CreateMenuIdle(
        name: clearName ? null : (name ?? this.name),
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        plannedMealCount: plannedMealCount ?? this.plannedMealCount,
      );

  @override
  List<Object?> get props => [name, startDate, endDate, plannedMealCount];
}

class CreateMenuSubmitting extends CreateMenuState {
  const CreateMenuSubmitting();
}

class CreateMenuSuccess extends CreateMenuState {
  final int menuId;
  const CreateMenuSuccess(this.menuId);
  @override
  List<Object?> get props => [menuId];
}

class CreateMenuError extends CreateMenuState {
  final String message;
  const CreateMenuError(this.message);
  @override
  List<Object?> get props => [message];
}
