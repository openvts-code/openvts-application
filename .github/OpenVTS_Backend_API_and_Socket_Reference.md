# OpenVTS Backend API & Socket Reference — Updated

Generated from static source review of `openVTS-main/backend/src` on **2026-05-15**.

> Scope: NestJS controller/gateway source, HTTP route decorators, visible controller signatures, DTO/interface/enums referenced from signatures, streaming endpoints, and Socket.IO channels. Runtime behavior can still differ where services parse `FastifyRequest` manually or return raw `FastifyReply`.

## API base URL

```txt
https://app.openvts.io/api
```

## Runtime conventions

- **HTTP platform:** NestJS 11 with Fastify.
- **Backend package version:** `0.0.1`.
- **Body limit:** `8 MB` Fastify body limit.
- **Global validation:** `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, transformOptions: { enableImplicitConversion: true } })`.
- **CORS:** enabled with credentials; methods `GET, PUT, POST, DELETE, OPTIONS, PATCH, HEAD`.
- **Multipart:** Fastify multipart enabled with `fileSize=5MB`, `files=5`, `fields=20`.
- **Uploads:** served from `/uploads/`.
- **Response wrapper:** normal controller returns are wrapped by `ResponseInterceptor` as:

```json
{ "status": "success", "data": {}, "timestamp": "2026-05-15T00:00:00.000Z" }
```

- **Raw responses:** endpoints using `@Res()`, downloads, streams, SSE, or exceptions can bypass the success wrapper.
- **Auth:** protected endpoints require `Authorization: Bearer <jwt>`. Role-gated endpoints additionally use `RolesGuard`.
- **`@HeaderId()`:** derived from authenticated JWT `req.user.userId` or `req.user.sub`; do not send it manually.

## Audit against uploaded document

The uploaded reference says it was generated from `openVTS-main/backend/src` on 2026-05-09. The current backend zip was re-indexed from source.

| Check | Uploaded document | Current backend review | Result |
|---|---:|---:|---|
| HTTP route decorators | 488 | 488 | Endpoint count matches |
| Missing routes in uploaded document | - | 0 | None detected |
| Extra routes in uploaded document not in backend | - | 0 | None detected |
| Indexed TypeScript classes/interfaces/enums | partial in old static export | 521 | Expanded DTO/type indexing |

**Main correction:** route coverage is already aligned with the current backend, but the updated document expands DTO/query/body details using the current TypeScript AST and adds clearer raw-response, multipart, SSE, and socket notes.

## Summary

- **Controllers found:** 16
- **HTTP endpoints found:** 488
- **TypeScript classes/interfaces/enums indexed:** 521
- **Socket/real-time source files indexed:** 14

### Endpoint count by controller

| Controller | Endpoints |
|---|---:|
| `AdminController` | 158 |
| `AgentController` | 3 |
| `AppController` | 19 |
| `AuthController` | 14 |
| `BugReportController` | 1 |
| `GeocodingController` | 3 |
| `HandledataController` | 1 |
| `HealthController` | 9 |
| `PublicTrackController` | 7 |
| `ServerController` | 4 |
| `SslController` | 3 |
| `SslStreamController` | 1 |
| `SuperadminController` | 140 |
| `UserController` | 118 |
| `WhatsAppTemplatesController` | 5 |
| `WhatsappWebhookController` | 2 |

### Endpoint count by access role

| Access | Count |
|---|---:|
| `ADMIN` | 158 |
| `SUPERADMIN` | 152 |
| `ADMIN,USER` | 111 |
| `PUBLIC/UNSPECIFIED` | 48 |
| `USER` | 7 |
| `JWT` | 6 |
| `SUPERADMIN,ADMIN,USER,SUBUSER` | 3 |
| `SUPERADMIN,ADMIN,USER,SUBUSER,TEAM,DRIVER` | 3 |

## Quick endpoint index

