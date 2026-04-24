import 'package:flutter/material.dart';
import 'package:frp_flutter/utils/FrpService.dart';
import 'package:frp_flutter/utils/TerminalUtil.dart';

//首页连接按钮
int _state = 0; //0未连接，1已连接

class connectBotton extends StatefulWidget {
  const connectBotton({super.key,});

  @override
  State<connectBotton> createState() => _connectBottonState();
}

class _connectBottonState extends State<connectBotton> with AutomaticKeepAliveClientMixin{

  //必须添加这个 getter，返回 true 表示希望保留状态
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color power = _state == 1 ? Colors.red : Theme.of(context).colorScheme.primaryContainer;;
    return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        height: double.infinity,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                backgroundColor: Colors.white,
                onPressed: () async {
                  if (_state == 0) {
                    TerminalUtil.instance.clear();
                    TerminalUtil.instance.writeLog("正在启动frp进程...");
                    await FrpService.instance.startFrp("/frp/frpc.toml");
                    _state = 1;
                  }
                  else{
                    TerminalUtil.instance.clear();
                    await FrpService.instance.stopFrp();
                    _state = 0;
                  };
                  setState(() {});
                },
                child: Icon(size: 150, Icons.power_settings_new, color: power),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "点击连接",
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ],
        ),
      );
  }
}