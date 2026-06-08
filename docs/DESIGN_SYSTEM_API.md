# CarCare Pro — Internal API Cheat Sheet

Authoritative reference for building feature screens consistently. Read the
referenced source files to confirm exact signatures before using them.

## Imports use relative paths
A screen in `lib/features/<x>/<screen>.dart` reaches `lib/` with `../../`.

## Theme tokens
- `themes/app_colors.dart` → `AppColors.{primary,secondary,tertiary,success,warning,danger,info,accentPink,accentAmber}`,
  gradients `{brandGradient,mintGradient,sunsetGradient,healthGoodGradient,healthWarnGradient}`,
  `AppColors.forScore(double)→Color`, `AppColors.gradientForScore(double)`.
- `themes/app_dimens.dart` → `AppDimens.{xs=4,sm=8,md=12,lg=16,xl=24,xxl=32,xxxl=48}`,
  `radius{Sm=14,Md=20,Lg=24,Xl=28}`, `br{Sm,Md,Lg,Xl}` (BorderRadius), `blur{Soft,Medium,Strong}`,
  `screenPadding`, `cardPadding`. `AppMotion.{fast,medium,slow,page}` (Duration), `{spring,emphasized,standard}` (Curve).
- `themes/app_theme.dart` → `Theme.of(context).extension<GlassTokens>()!` →
  `.fill .fillStrong .border .highlight .shadow .textPrimary .textMuted .background .brightness`.

## Glass widgets (`lib/widgets/...`)
- `glass/glass_container.dart` → `GlassContainer({required child, padding, margin, borderRadius, blur, strong, gradient, border, shadow, width, height, alignment})`
- `glass/glass_card.dart` → `GlassCard({required child, onTap, padding, margin, borderRadius, blur, strong, gradient, width, height})`
- `glass/glass_button.dart` → `GlassButton({required label, onPressed, icon, variant:GlassButtonVariant.{primary,glass,ghost}, gradient, expand=true, loading=false})`
- `glass/glass_scaffold.dart` → `GlassScaffold({required body, appBar, bottomNavigationBar, floatingActionButton, floatingActionButtonLocation, extendBody, extendBodyBehindAppBar, animateBackground})` — provides its own animated background.
- `glass/glass_app_bar.dart` → `GlassAppBar({required title, subtitle, leading, actions, showBack})` (PreferredSizeWidget); `CircleGlassButton({required icon, required onTap, badge})`.
- `glass/frosted_background.dart` → `FrostedBackground({required child, animate})`.
- `common/section_header.dart` → `SectionHeader({required title, actionLabel, onAction, icon})`; `GradientText(text, {required style, gradient, textAlign})`.
- `common/stat_tile.dart` → `StatTile({required icon, required label, required value, unit, gradient, onTap, trend})`.
- `common/glass_text_field.dart` → `GlassTextField({required controller, label, hint, prefixIcon, suffixIcon, obscureText, keyboardType, validator, onChanged, inputFormatters, maxLines, textInputAction, readOnly, onTap})`.
- `common/glass_sheet.dart` → `showGlassSheet<T>(context, {required child})`; `showGlassConfirm(context, {required title, message, confirmLabel, cancelLabel, destructive})→Future<bool>`.
- `indicators/circular_health_indicator.dart` → `CircularHealthIndicator({required value, size, label, strokeWidth})`; `MiniHealthRing({required value, required icon, required label, size})`.
- `states/empty_state.dart` → `EmptyState({required icon, required title, required message, actionLabel, onAction})`.
- `states/loading_state.dart` → `ShimmerBox({height,width,radius})`; `GlassLoader({message})`.

## Models (`lib/models/...`)
- `enums.dart`: `FuelType`, `TransmissionType`, `MaintenanceType` (12), `ExpenseCategory` (9), `DocumentType` (5). Each has `.labelKey`. `MaintenanceType.defaultInterval` → `MaintenanceInterval{km,months}`.
- `vehicle.dart` `Vehicle(id,brand,model,year,trim,engine,fuelType,transmission,plateNumber,vin,currentMileage,imageUrl,colorHex,insuranceExpiry,licenseExpiry,inspectionDate,isPrimary,createdAt)`; `.title`, `.subtitle`, `copyWith(...)`.
- `maintenance_record.dart` `MaintenanceRecord(id,vehicleId,type,changeDate,changeMileage,nextDueMileage,nextDueDate,cost,notes,invoiceImages,createdAt)`.
- `fuel_log.dart` `FuelLog(id,vehicleId,date,odometer,liters,cost,station,fullTank,createdAt)`; `.pricePerLiter`.
- `expense.dart` `Expense(id,vehicleId,category,amount,date,title,notes,createdAt)`.
- `vehicle_document.dart` `VehicleDocument(id,vehicleId,type,title,fileUrl,localPath,expiryDate,issueDate,notes,createdAt)`; `.isExpired`.
- `app_user.dart` `AppUser`; `.displayName`, `.initials`.

