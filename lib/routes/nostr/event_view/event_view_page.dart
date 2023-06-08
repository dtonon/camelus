import 'dart:async';
import 'dart:developer';

import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/models/tweet_control.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EventViewPage extends ConsumerStatefulWidget {
  late String eventId;

  EventViewPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventViewPageState createState() => _EventViewPageState();
}

class _EventViewPageState extends ConsumerState<EventViewPage> {
  late NostrService _nostrService;
  final StreamController<List<Tweet>> _streamController =
      StreamController<List<Tweet>>.broadcast();
  late StreamSubscription _streamSubscription;

  String requestId = Helpers().getRandomString(4);

  late Tweet rootTweet;

  void _requestEvents() {
    _nostrService.requestEvents(
        eventIds: [widget.eventId],
        requestId: requestId,
        //limit: 30,
        streamController: _streamController);
  }

  void _closeSubscription() {
    _nostrService.closeSubscription("event-$requestId");
  }

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    _initNostrService();
    _requestEvents();

    _streamSubscription = _streamController.stream.listen((event) {
      log("EVENT_PAGE: got smth ${event[0].replies.length}");
    });
  }

  @override
  void dispose() {
    _closeSubscription();
    _streamSubscription.cancel();
    _streamController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: const Text("thread"),
      ),
      body: StreamBuilder<List<Tweet>>(
          stream: _streamController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              rootTweet = snapshot.data![0];

              // silver list view
              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        TweetCard(
                          tweet: rootTweet,
                        ),
                        for (var tweet in rootTweet.replies)
                          if (tweet.replies.length > 0)
                            Container(
                              // move to right
                              //color: Colors.red,
                              margin: const EdgeInsets.only(left: 0),
                              child: Column(
                                children: [
                                  TweetCard(
                                    tweet: tweet,
                                    tweetControl: TweetControl(
                                      showInReplyTo: false,
                                      showVerticalLineBottom: true,
                                    ),
                                  ),

                                  // for loop with index
                                  for (var i = 0; i < tweet.replies.length; i++)
                                    // is last element
                                    if (i == tweet.replies.length - 1)
                                      Column(
                                        children: [
                                          TweetCard(
                                            tweet: tweet.replies[i],
                                            tweetControl: TweetControl(
                                              showInReplyTo: false,
                                              showVerticalLineTop: true,
                                              showVerticalLineBottom: tweet
                                                      .replies[i]
                                                      .replies
                                                      .length >
                                                  0,
                                            ),
                                          ),
                                          for (var j = 0;
                                              j <
                                                  tweet.replies[i].replies
                                                      .length;
                                              j++)
                                            TweetCard(
                                              tweet:
                                                  tweet.replies[i].replies[j],
                                              tweetControl: TweetControl(
                                                showInReplyTo: false,
                                                showVerticalLineTop: true,
                                                showVerticalLineBottom:
                                                    (j - 1 ==
                                                        tweet.replies[i].replies
                                                            .length),
                                              ),
                                            )
                                        ],
                                      )
                                    else
                                      // is not last element

                                      TweetCard(
                                        tweet: tweet.replies[i],
                                        tweetControl: TweetControl(
                                          showInReplyTo: false,
                                          showVerticalLineTop: true,
                                          showVerticalLineBottom: true,
                                        ),
                                      )
                                ],
                              ),
                            )
                          else
                            TweetCard(
                              tweet: tweet,
                              tweetControl: TweetControl(
                                showInReplyTo: false,
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}
