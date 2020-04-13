import 'package:flutter/material.dart';

class SingleDigit extends StatefulWidget {
  final TextStyle textStyle;
  final BoxDecoration boxDecoration;
  final int initialValue;

  _SingleDigitState _state;

  SingleDigit(
      {this.boxDecoration: const BoxDecoration(color: Colors.black),
      this.textStyle: const TextStyle(color: Colors.grey, fontSize: 30),
      this.initialValue: 0});

  @override
  State<StatefulWidget> createState() {
    _state =
        new _SingleDigitState(textStyle, boxDecoration, 0, this.initialValue);
    return _state;
  }

  setValue(newValue) {
    if (_state != null) {
      _state._setValue(newValue);
    }
  }
}

class _SingleDigitState extends State<SingleDigit>
    with TickerProviderStateMixin {
  _SingleDigitState(this._textStyle, this._boxDecoration, this.previousValue,
      this.currentValue);

  final TextStyle _textStyle;
  final BoxDecoration _boxDecoration;

  int previousValue;
  int currentValue;

  Animation<double> animation;
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  _initAnimation() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    animation = Tween<double>(
            begin: previousValue.toDouble(), end: currentValue.toDouble())
        .animate(controller)
          ..addListener(() {
            setState(() {});
          });
    controller.forward();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  _setValue(int newValue) {
    this.previousValue = this.currentValue;
    this.currentValue = newValue;
    controller.dispose();
    _initAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final Size digitSize = _getSingleDigitSize();

    return Container(
      decoration: _boxDecoration,
      child: SizedOverflowBox(
        alignment: Alignment.topCenter,
        size: digitSize,
        child: ClipRect(
          clipper: CustomDigitClipper(digitSize),
          child: Transform.translate(
            offset: Offset(0, -this.animation.value * digitSize.height),
            child: Column(
              children: List<Widget>.generate(
                10,
                (i) => Text(i.toString(), style: _textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///
  /// Calculates the size of a single digit based on the current text style
  ///
  _getSingleDigitSize() {
    final painter = TextPainter();
    painter.text = TextSpan(style: _textStyle, text: '0');
    painter.textDirection = TextDirection.ltr;
    painter.textAlign = TextAlign.left;
    painter.textScaleFactor = 1.0;
    painter.layout();
    return painter.size;
  }
}

class CustomDigitClipper extends CustomClipper<Rect> {
  CustomDigitClipper(this.digitSize);
  final Size digitSize;

  @override
  Rect getClip(Size size) {
    return Rect.fromPoints(
        Offset.zero, Offset(digitSize.width, digitSize.height));
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }
}

final counterKey = GlobalKey();

class MultipleDigitCounter extends StatefulWidget {
  int initialValue;
  int numberOfDigits;
  bool expandable;
  final TextStyle textStyle;
  final BoxDecoration boxDecoration;

  //MultipleDigitCounterState _state;

  /// state has to be accessible so that the value is accessible from the parent widget
  //MultipleDigitCounterState get state => _state;

  MultipleDigitCounter(this.numberOfDigits, this.expandable, this.textStyle,
      this.initialValue, this.boxDecoration,
      {Key key})
      : super(key: key);

  @override
  MultipleDigitCounterState createState() {
    return MultipleDigitCounterState(this.numberOfDigits, this.expandable,
        this.initialValue, this.textStyle, this.boxDecoration);
  }
}

class MultipleDigitCounterState extends State<MultipleDigitCounter> {
  int numberOfDigits;
  bool expandable;
  int _value;
  final TextStyle _textStyle;
  final BoxDecoration _boxDecoration;

  List<SingleDigit> animatedDigits = [];

  String _oldValue;
  String _newValue;

  int get value => _value;

  set value(int newValue) {
    _oldValue = value.toString();
    while (_oldValue.length < numberOfDigits) {
      _oldValue = '0$_oldValue';
    }

    _value = newValue;

    _newValue = newValue.toString();
    while (_newValue.length < numberOfDigits) {
      _newValue = '0$_newValue';
    }

    setState(() {
      for (var i = 0; i < numberOfDigits; i++) {
        if (_oldValue[i] != _newValue[i]) {
          animatedDigits[i].setValue(int.parse(_newValue[i]));
        }
      }
    });
  }

  String getValueAsString() {
    String val = _value.toString();
    while (val.length < numberOfDigits) {
      val = '0$val';
    }
    return val;
  }

  MultipleDigitCounterState(this.numberOfDigits, this.expandable, this._value,
      this._textStyle, this._boxDecoration);

  @override
  Widget build(BuildContext context) {
    if (animatedDigits.isEmpty) {
      String newValue = getValueAsString();

      for (var i = 0; i < newValue.length; i++) {
        var initialDigit = 0;
        if (_oldValue != null && _oldValue.length > i) {
          initialDigit = int.parse(_oldValue[i]);
        }
        animatedDigits.add(SingleDigit(initialValue: initialDigit));
      }
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.center, children: animatedDigits);
  }
}

class ScoreBox extends StatefulWidget {
  void changeScore(int newValue) => score.changeScore(newValue);
  _ScoreBoxState score = new _ScoreBoxState();
  @override
  _ScoreBoxState createState() => score;
}

class _ScoreBoxState extends State<ScoreBox>
    with SingleTickerProviderStateMixin {
  void changeScore(int newValue) {
    (counterKey.currentState as MultipleDigitCounterState).value = newValue;
  }

  AnimationController con;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    con = new AnimationController(vsync: this, duration: Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedIcon(icon: AnimatedIcons.view_list, progress: con),
          RaisedButton(onPressed: () {
            con.forward();
          })
        ],
      ),
    );
  }
}
