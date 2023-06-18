import 'package:camelus/config/palette.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

Widget RefreshIndicatorNoNeed(
    {required Widget child, required Future<void> Function() onRefresh}) {
  return CustomRefreshIndicator(
    builder: (
      BuildContext context,
      Widget child,
      IndicatorController controller,
    ) {
      return Stack(
        children: <Widget>[
          //Transform.scale(
          //  // max 0.8
          //  scale: 1.0 - controller.value,
          //  child: child,
          //),
          //child,

          Transform.scale(
            scale: controller.value < 0.1 ? 1.0 - controller.value : 0.9,
            child: child,
          ),

          /// Your indicator implementation
          myIndicator(
              value: controller.value, loading: controller.state.isLoading),
        ],
      );
    },

    /// A function that is called when the user drags the refresh indicator.
    onRefresh: onRefresh,

    child: child,
  );
}

Widget myIndicator({
  required double value,
  required bool loading,
}) {
  if (value == 0) return Container();
  return Padding(
      padding: EdgeInsets.only(top: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Palette.extraDarkGray,
            ),
            child: Text(
              'dark pattern detected',
              style: TextStyle(color: Palette.white, fontSize: 18),
            ),
          ),
        ],
      ));
}
