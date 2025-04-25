import 'dart:async';

import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';

class Online extends ChangeNotifier {
  static Future<void> meOnline({String? room}) async {
    String uid = await CosmosFirebase.getUID();
    if (room == null) {
      await CosmosFirebase.add(
        reference: "online",
        tag: uid,
        value: [
          uid,
          CosmosTime.getNowTimeString(),
          "-1", // -1 Aktif ama toplantıda değil
        ],
      );
    } else {
      await CosmosFirebase.add(
        reference: "online",
        tag: uid,
        value: [
          uid,
          CosmosTime.getNowTimeString(),
          room,
        ],
      );
    }
  }

  static Future<Map> isOnline(String uid) async {
    List ax = [];
    List axa = await CosmosFirebase.getOnce('online');
    for (List element in axa) {
      if (element[0] == uid) {
        ax = element;
      }
    }
    if (ax == [] || ax.isEmpty) {
      return {"status": false, "room": "0"};
    } else {
      bool lastTime = isTimeDMT6s(ax[1], CosmosTime.getNowTimeString());
      if (!lastTime) {
        return {"status": false, "room": ax[2]};
      } else {
        return {"status": false, "room": "0"};
      }
    }
  }
}

bool isTimeDMT6s(String time1, String time2) {
  DateTime dateTime1 = DateTime.parse(
      "${time1.split(' ')[0].split('/').reversed.join('-')}T${time1.split(' ')[1]}");
  DateTime dateTime2 = DateTime.parse(
      "${time2.split(' ')[0].split('/').reversed.join('-')}T${time2.split(' ')[1]}");

  Duration difference = dateTime1.difference(dateTime2).abs();

  return difference.inSeconds > 6;
}

bool isTimeDMT45m(String time1, String time2) {
  DateTime dateTime1 = DateTime.parse(
      "${time1.split(' ')[0].split('/').reversed.join('-')}T${time1.split(' ')[1]}");
  DateTime dateTime2 = DateTime.parse(
      "${time2.split(' ')[0].split('/').reversed.join('-')}T${time2.split(' ')[1]}");

  Duration difference = dateTime1.difference(dateTime2).abs();

  return difference.inMinutes > 45;
}

bool isTimeDMT59s(String time1, String time2) {
  DateTime dateTime1 = DateTime.parse(
      "${time1.split(' ')[0].split('/').reversed.join('-')}T${time1.split(' ')[1]}");
  DateTime dateTime2 = DateTime.parse(
      "${time2.split(' ')[0].split('/').reversed.join('-')}T${time2.split(' ')[1]}");

  Duration difference = dateTime1.difference(dateTime2).abs();

  return difference.inSeconds > 59;
}
