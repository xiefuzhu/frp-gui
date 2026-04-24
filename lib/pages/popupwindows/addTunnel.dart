import 'package:flutter/material.dart';
import 'package:frp_flutter/utils/ToastUtils.dart';
import '../../components/Tunnel/Card.dart';
import '../../utils/TunnelStorage.dart';
import '../../components/Tunnel/popupwindows/configModification.dart';
import '../../components/Tunnel/popupwindows/tcpConfig.dart';

//控制配置填写文本框数据获取的控制器
TextEditingController nameconfigController = TextEditingController();
TextEditingController ipconfigController = TextEditingController();
TextEditingController localportconfigController = TextEditingController();
TextEditingController remoteportconfigController = TextEditingController();

//toml文件写入内容
final Map<String, dynamic> newProxies = {
  'name': '',
  'type': 'tcp',
  'localIP': '',
  'localPort': 0,
  'remotePort': 0,
};


//配置填写框
Column _addConfig(BuildContext context){
  return Column(
    children: [
       Container(
        alignment: Alignment.centerLeft,
        child: Text("网络类型:"),
      ),
      SizedBox(height: 10),
      tcpConfig(context, newProxies),
      SizedBox(height: 10),
      Container(
        alignment: Alignment.centerLeft,
        child: Text("基础配置:"),
      ),
      SizedBox(height: 10),
      configModification(
        context,
        nameconfigController,
        "名称",
        "name",
      ),
      SizedBox(height: 20),
      configModification(
        context,
        ipconfigController,
        "本地ip",
        "127.0.0.1",
      ),
      SizedBox(height: 20),
      configModification(
        context,
        localportconfigController,
        "本地端口",
        "25565",
      ),
      SizedBox(height: 20),
      configModification(
        context,
        remoteportconfigController,
        "远程端口",
        "25565",
      ),
    ],
  );
}


//保存配置
Future<void> _saveEditedTunnel(BuildContext context)async{
  try {
    //用文本输入控制器获取输入的数据然后写入newProxies
    newProxies['name'] = nameconfigController.text;
    newProxies['localIP'] = ipconfigController.text;
    newProxies['localPort'] =
        int.tryParse(localportconfigController.text) ??
        0;
    newProxies['remotePort'] =
        int.tryParse(remoteportconfigController.text) ??
        0;

    await saveTunnelConfig(
      Map<String, dynamic>.from(newProxies),
      enabled: true,
    );

    //写入成功后的提示（可选）
    ToastUtils.showToast(context, "保存成功");
  } catch (e) {
    // 错误处理
    ToastUtils.showToast(context, "保存失败$e");
  }
}


//弹窗布局
Future<void> addTunnel(BuildContext context) async {
  //每次打开对话框前，清空四个输入框
  nameconfigController.clear();
  ipconfigController.clear();
  localportconfigController.clear();
  remoteportconfigController.clear();

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
                padding: EdgeInsetsGeometry.only(right: 10, left: 10),
                //配置填写框
                child: _addConfig(context)
              ),
            ),
          ),

          //弹窗底部按钮
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                //刷新页面
                refreshTunnelCard();
                //关闭弹窗
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () async {
                //保存
                await _saveEditedTunnel(context);
                //关闭弹窗
                Navigator.of(context).pop();
                //刷新页面
                refreshTunnelCard();
              },
            ),
          ],
        ),
      );
    },
  );
}


//底部弹出卡片布局
Future<void> addTunnel2(BuildContext context) async {
  //每次打开对话框前，清空四个输入框
  nameconfigController.clear();
  ipconfigController.clear();
  localportconfigController.clear();
  remoteportconfigController.clear();

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
                  //配置填写框
                  _addConfig(context),
                  //保存取消按钮
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          //刷新页面
                          refreshTunnelCard();
                          //关闭弹窗
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('保存'),
                        onPressed: () async {
                          //保存配置
                          await _saveEditedTunnel(context);
                          //关闭弹窗
                          Navigator.of(context).pop();
                          //刷新页面
                          refreshTunnelCard();
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

