import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  static const routeName = '/meal-planner';

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  static const _preferenceOptions = [
    'Vegetarian',
    'High protein',
    'Keto',
    'Budget meals',
  ];

  final _ingredientsController = TextEditingController();
  final _goalController = TextEditingController(text: 'Muscle gain');
  final _budgetController = TextEditingController(text: 'Low');
  late final TabController _tabController;
  int _durationDays = 7;
  final Set<String> _preferences = {'High protein', 'Budget meals'};

  @override
  void initState() {
    super.initState();
    _ingredientsController.text = 'rice, chicken, vegetables';
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _ingredientsController.dispose();
    _goalController.dispose();
    _budgetController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan(MealPlanProvider provider) async {
    final ingredients = _ingredientsController.text
        .split(',')
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    await provider.generatePlan(
      MealPlanRequest(
        durationDays: _durationDays,
        preferences: _preferences.toList(),
        ingredients: ingredients,
        goal: _goalController.text.trim(),
        budget: _budgetController.text.trim(),
      ),
    );

    if (!mounted) return;
    _tabController.animateTo(0);
  }

  Future<void> _copyShareText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<MealPlanProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Meal Planner',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Recipe chat',
                onPressed: () =>
                    Navigator.of(context).pushNamed(HomeScreen.routeName),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              IconButton(
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: themeProvider.toggleDarkMode,
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.calendar_month), text: 'Plan'),
                Tab(icon: Icon(Icons.checklist), text: 'Shopping'),
                Tab(icon: Icon(Icons.bookmark_border), text: 'Saved'),
              ],
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  children: [
                    if (provider.errorMessage != null)
                      _Banner(
                        icon: Icons.error_outline,
                        message: provider.errorMessage!,
                        color: colorScheme.errorContainer,
                        foreground: colorScheme.onErrorContainer,
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _PlanTab(
                            durationDays: _durationDays,
                            preferences: _preferences,
                            preferenceOptions: _preferenceOptions,
                            ingredientsController: _ingredientsController,
                            goalController: _goalController,
                            budgetController: _budgetController,
                            provider: provider,
                            onDurationChanged: (value) {
                              if (value == null) return;
                              setState(() => _durationDays = value);
                            },
                            onPreferenceSelected: (preference, selected) {
                              setState(() {
                                if (selected) {
                                  _preferences.add(preference);
                                } else {
                                  _preferences.remove(preference);
                                }
                              });
                            },
                            onGenerate: () => _generatePlan(provider),
                            onSave: provider.saveCurrentPlan,
                            onShare: provider.currentPlan == null
                                ? null
                                : () => _copyShareText(
                                    provider.currentPlan!.toShareText(),
                                    'Meal plan copied for sharing.',
                                  ),
                          ),
                          _ShoppingTab(
                            plan: provider.currentPlan,
                            onShare: provider.currentPlan == null
                                ? null
                                : () => _copyShareText(
                                    provider.currentPlan!.shoppingList.join(
                                      '\n',
                                    ),
                                    'Shopping list copied for sharing.',
                                  ),
                          ),
                          _SavedPlansTab(
                            plans: provider.savedPlans,
                            onOpen: (plan) {
                              provider.openPlan(plan);
                              _tabController.animateTo(0);
                            },
                            onDelete: provider.deletePlan,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.durationDays,
    required this.preferences,
    required this.preferenceOptions,
    required this.ingredientsController,
    required this.goalController,
    required this.budgetController,
    required this.provider,
    required this.onDurationChanged,
    required this.onPreferenceSelected,
    required this.onGenerate,
    required this.onSave,
    required this.onShare,
  });

  final int durationDays;
  final Set<String> preferences;
  final List<String> preferenceOptions;
  final TextEditingController ingredientsController;
  final TextEditingController goalController;
  final TextEditingController budgetController;
  final MealPlanProvider provider;
  final ValueChanged<int?> onDurationChanged;
  final void Function(String preference, bool selected) onPreferenceSelected;
  final VoidCallback onGenerate;
  final VoidCallback onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final plan = provider.currentPlan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PlannerForm(
          durationDays: durationDays,
          preferences: preferences,
          preferenceOptions: preferenceOptions,
          ingredientsController: ingredientsController,
          goalController: goalController,
          budgetController: budgetController,
          isLoading: provider.isLoading,
          onDurationChanged: onDurationChanged,
          onPreferenceSelected: onPreferenceSelected,
          onGenerate: onGenerate,
        ),
        const SizedBox(height: 16),
        if (plan == null)
          const _EmptyState(
            icon: Icons.calendar_month,
            title: 'Configure a custom meal plan',
            body:
                'Choose a duration, preferences, ingredients, goal, and budget, then generate your plan.',
          )
        else
          _MealPlanView(plan: plan, onSave: onSave, onShare: onShare),
      ],
    );
  }
}

