class SuperadminServerOverview {
  const SuperadminServerOverview({
    required this.checkedAt,
    required this.isAgentOnline,
    required this.agentStatusText,
    required this.cpuPercent,
    required this.cpuLoadText,
    required this.memoryPercent,
    required this.memoryUsedGb,
    required this.memoryTotalGb,
    required this.diskPercent,
    required this.diskUsedGb,
    required this.diskTotalGb,
    required this.diskLabel,
    required this.serverUptimeText,
    required this.components,
  });

  final DateTime? checkedAt;
  final bool isAgentOnline;
  final String agentStatusText;
  final double? cpuPercent;
  final String cpuLoadText;
  final double? memoryPercent;
  final double? memoryUsedGb;
  final double? memoryTotalGb;
  final double? diskPercent;
  final double? diskUsedGb;
  final double? diskTotalGb;
  final String diskLabel;
  final String serverUptimeText;
  final List<SuperadminServerComponent> components;

  factory SuperadminServerOverview.fromJson(dynamic json) {
    final map = _asMap(json);
    final metrics = _firstMap(
          map,
          const [
            'systemMetrics',
            'system',
            'metrics',
            'monitor',
            'overview',
          ],
        ) ??
        const <String, dynamic>{};
    final agent = _firstMap(
          map,
          const ['localAgent', 'agent', 'agentStatus'],
        ) ??
        _firstMap(
          metrics,
          const ['localAgent', 'agent', 'agentStatus'],
        ) ??
        const <String, dynamic>{};
    final memoryMetric = _extractMemoryMetric(map, metrics);
    final diskMetric = _extractDiskMetric(map, metrics);

    final components = _mergeWithDefaults(_extractComponents(map, metrics));
    final listener = _componentById(components, 'listener');
    final rawAgentOnline = _firstBool(
          agent,
          const ['online', 'isOnline', 'connected', 'healthy', 'running'],
        ) ??
        ((_firstBool(agent, const ['offline', 'isOffline']) == true)
            ? false
            : null);

    return SuperadminServerOverview(
      checkedAt: _firstDateTime(
            map,
            const [
              'checkedAt',
              'lastCheckedAt',
              'lastCheckAt',
              'updatedAt',
              'generatedAt',
              'timestamp',
            ],
          ) ??
          _firstDateTime(
            metrics,
            const [
              'checkedAt',
              'lastCheckedAt',
              'lastCheckAt',
              'updatedAt',
              'generatedAt',
              'timestamp',
            ],
          ),
      isAgentOnline: rawAgentOnline ??
          switch (listener?.status ?? SuperadminServerComponentStatus.unknown) {
            SuperadminServerComponentStatus.running => true,
            SuperadminServerComponentStatus.degraded => true,
            SuperadminServerComponentStatus.stopped => false,
            SuperadminServerComponentStatus.offline => false,
            SuperadminServerComponentStatus.unknown => false,
          },
      agentStatusText: _firstString(
            agent,
            const ['label', 'status', 'state', 'message'],
          ) ??
          (rawAgentOnline == true ? 'Online' : 'Offline'),
      cpuPercent: _extractCpuPercent(map, metrics),
      cpuLoadText: _extractCpuLoadText(map, metrics),
      memoryPercent: memoryMetric.percent,
      memoryUsedGb: memoryMetric.usedGb,
      memoryTotalGb: memoryMetric.totalGb,
      diskPercent: diskMetric.percent,
      diskUsedGb: diskMetric.usedGb,
      diskTotalGb: diskMetric.totalGb,
      diskLabel: diskMetric.label ?? 'Disk',
      serverUptimeText: _extractServerUptimeText(map, metrics),
      components: components,
    );
  }

  factory SuperadminServerOverview.mock() {
    return SuperadminServerOverview(
      checkedAt: DateTime(2026, 5, 15, 10, 47),
      isAgentOnline: false,
      agentStatusText: 'Offline',
      cpuPercent: 0,
      cpuLoadText: '2c • 0.00 / 0.00 / 0.00',
      memoryPercent: 33,
      memoryUsedGb: 2.6,
      memoryTotalGb: 7.9,
      diskPercent: 36,
      diskUsedGb: 36.4,
      diskTotalGb: 100,
      diskLabel: 'C:',
      serverUptimeText: '13d 19h 6m',
      components: <SuperadminServerComponent>[
        const SuperadminServerComponent(
          id: 'frontend',
          name: 'Frontend',
          description: 'Next.js UI (this app)',
          status: SuperadminServerComponentStatus.running,
          pid: 4656,
          ports: <int>[3000],
          uptimeText: '1d 22h 19m',
          statusMessage: 'Frontend status endpoint healthy',
          availableActions: <String>['start', 'restart'],
        ),
        const SuperadminServerComponent(
          id: 'backend',
          name: 'Backend',
          description: 'Core API service',
          status: SuperadminServerComponentStatus.running,
          pid: 5520,
          ports: <int>[4000],
          uptimeText: '7d 17h 48m',
          statusMessage: 'Backend status endpoint healthy',
          availableActions: <String>['restart'],
        ),
        const SuperadminServerComponent(
          id: 'listener',
          name: 'Listener',
          description: 'Background listener service',
          status: SuperadminServerComponentStatus.stopped,
          pid: null,
          ports: <int>[5055, 5005],
          uptimeText: '—',
          statusMessage: 'No listener on ports 5055/5005',
          availableActions: <String>['start', 'restart'],
        ),
        const SuperadminServerComponent(
          id: 'nginx',
          name: 'Nginx',
          description: 'Reverse proxy and edge gateway',
          status: SuperadminServerComponentStatus.running,
          pid: 412,
          ports: <int>[80, 443],
          uptimeText: '13d 19h 4m',
          statusMessage: 'nginx process and listener port detected',
          availableActions: <String>['start', 'restart', 'reload'],
        ),
        const SuperadminServerComponent(
          id: 'redis',
          name: 'Redis',
          description: 'Cache / queue backing store',
          status: SuperadminServerComponentStatus.running,
          pid: 2528,
          ports: <int>[6379],
          uptimeText: '13d 19h 6m',
          statusMessage: 'Redis ping healthy and port 6379 listening',
          availableActions: <String>['restart'],
        ),
        const SuperadminServerComponent(
          id: 'postgresql',
          name: 'PostgreSQL',
          description: 'Primary data store',
          status: SuperadminServerComponentStatus.running,
          pid: 3348,
          ports: <int>[5432],
          uptimeText: '13d 19h 6m',
          statusMessage: 'Primary database healthy and port 5432 listening',
          availableActions: <String>['restart'],
        ),
      ],
    );
  }