| # | Method | Endpoint | Controller.handler | Auth/Roles | Source |
|---:|---|---|---|---|---|
| 1 | `GET` | `/` | `AppController.getHello` | Public / unspecified | `app.controller.ts:18` |
| 2 | `GET` | `/admin/calendar/day` | `AdminController.getCalendarDayDetails` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:971` |
| 3 | `GET` | `/admin/calendar/events` | `AdminController.getCalendarEvents` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:963` |
| 4 | `GET` | `/admin/calendar/user/:uid` | `AdminController.getCalendarUserDetails` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:979` |
| 5 | `GET` | `/admin/commands/:cmdId` | `AdminController.getCommandLogByCmdId` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1323` |
| 6 | `GET` | `/admin/commands/status/:cmdId` | `AdminController.getCommandStatus` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1304` |
| 7 | `PATCH` | `/admin/companydetails` | `AdminController.updateOwnCompanyDetails` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:690` |
| 8 | `GET` | `/admin/companydetails/:id` | `AdminController.getCompanyDetails` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:239` |
| 9 | `PATCH` | `/admin/companydetails/:id` | `AdminController.updateCompanyDetails` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:244` |
| 10 | `PATCH` | `/admin/companyinfo/:id` | `AdminController.updateCompanyInfo` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:587` |
| 11 | `GET` | `/admin/config` | `AdminController.getAdminConfig` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:699` |
| 12 | `PATCH` | `/admin/config` | `AdminController.patchAdminConfig` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:704` |
| 13 | `GET` | `/admin/customcommands` | `AdminController.getCustomCommands` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1281` |
| 14 | `GET` | `/admin/dashboard/summary` | `AdminController.getDashboardSummary` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:83` |
| 15 | `POST` | `/admin/deviceandsim` | `AdminController.createDeviceAndSim` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:283` |
| 16 | `GET` | `/admin/devices` | `AdminController.getDevices` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:249` |
| 17 | `POST` | `/admin/devices` | `AdminController.createDevice` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:254` |
| 18 | `DELETE` | `/admin/devices/:id` | `AdminController.deleteDevice` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:263` |
| 19 | `PATCH` | `/admin/devices/:id` | `AdminController.updateDevice` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:258` |
| 20 | `GET` | `/admin/documents/:userId` | `AdminController.getDocuments` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:742` |
| 21 | `GET` | `/admin/documents/driver/:driverId` | `AdminController.getDriverDocuments` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:755` |
| 22 | `GET` | `/admin/documents/vehicle/:vehicleId` | `AdminController.getVehicleDocuments` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:747` |
| 23 | `POST` | `/admin/driverbulkjobs` | `AdminController.createDriverBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:838` |
| 24 | `GET` | `/admin/driverbulkjobs/:id` | `AdminController.getDriverBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:844` |
| 25 | `GET` | `/admin/driverbulkjobs/:id/failed.csv` | `AdminController.downloadDriverFailedCsv` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:851` |
| 26 | `GET` | `/admin/driverbulkjobs/:id/stream` | `AdminController.streamDriverBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:869` |
| 27 | `GET` | `/admin/drivers` | `AdminController.getDrivers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:562` |
| 28 | `POST` | `/admin/drivers` | `AdminController.createDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:557` |
| 29 | `DELETE` | `/admin/drivers/:id` | `AdminController.deleteDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:582` |
| 30 | `GET` | `/admin/drivers/:id` | `AdminController.getDriverById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:567` |
| 31 | `PATCH` | `/admin/drivers/:id` | `AdminController.updateDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:577` |
| 32 | `GET` | `/admin/drivers/:id/users` | `AdminController.getDriverUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:572` |
| 33 | `GET` | `/admin/drivers/linkedusers/:driverId` | `AdminController.getLinkedUsersForDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:819` |
| 34 | `POST` | `/admin/drivers/linkedusers/:driverId` | `AdminController.linkUsersToDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:827` |
| 35 | `GET` | `/admin/drivers/unlinkedusers/:driverId` | `AdminController.getUnlinkedUsersForDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:823` |
| 36 | `POST` | `/admin/drivers/unlinkedusers/:driverId` | `AdminController.unlinkUsersFromDriver` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:832` |
| 37 | `POST` | `/admin/inventorybulkjobs` | `AdminController.createInventoryBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:369` |
| 38 | `GET` | `/admin/inventorybulkjobs/:id` | `AdminController.getInventoryBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:375` |
| 39 | `GET` | `/admin/inventorybulkjobs/:id/failed.csv` | `AdminController.downloadInventoryFailedCsv` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:382` |
| 40 | `GET` | `/admin/inventorybulkjobs/:id/stream` | `AdminController.streamInventoryBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:400` |
| 41 | `GET` | `/admin/linkusers/:vehicleId` | `AdminController.getLinkedUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:800` |
| 42 | `POST` | `/admin/linkusers/:vehicleId` | `AdminController.linkUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:804` |
| 43 | `GET` | `/admin/linkvehicles/:userId` | `AdminController.getLinkedVehicles` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:778` |
| 44 | `POST` | `/admin/linkvehicles/:userId` | `AdminController.linkVehicles` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:783` |
| 45 | `GET` | `/admin/localization` | `AdminController.getLocalizationData` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:928` |
| 46 | `PATCH` | `/admin/localization` | `AdminController.updateLocalizationData` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:933` |
| 47 | `GET` | `/admin/logs/activity` | `AdminController.getActivityLogs` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1078` |
| 48 | `GET` | `/admin/logs/events` | `AdminController.getEventLogs` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1086` |
| 49 | `GET` | `/admin/logs/events/:id` | `AdminController.getEventLogById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1094` |
| 50 | `GET` | `/admin/logs/options` | `AdminController.getLogsOptions` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1073` |
| 51 | `GET` | `/admin/logs/telemetry` | `AdminController.getTelemetryLogs` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1102` |
| 52 | `GET` | `/admin/logs/telemetry/:id` | `AdminController.getTelemetryLogById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1110` |
| 53 | `GET` | `/admin/map-events` | `AdminController.getMapEvents` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1127` |
| 54 | `GET` | `/admin/map-telemetry` | `AdminController.getMapTelemetry` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1122` |
| 55 | `GET` | `/admin/mytickets` | `AdminController.listAdminMyTickets` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:163` |
| 56 | `POST` | `/admin/mytickets` | `AdminController.createAdminMyTicket` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:172` |
| 57 | `GET` | `/admin/mytickets/:id` | `AdminController.getAdminMyTicketById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:181` |
| 58 | `POST` | `/admin/mytickets/:id/messages` | `AdminController.replyAdminMyTicket` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:189` |
| 59 | `PATCH` | `/admin/mytickets/:id/status` | `AdminController.updateAdminMyTicketStatus` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:199` |
| 60 | `GET` | `/admin/notifications` | `AdminController.getNotifications` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1251` |
| 61 | `PATCH` | `/admin/notifications/:id/read` | `AdminController.markNotificationRead` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1269` |
| 62 | `PATCH` | `/admin/notifications/read-all` | `AdminController.markAllNotificationsRead` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1262` |
| 63 | `GET` | `/admin/payments` | `AdminController.listAdminPayments` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1022` |
| 64 | `POST` | `/admin/payments/renew` | `AdminController.renewVehiclesPayment` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1037` |
| 65 | `GET` | `/admin/pricingplans` | `AdminController.getPricingPlans` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:763` |
| 66 | `POST` | `/admin/pricingplans` | `AdminController.createPricingPlan` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:768` |
| 67 | `PATCH` | `/admin/pricingplans/:id` | `AdminController.updatePricingPlan` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:773` |
| 68 | `GET` | `/admin/profile` | `AdminController.getProfile` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:630` |
| 69 | `PATCH` | `/admin/profile` | `AdminController.updateProfile` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:635` |
| 70 | `GET` | `/admin/profile/email-subscription` | `AdminController.getEmailSubscription` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:668` |
| 71 | `POST` | `/admin/profile/email-subscription/subscribe` | `AdminController.subscribeEmail` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:679` |
| 72 | `POST` | `/admin/profile/verify/email/confirm` | `AdminController.verifyEmailOtp` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:649` |
| 73 | `POST` | `/admin/profile/verify/email/request` | `AdminController.requestEmailOtp` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:644` |
| 74 | `POST` | `/admin/profile/verify/whatsapp/confirm` | `AdminController.verifyWhatsAppOtp` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:659` |
| 75 | `POST` | `/admin/profile/verify/whatsapp/request` | `AdminController.requestWhatsAppOtp` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:654` |
| 76 | `GET` | `/admin/quickdevice` | `AdminController.getQuickDevices` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:301` |
| 77 | `POST` | `/admin/quickdevice` | `AdminController.createQuickDevice` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:308` |
| 78 | `GET` | `/admin/quicksimcards` | `AdminController.getQuickSimCards` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:314` |
| 79 | `GET` | `/admin/shortusers` | `AdminController.getShortUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:104` |
| 80 | `GET` | `/admin/simcards` | `AdminController.getSimCards` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:268` |
| 81 | `POST` | `/admin/simcards` | `AdminController.createSimCard` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:273` |
| 82 | `DELETE` | `/admin/simcards/:id` | `AdminController.deleteSimCard` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:278` |
| 83 | `GET` | `/admin/simcards/:id` | `AdminController.getSimCardById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:289` |
| 84 | `PATCH` | `/admin/simcards/:id` | `AdminController.updateSimCard` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:294` |
| 85 | `GET` | `/admin/smtpconfig` | `AdminController.getSmtpConfig` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:592` |
| 86 | `PATCH` | `/admin/smtpconfig` | `AdminController.patchSmtpConfig` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:603` |
| 87 | `POST` | `/admin/smtpconfig` | `AdminController.updateSmtpConfig` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:597` |
| 88 | `GET` | `/admin/systemvariables` | `AdminController.getSystemVariables` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1286` |
| 89 | `GET` | `/admin/teams` | `AdminController.getTeams` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:903` |
| 90 | `POST` | `/admin/teams` | `AdminController.createTeam` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:907` |
| 91 | `DELETE` | `/admin/teams/:id` | `AdminController.deleteTeam` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:919` |
| 92 | `GET` | `/admin/teams/:id` | `AdminController.getTeamById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:911` |
| 93 | `PATCH` | `/admin/teams/:id` | `AdminController.updateTeam` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:915` |
| 94 | `POST` | `/admin/testsmtp` | `AdminController.testSmtpSettings` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:608` |
| 95 | `GET` | `/admin/tickets` | `AdminController.listAdminTickets` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:113` |
| 96 | `POST` | `/admin/tickets` | `AdminController.createAdminTicket` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:131` |
| 97 | `GET` | `/admin/tickets/:id` | `AdminController.getAdminTicketById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:123` |
| 98 | `POST` | `/admin/tickets/:id/messages` | `AdminController.replyAdminTicket` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:140` |
| 99 | `PATCH` | `/admin/tickets/:id/status` | `AdminController.updateAdminTicketStatus` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:150` |
| 100 | `GET` | `/admin/topbar-search` | `AdminController.searchTopbar` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:91` |
| 101 | `GET` | `/admin/transactions` | `AdminController.listAdminTransactions` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:991` |
| 102 | `GET` | `/admin/transactions/analytics` | `AdminController.transactionsAnalytics` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1005` |
| 103 | `POST` | `/admin/transactions/renew` | `AdminController.renewVehicles` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1047` |
| 104 | `GET` | `/admin/unlinkusers/:vehicleId` | `AdminController.getUnlinkedUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:809` |
| 105 | `POST` | `/admin/unlinkusers/:vehicleId` | `AdminController.unlinkUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:813` |
| 106 | `GET` | `/admin/unlinkvehicles/:userId` | `AdminController.getUnlinkedVehicles` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:789` |
| 107 | `POST` | `/admin/unlinkvehicles/:userId` | `AdminController.unlinkVehicles` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:794` |
| 108 | `PATCH` | `/admin/updatepassword` | `AdminController.patchPasswordAdmin` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:620` |
| 109 | `POST` | `/admin/updatepassword` | `AdminController.updatePasswordAdmin` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:613` |
| 110 | `POST` | `/admin/updateuserpassword/:id` | `AdminController.updatePassword` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:233` |
| 111 | `POST` | `/admin/upload` | `AdminController.uploadFile` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:709` |
| 112 | `POST` | `/admin/uploaddoc` | `AdminController.uploadDocument` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:723` |
| 113 | `DELETE` | `/admin/uploaddoc/:id` | `AdminController.deleteDocument` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:733` |
| 114 | `PATCH` | `/admin/uploaddoc/:id` | `AdminController.updateDocument` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:728` |
| 115 | `POST` | `/admin/userbulkjobs` | `AdminController.createUserBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:417` |
| 116 | `GET` | `/admin/userbulkjobs/:id` | `AdminController.getUserBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:423` |
| 117 | `GET` | `/admin/userbulkjobs/:id/failed.csv` | `AdminController.downloadUserFailedCsv` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:430` |
| 118 | `GET` | `/admin/userbulkjobs/:id/stream` | `AdminController.streamUserBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:444` |
| 119 | `GET` | `/admin/userlogin/:id` | `AdminController.adminLogin` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:223` |
| 120 | `GET` | `/admin/users` | `AdminController.getUsers` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:99` |
| 121 | `POST` | `/admin/users` | `AdminController.createUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:208` |
| 122 | `DELETE` | `/admin/users/:id` | `AdminController.deleteUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:228` |
| 123 | `GET` | `/admin/users/:id` | `AdminController.getUserById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:213` |
| 124 | `PATCH` | `/admin/users/:id` | `AdminController.updateUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:218` |
| 125 | `GET` | `/admin/users/:id/activitylogs` | `AdminController.getUserActivityLogs` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1060` |
| 126 | `GET` | `/admin/users/linkeddrivers/:userId` | `AdminController.getLinkedDriversForUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:884` |
| 127 | `POST` | `/admin/users/linkeddrivers/:userId` | `AdminController.linkDriversToUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:892` |
| 128 | `GET` | `/admin/users/unlinkeddrivers/:userId` | `AdminController.getUnlinkedDriversForUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:888` |
| 129 | `POST` | `/admin/users/unlinkeddrivers/:userId` | `AdminController.unlinkDriversFromUser` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:897` |
| 130 | `POST` | `/admin/vehiclebulkjobs` | `AdminController.createVehicleBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:321` |
| 131 | `GET` | `/admin/vehiclebulkjobs/:id` | `AdminController.getVehicleBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:327` |
| 132 | `GET` | `/admin/vehiclebulkjobs/:id/failed.csv` | `AdminController.downloadFailedCsv` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:334` |
| 133 | `GET` | `/admin/vehiclebulkjobs/:id/stream` | `AdminController.streamVehicleBulkJob` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:352` |
| 134 | `GET` | `/admin/vehicles` | `AdminController.getVehicles` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:459` |
| 135 | `POST` | `/admin/vehicles` | `AdminController.createVehicle` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:464` |
| 136 | `DELETE` | `/admin/vehicles/:id` | `AdminController.deleteVehicle` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:479` |
| 137 | `GET` | `/admin/vehicles/:id` | `AdminController.getVehicleById` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:474` |
| 138 | `PATCH` | `/admin/vehicles/:id` | `AdminController.updateVehicle` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:469` |
| 139 | `PATCH` | `/admin/vehicles/:id/config` | `AdminController.updateVehicleConfig` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:484` |
| 140 | `GET` | `/admin/vehicles/:vehicleId/sensors` | `AdminController.listVehicleSensors` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:497` |
| 141 | `POST` | `/admin/vehicles/:vehicleId/sensors` | `AdminController.createVehicleSensor` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:512` |
| 142 | `DELETE` | `/admin/vehicles/:vehicleId/sensors/:sensorId` | `AdminController.deleteVehicleSensor` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:531` |
| 143 | `PATCH` | `/admin/vehicles/:vehicleId/sensors/:sensorId` | `AdminController.updateVehicleSensor` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:521` |
| 144 | `POST` | `/admin/vehicles/:vehicleId/sensors/run` | `AdminController.runVehicleSensor` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:540` |
| 145 | `GET` | `/admin/vehicles/:vehicleId/sensors/telemetry` | `AdminController.getVehicleSensorTelemetry` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:549` |
| 146 | `GET` | `/admin/vehicles/by-imei/:imei/commands` | `AdminController.getCommandHistoryByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1313` |
| 147 | `GET` | `/admin/vehicles/by-imei/:imei/details` | `AdminController.getVehicleDetailsByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1135` |
| 148 | `GET` | `/admin/vehicles/by-imei/:imei/events` | `AdminController.getVehicleEventsByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1155` |
| 149 | `GET` | `/admin/vehicles/by-imei/:imei/events/export` | `AdminController.exportVehicleEventsCsv` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1181` |
| 150 | `GET` | `/admin/vehicles/by-imei/:imei/history` | `AdminController.getVehicleHistoryByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1223` |
| 151 | `GET` | `/admin/vehicles/by-imei/:imei/logs` | `AdminController.getVehicleLogsByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1143` |
| 152 | `GET` | `/admin/vehicles/by-imei/:imei/logs/export` | `AdminController.exportVehicleLogsCsv` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1164` |
| 153 | `GET` | `/admin/vehicles/by-imei/:imei/replay` | `AdminController.getVehicleReplayByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1212` |
| 154 | `POST` | `/admin/vehicles/by-imei/:imei/send-command` | `AdminController.sendDeviceCommandByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1295` |
| 155 | `GET` | `/admin/vehicles/by-imei/:imei/sensors` | `AdminController.getVehicleSensorsByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1238` |
| 156 | `GET` | `/admin/vehicles/by-imei/:imei/trail` | `AdminController.getVehicleTrailByImei` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:1200` |
| 157 | `GET` | `/admin/whitelabel` | `AdminController.getWhiteLabelSettings` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:941` |
| 158 | `PATCH` | `/admin/whitelabel` | `AdminController.updateWhiteLabelSettings` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:951` |
| 159 | `GET` | `/admin/whitelabel/inspect` | `AdminController.inspectWhiteLabelBranding` | Bearer JWT; roles: ADMIN | `admin/admin.controller.ts:946` |
| 160 | `POST` | `/agent/commands` | `AgentController.createCommand` | Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER | `agent/controllers/agent.controller.ts:33` |
| 161 | `GET` | `/agent/executions/:executionId` | `AgentController.getExecution` | Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER | `agent/controllers/agent.controller.ts:55` |
| 162 | `GET` | `/agent/executions/:executionId/status` | `AgentController.getExecutionStatus` | Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER | `agent/controllers/agent.controller.ts:75` |
| 163 | `GET` | `/auth/checksadmin` | `AuthController.getChecksAdmin` | Public / unspecified | `auth/controllers/auth.controller.ts:22` |
| 164 | `POST` | `/auth/createsuperadmin` | `AuthController.createSuperAdmin` | Public / unspecified | `auth/controllers/auth.controller.ts:28` |
| 165 | `POST` | `/auth/email-test` | `AuthController.testEmail` | Bearer JWT | `auth/controllers/auth.controller.ts:129` |
| 166 | `GET` | `/auth/fcm-web-config` | `AuthController.getFcmWebConfig` | Public / unspecified | `auth/controllers/auth.controller.ts:88` |
| 167 | `POST` | `/auth/forgot-password` | `AuthController.forgotPassword` | Public / unspecified | `auth/controllers/auth.controller.ts:52` |
| 168 | `GET` | `/auth/google/client-id` | `AuthController.getGoogleClientId` | Public / unspecified | `auth/controllers/auth.controller.ts:71` |
| 169 | `POST` | `/auth/google/login` | `AuthController.googleLogin` | Public / unspecified | `auth/controllers/auth.controller.ts:81` |
| 170 | `POST` | `/auth/login` | `AuthController.login` | Public / unspecified | `auth/controllers/auth.controller.ts:38` |
| 171 | `POST` | `/auth/push-test` | `AuthController.testPush` | Bearer JWT | `auth/controllers/auth.controller.ts:119` |
| 172 | `DELETE` | `/auth/push-token` | `AuthController.removePushToken` | Bearer JWT | `auth/controllers/auth.controller.ts:103` |
| 173 | `POST` | `/auth/push-token` | `AuthController.registerPushToken` | Bearer JWT | `auth/controllers/auth.controller.ts:93` |
| 174 | `GET` | `/auth/push-tokens/me` | `AuthController.getMyPushTokens` | Bearer JWT | `auth/controllers/auth.controller.ts:113` |
| 175 | `POST` | `/auth/refresh-token` | `AuthController.refreshToken` | Public / unspecified | `auth/controllers/auth.controller.ts:44` |
| 176 | `POST` | `/auth/reset-password` | `AuthController.resetPassword` | Public / unspecified | `auth/controllers/auth.controller.ts:58` |
| 177 | `GET` | `/branding` | `AppController.getBranding` | Public / unspecified | `app.controller.ts:221` |
| 178 | `POST` | `/bug-reports` | `BugReportController.create` | Bearer JWT | `bug-report/bug-report.controller.ts:28` |
| 179 | `GET` | `/cities/:countryCode/:stateCode` | `AppController.getCities` | Public / unspecified | `app.controller.ts:150` |
| 180 | `GET` | `/countries` | `AppController.getCountries` | Public / unspecified | `app.controller.ts:139` |
| 181 | `GET` | `/currencies` | `AppController.getCurrencies` | Public / unspecified | `app.controller.ts:158` |
| 182 | `GET` | `/dateformats` | `AppController.getDateFormats` | Public / unspecified | `app.controller.ts:211` |
| 183 | `GET` | `/devicestypes` | `AppController.getDeviceTypes` | Public / unspecified | `app.controller.ts:123` |
| 184 | `GET` | `/documenttypes/:documentType` | `AppController.getDocumentTypes` | Public / unspecified | `app.controller.ts:216` |
| 185 | `GET` | `/geocoding/precision` | `GeocodingController.precision` | Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER | `geocoding/geocoding.controller.ts:111` |
| 186 | `GET` | `/geocoding/reverse` | `GeocodingController.reverse` | Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER | `geocoding/geocoding.controller.ts:35` |
| 187 | `POST` | `/geocoding/reverse/bulk` | `GeocodingController.reverseBulk` | Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER | `geocoding/geocoding.controller.ts:87` |
| 188 | `POST` | `/handledata` | `HandledataController.handleData` | Public / unspecified | `handledata/handledata.controller.ts:8` |
| 189 | `GET` | `/health` | `HealthController.getHealth` | Public / unspecified | `health/health.controller.ts:47` |
| 190 | `GET` | `/health/address-db` | `HealthController.getAddressDbHealth` | Public / unspecified | `health/health.controller.ts:130` |
| 191 | `GET` | `/health/databases` | `HealthController.getDatabasesHealth` | Public / unspecified | `health/health.controller.ts:77` |
| 192 | `GET` | `/health/logs-db` | `HealthController.getLogsDbHealth` | Public / unspecified | `health/health.controller.ts:120` |
| 193 | `GET` | `/health/primary-db` | `HealthController.getPrimaryDbHealth` | Public / unspecified | `health/health.controller.ts:110` |
| 194 | `GET` | `/health/telemetry-diagnostics/:imei` | `HealthController.getTelemetryDiagnostics` | Public / unspecified | `health/health.controller.ts:167` |
| 195 | `GET` | `/health/telemetry-packet/:imei/:sourcePacketId` | `HealthController.getTelemetryPacket` | Public / unspecified | `health/health.controller.ts:178` |
| 196 | `GET` | `/health/telemetry-stats` | `HealthController.getTelemetryStats` | Public / unspecified | `health/health.controller.ts:140` |
| 197 | `GET` | `/health/telemetry-stats/:imei` | `HealthController.getImeiTelemetryStats` | Public / unspecified | `health/health.controller.ts:156` |
| 198 | `GET` | `/languages` | `AppController.getLanguages` | Public / unspecified | `app.controller.ts:173` |
| 199 | `GET` | `/mobileprefix` | `AppController.getMobileCode` | Public / unspecified | `app.controller.ts:133` |
| 200 | `GET` | `/policies` | `AppController.getPolicies` | Public / unspecified | `app.controller.ts:178` |
| 201 | `GET` | `/policies/:type` | `AppController.getPolicyByType` | Public / unspecified | `app.controller.ts:192` |
| 202 | `GET` | `/public/track/:code` | `PublicTrackController.getLinkMeta` | Public / unspecified | `public-track/public-track.controller.ts:18` |
| 203 | `GET` | `/public/track/:code/geofences` | `PublicTrackController.getGeofences` | Public / unspecified | `public-track/public-track.controller.ts:66` |
| 204 | `GET` | `/public/track/:code/telemetry` | `PublicTrackController.getMapTelemetry` | Public / unspecified | `public-track/public-track.controller.ts:23` |
| 205 | `GET` | `/public/track/:code/vehicles/:imei/details` | `PublicTrackController.getVehicleDetailsByImei` | Public / unspecified | `public-track/public-track.controller.ts:28` |
| 206 | `GET` | `/public/track/:code/vehicles/:imei/history` | `PublicTrackController.getVehicleHistoryByImei` | Public / unspecified | `public-track/public-track.controller.ts:47` |
| 207 | `GET` | `/public/track/:code/vehicles/:imei/logs` | `PublicTrackController.getVehicleLogsByImei` | Public / unspecified | `public-track/public-track.controller.ts:71` |
| 208 | `GET` | `/public/track/:code/vehicles/:imei/replay` | `PublicTrackController.getVehicleReplayByImei` | Public / unspecified | `public-track/public-track.controller.ts:36` |
| 209 | `GET` | `/simproviders` | `AppController.getSimProviders` | Public / unspecified | `app.controller.ts:163` |
| 210 | `GET` | `/states/:countryCode` | `AppController.getStates` | Public / unspecified | `app.controller.ts:145` |
| 211 | `GET` | `/status` | `AppController.getStatus` | Public / unspecified | `app.controller.ts:116` |
| 212 | `POST` | `/superadmin/activateadmin/:id` | `SuperadminController.activateAdmin` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:154` |
| 213 | `GET` | `/superadmin/admin/:id` | `SuperadminController.getAdminById` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:142` |
| 214 | `GET` | `/superadmin/admin/:id/activitylogs` | `SuperadminController.getAdminActivityLogs` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:665` |
| 215 | `GET` | `/superadmin/adminlist` | `SuperadminController.getAdminList` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:137` |
| 216 | `GET` | `/superadmin/adminlogin/:id` | `SuperadminController.adminLogin` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:163` |
| 217 | `POST` | `/superadmin/adminpasswordupdate` | `SuperadminController.updateAdminPassword` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:149` |
| 218 | `GET` | `/superadmin/adminvehicles/:adminId` | `SuperadminController.getAdminVehiclesList` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:675` |
| 219 | `GET` | `/superadmin/appnotifytemplates` | `SuperadminController.getAppNotifyTemplates` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:408` |
| 220 | `GET` | `/superadmin/appnotifytemplates/:id` | `SuperadminController.getAppNotifyTemplateById` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:412` |
| 221 | `PATCH` | `/superadmin/appnotifytemplates/:id` | `SuperadminController.updateAppNotifyTemplate` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:416` |
| 222 | `POST` | `/superadmin/assigncredits/:id` | `SuperadminController.assignCredits` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:174` |
| 223 | `GET` | `/superadmin/calendar/day` | `SuperadminController.getCalendarDayDetails` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:719` |
| 224 | `GET` | `/superadmin/calendar/events` | `SuperadminController.getCalendarEvents` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:714` |
| 225 | `GET` | `/superadmin/calendar/user/:uid` | `SuperadminController.getCalendarUserDetails` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:724` |
| 226 | `GET` | `/superadmin/commands/:cmdId` | `SuperadminController.getCommandLogByCmdId` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1036` |
| 227 | `GET` | `/superadmin/commands/status/:cmdId` | `SuperadminController.getCommandStatus` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1018` |
| 228 | `GET` | `/superadmin/commandtypes` | `SuperadminController.getCommandTypes` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:294` |
| 229 | `POST` | `/superadmin/commandtypes` | `SuperadminController.createCommandType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:298` |
| 230 | `DELETE` | `/superadmin/commandtypes/:id` | `SuperadminController.deleteCommandType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:306` |
| 231 | `PATCH` | `/superadmin/commandtypes/:id` | `SuperadminController.updateCommandType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:302` |
| 232 | `GET` | `/superadmin/companyconfig/:id` | `SuperadminController.getCompanyConfig` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:236` |
| 233 | `PATCH` | `/superadmin/companyconfig/:id` | `SuperadminController.updateCompanyConfig` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:241` |
| 234 | `PATCH` | `/superadmin/companydetails` | `SuperadminController.updateCompanyDetails` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:615` |
| 235 | `POST` | `/superadmin/createadmin` | `SuperadminController.createAdmin` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:132` |
| 236 | `GET` | `/superadmin/creditlogs/:id` | `SuperadminController.getCreditLogs` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:179` |
| 237 | `GET` | `/superadmin/customcommands` | `SuperadminController.getCustomCommands` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:328` |
| 238 | `POST` | `/superadmin/customcommands` | `SuperadminController.createCustomCommand` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:332` |
| 239 | `DELETE` | `/superadmin/customcommands/:id` | `SuperadminController.deleteCustomCommand` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:340` |
| 240 | `PATCH` | `/superadmin/customcommands/:id` | `SuperadminController.updateCustomCommand` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:336` |
| 241 | `GET` | `/superadmin/dashboard/activitylogs` | `SuperadminController.getDashboardActivityLogs` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:650` |
| 242 | `GET` | `/superadmin/dashboard/adoptiongraph` | `SuperadminController.getAdoptionGraph` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:659` |
| 243 | `GET` | `/superadmin/dashboard/overview` | `SuperadminController.getDashboardOverview` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:627` |
| 244 | `GET` | `/superadmin/dashboard/recentusers` | `SuperadminController.getRecentUsers` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:639` |
| 245 | `GET` | `/superadmin/dashboard/recentvehicles` | `SuperadminController.getRecentVehicles` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:633` |
| 246 | `GET` | `/superadmin/dashboard/totalcounts` | `SuperadminController.getTotalCounts` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:644` |
| 247 | `DELETE` | `/superadmin/deleteadmin/:id` | `SuperadminController.deleteAdmin` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:184` |
| 248 | `POST` | `/superadmin/devices/:imei/send-command` | `SuperadminController.sendDeviceCommand` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1009` |
| 249 | `GET` | `/superadmin/devicetypes` | `SuperadminController.getDeviceTypes` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:311` |
| 250 | `POST` | `/superadmin/devicetypes` | `SuperadminController.createDeviceType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:315` |
| 251 | `DELETE` | `/superadmin/devicetypes/:id` | `SuperadminController.deleteDeviceType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:323` |
| 252 | `PATCH` | `/superadmin/devicetypes/:id` | `SuperadminController.updateDeviceType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:319` |
| 253 | `GET` | `/superadmin/documents/:adminId` | `SuperadminController.getDocuments` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:458` |
| 254 | `GET` | `/superadmin/documenttypes` | `SuperadminController.getDocumentTypes` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:362` |
| 255 | `POST` | `/superadmin/documenttypes` | `SuperadminController.createDocumentType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:366` |
| 256 | `DELETE` | `/superadmin/documenttypes/:id` | `SuperadminController.deleteDocumentType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:374` |
| 257 | `PATCH` | `/superadmin/documenttypes/:id` | `SuperadminController.updateDocumentType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:370` |
| 258 | `GET` | `/superadmin/domainlist` | `SuperadminController.getDomainList` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:681` |
| 259 | `GET` | `/superadmin/emailtemplates` | `SuperadminController.getEmailTemplates` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:396` |
| 260 | `GET` | `/superadmin/emailtemplates/:id` | `SuperadminController.getEmailTemplateById` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:400` |
| 261 | `PATCH` | `/superadmin/emailtemplates/:id` | `SuperadminController.updateEmailTemplate` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:404` |
| 262 | `POST` | `/superadmin/ftkey/deactivate` | `SuperadminController.deactivateFtkey` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:705` |
| 263 | `POST` | `/superadmin/ftkey/recheck` | `SuperadminController.recheckFtkey` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:700` |
| 264 | `GET` | `/superadmin/ftkey/status` | `SuperadminController.getFtkeyStatus` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:690` |
| 265 | `POST` | `/superadmin/ftkey/validate` | `SuperadminController.validateFtkey` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:695` |
| 266 | `GET` | `/superadmin/geofences` | `SuperadminController.getAllGeofences` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:783` |
| 267 | `GET` | `/superadmin/integrations` | `SuperadminController.listIntegrations` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:855` |
| 268 | `POST` | `/superadmin/integrations` | `SuperadminController.upsertIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:863` |
| 269 | `DELETE` | `/superadmin/integrations/:id` | `SuperadminController.deleteIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:958` |
| 270 | `PATCH` | `/superadmin/integrations/:id` | `SuperadminController.updateIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:872` |
| 271 | `GET` | `/superadmin/integrations/:id/openrouter/models` | `SuperadminController.getOpenRouterModels` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:920` |
| 272 | `POST` | `/superadmin/integrations/:id/rotate-secret` | `SuperadminController.rotateIntegrationSecret` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:881` |
| 273 | `POST` | `/superadmin/integrations/:id/test-fcm` | `SuperadminController.testFcmIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:891` |
| 274 | `POST` | `/superadmin/integrations/:id/test-openrouter` | `SuperadminController.testOpenRouterIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:928` |
| 275 | `POST` | `/superadmin/integrations/:id/test-whatsapp` | `SuperadminController.testWhatsAppIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:910` |
| 276 | `POST` | `/superadmin/integrations/:id/validate-geocoding` | `SuperadminController.validateGeocodingIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:948` |
| 277 | `POST` | `/superadmin/integrations/:id/validate-google-sso` | `SuperadminController.validateGoogleSsoIntegration` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:938` |
| 278 | `GET` | `/superadmin/localization` | `SuperadminController.getLocalizationData` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:569` |
| 279 | `PATCH` | `/superadmin/localization` | `SuperadminController.updateLocalizationData` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:574` |
| 280 | `GET` | `/superadmin/map-events` | `SuperadminController.getMapEvents` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:981` |
| 281 | `GET` | `/superadmin/map-telemetry` | `SuperadminController.getMapTelemetry` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:761` |
| 282 | `GET` | `/superadmin/notifications` | `SuperadminController.getNotifications` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1060` |
| 283 | `PATCH` | `/superadmin/notifications/:id/read` | `SuperadminController.markNotificationRead` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1075` |
| 284 | `PATCH` | `/superadmin/notifications/read-all` | `SuperadminController.markAllNotificationsRead` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1068` |
| 285 | `POST` | `/superadmin/notifications/test-fcm-me` | `SuperadminController.testFcmToMe` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:901` |
| 286 | `GET` | `/superadmin/openrouter/models` | `SuperadminController.listOpenRouterModels` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:970` |
| 287 | `GET` | `/superadmin/pois` | `SuperadminController.getAllPois` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:788` |
| 288 | `PATCH` | `/superadmin/policy` | `SuperadminController.updatePolicy` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:609` |
| 289 | `POST` | `/superadmin/policy` | `SuperadminController.createPolicy` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:604` |
| 290 | `GET` | `/superadmin/profile` | `SuperadminController.getProfile` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:473` |
| 291 | `PATCH` | `/superadmin/profile` | `SuperadminController.updateProfile` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:478` |
| 292 | `GET` | `/superadmin/profile/email-subscription` | `SuperadminController.getEmailSubscription` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:511` |
| 293 | `POST` | `/superadmin/profile/email-subscription/subscribe` | `SuperadminController.subscribeEmail` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:522` |
| 294 | `POST` | `/superadmin/profile/verify/email/confirm` | `SuperadminController.verifyEmailOtp` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:492` |
| 295 | `POST` | `/superadmin/profile/verify/email/request` | `SuperadminController.requestEmailOtp` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:487` |
| 296 | `POST` | `/superadmin/profile/verify/whatsapp/confirm` | `SuperadminController.verifyWhatsAppOtp` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:502` |
| 297 | `POST` | `/superadmin/profile/verify/whatsapp/request` | `SuperadminController.requestWhatsAppOtp` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:497` |
| 298 | `GET` | `/superadmin/routes` | `SuperadminController.getAllRoutes` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:793` |
| 299 | `POST` | `/superadmin/server/actions` | `ServerController.createServerActionJob` | Bearer JWT; roles: SUPERADMIN | `superadmin/server/server.controller.ts:31` |
| 300 | `GET` | `/superadmin/server/jobs/:id` | `ServerController.getServerActionJob` | Bearer JWT; roles: SUPERADMIN | `superadmin/server/server.controller.ts:44` |
| 301 | `GET` | `/superadmin/server/jobs/:id/stream` | `ServerController.streamServerActionJob` | Bearer JWT; roles: SUPERADMIN | `superadmin/server/server.controller.ts:67` |
| 302 | `GET` | `/superadmin/server/overview` | `ServerController.getOverview` | Bearer JWT; roles: SUPERADMIN | `superadmin/server/server.controller.ts:21` |
| 303 | `GET` | `/superadmin/settings/:id` | `SuperadminController.getSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:463` |
| 304 | `PATCH` | `/superadmin/settings/:id` | `SuperadminController.updateSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:468` |
| 305 | `GET` | `/superadmin/settings/data-retention/preview` | `SuperadminController.previewDataRetention` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:594` |
| 306 | `POST` | `/superadmin/settings/data-retention/run` | `SuperadminController.runDataRetention` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:599` |
| 307 | `GET` | `/superadmin/simproviders` | `SuperadminController.getSimProviders` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:379` |
| 308 | `POST` | `/superadmin/simproviders` | `SuperadminController.createSimProvider` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:383` |
| 309 | `DELETE` | `/superadmin/simproviders/:id` | `SuperadminController.deleteSimProvider` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:391` |
| 310 | `PATCH` | `/superadmin/simproviders/:id` | `SuperadminController.updateSimProvider` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:387` |
| 311 | `GET` | `/superadmin/smtpconfig/:id` | `SuperadminController.getSmtpConfig` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:226` |
| 312 | `PATCH` | `/superadmin/smtpconfig/:id` | `SuperadminController.updateSmtpConfig` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:231` |
| 313 | `GET` | `/superadmin/smtpsettings` | `SuperadminController.getSmtpSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:551` |
| 314 | `PATCH` | `/superadmin/smtpsettings` | `SuperadminController.updateSmtpSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:556` |
| 315 | `GET` | `/superadmin/softwareconfig` | `SuperadminController.getConfig` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:582` |
| 316 | `PATCH` | `/superadmin/softwareconfig` | `SuperadminController.updateConfig` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:587` |
| 317 | `POST` | `/superadmin/ssl/install` | `SslController.install` | Bearer JWT; roles: SUPERADMIN | `ssl/ssl.controller.ts:36` |
| 318 | `GET` | `/superadmin/ssl/jobs/:jobId` | `SslController.getJob` | Bearer JWT; roles: SUPERADMIN | `ssl/ssl.controller.ts:51` |
| 319 | `GET` | `/superadmin/ssl/jobs/:jobId/stream` | `SslStreamController.streamJob` | Public / unspecified | `ssl/ssl.controller.ts:74` |
| 320 | `GET` | `/superadmin/ssl/status` | `SslController.getStatus` | Bearer JWT; roles: SUPERADMIN | `ssl/ssl.controller.ts:30` |
| 321 | `GET` | `/superadmin/support/tickets` | `SuperadminController.listSupportTickets` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:85` |
| 322 | `POST` | `/superadmin/support/tickets` | `SuperadminController.createSupportTicketOnBehalfOfAdmin` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:96` |
| 323 | `GET` | `/superadmin/support/tickets/:id` | `SuperadminController.getSupportTicketById` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:105` |
| 324 | `POST` | `/superadmin/support/tickets/:id/messages` | `SuperadminController.replySupportTicket` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:113` |
| 325 | `PATCH` | `/superadmin/support/tickets/:id/status` | `SuperadminController.updateSupportTicketStatus` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:123` |
| 326 | `GET` | `/superadmin/systemvariables` | `SuperadminController.getSystemVariables` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:345` |
| 327 | `POST` | `/superadmin/systemvariables` | `SuperadminController.createSystemVariable` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:349` |
| 328 | `DELETE` | `/superadmin/systemvariables/:id` | `SuperadminController.deleteSystemVariable` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:357` |
| 329 | `PATCH` | `/superadmin/systemvariables/:id` | `SuperadminController.updateSystemVariable` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:353` |
| 330 | `GET` | `/superadmin/telemetry` | `SuperadminController.getTelemetrySnapshot` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:771` |
| 331 | `POST` | `/superadmin/testsmtp` | `SuperadminController.testSmtpSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:564` |
| 332 | `GET` | `/superadmin/topbar-search` | `SuperadminController.searchTopbar` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:73` |
| 333 | `GET` | `/superadmin/transactions` | `SuperadminController.listTransactions` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:189` |
| 334 | `GET` | `/superadmin/transactions/analytics` | `SuperadminController.transactionsAnalytics` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:204` |
| 335 | `POST` | `/superadmin/transactions/manual` | `SuperadminController.recordManualTransaction` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:217` |
| 336 | `POST` | `/superadmin/updateadmin/:id` | `SuperadminController.updateAdmin` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:168` |
| 337 | `PATCH` | `/superadmin/updatepassword` | `SuperadminController.updatePassword` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:620` |
| 338 | `POST` | `/superadmin/upload/:id` | `SuperadminController.upload` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:246` |
| 339 | `POST` | `/superadmin/uploaddoc` | `SuperadminController.uploadDocument` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:421` |
| 340 | `DELETE` | `/superadmin/uploaddoc/:id` | `SuperadminController.deleteDocument` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:449` |
| 341 | `PATCH` | `/superadmin/uploaddoc/:id` | `SuperadminController.uploadDocumentUpdate` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:432` |
| 342 | `GET` | `/superadmin/vehicles` | `SuperadminController.getAllVehicles` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:284` |
| 343 | `GET` | `/superadmin/vehicles/:id` | `SuperadminController.getVehicleById` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:289` |
| 344 | `GET` | `/superadmin/vehicles/by-imei/:imei/commands` | `SuperadminController.getCommandHistoryByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1027` |
| 345 | `GET` | `/superadmin/vehicles/by-imei/:imei/details` | `SuperadminController.getVehicleDetailsByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:733` |
| 346 | `GET` | `/superadmin/vehicles/by-imei/:imei/events` | `SuperadminController.getVehicleEventsByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:988` |
| 347 | `GET` | `/superadmin/vehicles/by-imei/:imei/history` | `SuperadminController.getVehicleHistoryByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:833` |
| 348 | `GET` | `/superadmin/vehicles/by-imei/:imei/logs` | `SuperadminController.getVehicleLogsByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:745` |
| 349 | `GET` | `/superadmin/vehicles/by-imei/:imei/replay` | `SuperadminController.getVehicleReplayByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:819` |
| 350 | `POST` | `/superadmin/vehicles/by-imei/:imei/send-command` | `SuperadminController.sendDeviceCommandByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1000` |
| 351 | `GET` | `/superadmin/vehicles/by-imei/:imei/sensors` | `SuperadminController.getVehicleSensorsByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:1045` |
| 352 | `GET` | `/superadmin/vehicles/by-imei/:imei/trail` | `SuperadminController.getVehicleTrailByImei` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:804` |
| 353 | `GET` | `/superadmin/vehicletypes` | `SuperadminController.getVehicleTypes` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:261` |
| 354 | `POST` | `/superadmin/vehicletypes` | `SuperadminController.createVehicleType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:266` |
| 355 | `DELETE` | `/superadmin/vehicletypes/:id` | `SuperadminController.deleteVehicleType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:276` |
| 356 | `PATCH` | `/superadmin/vehicletypes/:id` | `SuperadminController.updateVehicleType` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:271` |
| 357 | `GET` | `/superadmin/whatsapptemplates` | `WhatsAppTemplatesController.list` | Bearer JWT; roles: SUPERADMIN | `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:33` |
| 358 | `GET` | `/superadmin/whatsapptemplates/:id` | `WhatsAppTemplatesController.getOne` | Bearer JWT; roles: SUPERADMIN | `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:61` |
| 359 | `PATCH` | `/superadmin/whatsapptemplates/:id` | `WhatsAppTemplatesController.update` | Bearer JWT; roles: SUPERADMIN | `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:67` |
| 360 | `GET` | `/superadmin/whatsapptemplates/meta` | `WhatsAppTemplatesController.fetchMeta` | Bearer JWT; roles: SUPERADMIN | `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:41` |
| 361 | `POST` | `/superadmin/whatsapptemplates/sync` | `WhatsAppTemplatesController.sync` | Bearer JWT; roles: SUPERADMIN | `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:52` |
| 362 | `GET` | `/superadmin/whitelabel` | `SuperadminController.getWhiteLabelSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:533` |
| 363 | `PATCH` | `/superadmin/whitelabel` | `SuperadminController.updateWhiteLabelSettings` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:543` |
| 364 | `GET` | `/superadmin/whitelabel/inspect` | `SuperadminController.inspectWhiteLabelBranding` | Bearer JWT; roles: SUPERADMIN | `superadmin/superadmin.controller.ts:538` |
| 365 | `GET` | `/timezones` | `AppController.getTimezones` | Public / unspecified | `app.controller.ts:168` |
| 366 | `GET` | `/unsubscribe` | `AppController.unsubscribe` | Public / unspecified | `app.controller.ts:30` |
| 367 | `GET` | `/user/commands/:cmdId` | `UserController.getCommandLogByCmdId` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1006` |
| 368 | `POST` | `/user/commands/send-bulk` | `UserController.sendCommandBulk` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:979` |
| 369 | `GET` | `/user/commands/status/:cmdId` | `UserController.getCommandStatus` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:987` |
| 370 | `PATCH` | `/user/companydetails` | `UserController.updateOwnCompanyDetails` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:512` |
| 371 | `GET` | `/user/customcommands` | `UserController.getUserCustomCommands` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:965` |
| 372 | `GET` | `/user/dashboard/day-night-comparison` | `UserController.getDayNightComparison` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:862` |
| 373 | `GET` | `/user/dashboard/fleet-status` | `UserController.getUserFleetStatus` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:796` |
| 374 | `GET` | `/user/dashboard/recent-alerts` | `UserController.getDashboardRecentAlerts` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:819` |
| 375 | `GET` | `/user/dashboard/recent-alerts/:id` | `UserController.getDashboardRecentAlertDetail` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:836` |
| 376 | `PATCH` | `/user/dashboard/recent-alerts/:id/read` | `UserController.markDashboardRecentAlertRead` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:844` |
| 377 | `GET` | `/user/dashboard/top-performing-assets` | `UserController.topPerformingAssets` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:852` |
| 378 | `GET` | `/user/dashboard/usage-last-7-days` | `UserController.getUsageLast7Days` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:801` |
| 379 | `GET` | `/user/dashboard/weekly-comparison` | `UserController.weeklyComparison` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:810` |
| 380 | `GET` | `/user/dashboards` | `UserController.listDashboards` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:876` |
| 381 | `POST` | `/user/dashboards` | `UserController.createDashboard` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:889` |
| 382 | `DELETE` | `/user/dashboards/:id` | `UserController.deleteDashboard` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:906` |
| 383 | `GET` | `/user/dashboards/:id` | `UserController.getDashboard` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:881` |
| 384 | `PUT` | `/user/dashboards/:id` | `UserController.updateDashboard` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:897` |
| 385 | `GET` | `/user/drivers` | `UserController.getDrivers` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:357` |
| 386 | `POST` | `/user/drivers` | `UserController.createDriver` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:349` |
| 387 | `DELETE` | `/user/drivers/:id` | `UserController.deleteDriver` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:379` |
| 388 | `GET` | `/user/drivers/:id` | `UserController.getDriverById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:362` |
| 389 | `PATCH` | `/user/drivers/:id` | `UserController.updateDriver` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:370` |
| 390 | `POST` | `/user/drivers/:id/assign-vehicle` | `UserController.assignDriverToVehicle` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:387` |
| 391 | `GET` | `/user/drivers/:id/documents` | `UserController.getDriverDocuments` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:416` |
| 392 | `POST` | `/user/drivers/:id/documents` | `UserController.uploadDriverDocument` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:424` |
| 393 | `DELETE` | `/user/drivers/:id/documents/:docId` | `UserController.deleteDriverDocument` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:443` |
| 394 | `PATCH` | `/user/drivers/:id/documents/:docId` | `UserController.updateDriverDocument` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:433` |
| 395 | `GET` | `/user/drivers/:id/logs` | `UserController.getDriverLogs` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:404` |
| 396 | `POST` | `/user/drivers/:id/unassign-vehicle` | `UserController.unassignDriverFromVehicle` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:396` |
| 397 | `GET` | `/user/geofences` | `UserController.listGeofences` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:591` |
| 398 | `POST` | `/user/geofences` | `UserController.createGeofence` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:609` |
| 399 | `DELETE` | `/user/geofences/:id` | `UserController.deleteGeofence` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:626` |
| 400 | `GET` | `/user/geofences/:id` | `UserController.getGeofenceById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:601` |
| 401 | `PATCH` | `/user/geofences/:id` | `UserController.updateGeofence` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:617` |
| 402 | `POST` | `/user/landmarkbulkjobs` | `UserController.createLandmarkBulkJob` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:731` |
| 403 | `GET` | `/user/landmarkbulkjobs/:id` | `UserController.getLandmarkBulkJob` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:740` |
| 404 | `GET` | `/user/landmarkbulkjobs/:id/failed.csv` | `UserController.downloadLandmarkFailedCsv` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:750` |
| 405 | `GET` | `/user/landmarkbulkjobs/:id/stream` | `UserController.streamLandmarkBulkJob` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:768` |
| 406 | `GET` | `/user/localization` | `UserController.getLocalizationData` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:522` |
| 407 | `PATCH` | `/user/localization` | `UserController.updateLocalizationData` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:527` |
| 408 | `GET` | `/user/map-events` | `UserController.getMapEvents` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1021` |
| 409 | `GET` | `/user/map-telemetry` | `UserController.getMapTelemetry` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1016` |
| 410 | `GET` | `/user/notification-settings` | `UserController.getNotificationSettings` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:918` |
| 411 | `PUT` | `/user/notification-settings` | `UserController.updateNotificationSettings` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:923` |
| 412 | `GET` | `/user/notifications` | `UserController.getUserNotifications` | Bearer JWT; roles: USER | `user/user.controller.ts:1129` |
| 413 | `PATCH` | `/user/notifications/:id/read` | `UserController.markUserNotificationRead` | Bearer JWT; roles: USER | `user/user.controller.ts:1146` |
| 414 | `GET` | `/user/notifications/preferences` | `UserController.getNotificationPreferences` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:935` |
| 415 | `PUT` | `/user/notifications/preferences` | `UserController.updateNotificationPreferences` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:940` |
| 416 | `PATCH` | `/user/notifications/read-all` | `UserController.markAllUserNotificationsRead` | Bearer JWT; roles: USER | `user/user.controller.ts:1138` |
| 417 | `POST` | `/user/notifications/test-fcm-me` | `UserController.testFcmToMe` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:952` |
| 418 | `GET` | `/user/notifications/vehicle` | `UserController.getVehicleNotificationsForTopbar` | Bearer JWT; roles: USER | `user/user.controller.ts:1159` |
| 419 | `PATCH` | `/user/notifications/vehicle/:id/read` | `UserController.markVehicleNotificationReadForTopbar` | Bearer JWT; roles: USER | `user/user.controller.ts:1177` |
| 420 | `PATCH` | `/user/notifications/vehicle/read-all` | `UserController.markAllVehicleNotificationsReadForTopbar` | Bearer JWT; roles: USER | `user/user.controller.ts:1169` |
| 421 | `GET` | `/user/pois` | `UserController.listPois` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:685` |
| 422 | `POST` | `/user/pois` | `UserController.createPoi` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:702` |
| 423 | `DELETE` | `/user/pois/:id` | `UserController.deletePoi` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:719` |
| 424 | `GET` | `/user/pois/:id` | `UserController.getPoiById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:694` |
| 425 | `PATCH` | `/user/pois/:id` | `UserController.updatePoi` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:710` |
| 426 | `GET` | `/user/profile` | `UserController.getProfile` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:452` |
| 427 | `PATCH` | `/user/profile` | `UserController.updateProfile` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:457` |
| 428 | `GET` | `/user/profile/email-subscription` | `UserController.getEmailSubscription` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:490` |
| 429 | `POST` | `/user/profile/email-subscription/subscribe` | `UserController.subscribeEmail` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:501` |
| 430 | `POST` | `/user/profile/verify/email/confirm` | `UserController.verifyEmailOtp` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:471` |
| 431 | `POST` | `/user/profile/verify/email/request` | `UserController.requestEmailOtp` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:466` |
| 432 | `POST` | `/user/profile/verify/whatsapp/confirm` | `UserController.verifyWhatsAppOtp` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:481` |
| 433 | `POST` | `/user/profile/verify/whatsapp/request` | `UserController.requestWhatsAppOtp` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:476` |
| 434 | `GET` | `/user/routes` | `UserController.listRoutes` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:638` |
| 435 | `POST` | `/user/routes` | `UserController.createRoute` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:656` |
| 436 | `DELETE` | `/user/routes/:id` | `UserController.deleteRoute` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:673` |
| 437 | `GET` | `/user/routes/:id` | `UserController.getRouteById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:648` |
| 438 | `PATCH` | `/user/routes/:id` | `UserController.updateRoute` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:664` |
| 439 | `GET` | `/user/sharetracklinks` | `UserController.listShareTrackLinks` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:156` |
| 440 | `POST` | `/user/sharetracklinks` | `UserController.createShareTrackLink` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:148` |
| 441 | `DELETE` | `/user/sharetracklinks/:id` | `UserController.deleteShareTrackLink` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:181` |
| 442 | `GET` | `/user/sharetracklinks/:id` | `UserController.getShareTrackLinkById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:164` |
| 443 | `PATCH` | `/user/sharetracklinks/:id` | `UserController.updateShareTrackLink` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:172` |
| 444 | `GET` | `/user/subusers` | `UserController.listSubUsers` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:75` |
| 445 | `POST` | `/user/subusers` | `UserController.createSubUser` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:85` |
| 446 | `DELETE` | `/user/subusers/:id` | `UserController.deleteSubUser` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:104` |
| 447 | `GET` | `/user/subusers/:id` | `UserController.getSubUserById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:90` |
| 448 | `PATCH` | `/user/subusers/:id` | `UserController.updateSubUser` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:95` |
| 449 | `GET` | `/user/subusers/:id/vehicles` | `UserController.getSubUserVehicles` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:112` |
| 450 | `POST` | `/user/subusers/:id/vehicles/assign` | `UserController.assignSubUserVehicles` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:120` |
| 451 | `POST` | `/user/subusers/:id/vehicles/unassign` | `UserController.unassignSubUserVehicles` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:129` |
| 452 | `GET` | `/user/systemvariables` | `UserController.getUserSystemVariables` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:970` |
| 453 | `GET` | `/user/tickets` | `UserController.listTickets` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:557` |
| 454 | `POST` | `/user/tickets` | `UserController.createTicket` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:562` |
| 455 | `GET` | `/user/tickets/:id` | `UserController.getTicketConversation` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:570` |
| 456 | `POST` | `/user/tickets/:id` | `UserController.addTicketMessage` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:578` |
| 457 | `GET` | `/user/topbar-search` | `UserController.searchTopbar` | Bearer JWT; roles: USER | `user/user.controller.ts:62` |
| 458 | `GET` | `/user/transactions` | `UserController.listUserTransactions` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:539` |
| 459 | `PATCH` | `/user/updatepassword` | `UserController.updatePassword` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:517` |
| 460 | `POST` | `/user/upload` | `UserController.uploadProfile` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:787` |
| 461 | `GET` | `/user/vehicles` | `UserController.getUserVehicles` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:138` |
| 462 | `GET` | `/user/vehicles/:id` | `UserController.getVehicleById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:194` |
| 463 | `PATCH` | `/user/vehicles/:id` | `UserController.updateVehicleById` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:199` |
| 464 | `PATCH` | `/user/vehicles/:id/config` | `UserController.updateVehicleConfig` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:208` |
| 465 | `GET` | `/user/vehicles/:id/documents` | `UserController.getVehicleDocuments` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:309` |
| 466 | `POST` | `/user/vehicles/:id/documents` | `UserController.uploadVehicleDocument` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:317` |
| 467 | `DELETE` | `/user/vehicles/:id/documents/:docId` | `UserController.deleteVehicleDocument` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:336` |
| 468 | `PATCH` | `/user/vehicles/:id/documents/:docId` | `UserController.updateVehicleDocument` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:326` |
| 469 | `GET` | `/user/vehicles/:vehicleId/commands` | `UserController.getCommandHistoryByVehicleId` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:996` |
| 470 | `GET` | `/user/vehicles/:vehicleId/sensors` | `UserController.listVehicleSensors` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:221` |
| 471 | `POST` | `/user/vehicles/:vehicleId/sensors` | `UserController.createVehicleSensor` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:236` |
| 472 | `DELETE` | `/user/vehicles/:vehicleId/sensors/:sensorId` | `UserController.deleteVehicleSensor` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:255` |
| 473 | `PATCH` | `/user/vehicles/:vehicleId/sensors/:sensorId` | `UserController.updateVehicleSensor` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:245` |
| 474 | `GET` | `/user/vehicles/:vehicleId/sensors/:sensorId/history` | `UserController.getSensorHistory` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:281` |
| 475 | `POST` | `/user/vehicles/:vehicleId/sensors/run` | `UserController.runVehicleSensor` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:264` |
| 476 | `GET` | `/user/vehicles/:vehicleId/sensors/telemetry` | `UserController.getVehicleSensorTelemetry` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:273` |
| 477 | `GET` | `/user/vehicles/:vehicleId/telemetry` | `UserController.getVehicleTelemetrySnapshot` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:297` |
| 478 | `GET` | `/user/vehicles/by-imei/:imei/details` | `UserController.getVehicleDetailsByImei` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1029` |
| 479 | `GET` | `/user/vehicles/by-imei/:imei/events` | `UserController.getVehicleEventsByImei` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1054` |
| 480 | `GET` | `/user/vehicles/by-imei/:imei/history` | `UserController.getVehicleHistoryByImei` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1095` |
| 481 | `GET` | `/user/vehicles/by-imei/:imei/logs` | `UserController.getVehicleLogsByIMEI` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1037` |
| 482 | `GET` | `/user/vehicles/by-imei/:imei/replay` | `UserController.getVehicleReplayByImei` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1080` |
| 483 | `GET` | `/user/vehicles/by-imei/:imei/sensors` | `UserController.getVehicleSensorsByImei` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1114` |
| 484 | `GET` | `/user/vehicles/by-imei/:imei/trail` | `UserController.getVehicleTrailByImei` | Bearer JWT; roles: ADMIN, USER | `user/user.controller.ts:1063` |
| 485 | `GET` | `/vehicletypes` | `AppController.getVehicleTypes` | Public / unspecified | `app.controller.ts:128` |
| 486 | `GET` | `/version` | `AppController.getVersion` | Public / unspecified | `app.controller.ts:23` |
| 487 | `GET` | `/webhooks/whatsapp` | `WhatsappWebhookController.verify` | Public / unspecified | `webhooks/whatsapp-webhook.controller.ts:94` |
| 488 | `POST` | `/webhooks/whatsapp` | `WhatsappWebhookController.inbound` | Public / unspecified | `webhooks/whatsapp-webhook.controller.ts:124` |

## Copy-paste endpoint list

```txt
GET    /
GET    /admin/calendar/day
GET    /admin/calendar/events
GET    /admin/calendar/user/:uid
GET    /admin/commands/:cmdId
GET    /admin/commands/status/:cmdId
PATCH  /admin/companydetails
GET    /admin/companydetails/:id
PATCH  /admin/companydetails/:id
PATCH  /admin/companyinfo/:id
GET    /admin/config
PATCH  /admin/config
GET    /admin/customcommands
GET    /admin/dashboard/summary
POST   /admin/deviceandsim
GET    /admin/devices
POST   /admin/devices
DELETE /admin/devices/:id
PATCH  /admin/devices/:id
GET    /admin/documents/:userId
GET    /admin/documents/driver/:driverId
GET    /admin/documents/vehicle/:vehicleId
POST   /admin/driverbulkjobs
GET    /admin/driverbulkjobs/:id
GET    /admin/driverbulkjobs/:id/failed.csv
GET    /admin/driverbulkjobs/:id/stream
GET    /admin/drivers
POST   /admin/drivers
DELETE /admin/drivers/:id
GET    /admin/drivers/:id
PATCH  /admin/drivers/:id
GET    /admin/drivers/:id/users
GET    /admin/drivers/linkedusers/:driverId
POST   /admin/drivers/linkedusers/:driverId
GET    /admin/drivers/unlinkedusers/:driverId
POST   /admin/drivers/unlinkedusers/:driverId
POST   /admin/inventorybulkjobs
GET    /admin/inventorybulkjobs/:id
GET    /admin/inventorybulkjobs/:id/failed.csv
GET    /admin/inventorybulkjobs/:id/stream
GET    /admin/linkusers/:vehicleId
POST   /admin/linkusers/:vehicleId
GET    /admin/linkvehicles/:userId
POST   /admin/linkvehicles/:userId
GET    /admin/localization
PATCH  /admin/localization
GET    /admin/logs/activity
GET    /admin/logs/events
GET    /admin/logs/events/:id
GET    /admin/logs/options
GET    /admin/logs/telemetry
GET    /admin/logs/telemetry/:id
GET    /admin/map-events
GET    /admin/map-telemetry
GET    /admin/mytickets
POST   /admin/mytickets
GET    /admin/mytickets/:id
POST   /admin/mytickets/:id/messages
PATCH  /admin/mytickets/:id/status
GET    /admin/notifications
PATCH  /admin/notifications/:id/read
PATCH  /admin/notifications/read-all
GET    /admin/payments
POST   /admin/payments/renew
GET    /admin/pricingplans
POST   /admin/pricingplans
PATCH  /admin/pricingplans/:id
GET    /admin/profile
PATCH  /admin/profile
GET    /admin/profile/email-subscription
POST   /admin/profile/email-subscription/subscribe
POST   /admin/profile/verify/email/confirm
POST   /admin/profile/verify/email/request
POST   /admin/profile/verify/whatsapp/confirm
POST   /admin/profile/verify/whatsapp/request
GET    /admin/quickdevice
POST   /admin/quickdevice
GET    /admin/quicksimcards
GET    /admin/shortusers
GET    /admin/simcards
POST   /admin/simcards
DELETE /admin/simcards/:id
GET    /admin/simcards/:id
PATCH  /admin/simcards/:id
GET    /admin/smtpconfig
PATCH  /admin/smtpconfig
POST   /admin/smtpconfig
GET    /admin/systemvariables
GET    /admin/teams
POST   /admin/teams
DELETE /admin/teams/:id
GET    /admin/teams/:id
PATCH  /admin/teams/:id
POST   /admin/testsmtp
GET    /admin/tickets
POST   /admin/tickets
GET    /admin/tickets/:id
POST   /admin/tickets/:id/messages
PATCH  /admin/tickets/:id/status
GET    /admin/topbar-search
GET    /admin/transactions
GET    /admin/transactions/analytics
POST   /admin/transactions/renew
GET    /admin/unlinkusers/:vehicleId
POST   /admin/unlinkusers/:vehicleId
GET    /admin/unlinkvehicles/:userId
POST   /admin/unlinkvehicles/:userId
PATCH  /admin/updatepassword
POST   /admin/updatepassword
POST   /admin/updateuserpassword/:id
POST   /admin/upload
POST   /admin/uploaddoc
DELETE /admin/uploaddoc/:id
PATCH  /admin/uploaddoc/:id
POST   /admin/userbulkjobs
GET    /admin/userbulkjobs/:id
GET    /admin/userbulkjobs/:id/failed.csv
GET    /admin/userbulkjobs/:id/stream
GET    /admin/userlogin/:id
GET    /admin/users
POST   /admin/users
DELETE /admin/users/:id
GET    /admin/users/:id
PATCH  /admin/users/:id
GET    /admin/users/:id/activitylogs
GET    /admin/users/linkeddrivers/:userId
POST   /admin/users/linkeddrivers/:userId
GET    /admin/users/unlinkeddrivers/:userId
POST   /admin/users/unlinkeddrivers/:userId
POST   /admin/vehiclebulkjobs
GET    /admin/vehiclebulkjobs/:id
GET    /admin/vehiclebulkjobs/:id/failed.csv
GET    /admin/vehiclebulkjobs/:id/stream
GET    /admin/vehicles
POST   /admin/vehicles
DELETE /admin/vehicles/:id
GET    /admin/vehicles/:id
PATCH  /admin/vehicles/:id
PATCH  /admin/vehicles/:id/config
GET    /admin/vehicles/:vehicleId/sensors
POST   /admin/vehicles/:vehicleId/sensors
DELETE /admin/vehicles/:vehicleId/sensors/:sensorId
PATCH  /admin/vehicles/:vehicleId/sensors/:sensorId
POST   /admin/vehicles/:vehicleId/sensors/run
GET    /admin/vehicles/:vehicleId/sensors/telemetry
GET    /admin/vehicles/by-imei/:imei/commands
GET    /admin/vehicles/by-imei/:imei/details
GET    /admin/vehicles/by-imei/:imei/events
GET    /admin/vehicles/by-imei/:imei/events/export
GET    /admin/vehicles/by-imei/:imei/history
GET    /admin/vehicles/by-imei/:imei/logs
GET    /admin/vehicles/by-imei/:imei/logs/export
GET    /admin/vehicles/by-imei/:imei/replay
POST   /admin/vehicles/by-imei/:imei/send-command
GET    /admin/vehicles/by-imei/:imei/sensors
GET    /admin/vehicles/by-imei/:imei/trail
GET    /admin/whitelabel
PATCH  /admin/whitelabel
GET    /admin/whitelabel/inspect
POST   /agent/commands
GET    /agent/executions/:executionId
GET    /agent/executions/:executionId/status
GET    /auth/checksadmin
POST   /auth/createsuperadmin
POST   /auth/email-test
GET    /auth/fcm-web-config
POST   /auth/forgot-password
GET    /auth/google/client-id
POST   /auth/google/login
POST   /auth/login
POST   /auth/push-test
DELETE /auth/push-token
POST   /auth/push-token
GET    /auth/push-tokens/me
POST   /auth/refresh-token
POST   /auth/reset-password
GET    /branding
POST   /bug-reports
GET    /cities/:countryCode/:stateCode
GET    /countries
GET    /currencies
GET    /dateformats
GET    /devicestypes
GET    /documenttypes/:documentType
GET    /geocoding/precision
GET    /geocoding/reverse
POST   /geocoding/reverse/bulk
POST   /handledata
GET    /health
GET    /health/address-db
GET    /health/databases
GET    /health/logs-db
GET    /health/primary-db
GET    /health/telemetry-diagnostics/:imei
GET    /health/telemetry-packet/:imei/:sourcePacketId
GET    /health/telemetry-stats
GET    /health/telemetry-stats/:imei
GET    /languages
GET    /mobileprefix
GET    /policies
GET    /policies/:type
GET    /public/track/:code
GET    /public/track/:code/geofences
GET    /public/track/:code/telemetry
GET    /public/track/:code/vehicles/:imei/details
GET    /public/track/:code/vehicles/:imei/history
GET    /public/track/:code/vehicles/:imei/logs
GET    /public/track/:code/vehicles/:imei/replay
GET    /simproviders
GET    /states/:countryCode
GET    /status
POST   /superadmin/activateadmin/:id
GET    /superadmin/admin/:id
GET    /superadmin/admin/:id/activitylogs
GET    /superadmin/adminlist
GET    /superadmin/adminlogin/:id
POST   /superadmin/adminpasswordupdate
GET    /superadmin/adminvehicles/:adminId
GET    /superadmin/appnotifytemplates
GET    /superadmin/appnotifytemplates/:id
PATCH  /superadmin/appnotifytemplates/:id
POST   /superadmin/assigncredits/:id
GET    /superadmin/calendar/day
GET    /superadmin/calendar/events
GET    /superadmin/calendar/user/:uid
GET    /superadmin/commands/:cmdId
GET    /superadmin/commands/status/:cmdId
GET    /superadmin/commandtypes
POST   /superadmin/commandtypes
DELETE /superadmin/commandtypes/:id
PATCH  /superadmin/commandtypes/:id
GET    /superadmin/companyconfig/:id
PATCH  /superadmin/companyconfig/:id
PATCH  /superadmin/companydetails
POST   /superadmin/createadmin
GET    /superadmin/creditlogs/:id
GET    /superadmin/customcommands
POST   /superadmin/customcommands
DELETE /superadmin/customcommands/:id
PATCH  /superadmin/customcommands/:id
GET    /superadmin/dashboard/activitylogs
GET    /superadmin/dashboard/adoptiongraph
GET    /superadmin/dashboard/overview
GET    /superadmin/dashboard/recentusers
GET    /superadmin/dashboard/recentvehicles
GET    /superadmin/dashboard/totalcounts
DELETE /superadmin/deleteadmin/:id
POST   /superadmin/devices/:imei/send-command
GET    /superadmin/devicetypes
POST   /superadmin/devicetypes
DELETE /superadmin/devicetypes/:id
PATCH  /superadmin/devicetypes/:id
GET    /superadmin/documents/:adminId
GET    /superadmin/documenttypes
POST   /superadmin/documenttypes
DELETE /superadmin/documenttypes/:id
PATCH  /superadmin/documenttypes/:id
GET    /superadmin/domainlist
GET    /superadmin/emailtemplates
GET    /superadmin/emailtemplates/:id
PATCH  /superadmin/emailtemplates/:id
POST   /superadmin/ftkey/deactivate
POST   /superadmin/ftkey/recheck
GET    /superadmin/ftkey/status
POST   /superadmin/ftkey/validate
GET    /superadmin/geofences
GET    /superadmin/integrations
POST   /superadmin/integrations
DELETE /superadmin/integrations/:id
PATCH  /superadmin/integrations/:id
GET    /superadmin/integrations/:id/openrouter/models
POST   /superadmin/integrations/:id/rotate-secret
POST   /superadmin/integrations/:id/test-fcm
POST   /superadmin/integrations/:id/test-openrouter
POST   /superadmin/integrations/:id/test-whatsapp
POST   /superadmin/integrations/:id/validate-geocoding
POST   /superadmin/integrations/:id/validate-google-sso
GET    /superadmin/localization
PATCH  /superadmin/localization
GET    /superadmin/map-events
GET    /superadmin/map-telemetry
GET    /superadmin/notifications
PATCH  /superadmin/notifications/:id/read
PATCH  /superadmin/notifications/read-all
POST   /superadmin/notifications/test-fcm-me
GET    /superadmin/openrouter/models
GET    /superadmin/pois
PATCH  /superadmin/policy
POST   /superadmin/policy
GET    /superadmin/profile
PATCH  /superadmin/profile
GET    /superadmin/profile/email-subscription
POST   /superadmin/profile/email-subscription/subscribe
POST   /superadmin/profile/verify/email/confirm
POST   /superadmin/profile/verify/email/request
POST   /superadmin/profile/verify/whatsapp/confirm
POST   /superadmin/profile/verify/whatsapp/request
GET    /superadmin/routes
POST   /superadmin/server/actions
GET    /superadmin/server/jobs/:id
GET    /superadmin/server/jobs/:id/stream
GET    /superadmin/server/overview
GET    /superadmin/settings/:id
PATCH  /superadmin/settings/:id
GET    /superadmin/settings/data-retention/preview
POST   /superadmin/settings/data-retention/run
GET    /superadmin/simproviders
POST   /superadmin/simproviders
DELETE /superadmin/simproviders/:id
PATCH  /superadmin/simproviders/:id
GET    /superadmin/smtpconfig/:id
PATCH  /superadmin/smtpconfig/:id
GET    /superadmin/smtpsettings
PATCH  /superadmin/smtpsettings
GET    /superadmin/softwareconfig
PATCH  /superadmin/softwareconfig
POST   /superadmin/ssl/install
GET    /superadmin/ssl/jobs/:jobId
GET    /superadmin/ssl/jobs/:jobId/stream
GET    /superadmin/ssl/status
GET    /superadmin/support/tickets
POST   /superadmin/support/tickets
GET    /superadmin/support/tickets/:id
POST   /superadmin/support/tickets/:id/messages
PATCH  /superadmin/support/tickets/:id/status
GET    /superadmin/systemvariables
POST   /superadmin/systemvariables
DELETE /superadmin/systemvariables/:id
PATCH  /superadmin/systemvariables/:id
GET    /superadmin/telemetry
POST   /superadmin/testsmtp
GET    /superadmin/topbar-search
GET    /superadmin/transactions
GET    /superadmin/transactions/analytics
POST   /superadmin/transactions/manual
POST   /superadmin/updateadmin/:id
PATCH  /superadmin/updatepassword
POST   /superadmin/upload/:id
POST   /superadmin/uploaddoc
DELETE /superadmin/uploaddoc/:id
PATCH  /superadmin/uploaddoc/:id
GET    /superadmin/vehicles
GET    /superadmin/vehicles/:id
GET    /superadmin/vehicles/by-imei/:imei/commands
GET    /superadmin/vehicles/by-imei/:imei/details
GET    /superadmin/vehicles/by-imei/:imei/events
GET    /superadmin/vehicles/by-imei/:imei/history
GET    /superadmin/vehicles/by-imei/:imei/logs
GET    /superadmin/vehicles/by-imei/:imei/replay
POST   /superadmin/vehicles/by-imei/:imei/send-command
GET    /superadmin/vehicles/by-imei/:imei/sensors
GET    /superadmin/vehicles/by-imei/:imei/trail
GET    /superadmin/vehicletypes
POST   /superadmin/vehicletypes
DELETE /superadmin/vehicletypes/:id
PATCH  /superadmin/vehicletypes/:id
GET    /superadmin/whatsapptemplates
GET    /superadmin/whatsapptemplates/:id
PATCH  /superadmin/whatsapptemplates/:id
GET    /superadmin/whatsapptemplates/meta
POST   /superadmin/whatsapptemplates/sync
GET    /superadmin/whitelabel
PATCH  /superadmin/whitelabel
GET    /superadmin/whitelabel/inspect
GET    /timezones
GET    /unsubscribe
GET    /user/commands/:cmdId
POST   /user/commands/send-bulk
GET    /user/commands/status/:cmdId
PATCH  /user/companydetails
GET    /user/customcommands
GET    /user/dashboard/day-night-comparison
GET    /user/dashboard/fleet-status
GET    /user/dashboard/recent-alerts
GET    /user/dashboard/recent-alerts/:id
PATCH  /user/dashboard/recent-alerts/:id/read
GET    /user/dashboard/top-performing-assets
GET    /user/dashboard/usage-last-7-days
GET    /user/dashboard/weekly-comparison
GET    /user/dashboards
POST   /user/dashboards
DELETE /user/dashboards/:id
GET    /user/dashboards/:id
PUT    /user/dashboards/:id
GET    /user/drivers
POST   /user/drivers
DELETE /user/drivers/:id
GET    /user/drivers/:id
PATCH  /user/drivers/:id
POST   /user/drivers/:id/assign-vehicle
GET    /user/drivers/:id/documents
POST   /user/drivers/:id/documents
DELETE /user/drivers/:id/documents/:docId
PATCH  /user/drivers/:id/documents/:docId
GET    /user/drivers/:id/logs
POST   /user/drivers/:id/unassign-vehicle
GET    /user/geofences
POST   /user/geofences
DELETE /user/geofences/:id
GET    /user/geofences/:id
PATCH  /user/geofences/:id
POST   /user/landmarkbulkjobs
GET    /user/landmarkbulkjobs/:id
GET    /user/landmarkbulkjobs/:id/failed.csv
GET    /user/landmarkbulkjobs/:id/stream
GET    /user/localization
PATCH  /user/localization
GET    /user/map-events
GET    /user/map-telemetry
GET    /user/notification-settings
PUT    /user/notification-settings
GET    /user/notifications
PATCH  /user/notifications/:id/read
GET    /user/notifications/preferences
PUT    /user/notifications/preferences
PATCH  /user/notifications/read-all
POST   /user/notifications/test-fcm-me
GET    /user/notifications/vehicle
PATCH  /user/notifications/vehicle/:id/read
PATCH  /user/notifications/vehicle/read-all
GET    /user/pois
POST   /user/pois
DELETE /user/pois/:id
GET    /user/pois/:id
PATCH  /user/pois/:id
GET    /user/profile
PATCH  /user/profile
GET    /user/profile/email-subscription
POST   /user/profile/email-subscription/subscribe
POST   /user/profile/verify/email/confirm
POST   /user/profile/verify/email/request
POST   /user/profile/verify/whatsapp/confirm
POST   /user/profile/verify/whatsapp/request
GET    /user/routes
POST   /user/routes
DELETE /user/routes/:id
GET    /user/routes/:id
PATCH  /user/routes/:id
GET    /user/sharetracklinks
POST   /user/sharetracklinks
DELETE /user/sharetracklinks/:id
GET    /user/sharetracklinks/:id
PATCH  /user/sharetracklinks/:id
GET    /user/subusers
POST   /user/subusers
DELETE /user/subusers/:id
GET    /user/subusers/:id
PATCH  /user/subusers/:id
GET    /user/subusers/:id/vehicles
POST   /user/subusers/:id/vehicles/assign
POST   /user/subusers/:id/vehicles/unassign
GET    /user/systemvariables
GET    /user/tickets
POST   /user/tickets
GET    /user/tickets/:id
POST   /user/tickets/:id
GET    /user/topbar-search
GET    /user/transactions
PATCH  /user/updatepassword
POST   /user/upload
GET    /user/vehicles
GET    /user/vehicles/:id
PATCH  /user/vehicles/:id
PATCH  /user/vehicles/:id/config
GET    /user/vehicles/:id/documents
POST   /user/vehicles/:id/documents
DELETE /user/vehicles/:id/documents/:docId
PATCH  /user/vehicles/:id/documents/:docId
GET    /user/vehicles/:vehicleId/commands
GET    /user/vehicles/:vehicleId/sensors
POST   /user/vehicles/:vehicleId/sensors
DELETE /user/vehicles/:vehicleId/sensors/:sensorId
PATCH  /user/vehicles/:vehicleId/sensors/:sensorId
GET    /user/vehicles/:vehicleId/sensors/:sensorId/history
POST   /user/vehicles/:vehicleId/sensors/run
GET    /user/vehicles/:vehicleId/sensors/telemetry
GET    /user/vehicles/:vehicleId/telemetry
GET    /user/vehicles/by-imei/:imei/details
GET    /user/vehicles/by-imei/:imei/events
GET    /user/vehicles/by-imei/:imei/history
GET    /user/vehicles/by-imei/:imei/logs
GET    /user/vehicles/by-imei/:imei/replay
GET    /user/vehicles/by-imei/:imei/sensors
GET    /user/vehicles/by-imei/:imei/trail
GET    /vehicletypes
GET    /version
GET    /webhooks/whatsapp
POST   /webhooks/whatsapp
```

## Server-Sent Event / raw streaming / download endpoints

| Method | Endpoint | Auth/Roles | Notes |
|---|---|---|---|
| `GET` | `/admin/driverbulkjobs/:id/failed.csv` | Bearer JWT; roles: ADMIN | CSV download |
| `GET` | `/admin/driverbulkjobs/:id/stream` | Bearer JWT; roles: ADMIN | Stream/SSE/raw response |
| `GET` | `/admin/inventorybulkjobs/:id/failed.csv` | Bearer JWT; roles: ADMIN | CSV download |
| `GET` | `/admin/inventorybulkjobs/:id/stream` | Bearer JWT; roles: ADMIN | Stream/SSE/raw response |
| `GET` | `/admin/userbulkjobs/:id/failed.csv` | Bearer JWT; roles: ADMIN | CSV download |
| `GET` | `/admin/userbulkjobs/:id/stream` | Bearer JWT; roles: ADMIN | Stream/SSE/raw response |
| `GET` | `/admin/vehiclebulkjobs/:id/failed.csv` | Bearer JWT; roles: ADMIN | CSV download |
| `GET` | `/admin/vehiclebulkjobs/:id/stream` | Bearer JWT; roles: ADMIN | Stream/SSE/raw response |
| `GET` | `/admin/vehicles/by-imei/:imei/events/export` | Bearer JWT; roles: ADMIN | Raw FastifyReply response |
| `GET` | `/admin/vehicles/by-imei/:imei/logs/export` | Bearer JWT; roles: ADMIN | Raw FastifyReply response |
| `GET` | `/branding` | Public / unspecified | Raw FastifyReply response |
| `GET` | `/superadmin/server/jobs/:id/stream` | Bearer JWT; roles: SUPERADMIN | Stream/SSE/raw response |
| `GET` | `/superadmin/ssl/jobs/:jobId/stream` | Public / unspecified | Stream/SSE/raw response |
| `GET` | `/unsubscribe` | Public / unspecified | Raw FastifyReply response |
| `GET` | `/user/landmarkbulkjobs/:id/failed.csv` | Bearer JWT; roles: ADMIN, USER | CSV download |
| `GET` | `/user/landmarkbulkjobs/:id/stream` | Bearer JWT; roles: ADMIN, USER | Stream/SSE/raw response |
| `GET` | `/webhooks/whatsapp` | Public / unspecified | Raw FastifyReply response |
| `POST` | `/webhooks/whatsapp` | Public / unspecified | Raw FastifyReply response |

## Socket.IO / real-time channels

Socket gateways use the same JWT model as HTTP. Tokens can be supplied through gateway-specific auth/header/query handling implemented in source.

| Source | Namespace(s) | Client → server events | Server emits found | Rooms/patterns detected |
|---|---|---|---|---|
| `admin/driver-bulk-jobs.service.ts` | - | - | `evt` | `,`, `\n` |
| `admin/inventory-bulk-jobs.service.ts` | - | - | `evt` | `,`, `\n` |
| `admin/user-bulk-jobs.service.ts` | - | - | `evt` | `,`, `\n` |
| `admin/vehicle-bulk-jobs.service.ts` | - | - | `evt` | `,`, `\n` |
| `common/transports/winston-csv.transport.ts` | - | - | `logged` | `,` |
| `realtime/device-status-realtime.service.ts` | - | - | `devicestatus:update` | `imei:{value}`, `scope:superadmin` |
| `realtime/notification-realtime.service.ts` | - | - | `notif:new` | `scope:superadmin`, `imei:{value}` |
| `realtime/notification.gateway.ts` | `/notifications` | `notif:subscribe` | `notif:error`, `notif:subscribed` | `role:{value}`, `scope:superadmin`, `imei:{value}`, `,` |
| `realtime/telemetry-realtime.service.ts` | - | - | `telemetry:update` | `imei:{value}`, `scope:superadmin` |
| `realtime/telemetry.gateway.ts` | `/telemetry` | `telemetry:subscribe` | `telemetry:error`, `telemetry:snapshot` | `imei:{value}`, `role:{value}`, `scope:superadmin` |
| `ssl/ssl.controller.ts` | - | - | `evt` | - |
| `ssl/ssl.service.ts` | - | - | `evt` | `; `, ` ` |
| `superadmin/server/server-actions.service.ts` | - | - | `evt` | `, `, ` ` |
| `user/landmark-bulk-jobs.service.ts` | - | - | `evt` | `,`, `\n` |

### Real-time event guide

| Namespace/source | Event | Direction | Payload/source notes |
|---|---|---|---|
| `/telemetry` | `telemetry:subscribe` | client → server | Subscribe to superadmin scope, IMEI rooms, or public-track code where allowed. |
| `/telemetry` | `telemetry:snapshot` | server → client | Initial telemetry records after successful subscription. |
| `/telemetry` | `telemetry:update` | server → client | Live telemetry record emitted to `imei:{imei}` and/or `scope:superadmin`. |
| `/telemetry` | `telemetry:error` | server → client | Invalid/unauthorized subscription or subscription failure. |
| `/notifications` | `notif:subscribe` | client → server | Subscribe to superadmin scope and/or authorized IMEI rooms. |
| `/notifications` | `notif:subscribed` | server → client | Acknowledgement with allowed/denied rooms. |
| `/notifications` | `notif:new` | server → client | Notification payload emitted to role/scope/IMEI rooms. |
| `/notifications` | `devicestatus:update` | server → client | Device status update payload. |
| `/notifications` | `notif:error` | server → client | Invalid/unauthorized subscription or subscription failure. |

---

# Complete endpoint reference


## AppController

### 1. `GET /`

- **Handler:** `AppController.getHello()`
- **Source:** `app.controller.ts:18`
- **Auth:** Public / unspecified
- **Controller return type:** `string`
- **Return expression/source:** `this.appService.getHello()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AdminController

