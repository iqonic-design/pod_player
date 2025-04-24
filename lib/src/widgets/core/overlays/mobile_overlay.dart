part of 'package:pod_player/src/pod_player.dart';

class _MobileOverlay extends StatelessWidget {
  final String tag;
  final bool showMenu;

  const _MobileOverlay({
    required this.tag,
    this.showMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    const overlayColor = Colors.black38;
    const itemColor = Colors.white;
    final podCtr = Get.find<PodGetXVideoController>(tag: tag);
    return Stack(
      alignment: Alignment.center,
      children: [
        _VideoGestureDetector(
          tag: tag,
          child: ColoredBox(
            color: overlayColor,
            child: Row(
              children: [
                Expanded(
                  child: DoubleTapIcon(
                    tag: tag,
                    isForward: false,
                    height: double.maxFinite,
                    onDoubleTap: _isRtl() ? podCtr.onRightDoubleTap : podCtr.onLeftDoubleTap,
                  ),
                ),
                SizedBox(
                  height: double.infinity,
                  child: Center(
                    child: _AnimatedPlayPauseIcon(tag: tag, size: 42),
                  ),
                ),
                Expanded(
                  child: DoubleTapIcon(
                    isForward: true,
                    tag: tag,
                    height: double.maxFinite,
                    onDoubleTap: _isRtl() ? podCtr.onLeftDoubleTap : podCtr.onRightDoubleTap,
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: IgnorePointer(
                  child: podCtr.videoTitle ?? const SizedBox(),
                ),
              ),
              if (showMenu)
                MaterialIconButton(
                  toolTipMesg: podCtr.podPlayerLabels.settings,
                  color: itemColor,
                  onPressed: () {
                    if (podCtr.isOverlayVisible) {
                      _bottomSheet(context);
                    } else {
                      podCtr.toggleVideoOverlay();
                    }
                  },
                  child: const Icon(
                    Icons.more_vert_rounded,
                  ),
                ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: _MobileOverlayBottomControlles(tag: tag),
        ),
      ],
    );
  }

  bool _isRtl() {
    return false;
  }

  void _bottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(child: _MobileBottomSheet(tag: tag)),
    );
  }
}