  SuperadminServerComponent? componentById(String componentId) {
    return _componentById(components, componentId);
  }
}

enum SuperadminServerComponentStatus {
  running,
  stopped,
  degraded,
  offline,
  unknown;

  String get label {
    switch (this) {
      case SuperadminServerComponentStatus.running:
        return 'Running';
      case SuperadminServerComponentStatus.stopped:
        return 'Stopped';
      case SuperadminServerComponentStatus.degraded:
        return 'Degraded';
      case SuperadminServerComponentStatus.offline:
        return 'Offline';
      case SuperadminServerComponentStatus.unknown:
        return 'Unknown';
    }
  }
}

class SuperadminServerComponent {
  const SuperadminServerComponent({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.pid,
    required this.ports,
    required this.uptimeText,
    required this.statusMessage,
    required this.availableActions,
  });

  final String id;
  final String name;
  final String description;
  final SuperadminServerComponentStatus status;
  final int? pid;
  final List<int> ports;
  final String uptimeText;
  final String statusMessage;
  final List<String> availableActions;

  factory SuperadminServerComponent.fromJson(
    dynamic json, {
    String? fallbackId,
  }) {
    final map = _asMap(json);
    final nested = _firstMap(
          map,
          const ['component', 'service', 'runtime', 'details', 'meta'],
        ) ??
        const <String, dynamic>{};
    final id = _normalizeComponentId(
      _firstString(
            map,
            const [
              'id',
              'componentId',
              'serviceId',
              'key',
              'serviceKey',
              'slug',
            ],
          ) ??
          _firstString(
            nested,
            const [
              'id',
              'componentId',
              'serviceId',
              'key',
              'serviceKey',
              'slug',
            ],
          ) ??
          fallbackId ??
          _firstString(map, const ['name', 'title', 'label']) ??
          '',
    );

    final actions = _extractStringList(
      map,
      const ['actions', 'availableActions', 'allowedActions'],
    );

    return SuperadminServerComponent(
      id: id,
      name: _firstString(map, const ['name', 'title', 'label']) ??
          _firstString(nested, const ['name', 'title', 'label']) ??
          _defaultComponentName(id),
      description: _firstString(
            map,
            const ['description', 'subtitle', 'summary', 'serviceDescription'],
          ) ??
          _firstString(
            nested,
            const ['description', 'subtitle', 'summary', 'serviceDescription'],
          ) ??
          _defaultComponentDescription(id),
      status: _extractComponentStatus(map, nested),
      pid: _firstInt(map, const ['pid', 'processId', 'process_id']) ??
          _firstInt(nested, const ['pid', 'processId', 'process_id']),
      ports: _extractIntList(
        map,
        const ['ports', 'listenPorts', 'listeningPorts', 'port'],
      ).isNotEmpty
          ? _extractIntList(
              map,
              const ['ports', 'listenPorts', 'listeningPorts', 'port'],
            )
          : _extractIntList(
              nested,
              const ['ports', 'listenPorts', 'listeningPorts', 'port'],
            ),
      uptimeText: _firstString(
            map,
            const ['uptimeHuman', 'uptimeText', 'uptime', 'upTime'],
          ) ??
          _firstString(
            nested,
            const ['uptimeHuman', 'uptimeText', 'uptime', 'upTime'],
          ) ??
          _formatDurationText(
            _firstInt(
                  map,
                  const ['uptimeSeconds', 'uptimeSec', 'uptime_seconds'],
                ) ??
                _firstInt(
                  nested,
                  const [
                    'uptimeSeconds',
                    'uptimeSec',
                    'uptime_seconds',
                  ],
                ),
          ) ??
          '—',
      statusMessage: _firstString(
            map,
            const ['statusMessage', 'healthMessage', 'message', 'detail'],
          ) ??
          _firstString(
            nested,
            const ['statusMessage', 'healthMessage', 'message', 'detail'],
          ) ??
          'No status details available',
      availableActions: actions.isNotEmpty
          ? actions
              .map(_normalizeAction)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : _defaultActionsForComponent(id),
    );
  }

  String get pidText => pid == null ? '—' : pid.toString();

  String get portsText {
    if (ports.isEmpty) {
      return '—';
    }
    return ports.join(', ');
  }
}

enum SuperadminServerJobStatus {
  queued,
  running,
  success,
  failed,
  unknown;