### 2. `GET /admin/calendar/day`

- **Handler:** `AdminController.getCalendarDayDetails()`
- **Source:** `admin/admin.controller.ts:971`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCalendarDayDetails(headerId, dto.date, dto.types)`

**Query params**

- Object binding: `AdminCalendarDayDto` from `@Query() dto: AdminCalendarDayDto` — source: `admin/dto/calendar.dto.ts:86`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `date` | `string` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format', }) |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 3. `GET /admin/calendar/events`

- **Handler:** `AdminController.getCalendarEvents()`
- **Source:** `admin/admin.controller.ts:963`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCalendarEvents(headerId, dto.from, dto.to, dto.types)`

**Query params**

- Object binding: `AdminCalendarRangeDto` from `@Query() dto: AdminCalendarRangeDto` — source: `admin/dto/calendar.dto.ts:56`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `from` | `string` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'from must be in YYYY-MM-DD format', }) |
| `to` | `string` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'to must be in YYYY-MM-DD format', }), @Validate(IsValidDateRange) |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 4. `GET /admin/calendar/user/:uid`

- **Handler:** `AdminController.getCalendarUserDetails()`
- **Source:** `admin/admin.controller.ts:979`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCalendarUserDetails(headerId, uid)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `uid` | `number` | Yes | `@Param('uid', ParseIntPipe) uid: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 5. `GET /admin/commands/:cmdId`

- **Handler:** `AdminController.getCommandLogByCmdId()`
- **Source:** `admin/admin.controller.ts:1323`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCommandLogByCmdId(adminId, cmdId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 6. `GET /admin/commands/status/:cmdId`

- **Handler:** `AdminController.getCommandStatus()`
- **Source:** `admin/admin.controller.ts:1304`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCommandStatus(cmdId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 7. `PATCH /admin/companydetails`

- **Handler:** `AdminController.updateOwnCompanyDetails()`
- **Source:** `admin/admin.controller.ts:690`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateCompanyConfig(headerId, companyConfig)`

**Body / payload**

- Object binding: `CompanyDto` from `@Body() companyConfig: CompanyDto` — source: `admin/dto/company.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 8. `GET /admin/companydetails/:id`

- **Handler:** `AdminController.getCompanyDetails()`
- **Source:** `admin/admin.controller.ts:239`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCompanyDetails(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 9. `PATCH /admin/companydetails/:id`

- **Handler:** `AdminController.updateCompanyDetails()`
- **Source:** `admin/admin.controller.ts:244`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateCompanyConfig(id, companyConfig)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `CompanyDto` from `@Body() companyConfig: CompanyDto` — source: `admin/dto/company.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 10. `PATCH /admin/companyinfo/:id`

