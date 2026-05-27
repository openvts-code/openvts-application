import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/live_map/models/live_map_role_config.dart';

void main() {
  group('LiveMapRoleConfig vehicle detail endpoints', () {
    test('use the backend details route for every role', () {
      expect(
        LiveMapRoleConfig.superadmin().vehicleDetailsByImei('867440060976859'),
        '/superadmin/vehicles/by-imei/867440060976859/details',
      );
      expect(
        LiveMapRoleConfig.admin().vehicleDetailsByImei('867440060976859'),
        '/admin/vehicles/by-imei/867440060976859/details',
      );
      expect(
        LiveMapRoleConfig.user().vehicleDetailsByImei('867440060976859'),
        '/user/vehicles/by-imei/867440060976859/details',
      );
    });

    test('encodes raw IMEI values before appending details', () {
      expect(
        LiveMapRoleConfig.superadmin().vehicleDetailsByImei('imei/with space'),
        '/superadmin/vehicles/by-imei/imei%2Fwith%20space/details',
      );
    });
  });
}
