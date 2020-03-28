import 'dart:async';
import 'package:flutter/material.dart';

class GameTimer extends StatefulWidget {
  final TextStyle style;
  final bool reverse;
  final Duration initDuration;
  final Function timerEnd;
  GameTimer(
      {this.style,
      this.initDuration,
      @required this.reverse,
      @required this.timerEnd})
      : assert(!reverse || (reverse && initDuration != null));
  void startTimer() {
    timState.startTimer();
  }

  void endTimer() {
    timState.endTimer();
  }

  Map<String, num> timePlayed() {
    Map<String, num> m;
    if (initDuration != null) {
      m = {
        'min': initDuration.inMinutes - timState.min,
        'sec': initDuration.inSeconds - timState.sec,
      };
    } else {
      m = {
        'min': timState.min,
        'sec': timState.sec,
      };
    }

    return m;
  }

  bool isActive() => timState.t.isActive;
  final _GameTimerState timState = new _GameTimerState();
  @override
  _GameTimerState createState() => timState;
}

class _GameTimerState extends State<GameTimer> {
  Timer t;
  int min = 0, sec = 0;

  void startTimer() {
    t = new Timer.periodic(const Duration(seconds: 1), (tim) {
      if (widget.reverse) {
        if (sec == 0) {
          if (min == 0) {
            t.cancel();
            widget.timerEnd();
          } else {
            min -= 1;
            sec = 59;
          }
        } else {
          sec -= 1;
        }
      } else {
        sec += 1;
        if (sec == 60) {
          min += 1;
          sec = 0;
        }
      }
      if (this.mounted) setState(() {});
    });
  }

  void endTimer() {
    t.cancel();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initDuration != null) {
      min = widget.initDuration.inMinutes;
      sec = widget.initDuration.inSeconds;
    }
  }

  @override
  void dispose() {
    if (t.isActive) t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      (min < 10 ? "0" + min.toString() : min.toString()) +
          ":" +
          (sec < 10 ? "0" + sec.toString() : sec.toString()),
      style: widget.style != null ? widget.style : TextStyle(),
    );
  }
}