- **Handler:** `AdminController.updateCompanyInfo()`
- **Source:** `admin/admin.controller.ts:587`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateCompanyInfo(id, headerId, updateCompanydto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateCompanyDto` from `@Body() updateCompanydto: UpdateCompanyDto` — source: `admin/dto/updatecompany.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |
| `secondaryColor` | `string` | No | @IsOptional(), @IsString() |
| `navbarColor` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 11. `GET /admin/config`

- **Handler:** `AdminController.getAdminConfig()`
- **Source:** `admin/admin.controller.ts:699`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getAdminConfig(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 12. `PATCH /admin/config`

- **Handler:** `AdminController.patchAdminConfig()`
- **Source:** `admin/admin.controller.ts:704`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminConfig(headerId, configDto)`

**Body / payload**

- Object binding: `AdminConfigDto` from `@Body() configDto: AdminConfigDto` — source: `admin/dto/adminconfig.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `allowSignup` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `signupCredits` | `number` | No | @IsOptional(), @IsInt(), @Min(0) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 13. `GET /admin/customcommands`

- **Handler:** `AdminController.getCustomCommands()`
- **Source:** `admin/admin.controller.ts:1281`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.adminService.getAdminCustomCommands(query)`

**Query params**

- Object binding: `CustomCommandsQueryDto` from `@Query() query: CustomCommandsQueryDto` — source: `superadmin/dto/custom-commands-query.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `deviceTypeId` | `string` | No | @IsOptional(), @IsString() |
| `commandTypeId` | `string` | No | @IsOptional(), @IsString() |
| `activeOnly` | `string` | No | @IsOptional(), @IsString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 14. `GET /admin/dashboard/summary`

- **Handler:** `AdminController.getDashboardSummary()`
- **Source:** `admin/admin.controller.ts:83`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDashboardSummary(headerId, dto)`

**Query params**

- Object binding: `AdminDashboardSummaryDto` from `@Query() dto: AdminDashboardSummaryDto` — source: `admin/dto/admin-dashboard-summary.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `months` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(3), @Max(24) |
| `listLimit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(25) |
| `currency` | `string` | No | @IsOptional(), @IsString(), @Length(3, 3) |
| `rk` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 15. `POST /admin/deviceandsim`

- **Handler:** `AdminController.createDeviceAndSim()`
- **Source:** `admin/admin.controller.ts:283`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createDeviceAndSim(headerId, dto)`

**Body / payload**

- Object binding: `DeviceAndSimDto` from `@Body() dto: DeviceAndSimDto` — source: `admin/dto/deviceandsim.dto.ts:15`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @ToInt(), @IsInt(), @Min(1) |
| `simNumber` | `string` | Yes | @ToStringish(), @IsString(), @IsNotEmpty() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 16. `GET /admin/devices`

- **Handler:** `AdminController.getDevices()`
- **Source:** `admin/admin.controller.ts:249`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDevices(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 17. `POST /admin/devices`

- **Handler:** `AdminController.createDevice()`
- **Source:** `admin/admin.controller.ts:254`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createDevice(headerId, createDeviceDto)`

**Body / payload**

- Object binding: `CreateDeviceDto` from `@Body() createDeviceDto: CreateDeviceDto` — source: `admin/dto/createdevice.dto.ts:5`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @Transform(({ value }) => { if (value == null \|\| value === "") return value; if (typeof value === "number") return value; const n = parseInt(String(value), 10); return Number.isNaN(n) ? value : n; }), @IsInt(), @Min(1) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 18. `DELETE /admin/devices/:id`

- **Handler:** `AdminController.deleteDevice()`
- **Source:** `admin/admin.controller.ts:263`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteDevice(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 19. `PATCH /admin/devices/:id`

- **Handler:** `AdminController.updateDevice()`
- **Source:** `admin/admin.controller.ts:258`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateDevice(id, headerId, updateDeviceDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateDeviceDto` from `@Body() updateDeviceDto: UpdateDeviceDto` — source: `admin/dto/updatedevice.dto.ts:10`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `simId` | `number \| null` | No | @IsOptional(), @IsInt(), @Min(0) |
| `deviceTypeId` | `number \| null` | No | @IsOptional(), @IsInt(), @Min(1) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `status` | `DeviceInventoryStatusDto` | No | @IsOptional(), @IsEnum(DeviceInventoryStatusDto, { message: "status must be one of: IN_STOCK, IN_USE, IN_SCRAP", }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 20. `GET /admin/documents/:userId`

- **Handler:** `AdminController.getDocuments()`
- **Source:** `admin/admin.controller.ts:742`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDocuments(userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 21. `GET /admin/documents/driver/:driverId`

- **Handler:** `AdminController.getDriverDocuments()`
- **Source:** `admin/admin.controller.ts:755`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDriverDocuments(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 22. `GET /admin/documents/vehicle/:vehicleId`

- **Handler:** `AdminController.getVehicleDocuments()`
- **Source:** `admin/admin.controller.ts:747`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleDocuments(vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 23. `POST /admin/driverbulkjobs`

- **Handler:** `AdminController.createDriverBulkJob()`
- **Source:** `admin/admin.controller.ts:838`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Body / payload**

- Object binding: `CreateDriverBulkJobDto` from `@Body() dto: CreateDriverBulkJobDto` — source: `admin/dto/driverbulkjobs.dto.ts:94`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `primaryUserId` | `string` | Yes | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty() |
| `rows` | `DriverBulkJobRowDto[]` | Yes | @IsArray(), @ValidateNested({ each: true }), @Type(() => DriverBulkJobRowDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 24. `GET /admin/driverbulkjobs/:id`

- **Handler:** `AdminController.getDriverBulkJob()`
- **Source:** `admin/admin.controller.ts:844`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' }` OR `{ action: true, message: 'Job fetched', data: job }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 25. `GET /admin/driverbulkjobs/:id/failed.csv`

- **Handler:** `AdminController.downloadDriverFailedCsv()`
- **Source:** `admin/admin.controller.ts:851`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 26. `GET /admin/driverbulkjobs/:id/stream`

- **Handler:** `AdminController.streamDriverBulkJob()`
- **Source:** `admin/admin.controller.ts:869`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 27. `GET /admin/drivers`

- **Handler:** `AdminController.getDrivers()`
- **Source:** `admin/admin.controller.ts:562`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDrivers(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 28. `POST /admin/drivers`

- **Handler:** `AdminController.createDriver()`
- **Source:** `admin/admin.controller.ts:557`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createDriver(headerId, CreateDriverDto)`

**Body / payload**

- Object binding: `CreateDriverDto` from `@Body() CreateDriverDto: CreateDriverDto` — source: `admin/dto/createdriver.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | Yes | @IsString(), @MaxLength(10) |
| `mobile` | `string` | Yes | @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `primaryUserid` | `string \| number` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString(), @MaxLength(50) |
| `password` | `string` | Yes | @IsString(), @MaxLength(100) |
| `countryCode` | `string` | Yes | @IsString(), @MaxLength(5) |
| `stateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 29. `DELETE /admin/drivers/:id`

- **Handler:** `AdminController.deleteDriver()`
- **Source:** `admin/admin.controller.ts:582`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteDriver(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 30. `GET /admin/drivers/:id`

- **Handler:** `AdminController.getDriverById()`
- **Source:** `admin/admin.controller.ts:567`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDriverById(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 31. `PATCH /admin/drivers/:id`

- **Handler:** `AdminController.updateDriver()`
- **Source:** `admin/admin.controller.ts:577`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateDriver(id, headerId, UpdateDriverDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateDriverDto` from `@Body() UpdateDriverDto: UpdateDriverDto` — source: `admin/dto/updatedriver.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `mobile` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @MaxLength(254) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `countryCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5) |
| `StateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(12) |
| `isactive` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `attributes` | `Record<string, any> \| string` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 32. `GET /admin/drivers/:id/users`

- **Handler:** `AdminController.getDriverUsers()`
- **Source:** `admin/admin.controller.ts:572`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDriverUsers(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 33. `GET /admin/drivers/linkedusers/:driverId`

- **Handler:** `AdminController.getLinkedUsersForDriver()`
- **Source:** `admin/admin.controller.ts:819`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedUsersForDriver(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 34. `POST /admin/drivers/linkedusers/:driverId`

- **Handler:** `AdminController.linkUsersToDriver()`
- **Source:** `admin/admin.controller.ts:827`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkDriverToUser(driverId, userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Body('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 35. `GET /admin/drivers/unlinkedusers/:driverId`

- **Handler:** `AdminController.getUnlinkedUsersForDriver()`
- **Source:** `admin/admin.controller.ts:823`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedUsersForDriver(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 36. `POST /admin/drivers/unlinkedusers/:driverId`

- **Handler:** `AdminController.unlinkUsersFromDriver()`
- **Source:** `admin/admin.controller.ts:832`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkDriverFromUser(driverId, userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Body('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 37. `POST /admin/inventorybulkjobs`

- **Handler:** `AdminController.createInventoryBulkJob()`
- **Source:** `admin/admin.controller.ts:369`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Body / payload**

- Object binding: `CreateInventoryBulkJobDto` from `@Body() dto: CreateInventoryBulkJobDto` — source: `admin/dto/inventorybulkjobs.dto.ts:51`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `target` | `InventoryBulkTarget` | Yes | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty(), @IsIn(['devices', 'simcards', 'both']) |
| `deviceTypeId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)) |
| `providerId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)) |
| `rows` | `InventoryBulkJobRowDto[]` | Yes | @IsArray(), @ValidateNested({ each: true }), @Type(() => InventoryBulkJobRowDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 38. `GET /admin/inventorybulkjobs/:id`

- **Handler:** `AdminController.getInventoryBulkJob()`
- **Source:** `admin/admin.controller.ts:375`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' }` OR `{ action: true, message: 'Job fetched', data: job }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 39. `GET /admin/inventorybulkjobs/:id/failed.csv`

- **Handler:** `AdminController.downloadInventoryFailedCsv()`
- **Source:** `admin/admin.controller.ts:382`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 40. `GET /admin/inventorybulkjobs/:id/stream`

- **Handler:** `AdminController.streamInventoryBulkJob()`
- **Source:** `admin/admin.controller.ts:400`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 41. `GET /admin/linkusers/:vehicleId`

- **Handler:** `AdminController.getLinkedUsers()`
- **Source:** `admin/admin.controller.ts:800`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedUsers(vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 42. `POST /admin/linkusers/:vehicleId`

- **Handler:** `AdminController.linkUsers()`
- **Source:** `admin/admin.controller.ts:804`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkVehicleToUser(userId, vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Body('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 43. `GET /admin/linkvehicles/:userId`

- **Handler:** `AdminController.getLinkedVehicles()`
- **Source:** `admin/admin.controller.ts:778`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedVehicles(userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 44. `POST /admin/linkvehicles/:userId`

- **Handler:** `AdminController.linkVehicles()`
- **Source:** `admin/admin.controller.ts:783`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkVehicleToUser(userId, vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Body('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 45. `GET /admin/localization`

- **Handler:** `AdminController.getLocalizationData()`
- **Source:** `admin/admin.controller.ts:928`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLocalizationData(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 46. `PATCH /admin/localization`

- **Handler:** `AdminController.updateLocalizationData()`
- **Source:** `admin/admin.controller.ts:933`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateLocalizationSettings(headerId, localizationDto)`

**Body / payload**

- Object binding: `UpdateSettingsStateDto` from `@Body() localizationDto: UpdateSettingsStateDto` — source: `superadmin/dto/usersetting.dto.ts:64`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 47. `GET /admin/logs/activity`

- **Handler:** `AdminController.getActivityLogs()`
- **Source:** `admin/admin.controller.ts:1078`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getActivityLogs(headerId, dto)`

**Query params**

- Object binding: `AdminActivityLogsDto` from `@Query() dto: AdminActivityLogsDto` — source: `admin/dto/admin-activity-logs.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `userId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `actionPrefix` | `string` | No | @IsOptional(), @IsString() |
| `entity` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 48. `GET /admin/logs/events`

- **Handler:** `AdminController.getEventLogs()`
- **Source:** `admin/admin.controller.ts:1086`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getEventLogs(headerId, dto)`

**Query params**

- Object binding: `AdminEventLogsDto` from `@Query() dto: AdminEventLogsDto` — source: `admin/dto/admin-event-logs.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(200) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `vehicleId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `userId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `source` | `string` | No | @IsOptional(), @IsString() |
| `severity` | `string` | No | @IsOptional(), @IsString(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |
| `isRead` | `boolean` | No | @IsOptional(), @Transform(({ value }) => { if (value === 'true' \|\| value === '1') return true; if (value === 'false' \|\| value === '0') return false; return value; }), @IsBoolean() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `dedupe` | `boolean` | No | @IsOptional(), @Transform(({ value }) => { if (value === 'true' \|\| value === '1') return true; if (value === 'false' \|\| value === '0') return false; return value; }), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 49. `GET /admin/logs/events/:id`

- **Handler:** `AdminController.getEventLogById()`
- **Source:** `admin/admin.controller.ts:1094`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getEventLogById(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 50. `GET /admin/logs/options`

- **Handler:** `AdminController.getLogsOptions()`
- **Source:** `admin/admin.controller.ts:1073`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLogsOptions(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 51. `GET /admin/logs/telemetry`

- **Handler:** `AdminController.getTelemetryLogs()`
- **Source:** `admin/admin.controller.ts:1102`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTelemetryLogs(headerId, dto)`

**Query params**

- Object binding: `AdminTelemetryLogsDto` from `@Query() dto: AdminTelemetryLogsDto` — source: `admin/dto/admin-telemetry-logs.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(500) |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `vehicleId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `imei` | `string` | No | @IsOptional(), @IsString() |
| `packetType` | `string` | No | @IsOptional(), @IsString(), @IsIn(['LOCATION', 'HISTORY', 'ALARM', 'HEARTBEAT', 'COMMAND', 'EVENT', 'UNKNOWN']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 52. `GET /admin/logs/telemetry/:id`

- **Handler:** `AdminController.getTelemetryLogById()`
- **Source:** `admin/admin.controller.ts:1110`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTelemetryLogById(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 53. `GET /admin/map-events`

- **Handler:** `AdminController.getMapEvents()`
- **Source:** `admin/admin.controller.ts:1127`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getMapEvents(headerId, query)`

**Query params**

- Object binding: `MapEventsQueryDto` from `@Query() query: MapEventsQueryDto` — source: `superadmin/dto/map-events.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 54. `GET /admin/map-telemetry`

- **Handler:** `AdminController.getMapTelemetry()`
- **Source:** `admin/admin.controller.ts:1122`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getMapTelemetry(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 55. `GET /admin/mytickets`

- **Handler:** `AdminController.listAdminMyTickets()`
- **Source:** `admin/admin.controller.ts:163`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.listAdminMyTickets(headerId, { status, search })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `search` | `string` | Yes | `@Query('search') search?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 56. `POST /admin/mytickets`

- **Handler:** `AdminController.createAdminMyTicket()`
- **Source:** `admin/admin.controller.ts:172`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createAdminMyTicket(headerId, req, body)`

**Body / payload**

- Object binding: `any` from `@Body() body: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 57. `GET /admin/mytickets/:id`

- **Handler:** `AdminController.getAdminMyTicketById()`
- **Source:** `admin/admin.controller.ts:181`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getAdminMyTicketById(ticketId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 58. `POST /admin/mytickets/:id/messages`

- **Handler:** `AdminController.replyAdminMyTicket()`
- **Source:** `admin/admin.controller.ts:189`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.replyAdminMyTicket(ticketId, headerId, req, body)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Body / payload**

- Object binding: `any` from `@Body() body: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 59. `PATCH /admin/mytickets/:id/status`

- **Handler:** `AdminController.updateAdminMyTicketStatus()`
- **Source:** `admin/admin.controller.ts:199`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminMyTicketStatus(ticketId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Body / payload**

- Object binding: `AdminUpdateTicketStatusDto` from `@Body() dto: AdminUpdateTicketStatusDto` — source: `admin/dto/admin-update-ticket-status.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 60. `GET /admin/notifications`

- **Handler:** `AdminController.getNotifications()`
- **Source:** `admin/admin.controller.ts:1251`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getNotifications(headerId, { limit, beforeId, unreadOnly, category })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `beforeId` | `string` | Yes | `@Query('beforeId') beforeId?: string` |
| `unreadOnly` | `string` | Yes | `@Query('unreadOnly') unreadOnly?: string` |
| `category` | `string` | Yes | `@Query('category') category?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 61. `PATCH /admin/notifications/:id/read`

- **Handler:** `AdminController.markNotificationRead()`
- **Source:** `admin/admin.controller.ts:1269`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.markNotificationRead(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 62. `PATCH /admin/notifications/read-all`

- **Handler:** `AdminController.markAllNotificationsRead()`
- **Source:** `admin/admin.controller.ts:1262`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.markAllNotificationsRead(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 63. `GET /admin/payments`

- **Handler:** `AdminController.listAdminPayments()`
- **Source:** `admin/admin.controller.ts:1022`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `string` | Yes | `@Query('userId') userId?: string` |
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 64. `POST /admin/payments/renew`

- **Handler:** `AdminController.renewVehiclesPayment()`
- **Source:** `admin/admin.controller.ts:1037`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Vehicles renewed successfully', data }`

**Body / payload**

- Object binding: `AdminRenewVehiclesDto` from `@Body() dto: AdminRenewVehiclesDto` — source: `admin/dto/admin-transactions.dto.ts:20`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `userId` | `number` | Yes | @Type(() => Number), @IsInt(), @Min(1) |
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @Type(() => Number), @IsInt({ each: true }) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `amountOverride` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+(\.\d{1,2})?$/, { message: 'amountOverride must be a valid decimal string (e.g., "150.00")' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 65. `GET /admin/pricingplans`

- **Handler:** `AdminController.getPricingPlans()`
- **Source:** `admin/admin.controller.ts:763`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getPricingPlans(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 66. `POST /admin/pricingplans`

- **Handler:** `AdminController.createPricingPlan()`
- **Source:** `admin/admin.controller.ts:768`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createPricingPlan(headerId, createPricingPlanDto)`

**Body / payload**

- Object binding: `CreatePricingPlanDto` from `@Body() createPricingPlanDto: CreatePricingPlanDto` — source: `admin/dto/createpricingplan.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `durationDays` | `number` | Yes | @IsInt(), @Min(1) |
| `price` | `number` | Yes | @IsNumber(), @Min(0) |
| `currency` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(3, 3), @Matches(/^[A-Z]{3}$/, { message: "currency must be a 3-letter ISO code" }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 67. `PATCH /admin/pricingplans/:id`

- **Handler:** `AdminController.updatePricingPlan()`
- **Source:** `admin/admin.controller.ts:773`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updatePricingPlan(id, headerId, updatePricingPlanDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `CreatePricingPlanDto` from `@Body() updatePricingPlanDto: CreatePricingPlanDto` — source: `admin/dto/createpricingplan.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `durationDays` | `number` | Yes | @IsInt(), @Min(1) |
| `price` | `number` | Yes | @IsNumber(), @Min(0) |
| `currency` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(3, 3), @Matches(/^[A-Z]{3}$/, { message: "currency must be a 3-letter ISO code" }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 68. `GET /admin/profile`

- **Handler:** `AdminController.getProfile()`
- **Source:** `admin/admin.controller.ts:630`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getProfile(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 69. `PATCH /admin/profile`

- **Handler:** `AdminController.updateProfile()`
- **Source:** `admin/admin.controller.ts:635`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateProfile(headerId, profileDto)`

**Body / payload**

- Object binding: `ProfileDto` from `@Body() profileDto: ProfileDto` — source: `superadmin/dto/profile.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 70. `GET /admin/profile/email-subscription`

- **Handler:** `AdminController.getEmailSubscription()`
- **Source:** `admin/admin.controller.ts:668`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, data: { isSubscribed: subscribed, brandOwnerId, scope } }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 71. `POST /admin/profile/email-subscription/subscribe`

- **Handler:** `AdminController.subscribeEmail()`
- **Source:** `admin/admin.controller.ts:679`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Subscribed', data: { isSubscribed: true } }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 72. `POST /admin/profile/verify/email/confirm`

- **Handler:** `AdminController.verifyEmailOtp()`
- **Source:** `admin/admin.controller.ts:649`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyEmailOtp(headerId, dto.otp)`

**Body / payload**

- Object binding: `VerifyOtpDto` from `@Body() dto: VerifyOtpDto` — source: `verification/dto/verify-otp.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 73. `POST /admin/profile/verify/email/request`

- **Handler:** `AdminController.requestEmailOtp()`
- **Source:** `admin/admin.controller.ts:644`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestEmailOtp(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 74. `POST /admin/profile/verify/whatsapp/confirm`

- **Handler:** `AdminController.verifyWhatsAppOtp()`
- **Source:** `admin/admin.controller.ts:659`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyWhatsAppOtp(headerId, dto.otp)`

**Body / payload**

- Object binding: `VerifyOtpDto` from `@Body() dto: VerifyOtpDto` — source: `verification/dto/verify-otp.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 75. `POST /admin/profile/verify/whatsapp/request`

- **Handler:** `AdminController.requestWhatsAppOtp()`
- **Source:** `admin/admin.controller.ts:654`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestWhatsAppOtp(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 76. `GET /admin/quickdevice`

- **Handler:** `AdminController.getQuickDevices()`
- **Source:** `admin/admin.controller.ts:301`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getQuickDevices(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 77. `POST /admin/quickdevice`

- **Handler:** `AdminController.createQuickDevice()`
- **Source:** `admin/admin.controller.ts:308`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createQuickDevice(headerId, imei, deviceTypeId, simNumber)`

**Body / payload**

- Object binding: `QuickDeviceDto` from `@Body() quickDeviceDto: QuickDeviceDto` — source: `admin/dto/quickdevice.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(4, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `simNumber` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 30), @Matches(/^\d+$/, { message: "simNumber must contain digits only" }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 78. `GET /admin/quicksimcards`

- **Handler:** `AdminController.getQuickSimCards()`
- **Source:** `admin/admin.controller.ts:314`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getQuickSimCards(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 79. `GET /admin/shortusers`

- **Handler:** `AdminController.getShortUsers()`
- **Source:** `admin/admin.controller.ts:104`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getShortUsers(headerId, search)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `search` | `string` | Yes | `@Query('search') search?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 80. `GET /admin/simcards`

- **Handler:** `AdminController.getSimCards()`
- **Source:** `admin/admin.controller.ts:268`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getSimCards(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 81. `POST /admin/simcards`

- **Handler:** `AdminController.createSimCard()`
- **Source:** `admin/admin.controller.ts:273`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createSimCard(headerId, CreateSimCardDto)`

**Body / payload**

- Object binding: `SimCardDto` from `@Body() CreateSimCardDto: SimCardDto` — source: `admin/dto/sim.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `simNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional() |
| `status` | `'IN_STOCK' \| 'IN_USE' \| 'IN_SCRAP'` | No | @IsOptional(), @ToStringish(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 82. `DELETE /admin/simcards/:id`

- **Handler:** `AdminController.deleteSimCard()`
- **Source:** `admin/admin.controller.ts:278`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteSimCard(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 83. `GET /admin/simcards/:id`

- **Handler:** `AdminController.getSimCardById()`
- **Source:** `admin/admin.controller.ts:289`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getSimCardById(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 84. `PATCH /admin/simcards/:id`

- **Handler:** `AdminController.updateSimCard()`
- **Source:** `admin/admin.controller.ts:294`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateSimCard(id, headerId, UpdateSimCardDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `SimCardDto` from `@Body() UpdateSimCardDto: SimCardDto` — source: `admin/dto/sim.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `simNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional() |
| `status` | `'IN_STOCK' \| 'IN_USE' \| 'IN_SCRAP'` | No | @IsOptional(), @ToStringish(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 85. `GET /admin/smtpconfig`

- **Handler:** `AdminController.getSmtpConfig()`
- **Source:** `admin/admin.controller.ts:592`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getSmtpConfig(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 86. `PATCH /admin/smtpconfig`

- **Handler:** `AdminController.patchSmtpConfig()`
- **Source:** `admin/admin.controller.ts:603`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateSmtpConfig(headerId, smtpConfig)`

**Body / payload**

- Object binding: `UpdateSmtpConfigDto` from `@Body() smtpConfig: UpdateSmtpConfigDto` — source: `admin/dto/updatesmtpconfig.dto.ts:19`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 87. `POST /admin/smtpconfig`

- **Handler:** `AdminController.updateSmtpConfig()`
- **Source:** `admin/admin.controller.ts:597`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateSmtpConfig(headerId, smtpConfig)`

**Body / payload**

- Object binding: `UpdateSmtpConfigDto` from `@Body() smtpConfig: UpdateSmtpConfigDto` — source: `admin/dto/updatesmtpconfig.dto.ts:19`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 88. `GET /admin/systemvariables`

- **Handler:** `AdminController.getSystemVariables()`
- **Source:** `admin/admin.controller.ts:1286`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.adminService.getAdminSystemVariables()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 89. `GET /admin/teams`

- **Handler:** `AdminController.getTeams()`
- **Source:** `admin/admin.controller.ts:903`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTeams(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 90. `POST /admin/teams`

- **Handler:** `AdminController.createTeam()`
- **Source:** `admin/admin.controller.ts:907`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createTeam(createTeamDto, headerId)`

**Body / payload**

- Object binding: `CreateTeamMemberDto` from `@Body() createTeamDto: CreateTeamMemberDto` — source: `admin/dto/createteam.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `email` | `string` | Yes | @IsEmail(), @IsNotEmpty() |
| `mobilePrefix` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `mobileNumber` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `username` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `password` | `string` | Yes | @IsString(), @IsNotEmpty() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 91. `DELETE /admin/teams/:id`

- **Handler:** `AdminController.deleteTeam()`
- **Source:** `admin/admin.controller.ts:919`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteTeam(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 92. `GET /admin/teams/:id`

- **Handler:** `AdminController.getTeamById()`
- **Source:** `admin/admin.controller.ts:911`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTeamById(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 93. `PATCH /admin/teams/:id`

- **Handler:** `AdminController.updateTeam()`
- **Source:** `admin/admin.controller.ts:915`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateTeam(id, updateTeamDto, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateTeamMemberDto` from `@Body() updateTeamDto: UpdateTeamMemberDto` — source: `admin/dto/updateteam.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString() |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 94. `POST /admin/testsmtp`

- **Handler:** `AdminController.testSmtpSettings()`
- **Source:** `admin/admin.controller.ts:608`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.testSmtpSettings(headerId, email)`

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `email` | `string` | Yes | `@Body('email') email: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 95. `GET /admin/tickets`

- **Handler:** `AdminController.listAdminTickets()`
- **Source:** `admin/admin.controller.ts:113`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.listAdminTickets(headerId, { status, search, userId })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `search` | `string` | Yes | `@Query('search') search?: string` |
| `userId` | `string` | Yes | `@Query('userId') userId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 96. `POST /admin/tickets`

- **Handler:** `AdminController.createAdminTicket()`
- **Source:** `admin/admin.controller.ts:131`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createAdminTicket(headerId, req, body)`

**Body / payload**

- Object binding: `any` from `@Body() body: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 97. `GET /admin/tickets/:id`

- **Handler:** `AdminController.getAdminTicketById()`
- **Source:** `admin/admin.controller.ts:123`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getAdminTicketById(ticketId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 98. `POST /admin/tickets/:id/messages`

- **Handler:** `AdminController.replyAdminTicket()`
- **Source:** `admin/admin.controller.ts:140`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.replyAdminTicket(ticketId, headerId, req, body)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Body / payload**

- Object binding: `any` from `@Body() body: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 99. `PATCH /admin/tickets/:id/status`

- **Handler:** `AdminController.updateAdminTicketStatus()`
- **Source:** `admin/admin.controller.ts:150`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminTicketStatus(ticketId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Body / payload**

- Object binding: `AdminUpdateTicketStatusDto` from `@Body() dto: AdminUpdateTicketStatusDto` — source: `admin/dto/admin-update-ticket-status.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 100. `GET /admin/topbar-search`

- **Handler:** `AdminController.searchTopbar()`
- **Source:** `admin/admin.controller.ts:91`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.topbarSearch.searchForAdmin(headerId, dto)`

**Query params**

- Object binding: `TopbarSearchQueryDto` from `@Query() dto: TopbarSearchQueryDto` — source: `topbar-search/dto/topbar-search.dto.ts:13`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `q` | `string` | Yes | @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @IsString(), @IsNotEmpty(), @MinLength(2), @MaxLength(80) |
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(30) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 101. `GET /admin/transactions`

- **Handler:** `AdminController.listAdminTransactions()`
- **Source:** `admin/admin.controller.ts:991`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 102. `GET /admin/transactions/analytics`

- **Handler:** `AdminController.transactionsAnalytics()`
- **Source:** `admin/admin.controller.ts:1005`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `string` | Yes | `@Query('userId') userId?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `month` | `string` | Yes | `@Query('month') month?: string` |
| `year` | `string` | Yes | `@Query('year') year?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 103. `POST /admin/transactions/renew`

- **Handler:** `AdminController.renewVehicles()`
- **Source:** `admin/admin.controller.ts:1047`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Vehicles renewed successfully', data }`

**Body / payload**

- Object binding: `AdminRenewVehiclesDto` from `@Body() dto: AdminRenewVehiclesDto` — source: `admin/dto/admin-transactions.dto.ts:20`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `userId` | `number` | Yes | @Type(() => Number), @IsInt(), @Min(1) |
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @Type(() => Number), @IsInt({ each: true }) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `amountOverride` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+(\.\d{1,2})?$/, { message: 'amountOverride must be a valid decimal string (e.g., "150.00")' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 104. `GET /admin/unlinkusers/:vehicleId`

- **Handler:** `AdminController.getUnlinkedUsers()`
- **Source:** `admin/admin.controller.ts:809`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedUsers(vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 105. `POST /admin/unlinkusers/:vehicleId`

- **Handler:** `AdminController.unlinkUsers()`
- **Source:** `admin/admin.controller.ts:813`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkVehicleFromUser(userId, vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Body('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 106. `GET /admin/unlinkvehicles/:userId`

- **Handler:** `AdminController.getUnlinkedVehicles()`
- **Source:** `admin/admin.controller.ts:789`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedVehicles(userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 107. `POST /admin/unlinkvehicles/:userId`

- **Handler:** `AdminController.unlinkVehicles()`
- **Source:** `admin/admin.controller.ts:794`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkVehicleFromUser(userId, vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Body('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 108. `PATCH /admin/updatepassword`

- **Handler:** `AdminController.patchPasswordAdmin()`
- **Source:** `admin/admin.controller.ts:620`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminPassword(headerId, currentPassword, newPassword)`

**Body / payload**

- Object binding: `{ currentPassword: string, newPassword: string }` from `@Body() body: { currentPassword: string, newPassword: string }`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 109. `POST /admin/updatepassword`

- **Handler:** `AdminController.updatePasswordAdmin()`
- **Source:** `admin/admin.controller.ts:613`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminPassword(headerId, currentPassword, newPassword)`

**Body / payload**

- Object binding: `{ currentPassword: string, newPassword: string }` from `@Body() body: { currentPassword: string, newPassword: string }`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 110. `POST /admin/updateuserpassword/:id`

- **Handler:** `AdminController.updatePassword()`
- **Source:** `admin/admin.controller.ts:233`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateuserPassword(id, headerId, newPassword)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `{ newPassword: string }` from `@Body() body: { newPassword: string }`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 111. `POST /admin/upload`

- **Handler:** `AdminController.uploadFile()`
- **Source:** `admin/admin.controller.ts:709`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `result` OR `{ action: false, message: error.message \|\| 'Upload failed', data: null }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 112. `POST /admin/uploaddoc`

- **Handler:** `AdminController.uploadDocument()`
- **Source:** `admin/admin.controller.ts:723`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.uploadDocumentMultipart(req, headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 113. `DELETE /admin/uploaddoc/:id`

- **Handler:** `AdminController.deleteDocument()`
- **Source:** `admin/admin.controller.ts:733`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.adminService.deleteDocument(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 114. `PATCH /admin/uploaddoc/:id`

- **Handler:** `AdminController.updateDocument()`
- **Source:** `admin/admin.controller.ts:728`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateDocumentMultipartWithAuth(req, id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 115. `POST /admin/userbulkjobs`

- **Handler:** `AdminController.createUserBulkJob()`
- **Source:** `admin/admin.controller.ts:417`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Body / payload**

- Object binding: `CreateUserBulkJobDto` from `@Body() dto: CreateUserBulkJobDto` — source: `admin/dto/userbulkjobs.dto.ts:101`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `rows` | `UserBulkJobRowDto[]` | Yes | @IsArray(), @ValidateNested({ each: true }), @Type(() => UserBulkJobRowDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 116. `GET /admin/userbulkjobs/:id`

- **Handler:** `AdminController.getUserBulkJob()`
- **Source:** `admin/admin.controller.ts:423`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' }` OR `{ action: true, message: 'Job fetched', data: job }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 117. `GET /admin/userbulkjobs/:id/failed.csv`

- **Handler:** `AdminController.downloadUserFailedCsv()`
- **Source:** `admin/admin.controller.ts:430`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 118. `GET /admin/userbulkjobs/:id/stream`

- **Handler:** `AdminController.streamUserBulkJob()`
- **Source:** `admin/admin.controller.ts:444`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 119. `GET /admin/userlogin/:id`

- **Handler:** `AdminController.adminLogin()`
- **Source:** `admin/admin.controller.ts:223`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.userLogin(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param("id", ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 120. `GET /admin/users`

- **Handler:** `AdminController.getUsers()`
- **Source:** `admin/admin.controller.ts:99`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUsers(headerId, search)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `search` | `string` | Yes | `@Query('search') search?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 121. `POST /admin/users`

- **Handler:** `AdminController.createUser()`
- **Source:** `admin/admin.controller.ts:208`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createUser(headerId, CreateUserDto)`

**Body / payload**

- Object binding: `CreateUserDto` from `@Body() CreateUserDto: CreateUserDto` — source: `admin/dto/createuser.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString() |
| `email` | `string` | No | @IsOptional(), @IsString() |
| `mobilePrefix` | `string` | Yes | @IsString() |
| `mobileNumber` | `string` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString() |
| `password` | `string` | Yes | @IsString() |
| `companyName` | `string` | No | @IsOptional(), @IsString() |
| `address` | `string` | Yes | @IsString() |
| `countryCode` | `string` | Yes | @IsString() |
| `stateCode` | `string` | No | @IsOptional(), @IsString() |
| `city` | `string` | No | @IsOptional(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 122. `DELETE /admin/users/:id`

- **Handler:** `AdminController.deleteUser()`
- **Source:** `admin/admin.controller.ts:228`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteUser(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 123. `GET /admin/users/:id`

- **Handler:** `AdminController.getUserById()`
- **Source:** `admin/admin.controller.ts:213`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.adminService.getUserById(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 124. `PATCH /admin/users/:id`

- **Handler:** `AdminController.updateUser()`
- **Source:** `admin/admin.controller.ts:218`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateUser(id, UpdateUserDto, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateUserDto` from `@Body() UpdateUserDto: UpdateUserDto` — source: `admin/dto/updateuser.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `roleId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `name` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `email` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `mobilePrefix` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `username` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `password` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `companyName` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `address` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `countryCode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `stateCode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `city` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 125. `GET /admin/users/:id/activitylogs`

- **Handler:** `AdminController.getUserActivityLogs()`
- **Source:** `admin/admin.controller.ts:1060`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUserActivityLogs(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Query params**

- Object binding: `UserActivityLogsDto` from `@Query() dto: UserActivityLogsDto` — source: `admin/dto/user-activity-logs.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `actionPrefix` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 126. `GET /admin/users/linkeddrivers/:userId`

- **Handler:** `AdminController.getLinkedDriversForUser()`
- **Source:** `admin/admin.controller.ts:884`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedDriversForUser(userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 127. `POST /admin/users/linkeddrivers/:userId`

- **Handler:** `AdminController.linkDriversToUser()`
- **Source:** `admin/admin.controller.ts:892`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkDriverToUser(driverId, userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Body('driverId', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 128. `GET /admin/users/unlinkeddrivers/:userId`

- **Handler:** `AdminController.getUnlinkedDriversForUser()`
- **Source:** `admin/admin.controller.ts:888`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedDriversForUser(userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 129. `POST /admin/users/unlinkeddrivers/:userId`

- **Handler:** `AdminController.unlinkDriversFromUser()`
- **Source:** `admin/admin.controller.ts:897`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkDriverFromUser(driverId, userId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Body('driverId', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 130. `POST /admin/vehiclebulkjobs`

- **Handler:** `AdminController.createVehicleBulkJob()`
- **Source:** `admin/admin.controller.ts:321`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Body / payload**

- Object binding: `CreateVehicleBulkJobDto` from `@Body() dto: CreateVehicleBulkJobDto` — source: `admin/dto/vehiclebulkjobs.dto.ts:63`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `primaryUserId` | `string` | Yes | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty() |
| `planId` | `string` | Yes | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty() |
| `trackerDeviceTypeId` | `string` | Yes | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty() |
| `rows` | `VehicleBulkJobRowDto[]` | Yes | @IsArray(), @ValidateNested({ each: true }), @Type(() => VehicleBulkJobRowDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 131. `GET /admin/vehiclebulkjobs/:id`

- **Handler:** `AdminController.getVehicleBulkJob()`
- **Source:** `admin/admin.controller.ts:327`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' }` OR `{ action: true, message: 'Job fetched', data: job }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 132. `GET /admin/vehiclebulkjobs/:id/failed.csv`

- **Handler:** `AdminController.downloadFailedCsv()`
- **Source:** `admin/admin.controller.ts:334`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 133. `GET /admin/vehiclebulkjobs/:id/stream`

- **Handler:** `AdminController.streamVehicleBulkJob()`
- **Source:** `admin/admin.controller.ts:352`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 134. `GET /admin/vehicles`

- **Handler:** `AdminController.getVehicles()`
- **Source:** `admin/admin.controller.ts:459`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.adminService.getVehicles(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 135. `POST /admin/vehicles`

- **Handler:** `AdminController.createVehicle()`
- **Source:** `admin/admin.controller.ts:464`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createVehicle(headerId, CreateVehicleDto)`

**Body / payload**

- Object binding: `CreateVehicleDto` from `@Body() CreateVehicleDto: CreateVehicleDto` — source: `admin/dto/createvehicle.dto.ts:19`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty(), @MaxLength(120) |
| `vin` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)), @MaxLength(64) |
| `plateNumber` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)), @MaxLength(32) |
| `deviceId` | `number \| string` | Yes | @IsDefined(), @Transform(({ value }) => toNumberIfNumeric(value)), @ValidateIf((_, v) => typeof v === 'number' \|\| (typeof v === 'string' && /^\d+$/.test(v))), @IsInt(), @ValidateIf((_, v) => typeof v === 'string' && !/^\d+$/.test(v)), @IsString() |
| `vehicleTypeId` | `number \| string` | Yes | @IsDefined(), @Transform(({ value }) => toNumberIfNumeric(value)), @ValidateIf((_, v) => typeof v === 'number' \|\| (typeof v === 'string' && /^\d+$/.test(v))), @IsInt(), @ValidateIf((_, v) => typeof v === 'string' && !/^\d+$/.test(v)), @IsString() |
| `primaryUserId` | `number \| string` | Yes | @IsDefined(), @Transform(({ value }) => toNumberIfNumeric(value)), @ValidateIf((_, v) => typeof v === 'number' \|\| (typeof v === 'string' && /^\d+$/.test(v))), @IsInt(), @ValidateIf((_, v) => typeof v === 'string' && !/^\d+$/.test(v)), @IsString() |
| `planId` | `number \| string` | Yes | @IsDefined(), @Transform(({ value }) => toNumberIfNumeric(value)), @ValidateIf((_, v) => typeof v === 'number' \|\| (typeof v === 'string' && /^\d+$/.test(v))), @IsInt(), @ValidateIf((_, v) => typeof v === 'string' && !/^\d+$/.test(v)), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 136. `DELETE /admin/vehicles/:id`

- **Handler:** `AdminController.deleteVehicle()`
- **Source:** `admin/admin.controller.ts:479`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteVehicle(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 137. `GET /admin/vehicles/:id`

- **Handler:** `AdminController.getVehicleById()`
- **Source:** `admin/admin.controller.ts:474`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleById(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 138. `PATCH /admin/vehicles/:id`

- **Handler:** `AdminController.updateVehicle()`
- **Source:** `admin/admin.controller.ts:469`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateVehicle(id, headerId, UpdateVehicleDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateVehicleDto` from `@Body() UpdateVehicleDto: UpdateVehicleDto` — source: `admin/dto/updatevehicle.dto.ts:37`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `vin` | `string` | No | @IsOptional(), @IsString() |
| `plateNumber` | `string` | No | @IsOptional(), @IsString() |
| `deviceid` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `vehicleTypeId` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `planid` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `gmtOffset` | `string` | No | @IsOptional(), @ToTrimmedString(), @Matches(/^[+-](0\d\|1[0-4]):[0-5]\d$/) |
| `isActive` | `boolean` | No | @IsOptional(), @ToOptionalBool(), @IsBoolean() |
| `vehicleMeta` | `Record<string, any>` | No | @IsOptional(), @ToOptionalJSON(), @IsObject() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 139. `PATCH /admin/vehicles/:id/config`

- **Handler:** `AdminController.updateVehicleConfig()`
- **Source:** `admin/admin.controller.ts:484`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateVehicleConfig(vehicleId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `UpdateVehicleConfigDto` from `@Body() dto: UpdateVehicleConfigDto` — source: `admin/dto/update-vehicle-config.dto.ts:17`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `speedVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `distanceVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `odometer` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `engineHours` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `ignitionSource` | `'ACC' \| 'MOTION'` | No | @IsOptional(), @ToOptionalUpper(), @IsIn(['ACC', 'MOTION']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 140. `GET /admin/vehicles/:vehicleId/sensors`

- **Handler:** `AdminController.listVehicleSensors()`
- **Source:** `admin/admin.controller.ts:497`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.listVehicleSensors(headerId, vehicleId, { search, page, limit, includeLive: includeLive === 'true', })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `search` | `string` | Yes | `@Query('search') search?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `includeLive` | `string` | Yes | `@Query('includeLive') includeLive?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 141. `POST /admin/vehicles/:vehicleId/sensors`

- **Handler:** `AdminController.createVehicleSensor()`
- **Source:** `admin/admin.controller.ts:512`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createVehicleSensor(headerId, vehicleId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `CreateVehicleSensorDto` from `@Body() dto: CreateVehicleSensorDto` — source: `user/dto/sensors/create-vehicle-sensor.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 142. `DELETE /admin/vehicles/:vehicleId/sensors/:sensorId`

- **Handler:** `AdminController.deleteVehicleSensor()`
- **Source:** `admin/admin.controller.ts:531`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteVehicleSensor(headerId, vehicleId, sensorId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 143. `PATCH /admin/vehicles/:vehicleId/sensors/:sensorId`

- **Handler:** `AdminController.updateVehicleSensor()`
- **Source:** `admin/admin.controller.ts:521`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateVehicleSensor(headerId, vehicleId, sensorId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Body / payload**

- Object binding: `UpdateVehicleSensorDto` from `@Body() dto: UpdateVehicleSensorDto` — source: `user/dto/sensors/update-vehicle-sensor.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | No | @IsOptional(), @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 144. `POST /admin/vehicles/:vehicleId/sensors/run`

- **Handler:** `AdminController.runVehicleSensor()`
- **Source:** `admin/admin.controller.ts:540`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.runVehicleSensor(headerId, vehicleId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `RunVehicleSensorDto` from `@Body() dto: RunVehicleSensorDto` — source: `user/dto/sensors/run-vehicle-sensor.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `payload` | `Record<string, unknown>` | Yes | @IsObject() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 145. `GET /admin/vehicles/:vehicleId/sensors/telemetry`

- **Handler:** `AdminController.getVehicleSensorTelemetry()`
- **Source:** `admin/admin.controller.ts:549`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleSensorTelemetry(headerId, vehicleId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 146. `GET /admin/vehicles/by-imei/:imei/commands`

- **Handler:** `AdminController.getCommandHistoryByImei()`
- **Source:** `admin/admin.controller.ts:1313`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCommandHistoryByImei(adminId, imei, { limit, cursorId })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `cursorId` | `string` | Yes | `@Query('cursorId') cursorId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 147. `GET /admin/vehicles/by-imei/:imei/details`

- **Handler:** `AdminController.getVehicleDetailsByImei()`
- **Source:** `admin/admin.controller.ts:1135`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleDetailsByImei(headerId, imei)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 148. `GET /admin/vehicles/by-imei/:imei/events`

- **Handler:** `AdminController.getVehicleEventsByImei()`
- **Source:** `admin/admin.controller.ts:1155`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleEventsByImei(headerId!, imei, query)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

- Object binding: `MapEventsQueryDto` from `@Query() query: MapEventsQueryDto` — source: `superadmin/dto/map-events.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 149. `GET /admin/vehicles/by-imei/:imei/events/export`

- **Handler:** `AdminController.exportVehicleEventsCsv()`
- **Source:** `admin/admin.controller.ts:1181`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `source` | `string` | Yes | `@Query('source') source?: string` |
| `severity` | `string` | Yes | `@Query('severity') severity?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 150. `GET /admin/vehicles/by-imei/:imei/history`

- **Handler:** `AdminController.getVehicleHistoryByImei()`
- **Source:** `admin/admin.controller.ts:1223`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleHistoryByImei(headerId!, imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | Yes | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | Yes | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 151. `GET /admin/vehicles/by-imei/:imei/logs`

- **Handler:** `AdminController.getVehicleLogsByImei()`
- **Source:** `admin/admin.controller.ts:1143`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleLogsByImei(headerId!, imei, { from, to, limit, beforeId })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `beforeId` | `string` | Yes | `@Query('beforeId') beforeId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 152. `GET /admin/vehicles/by-imei/:imei/logs/export`

- **Handler:** `AdminController.exportVehicleLogsCsv()`
- **Source:** `admin/admin.controller.ts:1164`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 153. `GET /admin/vehicles/by-imei/:imei/replay`

- **Handler:** `AdminController.getVehicleReplayByImei()`
- **Source:** `admin/admin.controller.ts:1212`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleReplayByImei(headerId!, imei, { from, to, maxPoints })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 154. `POST /admin/vehicles/by-imei/:imei/send-command`

- **Handler:** `AdminController.sendDeviceCommandByImei()`
- **Source:** `admin/admin.controller.ts:1295`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.sendDeviceCommandByImei(headerId, imei, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Body / payload**

- Object binding: `SendDeviceCommandDto` from `@Body() dto: SendDeviceCommandDto` — source: `superadmin/dto/send-device-command.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 155. `GET /admin/vehicles/by-imei/:imei/sensors`

- **Handler:** `AdminController.getVehicleSensorsByImei()`
- **Source:** `admin/admin.controller.ts:1238`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleSensorsByImei(headerId, imei, { includeTelemetryMeta })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `includeTelemetryMeta` | `string` | Yes | `@Query('includeTelemetryMeta') includeTelemetryMeta?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 156. `GET /admin/vehicles/by-imei/:imei/trail`

- **Handler:** `AdminController.getVehicleTrailByImei()`
- **Source:** `admin/admin.controller.ts:1200`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleTrailByImei(headerId!, imei, { hours, from, to, maxPoints })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `hours` | `string` | Yes | `@Query('hours') hours?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 157. `GET /admin/whitelabel`

- **Handler:** `AdminController.getWhiteLabelSettings()`
- **Source:** `admin/admin.controller.ts:941`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getWhiteLabelSettings(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 158. `PATCH /admin/whitelabel`

- **Handler:** `AdminController.updateWhiteLabelSettings()`
- **Source:** `admin/admin.controller.ts:951`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateWhiteLabelSettings(req, headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 159. `GET /admin/whitelabel/inspect`

- **Handler:** `AdminController.inspectWhiteLabelBranding()`
- **Source:** `admin/admin.controller.ts:946`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.inspectWhiteLabelBranding(headerId, host)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `host` | `string` | Yes | `@Query('host') host?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AgentController

### 160. `POST /agent/commands`

- **Handler:** `AgentController.createCommand()`
- **Source:** `agent/controllers/agent.controller.ts:33`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Command received', data: result }`

**Body / payload**

- Object binding: `CreateAgentCommandDto` from `@Body() dto: CreateAgentCommandDto` — source: `agent/dto/create-agent-command.dto.ts:33`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @MaxLength(1000) |
| `channel` | `'WEB' \| 'API' \| 'WHATSAPP' \| 'WORKFLOW'` | No | @IsOptional(), @IsEnum(['WEB', 'API', 'WHATSAPP', 'WORKFLOW']) |
| `payload` | `StructuredCommandPayload` | No | @IsOptional(), @ValidateNested(), @Type(() => StructuredCommandPayload) |
| `metadata` | `Record<string, any>` | No | @IsOptional(), @IsObject() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 161. `GET /agent/executions/:executionId`

- **Handler:** `AgentController.getExecution()`
- **Source:** `agent/controllers/agent.controller.ts:55`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Execution loaded', data: execution }`

**Path params**

- Object binding: `ExecutionIdParamDto` from `@Param() params: ExecutionIdParamDto` — source: `agent/dto/execution-id-param.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `executionId` | `string` | Yes | @IsUUID() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 162. `GET /agent/executions/:executionId/status`

- **Handler:** `AgentController.getExecutionStatus()`
- **Source:** `agent/controllers/agent.controller.ts:75`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Status loaded', data: status }`

**Path params**

- Object binding: `ExecutionIdParamDto` from `@Param() params: ExecutionIdParamDto` — source: `agent/dto/execution-id-param.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `executionId` | `string` | Yes | @IsUUID() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AuthController

### 163. `GET /auth/checksadmin`

- **Handler:** `AuthController.getChecksAdmin()`
- **Source:** `auth/controllers/auth.controller.ts:22`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.getChecksAdmin()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 164. `POST /auth/createsuperadmin`

- **Handler:** `AuthController.createSuperAdmin()`
- **Source:** `auth/controllers/auth.controller.ts:28`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.authService.createSuperAdmin(superadminDto)`

**Body / payload**

- Object binding: `CreateSuperAdminDto` from `@Body() superadminDto: CreateSuperAdminDto` — source: `auth/dto/superadmin.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString() |
| `email` | `string` | Yes | @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsString() |
| `mobileNumber` | `string` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString() |
| `password` | `string` | Yes | @IsString(), @MinLength(6) |
| `companyName` | `string` | Yes | @IsString() |
| `website` | `string` | No | @IsOptional(), @IsString() |
| `address` | `string` | Yes | @IsString() |
| `country` | `string` | Yes | @IsString() |
| `state` | `string` | Yes | @IsString() |
| `city` | `string` | Yes | @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 165. `POST /auth/email-test`

- **Handler:** `AuthController.testEmail()`
- **Source:** `auth/controllers/auth.controller.ts:129`
- **Auth:** Bearer JWT
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.testEmailToMe(userId, dto)`

**Body / payload**

- Object binding: `TestEmailDto` from `@Body() dto: TestEmailDto` — source: `auth/dto/email-test.dto.ts:7`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `subject` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 166. `GET /auth/fcm-web-config`

- **Handler:** `AuthController.getFcmWebConfig()`
- **Source:** `auth/controllers/auth.controller.ts:88`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.getFcmWebConfig()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 167. `POST /auth/forgot-password`

- **Handler:** `AuthController.forgotPassword()`
- **Source:** `auth/controllers/auth.controller.ts:52`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.forgotPassword(dto.identifier, req)`

**Body / payload**

- Object binding: `ForgotPasswordDto` from `@Body() dto: ForgotPasswordDto` — source: `auth/dto/forgot-password.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `identifier` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 168. `GET /auth/google/client-id`

- **Handler:** `AuthController.getGoogleClientId()`
- **Source:** `auth/controllers/auth.controller.ts:71`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.getGoogleClientId()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 169. `POST /auth/google/login`

- **Handler:** `AuthController.googleLogin()`
- **Source:** `auth/controllers/auth.controller.ts:81`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<AuthResponseDto>`
- **Return expression/source:** `this.authService.googleLogin(dto.code, req)`

**Body / payload**

- Object binding: `GoogleLoginDto` from `@Body() dto: GoogleLoginDto` — source: `auth/dto/google-login.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 170. `POST /auth/login`

- **Handler:** `AuthController.login()`
- **Source:** `auth/controllers/auth.controller.ts:38`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<AuthResponseDto>`
- **Return expression/source:** `this.authService.login(loginDto, req)`

**Body / payload**

- Object binding: `LoginDto` from `@Body() loginDto: LoginDto` — source: `auth/dto/login.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `identifier` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `password` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 171. `POST /auth/push-test`

- **Handler:** `AuthController.testPush()`
- **Source:** `auth/controllers/auth.controller.ts:119`
- **Auth:** Bearer JWT
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.testPushToMe(userId, dto)`

**Body / payload**

- Object binding: `TestPushDto` from `@Body() dto: TestPushDto` — source: `auth/dto/push-token.dto.ts:32`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 172. `DELETE /auth/push-token`

- **Handler:** `AuthController.removePushToken()`
- **Source:** `auth/controllers/auth.controller.ts:103`
- **Auth:** Bearer JWT
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.removePushToken(userId, dto)`

**Body / payload**

- Object binding: `RemovePushTokenDto` from `@Body() dto: RemovePushTokenDto` — source: `auth/dto/push-token.dto.ts:48`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `token` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `deviceId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 173. `POST /auth/push-token`

- **Handler:** `AuthController.registerPushToken()`
- **Source:** `auth/controllers/auth.controller.ts:93`
- **Auth:** Bearer JWT
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.registerPushToken(userId, dto)`

**Body / payload**

- Object binding: `RegisterPushTokenDto` from `@Body() dto: RegisterPushTokenDto` — source: `auth/dto/push-token.dto.ts:7`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'token must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `platform` | `string` | No | @IsOptional(), @IsString(), @IsIn(['web', 'android', 'ios']) |
| `deviceId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `userAgent` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 174. `GET /auth/push-tokens/me`

- **Handler:** `AuthController.getMyPushTokens()`
- **Source:** `auth/controllers/auth.controller.ts:113`
- **Auth:** Bearer JWT
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.getMyPushTokens(userId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 175. `POST /auth/refresh-token`

- **Handler:** `AuthController.refreshToken()`
- **Source:** `auth/controllers/auth.controller.ts:44`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<AuthResponseDto>`
- **Return expression/source:** `this.authService.refreshToken(dto.refresh_token)`

**Body / payload**

- Object binding: `RefreshTokenDto` from `@Body() dto: RefreshTokenDto` — source: `auth/dto/refresh-token.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `refresh_token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'refresh_token must not be empty' }), @Transform(({ value }) => String(value).trim()) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 176. `POST /auth/reset-password`

- **Handler:** `AuthController.resetPassword()`
- **Source:** `auth/controllers/auth.controller.ts:58`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.authService.resetPassword(dto.token, dto.newPassword, req)`

**Body / payload**

- Object binding: `ResetPasswordDto` from `@Body() dto: ResetPasswordDto` — source: `auth/dto/reset-password.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `newPassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @MinLength(6), @MaxLength(35) |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AppController

### 177. `GET /branding`

- **Handler:** `AppController.getBranding()`
- **Source:** `app.controller.ts:221`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `null` OR `branding`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `host` | `string` | Yes | `@Query('host') hostQuery?: string` |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## BugReportController

### 178. `POST /bug-reports`

- **Handler:** `BugReportController.create()`
- **Source:** `bug-report/bug-report.controller.ts:28`
- **Auth:** Bearer JWT
- **Controller return type:** `any`
- **Return expression/source:** `this.bugReportService.submitBugReport( dto, request.user, this.extractRequestDetails(request), )`

**Body / payload**

- Object binding: `CreateBugReportDto` from `@Body() dto: CreateBugReportDto` — source: `bug-report/dto/create-bug-report.dto.ts:84`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `message` | `string` | Yes | @IsString(), @Transform(trimRequiredString), @IsNotEmpty(), @MinLength(5), @MaxLength(3000) |
| `category` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(80) |
| `severity` | `BugReportSeverity` | No | @IsOptional(), @Transform(({ value }) => { if (value === null \|\| value === undefined \|\| value === '') { return BugReportSeverity.MEDIUM; } return typeof value === 'string' ? value.trim().toUpperCase() : value; }), @IsEnum(BugReportSeverity) |
| `pageUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `route` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(500) |
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(300) |
| `screenshotDataUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @Validate(ScreenshotDataUrlConstraint), @Validate(ScreenshotDataUrlSizeConstraint) |
| `uploadedScreenshotDataUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @Validate(ScreenshotDataUrlConstraint), @Validate(ScreenshotDataUrlSizeConstraint) |
| `browser` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `os` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `device` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `screen` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `network` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `app` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `recentErrors` | `any[]` | No | @IsOptional(), @IsArray(), @ArrayMaxSize(20) |
| `stepsToReproduce` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `expectedBehavior` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `actualBehavior` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `extra` | `Record<string, any>` | No | @IsOptional(), @IsObject() |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AppController

### 179. `GET /cities/:countryCode/:stateCode`

- **Handler:** `AppController.getCities()`
- **Source:** `app.controller.ts:150`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Cities fetched successfully', data: this.appService.getCitiesByState(countryCode, stateCode) }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `countryCode` | `string` | Yes | `@Param('countryCode') countryCode: string` |
| `stateCode` | `string` | Yes | `@Param('stateCode') stateCode: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 180. `GET /countries`

- **Handler:** `AppController.getCountries()`
- **Source:** `app.controller.ts:139`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Countries fetched successfully', data: this.appService.getCountries() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 181. `GET /currencies`

- **Handler:** `AppController.getCurrencies()`
- **Source:** `app.controller.ts:158`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Currencies fetched successfully', data: this.appService.getCurrencies() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 182. `GET /dateformats`

- **Handler:** `AppController.getDateFormats()`
- **Source:** `app.controller.ts:211`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.appService.getDateFormats()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 183. `GET /devicestypes`

- **Handler:** `AppController.getDeviceTypes()`
- **Source:** `app.controller.ts:123`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.appService.getDeviceTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 184. `GET /documenttypes/:documentType`

- **Handler:** `AppController.getDocumentTypes()`
- **Source:** `app.controller.ts:216`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `await this.appService.getDocumentTypes(documentType)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `documentType` | `string` | Yes | `@Param('documentType') documentType: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## GeocodingController

### 185. `GET /geocoding/precision`

- **Handler:** `GeocodingController.precision()`
- **Source:** `geocoding/geocoding.controller.ts:111`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Current geocoding precision', data: { precision: p }, }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 186. `GET /geocoding/reverse`

- **Handler:** `GeocodingController.reverse()`
- **Source:** `geocoding/geocoding.controller.ts:35`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Address resolved', data: { address: result.address, cached: result.source !== 'api', precision, rounded: { lat: latRounded, lon: lonRounded }, providerUsed: result.providerUsed ?? result.source, }, }` OR `{ action: false, message: 'Geocoding failed internally', data: { address: '' }, }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `lat` | `string` | Yes | `@Query('lat') latRaw: string` |
| `lng` | `string` | Yes | `@Query('lng') lngRaw: string` |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 187. `POST /geocoding/reverse/bulk`

- **Handler:** `GeocodingController.reverseBulk()`
- **Source:** `geocoding/geocoding.controller.ts:87`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: `Resolved ${items.length} addresses`, data: { items }, }`

**Body / payload**

- Object binding: `BulkReverseGeocodeDto` from `@Body() dto: BulkReverseGeocodeDto` — source: `geocoding/dto/reverse-geocode.dto.ts:36`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `points` | `BulkPointDto[]` | Yes | @IsArray(), @ArrayMinSize(1), @ArrayMaxSize(100), @ValidateNested({ each: true }), @Type(() => BulkPointDto) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## HandledataController

### 188. `POST /handledata`

- **Handler:** `HandledataController.handleData()`
- **Source:** `handledata/handledata.controller.ts:8`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.handledataService.ingest(payload)`

**Body / payload**

- Object binding: `any` from `@Body() payload: any`

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## HealthController

### 189. `GET /health`

- **Handler:** `HealthController.getHealth()`
- **Source:** `health/health.controller.ts:47`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: primaryHealth && logsHealth && addressHealth && redisHealth ? 'ok' : 'degraded', timestamp: new Date().toISOString(), service: 'NestJS Backend', build: this.buildFingerprint(), runtime: describeBackendRuntimeProfile(), services: { redis: { status: redisHealth ? 'connected' : 'disconnected', durability: redisDurability, }, databases: { primary: primaryHealth ? 'connected' : 'disconnected', logs: logsHealth ? 'connected' : 'disconnected', address: addressHealth ? 'connected' : 'disconnected', }, }, }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 190. `GET /health/address-db`

- **Handler:** `HealthController.getAddressDbHealth()`
- **Source:** `health/health.controller.ts:130`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: isHealthy ? 'ok' : 'error', database: 'address', timestamp: new Date().toISOString(), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 191. `GET /health/databases`

- **Handler:** `HealthController.getDatabasesHealth()`
- **Source:** `health/health.controller.ts:77`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: primaryHealth && logsHealth && addressHealth ? 'ok' : 'degraded', timestamp: new Date().toISOString(), runtime: describeBackendRuntimeProfile(), redis: { durability: redisDurability, }, databases: { primary: { status: primaryHealth ? 'connected' : 'disconnected', type: 'postgresql', }, logs: { status: logsHealth ? 'connected' : 'disconnected', type: 'postgresql', }, address: { status: addressHealth ? 'connected' : 'disconnected', type: 'postgresql', }, }, }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 192. `GET /health/logs-db`

- **Handler:** `HealthController.getLogsDbHealth()`
- **Source:** `health/health.controller.ts:120`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: isHealthy ? 'ok' : 'error', database: 'logs', timestamp: new Date().toISOString(), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 193. `GET /health/primary-db`

- **Handler:** `HealthController.getPrimaryDbHealth()`
- **Source:** `health/health.controller.ts:110`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: isHealthy ? 'ok' : 'error', database: 'primary', timestamp: new Date().toISOString(), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 194. `GET /health/telemetry-diagnostics/:imei`

- **Handler:** `HealthController.getTelemetryDiagnostics()`
- **Source:** `health/health.controller.ts:167`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), data: stats ? this.buildImeiTelemetrySummary(imei, stats) : null, }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 195. `GET /health/telemetry-packet/:imei/:sourcePacketId`

- **Handler:** `HealthController.getTelemetryPacket()`
- **Source:** `health/health.controller.ts:178`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), data: { imei, sourcePacketId, route, telemetryLog, deviceEventLog, }, }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |
| `sourcePacketId` | `string` | Yes | `@Param('sourcePacketId') sourcePacketId: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 196. `GET /health/telemetry-stats`

- **Handler:** `HealthController.getTelemetryStats()`
- **Source:** `health/health.controller.ts:140`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), runtime: describeBackendRuntimeProfile(), redis: { durability: redisDurability, }, data: this.buildGlobalTelemetrySummary(summary), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 197. `GET /health/telemetry-stats/:imei`

- **Handler:** `HealthController.getImeiTelemetryStats()`
- **Source:** `health/health.controller.ts:156`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), data: stats ? this.buildImeiTelemetrySummary(imei, stats) : null, }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AppController

### 198. `GET /languages`

- **Handler:** `AppController.getLanguages()`
- **Source:** `app.controller.ts:173`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.appService.getLanguages()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 199. `GET /mobileprefix`

- **Handler:** `AppController.getMobileCode()`
- **Source:** `app.controller.ts:133`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Mobile codes fetched successfully', data: this.appService.getMobileCode() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 200. `GET /policies`

- **Handler:** `AppController.getPolicies()`
- **Source:** `app.controller.ts:178`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Policies fetched successfully', data: policies }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 201. `GET /policies/:type`

- **Handler:** `AppController.getPolicyByType()`
- **Source:** `app.controller.ts:192`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: false, message: 'Policy not found', data: null }` OR `{ action: true, message: 'Policy fetched successfully', data: policy }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `type` | `string` | Yes | `@Param('type') type: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## PublicTrackController

### 202. `GET /public/track/:code`

- **Handler:** `PublicTrackController.getLinkMeta()`
- **Source:** `public-track/public-track.controller.ts:18`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getLinkMeta(code)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 203. `GET /public/track/:code/geofences`

- **Handler:** `PublicTrackController.getGeofences()`
- **Source:** `public-track/public-track.controller.ts:66`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getGeofences(code)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 204. `GET /public/track/:code/telemetry`

- **Handler:** `PublicTrackController.getMapTelemetry()`
- **Source:** `public-track/public-track.controller.ts:23`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getMapTelemetry(code)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 205. `GET /public/track/:code/vehicles/:imei/details`

- **Handler:** `PublicTrackController.getVehicleDetailsByImei()`
- **Source:** `public-track/public-track.controller.ts:28`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleDetailsByImei(code, imei)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 206. `GET /public/track/:code/vehicles/:imei/history`

- **Handler:** `PublicTrackController.getVehicleHistoryByImei()`
- **Source:** `public-track/public-track.controller.ts:47`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleHistoryByImei(code, imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | Yes | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | Yes | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 207. `GET /public/track/:code/vehicles/:imei/logs`

- **Handler:** `PublicTrackController.getVehicleLogsByImei()`
- **Source:** `public-track/public-track.controller.ts:71`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleLogsByImei(code, imei, { limit, beforeId })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `beforeId` | `string` | Yes | `@Query('beforeId') beforeId?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 208. `GET /public/track/:code/vehicles/:imei/replay`

- **Handler:** `PublicTrackController.getVehicleReplayByImei()`
- **Source:** `public-track/public-track.controller.ts:36`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleReplayByImei(code, imei, { from, to, maxPoints })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AppController

### 209. `GET /simproviders`

- **Handler:** `AppController.getSimProviders()`
- **Source:** `app.controller.ts:163`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'SIM Providers fetched successfully', data: await this.appService.getSimProviders() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 210. `GET /states/:countryCode`

- **Handler:** `AppController.getStates()`
- **Source:** `app.controller.ts:145`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'States fetched successfully', data: this.appService.getStatesByCountry(countryCode) }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `countryCode` | `string` | Yes | `@Param('countryCode') countryCode: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 211. `GET /status`

- **Handler:** `AppController.getStatus()`
- **Source:** `app.controller.ts:116`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `"Running"`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SuperadminController

### 212. `POST /superadmin/activateadmin/:id`

- **Handler:** `SuperadminController.activateAdmin()`
- **Source:** `superadmin/superadmin.controller.ts:154`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.activateAdmin(adminid, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param("id", ParseIntPipe) adminid: number` |

**Body / payload**

- Object binding: `ActivateAdminDto` from `@Body() dto: ActivateAdminDto` — source: `superadmin/dto/activateadmin.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `isActive` | `boolean` | Yes | @IsBoolean() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 213. `GET /superadmin/admin/:id`

- **Handler:** `SuperadminController.getAdminById()`
- **Source:** `superadmin/superadmin.controller.ts:142`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getAdminById(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 214. `GET /superadmin/admin/:id/activitylogs`

- **Handler:** `SuperadminController.getAdminActivityLogs()`
- **Source:** `superadmin/superadmin.controller.ts:665`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdminActivityLogs(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Query params**

- Object binding: `AdminActivityLogsDto` from `@Query() dto: AdminActivityLogsDto` — source: `superadmin/dto/admin-activity-logs.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `actionPrefix` | `string` | No | @IsOptional(), @IsString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 215. `GET /superadmin/adminlist`

- **Handler:** `SuperadminController.getAdminList()`
- **Source:** `superadmin/superadmin.controller.ts:137`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdminList(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 216. `GET /superadmin/adminlogin/:id`

- **Handler:** `SuperadminController.adminLogin()`
- **Source:** `superadmin/superadmin.controller.ts:163`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.adminLogin(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param("id", ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 217. `POST /superadmin/adminpasswordupdate`

- **Handler:** `SuperadminController.updateAdminPassword()`
- **Source:** `superadmin/superadmin.controller.ts:149`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateAdminPassword(adminpasswordupdate)`

**Body / payload**

- Object binding: `AdminPasswordUpdateDto` from `@Body() adminpasswordupdate: AdminPasswordUpdateDto` — source: `superadmin/dto/adminpasswordupdate.dto.ts:40`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `adminid` | `string` | Yes | @IsNotEmpty(), @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |
| `newpassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @MinLength(6), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |
| `confirmpassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @Match('newpassword', { message: 'confirmpassword must match newpassword' }), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 218. `GET /superadmin/adminvehicles/:adminId`

- **Handler:** `SuperadminController.getAdminVehiclesList()`
- **Source:** `superadmin/superadmin.controller.ts:675`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdminVehiclesList(adminId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `adminId` | `number` | Yes | `@Param('adminId', ParseIntPipe) adminId: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 219. `GET /superadmin/appnotifytemplates`

- **Handler:** `SuperadminController.getAppNotifyTemplates()`
- **Source:** `superadmin/superadmin.controller.ts:408`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getAppNotifyTemplates()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 220. `GET /superadmin/appnotifytemplates/:id`

- **Handler:** `SuperadminController.getAppNotifyTemplateById()`
- **Source:** `superadmin/superadmin.controller.ts:412`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getAppNotifyTemplateById(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 221. `PATCH /superadmin/appnotifytemplates/:id`

- **Handler:** `SuperadminController.updateAppNotifyTemplate()`
- **Source:** `superadmin/superadmin.controller.ts:416`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateAppNotifyTemplate(id, appNotifyTemplateDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `AppNotifyTemplateDto` from `@Body() appNotifyTemplateDto: AppNotifyTemplateDto` — source: `superadmin/dto/appnotifytempletes.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `notifySubject` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 120) |
| `message` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10000) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 222. `POST /superadmin/assigncredits/:id`

- **Handler:** `SuperadminController.assignCredits()`
- **Source:** `superadmin/superadmin.controller.ts:174`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.assignCredits(id, creditsUpdateDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `CreditsUpdateDto` from `@Body() creditsUpdateDto: CreditsUpdateDto` — source: `superadmin/dto/creditassign.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `credits` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `activity` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 223. `GET /superadmin/calendar/day`

- **Handler:** `SuperadminController.getCalendarDayDetails()`
- **Source:** `superadmin/superadmin.controller.ts:719`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCalendarDayDetails(dto.date, dto.types)`

**Query params**

- Object binding: `CalendarDayDto` from `@Query() dto: CalendarDayDto` — source: `superadmin/dto/calendar.dto.ts:86`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `date` | `string` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format', }) |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 224. `GET /superadmin/calendar/events`

- **Handler:** `SuperadminController.getCalendarEvents()`
- **Source:** `superadmin/superadmin.controller.ts:714`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCalendarEvents(dto.from, dto.to, dto.types)`

**Query params**

- Object binding: `CalendarRangeDto` from `@Query() dto: CalendarRangeDto` — source: `superadmin/dto/calendar.dto.ts:56`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `from` | `string` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'from must be in YYYY-MM-DD format', }) |
| `to` | `string` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'to must be in YYYY-MM-DD format', }), @Validate(IsValidDateRange) |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 225. `GET /superadmin/calendar/user/:uid`

- **Handler:** `SuperadminController.getCalendarUserDetails()`
- **Source:** `superadmin/superadmin.controller.ts:724`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCalendarUserDetails(uid)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `uid` | `number` | Yes | `@Param('uid', ParseIntPipe) uid: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 226. `GET /superadmin/commands/:cmdId`

- **Handler:** `SuperadminController.getCommandLogByCmdId()`
- **Source:** `superadmin/superadmin.controller.ts:1036`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCommandLogByCmdId(cmdId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 227. `GET /superadmin/commands/status/:cmdId`

- **Handler:** `SuperadminController.getCommandStatus()`
- **Source:** `superadmin/superadmin.controller.ts:1018`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCommandStatus(cmdId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 228. `GET /superadmin/commandtypes`

- **Handler:** `SuperadminController.getCommandTypes()`
- **Source:** `superadmin/superadmin.controller.ts:294`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getCommandTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 229. `POST /superadmin/commandtypes`

- **Handler:** `SuperadminController.createCommandType()`
- **Source:** `superadmin/superadmin.controller.ts:298`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createCommandType(commandTypeDto)`

**Body / payload**

- Object binding: `any` from `@Body() commandTypeDto: any`

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 230. `DELETE /superadmin/commandtypes/:id`

- **Handler:** `SuperadminController.deleteCommandType()`
- **Source:** `superadmin/superadmin.controller.ts:306`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteCommandType(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 231. `PATCH /superadmin/commandtypes/:id`

- **Handler:** `SuperadminController.updateCommandType()`
- **Source:** `superadmin/superadmin.controller.ts:302`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCommandType(id, commandTypeDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `any` from `@Body() commandTypeDto: any`

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 232. `GET /superadmin/companyconfig/:id`

- **Handler:** `SuperadminController.getCompanyConfig()`
- **Source:** `superadmin/superadmin.controller.ts:236`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getCompanyConfig(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 233. `PATCH /superadmin/companyconfig/:id`

- **Handler:** `SuperadminController.updateCompanyConfig()`
- **Source:** `superadmin/superadmin.controller.ts:241`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCompanyConfig(id, companyConfig)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `CompanyDto` from `@Body() companyConfig: CompanyDto` — source: `superadmin/dto/company.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 234. `PATCH /superadmin/companydetails`

- **Handler:** `SuperadminController.updateCompanyDetails()`
- **Source:** `superadmin/superadmin.controller.ts:615`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCompanyConfig(headerId, companyConfig)`

**Body / payload**

- Object binding: `CompanyDto` from `@Body() companyConfig: CompanyDto` — source: `superadmin/dto/company.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 235. `POST /superadmin/createadmin`

- **Handler:** `SuperadminController.createAdmin()`
- **Source:** `superadmin/superadmin.controller.ts:132`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createAdmin(Admindto, headerId)`

**Body / payload**

- Object binding: `CreateAdminDto` from `@Body() Admindto: CreateAdminDto` — source: `superadmin/dto/admin.dto.ts:11`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @Transform(({ value }) => String(value).trim().toLowerCase()) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `username` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `password` | `string` | Yes | @IsString(), @MinLength(6) |
| `companyName` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `address` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `country` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `state` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `city` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `credits` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 236. `GET /superadmin/creditlogs/:id`

- **Handler:** `SuperadminController.getCreditLogs()`
- **Source:** `superadmin/superadmin.controller.ts:179`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCreditLogs(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 237. `GET /superadmin/customcommands`

- **Handler:** `SuperadminController.getCustomCommands()`
- **Source:** `superadmin/superadmin.controller.ts:328`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getCustomCommands(query)`

**Query params**

- Object binding: `CustomCommandsQueryDto` from `@Query() query: CustomCommandsQueryDto` — source: `superadmin/dto/custom-commands-query.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `deviceTypeId` | `string` | No | @IsOptional(), @IsString() |
| `commandTypeId` | `string` | No | @IsOptional(), @IsString() |
| `activeOnly` | `string` | No | @IsOptional(), @IsString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 238. `POST /superadmin/customcommands`

- **Handler:** `SuperadminController.createCustomCommand()`
- **Source:** `superadmin/superadmin.controller.ts:332`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createCustomCommand(customCommandDto)`

**Body / payload**

- Object binding: `CustomCommandDto` from `@Body() customCommandDto: CustomCommandDto` — source: `superadmin/dto/customcommand.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `commandTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 239. `DELETE /superadmin/customcommands/:id`

- **Handler:** `SuperadminController.deleteCustomCommand()`
- **Source:** `superadmin/superadmin.controller.ts:340`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteCustomCommand(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 240. `PATCH /superadmin/customcommands/:id`

- **Handler:** `SuperadminController.updateCustomCommand()`
- **Source:** `superadmin/superadmin.controller.ts:336`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCustomCommand(id, customCommandDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `CustomCommandDto` from `@Body() customCommandDto: CustomCommandDto` — source: `superadmin/dto/customcommand.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `commandTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 241. `GET /superadmin/dashboard/activitylogs`

- **Handler:** `SuperadminController.getDashboardActivityLogs()`
- **Source:** `superadmin/superadmin.controller.ts:650`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDashboardActivityLogs(headerId, dto)`

**Query params**

- Object binding: `DashboardActivityLogsDto` from `@Query() dto: DashboardActivityLogsDto` — source: `superadmin/dto/dashboard-activity-logs.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `actorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 242. `GET /superadmin/dashboard/adoptiongraph`

- **Handler:** `SuperadminController.getAdoptionGraph()`
- **Source:** `superadmin/superadmin.controller.ts:659`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdoptionGraphData()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 243. `GET /superadmin/dashboard/overview`

- **Handler:** `SuperadminController.getDashboardOverview()`
- **Source:** `superadmin/superadmin.controller.ts:627`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDashboardOverview(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 244. `GET /superadmin/dashboard/recentusers`

- **Handler:** `SuperadminController.getRecentUsers()`
- **Source:** `superadmin/superadmin.controller.ts:639`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getRecentUsers()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 245. `GET /superadmin/dashboard/recentvehicles`

- **Handler:** `SuperadminController.getRecentVehicles()`
- **Source:** `superadmin/superadmin.controller.ts:633`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getRecentVehicles()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 246. `GET /superadmin/dashboard/totalcounts`

- **Handler:** `SuperadminController.getTotalCounts()`
- **Source:** `superadmin/superadmin.controller.ts:644`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getTotalCounts()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 247. `DELETE /superadmin/deleteadmin/:id`

- **Handler:** `SuperadminController.deleteAdmin()`
- **Source:** `superadmin/superadmin.controller.ts:184`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteAdmin(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 248. `POST /superadmin/devices/:imei/send-command`

- **Handler:** `SuperadminController.sendDeviceCommand()`
- **Source:** `superadmin/superadmin.controller.ts:1009`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.sendDeviceCommandByImei(headerId, imei, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Body / payload**

- Object binding: `SendDeviceCommandDto` from `@Body() dto: SendDeviceCommandDto` — source: `superadmin/dto/send-device-command.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 249. `GET /superadmin/devicetypes`

- **Handler:** `SuperadminController.getDeviceTypes()`
- **Source:** `superadmin/superadmin.controller.ts:311`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getDeviceTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 250. `POST /superadmin/devicetypes`

- **Handler:** `SuperadminController.createDeviceType()`
- **Source:** `superadmin/superadmin.controller.ts:315`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createDeviceType(deviceTypeDto)`

**Body / payload**

- Object binding: `DeviceTypeDto` from `@Body() deviceTypeDto: DeviceTypeDto` — source: `superadmin/dto/devicetype.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `port` | `number` | Yes | @IsInt(), @Min(1), @Max(65535) |
| `manufacturer` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `protocol` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `firmwareVersion` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 251. `DELETE /superadmin/devicetypes/:id`

- **Handler:** `SuperadminController.deleteDeviceType()`
- **Source:** `superadmin/superadmin.controller.ts:323`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteDeviceType(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 252. `PATCH /superadmin/devicetypes/:id`

- **Handler:** `SuperadminController.updateDeviceType()`
- **Source:** `superadmin/superadmin.controller.ts:319`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateDeviceType(id, deviceTypeDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `DeviceTypeDto` from `@Body() deviceTypeDto: DeviceTypeDto` — source: `superadmin/dto/devicetype.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `port` | `number` | Yes | @IsInt(), @Min(1), @Max(65535) |
| `manufacturer` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `protocol` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `firmwareVersion` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 253. `GET /superadmin/documents/:adminId`

- **Handler:** `SuperadminController.getDocuments()`
- **Source:** `superadmin/superadmin.controller.ts:458`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDocuments(adminId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `adminId` | `number` | Yes | `@Param('adminId', ParseIntPipe) adminId: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 254. `GET /superadmin/documenttypes`

- **Handler:** `SuperadminController.getDocumentTypes()`
- **Source:** `superadmin/superadmin.controller.ts:362`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getDocumentTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 255. `POST /superadmin/documenttypes`

- **Handler:** `SuperadminController.createDocumentType()`
- **Source:** `superadmin/superadmin.controller.ts:366`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createDocumentType(documentTypeDto)`

**Body / payload**

- Object binding: `DocumentTypeDto` from `@Body() documentTypeDto: DocumentTypeDto` — source: `superadmin/dto/documenttype.dto.ts:10`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `docFor` | `DocForDto` | Yes | @IsEnum(DocForDto, { message: "docFor must be one of: USER, DRIVER, VEHICLE" }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 256. `DELETE /superadmin/documenttypes/:id`

- **Handler:** `SuperadminController.deleteDocumentType()`
- **Source:** `superadmin/superadmin.controller.ts:374`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteDocumentType(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 257. `PATCH /superadmin/documenttypes/:id`

- **Handler:** `SuperadminController.updateDocumentType()`
- **Source:** `superadmin/superadmin.controller.ts:370`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateDocumentType(id, documentTypeDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `DocumentTypeDto` from `@Body() documentTypeDto: DocumentTypeDto` — source: `superadmin/dto/documenttype.dto.ts:10`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `docFor` | `DocForDto` | Yes | @IsEnum(DocForDto, { message: "docFor must be one of: USER, DRIVER, VEHICLE" }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 258. `GET /superadmin/domainlist`

- **Handler:** `SuperadminController.getDomainList()`
- **Source:** `superadmin/superadmin.controller.ts:681`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDomainList()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 259. `GET /superadmin/emailtemplates`

- **Handler:** `SuperadminController.getEmailTemplates()`
- **Source:** `superadmin/superadmin.controller.ts:396`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getEmailTemplates()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 260. `GET /superadmin/emailtemplates/:id`

- **Handler:** `SuperadminController.getEmailTemplateById()`
- **Source:** `superadmin/superadmin.controller.ts:400`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getEmailTemplateById(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 261. `PATCH /superadmin/emailtemplates/:id`

- **Handler:** `SuperadminController.updateEmailTemplate()`
- **Source:** `superadmin/superadmin.controller.ts:404`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateEmailTemplate(id, emailTemplateDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `EmailTemplateDto` from `@Body() emailTemplateDto: EmailTemplateDto` — source: `superadmin/dto/emailtemplate.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `emailSubject` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 120) |
| `message` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10000) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 262. `POST /superadmin/ftkey/deactivate`

- **Handler:** `SuperadminController.deactivateFtkey()`
- **Source:** `superadmin/superadmin.controller.ts:705`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deactivateFtkey()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 263. `POST /superadmin/ftkey/recheck`

- **Handler:** `SuperadminController.recheckFtkey()`
- **Source:** `superadmin/superadmin.controller.ts:700`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.recheckFtkey()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 264. `GET /superadmin/ftkey/status`

- **Handler:** `SuperadminController.getFtkeyStatus()`
- **Source:** `superadmin/superadmin.controller.ts:690`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getFtkeyStatus()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 265. `POST /superadmin/ftkey/validate`

- **Handler:** `SuperadminController.validateFtkey()`
- **Source:** `superadmin/superadmin.controller.ts:695`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.validateAndSaveFtkey(dto.ftkey)`

**Body / payload**

- Object binding: `ValidateFtkeyDto` from `@Body() dto: ValidateFtkeyDto` — source: `superadmin/dto/ftkey.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `ftkey` | `string` | Yes | @IsString(), @IsNotEmpty() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 266. `GET /superadmin/geofences`

- **Handler:** `SuperadminController.getAllGeofences()`
- **Source:** `superadmin/superadmin.controller.ts:783`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllGeofences()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 267. `GET /superadmin/integrations`

- **Handler:** `SuperadminController.listIntegrations()`
- **Source:** `superadmin/superadmin.controller.ts:855`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.listThirdPartyIntegrations(headerId, query)`

**Query params**

- Object binding: `ListThirdPartyIntegrationsQueryDto` from `@Query() query: ListThirdPartyIntegrationsQueryDto` — source: `superadmin/dto/third-party-integrations.dto.ts:25`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `scope` | `IntegrationScope` | No | @IsOptional(), @IsEnum(IntegrationScope) |
| `adminId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @ValidateIf((o) => o.scope === 'ADMIN') |
| `category` | `IntegrationCategory` | No | @IsOptional(), @IsEnum(IntegrationCategory) |
| `provider` | `IntegrationProvider` | No | @IsOptional(), @IsEnum(IntegrationProvider) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 268. `POST /superadmin/integrations`

- **Handler:** `SuperadminController.upsertIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:863`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.upsertThirdPartyIntegration(headerId, dto)`

**Body / payload**

- Object binding: `UpsertThirdPartyIntegrationDto` from `@Body() dto: UpsertThirdPartyIntegrationDto` — source: `superadmin/dto/third-party-integrations.dto.ts:51`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `scope` | `IntegrationScope` | Yes | @IsEnum(IntegrationScope) |
| `adminId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @ValidateIf((o) => o.scope === 'ADMIN') |
| `category` | `IntegrationCategory` | Yes | @IsEnum(IntegrationCategory) |
| `provider` | `IntegrationProvider` | Yes | @IsEnum(IntegrationProvider) |
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => String(value).trim()) |
| `status` | `IntegrationStatus` | No | @IsOptional(), @IsEnum(IntegrationStatus) |
| `isDefault` | `boolean` | No | @IsOptional(), @Transform(({ value }) => typeof value === 'string' ? value.toLowerCase() === 'true' : Boolean(value), ), @IsBoolean() |
| `priority` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(0) |
| `publicConfig` | `any` | No | @IsOptional() |
| `secretJson` | `any` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 269. `DELETE /superadmin/integrations/:id`

- **Handler:** `SuperadminController.deleteIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:958`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteThirdPartyIntegration(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 270. `PATCH /superadmin/integrations/:id`

- **Handler:** `SuperadminController.updateIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:872`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateThirdPartyIntegration(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateThirdPartyIntegrationDto` from `@Body() dto: UpdateThirdPartyIntegrationDto` — source: `superadmin/dto/third-party-integrations.dto.ts:107`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `status` | `IntegrationStatus` | No | @IsOptional(), @IsEnum(IntegrationStatus) |
| `isDefault` | `boolean` | No | @IsOptional(), @Transform(({ value }) => typeof value === 'string' ? value.toLowerCase() === 'true' : Boolean(value), ), @IsBoolean() |
| `priority` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(0) |
| `publicConfig` | `any` | No | @IsOptional() |
| `lastError` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 271. `GET /superadmin/integrations/:id/openrouter/models`

- **Handler:** `SuperadminController.getOpenRouterModels()`
- **Source:** `superadmin/superadmin.controller.ts:920`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getOpenRouterModels(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 272. `POST /superadmin/integrations/:id/rotate-secret`

- **Handler:** `SuperadminController.rotateIntegrationSecret()`
- **Source:** `superadmin/superadmin.controller.ts:881`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.rotateThirdPartyIntegrationSecret(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `RotateThirdPartyIntegrationSecretDto` from `@Body() dto: RotateThirdPartyIntegrationSecretDto` — source: `superadmin/dto/third-party-integrations.dto.ts:138`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `secretJson` | `any` | Yes | @IsNotEmpty({ message: 'secretJson must not be empty' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 273. `POST /superadmin/integrations/:id/test-fcm`

- **Handler:** `SuperadminController.testFcmIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:891`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testFcmIntegration(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `TestFcmIntegrationDto` from `@Body() dto: TestFcmIntegrationDto` — source: `superadmin/dto/third-party-integrations.dto.ts:151`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'token must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `data` | `any` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 274. `POST /superadmin/integrations/:id/test-openrouter`

- **Handler:** `SuperadminController.testOpenRouterIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:928`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testOpenRouterIntegration(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `TestOpenRouterIntegrationDto` from `@Body() dto: TestOpenRouterIntegrationDto` — source: `superadmin/dto/third-party-integrations.dto.ts:234`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `model` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `prompt` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 275. `POST /superadmin/integrations/:id/test-whatsapp`

- **Handler:** `SuperadminController.testWhatsAppIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:910`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testWhatsAppIntegration(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `TestWhatsAppIntegrationDto` from `@Body() dto: TestWhatsAppIntegrationDto` — source: `superadmin/dto/third-party-integrations.dto.ts:197`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `phoneNumber` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'phoneNumber must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `mode` | `'template' \| 'custom'` | No | @IsOptional(), @IsString(), @Transform(({ value }) => String(value ?? 'template').trim().toLowerCase()) |
| `templateName` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `languageCode` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `message` | `string` | No | @ValidateIf((o) => o.mode === 'custom'), @IsString(), @IsNotEmpty({ message: 'message must not be empty when mode is custom' }), @Transform(({ value }) => (value ? String(value).trim() : value)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 276. `POST /superadmin/integrations/:id/validate-geocoding`

- **Handler:** `SuperadminController.validateGeocodingIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:948`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.validateGeocodingIntegration(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `ValidateGeocodingIntegrationDto` from `@Body() dto: ValidateGeocodingIntegrationDto` — source: `superadmin/dto/third-party-integrations.dto.ts:264`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `lat` | `number` | Yes | @Type(() => Number), @IsNumber(), @Min(-90), @Max(90) |
| `lng` | `number` | Yes | @Type(() => Number), @IsNumber(), @Min(-180), @Max(180) |
| `language` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `zoom` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(20) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 277. `POST /superadmin/integrations/:id/validate-google-sso`

- **Handler:** `SuperadminController.validateGoogleSsoIntegration()`
- **Source:** `superadmin/superadmin.controller.ts:938`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.validateGoogleSsoIntegration(headerId, id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `ValidateGoogleSsoDto` from `@Body() dto: ValidateGoogleSsoDto` — source: `superadmin/dto/third-party-integrations.dto.ts:252`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `redirectUri` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 278. `GET /superadmin/localization`

- **Handler:** `SuperadminController.getLocalizationData()`
- **Source:** `superadmin/superadmin.controller.ts:569`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getLocalizationData(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 279. `PATCH /superadmin/localization`

- **Handler:** `SuperadminController.updateLocalizationData()`
- **Source:** `superadmin/superadmin.controller.ts:574`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateadminSettings(headerId, localizationDto)`

**Body / payload**

- Object binding: `UpdateSettingsStateDto` from `@Body() localizationDto: UpdateSettingsStateDto` — source: `superadmin/dto/usersetting.dto.ts:64`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 280. `GET /superadmin/map-events`

- **Handler:** `SuperadminController.getMapEvents()`
- **Source:** `superadmin/superadmin.controller.ts:981`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getMapEvents(query)`

**Query params**

- Object binding: `MapEventsQueryDto` from `@Query() query: MapEventsQueryDto` — source: `superadmin/dto/map-events.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 281. `GET /superadmin/map-telemetry`

- **Handler:** `SuperadminController.getMapTelemetry()`
- **Source:** `superadmin/superadmin.controller.ts:761`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getMapTelemetry()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 282. `GET /superadmin/notifications`

- **Handler:** `SuperadminController.getNotifications()`
- **Source:** `superadmin/superadmin.controller.ts:1060`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getNotifications(headerId, query)`

**Query params**

- Object binding: `NotificationsQueryDto` from `@Query() query: NotificationsQueryDto` — source: `superadmin/dto/notifications.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsNumberString() |
| `unreadOnly` | `string` | No | @IsOptional(), @IsBooleanString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 283. `PATCH /superadmin/notifications/:id/read`

- **Handler:** `SuperadminController.markNotificationRead()`
- **Source:** `superadmin/superadmin.controller.ts:1075`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.markNotificationRead(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 284. `PATCH /superadmin/notifications/read-all`

- **Handler:** `SuperadminController.markAllNotificationsRead()`
- **Source:** `superadmin/superadmin.controller.ts:1068`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.markAllNotificationsRead(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 285. `POST /superadmin/notifications/test-fcm-me`

- **Handler:** `SuperadminController.testFcmToMe()`
- **Source:** `superadmin/superadmin.controller.ts:901`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testFcmToMe(headerId, dto)`

**Body / payload**

- Object binding: `TestFcmToMeDto` from `@Body() dto: TestFcmToMeDto` — source: `superadmin/dto/third-party-integrations.dto.ts:179`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 286. `GET /superadmin/openrouter/models`

- **Handler:** `SuperadminController.listOpenRouterModels()`
- **Source:** `superadmin/superadmin.controller.ts:970`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.listOpenRouterModels(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 287. `GET /superadmin/pois`

- **Handler:** `SuperadminController.getAllPois()`
- **Source:** `superadmin/superadmin.controller.ts:788`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllPois()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 288. `PATCH /superadmin/policy`

- **Handler:** `SuperadminController.updatePolicy()`
- **Source:** `superadmin/superadmin.controller.ts:609`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updatePolicy(PolicyDto)`

**Body / payload**

- Object binding: `PolicyDto` from `@Body() PolicyDto: PolicyDto` — source: `superadmin/dto/policy.dto.ts:11`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `PolicyType` | `PolicyTypeDto` | Yes | @IsEnum(PolicyTypeDto, { message: "type must be one of: PRIVACY_POLICY, SERVICE_TERMS, COOKIES, REFUND" }) |
| `PolicyText` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(200000) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 289. `POST /superadmin/policy`

- **Handler:** `SuperadminController.createPolicy()`
- **Source:** `superadmin/superadmin.controller.ts:604`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getPolicy(Policy_type)`

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `PolicyType` | `string` | Yes | `@Body('PolicyType') Policy_type: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 290. `GET /superadmin/profile`

- **Handler:** `SuperadminController.getProfile()`
- **Source:** `superadmin/superadmin.controller.ts:473`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<string>`
- **Return expression/source:** `this.superadminService.getProfile()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 291. `PATCH /superadmin/profile`

- **Handler:** `SuperadminController.updateProfile()`
- **Source:** `superadmin/superadmin.controller.ts:478`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateProfile(profileDto)`

**Body / payload**

- Object binding: `ProfileDto` from `@Body() profileDto: ProfileDto` — source: `superadmin/dto/profile.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 292. `GET /superadmin/profile/email-subscription`

- **Handler:** `SuperadminController.getEmailSubscription()`
- **Source:** `superadmin/superadmin.controller.ts:511`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, data: { isSubscribed: subscribed, brandOwnerId, scope } }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 293. `POST /superadmin/profile/email-subscription/subscribe`

- **Handler:** `SuperadminController.subscribeEmail()`
- **Source:** `superadmin/superadmin.controller.ts:522`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Subscribed', data: { isSubscribed: true } }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 294. `POST /superadmin/profile/verify/email/confirm`

- **Handler:** `SuperadminController.verifyEmailOtp()`
- **Source:** `superadmin/superadmin.controller.ts:492`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyEmailOtp(headerId, dto.otp)`

**Body / payload**

- Object binding: `VerifyOtpDto` from `@Body() dto: VerifyOtpDto` — source: `verification/dto/verify-otp.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 295. `POST /superadmin/profile/verify/email/request`

- **Handler:** `SuperadminController.requestEmailOtp()`
- **Source:** `superadmin/superadmin.controller.ts:487`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestEmailOtp(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 296. `POST /superadmin/profile/verify/whatsapp/confirm`

- **Handler:** `SuperadminController.verifyWhatsAppOtp()`
- **Source:** `superadmin/superadmin.controller.ts:502`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.commsVerification.verifyWhatsAppOtpForSuperadmin(headerId, dto.otp)`

**Body / payload**

- Object binding: `VerifyOtpDto` from `@Body() dto: VerifyOtpDto` — source: `verification/dto/verify-otp.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 297. `POST /superadmin/profile/verify/whatsapp/request`

- **Handler:** `SuperadminController.requestWhatsAppOtp()`
- **Source:** `superadmin/superadmin.controller.ts:497`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.commsVerification.requestWhatsAppOtpForSuperadmin(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 298. `GET /superadmin/routes`

- **Handler:** `SuperadminController.getAllRoutes()`
- **Source:** `superadmin/superadmin.controller.ts:793`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllRoutes(includeGeodata === 'true')`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `includeGeodata` | `string` | Yes | `@Query('includeGeodata') includeGeodata?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## ServerController

### 299. `POST /superadmin/server/actions`

- **Handler:** `ServerController.createServerActionJob()`
- **Source:** `superadmin/server/server.controller.ts:31`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Server action job created', data: created, }`

**Body / payload**

- Object binding: `ServerActionDto` from `@Body() dto: ServerActionDto` — source: `superadmin/server/dto/server-action.dto.ts:79`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `componentId` | `ServerActionComponentId` | Yes | @IsIn(SERVER_COMPONENT_IDS) |
| `action` | `ServerActionType` | Yes | @IsIn(SERVER_ACTIONS), @Validate(ServerActionRulesConstraint) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 300. `GET /superadmin/server/jobs/:id`

- **Handler:** `ServerController.getServerActionJob()`
- **Source:** `superadmin/server/server.controller.ts:44`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `{ action: false, message: 'Job not found' }` OR `{ action: false, message: latestLog?.message \|\| 'Job failed', data: job, }` OR `{ action: true, message: 'Job fetched', data: job, }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 301. `GET /superadmin/server/jobs/:id/stream`

- **Handler:** `ServerController.streamServerActionJob()`
- **Source:** `superadmin/server/server.controller.ts:67`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 302. `GET /superadmin/server/overview`

- **Handler:** `ServerController.getOverview()`
- **Source:** `superadmin/server/server.controller.ts:21`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'Server overview', data, }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SuperadminController

### 303. `GET /superadmin/settings/:id`

- **Handler:** `SuperadminController.getSettings()`
- **Source:** `superadmin/superadmin.controller.ts:463`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getadminSettings(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 304. `PATCH /superadmin/settings/:id`

- **Handler:** `SuperadminController.updateSettings()`
- **Source:** `superadmin/superadmin.controller.ts:468`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateadminSettings(id, settingsDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateSettingsStateDto` from `@Body() settingsDto: UpdateSettingsStateDto` — source: `superadmin/dto/usersetting.dto.ts:64`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 305. `GET /superadmin/settings/data-retention/preview`

- **Handler:** `SuperadminController.previewDataRetention()`
- **Source:** `superadmin/superadmin.controller.ts:594`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.previewDataRetention()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 306. `POST /superadmin/settings/data-retention/run`

- **Handler:** `SuperadminController.runDataRetention()`
- **Source:** `superadmin/superadmin.controller.ts:599`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.runDataRetention(body?.dryRun === true)`

**Body / payload**

- Object binding: `{ dryRun?: boolean }` from `@Body() body?: { dryRun?: boolean }`

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 307. `GET /superadmin/simproviders`

- **Handler:** `SuperadminController.getSimProviders()`
- **Source:** `superadmin/superadmin.controller.ts:379`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getSimProviders()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 308. `POST /superadmin/simproviders`

- **Handler:** `SuperadminController.createSimProvider()`
- **Source:** `superadmin/superadmin.controller.ts:383`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createSimProvider(simProviderDto)`

**Body / payload**

- Object binding: `SimProviderDto` from `@Body() simProviderDto: SimProviderDto` — source: `superadmin/dto/simprociders.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `countryCode` | `string` | Yes | @IsString(), @IsNotEmpty(), @Matches(/^[A-Z]{2}$/, { message: "countryCode must be 2 uppercase letters (e.g. IN, NZ)" }) |
| `apnName` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnUser` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnPassword` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 309. `DELETE /superadmin/simproviders/:id`

- **Handler:** `SuperadminController.deleteSimProvider()`
- **Source:** `superadmin/superadmin.controller.ts:391`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteSimProvider(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 310. `PATCH /superadmin/simproviders/:id`

- **Handler:** `SuperadminController.updateSimProvider()`
- **Source:** `superadmin/superadmin.controller.ts:387`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSimProvider(id, simProviderDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `SimProviderDto` from `@Body() simProviderDto: SimProviderDto` — source: `superadmin/dto/simprociders.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `countryCode` | `string` | Yes | @IsString(), @IsNotEmpty(), @Matches(/^[A-Z]{2}$/, { message: "countryCode must be 2 uppercase letters (e.g. IN, NZ)" }) |
| `apnName` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnUser` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnPassword` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 311. `GET /superadmin/smtpconfig/:id`

- **Handler:** `SuperadminController.getSmtpConfig()`
- **Source:** `superadmin/superadmin.controller.ts:226`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getSmtpConfig(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 312. `PATCH /superadmin/smtpconfig/:id`

- **Handler:** `SuperadminController.updateSmtpConfig()`
- **Source:** `superadmin/superadmin.controller.ts:231`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSmtpConfig(id, smtpConfig)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `SmtpSettingDto` from `@Body() smtpConfig: SmtpSettingDto` — source: `superadmin/dto/smtp.dto.ts:19`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 313. `GET /superadmin/smtpsettings`

- **Handler:** `SuperadminController.getSmtpSettings()`
- **Source:** `superadmin/superadmin.controller.ts:551`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getSmtpSettings(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 314. `PATCH /superadmin/smtpsettings`

- **Handler:** `SuperadminController.updateSmtpSettings()`
- **Source:** `superadmin/superadmin.controller.ts:556`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSmtpConfig(headerId, smtpSettingsDto)`

**Body / payload**

- Object binding: `SmtpSettingDto` from `@Body() smtpSettingsDto: SmtpSettingDto` — source: `superadmin/dto/smtp.dto.ts:19`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 315. `GET /superadmin/softwareconfig`

- **Handler:** `SuperadminController.getConfig()`
- **Source:** `superadmin/superadmin.controller.ts:582`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.GetConfig(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 316. `PATCH /superadmin/softwareconfig`

- **Handler:** `SuperadminController.updateConfig()`
- **Source:** `superadmin/superadmin.controller.ts:587`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.updateConfig(headerId, softwareConfigDto)`

**Body / payload**

- Object binding: `SoftwareConfigDto` from `@Body() softwareConfigDto: SoftwareConfigDto` — source: `superadmin/dto/softwareconfig.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `geocodingPrecision` | `GeocodingPrecisionDto` | No | @IsOptional(), @IsEnum(GeocodingPrecisionDto) |
| `backupDays` | `number` | No | @IsOptional(), @IsInt(), @Min(0) |
| `allowDemoLogin` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `allowSignup` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `signupCredits` | `number` | No | @IsOptional(), @IsInt(), @Min(0), @Max(2_000_000_000, { message: 'signupCredits must not exceed 2,000,000,000' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SslController

### 317. `POST /superadmin/ssl/install`

- **Handler:** `SslController.install()`
- **Source:** `ssl/ssl.controller.ts:36`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: `SSL ${dto.action} job started`, data: { jobId: job.id, domain: job.domain, action: job.action }, }`

**Body / payload**

- Object binding: `SslInstallDto` from `@Body() dto: SslInstallDto` — source: `ssl/dto/ssl.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `domain` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `action` | `SslAction` | Yes | @IsEnum(SslAction) |
| `email` | `string` | No | @IsOptional(), @IsString() |
| `backendProxyPass` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 318. `GET /superadmin/ssl/jobs/:jobId`

- **Handler:** `SslController.getJob()`
- **Source:** `ssl/ssl.controller.ts:51`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `{ action: false, message: 'Job not found', data: null }` OR `{ action: true, message: 'Job state retrieved', data: job }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `jobId` | `string` | Yes | `@Param('jobId') jobId: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SslStreamController

### 319. `GET /superadmin/ssl/jobs/:jobId/stream`

- **Handler:** `SslStreamController.streamJob()`
- **Source:** `ssl/ssl.controller.ts:74`
- **Auth:** Public / unspecified
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `jobId` | `string` | Yes | `@Param('jobId') jobId: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `token` | `string` | Yes | `@Query('token') token: string` |

**Implementation notes**

- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SslController

### 320. `GET /superadmin/ssl/status`

- **Handler:** `SslController.getStatus()`
- **Source:** `ssl/ssl.controller.ts:30`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `{ action: true, message: 'SSL status retrieved', data }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SuperadminController

### 321. `GET /superadmin/support/tickets`

- **Handler:** `SuperadminController.listSupportTickets()`
- **Source:** `superadmin/superadmin.controller.ts:85`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.listSupportTickets(headerId, { status, search, priority, category })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `search` | `string` | Yes | `@Query('search') search?: string` |
| `priority` | `string` | Yes | `@Query('priority') priority?: string` |
| `category` | `string` | Yes | `@Query('category') category?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 322. `POST /superadmin/support/tickets`

- **Handler:** `SuperadminController.createSupportTicketOnBehalfOfAdmin()`
- **Source:** `superadmin/superadmin.controller.ts:96`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createSupportTicketOnBehalfOfAdmin(headerId, req, body)`

**Body / payload**

- Object binding: `any` from `@Body() body: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 323. `GET /superadmin/support/tickets/:id`

- **Handler:** `SuperadminController.getSupportTicketById()`
- **Source:** `superadmin/superadmin.controller.ts:105`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getSupportTicketById(ticketId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 324. `POST /superadmin/support/tickets/:id/messages`

- **Handler:** `SuperadminController.replySupportTicket()`
- **Source:** `superadmin/superadmin.controller.ts:113`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.replySupportTicket(ticketId, headerId, req, body)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Body / payload**

- Object binding: `ReplySupportTicketDto` from `@Body() body: ReplySupportTicketDto` — source: `superadmin/dto/reply-support-ticket.dto.ts:6`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `message` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5000), @Matches(MEANINGFUL_TEXT, { message: 'Message must contain at least one letter or number' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 325. `PATCH /superadmin/support/tickets/:id/status`

- **Handler:** `SuperadminController.updateSupportTicketStatus()`
- **Source:** `superadmin/superadmin.controller.ts:123`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSupportTicketStatus(ticketId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Body / payload**

- Object binding: `UpdateSupportTicketStatusDto` from `@Body() dto: UpdateSupportTicketStatusDto` — source: `superadmin/dto/update-support-ticket-status.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 326. `GET /superadmin/systemvariables`

- **Handler:** `SuperadminController.getSystemVariables()`
- **Source:** `superadmin/superadmin.controller.ts:345`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getSystemVariables()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 327. `POST /superadmin/systemvariables`

- **Handler:** `SuperadminController.createSystemVariable()`
- **Source:** `superadmin/superadmin.controller.ts:349`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createSystemVariable(systemVariableDto)`

**Body / payload**

- Object binding: `SystemVariableDto` from `@Body() systemVariableDto: SystemVariableDto` — source: `superadmin/dto/systemvariable.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80), @Matches(/^[A-Za-z][A-Za-z0-9_]*$/, { message: "name must start with a letter and contain only letters, numbers, and underscore", }) |
| `initialValue` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 328. `DELETE /superadmin/systemvariables/:id`

- **Handler:** `SuperadminController.deleteSystemVariable()`
- **Source:** `superadmin/superadmin.controller.ts:357`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteSystemVariable(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 329. `PATCH /superadmin/systemvariables/:id`

- **Handler:** `SuperadminController.updateSystemVariable()`
- **Source:** `superadmin/superadmin.controller.ts:353`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSystemVariable(id, systemVariableDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `SystemVariableDto` from `@Body() systemVariableDto: SystemVariableDto` — source: `superadmin/dto/systemvariable.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80), @Matches(/^[A-Za-z][A-Za-z0-9_]*$/, { message: "name must start with a letter and contain only letters, numbers, and underscore", }) |
| `initialValue` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 330. `GET /superadmin/telemetry`

- **Handler:** `SuperadminController.getTelemetrySnapshot()`
- **Source:** `superadmin/superadmin.controller.ts:771`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getTelemetrySnapshot(headerId, imeis)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imeis` | `string` | Yes | `@Query('imeis') imeis?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 331. `POST /superadmin/testsmtp`

- **Handler:** `SuperadminController.testSmtpSettings()`
- **Source:** `superadmin/superadmin.controller.ts:564`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testSmtpSettings(headerId, email)`

**Body / payload**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `email` | `string` | Yes | `@Body('email') email: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 332. `GET /superadmin/topbar-search`

- **Handler:** `SuperadminController.searchTopbar()`
- **Source:** `superadmin/superadmin.controller.ts:73`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.topbarSearch.searchForSuperadmin(headerId, dto)`

**Query params**

- Object binding: `TopbarSearchQueryDto` from `@Query() dto: TopbarSearchQueryDto` — source: `topbar-search/dto/topbar-search.dto.ts:13`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `q` | `string` | Yes | @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @IsString(), @IsNotEmpty(), @MinLength(2), @MaxLength(80) |
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(30) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 333. `GET /superadmin/transactions`

- **Handler:** `SuperadminController.listTransactions()`
- **Source:** `superadmin/superadmin.controller.ts:189`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `adminId` | `string` | Yes | `@Query('adminId') adminId?: string` |
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 334. `GET /superadmin/transactions/analytics`

- **Handler:** `SuperadminController.transactionsAnalytics()`
- **Source:** `superadmin/superadmin.controller.ts:204`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `adminId` | `string` | Yes | `@Query('adminId') adminId?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `month` | `string` | Yes | `@Query('month') month?: string` |
| `year` | `string` | Yes | `@Query('year') year?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 335. `POST /superadmin/transactions/manual`

- **Handler:** `SuperadminController.recordManualTransaction()`
- **Source:** `superadmin/superadmin.controller.ts:217`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Payment recorded', data }`

**Body / payload**

- Object binding: `RecordManualTransactionDto` from `@Body() dto: RecordManualTransactionDto` — source: `superadmin/dto/record-manual-transaction.dto.ts:5`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `adminId` | `number` | Yes | @Type(() => Number), @IsInt() |
| `amount` | `string` | Yes | @IsString(), @Matches(/^\d+(\.\d{1,2})?$/), @MaxLength(12, { message: 'Amount must not exceed 9999999999.99' }) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 336. `POST /superadmin/updateadmin/:id`

- **Handler:** `SuperadminController.updateAdmin()`
- **Source:** `superadmin/superadmin.controller.ts:168`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateAdmin(id, Adminupdatedto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateAdminDto` from `@Body() Adminupdatedto: UpdateAdminDto` — source: `superadmin/dto/updateadmin.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 337. `PATCH /superadmin/updatepassword`

- **Handler:** `SuperadminController.updatePassword()`
- **Source:** `superadmin/superadmin.controller.ts:620`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updatePassword(headerId, passwordDto)`

**Body / payload**

- Object binding: `UpdatePasswordDto` from `@Body() passwordDto: UpdatePasswordDto` — source: `superadmin/dto/updatepassword.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `currentPassword` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `newPassword` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(6), @MaxLength(72) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 338. `POST /superadmin/upload/:id`

- **Handler:** `SuperadminController.upload()`
- **Source:** `superadmin/superadmin.controller.ts:246`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `await this.superadminService.handleUpload(req, id)` OR `{ action: false, message: error.message \|\| 'Upload failed', data: null }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 339. `POST /superadmin/uploaddoc`

- **Handler:** `SuperadminController.uploadDocument()`
- **Source:** `superadmin/superadmin.controller.ts:421`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.superadminService.uploadDocumentMultipart(req, headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 340. `DELETE /superadmin/uploaddoc/:id`

- **Handler:** `SuperadminController.deleteDocument()`
- **Source:** `superadmin/superadmin.controller.ts:449`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.superadminService.deleteDocument(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 341. `PATCH /superadmin/uploaddoc/:id`

- **Handler:** `SuperadminController.uploadDocumentUpdate()`
- **Source:** `superadmin/superadmin.controller.ts:432`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.superadminService.updateDocumentMultipart(req, id)` OR `await this.superadminService.updateDocument(id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateDocDto` from `@Body() dto: UpdateDocDto` — source: `superadmin/dto/updatedoc.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @MaxLength(255) |
| `docTypeId` | `number` | No | @IsOptional(), @IsInt(), @Min(1) |
| `fileName` | `string` | No | @IsOptional(), @IsString(), @MaxLength(255) |
| `description` | `string` | No | @IsOptional(), @IsString(), @MaxLength(1000) |
| `tags` | `string` | No | @IsOptional(), @IsString(), @MaxLength(2000) |
| `associateType` | `AssociateTypeDto` | No | @IsOptional(), @IsEnum(AssociateTypeDto, { message: 'associateType must be one of: USER, VEHICLE, DRIVER' }) |
| `associateId` | `number` | No | @IsOptional(), @IsInt(), @Min(1) |
| `expiryAt` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `isVisible` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isVisibleDriver` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 342. `GET /superadmin/vehicles`

- **Handler:** `SuperadminController.getAllVehicles()`
- **Source:** `superadmin/superadmin.controller.ts:284`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllVehicles(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 343. `GET /superadmin/vehicles/:id`

- **Handler:** `SuperadminController.getVehicleById()`
- **Source:** `superadmin/superadmin.controller.ts:289`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleById(id, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 344. `GET /superadmin/vehicles/by-imei/:imei/commands`

- **Handler:** `SuperadminController.getCommandHistoryByImei()`
- **Source:** `superadmin/superadmin.controller.ts:1027`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCommandHistoryByImei(imei, { limit, cursorId })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `cursorId` | `string` | Yes | `@Query('cursorId') cursorId?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 345. `GET /superadmin/vehicles/by-imei/:imei/details`

- **Handler:** `SuperadminController.getVehicleDetailsByImei()`
- **Source:** `superadmin/superadmin.controller.ts:733`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleDetailsByImei(imei, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 346. `GET /superadmin/vehicles/by-imei/:imei/events`

- **Handler:** `SuperadminController.getVehicleEventsByImei()`
- **Source:** `superadmin/superadmin.controller.ts:988`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleEventsByImei(imei, query)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

- Object binding: `MapEventsQueryDto` from `@Query() query: MapEventsQueryDto` — source: `superadmin/dto/map-events.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 347. `GET /superadmin/vehicles/by-imei/:imei/history`

- **Handler:** `SuperadminController.getVehicleHistoryByImei()`
- **Source:** `superadmin/superadmin.controller.ts:833`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleHistoryByImei(imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | Yes | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | Yes | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 348. `GET /superadmin/vehicles/by-imei/:imei/logs`

- **Handler:** `SuperadminController.getVehicleLogsByImei()`
- **Source:** `superadmin/superadmin.controller.ts:745`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleLogsByImei(imei, { from, to, limit, beforeId })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `beforeId` | `string` | Yes | `@Query('beforeId') beforeId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 349. `GET /superadmin/vehicles/by-imei/:imei/replay`

- **Handler:** `SuperadminController.getVehicleReplayByImei()`
- **Source:** `superadmin/superadmin.controller.ts:819`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleReplayByImei(imei, { from, to, maxPoints })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 350. `POST /superadmin/vehicles/by-imei/:imei/send-command`

- **Handler:** `SuperadminController.sendDeviceCommandByImei()`
- **Source:** `superadmin/superadmin.controller.ts:1000`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.sendDeviceCommandByImei(headerId, imei, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Body / payload**

- Object binding: `SendDeviceCommandDto` from `@Body() dto: SendDeviceCommandDto` — source: `superadmin/dto/send-device-command.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 351. `GET /superadmin/vehicles/by-imei/:imei/sensors`

- **Handler:** `SuperadminController.getVehicleSensorsByImei()`
- **Source:** `superadmin/superadmin.controller.ts:1045`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleSensorsByImei(imei, headerId, { includeTelemetryMeta, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `includeTelemetryMeta` | `string` | Yes | `@Query('includeTelemetryMeta') includeTelemetryMeta?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 352. `GET /superadmin/vehicles/by-imei/:imei/trail`

- **Handler:** `SuperadminController.getVehicleTrailByImei()`
- **Source:** `superadmin/superadmin.controller.ts:804`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleTrailByImei(imei, { hours, from, to, maxPoints })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `hours` | `string` | Yes | `@Query('hours') hours?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 353. `GET /superadmin/vehicletypes`

- **Handler:** `SuperadminController.getVehicleTypes()`
- **Source:** `superadmin/superadmin.controller.ts:261`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.superadminService.getVehicleTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 354. `POST /superadmin/vehicletypes`

- **Handler:** `SuperadminController.createVehicleType()`
- **Source:** `superadmin/superadmin.controller.ts:266`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createVehicleType(vehicleTypeDto)`

**Body / payload**

- Object binding: `VehicleTypeDto` from `@Body() vehicleTypeDto: VehicleTypeDto` — source: `superadmin/dto/vehicletype.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60) |
| `slug` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60), @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, { message: "slug must be lowercase and hyphen-separated (e.g. snowplow, mini-truck)", }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 355. `DELETE /superadmin/vehicletypes/:id`

- **Handler:** `SuperadminController.deleteVehicleType()`
- **Source:** `superadmin/superadmin.controller.ts:276`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteVehicleType(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 356. `PATCH /superadmin/vehicletypes/:id`

- **Handler:** `SuperadminController.updateVehicleType()`
- **Source:** `superadmin/superadmin.controller.ts:271`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateVehicleType(id, vehicleTypeDto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `VehicleTypeDto` from `@Body() vehicleTypeDto: VehicleTypeDto` — source: `superadmin/dto/vehicletype.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60) |
| `slug` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60), @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, { message: "slug must be lowercase and hyphen-separated (e.g. snowplow, mini-truck)", }) |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## WhatsAppTemplatesController

### 357. `GET /superadmin/whatsapptemplates`

- **Handler:** `WhatsAppTemplatesController.list()`
- **Source:** `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:33`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.templatesService.listTemplates(query)`

**Query params**

- Object binding: `ListWhatsAppTemplatesQueryDto` from `@Query() query: ListWhatsAppTemplatesQueryDto` — source: `superadmin/dto/whatsapp-templates.dto.ts:63`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `type` | `string` | No | @IsOptional(), @IsString() |
| `languageCode` | `string` | No | @IsOptional(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional(), @Transform(({ value }) => { if (value === 'true' \|\| value === '1') return true; if (value === 'false' \|\| value === '0') return false; return value; }), @IsBoolean() |
| `rk` | `string` | No | @IsOptional() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 358. `GET /superadmin/whatsapptemplates/:id`

- **Handler:** `WhatsAppTemplatesController.getOne()`
- **Source:** `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:61`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.templatesService.getTemplate(id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 359. `PATCH /superadmin/whatsapptemplates/:id`

- **Handler:** `WhatsAppTemplatesController.update()`
- **Source:** `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:67`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.templatesService.updateTemplate(id, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**

- Object binding: `UpdateWhatsAppTemplateDto` from `@Body() dto: UpdateWhatsAppTemplateDto` — source: `superadmin/dto/whatsapp-templates.dto.ts:16`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 200) |
| `body` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(1024) |
| `category` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(50) |
| `languageCode` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 360. `GET /superadmin/whatsapptemplates/meta`

- **Handler:** `WhatsAppTemplatesController.fetchMeta()`
- **Source:** `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:41`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.templatesService.fetchMetaTemplates()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 361. `POST /superadmin/whatsapptemplates/sync`

- **Handler:** `WhatsAppTemplatesController.sync()`
- **Source:** `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:52`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `any`
- **Return expression/source:** `this.templatesService.syncTemplates(dto)`

**Body / payload**

- Object binding: `SyncWhatsAppTemplatesDto` from `@Body() dto: SyncWhatsAppTemplatesDto` — source: `superadmin/dto/whatsapp-templates.dto.ts:48`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `templateIds` | `number[]` | No | @IsOptional(), @IsArray(), @IsInt({ each: true }), @Min(1, { each: true }), @Type(() => Number) |
| `dryRun` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## SuperadminController

### 362. `GET /superadmin/whitelabel`

- **Handler:** `SuperadminController.getWhiteLabelSettings()`
- **Source:** `superadmin/superadmin.controller.ts:533`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getWhiteLabelSettings(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 363. `PATCH /superadmin/whitelabel`

- **Handler:** `SuperadminController.updateWhiteLabelSettings()`
- **Source:** `superadmin/superadmin.controller.ts:543`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateWhiteLabelSettings(req, headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 364. `GET /superadmin/whitelabel/inspect`

- **Handler:** `SuperadminController.inspectWhiteLabelBranding()`
- **Source:** `superadmin/superadmin.controller.ts:538`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.inspectWhiteLabelBranding(host)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `host` | `string` | Yes | `@Query('host') host?: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AppController

### 365. `GET /timezones`

- **Handler:** `AppController.getTimezones()`
- **Source:** `app.controller.ts:168`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Timezones fetched successfully', data: await this.appService.getTimezones() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 366. `GET /unsubscribe`

- **Handler:** `AppController.unsubscribe()`
- **Source:** `app.controller.ts:30`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<void>`
- **Return expression/source:** `sendHtml( '<h2>Invalid link</h2>' + '<p>This unsubscribe link is invalid or has expired.</p>', )` OR `sendHtml( '<h2>Invalid link</h2>' + '<p>This unsubscribe link is invalid or has expired.</p>', )` OR `sendHtml( '<h2>Unsubscribed</h2>' + '<p>You have been unsubscribed from email notifications.</p>' + '<p style="margin-top:16px;">If this was a mistake you can re-subscribe from your account settings.</p>', )`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `u` | `string` | Yes | `@Query('u') u: string` |
| `b` | `string` | Yes | `@Query('b') b: string` |
| `s` | `string` | Yes | `@Query('s') s: string` |
| `t` | `string` | Yes | `@Query('t') t: string` |

**Implementation notes**

- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## UserController

### 367. `GET /user/commands/:cmdId`

- **Handler:** `UserController.getCommandLogByCmdId()`
- **Source:** `user/user.controller.ts:1006`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getCommandLogByCmdId(userId, cmdId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 368. `POST /user/commands/send-bulk`

- **Handler:** `UserController.sendCommandBulk()`
- **Source:** `user/user.controller.ts:979`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.sendCommandBulk(headerId, dto)`

**Body / payload**

- Object binding: `SendCommandBulkDto` from `@Body() dto: SendCommandBulkDto` — source: `user/dto/send-command-bulk.dto.ts:19`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `mode` | `SendCommandBulkMode` | Yes | @IsEnum(SendCommandBulkMode) |
| `vehicleIds` | `number[]` | No | @ValidateIf((o) => o.mode === SendCommandBulkMode.SELECTED && !o.items?.length), @IsOptional(), @IsArray(), @ArrayMinSize(1), @IsInt({ each: true }), @Type(() => Number) |
| `command` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |
| `items` | `SendCommandBulkItem[]` | No | @IsOptional(), @IsArray(), @ArrayMinSize(1), @ValidateNested({ each: true }), @Type(() => SendCommandBulkItem) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 369. `GET /user/commands/status/:cmdId`

- **Handler:** `UserController.getCommandStatus()`
- **Source:** `user/user.controller.ts:987`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getCommandStatus(cmdId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 370. `PATCH /user/companydetails`

- **Handler:** `UserController.updateOwnCompanyDetails()`
- **Source:** `user/user.controller.ts:512`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateCompanyDetails(headerId, companyDto)`

**Body / payload**

- Object binding: `CompanyDto` from `@Body() companyDto: CompanyDto` — source: `superadmin/dto/company.dto.ts:8`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 371. `GET /user/customcommands`

- **Handler:** `UserController.getUserCustomCommands()`
- **Source:** `user/user.controller.ts:965`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserCustomCommands(query)`

**Query params**

- Object binding: `CustomCommandsQueryDto` from `@Query() query: CustomCommandsQueryDto` — source: `superadmin/dto/custom-commands-query.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `deviceTypeId` | `string` | No | @IsOptional(), @IsString() |
| `commandTypeId` | `string` | No | @IsOptional(), @IsString() |
| `activeOnly` | `string` | No | @IsOptional(), @IsString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 372. `GET /user/dashboard/day-night-comparison`

- **Handler:** `UserController.getDayNightComparison()`
- **Source:** `user/user.controller.ts:862`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDayNightComparison(headerId, { vehicleId, from, to })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `string` | Yes | `@Query('vehicleId') vehicleId?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 373. `GET /user/dashboard/fleet-status`

- **Handler:** `UserController.getUserFleetStatus()`
- **Source:** `user/user.controller.ts:796`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserFleetStatus(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 374. `GET /user/dashboard/recent-alerts`

- **Handler:** `UserController.getDashboardRecentAlerts()`
- **Source:** `user/user.controller.ts:819`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDashboardRecentAlerts(headerId, { vehicleId: Number.isFinite(vid) ? vid : undefined, limit: limit ? parseInt(limit, 10) : undefined, beforeId: beforeId ? parseInt(beforeId, 10) : undefined, from, })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `string` | Yes | `@Query('vehicleId') vehicleId?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `beforeId` | `string` | Yes | `@Query('beforeId') beforeId?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 375. `GET /user/dashboard/recent-alerts/:id`

- **Handler:** `UserController.getDashboardRecentAlertDetail()`
- **Source:** `user/user.controller.ts:836`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDashboardRecentAlertDetail(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 376. `PATCH /user/dashboard/recent-alerts/:id/read`

- **Handler:** `UserController.markDashboardRecentAlertRead()`
- **Source:** `user/user.controller.ts:844`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markDashboardRecentAlertRead(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 377. `GET /user/dashboard/top-performing-assets`

- **Handler:** `UserController.topPerformingAssets()`
- **Source:** `user/user.controller.ts:852`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getTopPerformingAssets(headerId, { from, to, limit })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 378. `GET /user/dashboard/usage-last-7-days`

- **Handler:** `UserController.getUsageLast7Days()`
- **Source:** `user/user.controller.ts:801`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUsageLast7Days(headerId, Number.isFinite(vid) ? vid : undefined)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `string` | Yes | `@Query('vehicleId') vehicleId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 379. `GET /user/dashboard/weekly-comparison`

- **Handler:** `UserController.weeklyComparison()`
- **Source:** `user/user.controller.ts:810`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getWeeklyComparison(headerId, Number.isFinite(vid) ? vid : undefined)`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `string` | Yes | `@Query('vehicleId') vehicleId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 380. `GET /user/dashboards`

- **Handler:** `UserController.listDashboards()`
- **Source:** `user/user.controller.ts:876`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listUserDashboards(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 381. `POST /user/dashboards`

- **Handler:** `UserController.createDashboard()`
- **Source:** `user/user.controller.ts:889`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserDashboard(headerId, dto)`

**Body / payload**

- Object binding: `CreateDashboardDto` from `@Body() dto: CreateDashboardDto` — source: `user/dto/dashboard.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 382. `DELETE /user/dashboards/:id`

- **Handler:** `UserController.deleteDashboard()`
- **Source:** `user/user.controller.ts:906`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserDashboard(headerId, dashboardId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) dashboardId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 383. `GET /user/dashboards/:id`

- **Handler:** `UserController.getDashboard()`
- **Source:** `user/user.controller.ts:881`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserDashboardById(headerId, dashboardId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) dashboardId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 384. `PUT /user/dashboards/:id`

- **Handler:** `UserController.updateDashboard()`
- **Source:** `user/user.controller.ts:897`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserDashboard(headerId, dashboardId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) dashboardId: number` |

**Body / payload**

- Object binding: `UpdateDashboardDto` from `@Body() dto: UpdateDashboardDto` — source: `user/dto/dashboard.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `config` | `any` | No | @IsOptional() |
| `version` | `number` | Yes | @IsInt(), @Min(1) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 385. `GET /user/drivers`

- **Handler:** `UserController.getDrivers()`
- **Source:** `user/user.controller.ts:357`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDrivers(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 386. `POST /user/drivers`

- **Handler:** `UserController.createDriver()`
- **Source:** `user/user.controller.ts:349`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createDriver(headerId, dto)`

**Body / payload**

- Object binding: `CreateUserDriverDto` from `@Body() dto: CreateUserDriverDto` — source: `user/dto/create-driver.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | Yes | @IsString(), @MaxLength(10) |
| `mobile` | `string` | Yes | @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `username` | `string` | Yes | @IsString(), @MaxLength(50) |
| `password` | `string` | Yes | @IsString(), @MaxLength(100) |
| `countryCode` | `string` | Yes | @IsString(), @MaxLength(5) |
| `stateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 387. `DELETE /user/drivers/:id`

- **Handler:** `UserController.deleteDriver()`
- **Source:** `user/user.controller.ts:379`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteDriver(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 388. `GET /user/drivers/:id`

- **Handler:** `UserController.getDriverById()`
- **Source:** `user/user.controller.ts:362`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDriverById(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 389. `PATCH /user/drivers/:id`

- **Handler:** `UserController.updateDriver()`
- **Source:** `user/user.controller.ts:370`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateDriver(driverId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Body / payload**

- Object binding: `UpdateUserDriverDto` from `@Body() dto: UpdateUserDriverDto` — source: `user/dto/update-driver.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `mobile` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @MaxLength(254) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `countryCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5) |
| `StateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(12) |
| `isactive` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `attributes` | `Record<string, any> \| string` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 390. `POST /user/drivers/:id/assign-vehicle`

- **Handler:** `UserController.assignDriverToVehicle()`
- **Source:** `user/user.controller.ts:387`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.assignDriverToVehicle(driverId, dto.vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Body / payload**

- Object binding: `AssignDriverVehicleDto` from `@Body() dto: AssignDriverVehicleDto` — source: `user/dto/assign-driver-vehicle.dto.ts:10`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | @ToRequiredInt(), @IsNumber() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 391. `GET /user/drivers/:id/documents`

- **Handler:** `UserController.getDriverDocuments()`
- **Source:** `user/user.controller.ts:416`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDriverDocuments(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 392. `POST /user/drivers/:id/documents`

- **Handler:** `UserController.uploadDriverDocument()`
- **Source:** `user/user.controller.ts:424`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.uploadDriverDocumentMultipart(req, driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 393. `DELETE /user/drivers/:id/documents/:docId`

- **Handler:** `UserController.deleteDriverDocument()`
- **Source:** `user/user.controller.ts:443`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteDriverDocument(driverId, docId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 394. `PATCH /user/drivers/:id/documents/:docId`

- **Handler:** `UserController.updateDriverDocument()`
- **Source:** `user/user.controller.ts:433`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateDriverDocumentMultipart(req, driverId, docId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 395. `GET /user/drivers/:id/logs`

- **Handler:** `UserController.getDriverLogs()`
- **Source:** `user/user.controller.ts:404`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDriverLogs(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 396. `POST /user/drivers/:id/unassign-vehicle`

- **Handler:** `UserController.unassignDriverFromVehicle()`
- **Source:** `user/user.controller.ts:396`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.unassignDriverFromVehicle(driverId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 397. `GET /user/geofences`

- **Handler:** `UserController.listGeofences()`
- **Source:** `user/user.controller.ts:591`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserGeofences(headerId, { q, isActive, type })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `isActive` | `string` | Yes | `@Query('isActive') isActive?: string` |
| `type` | `string` | Yes | `@Query('type') type?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 398. `POST /user/geofences`

- **Handler:** `UserController.createGeofence()`
- **Source:** `user/user.controller.ts:609`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserGeofence(headerId, dto)`

**Body / payload**

- Object binding: `CreateGeofenceDto` from `@Body() dto: CreateGeofenceDto` — source: `user/dto/geofence.dto.ts:34`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `type` | `GeofenceType` | Yes | @IsEnum(GeofenceType) |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `geodata` | `GeofenceGeoData` | No | @IsObject(), @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 399. `DELETE /user/geofences/:id`

- **Handler:** `UserController.deleteGeofence()`
- **Source:** `user/user.controller.ts:626`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserGeofence(headerId, geofenceId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) geofenceId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 400. `GET /user/geofences/:id`

- **Handler:** `UserController.getGeofenceById()`
- **Source:** `user/user.controller.ts:601`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserGeofenceById(headerId, geofenceId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) geofenceId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 401. `PATCH /user/geofences/:id`

- **Handler:** `UserController.updateGeofence()`
- **Source:** `user/user.controller.ts:617`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserGeofence(headerId, geofenceId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) geofenceId: number` |

**Body / payload**

- Object binding: `UpdateGeofenceDto` from `@Body() dto: UpdateGeofenceDto` — source: `user/dto/geofence.dto.ts:60`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `type` | `GeofenceType` | No | @IsEnum(GeofenceType), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `geodata` | `GeofenceGeoData` | No | @IsObject(), @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 402. `POST /user/landmarkbulkjobs`

- **Handler:** `UserController.createLandmarkBulkJob()`
- **Source:** `user/user.controller.ts:731`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Landmark bulk job created', data: created }`

**Body / payload**

- Object binding: `CreateLandmarkBulkJobDto` from `@Body() dto: CreateLandmarkBulkJobDto` — source: `user/dto/landmarkbulkjobs.dto.ts:190`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `entityType` | `LandmarkEntityType` | Yes | @IsDefined(), @IsEnum(LandmarkEntityType) |
| `geofenceRows` | `GeofenceBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => GeofenceBulkRowDto) |
| `poiRows` | `PoiBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => PoiBulkRowDto) |
| `routeRows` | `RouteBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => RouteBulkRowDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 403. `GET /user/landmarkbulkjobs/:id`

- **Handler:** `UserController.getLandmarkBulkJob()`
- **Source:** `user/user.controller.ts:740`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' }` OR `{ action: true, message: 'Job fetched', data: job }`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 404. `GET /user/landmarkbulkjobs/:id/failed.csv`

- **Handler:** `UserController.downloadLandmarkFailedCsv()`
- **Source:** `user/user.controller.ts:750`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 405. `GET /user/landmarkbulkjobs/:id/stream`

- **Handler:** `UserController.streamLandmarkBulkJob()`
- **Source:** `user/user.controller.ts:768`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `any`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 406. `GET /user/localization`

- **Handler:** `UserController.getLocalizationData()`
- **Source:** `user/user.controller.ts:522`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getLocalizationData(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 407. `PATCH /user/localization`

- **Handler:** `UserController.updateLocalizationData()`
- **Source:** `user/user.controller.ts:527`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateLocalizationSettings(headerId, localizationDto)`

**Body / payload**

- Object binding: `UpdateSettingsStateDto` from `@Body() localizationDto: UpdateSettingsStateDto` — source: `superadmin/dto/usersetting.dto.ts:64`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 408. `GET /user/map-events`

- **Handler:** `UserController.getMapEvents()`
- **Source:** `user/user.controller.ts:1021`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapEvents(headerId, query)`

**Query params**

- Object binding: `MapEventsQueryDto` from `@Query() query: MapEventsQueryDto` — source: `superadmin/dto/map-events.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 409. `GET /user/map-telemetry`

- **Handler:** `UserController.getMapTelemetry()`
- **Source:** `user/user.controller.ts:1016`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapTelemetry(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 410. `GET /user/notification-settings`

- **Handler:** `UserController.getNotificationSettings()`
- **Source:** `user/user.controller.ts:918`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getNotificationSettings(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 411. `PUT /user/notification-settings`

- **Handler:** `UserController.updateNotificationSettings()`
- **Source:** `user/user.controller.ts:923`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateNotificationSettings(headerId, dto)`

**Body / payload**

- Object binding: `any` from `@Body() dto: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 412. `GET /user/notifications`

- **Handler:** `UserController.getUserNotifications()`
- **Source:** `user/user.controller.ts:1129`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserNotifications(headerId, query)`

**Query params**

- Object binding: `NotificationsQueryDto` from `@Query() query: NotificationsQueryDto` — source: `superadmin/dto/notifications.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsNumberString() |
| `unreadOnly` | `string` | No | @IsOptional(), @IsBooleanString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 413. `PATCH /user/notifications/:id/read`

- **Handler:** `UserController.markUserNotificationRead()`
- **Source:** `user/user.controller.ts:1146`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markUserNotificationRead(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 414. `GET /user/notifications/preferences`

- **Handler:** `UserController.getNotificationPreferences()`
- **Source:** `user/user.controller.ts:935`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getNotificationPreferences(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 415. `PUT /user/notifications/preferences`

- **Handler:** `UserController.updateNotificationPreferences()`
- **Source:** `user/user.controller.ts:940`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateNotificationPreferences(headerId, dto)`

**Body / payload**

- Object binding: `any` from `@Body() dto: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 416. `PATCH /user/notifications/read-all`

- **Handler:** `UserController.markAllUserNotificationsRead()`
- **Source:** `user/user.controller.ts:1138`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markAllUserNotificationsRead(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 417. `POST /user/notifications/test-fcm-me`

- **Handler:** `UserController.testFcmToMe()`
- **Source:** `user/user.controller.ts:952`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.testFcmToMe(headerId, dto)`

**Body / payload**

- Object binding: `any` from `@Body() dto: any`

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 418. `GET /user/notifications/vehicle`

- **Handler:** `UserController.getVehicleNotificationsForTopbar()`
- **Source:** `user/user.controller.ts:1159`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleNotificationsForTopbar(headerId, { ...query, vehicleId })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `string` | Yes | `@Query('vehicleId') vehicleId?: string` |

- Object binding: `NotificationsQueryDto` from `@Query() query: NotificationsQueryDto` — source: `superadmin/dto/notifications.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsNumberString() |
| `unreadOnly` | `string` | No | @IsOptional(), @IsBooleanString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 419. `PATCH /user/notifications/vehicle/:id/read`

- **Handler:** `UserController.markVehicleNotificationReadForTopbar()`
- **Source:** `user/user.controller.ts:1177`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markVehicleNotificationReadForTopbar(headerId, id)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 420. `PATCH /user/notifications/vehicle/read-all`

- **Handler:** `UserController.markAllVehicleNotificationsReadForTopbar()`
- **Source:** `user/user.controller.ts:1169`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markAllVehicleNotificationsReadForTopbar(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 421. `GET /user/pois`

- **Handler:** `UserController.listPois()`
- **Source:** `user/user.controller.ts:685`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserPois(headerId, { q, isActive })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `isActive` | `string` | Yes | `@Query('isActive') isActive?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 422. `POST /user/pois`

- **Handler:** `UserController.createPoi()`
- **Source:** `user/user.controller.ts:702`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserPoi(headerId, dto)`

**Body / payload**

- Object binding: `CreatePoiDto` from `@Body() dto: CreatePoiDto` — source: `user/dto/poi.dto.ts:28`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `category` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `iconSlug` | `string` | No | @IsString(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(0) |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `coordinates` | `PoiCoordinatesDto` | Yes | @IsObject(), @ValidateNested(), @Type(() => PoiCoordinatesDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 423. `DELETE /user/pois/:id`

- **Handler:** `UserController.deletePoi()`
- **Source:** `user/user.controller.ts:719`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserPoi(headerId, poiId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) poiId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 424. `GET /user/pois/:id`

- **Handler:** `UserController.getPoiById()`
- **Source:** `user/user.controller.ts:694`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserPoiById(headerId, poiId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) poiId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 425. `PATCH /user/pois/:id`

- **Handler:** `UserController.updatePoi()`
- **Source:** `user/user.controller.ts:710`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserPoi(headerId, poiId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) poiId: number` |

**Body / payload**

- Object binding: `UpdatePoiDto` from `@Body() dto: UpdatePoiDto` — source: `user/dto/poi.dto.ts:68`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `category` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `iconSlug` | `string` | No | @IsString(), @IsOptional() |
| `toleranceMeters` | `number \| null` | No | @IsNumber(), @IsOptional(), @Min(0) |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `coordinates` | `PoiCoordinatesDto` | No | @IsObject(), @IsOptional(), @ValidateNested(), @Type(() => PoiCoordinatesDto) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 426. `GET /user/profile`

- **Handler:** `UserController.getProfile()`
- **Source:** `user/user.controller.ts:452`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getProfile(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 427. `PATCH /user/profile`

- **Handler:** `UserController.updateProfile()`
- **Source:** `user/user.controller.ts:457`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateProfile(headerId, profileDto)`

**Body / payload**

- Object binding: `ProfileDto` from `@Body() profileDto: ProfileDto` — source: `superadmin/dto/profile.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 428. `GET /user/profile/email-subscription`

- **Handler:** `UserController.getEmailSubscription()`
- **Source:** `user/user.controller.ts:490`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, data: { isSubscribed: subscribed, brandOwnerId, scope } }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 429. `POST /user/profile/email-subscription/subscribe`

- **Handler:** `UserController.subscribeEmail()`
- **Source:** `user/user.controller.ts:501`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Subscribed', data: { isSubscribed: true } }`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 430. `POST /user/profile/verify/email/confirm`

- **Handler:** `UserController.verifyEmailOtp()`
- **Source:** `user/user.controller.ts:471`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyEmailOtp(headerId, dto.otp)`

**Body / payload**

- Object binding: `VerifyOtpDto` from `@Body() dto: VerifyOtpDto` — source: `verification/dto/verify-otp.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 431. `POST /user/profile/verify/email/request`

- **Handler:** `UserController.requestEmailOtp()`
- **Source:** `user/user.controller.ts:466`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestEmailOtp(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 432. `POST /user/profile/verify/whatsapp/confirm`

- **Handler:** `UserController.verifyWhatsAppOtp()`
- **Source:** `user/user.controller.ts:481`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyWhatsAppOtp(headerId, dto.otp)`

**Body / payload**

- Object binding: `VerifyOtpDto` from `@Body() dto: VerifyOtpDto` — source: `verification/dto/verify-otp.dto.ts:9`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 433. `POST /user/profile/verify/whatsapp/request`

- **Handler:** `UserController.requestWhatsAppOtp()`
- **Source:** `user/user.controller.ts:476`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestWhatsAppOtp(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 434. `GET /user/routes`

- **Handler:** `UserController.listRoutes()`
- **Source:** `user/user.controller.ts:638`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserRoutes(headerId, { q, isActive, includeGeodata })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `isActive` | `string` | Yes | `@Query('isActive') isActive?: string` |
| `includeGeodata` | `string` | Yes | `@Query('includeGeodata') includeGeodata?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 435. `POST /user/routes`

- **Handler:** `UserController.createRoute()`
- **Source:** `user/user.controller.ts:656`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserRoute(headerId, dto)`

**Body / payload**

- Object binding: `CreateRouteDto` from `@Body() dto: CreateRouteDto` — source: `user/dto/route.dto.ts:12`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(1) |
| `geodata` | `RouteGeoData` | No | @IsObject(), @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 436. `DELETE /user/routes/:id`

- **Handler:** `UserController.deleteRoute()`
- **Source:** `user/user.controller.ts:673`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserRoute(headerId, routeId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) routeId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 437. `GET /user/routes/:id`

- **Handler:** `UserController.getRouteById()`
- **Source:** `user/user.controller.ts:648`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserRouteById(headerId, routeId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) routeId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 438. `PATCH /user/routes/:id`

- **Handler:** `UserController.updateRoute()`
- **Source:** `user/user.controller.ts:664`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserRoute(headerId, routeId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) routeId: number` |

**Body / payload**

- Object binding: `UpdateRouteDto` from `@Body() dto: UpdateRouteDto` — source: `user/dto/route.dto.ts:40`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(1) |
| `geodata` | `RouteGeoData` | No | @IsObject(), @IsOptional() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 439. `GET /user/sharetracklinks`

- **Handler:** `UserController.listShareTrackLinks()`
- **Source:** `user/user.controller.ts:156`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listShareTrackLinks(headerId, query)`

**Query params**

- Object binding: `ListShareTrackLinksDto` from `@Query() query: ListShareTrackLinksDto` — source: `user/dto/sharetracklinks/list-sharetracklinks.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `search` | `string` | No | @IsOptional(), @IsString() |
| `page` | `string` | No | @IsOptional(), @IsString() |
| `limit` | `string` | No | @IsOptional(), @IsString() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 440. `POST /user/sharetracklinks`

- **Handler:** `UserController.createShareTrackLink()`
- **Source:** `user/user.controller.ts:148`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createShareTrackLink(headerId, dto)`

**Body / payload**

- Object binding: `CreateShareTrackLinkDto` from `@Body() dto: CreateShareTrackLinkDto` — source: `user/dto/sharetracklinks/create-sharetracklink.dto.ts:29`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @toIntArray(), @IsInt({ each: true }) |
| `expiryAt` | `string` | Yes | @IsDateString() |
| `isGeofence` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isHistory` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 441. `DELETE /user/sharetracklinks/:id`

- **Handler:** `UserController.deleteShareTrackLink()`
- **Source:** `user/user.controller.ts:181`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteShareTrackLink(headerId, shareLinkId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) shareLinkId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 442. `GET /user/sharetracklinks/:id`

- **Handler:** `UserController.getShareTrackLinkById()`
- **Source:** `user/user.controller.ts:164`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getShareTrackLinkById(headerId, shareLinkId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) shareLinkId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 443. `PATCH /user/sharetracklinks/:id`

- **Handler:** `UserController.updateShareTrackLink()`
- **Source:** `user/user.controller.ts:172`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateShareTrackLink(headerId, shareLinkId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) shareLinkId: number` |

**Body / payload**

- Object binding: `UpdateShareTrackLinkDto` from `@Body() dto: UpdateShareTrackLinkDto` — source: `user/dto/sharetracklinks/update-sharetracklink.dto.ts:29`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | No | @IsOptional(), @IsArray(), @ArrayMinSize(1), @toIntArray(), @IsInt({ each: true }) |
| `expiryAt` | `string` | No | @IsOptional(), @IsDateString() |
| `isGeofence` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isHistory` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 444. `GET /user/subusers`

- **Handler:** `UserController.listSubUsers()`
- **Source:** `user/user.controller.ts:75`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listSubUsers(headerId, { search, page, limit })`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `search` | `string` | Yes | `@Query('search') search?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 445. `POST /user/subusers`

- **Handler:** `UserController.createSubUser()`
- **Source:** `user/user.controller.ts:85`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createSubUser(headerId, dto)`

**Body / payload**

- Object binding: `CreateSubUserDto` from `@Body() dto: CreateSubUserDto` — source: `user/dto/subusers/create-subuser.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MinLength(3) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d{7,15}$/, { message: 'mobileNumber must be 7-15 digits' }) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MinLength(6) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 446. `DELETE /user/subusers/:id`

- **Handler:** `UserController.deleteSubUser()`
- **Source:** `user/user.controller.ts:104`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteSubUser(headerId, subUserId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 447. `GET /user/subusers/:id`

- **Handler:** `UserController.getSubUserById()`
- **Source:** `user/user.controller.ts:90`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getSubUserById(headerId, subUserId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 448. `PATCH /user/subusers/:id`

- **Handler:** `UserController.updateSubUser()`
- **Source:** `user/user.controller.ts:95`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateSubUser(headerId, subUserId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Body / payload**

- Object binding: `UpdateSubUserDto` from `@Body() dto: UpdateSubUserDto` — source: `user/dto/subusers/update-subuser.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MinLength(3) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d{7,15}$/, { message: 'mobileNumber must be 7-15 digits' }) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MinLength(6) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 449. `GET /user/subusers/:id/vehicles`

- **Handler:** `UserController.getSubUserVehicles()`
- **Source:** `user/user.controller.ts:112`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getSubUserVehicles(headerId, subUserId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 450. `POST /user/subusers/:id/vehicles/assign`

- **Handler:** `UserController.assignSubUserVehicles()`
- **Source:** `user/user.controller.ts:120`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.assignSubUserVehicles(headerId, subUserId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Body / payload**

- Object binding: `AssignSubUserVehiclesDto` from `@Body() dto: AssignSubUserVehiclesDto` — source: `user/dto/subusers/assign-subuser-vehicles.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayNotEmpty(), @IsInt({ each: true }), @Min(1, { each: true }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 451. `POST /user/subusers/:id/vehicles/unassign`

- **Handler:** `UserController.unassignSubUserVehicles()`
- **Source:** `user/user.controller.ts:129`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.unassignSubUserVehicles(headerId, subUserId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Body / payload**

- Object binding: `UnassignSubUserVehiclesDto` from `@Body() dto: UnassignSubUserVehiclesDto` — source: `user/dto/subusers/unassign-subuser-vehicles.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayNotEmpty(), @IsInt({ each: true }), @Min(1, { each: true }) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 452. `GET /user/systemvariables`

- **Handler:** `UserController.getUserSystemVariables()`
- **Source:** `user/user.controller.ts:970`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserSystemVariables()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 453. `GET /user/tickets`

- **Handler:** `UserController.listTickets()`
- **Source:** `user/user.controller.ts:557`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listTickets(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 454. `POST /user/tickets`

- **Handler:** `UserController.createTicket()`
- **Source:** `user/user.controller.ts:562`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createTicket(headerId, req)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 455. `GET /user/tickets/:id`

- **Handler:** `UserController.getTicketConversation()`
- **Source:** `user/user.controller.ts:570`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getTicketConversation(ticketId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 456. `POST /user/tickets/:id`

- **Handler:** `UserController.addTicketMessage()`
- **Source:** `user/user.controller.ts:578`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.addTicketMessage(ticketId, headerId, req)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 457. `GET /user/topbar-search`

- **Handler:** `UserController.searchTopbar()`
- **Source:** `user/user.controller.ts:62`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.topbarSearch.searchForUser(headerId, dto)`

**Query params**

- Object binding: `TopbarSearchQueryDto` from `@Query() dto: TopbarSearchQueryDto` — source: `topbar-search/dto/topbar-search.dto.ts:13`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `q` | `string` | Yes | @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @IsString(), @IsNotEmpty(), @MinLength(2), @MaxLength(80) |
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(30) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 458. `GET /user/transactions`

- **Handler:** `UserController.listUserTransactions()`
- **Source:** `user/user.controller.ts:539`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `status` | `string` | Yes | `@Query('status') status?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `q` | `string` | Yes | `@Query('q') q?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 459. `PATCH /user/updatepassword`

- **Handler:** `UserController.updatePassword()`
- **Source:** `user/user.controller.ts:517`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updatePassword(headerId, passwordDto)`

**Body / payload**

- Object binding: `UpdatePasswordDto` from `@Body() passwordDto: UpdatePasswordDto` — source: `superadmin/dto/updatepassword.dto.ts:4`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `currentPassword` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `newPassword` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(6), @MaxLength(72) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 460. `POST /user/upload`

- **Handler:** `UserController.uploadProfile()`
- **Source:** `user/user.controller.ts:787`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.uploadProfileImage(req, headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 461. `GET /user/vehicles`

- **Handler:** `UserController.getUserVehicles()`
- **Source:** `user/user.controller.ts:138`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserVehicles(headerId)`

**Payload:** none detected from the controller signature.

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 462. `GET /user/vehicles/:id`

- **Handler:** `UserController.getVehicleById()`
- **Source:** `user/user.controller.ts:194`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleById(vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 463. `PATCH /user/vehicles/:id`

- **Handler:** `UserController.updateVehicleById()`
- **Source:** `user/user.controller.ts:199`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleById(vehicleId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `UpdateUserVehicleDto` from `@Body() dto: UpdateUserVehicleDto` — source: `user/dto/update-vehicle.dto.ts:33`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @ToTrimmedString(), @IsString() |
| `plateNumber` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @IsString() |
| `vin` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @IsString() |
| `vehicleTypeId` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `gmtOffset` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @Matches(/^[+-](0\d\|1[0-4]):[0-5]\d$/) |
| `vehicleMeta` | `Record<string, any>` | No | @IsOptional(), @ToOptionalJSON(), @IsObject() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 464. `PATCH /user/vehicles/:id/config`

- **Handler:** `UserController.updateVehicleConfig()`
- **Source:** `user/user.controller.ts:208`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleConfig(vehicleId, headerId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `UpdateVehicleConfigDto` from `@Body() dto: UpdateVehicleConfigDto` — source: `user/dto/update-vehicle-config.dto.ts:17`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `speedVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `distanceVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `odometer` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `engineHours` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `ignitionSource` | `'ACC' \| 'MOTION'` | No | @IsOptional(), @ToOptionalUpper(), @IsIn(['ACC', 'MOTION']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 465. `GET /user/vehicles/:id/documents`

- **Handler:** `UserController.getVehicleDocuments()`
- **Source:** `user/user.controller.ts:309`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleDocuments(vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 466. `POST /user/vehicles/:id/documents`

- **Handler:** `UserController.uploadVehicleDocument()`
- **Source:** `user/user.controller.ts:317`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.uploadVehicleDocumentMultipart(req, vehicleId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 467. `DELETE /user/vehicles/:id/documents/:docId`

- **Handler:** `UserController.deleteVehicleDocument()`
- **Source:** `user/user.controller.ts:336`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteVehicleDocument(vehicleId, docId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 468. `PATCH /user/vehicles/:id/documents/:docId`

- **Handler:** `UserController.updateVehicleDocument()`
- **Source:** `user/user.controller.ts:326`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleDocumentMultipart(req, vehicleId, docId, headerId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.
- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 469. `GET /user/vehicles/:vehicleId/commands`

- **Handler:** `UserController.getCommandHistoryByVehicleId()`
- **Source:** `user/user.controller.ts:996`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getCommandHistoryByVehicleId(userId, vehicleId, { limit, cursorId })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `cursorId` | `string` | Yes | `@Query('cursorId') cursorId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 470. `GET /user/vehicles/:vehicleId/sensors`

- **Handler:** `UserController.listVehicleSensors()`
- **Source:** `user/user.controller.ts:221`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listVehicleSensors(headerId, vehicleId, { search, page, limit, includeLive: includeLive === 'true', })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `search` | `string` | Yes | `@Query('search') search?: string` |
| `page` | `string` | Yes | `@Query('page') page?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `includeLive` | `string` | Yes | `@Query('includeLive') includeLive?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 471. `POST /user/vehicles/:vehicleId/sensors`

- **Handler:** `UserController.createVehicleSensor()`
- **Source:** `user/user.controller.ts:236`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createVehicleSensor(headerId, vehicleId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `CreateVehicleSensorDto` from `@Body() dto: CreateVehicleSensorDto` — source: `user/dto/sensors/create-vehicle-sensor.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 472. `DELETE /user/vehicles/:vehicleId/sensors/:sensorId`

- **Handler:** `UserController.deleteVehicleSensor()`
- **Source:** `user/user.controller.ts:255`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteVehicleSensor(headerId, vehicleId, sensorId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 473. `PATCH /user/vehicles/:vehicleId/sensors/:sensorId`

- **Handler:** `UserController.updateVehicleSensor()`
- **Source:** `user/user.controller.ts:245`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleSensor(headerId, vehicleId, sensorId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Body / payload**

- Object binding: `UpdateVehicleSensorDto` from `@Body() dto: UpdateVehicleSensorDto` — source: `user/dto/sensors/update-vehicle-sensor.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | No | @IsOptional(), @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 474. `GET /user/vehicles/:vehicleId/sensors/:sensorId/history`

- **Handler:** `UserController.getSensorHistory()`
- **Source:** `user/user.controller.ts:281`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleSensorHistory(headerId, vehicleId, sensorId, { from, to, maxPoints })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 475. `POST /user/vehicles/:vehicleId/sensors/run`

- **Handler:** `UserController.runVehicleSensor()`
- **Source:** `user/user.controller.ts:264`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.runVehicleSensor(headerId, vehicleId, dto)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Body / payload**

- Object binding: `RunVehicleSensorDto` from `@Body() dto: RunVehicleSensorDto` — source: `user/dto/sensors/run-vehicle-sensor.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `payload` | `Record<string, unknown>` | Yes | @IsObject() |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 476. `GET /user/vehicles/:vehicleId/sensors/telemetry`

- **Handler:** `UserController.getVehicleSensorTelemetry()`
- **Source:** `user/user.controller.ts:273`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleSensorTelemetry(headerId, vehicleId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 477. `GET /user/vehicles/:vehicleId/telemetry`

- **Handler:** `UserController.getVehicleTelemetrySnapshot()`
- **Source:** `user/user.controller.ts:297`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleTelemetrySnapshot(headerId, vehicleId)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 478. `GET /user/vehicles/by-imei/:imei/details`

- **Handler:** `UserController.getVehicleDetailsByImei()`
- **Source:** `user/user.controller.ts:1029`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleDetailsByImei(headerId, imei)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 479. `GET /user/vehicles/by-imei/:imei/events`

- **Handler:** `UserController.getVehicleEventsByImei()`
- **Source:** `user/user.controller.ts:1054`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleEventsByImei(headerId, imei, query)`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

- Object binding: `MapEventsQueryDto` from `@Query() query: MapEventsQueryDto` — source: `superadmin/dto/map-events.dto.ts:3`

| Field | Type | Required | Validation / transform decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 480. `GET /user/vehicles/by-imei/:imei/history`

- **Handler:** `UserController.getVehicleHistoryByImei()`
- **Source:** `user/user.controller.ts:1095`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleHistoryByImei(headerId, imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | Yes | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | Yes | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 481. `GET /user/vehicles/by-imei/:imei/logs`

- **Handler:** `UserController.getVehicleLogsByIMEI()`
- **Source:** `user/user.controller.ts:1037`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleLogsByImei(headerId, imei, { from, to, limit, beforeId, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `limit` | `string` | Yes | `@Query('limit') limit?: string` |
| `beforeId` | `string` | Yes | `@Query('beforeId') beforeId?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 482. `GET /user/vehicles/by-imei/:imei/replay`

- **Handler:** `UserController.getVehicleReplayByImei()`
- **Source:** `user/user.controller.ts:1080`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleReplayByImei(headerId, imei, { from, to, maxPoints, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 483. `GET /user/vehicles/by-imei/:imei/sensors`

- **Handler:** `UserController.getVehicleSensorsByImei()`
- **Source:** `user/user.controller.ts:1114`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleSensorsByImei(headerId, imei, { includeTelemetryMeta, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `includeTelemetryMeta` | `string` | Yes | `@Query('includeTelemetryMeta') includeTelemetryMeta?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 484. `GET /user/vehicles/by-imei/:imei/trail`

- **Handler:** `UserController.getVehicleTrailByImei()`
- **Source:** `user/user.controller.ts:1063`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleTrailByImei(headerId, imei, { hours, from, to, maxPoints, })`

**Path params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `hours` | `string` | Yes | `@Query('hours') hours?: string` |
| `from` | `string` | Yes | `@Query('from') from?: string` |
| `to` | `string` | Yes | `@Query('to') to?: string` |
| `maxPoints` | `string` | Yes | `@Query('maxPoints') maxPoints?: string` |

**Implementation notes**

- `@HeaderId()` is derived from the authenticated JWT user id; it is not a manual HTTP header.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## AppController

### 485. `GET /vehicletypes`

- **Handler:** `AppController.getVehicleTypes()`
- **Source:** `app.controller.ts:128`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `this.appService.getVehicleTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 486. `GET /version`

- **Handler:** `AppController.getVersion()`
- **Source:** `app.controller.ts:23`
- **Auth:** Public / unspecified
- **Controller return type:** `any`
- **Return expression/source:** `{ action : true, message: 'Version fetched successfully', version: '2.5.9' }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```


## WhatsappWebhookController

### 487. `GET /webhooks/whatsapp`

- **Handler:** `WhatsappWebhookController.verify()`
- **Source:** `webhooks/whatsapp-webhook.controller.ts:94`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<void>`

**Query params**

| Name | Type | Required | Raw decorator |
|---|---|---:|---|
| `hub.mode` | `string` | Yes | `@Query('hub.mode') mode: string` |
| `hub.verify_token` | `string` | Yes | `@Query('hub.verify_token') token: string` |
| `hub.challenge` | `string` | Yes | `@Query('hub.challenge') challenge: string` |

**Implementation notes**

- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 488. `POST /webhooks/whatsapp`

- **Handler:** `WhatsappWebhookController.inbound()`
- **Source:** `webhooks/whatsapp-webhook.controller.ts:124`
- **Auth:** Public / unspecified
- **Controller return type:** `Promise<void>`

**Payload:** none detected from the controller signature.

**Implementation notes**

- Uses `FastifyRequest`; payload may be parsed manually by the service. For upload/ticket/document endpoints, validate multipart fields against the service implementation.
- Uses raw `FastifyReply`; response may bypass the standard success wrapper, especially for streams/downloads/SSE.

**Standard successful HTTP response envelope**

```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

---

# DTO / type appendix

This appendix includes TypeScript classes/interfaces/enums discovered in `backend/src`. Controller sections above include the relevant DTO fields inline where the type is used directly from a controller signature.

| Type | Kind | Source | Fields / values |
|---|---|---|---:|
| `ActivateAdminDto` | class | `superadmin/dto/activateadmin.ts:4` | 1 |
| `ActivityLogInput` | interface | `activity-log/activity-log.service.ts:16` | 6 |
| `ActivityLogInterceptor` | class | `activity-log/activity-log.interceptor.ts:42` | 1 |
| `ActivityLogModule` | class | `activity-log/activity-log.module.ts:16` | 0 |
| `ActivityLogService` | class | `activity-log/activity-log.service.ts:64` | 1 |
| `AddressDatabaseService` | class | `database/address-database.service.ts:11` | 1 |
| `AdminActivityLogsDto` | class | `admin/dto/admin-activity-logs.dto.ts:4` | 8 |
| `AdminActivityLogsDto` | class | `superadmin/dto/admin-activity-logs.dto.ts:4` | 7 |
| `AdminCalendarDayDto` | class | `admin/dto/calendar.dto.ts:86` | 3 |
| `AdminCalendarRangeDto` | class | `admin/dto/calendar.dto.ts:56` | 4 |
| `AdminConfigDto` | class | `admin/dto/adminconfig.dto.ts:3` | 2 |
| `AdminController` | class | `admin/admin.controller.ts:63` | 0 |
| `AdminCreateMyTicketDto` | class | `admin/dto/admin-create-my-ticket.dto.ts:4` | 4 |
| `AdminCreateTicketDto` | class | `admin/dto/admin-create-ticket.dto.ts:22` | 6 |
| `AdminDashboardSummaryDto` | class | `admin/dto/admin-dashboard-summary.dto.ts:4` | 4 |
| `AdminEventLogsDto` | class | `admin/dto/admin-event-logs.dto.ts:4` | 11 |
| `AdminModule` | class | `admin/admin.module.ts:13` | 0 |
| `AdminPasswordUpdateDto` | class | `superadmin/dto/adminpasswordupdate.dto.ts:40` | 3 |
| `AdminRenewVehiclesDto` | class | `admin/dto/admin-transactions.dto.ts:20` | 5 |
| `AdminReplyMyTicketDto` | class | `admin/dto/admin-reply-my-ticket.dto.ts:6` | 1 |
| `AdminReplyTicketDto` | class | `admin/dto/admin-reply-ticket.dto.ts:6` | 1 |
| `AdminService` | class | `admin/admin.service.ts:106` | 3 |
| `AdminTelemetryLogsDto` | class | `admin/dto/admin-telemetry-logs.dto.ts:4` | 7 |
| `AdminUpdateTicketStatusDto` | class | `admin/dto/admin-update-ticket-status.dto.ts:9` | 1 |
| `AgentCommand` | interface | `agent/interfaces/agent-command.interface.ts:13` | 10 |
| `AgentCommandEntities` | interface | `agent/interfaces/agent-command.interface.ts:1` | 9 |
| `AgentController` | class | `agent/controllers/agent.controller.ts:18` | 0 |
| `AgentIntent` | enum | `agent/constants/agent-intents.ts:1` | 22 |
| `AgentModule` | class | `agent/agent.module.ts:20` | 0 |
| `AgentRegistry` | class | `agent/registry/agent.registry.ts:9` | 3 |
| `AgentResponse` | interface | `agent/interfaces/agent-response.interface.ts:1` | 9 |
| `AgentRouterService` | class | `agent/orchestrator/agent-router.service.ts:6` | 0 |
| `AgentTaskWorker` | class | `agent/workers/agent-task.worker.ts:10` | 1 |
| `AnalyticsAgent` | class | `agent/agents/analytics.agent.ts:8` | 2 |
| `AppController` | class | `app.controller.ts:9` | 0 |
| `AppModule` | class | `app.module.ts:39` | 0 |
| `AppNotifyTemplateDto` | class | `superadmin/dto/appnotifytempletes.dto.ts:4` | 2 |
| `AppService` | class | `app.service.ts:10` | 0 |
| `AssignDriverVehicleDto` | class | `user/dto/assign-driver-vehicle.dto.ts:10` | 1 |
| `AssignSubUserVehiclesDto` | class | `user/dto/subusers/assign-subuser-vehicles.dto.ts:3` | 1 |
| `AssociateTypeDto` | enum | `superadmin/dto/uploaddoc.dto.ts:3` | 3 |
| `AuthController` | class | `auth/controllers/auth.controller.ts:18` | 0 |
| `AuthenticatedBugReportUser` | interface | `bug-report/bug-report.service.ts:23` | 8 |
| `AuthGuard` | class | `common/guards/auth.guard.ts:4` | 0 |
| `AuthModule` | class | `auth/auth.module.ts:10` | 0 |
| `AuthResponseDto` | class | `auth/dto/auth-response.dto.ts:1` | 3 |
| `AuthService` | class | `auth/services/auth.service.ts:26` | 6 |
| `AutosyncModule` | class | `autosync/autosync.module.ts:6` | 0 |
| `AutosyncService` | class | `autosync/autosync.service.ts:13` | 5 |
| `BoundedLatencyWindow` | class | `common/services/telemetry-stats.service.ts:73` | 2 |
| `BrandingCacheEntry` | interface | `branding/branding-cache.util.ts:1` | 2 |
| `BrandingDiagnosticsService` | class | `branding/branding-diagnostics.service.ts:30` | 1 |
| `BrandingInspectionResult` | interface | `branding/branding-resolver.service.ts:29` | 12 |
| `BrandingModule` | class | `branding/branding.module.ts:8` | 0 |
| `BrandingResolverService` | class | `branding/branding-resolver.service.ts:136` | 0 |
| `BrandingStorageService` | class | `branding/branding-storage.service.ts:16` | 2 |
| `BrandingUpdateService` | class | `branding/branding-update.service.ts:45` | 0 |
| `BugReportController` | class | `bug-report/bug-report.controller.ts:23` | 0 |
| `BugReportModule` | class | `bug-report/bug-report.module.ts:5` | 0 |
| `BugReportRequestDetails` | interface | `bug-report/bug-report.service.ts:34` | 7 |
| `BugReportService` | class | `bug-report/bug-report.service.ts:52` | 2 |
| `BugReportSeverity` | enum | `bug-report/dto/create-bug-report.dto.ts:25` | 4 |
| `BuildResult` | interface | `common/utils/reverse-geocoding.client.ts:68` | 2 |
| `BulkPointDto` | class | `geocoding/dto/reverse-geocode.dto.ts:24` | 2 |
| `BulkReverseGeocodeDto` | class | `geocoding/dto/reverse-geocode.dto.ts:36` | 1 |
| `CachedBrandIdentity` | interface | `email/services/email-brand-cache.service.ts:18` | 11 |
| `CachedEmailTemplate` | interface | `email/services/email-template-cache.service.ts:12` | 4 |
| `CachedParent` | interface | `email/services/email-context.resolver.ts:45` | 3 |
| `CachedSmtpSetting` | interface | `email/services/smtp-cache.service.ts:10` | 11 |
| `CachedVehicle` | interface | `notifications/notification-cache.service.ts:18` | 4 |
| `CalendarDayDto` | class | `superadmin/dto/calendar.dto.ts:86` | 3 |
| `CalendarEventType` | enum | `admin/dto/calendar.dto.ts:6` | 3 |
| `CalendarEventType` | enum | `superadmin/dto/calendar.dto.ts:6` | 3 |
| `CalendarRangeDto` | class | `superadmin/dto/calendar.dto.ts:56` | 4 |
| `CanonicalTelemetry` | interface | `handledata/types/telemetry-normalizer.ts:69` | 19 |
| `CommandExecutor` | class | `common/utils/executecommands.ts:37` | 3 |
| `CommandParserService` | class | `agent/orchestrator/command-parser.service.ts:165` | 0 |
| `CommandRateLimitService` | class | `agent/orchestrator/command-rate-limit.service.ts:19` | 0 |
| `CommandResult` | interface | `common/utils/executecommands.ts:10` | 5 |
| `CommandStatusResult` | interface | `agent/application/device-command-dispatcher.service.ts:28` | 15 |
| `commandTypeDto` | class | `superadmin/dto/commandtype.dto.ts:4` | 2 |
| `CommsModule` | class | `comms/comms.module.ts:26` | 0 |
| `CommsService` | class | `comms/comms.service.ts:33` | 1 |
| `CommsVerificationModule` | class | `communications/verification/verification.module.ts:10` | 0 |
| `CommsVerificationService` | class | `communications/verification/verification.service.ts:60` | 2 |
| `CompanyDto` | class | `admin/dto/company.dto.ts:8` | 5 |
| `CompanyDto` | class | `superadmin/dto/company.dto.ts:8` | 5 |
| `ComponentInfo` | interface | `superadmin/server/server.types.ts:11` | 8 |
| `ContributionMetadata` | interface | `handledata/handledata.service.ts:42` | 8 |
| `CreateAdminDto` | class | `superadmin/dto/admin.dto.ts:11` | 13 |
| `CreateAgentCommandDto` | class | `agent/dto/create-agent-command.dto.ts:33` | 4 |
| `CreateBugReportDto` | class | `bug-report/dto/create-bug-report.dto.ts:84` | 19 |
| `CreateDashboardDto` | class | `user/dto/dashboard.dto.ts:3` | 1 |
| `CreateDeviceDto` | class | `admin/dto/createdevice.dto.ts:5` | 2 |
| `CreateDriverBulkJobDto` | class | `admin/dto/driverbulkjobs.dto.ts:94` | 2 |
| `CreateDriverDto` | class | `admin/dto/createdriver.dto.ts:4` | 12 |
| `CreateExecutionParams` | interface | `agent/orchestrator/execution-store.service.ts:9` | 4 |
| `CreateGeofenceDto` | class | `user/dto/geofence.dto.ts:34` | 6 |
| `CreateInventoryBulkJobDto` | class | `admin/dto/inventorybulkjobs.dto.ts:51` | 4 |
| `CreateLandmarkBulkJobDto` | class | `user/dto/landmarkbulkjobs.dto.ts:190` | 4 |
| `CreatePoiDto` | class | `user/dto/poi.dto.ts:28` | 8 |
| `CreatePricingPlanDto` | class | `admin/dto/createpricingplan.dto.ts:3` | 4 |
| `CreateRouteDto` | class | `user/dto/route.dto.ts:12` | 6 |
| `CreateShareTrackLinkDto` | class | `user/dto/sharetracklinks/create-sharetracklink.dto.ts:29` | 4 |
| `CreateSubUserDto` | class | `user/dto/subusers/create-subuser.dto.ts:3` | 7 |
| `CreateSuperAdminDto` | class | `auth/dto/superadmin.dto.ts:3` | 13 |
| `CreateTeamMemberDto` | class | `admin/dto/createteam.dto.ts:4` | 6 |
| `CreateTicketDto` | class | `user/dto/create-ticket.dto.ts:21` | 4 |
| `CreateTicketMessageDto` | class | `user/dto/create-ticket-message.dto.ts:6` | 1 |
| `CreateUserBulkJobDto` | class | `admin/dto/userbulkjobs.dto.ts:101` | 1 |
| `CreateUserDriverDto` | class | `user/dto/create-driver.dto.ts:3` | 11 |
| `CreateUserDto` | class | `admin/dto/createuser.dto.ts:4` | 12 |
| `CreateVehicleBulkJobDto` | class | `admin/dto/createvehiclebulkjob.dto.ts:40` | 3 |
| `CreateVehicleBulkJobDto` | class | `admin/dto/vehiclebulkjobs.dto.ts:63` | 4 |
| `CreateVehicleDto` | class | `admin/dto/createvehicle.dto.ts:19` | 7 |
| `CreateVehicleDto` | class | `user/dto/createvehicle.dto.ts:4` | 7 |
| `CreateVehicleSensorDto` | class | `user/dto/sensors/create-vehicle-sensor.dto.ts:3` | 5 |
| `CreditsUpdateDto` | class | `superadmin/dto/creditassign.dto.ts:3` | 2 |
| `CsvTransport` | class | `common/transports/winston-csv.transport.ts:10` | 4 |
| `CsvTransportOptions` | interface | `common/transports/winston-csv.transport.ts:5` | 2 |
| `CustomCommandDto` | class | `superadmin/dto/customcommand.dto.ts:4` | 4 |
| `CustomCommandsQueryDto` | class | `superadmin/dto/custom-commands-query.dto.ts:3` | 4 |
| `DashboardActivityLogsDto` | class | `superadmin/dto/dashboard-activity-logs.dto.ts:4` | 6 |
| `DashboardModule` | class | `dashboard/dashboard.module.ts:12` | 0 |
| `DatabaseInitializerService` | class | `database/database-initializer.service.ts:27` | 5 |
| `DatabaseModule` | class | `database/database.module.ts:9` | 0 |
| `DataRetentionCleanupService` | class | `data-retention/data-retention-cleanup.service.ts:77` | 3 |
| `DataRetentionCleanupSummary` | interface | `data-retention/data-retention-cleanup.service.ts:61` | 13 |
| `DataRetentionModule` | class | `data-retention/data-retention.module.ts:11` | 0 |
| `DataRetentionTableResult` | interface | `data-retention/data-retention-cleanup.service.ts:50` | 8 |
| `DateRange` | interface | `agent/utils/command-normalizer.ts:108` | 2 |
| `DayUtcBounds` | interface | `common/time/timezone-context.service.ts:17` | 2 |
| `DeliveryRow` | interface | `queue/notification-dispatch.worker.ts:28` | 5 |
| `DeviceAndSimDto` | class | `admin/dto/deviceandsim.dto.ts:15` | 6 |
| `DeviceCommandAgent` | class | `agent/agents/device-command.agent.ts:19` | 2 |
| `DeviceCommandDispatcherService` | class | `agent/application/device-command-dispatcher.service.ts:89` | 1 |
| `DeviceCommandLogListQuery` | interface | `common/utils/device-command-log.util.ts:13` | 2 |
| `DeviceCommandLogRecord` | interface | `common/utils/device-command-log.util.ts:23` | 22 |
| `DeviceInventoryStatusDto` | enum | `admin/dto/updatedevice.dto.ts:4` | 3 |
| `DeviceStatusEntry` | interface | `dashboard/map-vehicle-status.service.ts:21` | 3 |
| `DeviceStatusRealtimeService` | class | `realtime/device-status-realtime.service.ts:23` | 3 |
| `DeviceTypeDto` | class | `superadmin/dto/devicetype.dto.ts:4` | 5 |
| `DiagnosticsWarning` | interface | `health/health.controller.ts:28` | 4 |
| `DispatchCommandParams` | interface | `agent/application/device-command-dispatcher.service.ts:9` | 9 |
| `DispatchCommandResult` | interface | `agent/application/device-command-dispatcher.service.ts:21` | 4 |
| `DistanceReportResult` | interface | `agent/application/report-builder.service.ts:8` | 4 |
| `DocForDto` | enum | `superadmin/dto/documenttype.dto.ts:4` | 3 |
| `DocumentTypeDto` | class | `superadmin/dto/documenttype.dto.ts:10` | 2 |
| `DriverBulkJobRowDto` | class | `admin/dto/driverbulkjobs.dto.ts:16` | 12 |
| `DriverBulkJobsService` | class | `admin/driver-bulk-jobs.service.ts:134` | 1 |
| `EmailBrandCacheService` | class | `email/services/email-brand-cache.service.ts:77` | 1 |
| `EmailCatalogEntry` | interface | `email/email-events.catalog.ts:36` | 6 |
| `EmailContextResolver` | class | `email/services/email-context.resolver.ts:77` | 1 |
| `EmailModule` | class | `email/email.module.ts:33` | 0 |
| `EmailRenderError` | class | `email/services/email-renderer.service.ts:27` | 0 |
| `EmailRendererService` | class | `email/services/email-renderer.service.ts:93` | 1 |
| `EmailSenderService` | class | `comms/services/email-sender.service.ts:19` | 1 |
| `EmailService` | class | `email/email.service.ts:116` | 1 |
| `EmailSubscriptionService` | class | `email/services/email-subscription.service.ts:32` | 3 |
| `EmailTemplateCacheService` | class | `email/services/email-template-cache.service.ts:63` | 2 |
| `EmailTemplateDto` | class | `superadmin/dto/emailtemplate.dto.ts:4` | 2 |
| `EmailTemplateMissingError` | class | `email/services/email-renderer.service.ts:16` | 0 |
| `EventCandidate` | interface | `notifications/services/notification-event-detector.service.ts:67` | 9 |
| `ExecuteCommandOptions` | interface | `common/utils/executecommands.ts:21` | 5 |
| `ExecutionIdParamDto` | class | `agent/dto/execution-id-param.dto.ts:3` | 1 |
| `ExecutionRow` | interface | `agent/agent-integration.spec.ts:38` | 19 |
| `ExecutionStoreService` | class | `agent/orchestrator/execution-store.service.ts:26` | 0 |
| `ExternalServiceReadinessService` | class | `integrations/external-service-readiness.service.ts:37` | 1 |
| `FakeDb` | interface | `data-retention/data-retention-cleanup.service.spec.ts:16` | 3 |
| `FakeRedisClient` | interface | `data-retention/data-retention-cleanup.service.spec.ts:6` | 2 |
| `FakeRedisService` | interface | `data-retention/data-retention-cleanup.service.spec.ts:11` | 2 |
| `FcmDiagnostics` | interface | `common/utils/firebase-fcm.client.ts:46` | 4 |
| `FcmErrorClassification` | interface | `common/utils/firebase-fcm.client.ts:261` | 4 |
| `FcmSendResult` | interface | `common/utils/firebase-fcm.client.ts:53` | 2 |
| `FenceFixture` | interface | `notifications/services/geofence-evaluator.service.spec.ts:24` | 6 |
| `FetchProviderResult` | interface | `geocoding/geocoding.service.ts:56` | 2 |
| `FirstDayOfWeekDto` | enum | `superadmin/dto/usersetting.dto.ts:25` | 2 |
| `FleetStatusBuckets` | interface | `dashboard/fleet-status.spec.ts:39` | 7 |
| `FleetStatusBuckets` | interface | `dashboard/live-status.service.ts:45` | 7 |
| `ForgotPasswordDto` | class | `auth/dto/forgot-password.dto.ts:3` | 1 |
| `GeocodingConsolidator` | class | `geocoding/geocoding.consolidator.ts:39` | 2 |
| `GeocodingController` | class | `geocoding/geocoding.controller.ts:23` | 1 |
| `GeocodingModule` | class | `geocoding/geocoding.module.ts:6` | 0 |
| `GeocodingPrecisionDto` | enum | `superadmin/dto/softwareconfig.dto.ts:3` | 2 |
| `GeocodingService` | class | `geocoding/geocoding.service.ts:144` | 25 |
| `GeofenceBulkRowDto` | class | `user/dto/landmarkbulkjobs.dto.ts:37` | 11 |
| `GeofenceEvaluatorService` | class | `notifications/services/geofence-evaluator.service.ts:50` | 1 |
| `GeofenceLink` | interface | `notifications/services/geofence-evaluator.service.ts:20` | 6 |
| `GeofenceState` | interface | `notifications/services/geofence-evaluator.service.ts:29` | 2 |
| `GeofenceType` | enum | `user/dto/geofence.dto.ts:6` | 3 |
| `GeofenceType` | enum | `user/dto/landmarkbulkjobs.dto.ts:28` | 3 |
| `GetOrCreateAddressOpts` | interface | `geocoding/geocoding.service.ts:38` | 2 |
| `GlobalProcessingStats` | interface | `common/services/telemetry-stats.service.ts:165` | 41 |
| `GoogleLoginDto` | class | `auth/dto/google-login.dto.ts:3` | 1 |
| `HandleCommandParams` | interface | `agent/orchestrator/orchestrator.service.ts:19` | 6 |
| `HandledataController` | class | `handledata/handledata.controller.ts:4` | 0 |
| `HandledataModule` | class | `handledata/handledata.module.ts:5` | 0 |
| `HandledataService` | class | `handledata/handledata.service.ts:71` | 1 |
| `HealthController` | class | `health/health.controller.ts:35` | 1 |
| `HealthModule` | class | `health/health.module.ts:4` | 0 |
| `HistoryAnalyticsData` | interface | `common/services/telemetry-playback.service.ts:117` | 8 |
| `HistoryLoadData` | interface | `common/services/telemetry-playback.service.ts:128` | 9 |
| `HistoryPlaybackData` | interface | `common/services/telemetry-playback.service.ts:84` | 5 |
| `HistoryPlaybackPoint` | interface | `common/services/telemetry-playback.service.ts:73` | 8 |
| `HistoryRebaseManager` | class | `handledata/history-rebase-idempotency.spec.ts:43` | 4 |
| `HistorySegmentData` | interface | `common/services/telemetry-playback.service.ts:94` | 10 |
| `HistoryStopMarkerData` | interface | `common/services/telemetry-playback.service.ts:107` | 7 |
| `HistoryTimelineRow` | interface | `common/utils/telemetry-timeline.util.ts:44` | 8 |
| `IAgent` | interface | `agent/interfaces/agent.interface.ts:4` | 2 |
| `ImeiProcessingStats` | interface | `common/services/telemetry-stats.service.ts:123` | 36 |
| `InstallInfo` | interface | `superadmin/server/server.types.ts:58` | 4 |
| `InstallPaths` | interface | `superadmin/server/server.types.ts:51` | 4 |
| `IntegrationCreateDefaults` | interface | `stack/third-party-integrations.service.ts:29` | 5 |
| `IntegrationIdentity` | interface | `stack/third-party-integrations.service.ts:20` | 5 |
| `IntegrationsModule` | class | `integrations/integrations.module.ts:20` | 0 |
| `IntentRule` | interface | `agent/orchestrator/command-parser.service.ts:29` | 3 |
| `InventoryBulkJobRowDto` | class | `admin/dto/inventorybulkjobs.dto.ts:19` | 5 |
| `InventoryBulkJobsService` | class | `admin/inventory-bulk-jobs.service.ts:105` | 1 |
| `IsValidDateRange` | class | `admin/dto/calendar.dto.ts:32` | 0 |
| `IsValidDateRange` | class | `superadmin/dto/calendar.dto.ts:32` | 0 |
| `IsValidEventTypes` | class | `admin/dto/calendar.dto.ts:15` | 0 |
| `IsValidEventTypes` | class | `superadmin/dto/calendar.dto.ts:15` | 0 |
| `JwtSharedModule` | class | `auth/jwt-shared.module.ts:5` | 0 |
| `JwtStrategy` | class | `auth/strategies/jwt.strategy.ts:6` | 0 |
| `LandmarkBulkJobsService` | class | `user/landmark-bulk-jobs.service.ts:177` | 1 |
| `LandmarkEntityType` | enum | `user/dto/landmarkbulkjobs.dto.ts:22` | 3 |
| `LatencySnapshot` | interface | `common/services/telemetry-stats.service.ts:13` | 4 |
| `LayoutDirectionDto` | enum | `superadmin/dto/usersetting.dto.ts:9` | 2 |
| `LicenseCachePayload` | interface | `licensing/license.types.ts:289` | 4 |
| `LicenseService` | class | `licensing/license.service.ts:77` | 10 |
| `LicenseSnapshot` | interface | `licensing/license.types.ts:243` | 18 |
| `LicenseValidationRequest` | interface | `licensing/license.types.ts:74` | 5 |
| `LicensingModule` | class | `licensing/licensing.module.ts:4` | 0 |
| `ListOpenRouterModelsParams` | interface | `common/utils/openrouter.client.ts:46` | 3 |
| `ListShareTrackLinksDto` | class | `user/dto/sharetracklinks/list-sharetracklinks.dto.ts:3` | 3 |
| `ListThirdPartyIntegrationsQueryDto` | class | `superadmin/dto/third-party-integrations.dto.ts:25` | 4 |
| `ListWhatsAppTemplatesQueryDto` | class | `superadmin/dto/whatsapp-templates.dto.ts:63` | 4 |
| `LiveStatusBuckets` | interface | `dashboard/live-status.service.ts:24` | 6 |
| `LiveStatusBuckets` | interface | `dashboard/live-status.spec.ts:28` | 6 |
| `LiveStatusService` | class | `dashboard/live-status.service.ts:65` | 1 |
| `LocalLicenseSnapshot` | interface | `licensing/license.types.ts:198` | 12 |
| `LoggerConfig` | interface | `common/config/winston.config.ts:11` | 8 |
| `LoggerUtil` | class | `common/utils/logger.util.ts:87` | 0 |
| `LoginDto` | class | `auth/dto/login.dto.ts:4` | 2 |
| `LogsDatabaseService` | class | `database/logs-database.service.ts:11` | 1 |
| `MapEventItem` | interface | `superadmin/superadmin.service.ts:6938` | 11 |
| `MapEventsQueryDto` | class | `superadmin/dto/map-events.dto.ts:3` | 6 |
| `MapVehicleStatusService` | class | `dashboard/map-vehicle-status.service.ts:30` | 0 |
| `MarkParsedParams` | interface | `agent/orchestrator/execution-store.service.ts:16` | 5 |
| `MatchConstraint` | class | `superadmin/dto/adminpasswordupdate.dto.ts:14` | 0 |
| `MetaCredentials` | interface | `superadmin/whatsapp-templates/whatsapp-templates.service.ts:14` | 3 |
| `MetaTemplate` | interface | `superadmin/whatsapp-templates/whatsapp-templates.service.ts:20` | 6 |
| `MetricPreviousResolution` | interface | `handledata/handledata.service.ts:22` | 2 |
| `MetricSnapshot` | interface | `handledata/history-rebase-idempotency.spec.ts:21` | 9 |
| `MissingPointRow` | interface | `geocoding/geocoding.consolidator.ts:12` | 2 |
| `MockNotifLog` | interface | `queue/notification-evaluate.worker.spec.ts:32` | 9 |
| `NormalizedBugReportUser` | interface | `bug-report/bug-report.service.ts:44` | 5 |
| `NormalizedGeocodeResult` | interface | `common/utils/reverse-geocoding.client.ts:18` | 8 |
| `NotifDispatchPayload` | interface | `queue/notification-dispatch.worker.ts:22` | 1 |
| `NotificationAgent` | class | `agent/agents/notification.agent.ts:8` | 2 |
| `NotificationCacheService` | class | `notifications/notification-cache.service.ts:55` | 1 |
| `NotificationCandidate` | interface | `notifications/notification-engine.ts:38` | 6 |
| `NotificationDispatchWorker` | class | `queue/notification-dispatch.worker.ts:79` | 1 |
| `NotificationEvaluateWorker` | class | `queue/notification-evaluate.worker.ts:140` | 1 |
| `NotificationEvaluationResult` | interface | `queue/notification-evaluate.worker.ts:72` | 3 |
| `NotificationGateway` | class | `realtime/notification.gateway.ts:45` | 2 |
| `NotificationRealtimeService` | class | `realtime/notification-realtime.service.ts:20` | 3 |
| `NotificationsModule` | class | `notifications/notifications.module.ts:23` | 0 |
| `NotificationsQueryDto` | class | `superadmin/dto/notifications.dto.ts:3` | 3 |
| `OpenRouterDiagnostics` | interface | `common/utils/openrouter.client.ts:19` | 6 |
| `OpenRouterError` | interface | `common/utils/openrouter.client.ts:35` | 6 |
| `OpenRouterSuccess` | interface | `common/utils/openrouter.client.ts:28` | 4 |
| `OperatingSystem` | enum | `common/utils/identifyos.ts:7` | 4 |
| `OrchestratorService` | class | `agent/orchestrator/orchestrator.service.ts:30` | 1 |
| `OSIdentifier` | class | `common/utils/identifyos.ts:28` | 2 |
| `OSInfo` | interface | `common/utils/identifyos.ts:17` | 5 |
| `ParsedCommand` | interface | `agent/orchestrator/command-parser.service.ts:17` | 4 |
| `ParsedDeviceCommandLogQuery` | interface | `common/utils/device-command-log.util.ts:18` | 2 |
| `PermanentDispatchError` | class | `queue/notification-dispatch.worker.ts:548` | 0 |
| `PermissionResolverService` | class | `agent/orchestrator/permission-resolver.service.ts:45` | 0 |
| `PoiBulkRowDto` | class | `user/dto/landmarkbulkjobs.dto.ts:98` | 9 |
| `PoiCoordinatesDto` | class | `user/dto/poi.dto.ts:17` | 2 |
| `PolicyDto` | class | `superadmin/dto/policy.dto.ts:11` | 2 |
| `PolicyTypeDto` | enum | `superadmin/dto/policy.dto.ts:4` | 4 |
| `PoolEntry` | interface | `email/services/smtp-transport-pool.service.ts:9` | 4 |
| `PrimaryDatabaseService` | class | `database/primary-database.service.ts:11` | 1 |
| `ProfileDto` | class | `superadmin/dto/profile.dto.ts:3` | 9 |
| `ProviderChoice` | interface | `geocoding/geocoding.service.ts:46` | 5 |
| `PublicBrandingResult` | interface | `branding/branding-resolver.service.ts:13` | 13 |
| `PublicTrackController` | class | `public-track/public-track.controller.ts:14` | 0 |
| `PublicTrackModule` | class | `public-track/public-track.module.ts:7` | 0 |
| `PublicTrackService` | class | `public-track/public-track.service.ts:24` | 0 |
| `PushSenderService` | class | `comms/services/push-sender.service.ts:25` | 1 |
| `QuequeService` | class | `queue/queque.service.ts:7` | 3 |
| `QueryAgentExecutionDto` | class | `agent/dto/query-agent-execution.dto.ts:3` | 1 |
| `QueueModule` | class | `queue/queue.module.ts:13` | 0 |
| `QuickDeviceDto` | class | `admin/dto/quickdevice.dto.ts:3` | 3 |
| `RateSnapshot` | interface | `common/services/telemetry-stats.service.ts:7` | 3 |
| `RealtimeModule` | class | `realtime/realtime.module.ts:18` | 0 |
| `RebasedContribution` | interface | `handledata/handledata.service.ts:35` | 4 |
| `RebaseState` | interface | `handledata/history-rebase-idempotency.spec.ts:33` | 7 |
| `RecipientInfo` | interface | `email/services/email-context.resolver.ts:13` | 5 |
| `RecipientUser` | interface | `queue/notification-evaluate.worker.ts:38` | 8 |
| `RecordManualTransactionDto` | class | `superadmin/dto/record-manual-transaction.dto.ts:5` | 4 |
| `RedisConfig` | interface | `redis/redis.config.ts:4` | 4 |
| `RedisModule` | class | `redis/redis.module.ts:4` | 0 |
| `RedisService` | class | `redis/redis.service.ts:7` | 3 |
| `RedisStarter` | class | `common/utils/redisstart.ts:9` | 2 |
| `RefreshTokenDto` | class | `auth/dto/refresh-token.dto.ts:4` | 1 |
| `RegisterDto` | class | `auth/dto/register.dto.ts:3` | 6 |
| `RegisterPushTokenDto` | class | `auth/dto/push-token.dto.ts:7` | 4 |
| `RemoteLicenseValidationResponse` | interface | `licensing/license.types.ts:94` | 8 |
| `RemovePushTokenDto` | class | `auth/dto/push-token.dto.ts:48` | 2 |
| `RenderedEmail` | interface | `email/services/email-renderer.service.ts:65` | 3 |
| `RenderEmailInput` | interface | `email/services/email-renderer.service.ts:38` | 8 |
| `ReplayPlaybackData` | interface | `common/services/telemetry-playback.service.ts:61` | 5 |
| `ReplayPlaybackPoint` | interface | `common/services/telemetry-playback.service.ts:44` | 14 |
| `ReplayTimelineRow` | interface | `common/utils/telemetry-timeline.util.ts:34` | 7 |
| `ReplyContext` | interface | `webhooks/whatsapp-reply.service.ts:31` | 4 |
| `ReplySupportTicketDto` | class | `superadmin/dto/reply-support-ticket.dto.ts:6` | 1 |
| `ReportAgent` | class | `agent/agents/report.agent.ts:9` | 2 |
| `ReportBuilderService` | class | `agent/application/report-builder.service.ts:15` | 0 |
| `ResetPasswordDto` | class | `auth/dto/reset-password.dto.ts:3` | 2 |
| `ResolvedAddress` | interface | `geocoding/geocoding.service.ts:29` | 5 |
| `ResolvedEmailContext` | interface | `email/services/email-context.resolver.ts:34` | 3 |
| `ResolvedSmtp` | interface | `comms/types/comms.types.ts:12` | 10 |
| `ResolvedVehicle` | interface | `agent/application/vehicle-access.service.ts:14` | 9 |
| `Response` | interface | `common/interceptors/response.interceptor.ts:11` | 4 |
| `ResponseInterceptor` | class | `common/interceptors/response.interceptor.ts:18` | 0 |
| `RetentionTableConfig` | interface | `data-retention/data-retention-cleanup.service.ts:20` | 4 |
| `ReverseGeocodeDiagnostics` | interface | `common/utils/reverse-geocoding.client.ts:29` | 8 |
| `ReverseGeocodeParams` | interface | `common/utils/reverse-geocoding.client.ts:45` | 8 |
| `RoleGuardMixin` | class | `common/guards/roles.guard.ts:38` | 0 |
| `RolesGuard` | class | `common/guards/roles.guard.ts:6` | 0 |
| `RollingCounterWindow` | class | `common/services/telemetry-stats.service.ts:20` | 1 |
| `RotateThirdPartyIntegrationSecretDto` | class | `superadmin/dto/third-party-integrations.dto.ts:138` | 1 |
| `RoundedPoint` | interface | `geocoding/geocoding.service.ts:20` | 4 |
| `RouteBulkRowDto` | class | `user/dto/landmarkbulkjobs.dto.ts:152` | 6 |
| `RunVehicleSensorDto` | class | `user/dto/sensors/run-vehicle-sensor.dto.ts:3` | 2 |
| `ScreenshotDataUrlConstraint` | class | `bug-report/dto/create-bug-report.dto.ts:48` | 0 |
| `ScreenshotDataUrlSizeConstraint` | class | `bug-report/dto/create-bug-report.dto.ts:66` | 0 |
| `Semaphore` | class | `geocoding/geocoding.service.ts:116` | 2 |
| `SendCommandBulkDto` | class | `user/dto/send-command-bulk.dto.ts:19` | 5 |
| `SendCommandBulkItem` | class | `user/dto/send-command-bulk.dto.ts:9` | 2 |
| `SendCommandBulkMode` | enum | `user/dto/send-command-bulk.dto.ts:4` | 2 |
| `SendDeviceCommandDto` | class | `superadmin/dto/send-device-command.dto.ts:4` | 2 |
| `SendEmailParams` | interface | `comms/types/comms.types.ts:27` | 10 |
| `SendEmailParams` | interface | `email/email.service.ts:19` | 14 |
| `SendEmailResult` | interface | `comms/types/comms.types.ts:50` | 4 |
| `SendEmailResult` | interface | `email/email.service.ts:82` | 6 |
| `SendFcmToTokenParams` | interface | `common/utils/firebase-fcm.client.ts:21` | 8 |
| `SendPushParams` | interface | `comms/types/comms.types.ts:107` | 5 |
| `SendPushResult` | interface | `comms/types/comms.types.ts:123` | 2 |
| `SendTemplatedEmailParams` | interface | `email/email.service.ts:66` | 5 |
| `SendWhatsAppByTypeParams` | interface | `comms/types/comms.types.ts:92` | 4 |
| `SendWhatsAppMessageParams` | interface | `common/utils/whatsapp-cloud.client.ts:19` | 5 |
| `SendWhatsAppTemplateParams` | interface | `comms/types/comms.types.ts:61` | 4 |
| `SendWhatsAppTemplateResult` | interface | `comms/types/comms.types.ts:72` | 3 |
| `SendWhatsAppTextParams` | interface | `comms/types/comms.types.ts:81` | 2 |
| `SensorRunnerService` | class | `user/services/sensor-runner.service.ts:20` | 2 |
| `SerializedDeviceCommandLog` | interface | `common/utils/device-command-log.util.ts:48` | 22 |
| `ServerActionDto` | class | `superadmin/server/dto/server-action.dto.ts:79` | 2 |
| `ServerActionRulesConstraint` | class | `superadmin/server/dto/server-action.dto.ts:23` | 0 |
| `ServerActionsService` | class | `superadmin/server/server-actions.service.ts:43` | 1 |
| `ServerController` | class | `superadmin/server/server.controller.ts:12` | 0 |
| `ServerMonitorService` | class | `superadmin/server/server-monitor.service.ts:40` | 6 |
| `ServerOverviewResponse` | interface | `superadmin/server/server.types.ts:65` | 5 |
| `SimCardDto` | class | `admin/dto/sim.dto.ts:8` | 6 |
| `SimProviderDto` | class | `superadmin/dto/simprociders.dto.ts:4` | 5 |
| `SmtpCacheService` | class | `email/services/smtp-cache.service.ts:60` | 1 |
| `SmtpResolution` | interface | `email/services/email-context.resolver.ts:22` | 3 |
| `SmtpResolverInput` | interface | `comms/services/smtp-resolver.service.ts:10` | 2 |
| `SmtpResolverService` | class | `comms/services/smtp-resolver.service.ts:30` | 1 |
| `SmtpSecurity` | enum | `admin/dto/updatesmtpconfig.dto.ts:12` | 3 |
| `SmtpSecurity` | enum | `superadmin/dto/smtp.dto.ts:12` | 3 |
| `SmtpSettingDto` | class | `superadmin/dto/smtp.dto.ts:19` | 9 |
| `SmtpTransportPoolService` | class | `email/services/smtp-transport-pool.service.ts:55` | 3 |
| `SoftwareConfigDto` | class | `superadmin/dto/softwareconfig.dto.ts:9` | 5 |
| `SseStreamOptions` | interface | `common/utils/sse-stream.ts:30` | 1 |
| `SslAction` | enum | `ssl/dto/ssl.dto.ts:3` | 2 |
| `SslController` | class | `ssl/ssl.controller.ts:24` | 0 |
| `SslInstallDto` | class | `ssl/dto/ssl.dto.ts:8` | 4 |
| `SslJobState` | interface | `ssl/ssl.service.ts:25` | 9 |
| `SslModule` | class | `ssl/ssl.module.ts:6` | 0 |
| `SslService` | class | `ssl/ssl.service.ts:55` | 11 |
| `SslStatusInfo` | interface | `ssl/ssl.service.ts:13` | 9 |
| `SslStreamController` | class | `ssl/ssl.controller.ts:66` | 0 |
| `StackModule` | class | `stack/stack.module.ts:20` | 0 |
| `StackprocessWorker` | class | `queue/stackprocess.worker.ts:16` | 1 |
| `StackService` | class | `stack/stack.service.ts:46` | 8 |
| `Status` | enum | `common/enums/status.enum.ts:1` | 3 |
| `StoredOtpState` | interface | `communications/verification/verification.service.ts:34` | 3 |
| `StoredOtpState` | interface | `verification/verification.service.ts:16` | 3 |
| `StructuredCommandPayload` | class | `agent/dto/create-agent-command.dto.ts:11` | 5 |
| `SuperadminController` | class | `superadmin/superadmin.controller.ts:60` | 0 |
| `SuperadminModule` | class | `superadmin/superadmin.module.ts:18` | 0 |
| `SuperadminService` | class | `superadmin/superadmin.service.ts:113` | 2 |
| `SyncResultItem` | interface | `superadmin/whatsapp-templates/whatsapp-templates.service.ts:29` | 7 |
| `SyncWhatsAppTemplatesDto` | class | `superadmin/dto/whatsapp-templates.dto.ts:48` | 2 |
| `SystemMetrics` | interface | `superadmin/server/server.types.ts:22` | 7 |
| `SystemVariableDto` | class | `superadmin/dto/systemvariable.dto.ts:4` | 2 |
| `TelemetryGateway` | class | `realtime/telemetry.gateway.ts:49` | 3 |
| `TelemetryGpsCandidate` | interface | `handledata/types/telemetry-normalizer.ts:12` | 4 |
| `TelemetryHistoryDependencyError` | class | `handledata/errors/telemetry-history-dependency.error.ts:8` | 3 |
| `TelemetryInput` | interface | `notifications/services/notification-event-detector.service.ts:45` | 10 |
| `TelemetryLockContentionError` | class | `handledata/errors/telemetry-lock-contention.error.ts:9` | 1 |
| `TelemetryMetricComputation` | interface | `stack/telemetry-metric-computation.ts:42` | 10 |
| `TelemetryMetricPacket` | interface | `stack/telemetry-metric-computation.ts:11` | 11 |
| `TelemetryMetricPolicy` | interface | `stack/telemetry-metric-computation.ts:1` | 7 |
| `TelemetryOrigin` | interface | `handledata/types/telemetry-normalizer.ts:19` | 8 |
| `TelemetryPlaybackService` | class | `common/services/telemetry-playback.service.ts:160` | 2 |
| `TelemetryRealtimeService` | class | `realtime/telemetry-realtime.service.ts:58` | 3 |
| `TelemetryRecord` | interface | `realtime/types/telemetry-record.ts:6` | 22 |
| `TelemetrySnapshot` | interface | `agent/agents/vehicle-data.agent.ts:10` | 6 |
| `TelemetrySnapshot` | interface | `notifications/notification-engine.ts:64` | 8 |
| `TelemetryStatsModule` | class | `common/modules/telemetry-stats.module.ts:4` | 0 |
| `TelemetryStatsService` | class | `common/services/telemetry-stats.service.ts:269` | 7 |
| `TemplateVars` | interface | `notifications/whatsapp-templates.local.ts:21` | 6 |
| `TenantBrandingService` | class | `branding/tenant-branding.service.ts:45` | 0 |
| `TestEmailDto` | class | `auth/dto/email-test.dto.ts:7` | 2 |
| `TestFcmIntegrationDto` | class | `superadmin/dto/third-party-integrations.dto.ts:151` | 4 |
| `TestFcmToMeDto` | class | `superadmin/dto/third-party-integrations.dto.ts:179` | 2 |
| `TestOpenRouterChatParams` | interface | `common/utils/openrouter.client.ts:55` | 5 |
| `TestOpenRouterIntegrationDto` | class | `superadmin/dto/third-party-integrations.dto.ts:234` | 2 |
| `TestPushDto` | class | `auth/dto/push-token.dto.ts:32` | 2 |
| `TestWhatsAppIntegrationDto` | class | `superadmin/dto/third-party-integrations.dto.ts:197` | 5 |
| `ThemeModeDto` | enum | `superadmin/dto/usersetting.dto.ts:14` | 3 |
| `ThirdPartyIntegrationsService` | class | `stack/third-party-integrations.service.ts:53` | 2 |
| `TicketCategoryEnum` | enum | `admin/dto/admin-create-ticket.dto.ts:4` | 6 |
| `TicketCategoryEnum` | enum | `user/dto/create-ticket.dto.ts:3` | 6 |
| `TicketPriorityEnum` | enum | `admin/dto/admin-create-ticket.dto.ts:13` | 3 |
| `TicketPriorityEnum` | enum | `user/dto/create-ticket.dto.ts:12` | 3 |
| `TicketStatusEnum` | enum | `admin/dto/admin-update-ticket-status.dto.ts:3` | 3 |
| `TicketStatusEnum` | enum | `superadmin/dto/update-support-ticket-status.dto.ts:3` | 3 |
| `TimelineCountParams` | interface | `common/utils/telemetry-timeline.util.ts:13` | 3 |
| `TimelineQueryParams` | interface | `common/utils/telemetry-timeline.util.ts:6` | 4 |
| `TimelineStampedValue` | interface | `common/utils/telemetry-timeline.util.ts:19` | 2 |
| `TimeRange` | interface | `common/services/telemetry-playback.service.ts:20` | 2 |
| `TimezoneContext` | interface | `common/time/timezone-context.service.ts:8` | 3 |
| `TimezoneContextModule` | class | `common/time/timezone-context.module.ts:4` | 0 |
| `TimezoneContextService` | class | `common/time/timezone-context.service.ts:41` | 4 |
| `TopbarSearchAction` | interface | `topbar-search/dto/topbar-search.dto.ts:50` | 9 |
| `TopbarSearchGroup` | interface | `topbar-search/dto/topbar-search.dto.ts:73` | 3 |
| `TopbarSearchModule` | class | `topbar-search/topbar-search.module.ts:4` | 0 |
| `TopbarSearchQueryDto` | class | `topbar-search/dto/topbar-search.dto.ts:13` | 2 |
| `TopbarSearchResult` | interface | `topbar-search/dto/topbar-search.dto.ts:62` | 8 |
| `TopbarSearchService` | class | `topbar-search/topbar-search.service.ts:32` | 0 |
| `TraceContext` | interface | `handledata/types/telemetry-normalizer.ts:96` | 9 |
| `TrailPlaybackData` | interface | `common/services/telemetry-playback.service.ts:36` | 5 |
| `TrailPlaybackPoint` | interface | `common/services/telemetry-playback.service.ts:25` | 8 |
| `TrailTimelineRow` | interface | `common/utils/telemetry-timeline.util.ts:24` | 7 |
| `UnassignSubUserVehiclesDto` | class | `user/dto/subusers/unassign-subuser-vehicles.dto.ts:3` | 1 |
| `UnitsDto` | enum | `superadmin/dto/usersetting.dto.ts:20` | 2 |
| `UpdateAdminDto` | class | `superadmin/dto/updateadmin.dto.ts:3` | 9 |
| `UpdateCompanyDto` | class | `admin/dto/updatecompany.dto.ts:8` | 7 |
| `UpdateDashboardDto` | class | `user/dto/dashboard.dto.ts:9` | 3 |
| `UpdateDeviceDto` | class | `admin/dto/updatedevice.dto.ts:10` | 4 |
| `UpdateDocDto` | class | `superadmin/dto/updatedoc.dto.ts:4` | 10 |
| `UpdateDriverDto` | class | `admin/dto/updatedriver.dto.ts:3` | 13 |
| `UpdateGeofenceDto` | class | `user/dto/geofence.dto.ts:60` | 6 |
| `UpdatePasswordDto` | class | `superadmin/dto/updatepassword.dto.ts:4` | 2 |
| `UpdatePoiDto` | class | `user/dto/poi.dto.ts:68` | 8 |
| `UpdateRouteDto` | class | `user/dto/route.dto.ts:40` | 6 |
| `UpdateSettingsStateDto` | class | `superadmin/dto/usersetting.dto.ts:64` | 10 |
| `UpdateShareTrackLinkDto` | class | `user/dto/sharetracklinks/update-sharetracklink.dto.ts:29` | 5 |
| `UpdateSmtpConfigDto` | class | `admin/dto/updatesmtpconfig.dto.ts:19` | 9 |
| `UpdateSubUserDto` | class | `user/dto/subusers/update-subuser.dto.ts:3` | 7 |
| `UpdateSupportTicketStatusDto` | class | `superadmin/dto/update-support-ticket-status.dto.ts:9` | 1 |
| `UpdateTeamMemberDto` | class | `admin/dto/updateteam.dto.ts:4` | 7 |
| `UpdateThirdPartyIntegrationDto` | class | `superadmin/dto/third-party-integrations.dto.ts:107` | 5 |
| `UpdateUserDriverDto` | class | `user/dto/update-driver.dto.ts:3` | 13 |
| `UpdateUserDto` | class | `admin/dto/updateuser.dto.ts:8` | 14 |
| `UpdateUserVehicleDto` | class | `user/dto/update-vehicle.dto.ts:33` | 6 |
| `UpdateVehicleConfigDto` | class | `admin/dto/update-vehicle-config.dto.ts:17` | 5 |
| `UpdateVehicleConfigDto` | class | `user/dto/update-vehicle-config.dto.ts:17` | 5 |
| `UpdateVehicleDto` | class | `admin/dto/updatevehicle.dto.ts:37` | 9 |
| `UpdateVehicleSensorDto` | class | `user/dto/sensors/update-vehicle-sensor.dto.ts:3` | 5 |
| `UpdateWhatsAppTemplateDto` | class | `superadmin/dto/whatsapp-templates.dto.ts:16` | 5 |
| `UploadDocDto` | class | `superadmin/dto/uploaddoc.dto.ts:9` | 12 |
| `UpsertThirdPartyIntegrationDto` | class | `superadmin/dto/third-party-integrations.dto.ts:51` | 10 |
| `UserActivityLogsDto` | class | `admin/dto/user-activity-logs.dto.ts:4` | 6 |
| `UserBulkJobRowDto` | class | `admin/dto/userbulkjobs.dto.ts:16` | 13 |
| `UserBulkJobsService` | class | `admin/user-bulk-jobs.service.ts:134` | 1 |
| `UserController` | class | `user/user.controller.ts:49` | 0 |
| `UserModule` | class | `user/user.module.ts:14` | 0 |
| `UserService` | class | `user/user.service.ts:59` | 5 |
| `UserSettingsDto` | class | `superadmin/dto/usersetting.dto.ts:30` | 10 |
| `ValidateFtkeyDto` | class | `superadmin/dto/ftkey.dto.ts:3` | 1 |
| `ValidateGeocodingIntegrationDto` | class | `superadmin/dto/third-party-integrations.dto.ts:264` | 4 |
| `ValidateGoogleSsoDto` | class | `superadmin/dto/third-party-integrations.dto.ts:252` | 1 |
| `VehicleAccessService` | class | `agent/application/vehicle-access.service.ts:26` | 1 |
| `VehicleBulkJobRowDto` | class | `admin/dto/vehiclebulkjobs.dto.ts:16` | 7 |
| `VehicleBulkJobsService` | class | `admin/vehicle-bulk-jobs.service.ts:119` | 1 |
| `VehicleBulkRowDto` | class | `admin/dto/createvehiclebulkjob.dto.ts:13` | 6 |
| `VehicleDataAgent` | class | `agent/agents/vehicle-data.agent.ts:19` | 2 |
| `VehicleLicenseAdmission` | interface | `handledata/handledata.service.ts:29` | 3 |
| `VehicleRefParams` | interface | `agent/application/vehicle-access.service.ts:5` | 6 |
| `VehicleTypeDto` | class | `superadmin/dto/vehicletype.dto.ts:4` | 2 |
| `VerificationModule` | class | `verification/verification.module.ts:16` | 0 |
| `VerificationService` | class | `verification/verification.service.ts:42` | 6 |
| `VerifyOtpDto` | class | `verification/dto/verify-otp.dto.ts:9` | 1 |
| `WebhooksModule` | class | `webhooks/webhooks.module.ts:13` | 0 |
| `WhatsAppApiError` | interface | `common/utils/whatsapp-cloud.client.ts:55` | 7 |
| `WhatsAppApiSuccess` | interface | `common/utils/whatsapp-cloud.client.ts:47` | 5 |
| `WhatsAppDiagnostics` | interface | `common/utils/whatsapp-cloud.client.ts:36` | 8 |
| `WhatsAppGatewayResult` | interface | `communications/whatsapp/whatsapp-gateway.service.ts:33` | 5 |
| `WhatsAppGatewayService` | class | `communications/whatsapp/whatsapp-gateway.service.ts:71` | 1 |
| `WhatsAppModule` | class | `communications/whatsapp/whatsapp.module.ts:10` | 0 |
| `WhatsappReplyService` | class | `webhooks/whatsapp-reply.service.ts:53` | 1 |
| `WhatsAppSenderService` | class | `comms/services/whatsapp-sender.service.ts:45` | 1 |
| `WhatsAppTemplatesController` | class | `superadmin/whatsapp-templates/whatsapp-templates.controller.ts:24` | 0 |
| `WhatsAppTemplatesModule` | class | `superadmin/whatsapp-templates/whatsapp-templates.module.ts:6` | 0 |
| `WhatsAppTemplatesService` | class | `superadmin/whatsapp-templates/whatsapp-templates.service.ts:41` | 1 |
| `WhatsappWebhookController` | class | `webhooks/whatsapp-webhook.controller.ts:80` | 1 |
| `WhatsappWebhookService` | class | `webhooks/whatsapp-webhook.service.ts:13` | 1 |
| `WinstonLoggerService` | class | `common/services/winston-logger.service.ts:4` | 0 |
| `WireTraceEvent` | interface | `common/services/wire-trace.service.ts:28` | 24 |
| `WireTraceEventInput` | interface | `common/services/wire-trace.service.ts:74` | 2 |
| `WireTraceModule` | class | `common/modules/wire-trace.module.ts:4` | 0 |
| `WireTraceService` | class | `common/services/wire-trace.service.ts:82` | 4 |
| `WireTraceSessionSummary` | interface | `common/services/wire-trace.service.ts:55` | 16 |
