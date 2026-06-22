import 'package:equatable/equatable.dart';

class ActiveMenuSummary extends Equatable {
  final int menuId;
  final String? name;
  final String startDate;
  final String endDate;
  final int groupId;
  final String groupName;

  const ActiveMenuSummary({
    required this.menuId,
    this.name,
    required this.startDate,
    required this.endDate,
    required this.groupId,
    required this.groupName,
  });

  factory ActiveMenuSummary.fromJson(Map<String, dynamic> json) =>
      ActiveMenuSummary(
        menuId: json['menu_id'] as int,
        name: json['name'] as String?,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        groupId: json['group_id'] as int,
        groupName: json['group_name'] as String,
      );

  String get displayName => name ?? dateRange;

  String get dateRange {
    String fmt(String iso) {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}';
    }
    return '${fmt(startDate)} – ${fmt(endDate)}';
  }

  @override
  List<Object?> get props => [menuId, name, startDate, endDate, groupId, groupName];
}
