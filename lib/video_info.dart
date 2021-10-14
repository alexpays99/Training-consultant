import 'dart:convert';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'colors.dart' as color;

class VideoInfo extends StatefulWidget {
  VideoInfo({Key? key}) : super(key: key);

  @override
  _VideoInfoState createState() => _VideoInfoState();
}

class _VideoInfoState extends State<VideoInfo> {
  List videoinfo = []; // список видео
  bool _playArea = false; // определяет является ли зона просмотра видео доступной.
  bool _isPlaying = false;
  bool _disposed = false;
  int _isPlayingIndex = -1;
  VideoPlayerController? _controller; // глобальнай контроллер для видео

  //декодирует videoinfo.json и помещается в список videoinfo.
  _initData() async {
    await DefaultAssetBundle.of(context)
        .loadString("json/videoinfo.json")
        .then((value) {
      // когда билд уже загрузился, информация из json файла ещё не подгрузился.
      //из-за этого после перезапуска информация из джейсона не появлялась, только после перерисовки экрана.
      // чтобы информация из json подтягивалась после перезапуска, нужно поместить  videoinfo в setState.
      // когда он помешён в  setState, и в нём есть информация, билд перерисовывает экран и на пустом месте уже появляются изображения.
      setState(() {
        videoinfo = json.decode(value);
      });
    });
  }

  var _onUpdateControllerTime; // обновление времени контроллера

  void _onControllerUpdate () async {
    if(_disposed){
      return;
    }

    _onUpdateControllerTime = 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    if(_onUpdateControllerTime > now) {
      return;
    }

    _onUpdateControllerTime = now+500;

    final controller = _controller;
    if(controller == null) {
      debugPrint("controller is null");
      return;
    }

    if(!controller.value.isInitialized) {
      debugPrint("controller can't be initialized");
      return;
    }

    final playing = controller.value.isPlaying;
    _isPlaying = playing;
    
  }

  // инициализация видео
  _initializeVideo(int index) {
    final controller = VideoPlayerController.network(videoinfo[index]["videoUrl"]); //локальный контроллер для видео
    final old = _controller; // контроллер из предыдущего видео
    _controller = controller; //помещаем локальный контроллер в глобальный
    if(old != null) {
      old.removeListener(_onControllerUpdate); // удаляем слушателя 
      old.pause();
    }
    setState(() {
      // вызываеться чтобы перерисовать виджет и вызвать build виджета, ктогда локальный контроллер инициальзирован
    });
    _controller?..initialize().then((_) {
        old?.dispose(); // если старый контроллер существует, то он удаляется
        _isPlayingIndex = index;
        controller.addListener(_onControllerUpdate);
        // инициализация видео
        controller.play(); // локальный контроллер запускает видео.
        setState(() {
          //задаем состояние чтобы убедиться что перерисовка состоялась после запуска видео.
        });
      });
  }

  // при нажатии на видео происзодит инициализация видео
  _onTapVideo(int index) {
    _initializeVideo(index);
  }

