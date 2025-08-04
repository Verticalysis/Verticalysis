// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tabbed_view/tabbed_view.dart';

import '../domain/schema/FlatDirSchList.dart';
import 'shared/Extensions.dart';
import 'StartupMode.dart';
import 'Style.dart';

typedef TabDtor = void Function();

final class Scaffold extends StatelessWidget {
  final tabsctl = TabbedViewController([]);
  final bool useTmpSchDir;

  static const _startupPageTitle = "Welcome";
  static const _tabRadius = BorderRadius.only(
    topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)
  );

  Scaffold({ required this.useTmpSchDir, String src = "", super.key }) {
    tabsctl.newPage(_startupPageTitle, startUpPage, src: src);
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      TabbedViewTheme(
        data: tabCosmeticFromTheme(ColorScheme.of(context)),
        child: TabbedView(
          controller: tabsctl,
          selectToEnableButtons: false,
          tabCloseInterceptor: (index, tabData) {
            if(tabsctl.length == 1) {
              tabsctl.newPage(_startupPageTitle, startUpPage);
            } else {
              (tabData.value as TabDtor)();
              final selected = tabsctl.selectedIndex!;
              if(index <= selected) {
                if(index == selected - 1) {
                  if(index != 0) {
                    tabsctl.reorderTab(selected, index);
                    tabsctl.selectedIndex = index;
                    tabsctl.removeTab(selected);
                    return false;
                  } else tabsctl.selectedIndex = 0;
                } else tabsctl.selectedIndex = selected - 1;
              }
            }
            return true;
          },
        )
      ),
      WindowTitleBarBox(
        child: Row(
          children: [
            Expanded(child: MoveWindow()),
            NewTabButton(tabsctl, startUpPage, title: _startupPageTitle),
            const WindowButtons()
          ],
        ),
      ),
    ]
  );

  Future<Widget> startUpPage(TabData tab, { String src = ""}) async {
    try {
      final schDir = useTmpSchDir ?
        await getTemporaryDirectory() :
        await getApplicationDocumentsDirectory();

      return StartupMode(FlatDirSchSet(schDir), tab, src: src);
    } catch(e) {
      return StartupMode({}, tab, src: src);
    }
  }

  static TabbedViewThemeData tabCosmeticFromTheme(
    ColorScheme scheme
  ) => TabbedViewThemeData(
    tabsArea: TabsAreaThemeData(color: const Color(0x21000000)),
    tab: TabThemeData(
      padding: EdgeInsets.fromLTRB(12, 6, 6, 5.5),
      buttonsOffset: 8,
      hoverButtonColor: scheme.error,
      textStyle: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        // color: scheme.surface,
        borderRadius: _tabRadius
      ),
      draggingDecoration: BoxDecoration(
        borderRadius: _tabRadius,
        border: Border.symmetric(
          horizontal: BorderSide(width: 6, color: scheme.surface),
          vertical: BorderSide(width: 6, color: scheme.surface)
        )
      ),
      selectedStatus: TabStatusThemeData(decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: _tabRadius,
        border: Border(bottom: BorderSide(color: scheme.surface, width: 0.7))
      )),
      highlightedStatus: TabStatusThemeData(decoration: BoxDecoration(
        color: scheme.surfaceDim, borderRadius: _tabRadius
      ))
    ),
  );
}

extension on TabbedViewController {
  void newPage(String title, Future<Widget> builder(TabData tab, { String src }), {
    String src = ""
  }) => this.addTab(TabData(
    text: title,
    value: () {},
  )..postConstruct((tab) => builder(tab, src: src).then((page) {
      tab.content = page;
  })));
}

extension type NewTabButton._(WindowButton button) implements WindowButton{
  NewTabButton(
    TabbedViewController tabsctl,
    Future<Widget> builder(TabData tab, { String src }),
    { Key? key, String title = "", bool animate = false }
  ): button = WindowButton(
    key: key,
    colors: buttonColors,
    animate: animate,
    iconBuilder: (_) => Icon(
      Icons.tab_outlined, size: 12, color: const Color(0xFF000000)
    ),
    onPressed: () {
      tabsctl.newPage(title, builder);
      tabsctl.selectedIndex = tabsctl.tabs.length - 1;
    }
  );

  static final buttonColors = WindowButtonColors(
    iconNormal: const Color(0xFF000000),
    mouseOver: lightColorScheme.primary,
    mouseDown: lightColorScheme.primary,
    iconMouseOver: const Color(0xFF000000),
    iconMouseDown: const Color(0xFF000000)
  );
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: NewTabButton.buttonColors),
        if(appWindow.isMaximized) RestoreWindowButton(
          colors: NewTabButton.buttonColors,
          onPressed: maximizeOrRestore,
        ) else MaximizeWindowButton(
          colors: NewTabButton.buttonColors,
          onPressed: maximizeOrRestore,
        ),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }

  static final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0xFF805306),
    iconMouseOver: Colors.white
  );
}
