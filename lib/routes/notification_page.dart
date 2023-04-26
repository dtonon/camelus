import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';

import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: const Text('work in progress',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}