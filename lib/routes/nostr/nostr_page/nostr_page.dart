import 'dart:async';
import 'dart:convert';

import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_and_replies_view.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';
import 'package:camelus/routes/nostr/relays_page.dart';
import 'package:camelus/services/nostr/relays/my_relay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:camelus/atoms/my_profile_picture.dart';

import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';

import '../../../config/palette.dart';

class NostrPage extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final String pubkey;

  const NostrPage(
      {Key? key, required this.parentScaffoldKey, required this.pubkey})
      : super(key: key);
  @override
  ConsumerState<NostrPage> createState() => _NostrPageState();
}

class _NostrPageState extends ConsumerState<NostrPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> followingPubkeys = [];

  late final ScrollController _scrollControllerPage = ScrollController();

  late TabController _tabController;

  void _betaCheckForUpdates() async {
    await Future.delayed(const Duration(seconds: 15));

    // network get request to check for updates
    Response response = await http
        .get(Uri.parse("https://lox.de/.well-known/app-update-beta.json"));

    if (response.statusCode != 200) {
      return;
    }

    var updateInfo = jsonDecode(response.body);

    if (updateInfo["version"] <= 23) {
      // <-- current version

      return;
    }

    var title = updateInfo["title"];
    var body = updateInfo["body"];
    var url = updateInfo["url"];

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: <Widget>[
              TextButton(
                child: const Text("cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("update"),
                onPressed: () {
                  var u = Uri.parse(url);
                  launchUrl(u, mode: LaunchMode.externalApplication);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _openRelaysView() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RelaysPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 0.2);
          var end = Offset.zero;
          var curve = Curves.linear;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return ScaleTransition(
            alignment: Alignment.topRight,
            scale: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _betaCheckForUpdates();

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {}
    });

    _tabController.animation?.addListener(() {
      if ((_tabController.offset >= 1 || _tabController.offset <= -1)) {
        //log("animation tab changed to ${_tabController.index}");
      }
      if ((_tabController.offset >= 0.5 || _tabController.offset <= -0.5)) {
        //log("0,5###:  ${_tabController.index}");
      }
    });

    _scrollControllerPage.addListener(() {
      //log("scrolling page");
    });
  }

  @override
  void dispose() {
    _scrollControllerPage.dispose();

    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var metadata = ref.watch(metadataProvider);
    var myRelays = ref.watch(relayServiceProvider);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: null,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                floating: false,
                snap: false,
                pinned: false,
                elevation: 1.0,
                backgroundColor: Palette.background,
                leadingWidth: 52,
                leading: InkWell(
                  onTap: () =>
                      widget.parentScaffoldKey.currentState!.openDrawer(),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: const BoxDecoration(
                      color: Palette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: StreamBuilder<DbUserMetadata?>(
                        stream:
                            metadata.getMetadataByPubkeyStream(widget.pubkey),
                        builder: (BuildContext context,
                            AsyncSnapshot<DbUserMetadata?> snapshot) {
                          var picture = "";
                          var defaultPicture =
                              "https://avatars.dicebear.com/api/personas/${widget.pubkey}.svg";
                          if (snapshot.hasData) {
                            picture = snapshot.data?.picture ?? defaultPicture;
                          } else if (snapshot.hasError) {
                            picture = defaultPicture;
                          } else {
                            // loading
                            picture = defaultPicture;
                          }

                          return myProfilePicture(
                            pictureUrl: picture,
                            pubkey: widget.pubkey,
                            filterQuality: FilterQuality.medium,
                          );
                        }),
                  ),
                ),
                centerTitle: true,
                title: GestureDetector(
                  onTap: () => {},
                  child: badges.Badge(
                      badgeAnimation: const badges.BadgeAnimation.fade(),
                      showBadge: false,
                      badgeContent: const Text(
                        "",
                        style: TextStyle(color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "camelus - nostr",
                          style: TextStyle(
                            color: Palette.lightGray,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => _openRelaysView(),
                    child: StreamBuilder<List<MyRelay>>(
                        stream: myRelays.relaysStream,
                        initialData: myRelays.relays,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/cell-signal-slash.svg',
                                  color: Palette.gray,
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(width: 5),
                                if (!kReleaseMode)
                                  Text(
                                    "0".toString(),
                                    style: const TextStyle(
                                        color: Palette.lightGray),
                                  ),
                                const SizedBox(width: 5),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/cell-signal-full.svg',
                                  color: Palette.gray,
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(width: 5),
                                // check if dev build
                                if (!kReleaseMode)
                                  Text(
                                    // count how many relays are ready
                                    snapshot.data!
                                        .where((element) => element.connected)
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                        color: Palette.lightGray),
                                  ),
                                const SizedBox(width: 5),
                              ],
                            );
                          }
                        }),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(20),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Palette.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    automaticIndicatorColorAdjustment: true,
                    indicator: const UnderlineTabIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                        width: 2,
                        color: Palette.primary,
                      ),
                    ),
                    indicatorWeight: 5.0,
                    tabs: const [
                      Text("feed", style: TextStyle(color: Palette.lightGray)),
                      Text("feed & replies",
                          style: TextStyle(color: Palette.lightGray)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              UserFeedOriginalView(pubkey: widget.pubkey),
              UserFeedAndRepliesView(pubkey: widget.pubkey),
            ],
          ),
        ),
      ),
    );
  }
}
