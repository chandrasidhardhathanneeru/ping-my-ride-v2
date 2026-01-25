enum UserType {
  student('Student', 'assets/icons/student_icon.png'),
  driver('Driver', 'assets/icons/driver_icon.png'),
  admin('Admin', 'assets/icons/admin_icon.png');

  const UserType(this.label, this.iconPath);
  
  final String label;
  final String iconPath;
}