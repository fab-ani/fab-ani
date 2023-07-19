import 'dart:convert';

import 'package:bubble/bubble.dart';
import "package:flutter/material.dart";

import 'package:http/http.dart' as http;
import 'package:my_tips/selectingPhoto/imageViewer.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreen();
}

class _ChatBotScreen extends State<ChatBotScreen> {
  final GlobalKey<AnimatedListState> _listkey = GlobalKey();
  final List<dynamic> _data = [];
  static const String BOT_URL = 'http://172.20.10.2:5000/api/predict';
  TextEditingController queryController = TextEditingController();
  Map<String, bool> loadingMap = {};
  Map<int, bool> isTapMap = {};

  //late ScrollController _scrollController;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _data.length; i++) {
      isTapMap[i] = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffbdbdbd),
      appBar: AppBar(
        backgroundColor: const Color(0xff554994),
        title: const Text("ChapBot"),
        leading: IconButton(
          onPressed: () async {
            Navigator.pushNamed(context, "/");
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF112D60), Color(0xffB6C0C5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  key: _listkey,
                  itemCount: _data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return buildItem(_data[index], index);
                  },
                  controller: _scrollController),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: const Color(0xff554994).withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 20, bottom: 10, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: TextField(
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(
                                color: Colors.purple,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xff554994)),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            hintText: "Hellow chapBot....",
                            filled: true,
                            hintStyle: const TextStyle(fontFamily: "italic"),
                            fillColor: Colors.white,
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
                      FloatingActionButton.small(
                        onPressed: () {
                          getResponse();
                        },
                        backgroundColor: const Color(0xffff5722),
                        child: const Icon(
                          Icons.send,
                          color: Color(0xff554994),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
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
    _data.add(message);
    _listkey.currentState?.insertItem(
      _data.length - 1,
      duration: const Duration(milliseconds: 500),
    );
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  http.Client getClient() {
    return http.Client();
  }

  Widget buildItem(dynamic item, int index) {
    bool mine = item.toString().endsWith("<bot>");

    if (item.toString().startsWith("{")) {
      print("this block 1");
      print(item);
      Map<String, dynamic> details = item;

      print("items after jsonDecode $details");

      if (details.containsKey("response")) {
        // Handle the case where the response is a chat message
        String responseMessage = details["response"];

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            alignment: Alignment.topLeft,
            child: Bubble(
              color: const Color(0xfff5f5f5),
              padding: const BubbleEdges.only(
                  left: 10, right: 10, bottom: 10, top: 10),
              margin: const BubbleEdges.only(left: 10, right: 100, bottom: 10),
              child: Text(
                responseMessage,
                style: TextStyle(
                    color: mine ? Colors.blue : Colors.black, fontSize: 18),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        );
      } else {
        final imageUrlString = details["url_image"] as String;
        String name = details["name"];
        String detailstext = details["details"];
        String price = details["price"].toString();

        final imageUrlListString = imageUrlString
            .replaceAll("[", "")
            .replaceAll("]", "")
            .replaceAll("'", "");
        final imageUrlArray = imageUrlListString.split(',');

        final trimmedImageUrlArray =
            imageUrlArray.map((url) => url.trim()).toList();
        return GestureDetector(
          onTap: () {
            setState(() {
              isTapMap[index] = !(isTapMap[index] ?? true);
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 30),
            child: Container(
              alignment: Alignment.topLeft,
              child: Card(
                color: mine ? Colors.blue : Colors.white.withOpacity(0.5),
                elevation: 4,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: IntrinsicHeight(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                              fontStyle: FontStyle.italic),
                                        )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      detailstext,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    SizedBox(
                                      height: 150,
                                      width: double.infinity,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: trimmedImageUrlArray.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ExapandImages(
                                                        imageUrls:
                                                            trimmedImageUrlArray,
                                                        initialIndex: index,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Image.network(
                                                  trimmedImageUrlArray[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          alignment: Alignment.topRight,
          child: Bubble(
            color: const Color(0xffff5722),
            padding: const BubbleEdges.only(
                left: 10, right: 10, bottom: 10, top: 10),
            margin: const BubbleEdges.only(left: 100, right: 10, bottom: 8),
            child: Text(
              item.replaceAll("<bot>", " "),
              style: TextStyle(
                  color: mine ? Colors.blue : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lato'),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      );
    }
  }
}
