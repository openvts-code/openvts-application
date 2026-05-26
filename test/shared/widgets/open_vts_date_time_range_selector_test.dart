import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/shared/widgets/open_vts_date_time_range_selector.dart';

void main() {
  group('OpenVtsDateTimeRangeField', () {
    testWidgets('applies a date-only preset range', (tester) async {
      OpenVtsDateTimeRange selectedRange = const OpenVtsDateTimeRange.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return OpenVtsDateTimeRangeField(
                  label: 'Date Range',
                  value: selectedRange,
                  now: DateTime(2026, 5, 16, 9, 41),
                  onChanged: (range) {
                    setState(() => selectedRange = range);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select date range'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Date Range'), findsOneWidget);
      expect(find.text('Last Hour'), findsNothing);

      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(selectedRange.start, DateTime(2026, 5, 10));
      expect(selectedRange.end, DateTime(2026, 5, 16));
    });

    testWidgets('applies a date-time duration preset range', (tester) async {
      OpenVtsDateTimeRange selectedRange = const OpenVtsDateTimeRange.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return OpenVtsDateTimeRangeField(
                  label: 'Date Time Range',
                  value: selectedRange,
                  dateTimeEnabled: true,
                  now: DateTime(2026, 5, 16, 9, 41),
                  onChanged: (range) {
                    setState(() => selectedRange = range);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select date range'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Date & Time Range'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);

      await tester.tap(find.text('Last Hour'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(selectedRange.start, DateTime(2026, 5, 16, 8, 41));
      expect(selectedRange.end, DateTime(2026, 5, 16, 9, 41));
    });
  });
}
