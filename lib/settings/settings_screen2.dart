/*
 * SPDX-FileCopyrightText: 2020-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:function_types/function_types.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gitjournal/generated/locale_keys.g.dart';
import 'package:gitjournal/logger/debug_screen.dart';
import 'package:gitjournal/settings/bug_report.dart';
import 'package:gitjournal/settings/settings_about.dart';
import 'package:gitjournal/settings/settings_analyatics.dart';
import 'package:gitjournal/settings/settings_experimental.dart';

class SettingsScreen2 extends StatelessWidget {
  static const routePath = '/settings';

  @override
  Widget build(BuildContext context) {
    var list = ListView(
      children: [
        SettingsTile(
          iconData: FontAwesomeIcons.paintBrush,
          title: LocaleKeys.settings_list_userInterface_title.tr(),
          subtitle: LocaleKeys.settings_list_userInterface_subtitle.tr(),
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.git,
          title: LocaleKeys.settings_list_git_title.tr(),
          subtitle: LocaleKeys.settings_list_git_subtitle.tr(),
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.edit,
          title: LocaleKeys.settings_list_editor_title.tr(),
          subtitle: LocaleKeys.settings_list_editor_subtitle.tr(),
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.hdd,
          title: LocaleKeys.settings_list_storage_title.tr(),
          subtitle: LocaleKeys.settings_list_storage_subtitle.tr(),
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.chartArea,
          title: LocaleKeys.settings_list_analytics_title.tr(),
          subtitle: LocaleKeys.settings_list_analytics_subtitle.tr(),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => const SettingsAnalytics(),
              settings: const RouteSettings(name: '/settings/analytics'),
            );
            var _ = Navigator.push(context, route);
          },
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.wrench,
          title: LocaleKeys.settings_list_debug_title.tr(),
          subtitle: LocaleKeys.settings_list_debug_subtitle.tr(),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => const DebugScreen(),
              settings: const RouteSettings(name: '/settings/debug'),
            );
            var _ = Navigator.push(context, route);
          },
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.flask,
          title: LocaleKeys.settings_list_experiments_title.tr(),
          subtitle: LocaleKeys.settings_list_experiments_subtitle.tr(),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => ExperimentalSettingsScreen(),
              settings: const RouteSettings(name: '/settings/experimental'),
            );
            var _ = Navigator.push(context, route);
          },
        ),
        const Divider(),
        _SettingsHeader(LocaleKeys.settings_project_header.tr()),
        SettingsTile(
          iconData: Icons.question_answer_outlined,
          title: LocaleKeys.settings_project_docs.tr(),
          onTap: () {
            launch('https://gitjournal.io/docs');
          },
        ),
        SettingsTile(
          iconData: Icons.bug_report,
          title: LocaleKeys.drawer_bug.tr(),
          onTap: () => createBugReport(context),
        ),
        SettingsTile(
          iconData: Icons.feedback,
          title: LocaleKeys.drawer_feedback.tr(),
          onTap: () => createFeedback(context),
        ),
        SettingsTile(
          iconData: FontAwesomeIcons.solidHeart,
          title: LocaleKeys.settings_project_contribute.tr(),
        ),
        SettingsTile(
          iconData: Icons.info_outline,
          title: LocaleKeys.settings_project_about.tr(),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => const SettingsAboutPage(),
              settings: const RouteSettings(name: '/settings/about'),
            );
            var _ = Navigator.push(context, route);
          },
        ),
      ],
      padding: const EdgeInsets.symmetric(vertical: 16.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings_title.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: list,
    );
  }
}

// ignore: unused_element
class _SettingsSearchBar extends StatelessWidget {
  const _SettingsSearchBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 1.0,
        borderRadius: BorderRadius.circular(25.0),
        child: TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            hintText: "Search",
            fillColor: Colors.white70,
            prefixIcon: const Icon(Icons.search),
            // This content padding has no effect if 'prefixIcon' is set!!
            contentPadding: const EdgeInsets.fromLTRB(205.0, 15.0, 20.0, 15.0),
          ),
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String? subtitle;
  final Func0<void>? onTap;

  const SettingsTile({
    Key? key,
    required this.iconData,
    required this.title,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var listTileTheme = ListTileTheme.of(context);

    var textStyle = theme.textTheme.subtitle1!.copyWith(
      color: listTileTheme.textColor,
    );

    var icon = iconData is FontAwesomeIcons
        ? Icon(iconData, color: textStyle.color)
        : FaIcon(iconData, color: textStyle.color);

    return ListTile(
      leading: icon,
      title: Text(title, style: textStyle),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap ?? onTap,
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String text;
  const _SettingsHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 20.0),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
