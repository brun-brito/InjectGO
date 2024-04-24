import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.asset('assets/videos/video_merz.mp4');
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: 9 / 16, 
      autoPlay: false,
      looping: false,
      autoInitialize: true,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chewie Video Player in Carousel"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
          height: 200, 
          child: PageView.builder(
            controller: _pageController,
            itemCount: 2,  
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (_, index) {
                  return index == 0 ? buildFirstPage() : buildSecondPage();
            },
          ),
        ),
            SizedBox(height: 5),
            buildPageIndicator(),
            SizedBox(height: 20),
           ],
        ),
      ),
    );
  }

  Widget buildFirstPage() {
    return Container(
      padding: const EdgeInsets.only(left: 15),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 236, 63, 121),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Sua jornada\ncomeça aqui.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Apenas escolha onde\ne quando',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Image.asset(
              'assets/images/maquina.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

Widget buildSecondPage() {
  return Padding(
    padding: EdgeInsets.only(left: 70, right: 70), // Ajuste estes valores conforme necessário
    child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized ? Chewie(
      controller: _chewieController!,
    ) : Center(child: CircularProgressIndicator()),
  );
}

  Widget buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(2, (index) => buildIndicator(index == _currentPage)),
    );
  }

  Widget buildIndicator(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey,
      ),
    );
  }

}
