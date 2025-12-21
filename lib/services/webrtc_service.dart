import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:mgi/services/storage_service.dart';
import 'package:mgi/utils/constants.dart';
import 'websocket_service.dart';

const String _tag = '[WebRTC]';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  MediaStream? get localStream => _localStream;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();
  final _videoUpgradeRequestController = StreamController<bool>.broadcast();
  final _videoUpgradeResponseController = StreamController<bool>.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<CallState> get callState => _callStateController.stream;
  Stream<bool> get videoUpgradeRequest => _videoUpgradeRequestController.stream;
  Stream<bool> get videoUpgradeResponse => _videoUpgradeResponseController.stream;

  bool _polite = false;
  Timer? _connectionTimeoutTimer;

  Map<String, dynamic>? _configuration;
  bool _isVideoEnabled = false;

  final Map<String, dynamic> _audioOnlyConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': false,
  };

  final Map<String, dynamic> _videoConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': {
      'facingMode': 'user',
      'width': 1280,
      'height': 720,
      'frameRate': 30,
    },
  };

  final Map<String, dynamic> _offerAnswerConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  WebSocketService? _webSocketService;
  String? _currentCallId;
  String? _remoteUserId;
  bool _isInitialized = false;
  bool _makingOffer = false;
  bool _ignoreOffer = false;
  bool _isSettingRemoteAnswerPending = false;

  // États de négociation
  bool _localStreamReady = false;
  bool _peerConnectionCreated = false;
  bool _remoteDescriptionSet = false;

  // Queues
  final List<Map<String, dynamic>> _pendingIceCandidates = [];
  final List<Map<String, dynamic>> _pendingOutgoingIce = [];
  Timer? _iceBatchTimer;

  // Warmup cache
  Map<String, dynamic>? _cachedTurnConfig;
  DateTime? _turnConfigCacheTime;

  /// ========================
  /// INITIALISATION
  /// ========================
  Future<void> initialize(WebSocketService webSocketService) async {
    if (_isInitialized) {
      print('$_tag Déjà initialisé');
      return;
    }

    _webSocketService = webSocketService;
    _webSocketService!.onCallSignalReceived = _handleIncomingSignal;
    _webSocketService!.ensureCallSignalsSubscription();
    _isInitialized = true;

    print('$_tag ✓ WebRTCService initialisé');

    // Warmup: Pré-charger les credentials TURN
    _warmupTurnConnection();
  }

  /// Pré-charge les credentials TURN pour éviter le cold start
  Future<void> _warmupTurnConnection() async {
    try {
      print('$_tag Warmup TURN...');
      await _getTurnConfiguration();
      print('$_tag ✓ Warmup TURN terminé');
    } catch (e) {
      print('$_tag Warmup TURN échoué: $e');
    }
  }

  /// ========================
  /// TURN / STUN CONFIG
  /// ========================
  Future<Map<String, dynamic>> _getTurnConfiguration() async {
    // Vérifier le cache (TTL: 5 minutes)
    if (_cachedTurnConfig != null && _turnConfigCacheTime != null) {
      final age = DateTime.now().difference(_turnConfigCacheTime!);
      if (age.inSeconds < 300) {
        print('$_tag ✓ TURN depuis cache (${300 - age.inSeconds}s restant)');
        return _cachedTurnConfig!;
      }
    }

    print('$_tag Chargement TURN/STUN...');
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        final response = await http
            .get(
          Uri.parse('${Constants.baseUrl}/webrtc/turn-credentials'),
          headers: {'Authorization': 'Bearer $token'},
        )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> uris = data['uris'] ?? [];
          print('$_tag ✓ TURN chargé (${uris.length} URIs, TTL: ${data['ttl']}s)');
          print('$_tag Username: ${data['username']}');
          print('$_tag URIs: $uris');

          final config = {
            'iceServers': [
              // Serveurs STUN publics (rapides, toujours disponibles)
              {'urls': 'stun:stun.l.google.com:19302'},
              {'urls': 'stun:stun1.l.google.com:19302'},
              // Serveur TURN avec credentials
              if (uris.isNotEmpty)
                {
                  'urls': uris,
                  'username': data['username'],
                  'credential': data['password'],
                },
            ],
          };

          // Mettre en cache
          _cachedTurnConfig = config;
          _turnConfigCacheTime = DateTime.now();

          return config;
        }
      }
    } catch (e) {
      print('$_tag Erreur TURN: $e');
    }

    // Fallback: STUN uniquement
    print('$_tag ⚠ Utilisation STUN uniquement (fallback)');
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun1.l.google.com:19302'},
      ],
    };
  }

  Future<void> _ensureMediaPermissions() async {
    print('$_tag Vérification permissions...');

    try {
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        print('$_tag Demande permission microphone...');
        micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          throw Exception('Permission microphone refusée');
        }
      }

      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        print('$_tag Demande permission caméra...');
        cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          throw Exception('Permission caméra refusée');
        }
      }

      // Attendre un peu pour s'assurer que les permissions sont vraiment prêtes
      await Future.delayed(const Duration(milliseconds: 300));

      print('$_tag ✓ Permissions accordées');
    } catch (e) {
      print('$_tag ✗ Erreur permissions: $e');
      rethrow;
    }
  }

  /// ========================
  /// TIMEOUT MANAGEMENT
  /// ========================
  void _startConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    print('$_tag Timeout démarré (45s)');
    _connectionTimeoutTimer = Timer(const Duration(seconds: 45), () async {
      final connState = _peerConnection?.connectionState;
      final iceState = _peerConnection?.iceConnectionState;
      print('$_tag ⏰ TIMEOUT! ConnState=$connState, IceState=$iceState');

      if (connState != RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print('$_tag ✗ Échec de connexion après timeout');
        _callStateController.add(CallState.error);
        await _cleanup();
      }
    });
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  /// ========================
  /// START CALL (Appelant)
  /// ========================
  Future<void> startCall(String channelId, String remoteUserId) async {
    print('$_tag ========================================');
    print('$_tag    DÉMARRAGE APPEL (APPELANT)');
    print('$_tag    Channel: $channelId');
    print('$_tag    Remote: $remoteUserId');
    print('$_tag ========================================');

    await _cleanup();

    _remoteUserId = remoteUserId;
    _currentCallId = channelId;
    _polite = false;

    _resetNegotiationState();
    _callStateController.add(CallState.calling);

    try {
      // 1. Permissions
      await _ensureMediaPermissions();

      // 2. Configuration
      final iceConfig = await _getTurnConfiguration();
      _configuration = {
        ...iceConfig,
        'iceTransportPolicy': 'all',
        'sdpSemantics': 'unified-plan',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'iceCandidatePoolSize': 10,
      };

      // 3. Get local stream (audio only by default)
      print('$_tag Acquisition du localStream (audio uniquement)...');
      _isVideoEnabled = false;
      _localStream = await navigator.mediaDevices.getUserMedia(_audioOnlyConstraints);
      _localStreamReady = true;
      print('$_tag ✓ LocalStream obtenu: ${_localStream!.getTracks().length} tracks');

      // 4. Create peer connection
      await _setupPeerConnection(_localStream);

      // 5. Attendre que la peer connection soit stable
      await Future.delayed(const Duration(milliseconds: 500));

      // 6. Start timeout
      _startConnectionTimeout();

      // 7. Create initial offer
      print('$_tag Création de l\'offre initiale...');
      await _makeOffer();

      print('$_tag ✓ Appel démarré, en attente de réponse...');

    } catch (e) {
      print('$_tag ✗ Erreur startCall: $e');
      _callStateController.add(CallState.error);
      await _cleanup();
    }
  }

  /// ========================
  /// ANSWER CALL (Appelé)
  /// ========================
  Future<void> answerCall(String channelId, String remoteUserId) async {
    print('$_tag ========================================');
    print('$_tag    RÉPONSE À L\'APPEL (APPELÉ)');
    print('$_tag    Channel: $channelId');
    print('$_tag    Remote: $remoteUserId');
    print('$_tag ========================================');

    await _cleanup();

    _remoteUserId = remoteUserId;
    _currentCallId = channelId;
    _polite = true;

    _resetNegotiationState();
    _callStateController.add(CallState.ringing);

    try {
      // 1. Permissions
      await _ensureMediaPermissions();

      // 2. Configuration
      final iceConfig = await _getTurnConfiguration();
      _configuration = {
        ...iceConfig,
        'iceTransportPolicy': 'all',
        'sdpSemantics': 'unified-plan',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'iceCandidatePoolSize': 10,
      };

      // 3. Get local stream (audio only by default)
      print('$_tag Acquisition du localStream (audio uniquement)...');
      _isVideoEnabled = false;
      _localStream = await navigator.mediaDevices.getUserMedia(_audioOnlyConstraints);
      _localStreamReady = true;
      print('$_tag ✓ LocalStream obtenu: ${_localStream!.getTracks().length} tracks');

      // 4. Create peer connection
      await _setupPeerConnection(_localStream);

      // 5. Start timeout
      _startConnectionTimeout();

      print('$_tag ✓ Prêt à recevoir l\'offre...');

    } catch (e) {
      print('$_tag ✗ Erreur answerCall: $e');
      _callStateController.add(CallState.error);
      await _cleanup();
    }
  }

  /// ========================
  /// SETUP PEER CONNECTION
  /// ========================
  bool _hasRelayCandidates = false;
  bool _hasAnyCandidates = false;

  Future<void> _setupPeerConnection(MediaStream? stream) async {
    if (_configuration == null) {
      throw Exception('Configuration manquante');
    }

    print('$_tag Création PeerConnection...');
    print('$_tag Config ICE: ${_configuration!['iceServers']}');

    _peerConnection = await createPeerConnection(_configuration!);
    _peerConnectionCreated = true;
    _hasRelayCandidates = false;
    _hasAnyCandidates = false;

    // Add tracks
    if (stream != null) {
      for (var track in stream.getTracks()) {
        print('$_tag Ajout track: ${track.kind}');
        await _peerConnection!.addTrack(track, stream);
      }
    }

    // === CALLBACKS ===

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null && candidate.candidate != null) {
        _hasAnyCandidates = true;
        final type = candidate.candidate!.contains('relay') ? 'RELAY' :
        candidate.candidate!.contains('srflx') ? 'SRFLX' : 'HOST';

        if (type == 'RELAY') {
          _hasRelayCandidates = true;
          print('$_tag 🎯 ICE [$type] collecté - TURN fonctionne!');
        } else {
          print('$_tag ICE [$type] collecté');
        }

        _pendingOutgoingIce.add(candidate.toMap());
        _scheduleBatchIceSend();
      }
    };

    _peerConnection!.onIceGatheringState = (state) {
      print('$_tag ICE Gathering: $state');
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        if (_hasRelayCandidates) {
          print('$_tag ✓✓✓ ICE Gathering terminé avec RELAY ✓✓✓');
        } else if (_hasAnyCandidates) {
          print('$_tag ⚠ ICE Gathering terminé SANS RELAY (STUN/HOST uniquement)');
        } else {
          print('$_tag ✗ ICE Gathering terminé SANS CANDIDATS!');
        }
        _flushPendingIce();
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      print('$_tag ICE Connection: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print('$_tag ✓✓✓ ICE CONNECTÉ ✓✓✓');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('$_tag ✗✗✗ ICE ÉCHEC ✗✗✗');
      }
    };

    _peerConnection!.onConnectionState = (state) {
      print('$_tag Connection State: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _cancelConnectionTimeout();
        _callStateController.add(CallState.connected);
        print('$_tag ✓✓✓ APPEL CONNECTÉ ✓✓✓');
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        print('$_tag ✗✗✗ CONNEXION ÉCHOUÉE ✗✗✗');
        _callStateController.add(CallState.error);
      }
    };

    _peerConnection!.onTrack = (event) {
      print('$_tag 🎥 onTrack: ${event.streams.length} streams');
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams[0];
        print('$_tag ✓ Stream distant reçu: ${remoteStream.getTracks().length} tracks');
        _remoteStreamController.add(remoteStream);
      }
    };

    _peerConnection!.onSignalingState = (state) {
      print('$_tag Signaling State: $state');
    };

    print('$_tag ✓ PeerConnection configuré');
  }

  void _scheduleBatchIceSend() {
    _iceBatchTimer?.cancel();
    _iceBatchTimer = Timer(const Duration(milliseconds: 200), () {
      if (_pendingOutgoingIce.isNotEmpty) {
        print('$_tag Envoi batch de ${_pendingOutgoingIce.length} ICE candidates');
        for (var candidate in List.from(_pendingOutgoingIce)) {
          _sendSignal('ice-candidate', {'candidate': candidate});
        }
        _pendingOutgoingIce.clear();
      }
    });
  }

  // Envoyer immédiatement tous les ICE candidates en attente
  void _flushPendingIce() {
    _iceBatchTimer?.cancel();
    if (_pendingOutgoingIce.isNotEmpty) {
      print('$_tag Flush immédiat de ${_pendingOutgoingIce.length} ICE candidates');
      for (var candidate in List.from(_pendingOutgoingIce)) {
        _sendSignal('ice-candidate', {'candidate': candidate});
      }
      _pendingOutgoingIce.clear();
    }
  }

  /// ========================
  /// PERFECT NEGOTIATION
  /// ========================
  Future<void> _makeOffer() async {
    if (_peerConnection == null) {
      print('$_tag ✗ makeOffer: PC null');
      return;
    }

    try {
      print('$_tag Création offre...');
      _makingOffer = true;

      final offer = await _peerConnection!.createOffer(_offerAnswerConstraints);

      if (_peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateStable) {
        print('$_tag ⚠ Signaling state non-stable, attente...');
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await _peerConnection!.setLocalDescription(offer);
      print('$_tag ✓ LocalDescription (offer) définie');

      // Attendre la collecte des ICE candidates (plus long pour TURN)
      print('$_tag Attente collecte ICE candidates...');
      await _waitForIceCandidates();

      // Envoyer l'offre
      _sendSignal('offer', {'sdp': offer.toMap()});
      print('$_tag ✓ Offre envoyée');

      // Flush les ICE candidates en attente
      _flushPendingIce();

    } catch (e) {
      print('$_tag ✗ Erreur makeOffer: $e');
    } finally {
      _makingOffer = false;
    }
  }

  /// Attend que des ICE candidates soient collectés (avec timeout)
  Future<void> _waitForIceCandidates() async {
    final startTime = DateTime.now();
    final maxWait = const Duration(seconds: 5);

    while (DateTime.now().difference(startTime) < maxWait) {
      // Si on a des relay candidates, c'est parfait
      if (_hasRelayCandidates) {
        print('$_tag ✓ RELAY candidates collectés (${DateTime.now().difference(startTime).inMilliseconds}ms)');
        return;
      }

      // Si on a au moins des candidates après 2s, on continue
      if (_hasAnyCandidates && DateTime.now().difference(startTime).inSeconds >= 2) {
        print('$_tag ✓ ICE candidates collectés sans RELAY (${DateTime.now().difference(startTime).inMilliseconds}ms)');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!_hasAnyCandidates) {
      print('$_tag ⚠ Aucun ICE candidate collecté après ${maxWait.inSeconds}s');
    }
  }

  /// ========================
  /// SIGNAL HANDLING
  /// ========================
  void _handleIncomingSignal(Map<String, dynamic> signal) async {
    final type = signal['type'] as String;
    final data = (signal['data'] ?? {}) as Map<String, dynamic>;

    print('$_tag <<< Signal reçu: $type');

    if (!_peerConnectionCreated && type != 'end-call') {
      print('$_tag ⚠ PC pas encore créé, signal ignoré');
      return;
    }

    try {
      switch (type) {
        case 'offer':
          await _handleOffer(data);
          break;
        case 'answer':
          await _handleAnswer(data);
          break;
        case 'ice-candidate':
          await _handleIceCandidate(data);
          break;
        case 'video-upgrade-request':
          _videoUpgradeRequestController.add(true);
          break;
        case 'video-upgrade-accepted':
          _videoUpgradeResponseController.add(true);
          if (!_isVideoEnabled) {
            await acceptVideoUpgrade();
          }
          break;
        case 'video-upgrade-rejected':
          _videoUpgradeResponseController.add(false);
          break;
        case 'end-call':
          await _handleRemoteEndCall();
          break;
        default:
          print('$_tag Signal inconnu: $type');
      }
    } catch (e) {
      print('$_tag ✗ Erreur traitement signal $type: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;

    print('$_tag Traitement offre...');

    final sdpMap = data['sdp'] is Map ? data['sdp'] as Map<String, dynamic> : data['sdp'];
    final offerSdp = RTCSessionDescription(sdpMap['sdp'], sdpMap['type']);

    // Perfect Negotiation Pattern
    final offerCollision = _makingOffer ||
        _peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateStable;

    _ignoreOffer = !_polite && offerCollision;

    if (_ignoreOffer) {
      print('$_tag ⚠ Offre ignorée (collision, impolite)');
      return;
    }

    try {
      print('$_tag Définition remoteDescription (offer)...');
      await _peerConnection!.setRemoteDescription(offerSdp);
      _remoteDescriptionSet = true;
      print('$_tag ✓ RemoteDescription définie');

      // Process pending ICE candidates
      if (_pendingIceCandidates.isNotEmpty) {
        print('$_tag Traitement de ${_pendingIceCandidates.length} ICE en attente');
        for (var c in List.from(_pendingIceCandidates)) {
          await _addIceCandidate(c);
        }
        _pendingIceCandidates.clear();
      }

      // Create answer
      print('$_tag Création answer...');
      final answer = await _peerConnection!.createAnswer(_offerAnswerConstraints);
      await _peerConnection!.setLocalDescription(answer);
      print('$_tag ✓ LocalDescription (answer) définie');

      _sendSignal('answer', {'sdp': answer.toMap()});
      print('$_tag ✓ Answer envoyée');

    } catch (e) {
      print('$_tag ✗ Erreur handleOffer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;

    print('$_tag Traitement answer...');

    final sdpMap = data['sdp'] is Map ? data['sdp'] as Map<String, dynamic> : data['sdp'];
    final answerSdp = RTCSessionDescription(sdpMap['sdp'], sdpMap['type']);

    try {
      if (_isSettingRemoteAnswerPending) {
        print('$_tag ⚠ Answer déjà en cours de traitement');
        return;
      }

      _isSettingRemoteAnswerPending = true;

      print('$_tag Définition remoteDescription (answer)...');
      await _peerConnection!.setRemoteDescription(answerSdp);
      _remoteDescriptionSet = true;
      print('$_tag ✓ RemoteDescription (answer) définie');

      // Process pending ICE candidates
      if (_pendingIceCandidates.isNotEmpty) {
        print('$_tag Traitement de ${_pendingIceCandidates.length} ICE en attente');
        for (var c in List.from(_pendingIceCandidates)) {
          await _addIceCandidate(c);
        }
        _pendingIceCandidates.clear();
      }

    } catch (e) {
      print('$_tag ✗ Erreur handleAnswer: $e');
    } finally {
      _isSettingRemoteAnswerPending = false;
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final candidateData = data['candidate'] is Map
        ? data['candidate'] as Map<String, dynamic>
        : data;

    if (!_remoteDescriptionSet) {
      print('$_tag ICE reçu mais remoteDesc pas encore définie, mise en queue');
      _pendingIceCandidates.add(candidateData);
      return;
    }

    await _addIceCandidate(candidateData);
  }

  Future<void> _addIceCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;

    try {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );

      await _peerConnection!.addCandidate(candidate);
      print('$_tag ✓ ICE candidate ajouté');
    } catch (e) {
      print('$_tag ✗ Erreur ajout ICE: $e');
    }
  }

  /// ========================
  /// MEDIA CONTROLS
  /// ========================
  Future<void> toggleMute() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getAudioTracks();
    if (tracks.isEmpty) return;

    final enabled = !tracks.first.enabled;
    for (var t in tracks) {
      t.enabled = enabled;
    }
    print('$_tag ${enabled ? '🎤 Micro ON' : '🔇 Micro OFF'}');
  }

  bool get isMuted {
    if (_localStream == null) return true;
    final tracks = _localStream!.getAudioTracks();
    return tracks.isEmpty || !tracks.first.enabled;
  }

  bool get isVideoEnabled => _isVideoEnabled;

  /// Demander à l'autre utilisateur d'activer sa caméra
  Future<void> requestVideoUpgrade() async {
    print('$_tag Demande de bascule vidéo...');
    _sendSignal('video-upgrade-request', {});
  }

  /// Accepter la demande de bascule vidéo
  Future<void> acceptVideoUpgrade() async {
    try {
      print('$_tag Acceptation de la bascule vidéo...');

      if (_peerConnection == null) {
        print('$_tag ✗ PeerConnection null');
        return;
      }

      // Obtenir un nouveau stream avec audio + vidéo
      final newStream = await navigator.mediaDevices.getUserMedia(_videoConstraints);
      print('$_tag ✓ Nouveau stream obtenu avec ${newStream.getTracks().length} tracks');

      // Récupérer les senders actuels
      final senders = await _peerConnection!.getSenders();

      // Remplacer les tracks dans la peer connection
      for (var sender in senders) {
        if (sender.track != null) {
          final kind = sender.track!.kind;
          print('$_tag Remplacement track $kind...');

          if (kind == 'audio') {
            // Remplacer l'audio par le nouvel audio du stream vidéo
            final newAudioTrack = newStream.getAudioTracks().firstOrNull;
            if (newAudioTrack != null) {
              await sender.replaceTrack(newAudioTrack);
              print('$_tag ✓ Audio track remplacé');
            }
          } else if (kind == 'video') {
            // Remplacer ou ajouter la vidéo
            final newVideoTrack = newStream.getVideoTracks().firstOrNull;
            if (newVideoTrack != null) {
              await sender.replaceTrack(newVideoTrack);
              print('$_tag ✓ Video track remplacé');
            }
          }
        }
      }

      // Si aucun sender vidéo n'existe, l'ajouter
      final hasVideoSender = senders.any((s) => s.track?.kind == 'video');
      if (!hasVideoSender) {
        final videoTrack = newStream.getVideoTracks().firstOrNull;
        if (videoTrack != null) {
          await _peerConnection!.addTrack(videoTrack, newStream);
          print('$_tag ✓ Video track ajouté');
        }
      }

      // Arrêter l'ancien stream
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
      }

      // Utiliser le nouveau stream
      _localStream = newStream;
      _isVideoEnabled = true;

      print('$_tag ✓ Vidéo activée avec nouveau stream complet');

      // Envoyer la confirmation
      _sendSignal('video-upgrade-accepted', {});

      // Renégocier
      await _makeOffer();

    } catch (e) {
      print('$_tag ✗ Erreur activation vidéo: $e');
      _sendSignal('video-upgrade-rejected', {});
    }
  }

  /// Rejeter la demande de bascule vidéo
  Future<void> rejectVideoUpgrade() async {
    print('$_tag Rejet de la bascule vidéo');
    _sendSignal('video-upgrade-rejected', {});
  }

  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getVideoTracks();
    if (tracks.isEmpty) return;

    final enabled = !tracks.first.enabled;
    for (var t in tracks) {
      t.enabled = enabled;
    }
    print('$_tag ${enabled ? '📹 Caméra ON' : '📷 Caméra OFF'}');
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getVideoTracks();
    if (tracks.isEmpty) return;

    await Helper.switchCamera(tracks.first);
    print('$_tag 🔄 Caméra basculée');
  }

  /// ========================
  /// END CALL
  /// ========================
  Future<void> endCall() async {
    print('$_tag Fin d\'appel locale');
    _sendSignal('end-call', {});
    _cancelConnectionTimeout();
    await _cleanup();
    _callStateController.add(CallState.ended);
  }

  Future<void> _handleRemoteEndCall() async {
    print('$_tag Fin d\'appel distante');
    _cancelConnectionTimeout();
    await _cleanup();
    _callStateController.add(CallState.ended);
  }

  /// ========================
  /// CLEANUP
  /// ========================
  void _resetNegotiationState() {
    _localStreamReady = false;
    _peerConnectionCreated = false;
    _remoteDescriptionSet = false;
    _makingOffer = false;
    _ignoreOffer = false;
    _isSettingRemoteAnswerPending = false;
    _pendingIceCandidates.clear();
    _pendingOutgoingIce.clear();
    _hasRelayCandidates = false;
    _hasAnyCandidates = false;
  }

  Future<void> _cleanup() async {
    print('$_tag Nettoyage...');
    _resetNegotiationState();

    _iceBatchTimer?.cancel();
    _cancelConnectionTimeout();

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();

    await _peerConnection?.close();
    await _peerConnection?.dispose();

    _localStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _remoteUserId = null;
    if (_peerConnection != null) {
      try {
        print('$_tag Attente fermeture PeerConnection...');
        await _peerConnection!.close();

        // Attendre que le PC soit vraiment fermé
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}
    }

    try {
      await _peerConnection?.dispose();
    } catch (_) {}
    _peerConnection = null;


    print('$_tag ✓ Nettoyage terminé');
  }

  /// ========================
  /// SIGNALING
  /// ========================
  void _sendSignal(String type, Map<String, dynamic> data) {
    if (_remoteUserId == null || _currentCallId == null) {
      print('$_tag ⚠ Envoi signal ignoré (pas de remote/callId)');
      return;
    }

    _webSocketService?.sendCallSignal(
      type,
      _remoteUserId!,
      data,
      _currentCallId!,
    );
  }

  /// ========================
  /// DISPOSE
  /// ========================
  void dispose() {
    print('$_tag Dispose');
    _cancelConnectionTimeout();
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
    _videoUpgradeRequestController.close();
    _videoUpgradeResponseController.close();
    _isInitialized = false;
  }
}

enum CallState { idle, calling, ringing, connected, ended, error }