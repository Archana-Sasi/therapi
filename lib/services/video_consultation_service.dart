import 'package:url_launcher/url_launcher.dart';

class VideoConsultationService {
  
  /// Launches a Jitsi Meet meeting with the given room name
  Future<void> launchMeeting(String roomName) async {
    final cleanRoomName = roomName.trim().replaceAll(' ', '_');
    // The #config.disableDeepLinking=true flag forces Jitsi to open in the browser 
    // without asking the user to download the Jitsi app.
    final url = Uri.parse('https://meet.jit.si/$cleanRoomName#config.disableDeepLinking=true');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching meeting: $e');
      rethrow;
    }
  }
}
