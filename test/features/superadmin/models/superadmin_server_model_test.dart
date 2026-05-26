import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/models/superadmin_server_model.dart';

void main() {
  test('parses memory and disk metrics from bytes and fractional percentages',
      () {
    final overview = SuperadminServerOverview.fromJson(<String, dynamic>{
      'checkedAt': '2026-05-15T10:47:00.000Z',
      'systemMetrics': <String, dynamic>{
        'cpu': <String, dynamic>{
          'cores': 2,
          'loadavg': <double>[0, 0, 0],
          'usagePercent': 0,
        },
        'memory': <String, dynamic>{
          'used': <String, dynamic>{
            'value': 2791728742,
            'unit': 'bytes',
          },
          'total': <String, dynamic>{
            'value': 8482560410,
            'unit': 'bytes',
          },
          'usagePercent': 0.33,
        },
        'primaryDisk': <String, dynamic>{
          'mount': 'C:',
          'used': <String, dynamic>{
            'value': 39084202394,
            'unit': 'bytes',
          },
          'total': <String, dynamic>{
            'value': 107374182400,
            'unit': 'bytes',
          },
          'usage': 0.364,
        },
        'uptimeSeconds': 1199820,
      },
      'components': <Map<String, dynamic>>[],
    });

    expect(overview.memoryPercent, closeTo(33, 0.001));
    expect(overview.memoryUsedGb, closeTo(2.6, 0.05));
    expect(overview.memoryTotalGb, closeTo(7.9, 0.05));

    expect(overview.diskPercent, closeTo(36.4, 0.01));
    expect(overview.diskUsedGb, closeTo(36.4, 0.05));
    expect(overview.diskTotalGb, closeTo(100.0, 0.01));
    expect(overview.diskLabel, 'C:');
  });

  test('parses mixed MB and summary-string payloads into GB values', () {
    final overview = SuperadminServerOverview.fromJson(<String, dynamic>{
      'metrics': <String, dynamic>{
        'ram': <String, dynamic>{
          'used': 2662.4,
          'total': 8089.6,
          'unit': 'MB',
          'summary': '33% • 2.6 GB/7.9 GB',
        },
        'storage': <String, dynamic>{
          'drive': 'C:',
          'usageText': 'C: 36% • 36.4 GB/100.0 GB',
        },
      },
      'services': <Map<String, dynamic>>[],
    });

    expect(overview.memoryPercent, closeTo(33, 0.001));
    expect(overview.memoryUsedGb, closeTo(2.6, 0.05));
    expect(overview.memoryTotalGb, closeTo(7.9, 0.05));

    expect(overview.diskPercent, closeTo(36, 0.001));
    expect(overview.diskUsedGb, closeTo(36.4, 0.05));
    expect(overview.diskTotalGb, closeTo(100.0, 0.01));
    expect(overview.diskLabel, 'C:');
  });
}
