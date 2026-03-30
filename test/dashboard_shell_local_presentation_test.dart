import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('services can be renamed (local label) and pinned/unpinned', (tester) async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final gateway = FakeDeviceSmsGateway([
      RawDeviceSms(
        id: 'raw-1',
        address: 'NETFLIX',
        body: 'Renewed for Rs 499',
        receivedAt: now.subtract(const Duration(days: 1)),
      ),
      RawDeviceSms(
        id: 'raw-2',
        address: 'SPOTIFY',
        body: 'Premium Rs 119',
        receivedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    final harness = DashboardShellReviewHarness(
      clock: () => now,
      deviceSmsGateway: gateway,
    );

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleLocalServicePresentationUseCase: harness.handleLocalServicePresentationUseCase,
    );

    await openDashboardDestination(tester, 'subscriptions');
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);

    // 1. PINNING
    // Open details for Spotify
    await tapAndPumpDashboardShell(tester, find.text('Spotify'));
    
    // Open local service controls (rename/pin)
    await tapAndPumpDashboardShell(tester, find.widgetWithText(OutlinedButton, 'Manage device'));
    
    expect(find.text('Pin near top'), findsOneWidget);
    await tapAndPumpDashboardShell(tester, find.widgetWithText(OutlinedButton, 'Pin near top'));

    // Verify sheet is closed
    await settleDashboard(tester);
    expect(find.text('Manage device'), findsNothing);

    // Check that Spotify is now in a pinned/top position
    final rowFinder = find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key as ValueKey<String>).value.startsWith('passport-card-'));
    expect(find.descendant(of: rowFinder.at(0), matching: find.text('Spotify')), findsOneWidget);

    // 2. RENAMING
    await tapAndPumpDashboardShell(tester, find.text('Spotify'));
    await tapAndPumpDashboardShell(tester, find.widgetWithText(OutlinedButton, 'Manage device'));
    
    final inputKey = const ValueKey<String>('local-label-input-SPOTIFY');
    await tester.enterText(find.byKey(inputKey), 'Music Premium');
    await tester.pump();
    
    // Verify save button is present and enabled
    final saveButtonFinder = find.byWidgetPredicate((widget) => 
      widget is FilledButton && 
      widget.child is Text && ((widget.child as Text).data == 'Save name' || (widget.child as Text).data == 'Update')
    );
    expect(saveButtonFinder, findsOneWidget);
    final saveButton = tester.widget<FilledButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNotNull, reason: 'Save button should be enabled');
    
    await tester.tap(saveButtonFinder);
    await tester.pump(); 
    await tester.pump(const Duration(seconds: 1)); 
    await settleDashboard(tester); 

    // Verify sheet is closed
    expect(find.text('Manage device'), findsNothing, reason: 'Sheet should be closed after save');

    // Wait a bit more for projection and state update
    await tester.pump(const Duration(milliseconds: 500));
    await settleDashboard(tester);

    expect(find.text('Music Premium'), findsOneWidget, reason: 'Music Premium should be visible on the card');
    expect(find.text('Spotify'), findsNothing);

    // 3. UNPINNING
    await tapAndPumpDashboardShell(tester, find.text('Music Premium'));
    await tapAndPumpDashboardShell(tester, find.widgetWithText(OutlinedButton, 'Manage device'));
    
    expect(find.text('Unpin'), findsOneWidget);
    await tapAndPumpDashboardShell(tester, find.widgetWithText(OutlinedButton, 'Unpin'));
    await settleDashboard(tester);

    // 4. RESET LABEL
    await tapAndPumpDashboardShell(tester, find.text('Music Premium'));
    await tapAndPumpDashboardShell(tester, find.widgetWithText(OutlinedButton, 'Manage device'));
    
    await tapAndPumpDashboardShell(tester, find.widgetWithText(TextButton, 'Clear name'));
    await settleDashboard(tester);
    
    expect(find.text('Spotify'), findsOneWidget);
    expect(find.text('Music Premium'), findsNothing);
  });
}