  //возвращает список контейнеров с видео и названием видео
  _listView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      itemCount: videoinfo.length,
      itemBuilder: (_, index) {
        return GestureDetector(
          onTap: () {
            _onTapVideo(index);
            debugPrint(index.toString());
            setState(() {
              if (_playArea == false) {
                _playArea = true;
              }
            });
          },
          child: _buildCar(index),
        );
      },
    );
  }

  // запуск видео
  Widget _playView(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoPlayer(controller),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9, 
        child: Center(
          child: Text('Preparing...', style: TextStyle(fontSize: 20, color: Colors.white),)
        )
      );
    }
  }

  Widget _controlView (BuildContext context) {
    final noMute = (_controller?.value?.volume??0 > 0); // если контроллер существует, оттуда извлекается значение -> если значение есть, оттуда получается звук -> если звук есть, мы получаем звук и если звука нет, мы получаем 0.

    return Container(
      height: 40,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(bottom: 5),
      color: color.AppColor.gradientSecond,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0.0, 0.0),
                      blurRadius: 4.0,
                      color: Color.fromARGB(50, 0, 0, 0),
                    )
                  ]
                ),
                child: Icon(Icons.volume_up, color: Colors.white,),
              ),
            ),
            onTap: () {
              if(noMute == true) {
                _controller?.setVolume(0);
              }
              else {
                _controller?.setVolume(1);
              }
              setState(() {
                
              });
            },
          ),
          FlatButton(
            onPressed: () async { //при нажатии воспроизводится предыдущее видео
              final index = _isPlayingIndex - 1; // индекс предыдущего видео
              if(index >= 0 && videoinfo.length >= 0)  // потому что первое видео всегда 0 и не может быть -1
              {
                _initializeVideo(index);
              }
              else{
                Get.snackbar( 
                  "Video", "",
                  snackPosition: SnackPosition.BOTTOM,
                  icon: Icon(Icons.face, size: 30, color: Colors.white),
                  backgroundColor: color.AppColor.gradientSecond,
                  colorText: Colors.white,
                  messageText: Text("No videos ahead", style: TextStyle(fontSize: 20, color: Colors.white),)
                );
              }
            },
            child: Icon(Icons.fast_rewind, size: 36, color: Colors.white,),
          ),
          FlatButton(
            onPressed: () async {
              if(_isPlaying) {
                setState(() {
                  _isPlaying = false;
                });
                _controller?.pause();
              }
              else {
                setState(() {
                  _isPlaying = true;
                });
                _controller?.play();
              }
            },
            child: Icon(_isPlaying? Icons.pause: Icons.play_arrow, size: 36, color: Colors.white,),
          ),
          FlatButton(
            onPressed: () async {
              final index = _isPlayingIndex + 1; // индекс следующего видео
              if(index <= videoinfo.length - 1) 
              {
                _initializeVideo(index);
              }
              else{
                Get.snackbar( 
                  "Video", "",
                  snackPosition: SnackPosition.BOTTOM,
                  icon: Icon(Icons.face, size: 30, color: Colors.white),
                  backgroundColor: color.AppColor.gradientSecond,
                  colorText: Colors.white,
                  messageText: Text("You have fnished watching all the videos. Congrats!", style: TextStyle(fontSize: 20, color: Colors.white),)
                );
                
              }
            },
            child: Icon(Icons.fast_forward, size: 36, color: Colors.white,),
          )
        ],
      ),
    );
  }

  // возвращает контейнер с видео, и названием видео
  _buildCar(int index) {
    return Container(
      height: 135,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(videoinfo[index]["thumbnail"]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoinfo[index]["title"],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      videoinfo[index]["time"],
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(
            height: 18,
          ),
          Row(
            children: [
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFFeaeefc),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '15s rest',
                    style: TextStyle(
                      color: Color(0xFF839fed),
                    ),
                  ),
                ),
              ),
              //реализация пунктирных линий
              Row(
                children: [
                  for (int i = 0; i < 70; i++)
                    i.isEven
                        ? Container(
                            width: 3,
                            height: 1,
                            decoration: BoxDecoration(
                              color: Color(0xFF839fed),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : Container(
                            width: 3,
                            height: 1,
                            color: Colors.white,
                          )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.pause(); // поставить видео на паузу
    _controller?.dispose(); // очистить, если контроллер существует
    _controller = null; // ставим null и убеждаемся что контроллер был удален
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _playArea == false
            ? BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                    color.AppColor.gradientFirst.withOpacity(0.9),
                    color.AppColor.gradientSecond,
                  ],
                    begin: const FractionalOffset(0.0, 0.4),
                    end: Alignment.topRight))
            : BoxDecoration(color: color.AppColor.gradientSecond),
        child: Column(
          children: [
            _playArea == false
                ? Container(
                    padding:
                        const EdgeInsets.only(top: 70, left: 30, right: 30),
                    width: MediaQuery.of(context).size.width,
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.arrow_back_ios,
                                size: 20,
                                color: color.AppColor.secondPageIconColor,
                              ),
                            ),
                            Expanded(child: Container()),
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: color.AppColor.secondPageIconColor,
                            )
                          ],
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          'Legs Toning',
                          style: TextStyle(
                              fontSize: 25,
                              color: color.AppColor.secondPageTitleColor),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'and Glutes Workout',
                          style: TextStyle(
                              fontSize: 25,
                              color: color.AppColor.secondPageTitleColor),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 90,
                              height: 30,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                      colors: [
                                        color.AppColor
                                            .secondPageContainerGradient1stColor
                                            .withOpacity(0.4),
                                        color.AppColor
                                            .secondPageContainerGradient2ndColor
                                            .withOpacity(0.4),
                                      ],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 20,
                                    color: color.AppColor.secondPageIconColor,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    '68 min',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            color.AppColor.secondPageIconColor),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Container(
                              width: 240,
                              height: 30,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                      colors: [
                                        color.AppColor
                                            .secondPageContainerGradient1stColor
                                            .withOpacity(0.4),
                                        color.AppColor
                                            .secondPageContainerGradient2ndColor
                                            .withOpacity(0.4),
                                      ],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.handyman_outlined,
                                    size: 20,
                                    color: color.AppColor.secondPageIconColor,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    'Resistena band, kettebell',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            color.AppColor.secondPageIconColor),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          padding: const EdgeInsets.only(
                              top: 50, left: 30, right: 30),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back_ios,
                                    size: 20,
                                    color:
                                        color.AppColor.secondPageTopIconColor),
                              ),
                              Expanded(child: Container()),
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: color.AppColor.secondPageTopIconColor,
                              )
                            ],
                          ),
                        ),
                        _playView(context),// отображает видео
                        _controlView(context), // отображает панель контроля видео (пауза, дорожка и т д)
                      ],
                    ),
                  ),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(70))),
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                        ),
                        Text(
                          'Circuit 1 : Legs Toning',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color.AppColor.circuitsColor),
                        ),
                        Expanded(child: Container()),
                        Row(
                          children: [
                            Icon(
                              Icons.loop,
                              size: 20,
                              color: color.AppColor.loopColor,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              '3 sets',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: color.AppColor.setsColor),
                            )
                          ],
                        ),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: _listView(),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
