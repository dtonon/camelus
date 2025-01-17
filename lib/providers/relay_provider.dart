import 'dart:async';
import 'dart:isolate';

import 'package:camelus/providers/block_mute_provider.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final relayServiceProvider = Provider<RelayCoordinator>((ref) {
  final db = ref.watch(databaseProvider.future);

  final keypair = ref.watch(keyPairProvider.future);

  final blockMuteService = ref.watch(blockMuteProvider.future);

  final relayService = RelayCoordinator(
    dbFuture: db,
    keyPairFuture: keypair,
    blockMuteServiceFuture: blockMuteService,
  );

  return relayService;
});
