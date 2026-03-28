import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/rota_service.dart';
import 'services/attendance_service.dart';
import 'services/leave_service.dart';
import 'services/user_service.dart';
import 'services/payroll_service.dart';
import 'services/settings_service.dart';
import 'services/alert_service.dart';
import 'screens/login_screen.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'models/user_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, api) => api.dispose(),
        ),
        ProxyProvider<ApiService, AuthService>(
          update: (_, api, __) => AuthService(api),
        ),
        ProxyProvider<ApiService, RotaService>(
          update: (_, api, __) => RotaService(api),
        ),
        ProxyProvider<ApiService, AttendanceService>(
          update: (_, api, __) => AttendanceService(api),
        ),
        ProxyProvider<ApiService, LeaveService>(
          update: (_, api, __) => LeaveService(api),
        ),
        ProxyProvider<ApiService, UserService>(
          update: (_, api, __) => UserService(api),
        ),
        ProxyProvider<ApiService, PayrollService>(
          update: (_, api, __) => PayrollService(api),
        ),
        ProxyProvider<ApiService, SettingsService>(
          update: (_, api, __) => SettingsService(api),
        ),
        ProxyProvider<ApiService, AlertService>(
          update: (_, api, __) => AlertService(api),
        ),
      ],
      child: const CareShiftApp(),
    ),
  );
}

class CareShiftApp extends StatelessWidget {
  const CareShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        useMaterial3: true,
        fontFamily: 'Outfit',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final user = snapshot.data;
        if (user != null) {
          final userModel = UserModel.fromJson(user);
          if (user['role'] == 'admin') {
            return AdminDashboard(user: userModel);
          } else {
            return StaffDashboard(user: userModel);
          }
        }
        
        return const LoginScreen();
      },
    );
  }
}
