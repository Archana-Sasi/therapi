import 'package:url_launcher/url_launcher.dart';

class VideoConsultationService {
  
  /// Launches a video consultation meeting URL (e.g., Google Meet, Zoom)
  Future<void> launchMeetingUrl(String meetingLink) async {
    if (meetingLink.isEmpty) throw 'Meeting link cannot be empty';
    
    String urlStr = meetingLink.trim();
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }

    final url = Uri.parse(urlStr);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlStr';
      }
    } catch (e) {
      print('Error launching meeting: $e');
      rethrow;
    }
  }
}
