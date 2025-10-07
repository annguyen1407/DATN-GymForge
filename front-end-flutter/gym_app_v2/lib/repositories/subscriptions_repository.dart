import '../core/api/api_client.dart';
import '../core/api/api_mapper.dart';
import '../models/subscription_plan_model.dart';
import '../core/logging/app_logger.dart';

class SubscriptionsRepository {
  SubscriptionsRepository._();
  static final instance = SubscriptionsRepository._();

  Future<List<SubscriptionPlanModel>> listPlans() async {
    final response = await ApiClient.instance.requestJson(
      'GET',
      '/subscriptions/plans',
    );
    if (!response.ok) {
      AppLogger.warn(
        'List plans error: ${response.error} status=${response.status}',
        tag: 'SubscriptionsRepo',
      );
      return [];
    }
    return response.asModelList(SubscriptionPlanModel.fromJson);
  }

  Future<bool> purchase({
    required String planId,
    required String method,
    required String providerToken,
  }) async {
    final body = {
      'planId': planId,
      'method': method,
      'providerToken': providerToken,
    };
    final response = await ApiClient.instance.requestJson(
      'POST',
      '/subscriptions/purchase',
      body: body,
    );
    if (!response.ok) {
      AppLogger.error(
        'Purchase failed: status=${response.status} err=${response.error}',
        tag: 'SubscriptionsRepo',
      );
      return false;
    }
    return true;
  }
}
