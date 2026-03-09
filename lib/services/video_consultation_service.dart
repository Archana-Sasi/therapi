import 'package:url_launcher/url_launcher.dart';

class VideoConsultationService {
  
  /// Launches a Jitsi Meet meeting with the given room name
  Future<void> launchMeeting(String roomName) async {
    final cleanRoomName = roomName.trim().replaceAll(' ', '_');
    final url = Uri.parse('https://meet.jit.si/$cleanRoomName');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching meeting: $e');
      rethrow;
    }
  }
}
