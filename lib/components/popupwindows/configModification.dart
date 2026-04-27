import 'package:flutter/material.dart';


//填写配置信息组件
Widget configModification(BuildContext context, controller,String? labelText, String? hintText){
  return Row(
    children: [
      SizedBox(width: 5),
      Expanded(
        child: TextField(
          controller: controller,  //绑定文本编辑控制器
          onChanged: (Value) {},
          decoration: InputDecoration(
            labelStyle: TextStyle(),  //预览提示文字样式
            hintText: hintText,  //提示文字
            labelText: labelText,  //预览提示用文字
            filled: true,  //填充
            border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black), borderRadius: BorderRadius.circular(10)))  //文本框边框样式
        )
      ),
      SizedBox(width: 5)
    ],
  );
}