class _PlannerForm extends StatelessWidget {
  const _PlannerForm({
    required this.durationDays,
    required this.preferences,
    required this.preferenceOptions,
    required this.ingredientsController,
    required this.goalController,
    required this.budgetController,
    required this.isLoading,
    required this.onDurationChanged,
    required this.onPreferenceSelected,
    required this.onGenerate,
  });

  final int durationDays;
  final Set<String> preferences;
  final List<String> preferenceOptions;
  final TextEditingController ingredientsController;
  final TextEditingController goalController;
  final TextEditingController budgetController;
  final bool isLoading;
  final ValueChanged<int?> onDurationChanged;
  final void Function(String preference, bool selected) onPreferenceSelected;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: durationDays,
                    decoration: const InputDecoration(
                      labelText: 'Meal duration',
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 day')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                    ],
                    onChanged: isLoading ? null : onDurationChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: budgetController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Budget',
                      prefixIcon: Icon(Icons.savings_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Goal',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ingredientsController,
              enabled: !isLoading,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ingredients',
                hintText: 'rice, chicken, vegetables',
                prefixIcon: Icon(Icons.kitchen_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preferenceOptions.map((preference) {
                final selected = preferences.contains(preference);
                return FilterChip(
                  label: Text(preference),
                  selected: selected,
                  avatar: Icon(selected ? Icons.check : Icons.add, size: 18),
                  onSelected: isLoading
                      ? null
                      : (value) => onPreferenceSelected(preference, value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPlanView extends StatelessWidget {
  const _MealPlanView({
    required this.plan,
    required this.onSave,
    required this.onShare,
  });

  final MealPlan plan;
  final VoidCallback onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.durationDays} days  |  ${plan.goal.isEmpty ? 'Balanced eating' : plan.goal}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Save plan',
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Share plan',
              onPressed: onShare,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CalendarStrip(days: plan.days),
        const SizedBox(height: 12),
        ...plan.days.map((day) => _DayCard(day: day)),
      ],
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({required this.days});

  final List<MealPlanDay> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          return Container(
            width: 86,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Day',
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${day.dayNumber}',
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final MealPlanDay day;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        initiallyExpanded: day.dayNumber == 1,
        title: Text(
          day.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: const Icon(Icons.event_note),
        children: day.meals.map((meal) => _MealTile(meal: meal)).toList(),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${meal.type}: ${meal.name}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  Text(meal.prepTime),
                ],
              ),
              if (meal.calories != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${meal.calories} calories',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meal.ingredients
                    .map((ingredient) => Chip(label: Text(ingredient)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              ...meal.instructions.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- '),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingTab extends StatelessWidget {
  const _ShoppingTab({required this.plan, required this.onShare});

  final MealPlan? plan;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return const _EmptyState(
        icon: Icons.checklist,
        title: 'No shopping list yet',
        body: 'Generate a meal plan to extract its ingredients automatically.',
      );
    }

    final items = plan!.shoppingList;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Grocery checklist',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Share shopping list',
              onPressed: onShare,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => CheckboxListTile(
            value: false,
            onChanged: (_) {},
            title: Text(item),
          ),
        ),
      ],
    );
  }
}

class _SavedPlansTab extends StatelessWidget {
  const _SavedPlansTab({
    required this.plans,
    required this.onOpen,
    required this.onDelete,
  });

  final List<MealPlan> plans;
  final ValueChanged<MealPlan> onOpen;
  final ValueChanged<MealPlan> onDelete;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const _EmptyState(
        icon: Icons.bookmark_border,
        title: 'No saved plans',
        body: 'Save generated plans to revisit them later.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(plan.title),
            subtitle: Text(
              '${plan.durationDays} days  |  ${plan.shoppingList.length} grocery items',
            ),
            onTap: () => onOpen(plan),
            trailing: IconButton(
              tooltip: 'Delete plan',
              onPressed: () => onDelete(plan),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
