import 'package:equatable/equatable.dart';

enum MenuStatus { draft, active, final_ }

class Menu extends Equatable {
  final int menuId;
  final int groupId;
  final String startDate;
  final String endDate;
  final MenuStatus status;

  const Menu({
    required this.menuId,
    required this.groupId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        menuId: json['menu_id'] as int,
        groupId: json['group_id'] as int,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        status: _statusFromString(json['status'] as String),
      );

  static MenuStatus _statusFromString(String s) => switch (s) {
        'active' => MenuStatus.active,
        'final'  => MenuStatus.final_,
        _        => MenuStatus.draft,
      };

  bool get isActive => status == MenuStatus.active;
  bool get isFinal  => status == MenuStatus.final_;

  @override
  List<Object?> get props => [menuId, groupId, startDate, endDate, status];
}
