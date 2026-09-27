import 'package:flutter/foundation.dart';

import '../models/meal_plan_model.dart';
import '../services/meal_plan_service.dart';
import '../services/saved_meal_plan_service.dart';

class MealPlanProvider extends ChangeNotifier {
  MealPlanProvider({
    AiMealPlanService? mealPlanService,
    SavedMealPlanService? savedMealPlanService,
  }) : _mealPlanService = mealPlanService ?? AiMealPlanService(),
       _savedMealPlanService = savedMealPlanService ?? SavedMealPlanService() {
    loadSavedPlans();
  }

  final AiMealPlanService _mealPlanService;
  final SavedMealPlanService _savedMealPlanService;

  final List<MealPlan> _savedPlans = [];
  MealPlan? _currentPlan;
  bool _isLoading = false;
  String? _errorMessage;

  List<MealPlan> get savedPlans => List.unmodifiable(_savedPlans);
  MealPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> generateFoodBankPlan({
    required Map<String, List<String>> foodBank,
    bool remix = false,
    bool avoidRepeats = true,
  }) async {
    if (_isLoading) return;

    final breakfast = _cleanFoods(foodBank['breakfast']);
    final proteins = _cleanFoods(foodBank['protein']);
    final carbs = _cleanFoods(foodBank['carb']);
    final vegetables = _cleanFoods(foodBank['vegetable']);
    if (breakfast.isEmpty ||
        proteins.isEmpty ||
        carbs.isEmpty ||
        vegetables.isEmpty) {
      _errorMessage =
          'Add at least one food to each category before generating a plan.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final previousCombinations = <String>{};
      if (avoidRepeats) {
        for (final plan in _savedPlans) {
          for (final day in plan.days) {
            previousCombinations.addAll(
              day.meals
                  .where((meal) => meal.type == 'Lunch & Dinner')
                  .map((meal) => meal.name),
            );
          }
        }
      }

      final days = <MealPlanDay>[];
      for (var day = 0; day < 7; day++) {
        Meal? selectedMeal;
        for (var attempt = 0; attempt < 7; attempt++) {
          final index = day + attempt + (remix ? 1 : 0);
          final breakfastFood = breakfast[index % breakfast.length];
          final protein = proteins[index % proteins.length];
          final carb = carbs[(index + (remix ? 1 : 0)) % carbs.length];
          final vegetable =
              vegetables[(index + (remix ? 2 : 0)) % vegetables.length];
          final name = '$carb + $protein + $vegetable';
          if (!avoidRepeats || !previousCombinations.contains(name)) {
            selectedMeal = Meal(
              type: 'Lunch & Dinner',
              name: name,
              ingredients: [breakfastFood, protein, carb, vegetable],
              instructions: [
                'Breakfast: prepare $breakfastFood as you prefer.',
                'Serve $carb with $protein and $vegetable.',
              ],
              prepTime: '30 min',
            );
            break;
          }
        }

        selectedMeal ??= Meal(
          type: 'Lunch & Dinner',
          name:
              '${carbs[day % carbs.length]} + ${proteins[day % proteins.length]} + ${vegetables[day % vegetables.length]}',
          ingredients: [
            breakfast[day % breakfast.length],
            proteins[day % proteins.length],
            carbs[day % carbs.length],
            vegetables[day % vegetables.length],
          ],
          instructions: const [
            'Prepare and serve the selected foods together.',
          ],
          prepTime: '30 min',
        );

        days.add(
          MealPlanDay(
            dayNumber: day + 1,
            meals: [
              Meal(
                type: 'Breakfast',
                name: breakfast[(day + (remix ? 1 : 0)) % breakfast.length],
                ingredients: [
                  breakfast[(day + (remix ? 1 : 0)) % breakfast.length],
                ],
                instructions: const ['Prepare according to your usual method.'],
                prepTime: '15 min',
              ),
              selectedMeal,
            ],
          ),
        );
      }

      _currentPlan = MealPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: remix ? 'Remixed Weekly Plan' : 'My Weekly Meal Plan',
        durationDays: 7,
        preferences: const [],
        goal: 'Use my food bank',
        budget: '',
        days: days,
        createdAt: DateTime.now(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> _cleanFoods(List<String>? foods) {
    return (foods ?? [])
        .map((food) => food.trim())
        .where((food) => food.isNotEmpty)
        .toList();
  }

  Future<void> generatePlan(MealPlanRequest request) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPlan = await _mealPlanService.generateMealPlan(request);
    } catch (error) {
      _errorMessage = error
          .toString()
          .replaceFirst(RegExp(r'^Exception:\s*'), '')
          .trim();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedPlans() async {
    final plans = await _savedMealPlanService.loadPlans();
    _savedPlans
      ..clear()
      ..addAll(plans);
    notifyListeners();
  }

  Future<void> saveCurrentPlan() async {
    final plan = _currentPlan;
    if (plan == null) return;

    _savedPlans.removeWhere((saved) => saved.id == plan.id);
    _savedPlans.insert(0, plan);
    await _savedMealPlanService.savePlans(_savedPlans);
    notifyListeners();
  }

  Future<void> deletePlan(MealPlan plan) async {
    _savedPlans.removeWhere((saved) => saved.id == plan.id);
    if (_currentPlan?.id == plan.id) _currentPlan = null;
    await _savedMealPlanService.savePlans(_savedPlans);
    notifyListeners();
  }

  void openPlan(MealPlan plan) {
    _currentPlan = plan;
    _errorMessage = null;
    notifyListeners();
  }
}
