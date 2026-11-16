/**
 * ==========================================================================
 * EXOTIC MUSIC - MASTER WEB ADMIN CONTROL CENTER ENGINE
 * Real-time Firebase REST Database Sync & Google Drive API v3 Stream Engine
 * ==========================================================================
 */

// Master Configuration & Credentials
const CONFIG = {
  MASTER_PASSWORD: "9057578663@*RAZ",
  FIREBASE_DB_URL: "https://exoticglobalmusic-default-rtdb.firebaseio.com",
  DRIVE_API_KEY: "AIzaSyAsnrQhFjzUpBnQel1aCcFiWMebMkXxcwU",
  DEFAULT_COVER: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400",
  DEFAULT_ARTIST_IMG: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400"
};

// Application State
const state = {
  isAuthenticated: false,
  songs: [],
  artists: [],
  playlists: [],
  podcasts: [],
  heroBanners: [],
  homeSections: [
    "From your favorite artists",
    "Fresh finds",
    "Keep recommendation for later",
    "Albums + Singles for you",
    "Popular Radio",
    "Your top artists",
    "Hit Lists for you",
    "Featured Releases",
    "Best of Punjabi",
    "Fresh Punjabi",
    "Charts & Trends",
    "Top Music"
  ],
  appConfig: {
    appName: "EXOTIC MUSIC",
    isMaintenanceMode: false,
    isVipRequired: false,
    announcementMessage: "Welcome to EXOTIC MUSIC! Stream unlimited high-definition music."
  },
  detectedFolderTracks: [],
  currentPlayingTrack: null,
  activeTab: "dashboard"
};

// Native HTML5 Audio Controller
const audioController = {
  element: null,
  isPlaying: false,

  init() {
    this.element = document.getElementById("nativeAudio");
    if (!this.element) return;

    this.element.addEventListener("timeupdate", () => {
      const current = this.element.currentTime || 0;
      const duration = this.element.duration || 0;
      document.getElementById("playerCurrentTime").textContent = formatDuration(current);
      if (duration > 0) {
        document.getElementById("playerTotalDuration").textContent = formatDuration(duration);
        document.getElementById("playerScrubber").value = (current / duration) * 100;
      }
    });

    this.element.addEventListener("ended", () => {
      this.isPlaying = false;
      this.updatePlayBtn();
    });

    this.element.addEventListener("error", (e) => {
      console.warn("Audio playback error:", e);
      showToast("Audio stream error or network timeout", "error");
      this.isPlaying = false;
      this.updatePlayBtn();
    });
  },

  play(track) {
    if (!this.element) return;
    state.currentPlayingTrack = track;

    let streamUrl = track.audioUrl || track.url;
    if (streamUrl.includes("drive.google.com") || !streamUrl.includes("googleapis.com/drive/v3/files")) {
      streamUrl = convertDriveLinkToDirectStream(streamUrl);
    }

    this.element.src = streamUrl;
    this.element.play().then(() => {
      this.isPlaying = true;
      this.updatePlayerUI(track);
      this.updatePlayBtn();
    }).catch(err => {
      console.warn("Playback prevented or failed:", err);
      showToast("Tap Play to begin playback (Browser policy)", "error");
    });
  },

  toggle() {
    if (!this.element || !this.element.src) return;
    if (this.isPlaying) {
      this.element.pause();
      this.isPlaying = false;
    } else {
      this.element.play();
      this.isPlaying = true;
    }
    this.updatePlayBtn();
  },

  updatePlayBtn() {
    const icon = document.getElementById("playPauseIcon");
    if (icon) {
      icon.className = this.isPlaying ? "fa-solid fa-pause" : "fa-solid fa-play";
    }
  },

  updatePlayerUI(track) {
    document.getElementById("playerCover").src = track.coverUrl || CONFIG.DEFAULT_COVER;
    document.getElementById("playerTitle").textContent = track.title || "Unknown Title";
    document.getElementById("playerArtist").textContent = track.artist || "Unknown Artist";
  }
};

// ==========================================================================
// 1. AUTHENTICATION & SECURITY
// ==========================================================================
function checkAuth() {
  const isAuth = sessionStorage.getItem("exotic_admin_auth");
  if (isAuth === "true") {
    state.isAuthenticated = true;
    document.getElementById("authOverlay").style.display = "none";
    initAdminPanel();
  } else {
    state.isAuthenticated = false;
    document.getElementById("authOverlay").style.display = "flex";
  }
}

function handleAuthSubmit(event) {
  event.preventDefault();
  const inputPass = document.getElementById("authPassword").value.trim();
  const errorEl = document.getElementById("authError");

  if (inputPass === CONFIG.MASTER_PASSWORD) {
    sessionStorage.setItem("exotic_admin_auth", "true");
    state.isAuthenticated = true;
    errorEl.style.display = "none";
    document.getElementById("authOverlay").style.display = "none";
    showToast("Master Admin Authenticated Successfully!", "success");
    initAdminPanel();
  } else {
    errorEl.textContent = "Invalid Admin Password! Please try again.";
    errorEl.style.display = "block";
    document.getElementById("authPassword").value = "";
  }
}

function lockAdminPanel() {
  sessionStorage.removeItem("exotic_admin_auth");
  state.isAuthenticated = false;
  document.getElementById("authPassword").value = "";
  document.getElementById("authOverlay").style.display = "flex";
  if (audioController.element) {
    audioController.element.pause();
  }
}

