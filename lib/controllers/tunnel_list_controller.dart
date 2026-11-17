import 'package:flutter/foundation.dart';

import '../models/tunnel_config.dart';
import '../services/config_repository.dart';
import '../services/frp_process_service.dart';

class TunnelListController extends ChangeNotifier {
  TunnelListController._();
  static final TunnelListController instance = TunnelListController._();

  List<TunnelConfig> _tunnels = const [];
  bool _isLoading = false;
  Object? _error;

  List<TunnelConfig> get tunnels => _tunnels;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tunnels = await ConfigRepository.instance.loadTunnels();
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveTunnel(TunnelConfig draft) async {
    final saved = await ConfigRepository.instance.saveTunnel(draft);
    final next = List<TunnelConfig>.from(_tunnels);
    final oldPath = draft.filePath;
    final existingIdx = oldPath == null
        ? -1
        : next.indexWhere((item) => item.filePath == oldPath);

    if (existingIdx >= 0) {
      next[existingIdx] = saved;
    } else {
      next.add(saved);
    }
    next.sort((a, b) => a.name.compareTo(b.name));
    _tunnels = List<TunnelConfig>.unmodifiable(next);
    notifyListeners();

    return FrpProcessService.instance.restartIfRunning();
  }

  Future<bool> toggleTunnel(TunnelConfig tunnel, bool enabled) async {
    final updated = await ConfigRepository.instance.toggleTunnel(
      tunnel,
      enabled,
    );
    final next = _tunnels
        .map((item) => item.filePath == tunnel.filePath ? updated : item)
        .toList();
    _tunnels = List<TunnelConfig>.unmodifiable(next);
    notifyListeners();

    return FrpProcessService.instance.restartIfRunning();
  }

  Future<bool> deleteTunnel(TunnelConfig tunnel) async {
    final path = tunnel.filePath;
    if (path != null && path.isNotEmpty) {
      await ConfigRepository.instance.deleteTunnel(path);
    }
    _tunnels = List<TunnelConfig>.unmodifiable(
      _tunnels.where((item) => item.filePath != path),
    );
    notifyListeners();

    return FrpProcessService.instance.restartIfRunning();
  }
}
