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
}