function togglePasswordVisibility() {
  const passInput = document.getElementById("authPassword");
  const eyeIcon = document.getElementById("eyeIcon");
  if (passInput.type === "password") {
    passInput.type = "text";
    eyeIcon.className = "fa-solid fa-eye-slash";
  } else {
    passInput.type = "password";
    eyeIcon.className = "fa-solid fa-eye";
  }
}

// ==========================================================================
// 2. FIREBASE REST API INTEGRATION
// ==========================================================================
async function firebaseFetch(endpoint) {
  const url = `${CONFIG.FIREBASE_DB_URL}/${endpoint}.json`;
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    return data;
  } catch (err) {
    console.error(`Firebase fetch error [${endpoint}]:`, err);
    return null;
  }
}

async function firebaseSave(endpoint, payload) {
  const url = `${CONFIG.FIREBASE_DB_URL}/${endpoint}.json`;
  try {
    const res = await fetch(url, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    return res.ok;
  } catch (err) {
    console.error(`Firebase save error [${endpoint}]:`, err);
    return false;
  }
}

async function syncAllWithFirebase(showNotification = false) {
  updateSyncBadge("syncing");

  try {
    // 1. Fetch Songs
    const fbSongs = await firebaseFetch("songs");
    if (fbSongs) {
      if (Array.isArray(fbSongs)) {
        state.songs = fbSongs.filter(Boolean);
      } else if (typeof fbSongs === "object") {
        state.songs = Object.values(fbSongs).filter(Boolean);
      }
    }

    // 2. Fetch Artists
    const fbArtists = await firebaseFetch("artists");
    if (fbArtists) {
      if (Array.isArray(fbArtists)) {
        state.artists = fbArtists.filter(Boolean);
      } else if (typeof fbArtists === "object") {
        state.artists = Object.values(fbArtists).filter(Boolean);
      }
    }

    // 3. Fetch Playlists
    const fbPlaylists = await firebaseFetch("playlists");
    if (fbPlaylists) {
      state.playlists = Array.isArray(fbPlaylists) ? fbPlaylists.filter(Boolean) : Object.values(fbPlaylists).filter(Boolean);
    }

    // 4. Fetch Hero Banners
    const fbBanners = await firebaseFetch("heroBanners");
    if (fbBanners) {
      state.heroBanners = Array.isArray(fbBanners) ? fbBanners.filter(Boolean) : Object.values(fbBanners).filter(Boolean);
    }

    // 5. Fetch Announcement
    const fbAnnouncement = await firebaseFetch("announcement");
    if (fbAnnouncement && typeof fbAnnouncement === "string") {
      state.appConfig.announcementMessage = fbAnnouncement;
      document.getElementById("cfgAnnouncement").value = fbAnnouncement;
    }

    // 6. Fetch App Config
    const fbConfig = await firebaseFetch("appConfig");
    if (fbConfig) {
      Object.assign(state.appConfig, fbConfig);
      document.getElementById("cfgAppName").value = state.appConfig.appName || "EXOTIC MUSIC";
      document.getElementById("cfgMaintenance").value = state.appConfig.isMaintenanceMode ? "true" : "false";
      document.getElementById("cfgVipRequired").value = state.appConfig.isVipRequired ? "true" : "false";
    }

    // 7. Fetch Home Sections
    const fbSections = await firebaseFetch("homeSections");
    if (fbSections && Array.isArray(fbSections)) {
      state.homeSections = fbSections;
    }

    updateSyncBadge("connected");
    refreshAllViews();

    if (showNotification) {
      showToast("Data synchronized with Firebase Cloud!", "success");
    }
  } catch (e) {
    updateSyncBadge("error");
    if (showNotification) {
      showToast("Firebase Sync Failed: Check network", "error");
    }
  }
}

function updateSyncBadge(status) {
  const badge = document.getElementById("syncBadge");
  const sidebarText = document.getElementById("sidebarStatusText");
  if (!badge) return;

  if (status === "syncing") {
    badge.innerHTML = `<i class="fa-solid fa-rotate fa-spin"></i> <span>Syncing...</span>`;
    badge.style.color = "var(--accent-yellow)";
    badge.style.borderColor = "rgba(255, 165, 2, 0.4)";
  } else if (status === "connected") {
    badge.innerHTML = `<i class="fa-solid fa-cloud-arrow-up"></i> <span>Firebase Synced</span>`;
    badge.style.color = "var(--accent-green)";
    badge.style.borderColor = "rgba(0, 255, 135, 0.25)";
    if (sidebarText) sidebarText.textContent = "Live";
  } else {
    badge.innerHTML = `<i class="fa-solid fa-triangle-exclamation"></i> <span>Offline Mode</span>`;
    badge.style.color = "var(--accent-red)";
    badge.style.borderColor = "rgba(255, 71, 87, 0.4)";
    if (sidebarText) sidebarText.textContent = "Offline";
  }
}

// ==========================================================================
// 3. GOOGLE DRIVE REST API V3 ENGINE
// ==========================================================================
function extractDriveFileId(inputUrl) {
  const clean = (inputUrl || "").trim();
  if (!clean) return null;

  const dMatch = clean.match(/\/d\/([a-zA-Z0-9_-]+)/);
  if (dMatch && dMatch[1]) return dMatch[1];

  const idMatch = clean.match(/[?&]id=([a-zA-Z0-9_-]+)/);
  if (idMatch && idMatch[1]) return idMatch[1];

  const filesMatch = clean.match(/\/files\/([a-zA-Z0-9_-]+)/);
  if (filesMatch && filesMatch[1]) return filesMatch[1];

  if (!clean.startsWith("http") && clean.length > 20) return clean;
  return null;
}

function extractDriveFolderId(inputUrl) {
  const clean = (inputUrl || "").trim();
  const folderMatch = clean.match(/\/folders\/([a-zA-Z0-9_-]+)/);
  if (folderMatch && folderMatch[1]) return folderMatch[1];
  if (!clean.startsWith("http") && clean.length > 15) return clean;
  return null;
}

function convertDriveLinkToDirectStream(inputUrl) {
  const clean = (inputUrl || "").trim();
  const fileId = extractDriveFileId(clean);
  if (fileId) {
    return `https://www.googleapis.com/drive/v3/files/${fileId}?alt=media&key=${CONFIG.DRIVE_API_KEY}`;
  }
  return clean;
}

function handleSingleDriveConversion() {
  const link = document.getElementById("singleDriveLink").value.trim();
  const directInput = document.getElementById("singleDirectUrl");
  if (link) {
    const directUrl = convertDriveLinkToDirectStream(link);
    directInput.value = directUrl;
  } else {
    directInput.value = "";
  }
}

function testPlayDirectUrl() {
  const url = document.getElementById("singleDirectUrl").value.trim();
  const title = document.getElementById("singleTrackTitle").value.trim() || "Test Stream";
  const artist = document.getElementById("singleTrackArtist").value.trim() || "Drive Engine";
  const cover = document.getElementById("singleTrackCover").value.trim() || CONFIG.DEFAULT_COVER;

  if (!url) {
    showToast("Paste a Google Drive URL first", "error");
    return;
  }

  audioController.play({
    title,
    artist,
    audioUrl: url,
    coverUrl: cover
  });
}

async function handleFetchDriveFolder() {
  const folderInput = document.getElementById("driveFolderUrl").value.trim();
  const cover = document.getElementById("driveFolderCover").value.trim() || CONFIG.DEFAULT_COVER;
  const artist = document.getElementById("driveFolderArtist").value.trim() || "Various Artists";
  const album = document.getElementById("driveFolderAlbum").value.trim() || "Exotic Collection";
  const genre = document.getElementById("driveFolderGenre").value.trim() || "Pop";

  const folderId = extractDriveFolderId(folderInput);
  if (!folderId) {
    showToast("Invalid Google Drive Folder URL or ID!", "error");
    return;
  }

  const btn = document.getElementById("btnFetchFolder");
  btn.innerHTML = `<i class="fa-solid fa-spinner fa-spin"></i> Fetching from Google Drive API...`;
  btn.disabled = true;

  try {
    const apiUrl = `https://www.googleapis.com/drive/v3/files?q='${folderId}'+in+parents+and+trashed=false&fields=files(id,name,mimeType,size)&key=${CONFIG.DRIVE_API_KEY}`;
    const res = await fetch(apiUrl);
    const data = await res.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    const files = data.files || [];
    if (files.length === 0) {
      showToast("No files found in this Google Drive folder!", "error");
      return;
    }

    const detected = [];
    files.forEach((f, idx) => {
      const cleanTitle = (f.name || `Track ${idx + 1}`).replace(/\.(mp3|wav|m4a|aac|flac)$/i, "");
      const streamUrl = `https://www.googleapis.com/drive/v3/files/${f.id}?alt=media&key=${CONFIG.DRIVE_API_KEY}`;

      detected.push({
        id: `drive_${Date.now()}_${idx + 1}`,
        title: cleanTitle,
        artist: artist,
        album: album,
        genre: genre,
        audioUrl: streamUrl,
        coverUrl: cover,
        durationSeconds: 210
      });
    });

    state.detectedFolderTracks = detected;
    renderDetectedTracksTable();
    showToast(`Detected ${detected.length} tracks from Google Drive!`, "success");
  } catch (err) {
    console.error("Drive Folder Fetch Error:", err);
    showToast(`Drive API Error: ${err.message}`, "error");
  } finally {
    btn.innerHTML = `<i class="fa-solid fa-cloud-arrow-down"></i> Auto-Fetch All Songs From Google Drive Folder`;
    btn.disabled = false;
  }
}

function renderDetectedTracksTable() {
  const panel = document.getElementById("driveImportResultsPanel");
  const tbody = document.getElementById("detectedTracksTableBody");
  const countEl = document.getElementById("detectedTracksCount");

  if (state.detectedFolderTracks.length === 0) {
    panel.style.display = "none";
    return;
  }

  panel.style.display = "block";
  countEl.textContent = state.detectedFolderTracks.length;

  tbody.innerHTML = state.detectedFolderTracks.map((track, i) => `
    <tr>
      <td><strong>${escapeHtml(track.title)}</strong></td>
      <td>${escapeHtml(track.artist)}</td>
      <td>${escapeHtml(track.album)}</td>
      <td><span class="badge badge-cyan">${escapeHtml(track.genre)}</span></td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="audioController.play(state.detectedFolderTracks[${i}])">
          <i class="fa-solid fa-play"></i> Play
        </button>
      </td>
      <td>
        <button class="btn btn-danger btn-sm" onclick="removeDetectedTrack(${i})">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </td>
    </tr>
  `).join("");
}

function removeDetectedTrack(index) {
  state.detectedFolderTracks.splice(index, 1);
  renderDetectedTracksTable();
}

function clearImportedTracksPreview() {
  state.detectedFolderTracks = [];
  renderDetectedTracksTable();
}

async function commitImportedTracksToFirebase() {
  if (state.detectedFolderTracks.length === 0) return;

  const count = state.detectedFolderTracks.length;
  state.songs.push(...state.detectedFolderTracks);
  state.detectedFolderTracks = [];
  renderDetectedTracksTable();
  renderSongsTable();
  updateStatsCounters();

  const success = await firebaseSave("songs", state.songs);
  if (success) {
    showToast(`Successfully published ${count} songs to Firebase!`, "success");
  } else {
    showToast("Failed to save to Firebase Cloud!", "error");
  }
}

async function handleAddSingleTrackToCatalog() {
  const url = document.getElementById("singleDirectUrl").value.trim();
  const title = document.getElementById("singleTrackTitle").value.trim();
  const artist = document.getElementById("singleTrackArtist").value.trim() || "Various Artists";
  const album = document.getElementById("singleTrackAlbum").value.trim() || "Exotic Single";
  const cover = document.getElementById("singleTrackCover").value.trim() || CONFIG.DEFAULT_COVER;
  const genre = document.getElementById("singleTrackGenre").value.trim() || "Pop";

  if (!title || !url) {
    showToast("Title and Audio URL are required!", "error");
    return;
  }

  const newSong = {
    id: `track_${Date.now()}`,
    title,
    artist,
    album,
    audioUrl: url,
    coverUrl: cover,
    genre,
    durationSeconds: 215
  };

  state.songs.unshift(newSong);
  renderSongsTable();
  updateStatsCounters();

  const success = await firebaseSave("songs", state.songs);
  if (success) {
    showToast(`Track "${title}" saved & synced to Firebase!`, "success");
    document.getElementById("singleDriveLink").value = "";
    document.getElementById("singleDirectUrl").value = "";
    document.getElementById("singleTrackTitle").value = "";
  } else {
    showToast("Failed to sync to Firebase", "error");
  }
}

// ==========================================================================
// 4. SONGS MASTER CATALOG CRUD
// ==========================================================================
function renderSongsTable() {
  const tbody = document.getElementById("songsTableBody");
  const search = (document.getElementById("searchSongsInput").value || "").toLowerCase();
  const genreFilter = document.getElementById("filterGenreSelect").value;

  // Populate genre filter options dynamically
  populateGenreFilterOptions();

  let filtered = state.songs.filter(s => {
    const matchSearch = (s.title || "").toLowerCase().includes(search) ||
                        (s.artist || "").toLowerCase().includes(search) ||
                        (s.album || "").toLowerCase().includes(search);
    const matchGenre = genreFilter === "ALL" || s.genre === genreFilter;
    return matchSearch && matchGenre;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 30px;">No tracks found matching your filter.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map((song) => `
    <tr>
      <td>
        <div class="table-media-cell">
          <img src="${song.coverUrl || CONFIG.DEFAULT_COVER}" class="table-thumb" alt="cover">
          <div>
            <div class="table-title">${escapeHtml(song.title)}</div>
            <div class="table-subtitle">${escapeHtml(song.artist)}</div>
          </div>
        </div>
      </td>
      <td>${escapeHtml(song.album || "Exotic Release")}</td>
      <td><span class="badge badge-green">${escapeHtml(song.genre || "Pop")}</span></td>
      <td>${formatDuration(song.durationSeconds || 210)}</td>
      <td>
        <button class="btn btn-secondary btn-icon-only" onclick="playSongById('${song.id}')">
          <i class="fa-solid fa-play"></i>
        </button>
      </td>
      <td>
        <div style="display: flex; gap: 8px;">
          <button class="btn btn-secondary btn-sm" onclick="openEditSongModal('${song.id}')">
            <i class="fa-solid fa-pen"></i>
          </button>
          <button class="btn btn-danger btn-sm" onclick="deleteSong('${song.id}')">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </td>
    </tr>
  `).join("");
}

function playSongById(id) {
  const song = state.songs.find(s => s.id === id);
  if (song) {
    audioController.play(song);
  }
}

function populateGenreFilterOptions() {
  const select = document.getElementById("filterGenreSelect");
  const genres = Array.from(new Set(state.songs.map(s => s.genre).filter(Boolean)));
  const current = select.value;

  select.innerHTML = `<option value="ALL">All Genres</option>` +
    genres.map(g => `<option value="${escapeHtml(g)}" ${g === current ? "selected" : ""}>${escapeHtml(g)}</option>`).join("");
}

function openAddSongModal() {
  document.getElementById("songModalTitle").textContent = "Add New Track";
  document.getElementById("modalSongId").value = "";
  document.getElementById("modalSongTitle").value = "";
  document.getElementById("modalSongArtist").value = "";
  document.getElementById("modalSongAlbum").value = "";
  document.getElementById("modalSongGenre").value = "Pop";
  document.getElementById("modalSongDuration").value = "210";
  document.getElementById("modalSongAudioUrl").value = "";
  document.getElementById("modalSongCoverUrl").value = "";
  openModal("songModal");
}

function openEditSongModal(id) {
  const song = state.songs.find(s => s.id === id);
  if (!song) return;

  document.getElementById("songModalTitle").textContent = "Edit Track";
  document.getElementById("modalSongId").value = song.id;
  document.getElementById("modalSongTitle").value = song.title || "";
  document.getElementById("modalSongArtist").value = song.artist || "";
  document.getElementById("modalSongAlbum").value = song.album || "";
  document.getElementById("modalSongGenre").value = song.genre || "Pop";
  document.getElementById("modalSongDuration").value = song.durationSeconds || "210";
  document.getElementById("modalSongAudioUrl").value = song.audioUrl || "";
  document.getElementById("modalSongCoverUrl").value = song.coverUrl || "";
  openModal("songModal");
}

async function handleSaveSong(e) {
  e.preventDefault();
  const id = document.getElementById("modalSongId").value;
  const title = document.getElementById("modalSongTitle").value.trim();
  const artist = document.getElementById("modalSongArtist").value.trim();
  const album = document.getElementById("modalSongAlbum").value.trim();
  const genre = document.getElementById("modalSongGenre").value.trim();
  const duration = parseInt(document.getElementById("modalSongDuration").value) || 210;
  let audioUrl = document.getElementById("modalSongAudioUrl").value.trim();
  const coverUrl = document.getElementById("modalSongCoverUrl").value.trim() || CONFIG.DEFAULT_COVER;

  audioUrl = convertDriveLinkToDirectStream(audioUrl);

  if (id) {
    // Update existing
    const idx = state.songs.findIndex(s => s.id === id);
    if (idx !== -1) {
      state.songs[idx] = { ...state.songs[idx], title, artist, album, genre, durationSeconds: duration, audioUrl, coverUrl };
    }
  } else {
    // Add new
    state.songs.unshift({
      id: `song_${Date.now()}`,
      title,
      artist,
      album,
      genre,
      durationSeconds: duration,
      audioUrl,
      coverUrl
    });
  }

  closeModal("songModal");
  renderSongsTable();
  updateStatsCounters();

  const success = await firebaseSave("songs", state.songs);
  if (success) {
    showToast(`Track "${title}" saved successfully!`, "success");
  } else {
    showToast("Error updating Firebase Realtime DB", "error");
  }
}

async function deleteSong(id) {
  const song = state.songs.find(s => s.id === id);
  if (!confirm(`Delete "${song ? song.title : 'this song'}"? This will sync immediately to Firebase.`)) return;

  state.songs = state.songs.filter(s => s.id !== id);
  renderSongsTable();
  updateStatsCounters();

  const success = await firebaseSave("songs", state.songs);
  if (success) {
    showToast("Song deleted from Firebase!", "success");
  }
}

// ==========================================================================
// 5. ARTISTS MANAGER CRUD
// ==========================================================================
function renderArtistsGrid() {
  const container = document.getElementById("artistsGrid");
  const search = (document.getElementById("searchArtistsInput").value || "").toLowerCase();

  const filtered = state.artists.filter(a =>
    (a.name || "").toLowerCase().includes(search) ||
    (a.genre || "").toLowerCase().includes(search) ||
    (a.language || "").toLowerCase().includes(search)
  );

  if (filtered.length === 0) {
    container.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 40px;">No artists registered yet. Click 'Add Artist' to register.</div>`;
    return;
  }

  container.innerHTML = filtered.map(artist => `
    <div class="artist-card">
      <img src="${artist.imageUrl || CONFIG.DEFAULT_ARTIST_IMG}" class="artist-avatar" alt="${escapeHtml(artist.name)}">
      <div class="artist-name">${escapeHtml(artist.name)}</div>
      <div class="artist-meta">${escapeHtml(artist.artistType || "Playback Singer")} • ${escapeHtml(artist.language || "Hindi")}</div>
      <div style="margin-bottom: 14px;">
        <span class="badge badge-purple">${formatListeners(artist.monthlyListeners)} Listeners</span>
      </div>
      <div style="display: flex; gap: 8px; justify-content: center;">
        <button class="btn btn-secondary btn-sm" onclick="openEditArtistModal('${artist.id}')">
          <i class="fa-solid fa-pen"></i> Edit
        </button>
        <button class="btn btn-danger btn-sm" onclick="deleteArtist('${artist.id}')">
          <i class="fa-solid fa-trash"></i>
        </button>
      </div>
    </div>
  `).join("");
}

function openAddArtistModal() {
  document.getElementById("artistModalTitle").textContent = "Add New Artist";
  document.getElementById("modalArtistId").value = "";
  document.getElementById("modalArtistName").value = "";
  document.getElementById("modalArtistLanguage").value = "Hindi";
  document.getElementById("modalArtistType").value = "Playback Singer";
  document.getElementById("modalArtistGenre").value = "Bollywood";
  document.getElementById("modalArtistListeners").value = "45000000";
  document.getElementById("modalArtistImage").value = "";
  document.getElementById("modalArtistBanner").value = "";
  document.getElementById("modalArtistBio").value = "";
  openModal("artistModal");
}

function openEditArtistModal(id) {
  const artist = state.artists.find(a => a.id === id);
  if (!artist) return;

  document.getElementById("artistModalTitle").textContent = "Edit Artist";
  document.getElementById("modalArtistId").value = artist.id;
  document.getElementById("modalArtistName").value = artist.name || "";
  document.getElementById("modalArtistLanguage").value = artist.language || "Hindi";
  document.getElementById("modalArtistType").value = artist.artistType || "Playback Singer";
  document.getElementById("modalArtistGenre").value = artist.genre || "Bollywood";
  document.getElementById("modalArtistListeners").value = artist.monthlyListeners || "1000000";
  document.getElementById("modalArtistImage").value = artist.imageUrl || "";
  document.getElementById("modalArtistBanner").value = artist.bannerUrl || "";
  document.getElementById("modalArtistBio").value = artist.bio || "";
  openModal("artistModal");
}

async function handleSaveArtist(e) {
  e.preventDefault();
  const id = document.getElementById("modalArtistId").value;
  const name = document.getElementById("modalArtistName").value.trim();
  const language = document.getElementById("modalArtistLanguage").value.trim();
  const artistType = document.getElementById("modalArtistType").value.trim();
  const genre = document.getElementById("modalArtistGenre").value.trim();
  const monthlyListeners = parseInt(document.getElementById("modalArtistListeners").value) || 1000000;
  const imageUrl = document.getElementById("modalArtistImage").value.trim() || CONFIG.DEFAULT_ARTIST_IMG;
  const bannerUrl = document.getElementById("modalArtistBanner").value.trim() || imageUrl;
  const bio = document.getElementById("modalArtistBio").value.trim();

  if (id) {
    const idx = state.artists.findIndex(a => a.id === id);
    if (idx !== -1) {
      state.artists[idx] = { ...state.artists[idx], name, language, artistType, genre, monthlyListeners, imageUrl, bannerUrl, bio };
    }
  } else {
    state.artists.push({
      id: `art_${Date.now()}`,
      name,
      language,
      artistType,
      genre,
      monthlyListeners,
      imageUrl,
      bannerUrl,
      bio
    });
  }

  closeModal("artistModal");
  renderArtistsGrid();
  updateStatsCounters();

  const success = await firebaseSave("artists", state.artists);
  if (success) {
    showToast(`Artist "${name}" saved to Firebase!`, "success");
  } else {
    showToast("Error saving artist to Firebase", "error");
  }
}

async function deleteArtist(id) {
  const artist = state.artists.find(a => a.id === id);
  if (!confirm(`Delete "${artist ? artist.name : 'this artist'}"?`)) return;

  state.artists = state.artists.filter(a => a.id !== id);
  renderArtistsGrid();
  updateStatsCounters();

  const success = await firebaseSave("artists", state.artists);
  if (success) {
    showToast("Artist deleted!", "success");
  }
}

// ==========================================================================
// 6. PLAYLISTS & PODCASTS
// ==========================================================================
function renderPlaylistsTable() {
  const tbody = document.getElementById("playlistsTableBody");
  if (state.playlists.length === 0) {
    tbody.innerHTML = `<tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 25px;">No playlists created yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = state.playlists.map(p => `
    <tr>
      <td>
        <div class="table-media-cell">
          <img src="${p.coverUrl || CONFIG.DEFAULT_COVER}" class="table-thumb" alt="cover">
          <div>
            <div class="table-title">${escapeHtml(p.title)}</div>
            <div class="table-subtitle">${escapeHtml(p.description || "")}</div>
          </div>
        </div>
      </td>
      <td><span class="badge badge-cyan">${escapeHtml(p.genreTag || "Curated")}</span></td>
      <td>${(p.songs || []).length} Tracks</td>
      <td>
        <button class="btn btn-danger btn-sm" onclick="deletePlaylist('${p.id}')">
          <i class="fa-solid fa-trash"></i>
        </button>
      </td>
    </tr>
  `).join("");
}

function openAddPlaylistModal() {
  document.getElementById("modalPlaylistId").value = "";
  document.getElementById("modalPlaylistTitle").value = "";
  document.getElementById("modalPlaylistGenreTag").value = "Bollywood";
  document.getElementById("modalPlaylistCover").value = "";
  document.getElementById("modalPlaylistDesc").value = "";
  openModal("playlistModal");
}

async function handleSavePlaylist(e) {
  e.preventDefault();
  const title = document.getElementById("modalPlaylistTitle").value.trim();
  const genreTag = document.getElementById("modalPlaylistGenreTag").value.trim();
  const coverUrl = document.getElementById("modalPlaylistCover").value.trim() || CONFIG.DEFAULT_COVER;
  const description = document.getElementById("modalPlaylistDesc").value.trim();

  state.playlists.push({
    id: `pl_${Date.now()}`,
    title,
    genreTag,
    coverUrl,
    description,
    songs: state.songs.slice(0, 5) // Assign top 5 by default
  });

  closeModal("playlistModal");
  renderPlaylistsTable();
  updateStatsCounters();

  const success = await firebaseSave("playlists", state.playlists);
  if (success) {
    showToast(`Playlist "${title}" saved to Firebase!`, "success");
  }
}

async function deletePlaylist(id) {
  if (!confirm("Delete this playlist?")) return;
  state.playlists = state.playlists.filter(p => p.id !== id);
  renderPlaylistsTable();
  updateStatsCounters();
  await firebaseSave("playlists", state.playlists);
  showToast("Playlist deleted", "success");
}

function renderPodcastsTable() {
  const tbody = document.getElementById("podcastsTableBody");
  if (state.podcasts.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 25px;">No podcasts registered yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = state.podcasts.map(pod => `
    <tr>
      <td>
        <div class="table-media-cell">
          <img src="${pod.coverUrl || CONFIG.DEFAULT_COVER}" class="table-thumb" alt="cover">
          <div class="table-title">${escapeHtml(pod.title)}</div>
        </div>
      </td>
      <td>${escapeHtml(pod.publisher || "Host")}</td>
      <td><span class="badge badge-purple">${escapeHtml(pod.category || "Talk")}</span></td>
      <td>${(pod.episodes || []).length} Episodes</td>
      <td>
        <button class="btn btn-danger btn-sm" onclick="deletePodcast('${pod.id}')">
          <i class="fa-solid fa-trash"></i>
        </button>
      </td>
    </tr>
  `).join("");
}

function openAddPodcastModal() {
  const title = prompt("Podcast Title:");
  if (!title) return;
  const publisher = prompt("Host / Publisher:", "Ranveer Allahbadia") || "Host";

  state.podcasts.push({
    id: `pod_${Date.now()}`,
    title,
    publisher,
    category: "Talk Show",
    coverUrl: CONFIG.DEFAULT_COVER,
    episodes: []
  });

  renderPodcastsTable();
  firebaseSave("podcasts", state.podcasts);
  showToast("Podcast added!", "success");
}

async function deletePodcast(id) {
  state.podcasts = state.podcasts.filter(p => p.id !== id);
  renderPodcastsTable();
  await firebaseSave("podcasts", state.podcasts);
  showToast("Podcast deleted", "success");
}

// ==========================================================================
// 7. HOME CONFIGURATOR (BANNERS & SECTIONS)
// ==========================================================================
function renderBannersGrid() {
  const container = document.getElementById("bannersGrid");
  if (state.heroBanners.length === 0) {
    container.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 30px;">No hero banners configured.</div>`;
    return;
  }

  container.innerHTML = state.heroBanners.map((banner, i) => `
    <div class="banner-card">
      <img src="${banner.imageUrl || CONFIG.DEFAULT_COVER}" alt="${escapeHtml(banner.title)}">
      <div class="banner-card-body">
        <h4 style="font-size: 15px; margin-bottom: 4px;">${escapeHtml(banner.title)}</h4>
        <p style="font-size: 12px; color: var(--text-muted); margin-bottom: 12px;">${escapeHtml(banner.subtitle || "")}</p>
        <button class="btn btn-danger btn-sm" onclick="deleteBanner(${i})">
          <i class="fa-solid fa-trash"></i> Remove Banner
        </button>
      </div>
    </div>
  `).join("");
}

function openAddBannerModal() {
  document.getElementById("modalBannerTitle").value = "";
  document.getElementById("modalBannerSubtitle").value = "";
  document.getElementById("modalBannerImage").value = "";
  openModal("bannerModal");
}

async function handleSaveBanner(e) {
  e.preventDefault();
  const title = document.getElementById("modalBannerTitle").value.trim();
  const subtitle = document.getElementById("modalBannerSubtitle").value.trim();
  const imageUrl = document.getElementById("modalBannerImage").value.trim();

  state.heroBanners.push({ title, subtitle, imageUrl });
  closeModal("bannerModal");
  renderBannersGrid();

  const success = await firebaseSave("heroBanners", state.heroBanners);
  if (success) {
    showToast("Hero Banner published to app!", "success");
  }
}

async function deleteBanner(index) {
  state.heroBanners.splice(index, 1);
  renderBannersGrid();
  await firebaseSave("heroBanners", state.heroBanners);
  showToast("Banner removed", "success");
}

function renderHomeSections() {
  const container = document.getElementById("sectionsListContainer");
  container.innerHTML = state.homeSections.map((sec, i) => `
    <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: rgba(255,255,255,0.03); border: 1px solid var(--border-glass); border-radius: var(--radius-sm);">
      <div style="display: flex; align-items: center; gap: 10px;">
        <span style="color: var(--accent-green); font-weight: 800; font-size: 12px;">#${i + 1}</span>
        <span style="font-size: 13px; font-weight: 600;">${escapeHtml(sec)}</span>
      </div>
      <div style="display: flex; gap: 6px;">
        ${i > 0 ? `<button class="btn btn-secondary btn-sm" onclick="moveSection(${i}, -1)"><i class="fa-solid fa-arrow-up"></i></button>` : ''}
        ${i < state.homeSections.length - 1 ? `<button class="btn btn-secondary btn-sm" onclick="moveSection(${i}, 1)"><i class="fa-solid fa-arrow-down"></i></button>` : ''}
        <button class="btn btn-danger btn-sm" onclick="deleteSection(${i})"><i class="fa-solid fa-xmark"></i></button>
      </div>
    </div>
  `).join("");
}

function moveSection(index, delta) {
  const target = index + delta;
  if (target < 0 || target >= state.homeSections.length) return;
  const temp = state.homeSections[index];
  state.homeSections[index] = state.homeSections[target];
  state.homeSections[target] = temp;
  renderHomeSections();
}

function deleteSection(index) {
  state.homeSections.splice(index, 1);
  renderHomeSections();
}

function handleAddSectionTitle() {
  const input = document.getElementById("newSectionTitleInput");
  const val = input.value.trim();
  if (!val) return;
  state.homeSections.push(val);
  input.value = "";
  renderHomeSections();
}

async function saveHomeSectionsOrder() {
  const success = await firebaseSave("homeSections", state.homeSections);
  if (success) {
    showToast("Home Sections layout saved to Firebase!", "success");
  } else {
    showToast("Error saving sections layout", "error");
  }
}

// ==========================================================================
// 8. MASTER SETTINGS & CONTROLS
// ==========================================================================
async function saveAppGlobalSettings() {
  state.appConfig.appName = document.getElementById("cfgAppName").value.trim() || "EXOTIC MUSIC";
  state.appConfig.isMaintenanceMode = document.getElementById("cfgMaintenance").value === "true";
  state.appConfig.isVipRequired = document.getElementById("cfgVipRequired").value === "true";

  const success = await firebaseSave("appConfig", state.appConfig);
  if (success) {
    showToast("Global App Master Controls Saved!", "success");
  } else {
    showToast("Failed to save global app config", "error");
  }
}

async function broadcastAnnouncement() {
  const msg = document.getElementById("cfgAnnouncement").value.trim();
  state.appConfig.announcementMessage = msg;

  const success = await firebaseSave("announcement", msg);
  if (success) {
    showToast("Announcement broadcasted to all active app users!", "success");
  } else {
    showToast("Failed to broadcast announcement", "error");
  }
}

function saveDatabaseConfig() {
  CONFIG.FIREBASE_DB_URL = document.getElementById("cfgDbUrl").value.trim();
  CONFIG.DRIVE_API_KEY = document.getElementById("cfgDriveApiKey").value.trim();
  document.getElementById("dbUrlDisplay").textContent = CONFIG.FIREBASE_DB_URL;
  showToast("Database endpoints saved locally!", "success");
}

async function testFirebaseConnection() {
  showToast("Testing Firebase Realtime Database ping...", "success");
  const test = await firebaseFetch("announcement");
  if (test !== null) {
    showToast("Firebase Connection: ONLINE 200 OK!", "success");
  } else {
    showToast("Firebase Connection Failed!", "error");
  }
}

function exportDatabaseBackup() {
  const dump = {
    exportDate: new Date().toISOString(),
    songs: state.songs,
    artists: state.artists,
    playlists: state.playlists,
    heroBanners: state.heroBanners,
    homeSections: state.homeSections,
    appConfig: state.appConfig
  };

  const blob = new Blob([JSON.stringify(dump, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `exotic_music_db_backup_${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(url);
  showToast("Database backup downloaded!", "success");
}

// ==========================================================================
// 9. UI HELPERS, MODALS & TABS
// ==========================================================================
function setupNavigation() {
  const navItems = document.querySelectorAll(".nav-item");
  navItems.forEach(item => {
    item.addEventListener("click", () => {
      const targetTab = item.getAttribute("data-tab");
      switchTab(targetTab);

      // Close mobile sidebar if open
      document.getElementById("sidebar").classList.remove("mobile-open");
    });
  });
}

function switchTab(tabId) {
  state.activeTab = tabId;

  // Nav item active class
  document.querySelectorAll(".nav-item").forEach(item => {
    if (item.getAttribute("data-tab") === tabId) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });

  // Panes active class
  document.querySelectorAll(".tab-pane").forEach(pane => {
    pane.classList.remove("active");
  });
  const targetPane = document.getElementById(`tab-${tabId}`);
  if (targetPane) targetPane.classList.add("active");

  // Page title update
  const titleMap = {
    "dashboard": "Dashboard & Analytics",
    "drive-engine": "Google Drive Music Engine & Uploader",
    "songs": "Songs Master Catalog",
    "artists": "Registered Artists Directory",
    "playlists": "Curated Playlists & Podcasts",
    "home-config": "App Home Screen Configurator",
    "settings": "Settings & Database Configuration"
  };
  document.getElementById("pageTitle").textContent = titleMap[tabId] || "Admin Control Center";
}

function toggleMobileSidebar() {
  document.getElementById("sidebar").classList.toggle("mobile-open");
}

function openModal(modalId) {
  document.getElementById(modalId).classList.add("active");
}

function closeModal(modalId) {
  document.getElementById(modalId).classList.remove("active");
}

function updateStatsCounters() {
  document.getElementById("statTotalSongs").textContent = state.songs.length;
  document.getElementById("statTotalArtists").textContent = state.artists.length;
  document.getElementById("statTotalPlaylists").textContent = state.playlists.length;
}

function refreshAllViews() {
  updateStatsCounters();
  renderSongsTable();
  renderArtistsGrid();
  renderPlaylistsTable();
  renderPodcastsTable();
  renderBannersGrid();
  renderHomeSections();
}

function showToast(message, type = "success") {
  const container = document.getElementById("toastContainer");
  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <i class="${type === 'success' ? 'fa-solid fa-circle-check' : 'fa-solid fa-triangle-exclamation'}"></i>
    <span>${escapeHtml(message)}</span>
  `;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateX(100%)";
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

function formatDuration(seconds) {
  const sec = Math.floor(seconds || 0);
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${s < 10 ? "0" : ""}${s}`;
}

function formatListeners(num) {
  const n = parseInt(num) || 0;
  if (n >= 1000000) return (n / 1000000).toFixed(1) + "M";
  if (n >= 1000) return (n / 1000).toFixed(1) + "K";
  return n.toString();
}

function escapeHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function togglePlayPause() {
  audioController.toggle();
}

function handleScrub(e) {
  if (!audioController.element || !audioController.element.duration) return;
  const pct = e.target.value / 100;
  audioController.element.currentTime = pct * audioController.element.duration;
}

function handleVolume(e) {
  if (!audioController.element) return;
  audioController.element.volume = parseFloat(e.target.value);
}

// ==========================================================================
// 10. INITIALIZATION
// ==========================================================================
function initAdminPanel() {
  setupNavigation();
  audioController.init();
  syncAllWithFirebase(false);
}

window.addEventListener("DOMContentLoaded", () => {
  checkAuth();
});
