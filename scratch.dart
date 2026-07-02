import 'package:livekit_client/livekit_client.dart'; void main() async { try { await Room().connect('https://speak.fusslab.ai', 'token'); } catch(e) { print(e); } }
