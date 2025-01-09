import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // To open links in the browser
import '../colors.dart';
import '../widgets/text.dart'; // CustomText widget
import '../widgets/tap_card.dart';
import '../globals.dart' as globals;

class ActivityOfTheDay extends StatefulWidget {
  final String videoLink;
  final String articleLink;

  const ActivityOfTheDay({
    super.key,
    required this.videoLink,
    required this.articleLink,
  });

  @override
  State<ActivityOfTheDay> createState() => _ActivityOfTheDayState();
}

class _ActivityOfTheDayState extends State<ActivityOfTheDay> {
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoLink) ?? "";
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          CustomText(
            text: "Activity of the Day",
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: CustomColors.darkGray,
            squash: true,
          ),
          const SizedBox(height: 5),
          const Divider(
            thickness: 1.0,
            color: CustomColors.lightGray,
          ),
          const SizedBox(height: 10),
          // YouTube Embed Player with Fullscreen Support
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController,
                showVideoProgressIndicator: true,
                progressColors: ProgressBarColors(
                  playedColor: CustomColors.primary,
                  handleColor: CustomColors.primary,
                ),
              ),
              builder: (context, player) {
                return Column(
                  children: [
                    player,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          // TapCard for Article Link
          TapCard(
            text: 'Health Benefits',
            imagePath: 'assets/images/link.png',
            onPressed: () => _launchURL(widget.articleLink), // Launch article link
            backgroundColor: CustomColors.offWhite,
            imageColor: Colors.white,
            subText: globals.newDay ? 'From clevelandclinic.org' : 'From artofliving.org',
          ),
        ],
      ),
    );
  }
}
