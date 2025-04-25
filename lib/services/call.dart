import 'package:agor/page/call.dart';
import 'package:agor/services/database.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';

class CallClass extends ChangeNotifier {
  static Future<void> updateCall(
      BuildContext context, String tag, int status) async {
    if (status == 3) {
      List current = await CosmosFirebase.get('call/"$tag"', true);
      current[3] = status.toString();
      await CosmosFirebase.add(reference: "call", tag: tag, value: current);
      CosmosNavigator.pushNonAnimated(
          context,
          CallPage(
            callID: current[4],
            tag: tag,
          ));
    } else {
      List current = await CosmosFirebase.get('call/"$tag"', true);
      current[3] = status.toString();
      await CosmosFirebase.add(reference: "call", tag: tag, value: current);
    }
  }

  static Future<void> addCall(BuildContext context, String targetUID) async {
    String tag = CosmosRandom.randomTag();
    String uid = await CosmosFirebase.getUID();
    //Status:
    //0: Aranıyor,
    //1: Çalıyor.
    //2: Reddedildi.
    //Time: Kaç dakika konuşulduğuna dair dinamik değişen değer.

    List uProfile = await CosmosFirebase.get('users/"$targetUID"', true);
    await CosmosFirebase.add(
      reference: "call",
      tag: tag,
      value: [
        tag,
        uid,
        targetUID,
        "0",
        "${uProfile[6]}${Database.profileID.value}",
        CosmosTime.getNowTimeString(),
      ],
      onSuccess: () {
        CosmosNavigator.pushNonAnimated(
          context,
          CallPage(
            callID: "${uProfile[6]}${Database.profileID.value}",
            tag: tag,
          ),
        );
      },
    );
  }

  ///"tag": data[0],<br/>
  ///"caller_id": data[1],<br/>
  ///"callee_id": data[2],<br/>
  ///"status": data[3],<br/>
  ///"room_id": data[4],<br/>
  ///"time": data[5],<br/>
  static Future<Map> getCallInfo(String callID) async {
    List data = await CosmosFirebase.get('call/"$callID"', true);
    return {
      "tag": data[0],
      "caller_id": data[1],
      "callee_id": data[2],
      "status": data[3],
      "room_id": data[4],
      "time": data[5],
    };
  }
}