  String get label {
    switch (this) {
      case SuperadminServerJobStatus.queued:
        return 'Queued';
      case SuperadminServerJobStatus.running:
        return 'Running';
      case SuperadminServerJobStatus.success:
        return 'Completed';
      case SuperadminServerJobStatus.failed:
        return 'Failed';
      case SuperadminServerJobStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isTerminal {
    return this == SuperadminServerJobStatus.success ||
        this == SuperadminServerJobStatus.failed;
  }
}

class SuperadminServerJob {
  const SuperadminServerJob({
    required this.id,
    required this.componentId,
    required this.componentName,
    required this.action,
    required this.status,
    required this.message,
    required this.updatedAt,
    required this.logLines,
  });

  final String id;
  final String componentId;
  final String componentName;
  final String action;
  final SuperadminServerJobStatus status;
  final String message;
  final DateTime? updatedAt;
  final List<String> logLines;

  factory SuperadminServerJob.fromJson(
    dynamic json, {
    String? fallbackId,
    String? fallbackComponentId,
    String? fallbackComponentName,
    String? fallbackAction,
    String? fallbackMessage,
  }) {
    final map = _asMap(json);
    final nested = _firstMap(
          map,
          const ['job', 'data', 'result', 'payload'],
        ) ??
        const <String, dynamic>{};
    final status = _extractJobStatus(map, nested);
    final action = _normalizeAction(
      _firstString(
            map,
            const ['action', 'actionType', 'type', 'jobAction'],
          ) ??
          _firstString(
            nested,
            const ['action', 'actionType', 'type', 'jobAction'],
          ) ??
          fallbackAction ??
          '',
    );
    final componentId = _normalizeComponentId(
      _firstString(
            map,
            const [
              'componentId',
              'serviceId',
              'component',
              'service',
              'target',
            ],
          ) ??
          _firstString(
            nested,
            const [
              'componentId',
              'serviceId',
              'component',
              'service',
              'target',
            ],
          ) ??
          fallbackComponentId ??
          '',
    );
    final logs = _extractLogLines(map, nested);
    final message = _firstString(
          map,
          const ['message', 'statusMessage', 'detail', 'error'],
        ) ??
        _firstString(
          nested,
          const ['message', 'statusMessage', 'detail', 'error'],
        ) ??
        fallbackMessage ??
        (logs.isNotEmpty ? logs.last : '');

    return SuperadminServerJob(
      id: _firstString(map, const ['id', 'jobId']) ??
          _firstString(nested, const ['id', 'jobId']) ??
          fallbackId ??
          '',
      componentId: componentId,
      componentName: _firstString(
            map,
            const ['componentName', 'serviceName', 'componentLabel'],
          ) ??
          _firstString(
            nested,
            const ['componentName', 'serviceName', 'componentLabel'],
          ) ??
          fallbackComponentName ??
          _defaultComponentName(componentId),
      action: action,
      status: status,
      message: message,
      updatedAt: _firstDateTime(
            map,
            const [
              'updatedAt',
              'lastUpdatedAt',
              'createdAt',
              'startedAt',
              'timestamp',
            ],
          ) ??
          _firstDateTime(
            nested,
            const [
              'updatedAt',
              'lastUpdatedAt',
              'createdAt',
              'startedAt',
              'timestamp',
            ],
          ),
      logLines: logs,
    );
  }

  SuperadminServerJob copyWith({
    String? id,
    String? componentId,
    String? componentName,
    String? action,
    SuperadminServerJobStatus? status,
    String? message,
    DateTime? updatedAt,
    List<String>? logLines,
  }) {
    return SuperadminServerJob(
      id: id ?? this.id,
      componentId: componentId ?? this.componentId,
      componentName: componentName ?? this.componentName,
      action: action ?? this.action,
      status: status ?? this.status,
      message: message ?? this.message,
      updatedAt: updatedAt ?? this.updatedAt,
      logLines: logLines ?? this.logLines,
    );
  }

  SuperadminServerJob merge(SuperadminServerJob next) {
    final mergedLogs = <String>{
      ...logLines.where((value) => value.trim().isNotEmpty),
      ...next.logLines.where((value) => value.trim().isNotEmpty),
    }.toList(growable: false);

    return SuperadminServerJob(
      id: next.id.isNotEmpty ? next.id : id,
      componentId: next.componentId.isNotEmpty ? next.componentId : componentId,
      componentName:
          next.componentName.isNotEmpty ? next.componentName : componentName,
      action: next.action.isNotEmpty ? next.action : action,
      status: next.status != SuperadminServerJobStatus.unknown
          ? next.status
          : status,
      message: next.message.isNotEmpty ? next.message : message,
      updatedAt: next.updatedAt ?? updatedAt,
      logLines: mergedLogs,
    );
  }

  bool get isTerminal => status.isTerminal;

  String get displayMessage {
    if (message.trim().isNotEmpty) {
      return message.trim();
    }

    if (logLines.isNotEmpty) {
      return logLines.last;
    }

    return '${_titleCase(action.isEmpty ? 'action' : action)} ${status.label.toLowerCase()}';
  }
}

double? _extractCpuPercent(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  final cpu = _firstMap(map, const ['cpu']) ??
      _firstMap(metrics, const ['cpu']) ??
      const <String, dynamic>{};

  final rawPct = _firstDouble(
    cpu,
    const ['usagePct', 'cpuPct', 'pct'],
  );
  if (rawPct != null) {
    return rawPct.clamp(0, 100);
  }

  return _normalizePercent(
    _firstDouble(
          cpu,
          const [
            'usagePercent',
            'usage',
            'percent',
            'loadPercent',
            'value',
          ],
        ) ??
        _firstDouble(
          metrics,
          const ['cpuPercent', 'cpuUsage', 'cpuUsagePercent', 'cpuUsagePct'],
        ) ??
        _firstDouble(
          map,
          const ['cpuPercent', 'cpuUsage', 'cpuUsagePercent', 'cpuUsagePct'],
        ),
  );
}

String _extractCpuLoadText(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  final cpu = _firstMap(map, const ['cpu']) ??
      _firstMap(metrics, const ['cpu']) ??
      const <String, dynamic>{};
  final explicit = _firstString(
        cpu,
        const ['loadText', 'loadAverageText', 'subtitle', 'meta'],
      ) ??
      _firstString(
        metrics,
        const ['cpuLoadText', 'cpuLoadAverageText'],
      );
  if (explicit != null && explicit.trim().isNotEmpty) {
    return explicit.trim();
  }

  final cores = _firstInt(cpu, const ['cores', 'coreCount', 'cpuCount']) ??
      _firstInt(metrics, const ['cpuCores', 'coreCount']);
  var loadValues = _extractNumericSeries(
    cpu,
    const ['loads', 'loadAverage', 'loadAverages', 'loadavg'],
  );

  if (loadValues.isEmpty) {
    final l1 = _firstDouble(cpu, const ['load1', 'loadAvg1']);
    final l5 = _firstDouble(cpu, const ['load5', 'loadAvg5']);
    final l15 = _firstDouble(cpu, const ['load15', 'loadAvg15']);
    if (l1 != null || l5 != null || l15 != null) {
      loadValues = [l1 ?? 0, l5 ?? 0, l15 ?? 0];
    }
  }

  final segments = <String>[];
  if (cores != null && cores > 0) {
    segments.add('${cores}c');
  }
  if (loadValues.isNotEmpty) {
    segments.add(loadValues.map(_formatOneDecimal).join(' / '));
  }

  return segments.isEmpty ? '—' : segments.join(' • ');
}

_StorageMetricSnapshot _extractMemoryMetric(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  final memory = _firstMap(map, const ['memory', 'ram']) ??
      _firstMap(metrics, const ['memory', 'ram']) ??
      const <String, dynamic>{};
  final summaryPair = _extractSizePairFromSources(
    <Map<String, dynamic>>[memory, metrics, map],
    const [
      'summary',
      'usageText',
      'display',
      'valueText',
      'memorySummary',
      'memoryUsageText',
      'memoryDisplay',
    ],
  );

  final usedGb = _extractSizeInGbFromSource(
        memory,
        kind: _StorageMetricKind.memory,
        byteKeys: const [
          'usedBytes',
          'used_bytes',
          'usedMemoryBytes',
          'bytesUsed',
        ],
        kbKeys: const ['usedKb', 'usedKB', 'usedKiB'],
        mbKeys: const ['usedMb', 'usedMB', 'usedMiB'],
        gbKeys: const ['usedGb', 'usedGB', 'usedGiB'],
        tbKeys: const ['usedTb', 'usedTB', 'usedTiB'],
        genericKeys: const ['used', 'usedValue', 'valueUsed', 'usageValue'],
        unitKeys: const [
          'usedUnit',
          'unit',
          'memoryUnit',
          'displayUnit',
        ],
      ) ??
      _extractSizeInGbFromSource(
        metrics,
        kind: _StorageMetricKind.memory,
        byteKeys: const ['memoryUsedBytes', 'usedMemoryBytes'],
        kbKeys: const ['memoryUsedKb', 'usedMemoryKb'],
        mbKeys: const ['memoryUsedMb', 'usedMemoryMb'],
        gbKeys: const ['memoryUsedGb', 'usedMemoryGb'],
        tbKeys: const ['memoryUsedTb', 'usedMemoryTb'],
        genericKeys: const ['memoryUsed', 'usedMemory'],
        unitKeys: const ['memoryUnit', 'usedMemoryUnit'],
      ) ??
      _extractSizeInGbFromSource(
        map,
        kind: _StorageMetricKind.memory,
        byteKeys: const ['memoryUsedBytes', 'usedMemoryBytes'],
        kbKeys: const ['memoryUsedKb', 'usedMemoryKb'],
        mbKeys: const ['memoryUsedMb', 'usedMemoryMb'],
        gbKeys: const ['memoryUsedGb', 'usedMemoryGb'],
        tbKeys: const ['memoryUsedTb', 'usedMemoryTb'],
        genericKeys: const ['memoryUsed', 'usedMemory'],
        unitKeys: const ['memoryUnit', 'usedMemoryUnit'],
      ) ??
      summaryPair?.first;

  final totalGb = _extractSizeInGbFromSource(
        memory,
        kind: _StorageMetricKind.memory,
        byteKeys: const [
          'totalBytes',
          'total_bytes',
          'capacityBytes',
          'availableBytes',
        ],
        kbKeys: const ['totalKb', 'totalKB', 'totalKiB'],
        mbKeys: const ['totalMb', 'totalMB', 'totalMiB', 'capacityMb'],
        gbKeys: const ['totalGb', 'totalGB', 'totalGiB', 'capacityGb'],
        tbKeys: const ['totalTb', 'totalTB', 'totalTiB', 'capacityTb'],
        genericKeys: const ['total', 'capacity', 'available', 'totalValue'],
        unitKeys: const [
          'totalUnit',
          'unit',
          'memoryUnit',
          'displayUnit',
        ],
      ) ??
      _extractSizeInGbFromSource(
        metrics,
        kind: _StorageMetricKind.memory,
        byteKeys: const ['memoryTotalBytes', 'totalMemoryBytes'],
        kbKeys: const ['memoryTotalKb', 'totalMemoryKb'],
        mbKeys: const ['memoryTotalMb', 'totalMemoryMb'],
        gbKeys: const ['memoryTotalGb', 'totalMemoryGb'],
        tbKeys: const ['memoryTotalTb', 'totalMemoryTb'],
        genericKeys: const ['memoryTotal', 'totalMemory'],
        unitKeys: const ['memoryUnit', 'totalMemoryUnit'],
      ) ??
      _extractSizeInGbFromSource(
        map,
        kind: _StorageMetricKind.memory,
        byteKeys: const ['memoryTotalBytes', 'totalMemoryBytes'],
        kbKeys: const ['memoryTotalKb', 'totalMemoryKb'],
        mbKeys: const ['memoryTotalMb', 'totalMemoryMb'],
        gbKeys: const ['memoryTotalGb', 'totalMemoryGb'],
        tbKeys: const ['memoryTotalTb', 'totalMemoryTb'],
        genericKeys: const ['memoryTotal', 'totalMemory'],
        unitKeys: const ['memoryUnit', 'totalMemoryUnit'],
      ) ??
      summaryPair?.last;

  final percent = _extractPercentFromSources(
        <Map<String, dynamic>>[memory, metrics, map],
        const [
          'usagePercent',
          'usedPercent',
          'usagePct',
          'usage',
          'percent',
          'memoryPercent',
          'memoryUsage',
          'memoryUsagePercent',
          'value',
        ],
        const [
          'summary',
          'usageText',
          'display',
          'valueText',
          'memorySummary',
          'memoryUsageText',
          'memoryDisplay',
        ],
      ) ??
      _derivePercent(usedGb, totalGb);

  return _StorageMetricSnapshot(
    usedGb: usedGb,
    totalGb: totalGb,
    percent: percent,
  );
}

_StorageMetricSnapshot _extractDiskMetric(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  final disk = _extractPrimaryDisk(map, metrics);
  final summaryPair = _extractSizePairFromSources(
    <Map<String, dynamic>>[disk, metrics, map],
    const [
      'summary',
      'usageText',
      'display',
      'valueText',
      'diskSummary',
      'diskUsageText',
      'storageSummary',
      'storageUsageText',
    ],
  );

  final usedGb = _extractSizeInGbFromSource(
        disk,
        kind: _StorageMetricKind.disk,
        byteKeys: const ['usedBytes', 'used_bytes', 'bytesUsed'],
        kbKeys: const ['usedKb', 'usedKB', 'usedKiB'],
        mbKeys: const ['usedMb', 'usedMB', 'usedMiB'],
        gbKeys: const ['usedGb', 'usedGB', 'usedGiB'],
        tbKeys: const ['usedTb', 'usedTB', 'usedTiB'],
        genericKeys: const ['used', 'usedValue', 'valueUsed'],
        unitKeys: const ['usedUnit', 'unit', 'diskUnit', 'displayUnit'],
      ) ??
      _extractSizeInGbFromSource(
        metrics,
        kind: _StorageMetricKind.disk,
        byteKeys: const ['diskUsedBytes', 'storageUsedBytes'],
        kbKeys: const ['diskUsedKb', 'storageUsedKb'],
        mbKeys: const ['diskUsedMb', 'storageUsedMb'],
        gbKeys: const ['diskUsedGb', 'storageUsedGb'],
        tbKeys: const ['diskUsedTb', 'storageUsedTb'],
        genericKeys: const ['diskUsed', 'storageUsed'],
        unitKeys: const ['diskUnit', 'storageUnit'],
      ) ??
      _extractSizeInGbFromSource(
        map,
        kind: _StorageMetricKind.disk,
        byteKeys: const ['diskUsedBytes', 'storageUsedBytes'],
        kbKeys: const ['diskUsedKb', 'storageUsedKb'],
        mbKeys: const ['diskUsedMb', 'storageUsedMb'],
        gbKeys: const ['diskUsedGb', 'storageUsedGb'],
        tbKeys: const ['diskUsedTb', 'storageUsedTb'],
        genericKeys: const ['diskUsed', 'storageUsed'],
        unitKeys: const ['diskUnit', 'storageUnit'],
      ) ??
      summaryPair?.first;

  final totalGb = _extractSizeInGbFromSource(
        disk,
        kind: _StorageMetricKind.disk,
        byteKeys: const ['totalBytes', 'total_bytes', 'sizeBytes'],
        kbKeys: const ['totalKb', 'totalKB', 'totalKiB'],
        mbKeys: const ['totalMb', 'totalMB', 'totalMiB', 'sizeMb'],
        gbKeys: const ['totalGb', 'totalGB', 'totalGiB', 'sizeGb'],
        tbKeys: const ['totalTb', 'totalTB', 'totalTiB', 'sizeTb'],
        genericKeys: const ['total', 'size', 'capacity', 'totalValue'],
        unitKeys: const ['totalUnit', 'unit', 'diskUnit', 'displayUnit'],
      ) ??
      _extractSizeInGbFromSource(
        metrics,
        kind: _StorageMetricKind.disk,
        byteKeys: const ['diskTotalBytes', 'storageTotalBytes'],
        kbKeys: const ['diskTotalKb', 'storageTotalKb'],
        mbKeys: const ['diskTotalMb', 'storageTotalMb'],
        gbKeys: const ['diskTotalGb', 'storageTotalGb'],
        tbKeys: const ['diskTotalTb', 'storageTotalTb'],
        genericKeys: const ['diskTotal', 'storageTotal'],
        unitKeys: const ['diskUnit', 'storageUnit'],
      ) ??
      _extractSizeInGbFromSource(
        map,
        kind: _StorageMetricKind.disk,
        byteKeys: const ['diskTotalBytes', 'storageTotalBytes'],
        kbKeys: const ['diskTotalKb', 'storageTotalKb'],
        mbKeys: const ['diskTotalMb', 'storageTotalMb'],
        gbKeys: const ['diskTotalGb', 'storageTotalGb'],
        tbKeys: const ['diskTotalTb', 'storageTotalTb'],
        genericKeys: const ['diskTotal', 'storageTotal'],
        unitKeys: const ['diskUnit', 'storageUnit'],
      ) ??
      summaryPair?.last;

  final freeGb = usedGb == null || totalGb == null
      ? _extractSizeInGbFromSource(
            disk,
            kind: _StorageMetricKind.disk,
            byteKeys: const ['freeBytes', 'free_bytes', 'availableBytes'],
            gbKeys: const ['freeGb', 'freeGB', 'availableGb'],
            mbKeys: const ['freeMb', 'freeMB', 'availableMb'],
            genericKeys: const ['free', 'available', 'avail'],
            unitKeys: const ['unit', 'diskUnit'],
          )
      : null;

  final resolvedTotalGb = totalGb;
  final resolvedUsedGb = usedGb ??
      (resolvedTotalGb != null && freeGb != null
          ? (resolvedTotalGb - freeGb).clamp(0.0, resolvedTotalGb)
          : null);

  final percent = _extractPercentFromSources(
        <Map<String, dynamic>>[disk, metrics, map],
        const [
          'usagePercent',
          'usedPercent',
          'usagePct',
          'usage',
          'percent',
          'diskPercent',
          'diskUsage',
          'diskUsagePercent',
          'value',
        ],
        const [
          'summary',
          'usageText',
          'display',
          'valueText',
          'diskSummary',
          'diskUsageText',
          'storageSummary',
          'storageUsageText',
        ],
      ) ??
      _derivePercent(resolvedUsedGb, resolvedTotalGb);

  return _StorageMetricSnapshot(
    usedGb: resolvedUsedGb,
    totalGb: resolvedTotalGb,
    percent: percent,
    label: _firstString(
          disk,
          const [
            'label',
            'mount',
            'mountPoint',
            'path',
            'name',
            'drive',
            'volume',
            'filesystem',
          ],
        ) ??
        _firstString(metrics, const ['diskLabel', 'primaryDiskLabel']) ??
        _firstString(map, const ['diskLabel', 'primaryDiskLabel']),
  );
}

double? _extractSizeInGbFromSource(
  Map<String, dynamic> source, {
  required _StorageMetricKind kind,
  List<String> byteKeys = const <String>[],
  List<String> kbKeys = const <String>[],
  List<String> mbKeys = const <String>[],
  List<String> gbKeys = const <String>[],
  List<String> tbKeys = const <String>[],
  List<String> genericKeys = const <String>[],
  List<String> unitKeys = const <String>[],
}) {
  if (source.isEmpty) {
    return null;
  }

  for (final key in byteKeys) {
    if (!source.containsKey(key)) {
      continue;
    }
    final parsed = _parseSizeValueToGb(
      source[key],
      kind: kind,
      defaultUnit: 'bytes',
    );
    if (parsed != null) {
      return parsed;
    }
  }

  for (final key in kbKeys) {
    if (!source.containsKey(key)) {
      continue;
    }
    final parsed = _parseSizeValueToGb(
      source[key],
      kind: kind,
      defaultUnit: 'kb',
    );
    if (parsed != null) {
      return parsed;
    }
  }

  for (final key in mbKeys) {
    if (!source.containsKey(key)) {
      continue;
    }
    final parsed = _parseSizeValueToGb(
      source[key],
      kind: kind,
      defaultUnit: 'mb',
    );
    if (parsed != null) {
      return parsed;
    }
  }

  for (final key in gbKeys) {
    if (!source.containsKey(key)) {
      continue;
    }
    final parsed = _parseSizeValueToGb(
      source[key],
      kind: kind,
      defaultUnit: 'gb',
    );
    if (parsed != null) {
      return parsed;
    }
  }

  for (final key in tbKeys) {
    if (!source.containsKey(key)) {
      continue;
    }
    final parsed = _parseSizeValueToGb(
      source[key],
      kind: kind,
      defaultUnit: 'tb',
    );
    if (parsed != null) {
      return parsed;
    }
  }

  final defaultUnit = _firstString(source, unitKeys);
  for (final key in genericKeys) {
    if (!source.containsKey(key)) {
      continue;
    }
    final parsed = _parseSizeValueToGb(
      source[key],
      kind: kind,
      defaultUnit: defaultUnit,
    );
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

double? _parseSizeValueToGb(
  dynamic value, {
  required _StorageMetricKind kind,
  String? defaultUnit,
}) {
  if (value == null) {
    return null;
  }

  if (value is Map) {
    final map = _asMap(value);
    final nestedUnit = _firstString(
      map,
      const ['unit', 'displayUnit', 'measure', 'sizeUnit', 'suffix'],
    );
    final nestedValue = map['value'] ??
        map['amount'] ??
        map['size'] ??
        map['used'] ??
        map['total'] ??
        map['current'];

    if (nestedValue != null) {
      return _parseSizeValueToGb(
        nestedValue,
        kind: kind,
        defaultUnit: nestedUnit ?? defaultUnit,
      );
    }

    return _extractSizeInGbFromSource(
      map,
      kind: kind,
      byteKeys: const ['bytes', 'valueBytes', 'sizeBytes'],
      kbKeys: const ['kb', 'valueKb', 'sizeKb'],
      mbKeys: const ['mb', 'valueMb', 'sizeMb'],
      gbKeys: const ['gb', 'valueGb', 'sizeGb'],
      tbKeys: const ['tb', 'valueTb', 'sizeTb'],
      genericKeys: const ['value', 'amount', 'size', 'current'],
      unitKeys: const ['unit', 'displayUnit', 'measure', 'sizeUnit'],
    );
  }

  if (value is String) {
    final pair = _extractSizePairFromText(value);
    if (pair != null && pair.isNotEmpty) {
      return pair.first;
    }

    final parsed = _tryParseDouble(value);
    if (parsed != null) {
      final normalizedUnit =
          defaultUnit ?? _inferGenericSizeUnit(parsed, kind).name;
      return _convertSizeToGb(parsed, normalizedUnit);
    }
    return null;
  }

  if (value is num) {
    final normalizedUnit =
        defaultUnit ?? _inferGenericSizeUnit(value, kind).name;
    return _convertSizeToGb(value.toDouble(), normalizedUnit);
  }

  return null;
}

List<double>? _extractSizePairFromSources(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    for (final key in keys) {
      final value = source[key];
      if (value is! String || value.trim().isEmpty) {
        continue;
      }
      final pair = _extractSizePairFromText(value);
      if (pair != null && pair.length >= 2) {
        return pair;
      }
    }
  }
  return null;
}

List<double>? _extractSizePairFromText(String text) {
  final matches = RegExp(
    r'(\d+(?:\.\d+)?)\s*(bytes|byte|kb|kib|mb|mib|gb|gib|tb|tib)\b',
    caseSensitive: false,
  ).allMatches(text);

  final values = <double>[];
  for (final match in matches) {
    final amount = double.tryParse(match.group(1)!);
    final unit = match.group(2);
    if (amount == null || unit == null) {
      continue;
    }
    values.add(_convertSizeToGb(amount, unit));
  }

  if (values.length >= 2) {
    return values.take(2).toList(growable: false);
  }

  return null;
}

double? _extractPercentFromSources(
  List<Map<String, dynamic>> sources,
  List<String> numericKeys,
  List<String> textKeys,
) {
  for (final source in sources) {
    final raw = _firstDouble(source, numericKeys);
    final normalized = _normalizePercent(raw);
    if (normalized != null) {
      return normalized;
    }
  }

  for (final source in sources) {
    for (final key in textKeys) {
      final value = source[key];
      if (value is! String || value.trim().isEmpty) {
        continue;
      }
      final match = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(value);
      if (match == null) {
        continue;
      }
      final percent = double.tryParse(match.group(1)!);
      final normalized = _normalizePercent(percent);
      if (normalized != null) {
        return normalized;
      }
    }
  }

  return null;
}

double? _normalizePercent(double? value) {
  if (value == null) {
    return null;
  }
  if (value > 0 && value <= 1) {
    return value * 100;
  }
  return value;
}

double? _derivePercent(double? usedGb, double? totalGb) {
  if (usedGb == null || totalGb == null || totalGb <= 0) {
    return null;
  }
  return (usedGb / totalGb) * 100;
}

double _convertSizeToGb(double value, String rawUnit) {
  final unit = rawUnit.trim().toLowerCase();
  switch (unit) {
    case 'bytes':
    case 'byte':
    case 'b':
      return value / 1024 / 1024 / 1024;
    case 'kb':
    case 'kib':
      return value / 1024 / 1024;
    case 'mb':
    case 'mib':
      return value / 1024;
    case 'gb':
    case 'gib':
      return value;
    case 'tb':
    case 'tib':
      return value * 1024;
    default:
      return value;
  }
}

_InferredStorageUnit _inferGenericSizeUnit(
  num value,
  _StorageMetricKind kind,
) {
  final absoluteValue = value.abs().toDouble();
  if (absoluteValue >= 1048576) {
    return _InferredStorageUnit.bytes;
  }

  switch (kind) {
    case _StorageMetricKind.memory:
      if (absoluteValue >= 1024) {
        return _InferredStorageUnit.mb;
      }
      return _InferredStorageUnit.gb;
    case _StorageMetricKind.disk:
      if (absoluteValue >= 8192) {
        return _InferredStorageUnit.mb;
      }
      return _InferredStorageUnit.gb;
  }
}

double? _tryParseDouble(String value) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) {
    return null;
  }

  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(cleaned);
  if (match == null) {
    return null;
  }

  return double.tryParse(match.group(0)!);
}

String _extractServerUptimeText(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  return _firstString(
        map,
        const ['uptimeHuman', 'uptimeText', 'serverUptime', 'uptime'],
      ) ??
      _firstString(
        metrics,
        const ['uptimeHuman', 'uptimeText', 'serverUptime', 'uptime'],
      ) ??
      _formatDurationText(
        _firstInt(
              metrics,
              const ['uptimeSec', 'uptimeSeconds', 'serverUptimeSeconds'],
            ) ??
            _firstInt(
              map,
              const ['uptimeSec', 'uptimeSeconds', 'serverUptimeSeconds'],
            ),
      ) ??
      '—';
}

Map<String, dynamic> _extractPrimaryDisk(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  const mapKeys = [
    'primaryDisk',
    'diskInfo',
    'rootDisk',
    'filesystem',
  ];
  const listOrMapKeys = [
    'disk',
    'storage',
    'disks',
    'storageDisks',
    'filesystems',
    'volumes',
  ];

  for (final source in <Map<String, dynamic>>[map, metrics]) {
    final directMap = _firstMap(source, mapKeys);
    if (directMap != null && directMap.isNotEmpty) {
      return directMap;
    }

    for (final key in listOrMapKeys) {
      final value = source[key];
      if (value is Map) {
        final m = _asMap(value);
        if (m.isNotEmpty) return m;
      }
      if (value is List && value.isNotEmpty) {
        return _asMap(value.first);
      }
    }
  }

  return const <String, dynamic>{};
}

List<SuperadminServerComponent> _extractComponents(
  Map<String, dynamic> map,
  Map<String, dynamic> metrics,
) {
  final directList = _firstList(
        map,
        const ['components', 'services', 'serviceStates', 'items'],
      ) ??
      _firstList(
        metrics,
        const ['components', 'services', 'serviceStates', 'items'],
      );

  if (directList != null && directList.isNotEmpty) {
    return directList
        .map((item) => SuperadminServerComponent.fromJson(item))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  final directMap = _firstMap(
        map,
        const ['components', 'services', 'serviceStates'],
      ) ??
      _firstMap(
        metrics,
        const ['components', 'services', 'serviceStates'],
      );
  if (directMap != null && directMap.isNotEmpty) {
    return directMap.entries
        .map(
          (entry) => SuperadminServerComponent.fromJson(
            entry.value,
            fallbackId: entry.key,
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  return const <SuperadminServerComponent>[];
}

List<SuperadminServerComponent> _mergeWithDefaults(
  List<SuperadminServerComponent> components,
) {
  final lookup = <String, SuperadminServerComponent>{
    for (final component in components) component.id: component,
  };

  final merged = <SuperadminServerComponent>[];
  for (final id in _defaultComponentOrder) {
    merged.add(
      lookup[id] ??
          SuperadminServerComponent(
            id: id,
            name: _defaultComponentName(id),
            description: _defaultComponentDescription(id),
            status: SuperadminServerComponentStatus.unknown,
            pid: null,
            ports: const <int>[],
            uptimeText: '—',
            statusMessage: 'Status not available',
            availableActions: _defaultActionsForComponent(id),
          ),
    );
  }

  for (final component in components) {
    if (!_defaultComponentOrder.contains(component.id)) {
      merged.add(component);
    }
  }

  return merged;
}

SuperadminServerComponent? _componentById(
  List<SuperadminServerComponent> components,
  String componentId,
) {
  final normalizedId = _normalizeComponentId(componentId);
  for (final component in components) {
    if (component.id == normalizedId) {
      return component;
    }
  }
  return null;
}

SuperadminServerComponentStatus _extractComponentStatus(
  Map<String, dynamic> source,
  Map<String, dynamic> nested,
) {
  final raw = _firstString(
        source,
        const ['status', 'state', 'serviceStatus', 'health'],
      ) ??
      _firstString(
        nested,
        const ['status', 'state', 'serviceStatus', 'health'],
      );
  if (raw != null && raw.trim().isNotEmpty) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('run') || normalized.contains('healthy')) {
      return SuperadminServerComponentStatus.running;
    }
    if (normalized.contains('stop')) {
      return SuperadminServerComponentStatus.stopped;
    }
    if (normalized.contains('degrad') || normalized.contains('warn')) {
      return SuperadminServerComponentStatus.degraded;
    }
    if (normalized.contains('offline') || normalized.contains('down')) {
      return SuperadminServerComponentStatus.offline;
    }
  }

  final isRunning = _firstBool(
        source,
        const ['running', 'isRunning', 'healthy', 'active'],
      ) ??
      _firstBool(
        nested,
        const ['running', 'isRunning', 'healthy', 'active'],
      );
  if (isRunning == true) {
    return SuperadminServerComponentStatus.running;
  }

  final isStopped = _firstBool(
        source,
        const ['stopped', 'isStopped', 'offline', 'isOffline'],
      ) ??
      _firstBool(
        nested,
        const ['stopped', 'isStopped', 'offline', 'isOffline'],
      );
  if (isStopped == true) {
    return SuperadminServerComponentStatus.stopped;
  }

  return SuperadminServerComponentStatus.unknown;
}

SuperadminServerJobStatus _extractJobStatus(
  Map<String, dynamic> source,
  Map<String, dynamic> nested,
) {
  final raw = _firstString(
        source,
        const ['status', 'state', 'phase', 'result'],
      ) ??
      _firstString(
        nested,
        const ['status', 'state', 'phase', 'result'],
      );
  if (raw != null && raw.trim().isNotEmpty) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('queue') ||
        normalized.contains('pending') ||
        normalized.contains('created') ||
        normalized.contains('accept')) {
      return SuperadminServerJobStatus.queued;
    }
    if (normalized.contains('run') ||
        normalized.contains('progress') ||
        normalized.contains('working') ||
        normalized.contains('start')) {
      return SuperadminServerJobStatus.running;
    }
    if (normalized.contains('success') ||
        normalized.contains('complete') ||
        normalized.contains('done') ||
        normalized.contains('finish') ||
        normalized == 'ok') {
      return SuperadminServerJobStatus.success;
    }
    if (normalized.contains('fail') ||
        normalized.contains('error') ||
        normalized.contains('cancel') ||
        normalized.contains('abort')) {
      return SuperadminServerJobStatus.failed;
    }
  }

  final success = _firstBool(source, const ['success', 'action']) ??
      _firstBool(nested, const ['success', 'action']);
  if (success == true) {
    return SuperadminServerJobStatus.success;
  }
  if (success == false) {
    return SuperadminServerJobStatus.failed;
  }

  return SuperadminServerJobStatus.unknown;
}

List<String> _extractLogLines(
  Map<String, dynamic> source,
  Map<String, dynamic> nested,
) {
  final rawLogs = _firstList(
        source,
        const ['logs', 'events', 'history', 'entries'],
      ) ??
      _firstList(
        nested,
        const ['logs', 'events', 'history', 'entries'],
      ) ??
      const <dynamic>[];

  return rawLogs
      .map((item) {
        if (item is String) {
          return item.trim();
        }

        final itemMap = _asMap(item);
        return _firstString(
              itemMap,
              const ['message', 'detail', 'text', 'event'],
            ) ??
            '';
      })
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const <String, dynamic>{};
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (nestedKey, nestedValue) => MapEntry(
          nestedKey.toString(),
          nestedValue,
        ),
      );
    }
  }
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      return value;
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return value.toString();
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      if (cleaned.isEmpty) {
        continue;
      }
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        return parsed.round();
      }
    }
  }
  return null;
}

