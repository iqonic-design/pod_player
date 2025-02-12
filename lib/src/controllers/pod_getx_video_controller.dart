// ignore_for_file: require_trailing_commas

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as uni_html;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../pod_player.dart';
import '../utils/logger.dart';
import '../utils/video_apis.dart';

part 'pod_base_controller.dart';

part 'pod_gestures_controller.dart';

part 'pod_ui_controller.dart';

part 'pod_video_controller.dart';

part 'pod_video_quality_controller.dart';

class PodGetXVideoController extends _PodGesturesController {
  ///main videoplayer controller
  VideoPlayerController? get videoCtr => _videoCtr;

  ///podVideoPlayer state notifier
  PodVideoState get podVideoState => _podVideoState;

  ///vimeo or general --video player type
  PodVideoPlayerType get videoPlayerType => _videoPlayerType;

  String get currentPaybackSpeed => _currentPaybackSpeed;

  ///
  Duration get videoDuration => _videoDuration;

  ///
  Duration get videoPosition => _videoPosition;

  bool controllerInitialized = false;

  bool showMenu = true;

  bool hideFullScreenButton = true;

  late PodPlayerConfig podPlayerConfig;
  late PlayVideoFrom playVideoFrom;

  void config({
    required PlayVideoFrom playVideoFrom,
    required PodPlayerConfig playerConfig,
  }) {
    this.playVideoFrom = playVideoFrom;
    _videoPlayerType = playVideoFrom.playerType;
    podPlayerConfig = playerConfig;
    autoPlay = playerConfig.autoPlay;
    isLooping = playerConfig.isLooping;
  }

  ///*init
  Future<void> videoInit() async {
    ///
    // checkPlayerType();
    podLog(_videoPlayerType.toString());
    try {
      await _initializePlayer();
      await _videoCtr?.initialize();
      _videoDuration = _videoCtr?.value.duration ?? Duration.zero;
      await setLooping(isLooping);
      _videoCtr?.addListener(videoListner);
      addListenerId('podVideoState', podStateListner);

      checkAutoPlayVideo();
      controllerInitialized = true;
      update();

      update(['update-all']);
      // ignore: unawaited_futures
      Future<void>.delayed(const Duration(milliseconds: 600)).then((_) => _isWebAutoPlayDone = true);
    } catch (e) {
      podVideoStateChanger(PodVideoState.error);
      update(['errorState']);
      update(['update-all']);
      podLog('ERROR ON POD_PLAYER:  $e');
      rethrow;
    }
  }

  Future<void> _initializePlayer() async {
    switch (_videoPlayerType) {
      case PodVideoPlayerType.network:

        ///
        _videoCtr = VideoPlayerController.networkUrl(
          Uri.parse(playVideoFrom.dataSource!),
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          formatHint: playVideoFrom.formatHint,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          httpHeaders: playVideoFrom.httpHeaders,
        );
        playingVideoUrl = playVideoFrom.dataSource;
      case PodVideoPlayerType.networkQualityUrls:
        final url = await getUrlFromVideoQualityUrls(
          qualityList: podPlayerConfig.videoQualityPriority,
          videoUrls: playVideoFrom.videoQualityUrls!,
        );

        ///
        _videoCtr = VideoPlayerController.networkUrl(
          Uri.parse(url),
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          formatHint: playVideoFrom.formatHint,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          httpHeaders: playVideoFrom.httpHeaders,
        );
        playingVideoUrl = url;

      case PodVideoPlayerType.youtube:
        final urls = await getVideoQualityUrlsFromYoutube(
          playVideoFrom.dataSource!,
          playVideoFrom.live,
        );
        final url = await getUrlFromVideoQualityUrls(
          qualityList: podPlayerConfig.videoQualityPriority,
          videoUrls: urls,
        );

        ///
        _videoCtr = VideoPlayerController.networkUrl(
          Uri.parse(url),
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          formatHint: playVideoFrom.formatHint,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          httpHeaders: playVideoFrom.httpHeaders,
        );
        playingVideoUrl = url;

      case PodVideoPlayerType.vimeo:
        await getQualityUrlsFromVimeoId(
          playVideoFrom.dataSource!,
          hash: playVideoFrom.hash,
        );
        final url = await getUrlFromVideoQualityUrls(
          qualityList: podPlayerConfig.videoQualityPriority,
          videoUrls: vimeoOrVideoUrls,
        );

        _videoCtr = VideoPlayerController.networkUrl(
          Uri.parse(url),
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          formatHint: playVideoFrom.formatHint,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          httpHeaders: playVideoFrom.httpHeaders,
        );
        playingVideoUrl = url;

      case PodVideoPlayerType.asset:

        ///
        _videoCtr = VideoPlayerController.asset(
          playVideoFrom.dataSource!,
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          package: playVideoFrom.package,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
        );
        playingVideoUrl = playVideoFrom.dataSource;

      case PodVideoPlayerType.file:
        if (kIsWeb) {
          throw Exception('file doesnt support web');
        }

        ///
        _videoCtr = VideoPlayerController.file(
          playVideoFrom.file!,
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
        );

      case PodVideoPlayerType.vimeoPrivateVideos:
        await getQualityUrlsFromVimeoPrivateId(
          playVideoFrom.dataSource!,
          playVideoFrom.httpHeaders,
        );
        final url = await getUrlFromVideoQualityUrls(
          qualityList: podPlayerConfig.videoQualityPriority,
          videoUrls: vimeoOrVideoUrls,
        );

        _videoCtr = VideoPlayerController.networkUrl(
          Uri.parse(url),
          closedCaptionFile: playVideoFrom.closedCaptionFile,
          formatHint: playVideoFrom.formatHint,
          videoPlayerOptions: playVideoFrom.videoPlayerOptions,
          httpHeaders: playVideoFrom.httpHeaders,
        );
        playingVideoUrl = url;
    }
  }

