library social_media_recorder;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/widgets/lock_record.dart';
import 'package:social_media_recorder/widgets/show_counter.dart';
import 'package:social_media_recorder/widgets/show_mic_with_text.dart';
import 'package:social_media_recorder/widgets/sound_recorder_when_locked_design.dart';

import '../audio_encoder_type.dart';

class SocialMediaRecorder extends StatefulWidget {
  /// function reture the recording sound file
  final Function(String path) sendRequestFunction;
  final Function(SoundRecordNotifier state) didSoundRecordNotifier;

  /// recording Icon That pressesd to start record
  final Widget? recordIcon;

  /// recording Icon when user locked the record
  final Widget? recordIconWhenLockedRecord;

  /// use to change all recording widget color
  final Color? backGroundColor;

  /// use to change the counter style
  final TextStyle? counterTextStyle;

  /// text to know user should drag in the left to cancel record
  final String? slideToCancelText;

  /// use to change slide to cancel textstyle
  final TextStyle? slideToCancelTextStyle;

  /// this text show when lock record and to tell user should press in this text to cancel recod
  final String? cancelText;

  /// use to change cancel text style
  final TextStyle? cancelTextStyle;

  /// put you file directory storage path if you didn't pass it take deafult path
  final String? storeSoundRecoringPath;

  /// Chose the encode type
  final AudioEncoderType encode;

  /// use if you want change the raduis of un record
  final BorderRadius? radius;

  // use to change lock icon to design you need it
  final Widget? lockButton;
  // use it to change send button when user lock the record
  final Widget? sendButtonIcon;

  // ignore: sort_constructors_first
  const SocialMediaRecorder({
    this.sendButtonIcon,
    this.storeSoundRecoringPath = "",
    required this.sendRequestFunction,
    this.recordIcon,
    this.lockButton,
    this.backGroundColor,
    this.cancelTextStyle,
    this.counterTextStyle,
    this.slideToCancelTextStyle,
    this.slideToCancelText = " Slide to Cancel >",
    this.cancelText = "Cancel",
    this.encode = AudioEncoderType.AAC,
    this.radius,
    Key? key,
    this.recordIconWhenLockedRecord,
    required this.didSoundRecordNotifier,
  }) : super(key: key);

  @override
  _SocialMediaRecorder createState() => _SocialMediaRecorder();
}

class _SocialMediaRecorder extends State<SocialMediaRecorder> {
  late SoundRecordNotifier soundRecordNotifier;

  @override
  void initState() {
    soundRecordNotifier = SoundRecordNotifier();
    soundRecordNotifier.initialStorePathRecord =
        widget.storeSoundRecoringPath ?? "";
    soundRecordNotifier.isShow = false;
    soundRecordNotifier.voidInitialSound();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => soundRecordNotifier),
        ],
        child: Consumer<SoundRecordNotifier>(
          builder: (context, value, _) {
            return Directionality(
                textDirection: TextDirection.rtl, child: makeBody(value));
          },
        ));
  }

  Widget makeBody(SoundRecordNotifier state) {
    return Column(
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (scrollEnd) {
            state.updateScrollValue(scrollEnd.globalPosition, context);
          },
          onHorizontalDragEnd: (x) {
            widget.didSoundRecordNotifier(state);
          },
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: recordVoice(state),
          ),
        )
      ],
    );
  }

  Widget recordVoice(SoundRecordNotifier state) {
    if (state.lockScreenRecord == true) {
      return SoundRecorderWhenLockedDesign(
        cancelText: widget.cancelText,
        bankgroundColor: widget.backGroundColor,
        sendButtonIcon: widget.sendButtonIcon,
        cancelTextStyle: widget.cancelTextStyle,
        recordIconWhenLockedRecord: widget.recordIconWhenLockedRecord,
        sendRequestFunction: widget.sendRequestFunction,
        soundRecordNotifier: state,
        counterTextStyle: widget.cancelTextStyle,
        didSoundRecordNotifier: widget.didSoundRecordNotifier,
      );
    }

    return Listener(
      onPointerDown: (details) async {
        state.setNewInitialDraggableHeight(details.position.dy);
        state.stopRecorder();
        state.resetEdgePadding();
        soundRecordNotifier.isShow = true;
        state.record();
        widget.didSoundRecordNotifier(state);
      },
      onPointerUp: (details) async {
        if (!state.isLocked) {
          await state.stopRecorder();
          if (state.buttonPressed) {
            if (state.second > 1 || state.minute > 0) {
              String path = state.mPath;
              widget.sendRequestFunction(path);
            }
          }
          await state.resetEdgePadding();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: soundRecordNotifier.isShow ? 0 : 300),
        height: 50,
        width: (soundRecordNotifier.isShow)
            ? MediaQuery.of(context).size.width
            : 50,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: state.edge),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: soundRecordNotifier.isShow
                        ? BorderRadius.circular(12)
                        : widget.radius != null && !soundRecordNotifier.isShow
                            ? widget.radius
                            : BorderRadius.circular(0),
                    color: state.buttonPressed
                        ? widget.backGroundColor
                        : Colors.transparent),
                child: Stack(
                  children: [
                    ShowMicWithText(
                      recordIcon: widget.recordIcon,
                      shouldShowText: soundRecordNotifier.isShow,
                      soundRecorderState: state,
                      slideToCancelTextStyle: widget.slideToCancelTextStyle,
                      slideToCancelText: widget.slideToCancelText,
                      backGroundColor: widget.backGroundColor,
                      didSoundRecordNotifier: widget.didSoundRecordNotifier,
                    ),
                    if (soundRecordNotifier.isShow)
                      ShowCounter(soundRecorderState: state),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: LockRecord(
                soundRecorderState: state,
                lockIcon: widget.lockButton,
              ),
            )
          ],
        ),
      ),
    );
  }
}
