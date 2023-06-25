import 'dart:convert';

import 'package:bubble/bubble.dart';
import "package:flutter/material.dart";
import 'package:chat_bubbles/chat_bubbles.dart';

import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreen();
}

class _ChatBotScreen extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listkey = GlobalKey();
  final List<dynamic> _data = [];
  static const String BOT_URL = 'http://172.20.10.2:5000/api/predict';
  TextEditingController queryController = TextEditingController();
  Map<String, bool> loadingMap = {};
  late AnimationController _animationController;
  late Animation<Alignment> _alignmentAnimation;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _alignmentAnimation = Tween<Alignment>(
      begin: Alignment.center,
      end: Alignment.topCenter,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("chatBot"),
        leading: IconButton(
          onPressed: () async {
            Navigator.pushNamed(context, "/");
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AnimatedList(
              reverse: true,
              key: _listkey,
              initialItemCount: _data.length,
              itemBuilder: (BuildContext context, int index, animation) {
                return buildItem(_data[index], animation, index);
              },
              controller: _scrollController,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: const Color(0xffe4ebfb),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: TextField(
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.redAccent)),
                          hintText: "Hellow chapBot....",
                          filled: true,
                          hintStyle: const TextStyle(fontFamily: "italic"),
                          fillColor: Colors.yellow,
                        ),
                        controller: queryController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (msg) {
                          getResponse();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      onPressed: () {
                        getResponse();
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.amber,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  getResponse() async {
    if (queryController.text.isNotEmpty) {
      insertSingleItem(queryController.text);

      var client = getClient();
      try {
        client.post(
          Uri.parse(BOT_URL),
          body: {"text": queryController.text},
        ).then((response) async {
          if (response.statusCode == 200 && response.body.isNotEmpty) {
            Map<String, dynamic> data = json.decode(response.body);
            print("data ${data.runtimeType}");

            //await Future.delayed(const Duration(seconds: 8));

            insertSingleItem(data);
          }
        });
      } finally {
        client.close();
        queryController.clear();
      }
    }
  }

  void insertSingleItem(dynamic message) {
    print("messsssssse$message ${message.runtimeType}");
    _data.insert(0, message);
    _listkey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 500),
    );
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  http.Client getClient() {
    return http.Client();
  }

  List<Future> futures = [];
  List<int> indexes = [];

  Widget buildItem(dynamic item, Animation<double> animation, int index) {
    bool mine = item.toString().endsWith("<bot>");

    if (item.toString().startsWith("{")) {
      print("this block 1");
      print(item);
      Map<String, dynamic> details = item;
      print("items after jsonDecode $details");

      if (details.containsKey("response")) {
        // Handle the case where the response is a chat message
        String responseMessage = details["response"];
        futures.add(getClient().post(
          Uri.parse(BOT_URL),
          body: {"text": responseMessage},
        ));
        indexes.add(index);
        return SizeTransition(
          sizeFactor: animation,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              alignment: Alignment.topLeft,
              child: Bubble(
                color: const Color(0xfffbe4db),
                padding: const BubbleEdges.all(10),
                margin: const BubbleEdges.only(left: 10, right: 100),
                nip: BubbleNip.rightBottom,
                child: Text(
                  responseMessage,
                  style: TextStyle(color: mine ? Colors.blue : Colors.black),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
        );
      } else {
        String imageUrl = details["url_image"];
        String name = details["name"];
        String detailstext = details["details"];
        String price = details["price"].toString();
        bool isRow = true;
        return GestureDetector(
          onTap: () {
            setState(() {
              isRow = !isRow;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              alignment: Alignment.topLeft,
              child: Card(
                color: _isExpanded ? Colors.blue : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Align(
                        alignment: _alignmentAnimation.value,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            color: const Color(0xfffbe4db),
                            child: Flex(
                              direction:
                                  isRow ? Axis.horizontal : Axis.vertical,
                              children: [
                                Expanded(
                                  flex: _isExpanded ? 6 : 12,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: _isExpanded ? 0 : 6,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 2.0,
                                          ),
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                                size: 16,
                                              ),
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                                size: 16,
                                              ),
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                                size: 16,
                                              ),
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                                size: 16,
                                              ),
                                              Icon(
                                                Icons.star,
                                                color: Colors.grey,
                                                size: 16,
                                              )
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          Text(
                                            "Tsh $price",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.red),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                color: Colors.blue,
                                              ),
                                              Text(
                                                "mbeya",
                                                style: TextStyle(
                                                    fontStyle:
                                                        FontStyle.italic),
                                              )
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          Text(
                                            detailstext,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedCrossFade(
                                  firstChild: const Text("some details"),
                                  secondChild: const Text("secondChild"),
                                  crossFadeState: !isRow
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  duration: const Duration(seconds: 1),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
    } else {
      return SizeTransition(
        sizeFactor: animation,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            alignment: Alignment.topRight,
            child: Bubble(
              color: Color(0xffc1e8ff),
              padding: const BubbleEdges.all(10),
              margin: const BubbleEdges.only(left: 100, right: 10),
              nip: BubbleNip.rightBottom,
              child: Text(
                item.replaceAll("<bot>", " "),
                style: TextStyle(color: mine ? Colors.blue : Colors.black),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
        ),
      );
    }
  }
}
