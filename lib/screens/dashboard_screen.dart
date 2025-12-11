import 'package:flutter/material.dart';
import '../models/linked_site_model.dart';
import '../services/storage_service.dart';
import 'password_screen.dart';
import '../services/ctweb_secure_store.dart';
import 'pairing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<LinkedSiteModel> _sites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final sites = await StorageService.loadSites();
    setState(() {
      _sites = sites;
      _loading = false;
    });
  }

  Future<void> _openPassword(LinkedSiteModel site) async {
    // 1️⃣ Try to load CT_Web from secure storage (keystore)
    String? ctWebFromSecure;
    try {
      if (site.userId.isNotEmpty && site.siteId.isNotEmpty) {
      ctWebFromSecure = await CtWebSecureStore.loadCtWeb(
      userId: site.userId,
      siteId: site.siteId,
        );
    }   

    } catch (_) {
      // ignore, we'll just fall back
    }

    // 2️⃣ Fallback to whatever is stored in the model (plain ctWebBase64)
    final ctWeb = ctWebFromSecure ?? site.ctWebBase64;

    if (ctWeb.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load CT_Web for this site.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasswordScreen(
          ctWeb: ctWeb,
        ),
      ),
    );
  }

  void _goToPairing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PairingScreen()),
    ).then((_) => _loadSites()); // refresh after coming back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Neon / gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF141B3F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Linked Accounts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _goToPairing,
                      icon: const Icon(Icons.add_rounded, color: Colors.cyan),
                      tooltip: 'Link new website',
                    ),
                  ],
                ),
              ),

              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  ),
                )
              else if (_sites.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_open_outlined,
                            size: 48, color: Colors.white38),
                        SizedBox(height: 12),
                        Text(
                          'No linked websites yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap + to pair your first site',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _sites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final site = _sites[index];
                      return _SiteCard(
                        site: site,
                        onTap: () => _openPassword(site),
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF111827),
                              title: const Text(
                                'Remove site?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Do you want to unlink "${site.displayName}"?',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await StorageService.deleteSite(index);
                            _loadSites();
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final LinkedSiteModel site;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SiteCard({
    required this.site,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // If logoUrl provided, build network image. Else, initials avatar.
    Widget avatar;
    if (site.logoUrl.isNotEmpty) {
      // if logoUrl is relative ("/icons/logo.png"), prefix with serverUrl
      final url = site.logoUrl.startsWith('http')
          ? site.logoUrl
          : '${site.serverUrl}${site.logoUrl}';
      avatar = CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(url),
        backgroundColor: Colors.transparent,
      );
    } else {
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: Colors.cyanAccent.withOpacity(0.12),
        child: Text(
          site.initials,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.25),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    site.username,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }
}
