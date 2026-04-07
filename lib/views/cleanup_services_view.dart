import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CleanupServicesView extends StatelessWidget {
  const CleanupServicesView({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildInfo(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleanup Services"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
//not sure if theres anything else we want to add or  format differently here
            // Duluth Fire Department
            buildSectionTitle("Duluth Fire Department"),
            buildInfo("Business Line: 218-730-4394"),
            buildInfo("Life Safety: 218-730-5000 (Option 2)"),
            buildInfo("Email: lifesafety@duluthmn.gov"),
            buildInfo("Emergency: 9-1-1"),

            const Divider(),



            // Harm Reduction Sisters
            buildSectionTitle("Harm Reduction Sisters"),
            TextButton(
              onPressed: () => _launchUrl("https://harmreductionsisters.org/"),
              child: const Text("Visit Website"),
            ),
            buildInfo("Damiano Center (Duluth, MN):"),
            buildInfo("Mon, Tue, Wed, Fri: 9am - 3pm"),
            buildInfo("Thu: 11:30am - 3pm"),

            buildInfo("\nLakeview Behavioral Health (Hibbing, MN):"),
            buildInfo("Wed & Fri: 12pm - 4pm"),

            buildInfo("\nHDC Outreach Center (Cloquet, MN):"),
            buildInfo("Thu: 12pm - 2pm"),

            buildInfo("\nLakeview Behavioral Health (Grand Rapids, MN):"),
            buildInfo("Fri: 12pm - 4:30pm"),

            const Divider(),



            // RAAN
            buildSectionTitle("Rural AIDS Action Network (RAAN)"),
            buildInfo("31 W 1st St, Duluth, MN 55802"),
            buildInfo("Phone: 218-481-7225"),

            const Divider(),



            // Clean & Safe 
            buildSectionTitle("Clean & Safe Team"),
            TextButton(
              onPressed: () => _launchUrl(
                  "https://www.downtownduluth.com/clean-safe-team/"),
              child: const Text("Visit Website"),
            ),
            buildInfo("General Contact: 218-390-8899 / 218-727-8317"),
            buildInfo("Workshops: 218-727-8549"),
            buildInfo("Email: bjlind@downtownduluth.com"),
            buildInfo("Outreach Specialist:"),
            buildInfo("Nathan Kesti: 218-340-8274"),
            buildInfo("nkesti@blockbyblock.com"),
          ],
        ),
      ),
    );
  }
}
