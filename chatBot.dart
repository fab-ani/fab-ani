import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart" as cloud_store;

import 'package:image_picker/image_picker.dart';

import 'package:my_tips/models/user.dart';
import 'package:my_tips/selectingPhoto/selectingMultiple.dart' as mp;
import 'package:my_tips/services/Database.dart';
import 'package:provider/provider.dart';

final imageHelper1 = mp.ImageHelper();

class ProfileImage extends StatefulWidget {
  const ProfileImage({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  List<File>? _image = [];
  late cloud_store.CollectionReference imgref;
  bool _uploading = false;
  String _uploadStatus = "";

  final TextEditingController productName = TextEditingController();
  final TextEditingController productPrice = TextEditingController();
  final TextEditingController productDescription = TextEditingController();
  final TextEditingController productStock = TextEditingController();

  @override
  void dispose() {
    productName.dispose();
    productPrice.dispose();
    productDescription.dispose();
    productStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Photos"),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, "/");
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        actions: [
          ElevatedButton(
            onPressed: _uploading ? null : _uploadImage,
            child: _uploading
                ? const CircularProgressIndicator()
                : const Icon(Icons.arrow_upward),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: GridView.builder(
                  itemCount: _image!.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  itemBuilder: (context, index) {
                    if (index >= 0 && index < _image!.length) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(_image![index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () async {
                          final pickedImages =
                              await imageHelper1.pickImage(multiple: true);
                          if (pickedImages.isNotEmpty) {
                            final xfiles =
                                pickedImages.map((e) => XFile(e.path)).toList();
                            for (int i = 0; i < xfiles.length; i++) {
                              final croppedFile =
                                  await imageHelper1.crop(file: xfiles[i]);
                              if (croppedFile != null) {
                                setState(() {
                                  _image!.add(File(croppedFile.path));
                                });
                              }
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.add),
                          ),
                        ),
                      );
                    }
                  })),
          TextButton(
            onPressed: () async {
              final pickedImages = await imageHelper1.pickImage(multiple: true);
              if (pickedImages.isNotEmpty) {
                final xfiles = pickedImages.map((e) => XFile(e.path)).toList();
                final croppedFile = await imageHelper1.crop(file: xfiles[0]);
                if (croppedFile != null) {
                  setState(() {
                    _image!.add(File(croppedFile.path));
                  });
                }
                for (int i = 1; i < xfiles.length; i++) {
                  final croppedFile = await imageHelper1.crop(file: xfiles[i]);
                  if (croppedFile != null) {
                    setState(() {
                      _image!.add(File(croppedFile.path));
                    });
                  }
                }
              }
            },
            child: const Text('Pick images'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> uploadFiles(List<File> files) async {
    List<String> downloadUrls = [];
    final storageRef = FirebaseStorage.instance.ref();

    final uploadTasks = files.map((file) {
      final fileName = DateTime.now().microsecondsSinceEpoch.toString();
      final fileRef = storageRef.child('images/$fileName');
      return fileRef.putFile(file);
    }).toList();
    final snapShots = await Future.wait(uploadTasks);
    for (final snapshot in snapShots) {
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
      print(downloadUrl);
    }
    return downloadUrls;
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    final user = Provider.of<Users>(context, listen: false);
    print('uploading ');

    setState(() {
      _uploading = true;
      _uploadStatus = "Uploading image...";
    });
    String? fileURL;
    List<String>? downloadURL;
    if (_image!.length == 1) {
      final imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final firebaseStorageRef =
          FirebaseStorage.instance.ref().child('images/$imageName');
      final uploadTask = firebaseStorageRef.putFile(_image![0]);
      final taskSnapshot = await uploadTask;
      fileURL = await taskSnapshot.ref.getDownloadURL();
    }
    if (_image!.isNotEmpty) {
      try {
        downloadURL = await uploadFiles(_image!);
        setState(() {
          _uploadStatus = 'Images uploaded successfully';
        });
      } catch (e) {
        setState(() {
          _uploadStatus = 'Failed to upload images: $e';
        });
      }
    }

    // ignore: use_build_context_synchronously
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Add product Details"),
            content: Column(
              children: [
                TextFormField(
                  controller: productName,
                  decoration: const InputDecoration(labelText: "Product Name"),
                ),
                TextFormField(
                  controller: productPrice,
                  decoration: const InputDecoration(labelText: "Product Price"),
                ),
                TextFormField(
                  controller: productDescription,
                  decoration:
                      const InputDecoration(labelText: "Product Description"),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final name = productName.text;
                  final price = int.parse(productPrice.text);
                  final details = productDescription.text;
                  final stock = int.parse(productStock.text);
                  final List<String> imageUrls = [];
                  if (fileURL != null) {
                    imageUrls.add(fileURL);
                    print('my images urls here $imageUrls');
                  } else {
                    print('my fileurl is null');
                  }
                  if (downloadURL != null) {
                    imageUrls.addAll(downloadURL);
                    print('my images urls here $imageUrls');
                  } else {
                    print('downloadurl is empty');
                  }
                  try {
                    await DatabaseServices(uid: user.uid!).updateUserData(
                      name,
                      price,
                      details,
                      imageUrls,
                      stock,
                    );
                    setState(() {
                      _uploadStatus = 'Data updated successfully!';
                    });
                  } catch (e) {
                    print('error here');
                  }
                },
                child: const Text("upload"),
              ),
            ],
          );
        });

    setState(() {
      print('end');
      _uploading = false;
    });
  }
}