double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      if (cleaned.isEmpty) {
        continue;
      }
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

bool? _firstBool(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'online') {
        return true;
      }
      if (normalized == 'false' ||
          normalized == 'no' ||
          normalized == 'offline') {
        return false;
      }
    }
  }
  return null;
}

DateTime? _firstDateTime(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed.toLocal();
      }
    }
    if (value is int) {
      final millis = value > 9999999999 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
  }
  return null;
}

List<String> _extractStringList(
    Map<String, dynamic> source, List<String> keys) {
  final value = _firstList(source, keys) ??
      keys.map((key) => source[key]).firstWhere(
            (item) => item is String && item.trim().isNotEmpty,
            orElse: () => null,
          );

  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  if (value is String) {
    return value
        .split(RegExp(r'[,/]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}

List<int> _extractIntList(Map<String, dynamic> source, List<String> keys) {
  final rawValues = <int>[];
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      for (final item in value) {
        final parsed = item is num
            ? item.toInt()
            : int.tryParse(item.toString().replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null) {
          rawValues.add(parsed);
        }
      }
    } else if (value is String && value.trim().isNotEmpty) {
      final matches = RegExp(r'\d+').allMatches(value);
      for (final match in matches) {
        final parsed = int.tryParse(match.group(0)!);
        if (parsed != null) {
          rawValues.add(parsed);
        }
      }
    } else if (value is num) {
      rawValues.add(value.toInt());
    }
  }
  return rawValues.toSet().toList(growable: false);
}

List<double> _extractNumericSeries(
  Map<String, dynamic> source,
  List<String> keys,
) {
  final values = <double>[];
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      for (final item in value) {
        if (item is num) {
          values.add(item.toDouble());
        } else if (item is String) {
          final parsed = double.tryParse(item.trim());
          if (parsed != null) {
            values.add(parsed);
          }
        }
      }
    } else if (value is String && value.trim().isNotEmpty) {
      final matches = RegExp(r'-?\d+(?:\.\d+)?').allMatches(value);
      for (final match in matches) {
        final parsed = double.tryParse(match.group(0)!);
        if (parsed != null) {
          values.add(parsed);
        }
      }
    }
  }
  return values;
}

