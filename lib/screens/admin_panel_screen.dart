import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/album_model.dart';
import '../models/podcast_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_colors.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Global & Announcement Controllers
  final TextEditingController _announcementController = TextEditingController();

  // Drive Engine Folder Uploader Controllers
  final TextEditingController _folderDataController = TextEditingController();
  final TextEditingController _folderCoverUrlController = TextEditingController();
  final TextEditingController _folderAlbumNameController = TextEditingController();
  String _folderSelectedArtist = 'The Weeknd';
  String _folderSelectedGenre = 'Pop';
  String _folderReleaseType = 'Full Album';

  // Realtime Artist Creator & Editor Controllers
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _artistPictureController = TextEditingController();
  final TextEditingController _artistBannerController = TextEditingController();
  final TextEditingController _artistBioController = TextEditingController();
  String _artistSelectedLanguage = 'Hindi';
  String _artistSelectedType = 'Playback Singer';
  Artist? _editingArtist;

  // Custom Category & Language Creator Controllers
  final TextEditingController _newLanguageController = TextEditingController();
  final TextEditingController _newArtistTypeController = TextEditingController();

  // Global Playlist Creator Controllers
  final TextEditingController _playlistTitleController = TextEditingController();
  final TextEditingController _playlistDescController = TextEditingController();
  final TextEditingController _playlistCoverUrlController = TextEditingController();
  String _playlistGenreTag = 'Pop / Trending';
  final List<String> _playlistSelectedSongIds = [];

  // Master Configurator Controllers (Banners & Genres)
  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerSubtitleController = TextEditingController();
  final TextEditingController _bannerCoverUrlController = TextEditingController();

  final TextEditingController _genreNameController = TextEditingController();
  final TextEditingController _genreCoverUrlController = TextEditingController();
  final TextEditingController _homeSectionTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    final admin = Provider.of<AdminProvider>(context, listen: false);
    _announcementController.text = admin.announcementMessage;
    if (admin.artistsCatalog.isNotEmpty) {
      _folderSelectedArtist = admin.artistsCatalog.first.name;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _announcementController.dispose();
    _folderDataController.dispose();
    _folderCoverUrlController.dispose();
    _folderAlbumNameController.dispose();
    _artistNameController.dispose();
    _artistPictureController.dispose();
    _artistBannerController.dispose();
    _artistBioController.dispose();
    _newLanguageController.dispose();
    _newArtistTypeController.dispose();
    _playlistTitleController.dispose();
    _playlistDescController.dispose();
    _playlistCoverUrlController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerCoverUrlController.dispose();
    _genreNameController.dispose();
    _genreCoverUrlController.dispose();
    _homeSectionTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/app_logo.png', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Text('${adminProvider.appName} ADMIN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.secondary),
            onPressed: () => adminProvider.resetBellClick(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: adminProvider.themeAccentColor,
          indicatorWeight: 3,
          labelColor: adminProvider.themeAccentColor,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Analytics & Controls'),
            Tab(icon: Icon(Icons.folder_special), text: 'Drive Engine Uploader'),
            Tab(icon: Icon(Icons.person_add), text: 'Artist Creator & Editor'),
            Tab(icon: Icon(Icons.album), text: 'Manage Catalog & Discography'),
            Tab(icon: Icon(Icons.playlist_add), text: 'Playlists & Podcasts'),
            Tab(icon: Icon(Icons.tune), text: 'Home Screen Configurator'),
            Tab(icon: Icon(Icons.palette_outlined), text: 'Theme & Color Controller'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(adminProvider),
          _buildDriveEngineUploaderTab(adminProvider),
          _buildArtistCreatorAndEditorTab(adminProvider),
          _buildManageCatalogAndDiscographyTab(adminProvider),
          _buildPlaylistsCreatorTab(adminProvider),
          _buildMasterUserPanelConfiguratorTab(adminProvider),
          _buildThemeAndColorsControllerTab(adminProvider),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Real-Time App & System Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total App Songs',
                '${admin.allAppSongs.length}',
                Icons.audiotrack,
                Colors.green,
                onTap: () => _showAllSongsMasterDialog(context, admin),
              ),
              _buildStatCard('Artists Registered', '${admin.artistsCatalog.length}', Icons.people, Colors.purpleAccent),
              _buildStatCard('Curated Playlists', '${admin.playlistsCatalog.length}', Icons.queue_music, Colors.blueAccent),
              _buildStatCard('Albums Created', '${admin.albumsCatalog.length}', Icons.album, Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                    SizedBox(width: 8),
                    Text('Active Connected Firebase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Project ID: ${admin.firebaseProjectId}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Database URL: ${admin.firebaseDbUrl}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Global App Controls', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile(
            value: admin.isMaintenanceMode,
            activeThumbColor: AppColors.primary,
            title: const Text('Maintenance Mode Lock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Lock application with server maintenance notice', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            onChanged: (val) => admin.setMaintenanceMode(val),
          ),
          SwitchListTile(
            value: admin.isVipRequired,
            activeThumbColor: AppColors.primary,
            title: const Text('Require VIP Premier Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Require user subscription to stream audio', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            onChanged: (val) => admin.setVipRequired(val),
          ),
          const SizedBox(height: 14),
          const Text('Global Announcement Broadcast Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _announcementController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () {
              admin.setAnnouncementMessage(_announcementController.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global announcement broadcasted!')));
            },
            child: const Text('Broadcast Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: onTap != null ? AppColors.primary.withValues(alpha: 0.6) : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
                if (onTap != null) const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 10),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveEngineUploaderTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google Drive Engine - Full Album & Track Uploader',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Single Track link OR Google Drive Folder link. Hosted picture URL link applies to all songs!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Hosted Cover Picture URL Link Input
          const Text('Hosted Picture URL Link (Artwork for Songs/Album)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _folderCoverUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://images.unsplash.com/... or https://i.imgur.com/...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Album Name
          const Text('Album / Collection Title', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _folderAlbumNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Bipolar / Starboy Remastered',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Select Artist & Release Type Dropdowns
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Artist (Realtime)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: admin.artistsNamesList.contains(_folderSelectedArtist) ? _folderSelectedArtist : (admin.artistsNamesList.isNotEmpty ? admin.artistsNamesList.first : null),
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: admin.artistsNamesList.map((art) => DropdownMenuItem(value: art, child: Text(art))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _folderSelectedArtist = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Release Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _folderReleaseType,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: admin.releaseTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _folderReleaseType = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Drive Links / Folder Data Box
          Text(
            _folderReleaseType == 'Single Track' ? 'Single Google Drive Link / Audio URL' : 'Google Drive Folder Link / MP3 Links (All 12+ songs)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _folderDataController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'https://drive.google.com/file/d/1ABCXYZ...\nor Google Drive Folder Link',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Bulk Upload Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              icon: const Icon(Icons.cloud_upload),
              label: Text('UPLOAD ${_folderReleaseType.toUpperCase()} TO USER PANEL (REALTIME)', style: const TextStyle(fontWeight: FontWeight.w900)),
              onPressed: () async {
                if (_folderDataController.text.isNotEmpty) {
                  if (_folderReleaseType == 'Single Track') {
                    await admin.uploadSingleSong(
                      title: _folderAlbumNameController.text.isEmpty ? 'Single Track' : _folderAlbumNameController.text,
                      artist: _folderSelectedArtist,
                      album: _folderAlbumNameController.text.isEmpty ? 'Single Release' : _folderAlbumNameController.text,
                      audioUrl: _folderDataController.text,
                      hostedCoverUrl: _folderCoverUrlController.text,
                      genre: _folderSelectedGenre,
                      releaseType: _folderReleaseType,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded Single Track to User Panel!')));
                  } else {
                    final int count = await admin.uploadDriveFolder(
                      folderUrlOrData: _folderDataController.text,
                      hostedCoverUrl: _folderCoverUrlController.text,
                      artistName: _folderSelectedArtist,
                      albumName: _folderAlbumNameController.text.isEmpty ? 'Exotic Collection' : _folderAlbumNameController.text,
                      genre: _folderSelectedGenre,
                      releaseType: _folderReleaseType,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded ALL $count album songs to User Panel & Auto-routed to Albums!')));
                  }

                  _folderDataController.clear();
                  _folderCoverUrlController.clear();
                  _folderAlbumNameController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCreatorAndEditorTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Language & Category Creator Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Custom Languages & Artist Categories', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newLanguageController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(hintText: 'Add Language (e.g. Haryanvi)', filled: true, fillColor: AppColors.surfaceLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                        onPressed: () {
                          if (_newLanguageController.text.isNotEmpty) {
                            admin.addCustomLanguage(_newLanguageController.text);
                            setState(() => _artistSelectedLanguage = _newLanguageController.text);
                            _newLanguageController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added new language!')));
                          }
                        },
                        child: const Text('Add Lang'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newArtistTypeController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(hintText: 'Add Artist Category (e.g. Sufi Rapper)', filled: true, fillColor: AppColors.surfaceLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                        onPressed: () {
                          if (_newArtistTypeController.text.isNotEmpty) {
                            admin.addCustomArtistType(_newArtistTypeController.text);
                            setState(() => _artistSelectedType = _newArtistTypeController.text);
                            _newArtistTypeController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added new artist category!')));
                          }
                        },
                        child: const Text('Add Type'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Realtime Artist Profile Creator & Full Editor
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingArtist == null ? 'Create Realtime Artist Profile' : 'Edit Artist Profile: ${_editingArtist!.name}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_editingArtist != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingArtist = null;
                              _artistNameController.clear();
                              _artistPictureController.clear();
                              _artistBannerController.clear();
                              _artistBioController.clear();
                            });
                          },
                          child: const Text('Cancel Edit', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Select Artist to Edit
                  if (admin.artistsCatalog.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
                      child: DropdownButton<Artist>(
                        hint: const Text('Or Select Existing Artist to Edit Profile', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        value: _editingArtist,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: admin.artistsCatalog.map((art) => DropdownMenuItem(value: art, child: Text('Edit: ${art.name} (${art.artistType})'))).toList(),
                        onChanged: (art) {
                          if (art != null) {
                            setState(() {
                              _editingArtist = art;
                              _artistNameController.text = art.name;
                              _artistPictureController.text = art.imageUrl;
                              _artistBannerController.text = art.bannerUrl;
                              _artistBioController.text = art.bio;
                              _artistSelectedLanguage = art.language;
                              _artistSelectedType = art.artistType;
                            });
                          }
                        },
                      ),
                    ),

                  TextField(
                    controller: _artistNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Artist Name (e.g. Badshah)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _artistPictureController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Profile Picture Hosted Link (URL)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _artistBannerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Banner Cover Hosted Link (URL)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Language', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
                              child: DropdownButton<String>(
                                value: admin.languagesList.contains(_artistSelectedLanguage) ? _artistSelectedLanguage : admin.languagesList.first,
                                isExpanded: true,
                                dropdownColor: AppColors.surface,
                                underline: const SizedBox(),
                                style: const TextStyle(color: Colors.white),
                                items: admin.languagesList.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _artistSelectedLanguage = v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Artist Category / Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
                              child: DropdownButton<String>(
                                value: admin.artistTypesList.contains(_artistSelectedType) ? _artistSelectedType : admin.artistTypesList.first,
                                isExpanded: true,
                                dropdownColor: AppColors.surface,
                                underline: const SizedBox(),
                                style: const TextStyle(color: Colors.white),
                                items: admin.artistTypesList.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _artistSelectedType = v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _artistBioController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Artist Bio & Description for User Panel', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                      onPressed: () {
                        if (_artistNameController.text.isNotEmpty) {
                          final artistObj = Artist(
                            id: _editingArtist?.id ?? 'art_${DateTime.now().millisecondsSinceEpoch}',
                            name: _artistNameController.text,
                            imageUrl: _artistPictureController.text.isEmpty
                                ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400'
                                : _artistPictureController.text,
                            bannerUrl: _artistBannerController.text,
                            bio: _artistBioController.text.isEmpty ? 'Exotic Verified Premier Artist.' : _artistBioController.text,
                            language: _artistSelectedLanguage,
                            artistType: _artistSelectedType,
                            genre: 'Pop',
                          );

                          if (_editingArtist != null) {
                            admin.editArtist(artistObj);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated artist profile "${artistObj.name}"!')));
                          } else {
                            admin.addArtistFull(artistObj);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created realtime artist profile "${artistObj.name}"!')));
                          }

                          setState(() {
                            _editingArtist = null;
                            _folderSelectedArtist = artistObj.name;
                          });
                          _artistNameController.clear();
                          _artistPictureController.clear();
                          _artistBannerController.clear();
                          _artistBioController.clear();
                        }
                      },
                      child: Text(_editingArtist == null ? 'SAVE REALTIME ARTIST PROFILE' : 'UPDATE ARTIST PROFILE', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCatalogAndDiscographyTab(AdminProvider admin) {
    final artists = admin.artistsCatalog;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          final artistSongs = admin.allAppSongs.where((s) => s.artist.toLowerCase().contains(artist.name.toLowerCase())).toList();

          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(artist.imageUrl),
              ),
              title: Text(artist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${artist.language} • ${artist.artistType} • ${artistSongs.length} Tracks', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  admin.deleteArtist(artist.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted artist "${artist.name}"')));
                },
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bio: ${artist.bio}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Artist Discography & Edit Track Details:', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            icon: const Icon(Icons.album, size: 16),
                            label: const Text('Create Album Collection', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _showCreateAlbumDialog(context, admin, artist, artistSongs),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      artistSongs.isEmpty
                          ? const Text('No tracks uploaded for this artist.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: artistSongs.length,
                              itemBuilder: (ctx, sIdx) {
                                final song = artistSongs[sIdx];
                                return ListTile(
                                  dense: true,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(song.coverUrl, width: 32, height: 32, fit: BoxFit.cover),
                                  ),
                                  title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text(song.album, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                                        onPressed: () => _showEditSongDialog(context, admin, song),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                        onPressed: () => admin.deleteSong(song.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistsCreatorTab(AdminProvider admin) {
    final allSongs = admin.allAppSongs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Curated Global Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Mix songs from different artists into a single playlist for the User Panel Home Screen!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),

          TextField(
            controller: _playlistTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Playlist Title (e.g. Bipolar Hits / Cyberpunk Beats)', filled: true, fillColor: AppColors.surface),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _playlistCoverUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Cover Image Hosted Link (URL)', filled: true, fillColor: AppColors.surface),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _playlistDescController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Playlist Description & Mood Tag', filled: true, fillColor: AppColors.surface),
          ),
          const SizedBox(height: 14),

          const Text('Select Songs to Include in Playlist:', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Container(
            height: 200,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: ListView.builder(
              itemCount: allSongs.length,
              itemBuilder: (ctx, sIdx) {
                final song = allSongs[sIdx];
                final isSelected = _playlistSelectedSongIds.contains(song.id);
                return CheckboxListTile(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  checkColor: Colors.black,
                  title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('${song.artist} • ${song.album}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _playlistSelectedSongIds.add(song.id);
                      } else {
                        _playlistSelectedSongIds.remove(song.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('SAVE & PUBLISH PLAYLIST TO USER PANEL', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (_playlistTitleController.text.isNotEmpty) {
                  final selectedSongsList = allSongs.where((s) => _playlistSelectedSongIds.contains(s.id)).toList();
                  final newPlaylist = Playlist(
                    id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
                    title: _playlistTitleController.text,
                    description: _playlistDescController.text.isEmpty ? 'Curated Exotic Playlist' : _playlistDescController.text,
                    coverUrl: _playlistCoverUrlController.text.isEmpty
                        ? 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=800'
                        : _playlistCoverUrlController.text,
                    genreTag: _playlistGenreTag,
                    songs: selectedSongsList,
                  );

                  admin.addPlaylist(newPlaylist);
                  _playlistTitleController.clear();
                  _playlistDescController.clear();
                  _playlistCoverUrlController.clear();
                  setState(() => _playlistSelectedSongIds.clear());

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Published Playlist "${newPlaylist.title}" to User Panel!')));
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          const Text('Active App Playlists', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: admin.playlistsCatalog.length,
            itemBuilder: (ctx, idx) {
              final pl = admin.playlistsCatalog[idx];
              return ListTile(
                leading: Image.network(pl.coverUrl, width: 40, height: 40, fit: BoxFit.cover),
                title: Text(pl.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${pl.songs.length} Tracks • ${pl.description}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => admin.deletePlaylist(pl.id),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Podcasts & Shows Catalog', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Podcast Show', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _showCreatePodcastDialog(context, admin),
              ),
            ],
          ),
          const SizedBox(height: 8),
          admin.podcastsCatalog.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No Podcast shows created yet. Tap "Create Podcast Show" above!', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: admin.podcastsCatalog.length,
                  itemBuilder: (ctx, idx) {
                    final pod = admin.podcastsCatalog[idx];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(pod.coverUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.mic, color: Color(0xFF00FF87))),
                      ),
                      title: Text(pod.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${pod.publisher} • ${pod.episodes.length} episodes', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF00FF87), size: 20),
                            onPressed: () => _showCreatePodcastDialog(context, admin, existing: pod),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              admin.deletePodcast(pod.id);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted Podcast "${pod.title}"')));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMasterUserPanelConfiguratorTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Panel Master Configurator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Configure Hero Carousel Banners, Musical Genres, and User Panel Branding!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),

          // Add Hero Banner Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Home Screen Hero Banner', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bannerTitleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Banner Main Title (e.g. STARBOY REMASTERED)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bannerSubtitleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Banner Subtitle / Description', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bannerCoverUrlController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Banner Background Image Link (URL)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                      onPressed: () {
                        if (_bannerTitleController.text.isNotEmpty) {
                          admin.addHeroBanner(
                            _bannerTitleController.text,
                            _bannerSubtitleController.text,
                            _bannerCoverUrlController.text.isEmpty
                                ? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=1200'
                                : _bannerCoverUrlController.text,
                          );
                          _bannerTitleController.clear();
                          _bannerSubtitleController.clear();
                          _bannerCoverUrlController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added Hero Banner to User Panel Home Screen!')));
                        }
                      },
                      child: const Text('Publish Hero Banner', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Add Musical Genre Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Musical Genre / Mood Category', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _genreNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Genre Name (e.g. Haryanvi Beats / Lo-Fi Lounge)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _genreCoverUrlController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Genre Cover Image Link (URL)', filled: true, fillColor: AppColors.surfaceLight),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                      onPressed: () {
                        if (_genreNameController.text.isNotEmpty) {
                          admin.addGenre(
                            _genreNameController.text,
                            _genreCoverUrlController.text.isEmpty
                                ? 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400'
                                : _genreCoverUrlController.text,
                          );
                          _genreNameController.clear();
                          _genreCoverUrlController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added Genre Category to User Panel!')));
                        }
                      },
                      child: const Text('Publish Genre Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Home Screen Vertical Sections Array Manager Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Home Screen Vertical Sections Manager', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Add, reorder or remove Home Screen sections (e.g. Top Music, Fresh Finds, Favorites)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _homeSectionTitleController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(hintText: 'New Section Title (e.g. Top Music / Devotional)', filled: true, fillColor: AppColors.surfaceLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
                        onPressed: () {
                          if (_homeSectionTitleController.text.trim().isNotEmpty) {
                            admin.addHomeSection(_homeSectionTitleController.text.trim());
                            _homeSectionTitleController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added new Vertical Section to Home Screen!')));
                          }
                        },
                        child: const Text('Add Section', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Active Vertical Sections:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Column(
                    children: List.generate(admin.homeSectionsList.length, (idx) {
                      final title = admin.homeSectionsList[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(radius: 12, backgroundColor: AppColors.surfaceLight, child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            admin.deleteHomeSection(idx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed section "$title" from Home Screen')));
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context, AdminProvider admin, Artist artist, List<Song> artistSongs) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '2026');
    final coverCtrl = TextEditingController(text: artist.imageUrl);
    final List<String> selectedSongIds = [];

    // Fallback: Use all app songs if artist has no specific tracks yet
    final availableSongs = artistSongs.isNotEmpty
        ? artistSongs
        : admin.allAppSongs.where((s) => s.artist.toLowerCase().contains(artist.name.toLowerCase()) || s.artist == 'Various Artists').toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Create Album Collection for ${artist.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Album Title (e.g. Bipolar / Starboy)', labelStyle: TextStyle(color: AppColors.primary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Release Year / Date', labelStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: coverCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Album Cover Picture Link (URL)', labelStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 12),
                const Text('Select Tracks for Album:', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                availableSongs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No tracks available. Upload songs via Drive Engine first!', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      )
                    : Column(
                        children: availableSongs.map((song) {
                          final isChecked = selectedSongIds.contains(song.id);
                          return CheckboxListTile(
                            dense: true,
                            activeColor: AppColors.primary,
                            checkColor: Colors.black,
                            title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text(song.album, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            value: isChecked,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedSongIds.add(song.id);
                                } else {
                                  selectedSongIds.remove(song.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () {
                final albumTitle = titleCtrl.text.trim();
                if (albumTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an Album Title!')));
                  return;
                }

                final cover = coverCtrl.text.trim();
                final albumSongs = selectedSongIds.isEmpty
                    ? availableSongs
                    : availableSongs.where((s) => selectedSongIds.contains(s.id)).toList();

                final newAlbum = Album(
                  id: 'alb_${DateTime.now().millisecondsSinceEpoch}',
                  title: albumTitle,
                  artist: artist.name,
                  coverUrl: cover.isEmpty ? artist.imageUrl : cover,
                  releaseYear: dateCtrl.text,
                  songs: albumSongs,
                );

                admin.addAlbum(newAlbum);

                for (final song in albumSongs) {
                  final updated = Song(
                    id: song.id,
                    title: song.title,
                    artist: artist.name,
                    album: albumTitle,
                    duration: song.duration,
                    audioUrl: song.audioUrl,
                    coverUrl: cover.isEmpty ? song.coverUrl : cover,
                    genre: song.genre,
                  );
                  admin.updateSongDetails(song.id, updated);
                }

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created Album "$albumTitle" with ${albumSongs.length} tracks for ${artist.name}! Auto-routed to Artist Profile.')),
                );
              },
              child: const Text('SAVE ALBUM COLLECTION', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSongDialog(BuildContext context, AdminProvider admin, Song song) {
    final titleCtrl = TextEditingController(text: song.title);
    final artistCtrl = TextEditingController(text: song.artist);
    final albumCtrl = TextEditingController(text: song.album);
    final coverCtrl = TextEditingController(text: song.coverUrl);
    final audioCtrl = TextEditingController(text: song.audioUrl);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Track: ${song.title}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Track Title'), style: const TextStyle(color: Colors.white)),
              TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Artist Name'), style: const TextStyle(color: Colors.white)),
              TextField(controller: albumCtrl, decoration: const InputDecoration(labelText: 'Album Name'), style: const TextStyle(color: Colors.white)),
              TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: 'Cover Picture Link (URL)'), style: const TextStyle(color: Colors.white)),
              TextField(controller: audioCtrl, decoration: const InputDecoration(labelText: 'Audio Stream URL'), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () {
              final updated = Song(
                id: song.id,
                title: titleCtrl.text,
                artist: artistCtrl.text,
                album: albumCtrl.text,
                duration: song.duration,
                audioUrl: audioCtrl.text,
                coverUrl: coverCtrl.text,
                genre: song.genre,
              );
              admin.updateSongDetails(song.id, updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated track "${updated.title}"!')));
            },
            child: const Text('Save Track Details'),
          ),
        ],
      ),
    );
  }

  void _showAllSongsMasterDialog(BuildContext context, AdminProvider admin) {
    final searchCtrl = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allSongs = admin.allAppSongs;
          final filteredSongs = searchQuery.trim().isEmpty
              ? allSongs
              : allSongs.where((s) =>
                  s.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  s.artist.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  s.album.toLowerCase().contains(searchQuery.toLowerCase())).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.music_note, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Total App Songs Manager (${allSongs.length})',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(bottomCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Realtime Search Bar
                TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search songs by title, artist, or album...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              setModalState(() {
                                searchCtrl.clear();
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Songs List
                Expanded(
                  child: filteredSongs.isEmpty
                      ? const Center(
                          child: Text('No matching songs found.', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredSongs.length,
                          itemBuilder: (listCtx, idx) {
                            final song = filteredSongs[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    song.coverUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(width: 44, height: 44, color: AppColors.surfaceLight, child: const Icon(Icons.music_note, color: Colors.white)),
                                  ),
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${song.artist} • ${song.album}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit Song Button
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                      onPressed: () {
                                        _showEditSongDialog(context, admin, song);
                                      },
                                    ),
                                    // Delete Song Button
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (delCtx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            title: const Text('Delete Song?', style: TextStyle(color: Colors.white)),
                                            content: Text('Are you sure you want to permanently delete "${song.title}"?', style: const TextStyle(color: AppColors.textSecondary)),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(delCtx), child: const Text('Cancel')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                onPressed: () {
                                                  admin.deleteSong(song.id);
                                                  Navigator.pop(delCtx);
                                                  setModalState(() {});
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${song.title}"!')));
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreatePodcastDialog(BuildContext context, AdminProvider admin, {Podcast? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final pubCtrl = TextEditingController(text: existing?.publisher ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final coverCtrl = TextEditingController(text: existing?.coverUrl ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? 'Podcasts');
    final List<String> selectedSongIds = existing?.episodes.map((e) => e.id).toList() ?? [];

    final availableSongs = admin.allAppSongs;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(existing == null ? 'Create Podcast Show / Category' : 'Edit Podcast: ${existing.title}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Podcast Show Title', labelStyle: TextStyle(color: AppColors.primary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pubCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Publisher / Host Name', labelStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Podcast Description', labelStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: coverCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Podcast Cover Picture Link (URL)', labelStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: catCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Category Tag (e.g. Talk / Motivation)', labelStyle: TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.surfaceLight),
                ),
                const SizedBox(height: 12),
                const Text('Select Songs / Episodes to add to Podcast:', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                availableSongs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No tracks available. Upload songs via Drive Engine first!', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      )
                    : Column(
                        children: availableSongs.map((song) {
                          final isChecked = selectedSongIds.contains(song.id);
                          return CheckboxListTile(
                            dense: true,
                            activeColor: AppColors.primary,
                            checkColor: Colors.black,
                            title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text(song.artist, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            value: isChecked,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedSongIds.add(song.id);
                                } else {
                                  selectedSongIds.remove(song.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () {
                final podTitle = titleCtrl.text.trim();
                if (podTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Podcast Title!')));
                  return;
                }

                final cover = coverCtrl.text.trim();
                final episodes = availableSongs.where((s) => selectedSongIds.contains(s.id)).toList();

                final podcastObj = Podcast(
                  id: existing?.id ?? 'pod_${DateTime.now().millisecondsSinceEpoch}',
                  title: podTitle,
                  publisher: pubCtrl.text.trim().isEmpty ? 'Exotic Host' : pubCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  coverUrl: cover.isEmpty ? 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?q=80&w=400' : cover,
                  category: catCtrl.text.trim().isEmpty ? 'Podcasts' : catCtrl.text.trim(),
                  episodes: episodes,
                );

                if (existing == null) {
                  admin.addPodcast(podcastObj);
                } else {
                  admin.updatePodcast(existing.id, podcastObj);
                }

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved Podcast "${podcastObj.title}" with ${episodes.length} episode tracks! Available in User Panel.')),
                );
              },
              child: const Text('SAVE PODCAST SHOW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeAndColorsControllerTab(AdminProvider admin) {
    final hexController = TextEditingController();

    final presets = [
      {'name': 'Transparent Silver Glass', 'color': const Color(0xE6FFFFFF), 'icon': '✨'},
      {'name': 'Emerald Cyber Green', 'color': const Color(0xFF00FF87), 'icon': '🟢'},
      {'name': 'Electric Neon Cyan', 'color': const Color(0xFF00DFD8), 'icon': '💙'},
      {'name': 'Deep Purple Violet', 'color': const Color(0xFF9B51E0), 'icon': '💜'},
      {'name': 'Crimson Sunset Red', 'color': const Color(0xFFFF3B30), 'icon': '❤️'},
      {'name': 'Luxury Gold Amber', 'color': const Color(0xFFFFCC00), 'icon': '💛'},
      {'name': 'Pure Pearl White', 'color': const Color(0xFFFFFFFF), 'icon': '🤍'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme & Color Controller', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Control app branding logo, theme colors, and glassmorphic translucency in real-time!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),

          // Logo Preview & Brand Header Card
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: admin.themeAccentColor.withValues(alpha: 0.4))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: admin.themeAccentColor.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: admin.themeAccentColor.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXOTIC Music App Logo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Active Theme: ${admin.themeName}', style: TextStyle(color: admin.themeAccentColor, fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Frosted Glassmorphism Active', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Translucency & Glassmorphism Switch
          Card(
            color: AppColors.surface,
            child: SwitchListTile(
              activeTrackColor: admin.themeAccentColor,
              activeColor: Colors.black,
              title: const Text('Frosted Glassmorphism Theme Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Enables translucent glass cards, silver outlines & frosted glow effects across the app', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              value: admin.isGlassmorphismEnabled,
              onChanged: (val) {
                admin.toggleGlassmorphism(val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val ? 'Glassmorphism Translucency Enabled!' : 'Standard Theme Mode Enabled')),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Theme Color Presets Section
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Theme Color Preset', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Changes button highlights, sliders, icons, tabs and active indicators across the entire app:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      final pName = p['name'] as String;
                      final pColor = p['color'] as Color;
                      final pIcon = p['icon'] as String;
                      final isSelected = admin.themeName == pName;

                      return GestureDetector(
                        onTap: () {
                          admin.setThemeAccent(pColor, pName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('App Theme set to: $pName')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? pColor.withValues(alpha: 0.25) : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? pColor : Colors.white12,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text('$pIcon $pName', style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check, color: pColor, size: 16),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Custom Hex Color Input Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom Accent Color (Hex Code)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Enter custom Hex Code (e.g. #00FF87, #FF007F, #7B2CBF, #FFFFFF):', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hexController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: '#00FF87',
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: admin.themeAccentColor, foregroundColor: Colors.black),
                        onPressed: () {
                          final text = hexController.text.trim().replaceAll('#', '');
                          if (text.length == 6 || text.length == 8) {
                            try {
                              final hexVal = int.parse(text.length == 6 ? 'FF$text' : text, radix: 16);
                              final customCol = Color(hexVal);
                              admin.setThemeAccent(customCol, 'Custom (#$text)');
                              hexController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Applied Custom Accent Color #$text!')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Hex Code! Use format #RRGGBB')));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit Hex Code (e.g. #00FF87)')));
                          }
                        },
                        child: const Text('Apply Color', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
