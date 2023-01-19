import 'package:admin/constants.dart';
import 'package:flutter/material.dart';

class CloudStorageInfo {
  final String? svgSrc, title, totalStorage;
  final int? numOfFiles, percentage;
  final Color? color;
  final IconData? icon;

  CloudStorageInfo({
    this.svgSrc,
    this.icon,
    this.title,
    this.totalStorage,
    this.numOfFiles,
    this.percentage,
    this.color,
  });
}

List demoMyFiles = [
  CloudStorageInfo(
    title: "Leaves",
    numOfFiles: 7,
    //svgSrc: "assets/icons/Documents.svg",
    icon: Icons.calendar_month_rounded,
    totalStorage: "32",
    color: primaryColor,
    percentage: 35,
  ),
  CloudStorageInfo(
    title: "Attendance",
    numOfFiles: 132,
    //svgSrc: "assets/icons/google_drive.svg",
    icon: Icons.check,
    totalStorage: "132",
    color: Color(0xFFFFA113),
    percentage: 35,
  ),
  CloudStorageInfo(
    title: "Team",
    numOfFiles: 1,
    //svgSrc: "assets/icons/one_drive.svg",
    icon: Icons.people,
    totalStorage: "3",
    color: Color(0xFFA4CDFF),
    percentage: 10,
  ),
  CloudStorageInfo(
    title: "Payslip",
    numOfFiles: 8,
    //svgSrc: "assets/icons/drop_box.svg",
    icon: Icons.money_off_outlined,
    totalStorage: "18",
    color: Color(0xFF007EE5),
    percentage: 78,
  ),
];