class _StorageMetricSnapshot {
  const _StorageMetricSnapshot({
    this.usedGb,
    this.totalGb,
    this.percent,
    this.label,
  });

  final double? usedGb;
  final double? totalGb;
  final double? percent;
  final String? label;
}

enum _StorageMetricKind { memory, disk }

enum _InferredStorageUnit { bytes, mb, gb }

String _normalizeComponentId(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  switch (normalized) {
    case 'frontend':
    case 'front-end':
    case 'front':
      return 'frontend';
    case 'backend':
    case 'back-end':
    case 'api':
      return 'backend';
    case 'listener':
    case 'local-agent':
    case 'localagent':
    case 'agent':
      return 'listener';
    case 'nginx':
      return 'nginx';
    case 'redis':
      return 'redis';
    case 'postgres':
    case 'postgresql':
    case 'postgres-db':
    case 'database':
    case 'db':
      return 'postgresql';
    default:
      return normalized;
  }
}

String _normalizeAction(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  switch (normalized) {
    case 'start':
    case 'run':
      return 'start';
    case 'restart':
    case 'reboot':
      return 'restart';
    case 'reload':
      return 'reload';
    case 'stop':
      return 'stop';
    default:
      return normalized;
  }
}

String _defaultComponentName(String componentId) {
  switch (_normalizeComponentId(componentId)) {
    case 'frontend':
      return 'Frontend';
    case 'backend':
      return 'Backend';
    case 'listener':
      return 'Listener';
    case 'nginx':
      return 'Nginx';
    case 'redis':
      return 'Redis';
    case 'postgresql':
      return 'PostgreSQL';
    default:
      return _titleCase(componentId.replaceAll('-', ' '));
  }
}