  ///Listning on keyboard events
  void onKeyBoardEvents({
    required KeyEvent event,
    required BuildContext appContext,
    required String tag,
  }) {
    if (kIsWeb) {
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space)) {
        togglePlayPauseVideo();
        return;
      }
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyM)) {
        toggleMute();
        return;
      }
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft)) {
        onLeftDoubleTap();
        return;
      }
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight)) {
        onRightDoubleTap();
        return;
      }
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyF) && event.logicalKey.keyLabel == 'F') {
        toggleFullScreenOnWeb(appContext, tag);
      }
      if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.escape)) {
        if (isFullScreen) {
          uni_html.document.exitFullscreen();
          if (!isWebPopupOverlayOpen) {
            disableFullScreen(appContext, tag);
          }
        }
      }

      return;
    } else {
      if (event is KeyDownEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.select:
            togglePlayPauseVideo();
            return;
          case LogicalKeyboardKey.arrowLeft:
            seekBackward(Duration(seconds: _videoCtr!.value.position.inSeconds >= 5 ? 5 : _videoCtr!.value.position.inSeconds));
            return;
          case LogicalKeyboardKey.arrowRight:
            seekForward(Duration(seconds: ((_videoCtr!.value.position.inSeconds + 5) > videoDuration.inSeconds) ? videoDuration.inSeconds : 5));
            return;
        }
      }
      if (event is KeyRepeatEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft:
            onLeftDoubleTap();
            return;
          case LogicalKeyboardKey.arrowRight:
            onRightDoubleTap();
            return;
        }
      }
    }
  }

  void toggleFullScreenOnWeb(BuildContext context, String tag) {
    if (isFullScreen) {
      uni_html.document.exitFullscreen();
      if (!isWebPopupOverlayOpen) {
        disableFullScreen(context, tag);
      }
    } else {
      uni_html.document.documentElement?.requestFullscreen();
      enableFullScreen(tag, showMenu: showMenu);
    }
  }

  ///this func will listne to update id `_podVideoState`
  void podStateListner() {
    podLog(_podVideoState.toString());
    switch (_podVideoState) {
      case PodVideoState.playing:
        if (podPlayerConfig.wakelockEnabled) WakelockPlus.enable();
        playVideo(true);
      case PodVideoState.paused:
        if (podPlayerConfig.wakelockEnabled) WakelockPlus.disable();
        playVideo(false);
      case PodVideoState.loading:
        isShowOverlay(true);
      case PodVideoState.error:
        if (podPlayerConfig.wakelockEnabled) WakelockPlus.disable();
        playVideo(false);
    }
  }

  ///checkes wether video should be `autoplayed` initially
  void checkAutoPlayVideo() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (autoPlay && (isVideoUiBinded ?? false)) {
        if (kIsWeb) await _videoCtr?.setVolume(0);
        podVideoStateChanger(PodVideoState.playing);
      } else {
        podVideoStateChanger(PodVideoState.paused);
      }
    });
  }

  Future<void> changeVideo({
    required PlayVideoFrom playVideoFrom,
    required PodPlayerConfig playerConfig,
  }) async {
    _videoCtr?.removeListener(videoListner);
    podVideoStateChanger(PodVideoState.paused);
    podVideoStateChanger(PodVideoState.loading);
    keyboardFocusWeb?.removeListener(keyboadListner);
    removeListenerId('podVideoState', podStateListner);
    _isWebAutoPlayDone = false;
    vimeoOrVideoUrls = [];
    config(playVideoFrom: playVideoFrom, playerConfig: playerConfig);
    keyboardFocusWeb?.requestFocus();
    keyboardFocusWeb?.addListener(keyboadListner);
    await videoInit();
  }

  void showMoreVertIcon({bool showIcon = true}) {
    showMenu = showIcon;
  }
}
