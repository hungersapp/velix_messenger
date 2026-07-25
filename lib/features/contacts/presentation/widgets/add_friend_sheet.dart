import 'package:flutter/material.dart';

import '../../../profile/presentation/screens/qr_scanner_screen.dart';
import '../screens/search_users_screen.dart';

/// Bottom sheet entry for friend discovery: QR scan or user search.
Future<void> showAddFriendSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('Scan Velix QR'),
                subtitle: const Text('Connect by scanning a Velix identity QR'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QrScannerScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_search_rounded),
                title: const Text('Search Velix Users'),
                subtitle: const Text('Find people by Velix ID or username'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SearchUsersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
