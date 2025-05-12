import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/firebase_options.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/splash_screen.dart';
import 'package:studyflow_v2/states/flashcard_state.dart';
import 'package:studyflow_v2/states/group_state.dart';
import 'package:studyflow_v2/states/home_state.dart';
import 'package:studyflow_v2/states/note_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeState>(
          create: (_) => HomeState(),
        ),
        ChangeNotifierProvider<NoteState>(
          create: (_) => NoteState(),
        ),
        ChangeNotifierProvider<FlashcardState>(
          create: (_) => FlashcardState(),
        ),
        ChangeNotifierProvider<GroupState>(
          create: (_) => GroupState(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: primaryColor,
            scaffoldBackgroundColor: primaryColor,
            appBarTheme: AppBarTheme(
              foregroundColor: textColor,
            )),
        home: SplashScreen(),
      ),
    );
  }
}
