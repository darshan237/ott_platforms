// lib/ui/pages/shows/show_page.dart
import 'package:dd_box/blocs/show_bloc/show_bloc.dart';
import 'package:dd_box/ui/pages/shows/video_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowPage extends StatefulWidget {
  const ShowPage({super.key});

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {
  late PageController _pageController;

  final List<String> videoUrls = [
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F1.mp4?alt=media&token=02fbcf36-7811-4c54-9f64-7fcda022873c",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F2.mp4?alt=media&token=e727809e-c951-418f-93ea-1c45c8ff4193",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F3.mp4?alt=media&token=7c0bb56d-82d1-4b78-86a7-0372aa81baf5",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F4.mp4?alt=media&token=638052e4-052f-4a37-ad80-f5e5d7ec5327",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F5.mp4?alt=media&token=51d7ec54-060b-4765-8f47-f297b76cf71a",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F6.mp4?alt=media&token=dc910038-4940-4b2d-b7d9-07a87ca4dea0",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F7.mp4?alt=media&token=1dbc8191-78a6-43ec-a29b-dfb55995972f",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F8.mp4?alt=media&token=780a03c9-215f-435a-b57a-040e2d5655dc",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F9.mp4?alt=media&token=17be6ef0-e8e2-4c7f-ad47-979b8c579c09",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F10.mp4?alt=media&token=078a35b2-0621-477b-863e-879a0855d985",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F11.mp4?alt=media&token=4a5d6351-9a8d-462f-8a15-aa8ab6639661",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F12.mp4?alt=media&token=0f9493b0-beb8-4d5b-9a24-284b27768eae",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F13.mp4?alt=media&token=4086ade8-9f7e-40b6-85f0-4ec59d962e75",
    "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F14.mp4?alt=media&token=52918ffe-a3a7-4fcc-a950-e0f548a13787",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    final bloc = BlocProvider.of<ShowBloc>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bloc.add(LoadVideos(videoUrls));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    final bloc = BlocProvider.of<ShowBloc>(context);
    bloc.add(DisposeAll());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ShowBloc>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<ShowBloc, ShowState>(
          builder: (context, state) {
            if (state.loading && state.urls.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error) {
              return const Center(child: Text("Failed to load videos", style: TextStyle(color: Colors.white)));
            }
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              pageSnapping: true,
              itemCount: state.urls.length,
              onPageChanged: (index) {
                if (index != bloc.state.currentIndex) {
                  bloc.add(PageChanged(index));
                }
              },
              itemBuilder: (context, index) {
                return VideoItem(index: index, videoUrls: state.urls);
              },
            );
          },
        ),
      ),
    );
  }
}




// import 'package:dd_box/blocs/show_bloc/show_bloc.dart';
// import 'package:dd_box/ui/pages/shows/video_item.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
//
// class ShowPage extends StatefulWidget {
//   const ShowPage({super.key});
//
//   @override
//   State<ShowPage> createState() => _ShowPageState();
// }
//
// class _ShowPageState extends State<ShowPage> {
//   late PageController _pageController;
//
//   final List<String> videoUrls = [
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F1.mp4?alt=media&token=02fbcf36-7811-4c54-9f64-7fcda022873c",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F2.mp4?alt=media&token=e727809e-c951-418f-93ea-1c45c8ff4193",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F3.mp4?alt=media&token=7c0bb56d-82d1-4b78-86a7-0372aa81baf5",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F4.mp4?alt=media&token=638052e4-052f-4a37-ad80-f5e5d7ec5327",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F5.mp4?alt=media&token=51d7ec54-060b-4765-8f47-f297b76cf71a",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F6.mp4?alt=media&token=dc910038-4940-4b2d-b7d9-07a87ca4dea0",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F7.mp4?alt=media&token=1dbc8191-78a6-43ec-a29b-dfb55995972f",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F8.mp4?alt=media&token=780a03c9-215f-435a-b57a-040e2d5655dc",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F9.mp4?alt=media&token=17be6ef0-e8e2-4c7f-ad47-979b8c579c09",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F10.mp4?alt=media&token=078a35b2-0621-477b-863e-879a0855d985",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F11.mp4?alt=media&token=4a5d6351-9a8d-462f-8a15-aa8ab6639661",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F12.mp4?alt=media&token=0f9493b0-beb8-4d5b-9a24-284b27768eae",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F13.mp4?alt=media&token=4086ade8-9f7e-40b6-85f0-4ec59d962e75",
//     "https://firebasestorage.googleapis.com/v0/b/short-drama-1-dffff.firebasestorage.app/o/AI%20Billionaire%2F14.mp4?alt=media&token=52918ffe-a3a7-4fcc-a950-e0f548a13787",
//   ];
//
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: 0);
//     final bloc = BlocProvider.of<ShowBloc>(context);
//     // Delay load until after build to make sure bloc is provided (safe)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       bloc.add(LoadVideos(videoUrls));
//     });
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     final bloc = BlocProvider.of<ShowBloc>(context);
//     bloc.add(DisposeAll());
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bloc = BlocProvider.of<ShowBloc>(context);
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: BlocBuilder<ShowBloc, ShowState>(
//           builder: (context, state) {
//             if (state.loading && state.urls.isEmpty) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (state.error) {
//               return const Center(child: Text("Failed to load videos", style: TextStyle(color: Colors.white)));
//             }
//             return PageView.builder(
//               controller: _pageController,
//               scrollDirection: Axis.vertical,
//               itemCount: state.urls.length,
//               onPageChanged: (index) => bloc.add(PageChanged(index)),
//               itemBuilder: (context, index) {
//                 return VideoItem(index: index, videoUrls: state.urls);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
