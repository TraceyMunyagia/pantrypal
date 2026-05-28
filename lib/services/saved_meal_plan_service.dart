import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_plan.dart';

class SavedMealPlanService {
  static const _mealPlansKey = 'saved_meal_plans';

  Future<List<MealPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_mealPlansKey) ?? [];

    return values
        .map(
          (value) =>
              MealPlan.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> savePlans(List<MealPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final values = plans.map((plan) => jsonEncode(plan.toJson())).toList();
    await prefs.setStringList(_mealPlansKey, values);
  }
}
