import 'package:flutter/material.dart';
import 'package:frp_flutter/components/Tunnel/Card.dart';
import 'package:frp_flutter/pages/popupwindows/addTunnel.dart';


class ProxyView extends StatefulWidget {
  const ProxyView({super.key});

  @override
  State<ProxyView> createState() => _ProxyViewState();
}

class _ProxyViewState extends State<ProxyView> {

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //配置展示卡片
        Positioned(
          top:10,
          left: 10,
          right: 10,
          bottom: 0,
          child: TunnelCard()
        ),
        //添加按钮
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () => (MediaQuery.of(context).size.width < 600) ? addTunnel2(context) : addTunnel(context)
          )
        ),
      ],
    );
  }
}