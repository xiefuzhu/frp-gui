import 'package:flutter/material.dart';
import '../../utils/TunnelStorage.dart';
import '../../utils/ToastUtils.dart';
import '../../components/Tunnel/popupwindows/configModification.dart';
import '../../components/Tunnel/popupwindows/tcpConfig.dart';

//控制配置填写文本框数据获取的控制器
TextEditingController nameconfigController = TextEditingController();
TextEditingController ipconfigController = TextEditingController();
TextEditingController localportconfigController = TextEditingController();
TextEditingController remoteportconfigController = TextEditingController();

//获取toml配置并转成map类型
Map<String, dynamic> _buildEditableTunnel(Map<String, dynamic> sourceTunnel) {
  return {
    'name': sourceTunnel['name'] ?? '',
    'type': sourceTunnel['type'] ?? 'tcp',
    'localIP': sourceTunnel['localIP'] ?? '127.0.0.1',
    'localPort': sourceTunnel['localPort'] ?? 0,
    'remotePort': sourceTunnel['remotePort'] ?? 0,
  };
}

//配置保存功能
Future<void> _saveEditedTunnel(
  BuildContext context,
  Map<String, dynamic> tunnel,
  Map<String, dynamic> editableTunnel,
  VoidCallback? onUpdated,
) async {
  try {
    editableTunnel['name'] = nameconfigController.text;
    editableTunnel['localIP'] = ipconfigController.text;
    editableTunnel['localPort'] =
        int.tryParse(localportconfigController.text) ?? 0;
    editableTunnel['remotePort'] =
        int.tryParse(remoteportconfigController.text) ?? 0;

    final sourcePath = tunnel['_filePath'];
    if (sourcePath is! String || sourcePath.isEmpty) {
      throw Exception('无效的隧道文件路径');
    }

    final savedPath = await saveTunnelConfig(
      editableTunnel,
      sourceFilePath: sourcePath,
      enabled: tunnel['_enabled'] == true,
    );

    // 同步当前卡片数据，避免依赖整页重载。
    tunnel['name'] = editableTunnel['name'];
    tunnel['type'] = editableTunnel['type'];
    tunnel['localIP'] = editableTunnel['localIP'];
    tunnel['localPort'] = editableTunnel['localPort'];
    tunnel['remotePort'] = editableTunnel['remotePort'];
    tunnel['_filePath'] = savedPath;
    tunnel['_fileName'] = savedPath.replaceAll('\\', '/').split('/').last;
    onUpdated?.call();

    ToastUtils.showToast(context, "保存成功");
  } catch (_) {
    ToastUtils.showToast(context, "保存失败");
  }

  Navigator.of(context).pop();
}

//配置修改填写框
Column _changeConfig(BuildContext context, editableTunnel) {
  return Column(
    children: [
      Container(alignment: Alignment.centerLeft, child: Text("网络类型:")),
      SizedBox(height: 10),
      tcpConfig(context, editableTunnel),
      SizedBox(height: 10),
      Container(alignment: Alignment.centerLeft, child: Text("基础配置:")),
      SizedBox(height: 10),
      configModification(context, nameconfigController, "名称", "name"),
      SizedBox(height: 20),
      configModification(context, ipconfigController, "本地ip", "127.0.0.1"),
      SizedBox(height: 20),
      configModification(context, localportconfigController, "本地端口", "25565"),
      SizedBox(height: 20),
      configModification(context, remoteportconfigController, "远程端口", "25565"),
    ],
  );
}

//弹窗布局
Future<void> changeTunnel(
  BuildContext context,
  Map<String, dynamic> tunnel, {
  VoidCallback? onUpdated,
}) async {
  final editableTunnel = _buildEditableTunnel(tunnel);

  //将读取的配置显示到文本框中，以提供修改
  nameconfigController.text = '${editableTunnel['name']}';
  ipconfigController.text = '${editableTunnel['localIP']}';
  localportconfigController.text = '${editableTunnel['localPort']}';
  remoteportconfigController.text = '${editableTunnel['remotePort']}';

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return UnconstrainedBox(
        child: AlertDialog(
          //弹窗标题
          title: const Text('添加隧道'),
          //弹窗正文内容（填写配置的地方）
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4 > 400
                ? 400
                : MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width * 0.5 > 600
                ? 600
                : MediaQuery.of(context).size.width *
                      0.5, //宽度超过600前为屏幕宽度的0.7倍，超过后固定为600
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsetsGeometry.only(right: 20, left: 20),
                //配置修改框
                child: _changeConfig(context, editableTunnel),
              ),
            ),
          ),
          //弹窗底部按钮
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                //关闭弹窗
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () async {
                await _saveEditedTunnel(
                  context,
                  tunnel,
                  editableTunnel,
                  onUpdated,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

//底部弹出卡片布局
Future<void> changeTunnel2(
  BuildContext context,
  Map<String, dynamic> tunnel, {
  VoidCallback? onUpdated,
}) async {
  final editableTunnel = _buildEditableTunnel(tunnel);

  //将读取的配置显示到文本框中，以提供修改
  nameconfigController.text = '${editableTunnel['name']}';
  ipconfigController.text = '${editableTunnel['localIP']}';
  localportconfigController.text = '${editableTunnel['localPort']}';
  remoteportconfigController.text = '${editableTunnel['remotePort']}';

  return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return UnconstrainedBox(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8 > 450
              ? 450
              : MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width > 600
              ? 600
              : MediaQuery.of(
                  context,
                ).size.width, //宽度超过600前为屏幕宽度的0.7倍，超过后固定为600
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsetsGeometry.only(left: 20, right: 20),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Container(
                    height: 5,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(150),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  SizedBox(height: 10),
                  _changeConfig(context, editableTunnel),

                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          //关闭弹窗
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('保存'),
                        onPressed: () async {
                          await _saveEditedTunnel(
                            context,
                            tunnel,
                            editableTunnel,
                            onUpdated,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

//删除配置
Future<void> deletTunnel(
  BuildContext context,
  Map<String, dynamic> tunnel, {
  VoidCallback? onDeleted,
}) async {
  try {
    final path = tunnel['_filePath'];
    if (path is! String || path.isEmpty) {
      throw Exception('无效的隧道文件路径');
    }
    await deleteTunnelConfig(path);
    ToastUtils.showToast(context, "删除成功");
    onDeleted?.call();
  } catch (_) {
    ToastUtils.showToast(context, "删除失败");
  }
}
