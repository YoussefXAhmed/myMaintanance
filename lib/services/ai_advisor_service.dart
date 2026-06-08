import '../models/enums.dart';
import '../models/vehicle.dart';
import 'health_service.dart';

enum AdvisorPriority { high, medium, low, info }

enum AdvisorKind { overdue, dueSoon, insurance, license, inspection, mileageTrend, allGood }

/// A single structured recommendation. The UI localizes it (so the same data
/// renders correctly in Arabic & English).
class AdvisorRecommendation {
  const AdvisorRecommendation({
    required this.kind,
    required this.priority,
    this.type,
    this.kmRemaining,
    this.daysRemaining,
  });

  final AdvisorKind kind;
  final AdvisorPriority priority;
  final MaintenanceType? type;
  final int? kmRemaining;
  final int? daysRemaining;
}

/// Contract so a future OpenAI-backed advisor can drop in behind the same API.
abstract class AiAdvisor {
  List<AdvisorRecommendation> analyze({
    required Vehicle vehicle,
    required VehicleHealth health,
  });
}

/// Deterministic, on-device advisor derived from maintenance status, insurance
/// and license dates. No network required.
class RuleBasedAdvisor implements AiAdvisor {
  const RuleBasedAdvisor();

  @override
  List<AdvisorRecommendation> analyze({required Vehicle vehicle, required VehicleHealth health}) {
    final recs = <AdvisorRecommendation>[];

    for (final item in health.items) {
      if (!item.hasRecord) continue;
      if (item.status == DueStatus.overdue) {
        recs.add(AdvisorRecommendation(
          kind: AdvisorKind.overdue,
          priority: AdvisorPriority.high,
          type: item.type,
          kmRemaining: item.kmRemaining,
          daysRemaining: item.daysRemaining,
        ));
      } else if (item.status == DueStatus.dueSoon) {
        recs.add(AdvisorRecommendation(
          kind: AdvisorKind.dueSoon,
          priority: AdvisorPriority.medium,
          type: item.type,
          kmRemaining: item.kmRemaining,
          daysRemaining: item.daysRemaining,
        ));
      }
    }

    void expiry(DateTime? date, AdvisorKind kind) {
      if (date == null) return;
      final days = date.difference(DateTime.now()).inDays;
      if (days <= 45) {
        recs.add(AdvisorRecommendation(
          kind: kind,
          priority: days <= 0 ? AdvisorPriority.high : AdvisorPriority.medium,
          daysRemaining: days,
        ));
      }
    }

    expiry(vehicle.insuranceExpiry, AdvisorKind.insurance);
    expiry(vehicle.licenseExpiry, AdvisorKind.license);
    expiry(vehicle.inspectionDate, AdvisorKind.inspection);

    // Sort by priority (high → info).
    recs.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    if (recs.isEmpty) {
      recs.add(const AdvisorRecommendation(kind: AdvisorKind.allGood, priority: AdvisorPriority.info));
    }
    return recs;
  }
}

/// Placeholder for a cloud advisor. Wire `AppConfig.openAiApiKey` and a chat
/// completion call here, then return parsed [AdvisorRecommendation]s — the rest
/// of the app needs no changes.
class OpenAiAdvisor implements AiAdvisor {
  const OpenAiAdvisor(this.apiKey);
  final String apiKey;

  @override
  List<AdvisorRecommendation> analyze({required Vehicle vehicle, required VehicleHealth health}) {
    // TODO: call OpenAI; fall back to the rule-based engine until implemented.
    return const RuleBasedAdvisor().analyze(vehicle: vehicle, health: health);
  }
}