String _defaultComponentDescription(String componentId) {
  switch (_normalizeComponentId(componentId)) {
    case 'frontend':
      return 'Next.js UI (this app)';
    case 'backend':
      return 'Core API service';
    case 'listener':
      return 'Background listener service';
    case 'nginx':
      return 'Reverse proxy and edge gateway';
    case 'redis':
      return 'Cache / queue backing store';
    case 'postgresql':
      return 'Primary data store';
    default:
      return 'Managed service component';
  }
}

List<String> _defaultActionsForComponent(String componentId) {
  switch (_normalizeComponentId(componentId)) {
    case 'frontend':
      return const <String>['start', 'restart'];
    case 'backend':
      return const <String>['restart'];
    case 'listener':
      return const <String>['start', 'restart'];
    case 'nginx':
      return const <String>['start', 'restart', 'reload'];
    case 'redis':
      return const <String>['restart'];
    case 'postgresql':
      return const <String>['restart'];
    default:
      return const <String>['restart'];
  }
}

String _titleCase(String value) {
  final words = value
      .split(RegExp(r'\s+'))
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return '';
  }

  return words
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String? _formatDurationText(int? totalSeconds) {
  if (totalSeconds == null || totalSeconds <= 0) {
    return null;
  }

  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final parts = <String>[];
  if (days > 0) {
    parts.add('${days}d');
  }
  if (hours > 0 || days > 0) {
    parts.add('${hours}h');
  }
  parts.add('${minutes}m');
  return parts.join(' ');
}

String _formatOneDecimal(double value) {
  return value.toStringAsFixed(2);
}

const List<String> _defaultComponentOrder = <String>[
  'frontend',
  'backend',
  'listener',
  'nginx',
  'redis',
  'postgresql',
];

String serverComponentNameForId(String componentId) {
  return _defaultComponentName(componentId);
}

String serverActionLabel(String action) {
  return _titleCase(action);
}
