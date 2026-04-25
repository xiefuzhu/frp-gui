import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/routes/index.dart';
import 'package:system_theme/system_theme.dart';

final List<ThemeMode> _themeMode = [
  ThemeMode.system,
  ThemeMode.light,
  ThemeMode.dark,
];
//可选颜色列表
final List<Color> _colorMode = [
  SystemTheme.accentColor.accent,
  Colors.purple,
  Colors.redAccent,
  Colors.blueAccent,
  Colors.yellowAccent,
  Colors.green,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.pinkAccent,
];

List<String> _themeModeName = ["跟随系统", "浅色", "深色"];

//主题模式列表
Widget themeModeSetting(BuildContext context) {
  return InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: () {
      //设置弹窗
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return UnconstrainedBox(
            child: AlertDialog(
              //弹窗标题
              title: const Text('主题', style: TextStyle(fontSize: 30)),
              //弹窗正文内容
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("主题模式", style: TextStyle(fontSize: 20)),

                        SizedBox(height: 10),

                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeModeNotifier,
                          builder: (context, currentThemeMode, _) {
                            final int themeValue = _themeMode.indexOf(
                              currentThemeMode,
                            );
                            return Wrap(
                              crossAxisAlignment: WrapCrossAlignment.start,
                              spacing: 10,
                              runSpacing: 5,
                              children: List.generate(_themeMode.length, (
                                int index,
                              ) {
                                return ChoiceChip(
                                  side: BorderSide.none,
                                  selected: themeValue == index, //按钮的值
                                  label: Text(_themeModeName[index]), //按钮名称
                                  onSelected: (bool selected) {
                                    themeModeNotifier.value = _themeMode[index];
                                  },
                                );
                              }),
                            );
                          },
                        ),

                        SizedBox(height: 10),
                        const Text("主题色", style: TextStyle(fontSize: 20)),
                        SizedBox(height: 10),

                        //软件颜色选择
                        Container(
                          alignment: Alignment.topCenter,
                          child: ValueListenableBuilder<Color>(
                            valueListenable: colorModeNotifier,
                            builder: (context, currentColor, _) {
                              return Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_colorMode.length, (
                                  int index,
                                ) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(25),
                                    onTap: () {
                                      colorModeNotifier.value =
                                          _colorMode[index];
                                      colorMode = _colorMode[index];
                                    },
                                    //ink可以让涟漪动画居于上方
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        color: _colorMode[index],
                                        boxShadow: [
                                          BoxShadow(
                                            color: _colorMode[index].withAlpha(
                                              200,
                                            ),
                                            blurRadius: 7,
                                            spreadRadius: 0.5,
                                            offset: const Offset(2, 3),
                                          ),
                                        ],
                                      ),
                                      width: 46,
                                      height: 46,
                                      child: Stack(
                                        children: [
                                          //选中显示图标，即√
                                          Positioned(
                                            top: 13,
                                            bottom: 13,
                                            right: 13,
                                            child: Icon(
                                              Icons.check,
                                              color:
                                                  currentColor ==
                                                      _colorMode[index]
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              size: 20,
                                            ),
                                          ),
                                          //吸管图标，用于标明该颜色为跟随系统颜色
                                          Positioned(
                                            bottom: -1,
                                            right: -1,
                                            child: Icon(
                                              Icons.colorize,
                                              color:
                                                  _colorMode[index] ==
                                                      SystemTheme
                                                          .accentColor
                                                          .accent
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
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
              Icons.color_lens,
              size: 40,
              color: Theme.of(context).colorScheme.surfaceTint,
            ),
          ),
          Positioned(
            left: 70,
            top: 15,
            child: Text(
              "外观",
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
              "设置软件样式",
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
