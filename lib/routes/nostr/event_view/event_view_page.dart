import 'dart:async';
import 'dart:developer';

import 'package:camelus/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/scroll_controller/retainable_scroll_controller.dart';
import 'package:camelus/services/nostr/feeds/event_feed.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class EventViewPage extends ConsumerStatefulWidget {
  final String _rootId;
  final String? _scrollIntoView;
  final Relays _relays;

  EventViewPage({Key? key, required String rootId, String? scrollIntoView})
      : _scrollIntoView = scrollIntoView,
        _rootId = rootId,
        _relays = RelaysInjector().relays,
        super(key: key);

  @override
  _EventViewPageState createState() => _EventViewPageState();
}

class _EventViewPageState extends ConsumerState<EventViewPage> {
  late AppDatabase db;
  late EventFeed _eventFeed;
  late final RetainableScrollController _scrollControllerFeed =
      RetainableScrollController();

  final Completer<void> _servicesReady = Completer<void>();

  Future<void> _initDb() async {
    db = await ref.read(databaseProvider.future);
    return;
  }

  Future<void> _initSequence() async {
    await _initDb();

    _eventFeed = EventFeed(db, widget._rootId, widget._relays);
    await _eventFeed.feedRdy;
    _servicesReady.complete();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _eventFeed.cleanup();
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
      body: FutureBuilder(
        future: _servicesReady.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Palette.white,
            ));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return RefreshIndicatorNoNeed(
              onRefresh: () {
                return Future.delayed(const Duration(milliseconds: 0));
              },
              child: StreamBuilder(
                stream: _eventFeed.feedStream,
                initialData: _eventFeed.feed,
                builder: (BuildContext context,
                    AsyncSnapshot<List<NostrNote>> snapshot) {
                  if (snapshot.hasData) {
                    var notes = snapshot.data!;
                    if (notes.isEmpty) {
                      return const Center(
                        child: Text("no notes found",
                            style:
                                TextStyle(fontSize: 20, color: Palette.white)),
                      );
                    }
                    return _buildScrollView(notes);
                  }
                  if (snapshot.hasError) {
                    return Center(
                        //button
                        child: ElevatedButton(
                      onPressed: () {},
                      child: Text(snapshot.error.toString(),
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                    ));
                  }
                  return const Text("waiting for stream trigger ",
                      style: TextStyle(fontSize: 20));
                },
              ),
            );
          }
          return const Center(child: Text('Error'));
        },
      ),
    );
  }

  CustomScrollView _buildScrollView(List<NostrNote> notes) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _scrollControllerFeed,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return _buildReplyTree(notes, widget._rootId);
            },
            childCount: 1,
          ),
        ),
      ],
    );
  }

  // return the root
  NoteCardContainer _buildReplyTree(List<NostrNote> notes, String rootId) {
    var workingList = [...notes];
    var rootNote = workingList.firstWhere(
      (element) => element.id == rootId,
      orElse: () => NostrNote.empty(id: rootId),
    );
    // remove the root from the working list
    try {
      workingList.removeWhere((element) => element.id == rootId);
    } catch (e) {
      log("root not in tree");
    }

    // get author first level replies
    List<NostrNote> authorFirstLevelSelfReplies = workingList
        .where((element) =>
            element.getRootReply?.value == rootId &&
            element.pubkey == rootNote.pubkey &&
            element.getDirectReply == null)
        .toList();

    // get root level replies and build containers
    List<NostrNote> rootLevelReplies =
        workingList.where((element) => element.getDirectReply == null).toList();

    // remove root level replies from working list
    for (var element in rootLevelReplies) {
      workingList.removeWhere((e) => e.id == element.id);
    }

    List<NoteCardContainer> rootLevelRepliesContainers = rootLevelReplies
        .map((e) => NoteCardContainer(
              notes: [e],
            ))
        .toList();

    // add remaining replies to containers
    var foundNotes = <NostrNote>[];
    for (var container in rootLevelRepliesContainers) {
      for (var note in workingList) {
        for (var tag in note.getTagEvents) {
          if (container.notes.map((e) => e.id).contains(tag.value)) {
            container.notes.add(note);
            // remove note from working list
            foundNotes.add(note);
          } else {}
        }
      }
    }
    // remove found notes from working list
    for (var note in foundNotes) {
      workingList.removeWhere((e) => e.id == note.id);
    }

    log("unresolved notes: ${workingList.length}");

    // add unresolved notes to root level replies with missing Note

    for (var note in workingList) {
      rootLevelRepliesContainers.add(NoteCardContainer(
        notes: [NostrNote.empty(id: note.getDirectReply?.value ?? ""), note],
      ));
    }

    return NoteCardContainer(
      notes: [rootNote, ...authorFirstLevelSelfReplies],
      otherContainers: rootLevelRepliesContainers,
    );
  }
}
