import 'package:brewmaster/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/providers/message_provider.dart';
import 'presentation/screens/messaging/chat_screen.dart';
import 'domain/models/conversation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    /// Dummy conversation just for testing UI
    final conversation = Conversation(
      conversationId: "demo_conversation_123",
      participantIds: ["user1", "user2"],
      lastMessage: null,
      unreadCount: 0,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MessageProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat Demo',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),

        /// Open ChatScreen directly
        home: ChatScreen(conversation: conversation),
      ),
    );
  }
}