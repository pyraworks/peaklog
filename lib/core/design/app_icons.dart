import 'package:flutter/material.dart';

/// Central icon registry — swap the icon set by editing this file only.
abstract class AppIcons {
  // Navigation
  static IconData get back      => Icons.chevron_left;
  static IconData get forward   => Icons.chevron_right;
  static IconData get caretDown => Icons.keyboard_arrow_down;
  static IconData get caretUp   => Icons.keyboard_arrow_up;
  // Actions
  static IconData get close    => Icons.close;
  static IconData get check    => Icons.check;
  static IconData get edit     => Icons.edit;
  static IconData get delete   => Icons.delete_outline;
  static IconData get share    => Icons.ios_share;
  static IconData get copy     => Icons.content_copy;
  static IconData get download => Icons.download;
  // Content
  static IconData get search     => Icons.search;
  static IconData get settings   => Icons.settings;
  static IconData get handyman   => Icons.handyman;
  static IconData get home       => Icons.home;
  static IconData get folder     => Icons.folder_outlined;
  static IconData get infoCircle => Icons.info_outline;
  static IconData get calculator => Icons.calculate_outlined;
  static IconData get trophy     => Icons.emoji_events;
  static IconData get chart      => Icons.bar_chart;
  static IconData get calendar   => Icons.calendar_today;
  static IconData get dragHandle => Icons.drag_handle;
  static IconData get medal      => Icons.workspace_premium;
  static IconData get image      => Icons.image;
  static IconData get gallery    => Icons.photo_library_outlined;
  static IconData get video      => Icons.videocam;
  static IconData get feedback   => Icons.chat_bubble_outline;
  // Status
  static IconData get heart   => Icons.favorite;
  static IconData get xCircle => Icons.cancel;
  // Activity / sport
  static IconData get dumbbell => Icons.fitness_center;
  static IconData get run      => Icons.directions_run;
  static IconData get bike     => Icons.directions_bike;
  static IconData get swim     => Icons.pool;
}
