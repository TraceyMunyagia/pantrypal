import 'package:flutter/foundation.dart';

import '../models/meal_plan.dart';
import '../services/ai_meal_plan_service.dart';
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
