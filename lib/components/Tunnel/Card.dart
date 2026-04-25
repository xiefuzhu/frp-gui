import 'package:flutter/material.dart';
import '../../utils/ToastUtils.dart';
import 'card/moreMenu.dart';
import 'card/switchConfigState.dart';
import '../../utils/TunnelStorage.dart';

final ValueNotifier<int> _refreshTunnelCard = ValueNotifier(0);

//全局刷新函数,在其他地方调用此函数即可触发 TunnelCard 刷新
void refreshTunnelCard() {
  _refreshTunnelCard.value++;
}

//单个配置展示卡片组件
Container _frpcTomlCard(
  BuildContext context,
  Map<String, dynamic> tunnel, {
  VoidCallback? onTunnelUpdated,
  VoidCallback? onTunnelDeleted,
}) {
  final enabled = tunnel['_enabled'] == true;
  bool currentEnabled = enabled;
  return Container(
    height: 100,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Stack(
      children: [
        //隧道开关
        Positioned(
          top: 5,
          right: 5,
          child: StatefulBuilder(
            builder: (context, setSwitchState) {
              return switchConfigState(
                enabled: currentEnabled,
                onChanged: (value) async {
                  // 先更新本地状态，保证 Switch 动画正常播放。
                  setSwitchState(() {
                    currentEnabled = value;
                  });

                  final path = tunnel['_filePath'];
                  if (path is! String || path.isEmpty) {
                    setSwitchState(() {
                      currentEnabled = !value;
                    });
                    return;
                  }

                  try {
                    final newPath = await toggleTunnelConfigBySuffix(
                      path,
                      value,
                    );
                    tunnel['_enabled'] = value;
                    tunnel['_filePath'] = newPath;
                    tunnel['_fileName'] = newPath
                        .replaceAll('\\', '/')
                        .split('/')
                        .last;
                    ToastUtils.showToast(context, "更改成功，请重启穿透");
                  } catch (_) {
                    // 写文件失败时回滚 UI，保证界面与配置一致。
                    setSwitchState(() {
                      currentEnabled = !value;
                    });
                    ToastUtils.showToast(context, "更改失败");
                  }
                },
              );
            },
          ),
        ),
        //更多菜单
        Positioned(
          bottom: 5,
          right: 5,
          child: moreMenu(
            context,
            tunnel,
            onTunnelUpdated: onTunnelUpdated,
            onTunnelDeleted: onTunnelDeleted,
          ),
        ),
        //左侧信息展示
        Positioned(
          top: 5,
          left: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${tunnel['name'] ?? ''}'), //显示配置名称
              SizedBox(height: 5), //用于内容间的分隔
              Container(
                alignment: Alignment.center,
                height: 25,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text('${tunnel['type'] ?? ''}'),
              ), //显示隧道类型
              SizedBox(height: 5), //用于内容间的分隔
              Text("ip: ${tunnel['localIP'] ?? ''}"), //显示映射的本地ip
              SizedBox(height: 5), //用于内容间的分隔
              Text("本地端口: ${tunnel['localPort'] ?? ''}"), //显示映射的本地端口
              SizedBox(height: 5), //用于内容间的分隔
              Text("远程端口: ${tunnel['remotePort'] ?? ''}"), //显示远程端口
            ],
          ),
        ),
      ],
    ),
  );
}

//展示所有的配置卡片
class TunnelCard extends StatefulWidget {
  const TunnelCard({super.key});

  @override
  State<TunnelCard> createState() => _TunnelCardState();
}

class _TunnelCardState extends State<TunnelCard> {
  //initState() 只执行一次，防止窗口大小改变时的重建导致闪烁
  late Future<List<Map<String, dynamic>>> _frpFuture;
  final Set<String> _knownPaths = <String>{};
  final Set<String> _appearingPaths = <String>{};
  final Set<String> _removingPaths = <String>{};

  static const Duration _itemFadeDuration = Duration(milliseconds: 240);

  // 加载数据的方法
  @override
  void initState() {
    super.initState();
    _frpFuture = loadTunnelConfigs();
    // 监听全局刷新触发器
    _refreshTunnelCard.addListener(_onRefreshTrigger);
  }

  void _onRefreshTrigger() {
    setState(() {
      // 重新加载数据
      _frpFuture = loadTunnelConfigs();
    });
  }

  @override
  void dispose() {
    _refreshTunnelCard.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _frpFuture,

      builder: (context, snapshot) {
        //判断读取的toml文件是否有数据
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('错误: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('没有数据');
        }

        //获取配置数据，并指出数据一定非空
        final tunnels = snapshot.data!;
        final currentPaths = tunnels
            .map((tunnel) => '${tunnel['_filePath'] ?? ''}')
            .where((path) => path.isNotEmpty)
            .toSet();

        _knownPaths.removeWhere((path) => !currentPaths.contains(path));
        _appearingPaths.removeWhere((path) => !currentPaths.contains(path));

        if (tunnels.isEmpty) {
          return const Center(child: Text('暂无隧道配置，请先添加'));
        }

        //可以自动换行和滚动的配置展示卡片
        return LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            const minItemWidth = 300.0; //卡片最小宽度
            const itemHeight = 140.0; //卡片高度

            //这三坨玩意用于计算实时计算交叉轴卡片数量、卡片宽度，实现页面大小调整时卡片高度不变，宽度动态变化
            int crossAxisCount =
                (constraints.maxWidth / (minItemWidth + spacing)).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;
            final itemWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

            return GridView.builder(
              itemCount: tunnels.length,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, //实时计算的交叉轴卡片数量
                mainAxisExtent: itemHeight, //卡片固定高度
                mainAxisSpacing: spacing, //卡片主轴间距
                crossAxisSpacing: spacing, //卡片交叉轴间距
              ),
              itemBuilder: (context, index) {
                final tunnel = tunnels[index];
                final path = '${tunnel['_filePath'] ?? ''}';

                if (path.isNotEmpty &&
                    !_knownPaths.contains(path) &&
                    !_appearingPaths.contains(path)) {
                  _knownPaths.add(path);
                  _appearingPaths.add(path);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _appearingPaths.remove(path);
                    });
                  });
                }

                final isRemoving =
                    path.isNotEmpty && _removingPaths.contains(path);
                final isAppearing =
                    path.isNotEmpty && _appearingPaths.contains(path);

                return SizedBox(
                  width: itemWidth, //实时计算的卡片宽度
                  height: itemHeight, //固定的卡片高度
                  child: AnimatedOpacity(
                    duration: _itemFadeDuration,
                    curve: Curves.easeInOut,
                    opacity: (isRemoving || isAppearing) ? 0 : 1,
                    child: _frpcTomlCard(
                      context,
                      tunnel,
                      onTunnelUpdated: () {
                        setState(() {});
                      },
                      onTunnelDeleted: () {
                        if (path.isEmpty || _removingPaths.contains(path)) {
                          return;
                        }
                        setState(() {
                          _removingPaths.add(path);
                        });
                        Future.delayed(_itemFadeDuration, () {
                          if (!mounted) return;
                          setState(() {
                            tunnels.remove(tunnel);
                            _removingPaths.remove(path);
                            _knownPaths.remove(path);
                            _appearingPaths.remove(path);
                          });
                        });
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
