import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_story_app_concept/home.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  List<Widget> children;
  int age;
  String name, education;
  PageController controller;
  List<Widget> children1;

  void addPage() {
    setState(() {
      children.add(children1[children.length]);
    });
  }

  void onPressedNext() {
    if (children.length < 3) addPage();
    controller.nextPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void onPressedBack() {
    controller.previousPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void onChanged() {
    setState(() {});
  }

  void onSubmit() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Home(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = new PageController();
    children = new List();
    children1 = [
      _getPage(
        bgColor: Color(0xFFF2BB25),
        image: Image.asset('assets/login/first.png'),
        text: 'Tell us your\nage',
        index: 1,
        hint: 'Age',
        keyBoardType: TextInputType.number,
        value: age,
        onPressedNext: onPressedNext,
        onPressedBack: onPressedBack,
        onChanged: (String s) {
          age = int.parse(s);
          print(age);
          setState(() {});
        },
        onSubmit: onSubmit,
      ),
      _getPage(
        bgColor: Color(0xFF126C20),
        image: Image.asset('assets/login/second.png'),
        text: 'Tell us your\nname',
        index: 2,
        hint: 'Name',
        keyBoardType: TextInputType.number,
        value: age,
        onPressedNext: onPressedNext,
        onPressedBack: onPressedBack,
        onChanged: (String s) {
          name = s;
          setState(() {});
        },
        onSubmit: onSubmit,
      ),
      _getPage(
        bgColor: Color(0xFF8ED547),
        image: Image.asset('assets/login/third.png'),
        text: 'Tell us your\neducation',
        index: 3,
        hint: 'Education',
        keyBoardType: TextInputType.number,
        value: age,
        onPressedNext: onPressedNext,
        onPressedBack: onPressedBack,
        onChanged: (String s) {
          education = s;
          setState(() {});
        },
        onSubmit: onSubmit,
      ),
    ];
    children.add(
      children1.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      children: children1,
    );
  }
}

_getPage({
  Color bgColor,
  Image image,
  String text,
  int index,
  String hint,
  TextInputType keyBoardType,
  dynamic value,
  Function onPressedNext,
  Function onPressedBack,
  Function onSubmit,
  Function onChanged,
}) {
  return Scaffold(
    body: Container(
      padding: EdgeInsets.all(30),
      color: bgColor,
      child: Column(
        children: <Widget>[
          /* Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                'Skip',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ), */
          Spacer(
            flex: 1,
          ),
          Expanded(
            flex: 4,
            child: image,
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: <Widget>[
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 25,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: index == 1 ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: index == 1 ? Colors.white : Colors.white70,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      width: index == 2 ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: index == 2 ? Colors.white : Colors.white70,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      width: index == 3 ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: index == 3 ? Colors.white : Colors.white70,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    child: TextField(
                      keyboardType: keyBoardType,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    index > 1
                        ? FlatButton(
                            onPressed: onPressedBack,
                            child: Text(
                              'Back',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        : SizedBox(),
                    index < 3
                        ? FlatButton(
                            onPressed: onPressedNext,
                            child: Text(
                              'Next',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        : FlatButton(
                            onPressed: onSubmit,
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    ),
  );
}
