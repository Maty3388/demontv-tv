import "package:flutter/material.dart";

enum DeviceType { phone, tv }

DeviceType getDeviceType(BuildContext context) => DeviceType.tv;

bool isTV(BuildContext context) => true;
