import 'package:equatable/equatable.dart';

enum MenuStatus {
  draft,
  active,
  final_;

  static MenuStatus fromString(String s) => switch (s) {
        'active' => MenuStatus.active,
        'final'  => MenuStatus.final_,
        _        => MenuStatus.draft,
      };
}

class Menu extends Equatable {
  final int menuId;
  final int groupId;
  final String? name;
  final String startDate;
  final String endDate;
  final MenuStatus status;

  const Menu({
    required this.menuId,
    required this.groupId,
    this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        menuId: json['menu_id'] as int,
        groupId: json['group_id'] as int,
        name: json['name'] as String?,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        status: MenuStatus.fromString(json['status'] as String),
      );

  bool get isActive => status == MenuStatus.active;
  bool get isFinal  => status == MenuStatus.final_;

  @override
  List<Object?> get props => [menuId, groupId, name, startDate, endDate, status];
}
