import 'package:flutter/material.dart';

import 'mechanic_chat_screen.dart';

class WorkerAssistantScreen extends StatelessWidget {
  const WorkerAssistantScreen({
    super.key,
    this.assetId,
    this.assetBrand,
    this.assetModel,
    this.assetCategory,
  });

  final String? assetId;
  final String? assetBrand;
  final String? assetModel;
  final String? assetCategory;

  @override
  Widget build(BuildContext context) {
    return MechanicChatScreen(
      assetId: assetId,
      assetBrand: assetBrand,
      assetModel: assetModel,
      assetCategory: assetCategory,
    );
  }
}
