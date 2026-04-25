import 'package:flutter/material.dart';
import 'package:frp_flutter/utils/FrpService.dart';
import 'package:frp_flutter/utils/TerminalUtil.dart';

//首页连接按钮
int _state = 0; //0未连接，1已连接

class connectButton extends StatefulWidget {
  const connectButton({super.key});

  @override
  State<connectButton> createState() => _connectButtonState();
}

class _connectButtonState extends State<connectButton>
    with AutomaticKeepAliveClientMixin {
  //必须添加这个 getter，返回 true 表示希望保留状态
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //按钮大小
    double buttonSize = MediaQuery.of(context).size.height * 0.5 > 200
        ? 200
        : MediaQuery.of(context).size.height * 0.5;
    //根据按钮状态显示对应颜色
    Color power = _state == 1
        ? Colors.red
        : Theme.of(context).colorScheme.primaryContainer;
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Column 的高度至少等于窗口高度
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: buttonSize,
                      width: buttonSize,
                      child: FloatingActionButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        backgroundColor: Colors.white,
                        onPressed: () async {
                          if (_state == 0) {
                            TerminalUtil.instance.clear();
                            TerminalUtil.instance.writeLog("正在启动frp进程...");
                            await FrpService.instance.startFrp();
                            _state = 1;
                          } else {
                            await FrpService.instance.stopFrp();
                            _state = 0;
                          }
                          ;
                          setState(() {});
                        },
                        child: Icon(
                          size: buttonSize * 0.75,
                          Icons.power_settings_new,
                          color: power,
                        ),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
