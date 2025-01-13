import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // To open links in the browser
import '../colors.dart';
import '../widgets/text.dart'; 
import '../widgets/tap_card.dart';
import '../globals.dart' as globals;

/// Displays an embedded YouTube video and a health article related to a randomly selected activity.
class ActivityOfTheDay extends StatefulWidget {
  final String videoLink; // Link to the YouTube video
  final String articleLink; // Link to the related article

  const ActivityOfTheDay({
    super.key,
    required this.videoLink,
    required this.articleLink,
  });

  @override
  State<ActivityOfTheDay> createState() => _ActivityOfTheDayState();
}

class _ActivityOfTheDayState extends State<ActivityOfTheDay> {
  late YoutubePlayerController _youtubeController; // Controller for YouTube player

  @override
  void initState() {
    super.initState();
    // Extract the YouTube video ID from the provided link
    final videoId = YoutubePlayer.convertUrlToId(widget.videoLink) ?? "";
    // Initialize the YouTube player controller
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false, // Do not play the video automatically
        mute: false, // Do not mute the video
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose(); // Dispose the YouTube player controller
    super.dispose();
  }

  /// Launches the provided URL in the device's default browser.
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Optionally handle the error, e.g., show a toast or log it
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0), // Add padding inside the container
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(15.0), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
        children: [
          // Title of the section
          CustomText(
            text: "Activity of the Day",
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: CustomColors.darkGray,
            squash: true,
          ),
          const SizedBox(height: 5), // Spacing between the title and the divider
          const Divider(
            thickness: 1.0,
            color: CustomColors.lightGray, // Divider color
          ),
          const SizedBox(height: 10), // Spacing after the divider
          // Embedded YouTube player
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners for the player
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController,
                showVideoProgressIndicator: true, // Show progress indicator
                progressColors: ProgressBarColors(
                  playedColor: CustomColors.primary, // Color for played portion
                  handleColor: CustomColors.primary, // Color for progress handle
                ),
              ),
              builder: (context, player) {
                return Column(
                  children: [
                    player, // Display the YouTube player
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 15), // Spacing before the article link
          // TapCard for the related article
          TapCard(
            text: 'Health Benefits', // Title for the link
            imagePath: 'assets/images/link.png', // Path to the link icon
            onPressed: () => _launchURL(widget.articleLink), // Launch the article link
            backgroundColor: CustomColors.offWhite, // Background color for the card
            imageColor: Colors.white, // Color for the icon
            subText: globals.newDay
                ? 'From clevelandclinic.org' // Subtext for a new day
                : 'From artofliving.org', // Subtext for other days
          ),
        ],
      ),
    );
  }
}
