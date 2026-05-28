class MealPlanRequest {
  const MealPlanRequest({
    required this.durationDays,
    required this.preferences,
    required this.ingredients,
    required this.goal,
    required this.budget,
  });

  final int durationDays;
  final List<String> preferences;
  final List<String> ingredients;
  final String goal;
  final String budget;
}

class MealPlan {
  const MealPlan({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.preferences,
    required this.goal,
    required this.budget,
    required this.days,
    required this.createdAt,
  });

  final String id;
  final String title;
  final int durationDays;
  final List<String> preferences;
  final String goal;
  final String budget;
  final List<MealPlanDay> days;
  final DateTime createdAt;

  List<String> get shoppingList {
    final values = <String>{};
    for (final day in days) {
      for (final meal in day.meals) {
        for (final ingredient in meal.ingredients) {
          final cleaned = ingredient.trim();
          if (cleaned.isNotEmpty) values.add(cleaned);
        }
      }
    }
    final sorted = values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String? ?? DateTime.now().toIso8601String(),
      title: json['title'] as String? ?? 'Meal Plan',
      durationDays: json['durationDays'] as int? ?? 1,
      preferences: (json['preferences'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      goal: json['goal'] as String? ?? '',
      budget: json['budget'] as String? ?? '',
      days: (json['days'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MealPlanDay.fromJson)
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'durationDays': durationDays,
      'preferences': preferences,
      'goal': goal,
      'budget': budget,
      'days': days.map((day) => day.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toShareText() {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('$durationDays day plan')
      ..writeln('Goal: ${goal.isEmpty ? 'Balanced eating' : goal}')
      ..writeln('Budget: ${budget.isEmpty ? 'Flexible' : budget}')
      ..writeln();

    for (final day in days) {
      buffer.writeln(day.title);
      for (final meal in day.meals) {
        buffer.writeln('- ${meal.type}: ${meal.name}');
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }
}

class MealPlanDay {
  const MealPlanDay({required this.dayNumber, required this.meals});

  final int dayNumber;
  final List<Meal> meals;

  String get title => 'Day $dayNumber';

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    return MealPlanDay(
      dayNumber: json['dayNumber'] as int? ?? 1,
      meals: (json['meals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Meal.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }
}

class Meal {
  const Meal({
    required this.type,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    this.calories,
  });

  final String type;
  final String name;
  final List<String> ingredients;
  final List<String> instructions;
  final String prepTime;
  final int? calories;

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      type: json['type'] as String? ?? 'Meal',
      name: json['name'] as String? ?? 'Simple meal',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      instructions: (json['instructions'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      prepTime: json['prepTime'] as String? ?? '20 min',
      calories: json['calories'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'calories': calories,
    };
  }
}