## Providers (`flutter_riverpod`, `lib/providers/...`)
- `settings_provider.dart`: `settingsProvider`; `SettingsState{themeMode,locale,notificationsEnabled,reminderDays,onboardingComplete,reminderToggles,isArabic}`; notifier: `setThemeMode/setLocale/toggleLanguage/setNotificationsEnabled/setReminderDays/setReminderToggle/completeOnboarding`. `localeProvider`, `themeModeProvider`.
- `auth_provider.dart`: `authControllerProvider`; `AuthState{user,loading,errorKey,isAuthenticated}`; notifier: `signIn/signUp/signInWithGoogle/signInWithApple/sendPasswordReset/resendVerification/refreshVerification/signOut/deleteAccount/clearError`.
- `vehicle_provider.dart`: `vehiclesProvider`; `VehiclesState{vehicles,selectedId,selected,isEmpty}`; notifier: `select(id)/addOrUpdate(Vehicle,{isNew})/draft()→Vehicle/delete(id)/updateMileage(int)`. `selectedVehicleProvider→Vehicle?`.
- `data_providers.dart`: `maintenanceListProvider`, `fuelListProvider`, `expenseListProvider`, `documentListProvider`, `latestMaintenanceByTypeProvider`, `vehicleHealthProvider→VehicleHealth{overall,oil,battery,tires,insurance,items:List<MaintenanceStatusInfo>}`, `advisorProvider→List<AdvisorRecommendation>`, `fuelStatsProvider→FuelStats{kmPerLiter,costPerKm,monthlySpend,yearlySpend,totalLiters,avgPrice}`, `expenseStatsProvider→ExpenseStats{total,monthly,yearly,byCategory:Map<ExpenseCategory,double>,monthlySeries:List<double>(6 oldest→newest)}`.
- `data_controller.dart`: `dataControllerProvider→DataController{saveMaintenance,deleteMaintenance,saveFuel,deleteFuel,saveExpense,deleteExpense,saveDocument,deleteDocument,rescheduleReminders}`. `defaultNextDue(MaintenanceRecord)→({int mileage,DateTime date})`. `VehicleExpiryX.nextExpiry` on Vehicle.

## Services
- `health_service.dart`: `DueStatus{ok,dueSoon,overdue,unknown}`; `MaintenanceStatusInfo{type,status,lifeUsed,score,nextDueMileage,nextDueDate,kmRemaining,daysRemaining,hasRecord}`.
- `ai_advisor_service.dart`: `AdvisorRecommendation{kind,priority,type,kmRemaining,daysRemaining}`, enums `AdvisorPriority`, `AdvisorKind`.
- `features/advisor/advisor_presentation.dart`: `AdvisorView.from(rec, l)` → `{title,body,icon,color,priorityLabel}`.

## Localization
- `context.l10n` → `AppLocalizations`; `context.tr('key', params:{...})`; `l.t('key')`; `l.isArabic`.
- Keys live in `lib/localization/app_strings.dart` (read it). **Do not edit app_strings.dart** (avoids concurrent-edit conflicts); for any string with no existing key, write `l.isArabic ? 'عربى' : 'English'` inline.

## Formatters & catalog
- `core/formatters.dart`: `Fmt.{date,monthYear,shortDate,number(value,{decimals,locale}),money(value,{required currency,locale}),distance,relativeDays}`. Get `locale = ref.watch(settingsProvider).locale.languageCode`.
- `core/ui_catalog.dart`: `UiCatalog.{maintenanceIcon,maintenanceGradient,expenseIcon,expenseColor,documentIcon,fuelIcon}`.

## Routing
- `core/router/app_router.dart`: `AppRoutes.{home,maintenance,fuel,expenses,more,vehicles,addVehicle,documents,analytics,advisor,profile,settings}`. `context.push(...)` for stacked screens, `context.go(...)` to switch tabs. `import 'package:go_router/go_router.dart';`

## Conventions (MUST follow)
1. **Tab screens** (`maintenance/fuel/expenses/more`): return `Scaffold(backgroundColor: Colors.transparent, ...)`. Do NOT wrap in `FrostedBackground` (the shell already does). Add `~130` bottom padding to scroll content so the floating nav doesn't overlap. May use `floatingActionButton`.
2. **Pushed screens** (`vehicles/add_vehicle/documents/analytics/advisor/profile/settings`): use `GlassScaffold(appBar: GlassAppBar(title: ..., showBack: true), body: ...)`.
3. Use `ConsumerWidget` / `ConsumerStatefulWidget`.
4. Colors: use `.withValues(alpha: x)` — never `.withOpacity`.
5. IDs: `import 'package:uuid/uuid.dart';` then `const Uuid().v4()`. Timestamps: `DateTime.now()`.
6. Enum selection UI: prefer a wrap of selectable glass chips over raw `DropdownButton`.
7. Entrance polish: `import 'package:flutter_animate/flutter_animate.dart';` then `.animate().fadeIn(...).moveY(begin:14,end:0)`.
8. When `selectedVehicleProvider` is null on a data screen, show `EmptyState` pointing to `AppRoutes.addVehicle`.
9. Add/edit flows: `showGlassSheet(context, child: <StatefulForm>)`; on save call the `dataController`, then `Navigator.pop(context)`.
10. Currency label: `l.t('currency')`. Distance unit: `l.t('km')`.
11. Do NOT create new files under `lib/widgets`, `lib/providers`, `lib/services`, `lib/models`, `lib/core` — only add files inside your assigned `lib/features/<area>/` folder. Reuse the shared widgets above.
