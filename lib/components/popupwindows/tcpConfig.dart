import 'package:flutter/material.dart';


//选择代理类型组件
Widget tcpConfig(BuildContext context, Map<String, dynamic> tunnel){

  //创建代理类型列表
  List<String> networkProtocol = ['tcp', 'udp', 'http', 'https', 'stcp', 'xtcp', 'sudp'];

  final currentType = '${tunnel['type'] ?? ''}';
  Set<String> networkProtocolSelection = {
    networkProtocol.contains(currentType) ? currentType : networkProtocol.first,
  };

  tunnel['type'] = networkProtocolSelection.first;

  return StatefulBuilder(
    builder: (context, setState){
      return Row(
        children: [
          SizedBox(width: 5),
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                  segments: List.generate(networkProtocol.length, (int index){
                    return ButtonSegment<String>(
                      value: networkProtocol[index],  //按钮的值
                      label: Text(networkProtocol[index]),  //按钮名称
                    );
                  }),
                  showSelectedIcon: false,  //关闭选中时显示的图标
                  style: SegmentedButton.styleFrom(),  //设置按钮样式
                  selected: networkProtocolSelection,  //被选中的按钮
                  onSelectionChanged: (Set<String> newSelection) {
                    networkProtocolSelection = newSelection;  //将被选中的按钮改为被点击的按钮
                    tunnel['type'] = newSelection.first;  //将被选中的按钮对应的值写入配置
                    setState((){});  //更新状态（得益于StatefulBuilder才能使用）
                  },
                ),
              ),
            )
          ),
          SizedBox(width: 5,),
        ],
      );
    }
  );
}

