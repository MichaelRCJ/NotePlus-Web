import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Configuración',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('General'),
          _buildSettingCard(
            icon: Icons.language_rounded,
            title: 'Idioma',
            subtitle: context.watch<ThemeProvider>().language,
            onTap: () => _showLanguageDialog(),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Notificaciones'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSwitchCard(
                icon: Icons.notifications_rounded,
                title: 'Notificaciones',
                subtitle: 'Recibir notificaciones de recordatorios',
                value: themeProvider.notificationsEnabled,
                onChanged: (value) => themeProvider.setNotificationsEnabled(value),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Apariencia'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSwitchCard(
                icon: Icons.dark_mode_rounded,
                title: 'Modo Oscuro',
                subtitle: 'Usar tema oscuro',
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.setDarkMode(value),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Color de Énfasis'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).cardTheme.shape != null 
                            ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                            : const Color(0xFF2D3142),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecciona un color para las etiquetas y elementos de énfasis',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ThemeProvider.colorOptions.map((color) {
                            final isSelected = themeProvider.primaryColor == color;
                            return GestureDetector(
                              onTap: () => themeProvider.setPrimaryColor(color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? color : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Cuenta'),
          _buildSettingCard(
            icon: Icons.person_rounded,
            title: 'Perfil',
            subtitle: 'Gestionar información personal',
            onTap: () => Navigator.of(context).pushNamed('/profile'),
          ),
          _buildSettingCard(
            icon: Icons.security_rounded,
            title: 'Seguridad',
            subtitle: 'Contraseña y privacidad',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Datos'),
          _buildSettingCard(
            icon: Icons.backup_rounded,
            title: 'Respaldo',
            subtitle: 'Hacer copia de seguridad',
            onTap: () {},
          ),
          _buildSettingCard(
            icon: Icons.restore_rounded,
            title: 'Restaurar',
            subtitle: 'Restaurar desde copia de seguridad',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Acerca de'),
          _buildSettingCard(
            icon: Icons.info_rounded,
            title: 'Versión',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _buildSettingCard(
            icon: Icons.help_outline_rounded,
            title: 'Ayuda y Soporte',
            subtitle: 'Preguntas frecuentes',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ElevatedButton.icon(
                onPressed: () => _logout(authProvider),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.watch<ThemeProvider>().primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.watch<ThemeProvider>().primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.watch<ThemeProvider>().primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.watch<ThemeProvider>().primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: context.watch<ThemeProvider>().primaryColor,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Seleccionar idioma', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Español', 'English', 'Français'].map((lang) {
            final isSelected = context.watch<ThemeProvider>().language == lang;
            return ListTile(
              title: Text(lang, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface)),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: context.watch<ThemeProvider>().primaryColor)
                  : null,
              onTap: () {
                context.read<ThemeProvider>().setLanguage(lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _logout(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: Text('Cerrar sesión', style: GoogleFonts.inter(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

