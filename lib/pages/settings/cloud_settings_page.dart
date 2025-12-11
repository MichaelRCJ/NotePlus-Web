import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/cloud_note_provider.dart';
import '../../providers/cloud_reminder_provider.dart';
import '../../providers/auth_provider.dart';

class CloudSettingsPage extends StatefulWidget {
  const CloudSettingsPage({super.key});

  @override
  State<CloudSettingsPage> createState() => _CloudSettingsPageState();
}

class _CloudSettingsPageState extends State<CloudSettingsPage> {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isAuthenticated = user != null;
    });
  }

  Future<void> _toggleCloudSync(bool enabled) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (enabled) {
        // Enable cloud sync
        if (!_isAuthenticated) {
          await _signInAnonymously();
        }
        
        // Update providers
        final noteProvider = context.read<CloudNoteProvider>();
        final reminderProvider = context.read<CloudReminderProvider>();
        
        noteProvider.setCloudEnabled(true);
        reminderProvider.setCloudEnabled(true);
        
        // Load data from cloud
        await Future.wait([
          noteProvider.loadNotes(),
          reminderProvider.loadReminders(),
        ]);
      } else {
        // Disable cloud sync
        final noteProvider = context.read<CloudNoteProvider>();
        final reminderProvider = context.read<CloudReminderProvider>();
        
        noteProvider.setCloudEnabled(false);
        reminderProvider.setCloudEnabled(false);
        
        // Load data from local storage
        await Future.wait([
          noteProvider.loadNotes(),
          reminderProvider.loadReminders(),
        ]);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _isAuthenticated = true;
      });
      
      // Update auth provider
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser == null) {
        // Create a simple user object for anonymous user
        authProvider.setCurrentUser({
          'id': result.user!.uid,
          'email': 'anonymous@example.com',
          'name': 'Usuario Anónimo',
        });
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión anónima: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _isAuthenticated = false;
      });
      
      // Disable cloud sync
      await _toggleCloudSync(false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cerrar sesión: $e';
      });
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final noteProvider = context.read<CloudNoteProvider>();
      final reminderProvider = context.read<CloudReminderProvider>();
      
      await Future.wait([
        noteProvider.syncWithCloud(),
        reminderProvider.syncWithCloud(),
      ]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronización completada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de sincronización: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<CloudNoteProvider>();
    final reminderProvider = context.watch<CloudReminderProvider>();
    final isCloudEnabled = noteProvider.isCloudEnabled;
    final isSyncing = noteProvider.isSyncing || reminderProvider.isSyncing;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252836),
        elevation: 0,
        title: Text(
          'Configuración de Nube',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloud sync toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252836),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D3142)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCloudEnabled 
                        ? const Color(0xFF6366F1).withOpacity(0.15)
                        : const Color(0xFF2D3142),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    color: isCloudEnabled ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                  ),
                ),
                title: Text(
                  'Sincronización en la nube',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  isCloudEnabled 
                      ? 'Los datos se guardan en la nube'
                      : 'Los datos se guardan localmente',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                trailing: Switch(
                  value: isCloudEnabled,
                  onChanged: _isLoading ? null : _toggleCloudSync,
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sync status
            if (isCloudEnabled) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252836),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D3142)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cloud_done_rounded,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      title: Text(
                        'Estado de sincronización',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isSyncing ? 'Sincronizando...' : 'Sincronizado',
                        style: GoogleFonts.inter(
                          color: isSyncing ? Colors.orange : Colors.green,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isSyncing 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                              ),
                            )
                          : null,
                    ),
                    
                    if (!isSyncing) ...[
                      const Divider(height: 1, color: Color(0xFF2D3142)),
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.sync_rounded,
                          color: Color(0xFF6366F1),
                        ),
                        title: Text(
                          'Sincronizar ahora',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: _syncNow,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Account info
            if (_isAuthenticated) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252836),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D3142)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_circle_rounded,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  title: Text(
                    'Cuenta conectada',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    FirebaseAuth.instance.currentUser?.isAnonymous == true 
                        ? 'Usuario Anónimo'
                        : FirebaseAuth.instance.currentUser?.email ?? '',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Cerrar sesión',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Info section
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF252836),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D3142)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acerca de la sincronización',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Los datos se guardan en Firebase Firestore\n'
                    '• Sincronización automática cuando hay conexión\n'
                    '• Copia de seguridad local siempre disponible\n'
                    '• Los datos están cifrados y seguros',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
