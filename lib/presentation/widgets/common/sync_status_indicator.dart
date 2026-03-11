// Feature: brewmaster-offline-sync
// AppBar action widget showing the current online/offline status.
//
// Requirements: 23.1
// Developer: Developer 3 (Ryan)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/connectivity/connectivity_bloc.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        final IconData icon;
        final String tooltip;
        final Color color;

        if (state is ConnectivityOnline) {
          icon = Icons.wifi;
          tooltip = 'Online';
          color = Colors.green;
        } else if (state is ConnectivityOffline) {
          icon = Icons.wifi_off;
          tooltip = 'Offline — changes will sync when connected';
          color = Colors.red;
        } else {
          icon = Icons.wifi_find;
          tooltip = 'Checking connection…';
          color = Colors.orange;
        }

        return Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(icon, color: color),
          ),
        );
      },
    );
  }
}
