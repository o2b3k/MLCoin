/*
*  scanner.dart
*  mlcoin_app 2020-04-02
*  mlcoin_app 2020-06-05
*
*  Created by [Filippo Fresilli & Allan Nava].
*  Copyright © 2020 [Filippo Fresilli & Allan Nava]. All rights reserved.
*/
import 'dart:io';

///
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:mlcoin_app/repositories/repositories.dart';
import 'package:mlcoin_app/utils/values/colors.dart';
import 'package:mlcoin_app/widgets/atoms/atoms.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

///
import 'dart:io' show Platform;

///
class ScannerPage extends StatefulWidget {
  // id for routes
  static const String id = 'scanner_page';
  final MLRepository mlRepository;
  ScannerPage({Key key, this.mlRepository}) : super(key: key);

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

//
class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  Future<void> _initializeControllerFuture;
  List<CameraDescription> get cameras => widget.mlRepository.cameras;
  int selectedCamera;

  bool isSquared = false;
  bool isFlashActive = false;

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (cameras != null) _setController();
    print("camers $cameras");
  }

  _setController() {
    controller = CameraController(cameras.first, ResolutionPreset.max);
    selectedCamera = 0;
    _initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _scaffoldKey,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _cameraPreviewWidget(),
          Positioned.fill(
            child: SvgPicture.asset("assets/images/focus_rectangle.svg"),
            left: 90,
            right: 90,
            //top: 60,
            //bottom: 60,
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: isSquared
                        ? EdgeInsets.only(
                            left: 0,
                            right: 0,
                            top: 0,
                          )
                        : EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 10,
                          ),
                    height: isSquared ? 60 : 50,
                    decoration: BoxDecoration(
                      color: kOpacity,
                      borderRadius: isSquared
                          ? BorderRadius.circular(0)
                          : BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: Platform
                                  .isIOS // here if the device is iOS perform the first icon, else the second.
                              ? FlatButton(
                                  child: isFlashActive
                                      ? Icon(
                                          Icons.flash_off,
                                          size: 30,
                                        )
                                      : Icon(
                                          Icons.flash_on,
                                          size: 30,
                                        ),
                                  onPressed: () {
                                    setState(
                                      () {
                                        isFlashActive = !isFlashActive;
                                      },
                                    );
                                  },
                                )
                              : FlatButton(
                                  child: isFlashActive
                                      ? Icon(
                                          Icons.flash_off,
                                          size: 30,
                                        )
                                      : Icon(
                                          Icons.flash_on,
                                          size: 30,
                                        ),
                                  onPressed: () {
                                    setState(
                                      () {
                                        isFlashActive = !isFlashActive;
                                      },
                                    );
                                  },
                                ),
                          //margin: EdgeInsets.only(top: 20),
                        ),
                        Container(
                          child: FlatButton(
                            child: isSquared
                                ? SvgPicture.asset(
                                    "assets/images/portrait_picture.svg")
                                : SvgPicture.asset(
                                    "assets/images/square_picture.svg"),
                            onPressed: () {
                              setState(
                                () {
                                  isSquared = !isSquared;
                                },
                              );
                            },
                          ),
                          //margin: EdgeInsets.only(top: 20, left: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Container(
                  height: isSquared ? 125 : 115,
                  margin: isSquared
                      ? EdgeInsets.only(
                          left: 0,
                          right: 0,
                          bottom: 0,
                        )
                      : EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                          bottom: 10.0,
                        ),
                  decoration: BoxDecoration(
                    color: kOpacity,
                    borderRadius: isSquared
                        ? BorderRadius.circular(0)
                        : BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _previewControlRowWidget(),
                      _captureControlRowWidget(),
                      _swapControlRowWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Transform.scale(
              scale: controller.value.aspectRatio / deviceRatio,
              child: AspectRatio(
                child: CameraPreview(controller),
                aspectRatio: controller.value.aspectRatio,
              ),
            );
          } else
            return Center(
              child: CircularProgressIndicator(),
            );
        });
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Container(
      child: IconButton(
        icon: SvgPicture.asset(
          "assets/images/picture_button.svg",
        ),
        iconSize: 66,
        color: Colors.red,
        onPressed: controller != null ? onTakePictureButtonPressed : null,
      ),
    );
  }

  /// Display the control bar with buttons to preview gallery images.
  Widget _previewControlRowWidget() {
    return Container(
      child: IconButton(
        icon: Icon(
          Icons.photo_size_select_actual,
        ),
        iconSize: 40,
        color: Colors.white,
        onPressed: controller != null ? onTakePictureButtonPressed : null,
      ),
    );
  }

  /// Display the control bar with buttons to Swap Camera.
  Widget _swapControlRowWidget() {
    return Container(
      child: IconButton(
        icon: Platform
                .isIOS // here if the device is iOS perform the first icon, else the second.
            ? Icon(
                IconData(62622,
                    fontFamily: CupertinoIcons.iconFont,
                    fontPackage: CupertinoIcons.iconFontPackage),
              )
            : Icon(
                Icons.switch_camera,
              ),
        iconSize: 40,
        color: Colors.white,
        onPressed: controller != null ? swapCamera : null,
      ),
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];
    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(
                getCameraLensIcon(cameraDescription.lensDirection),
              ),
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged: controller != null && controller.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }
    return Row(children: toggles);
  }

  void swapCamera() {
    if (cameras.length > 1) {
      selectedCamera++;
      if (selectedCamera == 2)
        selectedCamera = 0;
      else
        selectedCamera = 1;
      onNewCameraSelected(cameras.elementAt(selectedCamera));
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      //enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        //print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      //print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<String> takePicture() async {
    String filePath;
    if (!controller.value.isInitialized) {
      //print('Error: select a camera first.');
      return null;
    }

    try {
      filePath = join((await getApplicationDocumentsDirectory()).path,
          "${DateTime.now()}.jpg");
      await controller.takePicture(filePath);
    } catch (e) {
      print(e);
    }
    if (controller.value.isTakingPicture) {
      return null;
    }
    return filePath;
  }

  //backup
  // void onTakePictureButtonPressed() async {
  //   await takePicture().then((String filePath) {
  //     if (mounted) {
  //       setState(() {
  //         imagePath = filePath;
  //       });

  //       if (filePath != null) {
  //         print('Picture saved to $filePath');
  //       }
  //     }
  //   });
  // }

  void onTakePictureButtonPressed() async {
    await takePicture().then((String filePath) {
      try {
        GallerySaver.saveImage(filePath);
        Fluttertoast.showToast(
            msg: "Foto Catturata",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0);
      } catch (e) {
        Fluttertoast.showToast(
            msg: e,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    });
  }

  /// Display the thumbnail of the captured image or video.
  /*Widget _thumbnailWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            videoController == null && imagePath == null
                ? Container()
                : SizedBox(
                    child: (videoController == null)
                        ? Image.file(File(imagePath))
                        : Container(
                            child: Center(
                              child: AspectRatio(
                                  aspectRatio:
                                      videoController.value.size != null
                                          ? videoController.value.aspectRatio
                                          : 1.0,
                                  child: VideoPlayer(videoController)),
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink)),
                          ),
                    width: 64.0,
                    height: 64.0,
                  ),
          ],
        ),
      ),
    );
  }*/
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}
