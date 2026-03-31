import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyView extends StatelessWidget {
  const SafetyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Safety Info section
            
            Text(
              '24/7 Sharps Hotline Number: 218-730-4001',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
           
            const SizedBox(height: 8),
            Text(
              'Follow these essential safety guidelines when encountering discarded needles. Your safety is our priority.',
            ),
            const SizedBox(height: 16),
            _buildSafetyCard(
              icon: Icons.pan_tool_alt,
              color: Colors.red.shade100,
              title: 'Never Touch with Bare Hands',
              content:
                  'Always wear thick gloves or use tools like tongs or pliers when handling needles.',
            ),
            _buildSafetyCard(
              icon: Icons.block,
              color: Colors.orange.shade100,
              title: 'Do Not Recap Needles',
              content:
                  'Never attempt to recap, bend, or break a needle. This increases the risk of injury.',
            ),
            _buildSafetyCard(
              icon: Icons.delete,
              color: Colors.green.shade100,
              title: 'Use Sharps Container',
              content:
                  'Place needles in an approved sharps disposal container. If unavailable, use a hard plastic container with a screw-on lid.',
            ),
            _buildSafetyCard(
              icon: Icons.trending_flat,
              color: Colors.blue.shade100,
              title: 'Point Away from Body',
              content:
                  'Always point the needle away from yourself and others when moving or disposing of it.',
            ),
            _buildSafetyCard(
              icon: Icons.clean_hands,
              color: Colors.teal.shade100,
              title: 'Wash Thoroughly',
              content:
                  'Wash your hands with soap and water immediately after handling any materials near needles.',
            ),
            _buildSafetyCard(
              icon: Icons.warning,
              color: Colors.purple.shade100,
              title: "If You're Injured",
              content:
                  '• Wash the area immediately with soap and water\n'
                  '• Seek medical attention right away\n'
                  '• Report the incident to local health authorities\n'
                  '• Consider getting tested for infectious diseases',
            ),

            const SizedBox(height: 24),

            //Legal Information section
            Text(
              'Know the Law (Minnesota)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Understanding local laws can help you act confidently and responsibly when handling discarded needles.',
            ),
            const SizedBox(height: 16),
            _buildSafetyCard(
              icon: Icons.gavel,
              color: Colors.indigo.shade100,
              title: 'Legal Standing',
              content:
                  'As of August 1, 2023, Minnesota law legalized the possession of all drug paraphernalia, including used hypodermic needles. '
                  'The possession of syringes, even those containing residual amounts of controlled substances, is no longer a crime.',
            ),

            _buildSafetyCard(
              icon: Icons.inventory_2,
              color: Colors.amber.shade100,
              title: 'Safe Transportation',
              content:
                  'While carrying needles is legal, they should be stored securely in a puncture-resistant, leakproof container such as a hard plastic bottle or sharps container.',
            ),
            _buildSafetyCard(
              icon: Icons.public,
              color: Colors.cyan.shade100,
              title: 'Public Safety Responsibility',
              content:
                  'Although possession is not illegal, disposing of needles in public trash or leaving them in public spaces is strongly discouraged. '
                  'Use designated disposal options whenever possible to avoid public health risks.',
            ),

            const SizedBox(height: 16),
            Text(
              'Sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildLink(
              'Minnesota Paraphernalia Law Update',
              'https://www.networkforphl.org/news-insights/repeal-of-paraphernalia-laws-minnesota-leads-the-way/#:~:text=these%20harmful%20laws.-,Minnesota%20recently%20became%20the%20first%20state%20to%20do%20so.,law%20made%20the%20following%20changes:',
            ),

            _buildLink(
              'Minnesota Needle Disposal Guidelines (PDF)',
              'https://www.pca.state.mn.us/sites/default/files/w-hhw4-67.pdf#:~:text=Used%20household%20needles%2C%20lancets%2C%20and%20syringes%20(collectively,destroying%20them%20at%20home%20using%20specialized%20devices.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLink(String text, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchUrl(url),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}
