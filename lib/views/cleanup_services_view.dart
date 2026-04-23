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

  Widget buildServiceCard({
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: color,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildInfo(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget buildLink(String text, String url) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(url),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 127, 180, 222),
          foregroundColor: Colors.black,
          elevation: 3,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleanup Services"),
        backgroundColor: const Color.fromARGB(255, 127, 180, 222),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Duluth Fire Department
            buildServiceCard(
              color: Colors.red.shade100,
              title: "Duluth Fire Department",
              children: [
                buildLink(
                  "Visit Website",
                  "https://duluthmn.gov/human-resources/safety-training/",
                ),
                buildInfo("Business Line: 218-730-4394"),
                buildInfo("Life Safety: 218-730-5000 (Option 2)"),
                buildInfo("Email: lifesafety@duluthmn.gov"),
                buildInfo("Emergency: 9-1-1"),
              ],
            ),

            // Harm Reduction Sisters
            buildServiceCard(
              color: Colors.orange.shade100,
              title: "Harm Reduction Sisters",
              children: [
                buildLink(
                  "Visit Website",
                  "https://harmreductionsisters.org/",
                ),
                buildInfo("Damiano Center (Duluth, MN):"),
                buildInfo("206 W 4th St, Duluth, MN 55806"),
                buildInfo("Mon, Tue, Wed, Fri: 9am - 3pm"),
                buildInfo("Thu: 11:30am - 3pm"),
                buildInfo(""),
                buildInfo("Lakeview Behavioral Health (Hibbing, MN):"),
                buildInfo("2729 E Beltline, Hibbing, MN 55746"),
                buildInfo("Wed & Fri: 12pm - 4pm"),
                buildInfo(""),
                buildInfo("HDC Outreach Center (Cloquet, MN):"),
                buildInfo("24 N 10th St, Cloquet, MN 55720"),
                buildInfo("Thu: 12pm - 2pm"),
                buildInfo(""),
                buildInfo("Lakeview Behavioral Health (Grand Rapids, MN):"),
                buildInfo("516 S Pokegama Ave, Grand Rapids, MN 55744"),
                buildInfo("Fri: 12pm - 4:30pm"),
              ],
            ),

            // RAAN
            buildServiceCard(
              color: Colors.blue.shade100,
              title: "Rural AIDS Action Network (RAAN)",
              children: [
                buildLink(
                  "Visit Website",
                  "https://raan.org/programs-services/ssps/",
                ),
                buildInfo("31 W 1st St, Duluth, MN 55802"),
                buildInfo("Phone: 218-481-7225"),
                buildInfo(""),
                buildInfo("Syringe Service Program (SSP)"),
                buildInfo("Mon-Fri: 9am - 4pm"),
                buildInfo("First Saturday of the month: 12pm - 4pm"),
              ],
            ),

            // Clean & Safe Team
            buildServiceCard(
              color: Colors.green.shade100,
              title: "Clean & Safe Team",
              children: [
                buildLink(
                  "Visit Website",
                  "https://www.downtownduluth.com/clean-safe-team/",
                ),
                buildInfo("5 W 1st St, Duluth, MN 55802"),
                buildInfo("General Contact: 218-390-8899 / 218-727-8317"),
                buildInfo("Workshops: 218-727-8549"),
                buildInfo("Email: bjlind@downtownduluth.com"),
                buildInfo(""),
                buildInfo("Outreach Specialist:"),
                buildInfo("Nathan Kesti: 218-340-8274"),
                buildInfo("nkesti@blockbyblock.com"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
