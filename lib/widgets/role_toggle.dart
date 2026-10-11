import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

enum LoginRole { guru, wali }

class RoleToggle extends StatelessWidget {
  final LoginRole selected;
  final ValueChanged<LoginRole> onChanged;

  const RoleToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.toggleBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _item('Guru', LoginRole.guru),
          _item('Siswa', LoginRole.wali),
        ],
      ),
    );
  }

  Widget _item(String label, LoginRole role) {
    final active = selected == role;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              color: active ? AppColors.white : AppColors.textTab,
            ),
          ),
        ),
      ),
    );
  }
}