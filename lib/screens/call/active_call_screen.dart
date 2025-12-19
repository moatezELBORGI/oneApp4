import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../models/call_model.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_service.dart';
import '../../providers/call_provider.dart';
import '../../widgets/user_avatar.dart';

class ActiveCallScreen extends StatefulWidget {
  final CallModel call;
  final WebRTCService webrtcService;
  final bool isOutgoing;

  const ActiveCallScreen({
    Key? key,
    required this.call,
    required this.webrtcService,
    required this.isOutgoing,
  }) : super(key: key);

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final CallService _callService = CallService();

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOn = false; // Commence en audio uniquement

  int _callDuration = 0;
  bool _isCallConnected = false;

  Timer? _timer;
  StreamSubscription<CallState>? _callStateSubscription;
  StreamSubscription<bool>? _videoUpgradeRequestSubscription;
  StreamSubscription<bool>? _videoUpgradeResponseSubscription;

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();

    // Attacher le flux local s'il existe déjà
    if (widget.webrtcService.localStream != null) {
      _localRenderer.srcObject = widget.webrtcService.localStream;
    }

    _listenToCallState();
    _listenToRemoteStream();
    _syncMicrophoneState();
  }

  void _listenToRemoteStream() {
    widget.webrtcService.remoteStream.listen((MediaStream stream) async {
      if (!mounted) return;

      _remoteRenderer.srcObject = stream;
      print("Remote stream reçu → attachement au renderer");

      // FORCE LE HAUT-PARLEUR quand le stream arrive
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await WebRTC.invokeMethod('setSpeakerphoneOn', {'enabled': true});
          await Future.delayed(const Duration(milliseconds: 300));
          await WebRTC.invokeMethod('setSpeakerphoneOn', {'enabled': true});
        } catch (e) {
          print('Erreur setSpeakerphoneOn: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isSpeakerOn = true;
        });
      }
      print("Haut-parleur FORCÉ ON");
    });
  }

  void _updateLocalStream() {
    // Mettre à jour le stream local dans le renderer
    if (widget.webrtcService.localStream != null) {
      _localRenderer.srcObject = widget.webrtcService.localStream;
      print("Local stream mis à jour dans le renderer");
    }
  }

  Future<void> _syncMicrophoneState() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _isMuted = widget.webrtcService.isMuted;
      });
    }
  }

  void _listenToCallState() {
    _callStateSubscription =
        widget.webrtcService.callState.listen((CallState state) {
          print("État appel → $state");
          if (state == CallState.connected) {
            if (!_isCallConnected) {
              _isCallConnected = true;
              _startTimer();
            }
          } else if (state == CallState.ended || state == CallState.error) {
            _endCall();
          }
        });

    // Écouter les demandes de bascule vidéo
    _videoUpgradeRequestSubscription =
        widget.webrtcService.videoUpgradeRequest.listen((requested) {
          if (requested) {
            _showVideoUpgradeDialog();
          }
        });

    // Écouter les réponses de bascule vidéo
    _videoUpgradeResponseSubscription =
        widget.webrtcService.videoUpgradeResponse.listen((accepted) {
          if (accepted) {
            // Mettre à jour le stream local dans le renderer
            _updateLocalStream();

            setState(() {
              _isCameraOn = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La vidéo a été activée'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La demande vidéo a été refusée'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
  }

  void _startTimer() {
    _timer?.cancel();
    _callDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  void _showVideoUpgradeDialog() {
    final otherName = widget.isOutgoing
        ? widget.call.receiverName
        : widget.call.callerName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Demande vidéo'),
        content: Text('$otherName souhaite activer la vidéo. Voulez-vous ouvrir votre caméra ?'),
        actions: [
          TextButton(
            onPressed: () {
              widget.webrtcService.rejectVideoUpgrade();
              Navigator.of(context).pop();
            },
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              await widget.webrtcService.acceptVideoUpgrade();
              if (mounted) {
                // Mettre à jour le stream local dans le renderer
                _updateLocalStream();

                setState(() {
                  _isCameraOn = true;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleMute() async {
    await widget.webrtcService.toggleMute();
    setState(() {
      _isMuted = widget.webrtcService.isMuted;
    });
  }

  Future<void> _toggleSpeaker() async {
    final newState = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(newState);
    setState(() => _isSpeakerOn = newState);
  }

  Future<void> _toggleCamera() async {
    // Si la vidéo n'est pas encore activée, demander à l'autre utilisateur
    if (!widget.webrtcService.isVideoEnabled) {
      await widget.webrtcService.requestVideoUpgrade();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'activation vidéo envoyée...'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Sinon, simplement activer/désactiver la caméra locale
      await widget.webrtcService.toggleCamera();
      setState(() {
        _isCameraOn = !_isCameraOn;
      });
    }
  }

  Future<void> _switchCamera() async {
    await widget.webrtcService.switchCamera();
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    _callStateSubscription?.cancel();

    final provider = Provider.of<CallProvider>(context, listen: false);
    await provider.endCall();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    _timer?.cancel();
    _callStateSubscription?.cancel();
    _videoUpgradeRequestSubscription?.cancel();
    _videoUpgradeResponseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.isOutgoing
        ? widget.call.receiverName
        : widget.call.callerName;
    final otherAvatar = widget.isOutgoing
        ? widget.call.receiverAvatar
        : widget.call.callerAvatar;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // --- VIDEO DISTANTE EN PLEIN ECRAN ---
            Positioned.fill(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                _remoteRenderer,
                objectFit:
                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
                  : Container(
                color: const Color(0xFF1C1C1E),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatar(
                        profilePictureUrl: otherAvatar,
                        firstName: otherName,
                        lastName: '',
                        radius: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        otherName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "En attente de connexion vidéo...",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- VIDEO LOCALE (PETITE VIGNETTE) ---
            Positioned(
              top: 20,
              right: 16,
              width: 110,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black87,
                  child: _localRenderer.srcObject != null && _isCameraOn
                      ? RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit
                        .RTCVideoViewObjectFitCover,
                  )
                      : Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),

            // --- INFOS EN HAUT (etat + durée + nom) ---
            Positioned(
              top: 20,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Appel en cours",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    otherName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTROLES EN BAS ---
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ligne caméra - n'afficher le switch camera que si la vidéo est activée
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon:
                        _isCameraOn ? Icons.videocam : Icons.videocam_off,
                        label: "Caméra",
                        active: _isCameraOn,
                        onTap: _toggleCamera,
                      ),
                      if (widget.webrtcService.isVideoEnabled)
                        _buildControlButton(
                          icon: Icons.flip_camera_android,
                          label: "Switch",
                          active: true,
                          onTap: _switchCamera,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ligne audio + fin + HP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: "Micro",
                        active: !_isMuted,
                        onTap: _toggleMute,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        label: "Raccrocher",
                        active: false,
                        onTap: _endCall,
                        color: Colors.red,
                        size: 72,
                        iconSize: 34,
                      ),
                      _buildControlButton(
                        icon:
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        label: "HP",
                        active: _isSpeakerOn,
                        onTap: _toggleSpeaker,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? color,
    double size = 66,
    double iconSize = 28,
  }) {
    return Column(
      children: [
        Material(
          color: color ?? (active ? Colors.white24 : Colors.white10),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
