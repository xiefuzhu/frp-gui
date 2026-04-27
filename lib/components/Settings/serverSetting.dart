import 'package:flutter/material.dart';
import '../../utils/ToastUtils.dart';
import '../../utils/TunnelStorage.dart';
import '../popupwindows/configModification.dart';

TextEditingController serverAddrConfigController = TextEditingController();
TextEditingController serverPortConfigController = TextEditingController();
TextEditingController tokenConfigController = TextEditingController();


//获取toml配置并转成map类型
Map<String, dynamic> buildEditableServerConfig(Map<String, dynamic> source) {
  return {
    'serverAddr': '${source['serverAddr'] ?? ''}',
    'serverPort': '${source['serverPort'] ?? ''}',
    'token': '${source['token'] ?? ''}',
  };
}

//服务器设置弹窗
class ServerSettingDialog extends StatefulWidget {
  const ServerSettingDialog({super.key});

  // 可选：提供一个静态方法，简化调用
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerSettingDialog(),
    );
  }

  @override
  State<ServerSettingDialog> createState() => _ServerSettingDialogState();
}

class _ServerSettingDialogState extends State<ServerSettingDialog> {

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServerConfigToControllers();
  }

  //服务器配置读取
  Future<void> _loadServerConfigToControllers() async {
    try {
      final config = await loadServerConfig();
      final editable = buildEditableServerConfig(config);

      serverAddrConfigController.text = editable['serverAddr'];
      serverPortConfigController.text = editable['serverPort'];
      tokenConfigController.text = editable['token'];
    } catch (e) {
      ToastUtils.showToast(context, '读取服务器配置失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
 
    return UnconstrainedBox(
      child: AlertDialog(
        //弹窗标题
        title: const Text('服务器设置', style: TextStyle(fontSize: 30)),
        //弹窗正文内容
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.35 > 210 ? 210 : MediaQuery.of(context).size.height * 0.35,
          width: MediaQuery.of(context).size.width * 0.5 > 600 ? 600 : MediaQuery.of(context).size.width * 0.5,
          child: SingleChildScrollView(
            child: Padding(
              padding:  const EdgeInsetsGeometry.only(right: 10, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  configModification(context, serverAddrConfigController, "服务器地址", "127.0.0.1"),
                  const SizedBox(height: 20),
                  configModification(context, serverPortConfigController, "服务器端口", "7000"),
                  const SizedBox(height: 20),
                  configModification(context, tokenConfigController, "Token", ""),
                ],
              ),
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
              try {
                await saveServerConfig({
                  'serverAddr': serverAddrConfigController.text.trim(),
                  'serverPort': serverPortConfigController.text.trim(),
                  'token': tokenConfigController.text.trim(),
                });

                if (context.mounted) {
                  Navigator.of(context).pop();
              
                ToastUtils.showToast(context, '服务器配置已保存');
                } 
              }
              catch (e) {
                  ToastUtils.showToast(context, '保存失败：$e');
                }
            },
          ),
        ],
      ),
    );
  }

}



//服务器设置按钮
Widget serverSetting(BuildContext context) {
  return InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: () {

      //设置弹窗
      ServerSettingDialog.show(context);
    },
    //设置选项按钮（ink能让涟漪动画居于上方）
    child: Ink(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.withAlpha(40),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 15,
            top: 20,
            bottom: 20,
            child: Icon(
              Icons.router,
              size: 40,
              color: Theme.of(context).colorScheme.surfaceTint,
            ),
          ),
          Positioned(
            left: 70,
            top: 15,
            child: Text(
              "服务器设置",
              style: TextStyle(
                color: Theme.of(context).colorScheme.surfaceTint.withAlpha(150),
                fontSize: 20,
              ),
            ),
          ),
          Positioned(
            left: 70,
            bottom: 15,
            child: Text(
              "设置frp远程连接的服务器",
              style: TextStyle(
                color: Theme.of(context).colorScheme.surfaceTint.withAlpha(150),
                fontSize: 15,
              ),
            ),
          ),
          Positioned(
            right: 15,
            top: 25,
            bottom: 25,
            child: Icon(
              Icons.chevron_right,
              size: 30,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withAlpha(100)
                  : Colors.black.withAlpha(100),
            ),
          ),
        ],
      ),
    ),
  );
}
