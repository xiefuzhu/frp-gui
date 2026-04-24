import 'package:flutter/material.dart';


// 导入各个页面组件，供主页面按索引切换显示
import '../../components/Main/PcPage.dart';
import '../../components/Main/PhonePage.dart';


// 当前选中的页面索引
// 0=首页、1=隧道、2=内核、3=日志、4=设置
int currentIndex = 0;
// 先前选中的页面索引
// 0=首页、1=隧道、2=内核、3=日志、4=设置
int previousIndex = 0;

// 主页面
// 根据屏幕宽度自动选择电脑布局或手机布局
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 宽屏：显示电脑端布局
        if (constraints.maxWidth > 600) {
          return PcPage();
        }
        // 窄屏：显示手机端布局
        else {
          return PhonePage();
        }
      },
    );
  }
}





