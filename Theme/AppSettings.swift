import SwiftUI

enum AppPreferenceKeys {
    static let appearance = "app.appearance"
    static let textSize = "app.textSize"
    static let language = "app.language"
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

enum AppTextSize: String, CaseIterable, Identifiable {
    case xs
    case small
    case medium
    case large
    case xl

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .xs:
            return 0.9
        case .small:
            return 1.02
        case .medium:
            return 1.16
        case .large:
            return 1.3
        case .xl:
            return 1.48
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case spanish

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en")
        case .spanish:
            return Locale(identifier: "es")
        }
    }
}

struct AppStrings {
    let appName: String
    let quickAddTab: String
    let dashboardTab: String
    let historyTab: String
    let insightsTab: String
    let goalsTab: String
    let quickAddHeader: String
    let dashboardHeader: String
    let historyHeader: String
    let insightsHeader: String
    let goalsHeader: String
    let settingsTitle: String
    let settingsDescription: String
    let appearanceTitle: String
    let appearanceDescription: String
    let textSizeTitle: String
    let textSizeDescription: String
    let languageTitle: String
    let languageDescription: String
    let privacyTitle: String
    let privacyNote: String
    let dataTitle: String
    let exportData: String
    let exportDescription: String
    let aboutTitle: String
    let aboutDescription: String
    let versionLabel: String
    let resetTitle: String
    let resetButton: String
    let resetConfirmationTitle: String
    let resetConfirmationMessage: String
    let deleteAllExpenses: String
    let cancel: String
    let backTapTitle: String
    let backTapDescription: String
    let copyQuickAddURL: String
    let openQuickAdd: String
    let openHistoryExports: String
    let openGoals: String
    let openHistory: String
    let appearance: String
    let textSize: String
    let language: String
    let resetLocalData: String
    let backTapQuickAdd: String
    let emptyNoExpenses: String
    let emptyNoInsights: String
    let emptyNoGoals: String
    let done: String
    let amountTitle: String
    let amountPlaceholder: String
    let quickAddIntro: String
    let next: String
    let categoryTitle: String
    let categorySubtitle: String
    let detailsTitle: String
    let merchantPlaceholder: String
    let notePlaceholder: String
    let pasteTitle: String
    let pasteDescription: String
    let parseTextButton: String
    let useParsedExpenseButton: String
    let saveExpenseButton: String
    let expenseSaved: String
    let dashboardQuickSnapshotTitle: String
    let dashboardCategoryDistributionTitle: String
    let dashboardRecentTrendTitle: String
    let dashboardNoCategoryDistribution: String
    let dashboardNoRecentTrend: String
    let historyExportsTitle: String
    let historyFilterTitle: String
    let historyCategoryTitle: String
    let historyResetFilters: String
    let historyNoMatchingExpenses: String
    let exportCSV: String
    let exportJSON: String
    let exportMonthlySummary: String
    let insightsWeeklyTotalsTitle: String
    let insightsCategoryBreakdownTitle: String
    let insightsNoCategoryBreakdown: String
    let goalsWeeklyTitle: String
    let goalsMonthlyTitle: String
    let goalsCreateWeekly: String
    let goalsCreateMonthly: String
    let goalsEdit: String
    let goalsRemove: String
    let goalsLimitLabel: String
    let goalsSpentLabel: String
    let goalsRemainingLabel: String
    let goalsStatusOnTrack: String
    let goalsStatusCloseToLimit: String
    let goalsStatusLimitReached: String
    let goalsEmptyWeekly: String
    let goalsEmptyMonthly: String
    let goalsEditorTitle: String
    let goalsGoalLogicDescription: String
    let goalsRemoveConfirmationTitle: String
    let goalsRemoveConfirmationMessage: String

    static func current() -> AppStrings {
        let language = AppLanguage.current
        switch language {
        case .english:
            return AppStrings(
                appName: "Pocket Leak",
                quickAddTab: "Quick Add",
                dashboardTab: "Dashboard",
                historyTab: "History",
                insightsTab: "Insights",
                goalsTab: "Goals",
                quickAddHeader: "Quick Add",
                dashboardHeader: "Dashboard",
                historyHeader: "History",
                insightsHeader: "Insights",
                goalsHeader: "Goals",
                settingsTitle: "Settings",
                settingsDescription: "Minimal local-first expense capture with parsing, exports, and goal tracking.",
                appearanceTitle: "Appearance",
                appearanceDescription: "System follows device appearance. Dark keeps the premium black shell. Light flips the palette for contrast testing.",
                textSizeTitle: "Text Size",
                textSizeDescription: "This scales headers, subtitles, cards, buttons, tab labels, and input fields across the app.",
                languageTitle: "Language",
                languageDescription: "Language updates the main tabs, headers, empty states, settings, and Back Tap instructions.",
                privacyTitle: "Privacy",
                privacyNote: "Pocket Leak stores expenses locally and only parses text you paste manually.",
                dataTitle: "Data",
                exportData: "Export Data",
                exportDescription: "Open History to share CSV, JSON, or the monthly summary report.",
                aboutTitle: "About",
                aboutDescription: "Built for fast, local-first capture.",
                versionLabel: "Version",
                resetTitle: "Reset",
                resetButton: "Reset Local Data",
                resetConfirmationTitle: "Reset local data?",
                resetConfirmationMessage: "This deletes the local expense store on this device. It cannot be undone.",
                deleteAllExpenses: "Delete All Expenses",
                cancel: "Cancel",
                backTapTitle: "Back Tap Quick Add",
                backTapDescription: "iOS cannot let Pocket Leak detect Back Tap directly. Use a Shortcut that opens pocketleak://quick-add, then assign that Shortcut to Back Tap.",
                copyQuickAddURL: "Copy pocketleak://quick-add",
                openQuickAdd: "Open Quick Add",
                openHistoryExports: "Open History Exports",
                openGoals: "Open Goals",
                openHistory: "Open History",
                appearance: "Appearance",
                textSize: "Text Size",
                language: "Language",
                resetLocalData: "Reset Local Data",
                backTapQuickAdd: "Back Tap Quick Add",
                emptyNoExpenses: "Add your first micro-expense from Quick Add.",
                emptyNoInsights: "Add a few expenses and the app will surface spending patterns here.",
                emptyNoGoals: "Create a spending goal to track your limit.",
                done: "Done",
                amountTitle: "Amount",
                amountPlaceholder: "0.00",
                quickAddIntro: "Capture a micro-expense in under 10 seconds.",
                next: "Next",
                categoryTitle: "Category",
                categorySubtitle: "Pick the closest match first. You can always adjust it later.",
                detailsTitle: "Details",
                merchantPlaceholder: "Optional merchant",
                notePlaceholder: "Optional note",
                pasteTitle: "Paste Notification Text",
                pasteDescription: "Paste a bank alert or transaction message. Pocket Leak only parses text you paste yourself, keeping the flow privacy-safe.",
                parseTextButton: "Parse Text",
                useParsedExpenseButton: "Use Parsed Expense",
                saveExpenseButton: "Save Expense",
                expenseSaved: "Expense saved",
                dashboardQuickSnapshotTitle: "Quick Snapshot",
                dashboardCategoryDistributionTitle: "Category Distribution",
                dashboardRecentTrendTitle: "Recent Spending Trend",
                dashboardNoCategoryDistribution: "Add a few expenses to see where the leaks cluster.",
                dashboardNoRecentTrend: "Add expenses to see your recent spending trend.",
                historyExportsTitle: "Exports",
                historyFilterTitle: "History",
                historyCategoryTitle: "Category",
                historyResetFilters: "Reset",
                historyNoMatchingExpenses: "Try a different category or time filter.",
                exportCSV: "Export CSV",
                exportJSON: "Export JSON",
                exportMonthlySummary: "Share Monthly Summary",
                insightsWeeklyTotalsTitle: "Weekly Totals",
                insightsCategoryBreakdownTitle: "Category Breakdown",
                insightsNoCategoryBreakdown: "No category breakdown yet.",
                goalsWeeklyTitle: "Weekly Goal",
                goalsMonthlyTitle: "Monthly Goal",
                goalsCreateWeekly: "Create Weekly Goal",
                goalsCreateMonthly: "Create Monthly Goal",
                goalsEdit: "Edit",
                goalsRemove: "Remove",
                goalsLimitLabel: "Limit",
                goalsSpentLabel: "Spent",
                goalsRemainingLabel: "Remaining",
                goalsStatusOnTrack: "On track",
                goalsStatusCloseToLimit: "Close to limit",
                goalsStatusLimitReached: "Limit reached",
                goalsEmptyWeekly: "No weekly goal yet.",
                goalsEmptyMonthly: "No monthly goal yet.",
                goalsEditorTitle: "Goal Editor",
                goalsGoalLogicDescription: "Goal logic is simple: stay under the selected limit by week or by month.",
                goalsRemoveConfirmationTitle: "Remove spending goal?",
                goalsRemoveConfirmationMessage: "This removes the local goal from this device."
            )
        case .spanish:
            return AppStrings(
                appName: "Pocket Leak",
                quickAddTab: "Captura",
                dashboardTab: "Panel",
                historyTab: "Historial",
                insightsTab: "Análisis",
                goalsTab: "Metas",
                quickAddHeader: "Captura rápida",
                dashboardHeader: "Panel",
                historyHeader: "Historial",
                insightsHeader: "Análisis",
                goalsHeader: "Metas",
                settingsTitle: "Ajustes",
                settingsDescription: "Captura de gastos minimalista y local con análisis, exportaciones y metas.",
                appearanceTitle: "Apariencia",
                appearanceDescription: "Sistema sigue la apariencia del dispositivo. Oscuro mantiene la shell negra premium. Claro cambia la paleta para pruebas.",
                textSizeTitle: "Tamaño de texto",
                textSizeDescription: "Esto escala encabezados, subtítulos, tarjetas, botones, tabs y campos de entrada en toda la app.",
                languageTitle: "Idioma",
                languageDescription: "El idioma actualiza las tabs principales, encabezados, estados vacíos, ajustes e instrucciones de Back Tap.",
                privacyTitle: "Privacidad",
                privacyNote: "Pocket Leak guarda los gastos localmente y solo analiza texto que tú pegas manualmente.",
                dataTitle: "Datos",
                exportData: "Exportar datos",
                exportDescription: "Abre Historial para compartir CSV, JSON o el resumen mensual.",
                aboutTitle: "Acerca de",
                aboutDescription: "Hecho para captura rápida y local-first.",
                versionLabel: "Versión",
                resetTitle: "Restablecer",
                resetButton: "Borrar datos locales",
                resetConfirmationTitle: "¿Borrar datos locales?",
                resetConfirmationMessage: "Esto borra el almacenamiento local de gastos en este dispositivo. No se puede deshacer.",
                deleteAllExpenses: "Borrar todos los gastos",
                cancel: "Cancelar",
                backTapTitle: "Quick Add con Back Tap",
                backTapDescription: "iOS no permite que Pocket Leak detecte Back Tap directamente. Usa un Shortcut que abra pocketleak://quick-add y asígnalo a Back Tap.",
                copyQuickAddURL: "Copiar pocketleak://quick-add",
                openQuickAdd: "Abrir Captura",
                openHistoryExports: "Abrir exportaciones",
                openGoals: "Abrir metas",
                openHistory: "Abrir historial",
                appearance: "Apariencia",
                textSize: "Tamaño de texto",
                language: "Idioma",
                resetLocalData: "Borrar datos locales",
                backTapQuickAdd: "Quick Add con Back Tap",
                emptyNoExpenses: "Agrega tu primer microgasto desde Captura.",
                emptyNoInsights: "Agrega algunos gastos y aquí aparecerán patrones de gasto.",
                emptyNoGoals: "Crea una meta de gasto para seguir tu límite.",
                done: "Listo",
                amountTitle: "Monto",
                amountPlaceholder: "0.00",
                quickAddIntro: "Captura un microgasto en menos de 10 segundos.",
                next: "Siguiente",
                categoryTitle: "Categoría",
                categorySubtitle: "Elige la coincidencia más cercana primero. Luego puedes ajustarla.",
                detailsTitle: "Detalles",
                merchantPlaceholder: "Comerciante opcional",
                notePlaceholder: "Nota opcional",
                pasteTitle: "Pegar texto de notificación",
                pasteDescription: "Pega una alerta bancaria o mensaje de transacción. Pocket Leak solo analiza texto que tú pegas, manteniendo el flujo privado.",
                parseTextButton: "Analizar texto",
                useParsedExpenseButton: "Usar gasto analizado",
                saveExpenseButton: "Guardar gasto",
                expenseSaved: "Gasto guardado",
                dashboardQuickSnapshotTitle: "Resumen rápido",
                dashboardCategoryDistributionTitle: "Distribución por categoría",
                dashboardRecentTrendTitle: "Tendencia reciente",
                dashboardNoCategoryDistribution: "Agrega algunos gastos para ver dónde se concentran las fugas.",
                dashboardNoRecentTrend: "Agrega gastos para ver tu tendencia reciente.",
                historyExportsTitle: "Exportaciones",
                historyFilterTitle: "Historial",
                historyCategoryTitle: "Categoría",
                historyResetFilters: "Restablecer",
                historyNoMatchingExpenses: "Prueba otra categoría o filtro de tiempo.",
                exportCSV: "Exportar CSV",
                exportJSON: "Exportar JSON",
                exportMonthlySummary: "Compartir resumen mensual",
                insightsWeeklyTotalsTitle: "Totales semanales",
                insightsCategoryBreakdownTitle: "Desglose por categoría",
                insightsNoCategoryBreakdown: "Aún no hay desglose por categoría.",
                goalsWeeklyTitle: "Meta semanal",
                goalsMonthlyTitle: "Meta mensual",
                goalsCreateWeekly: "Crear meta semanal",
                goalsCreateMonthly: "Crear meta mensual",
                goalsEdit: "Editar",
                goalsRemove: "Eliminar",
                goalsLimitLabel: "Límite",
                goalsSpentLabel: "Gastado",
                goalsRemainingLabel: "Restante",
                goalsStatusOnTrack: "En control",
                goalsStatusCloseToLimit: "Cerca del límite",
                goalsStatusLimitReached: "Límite alcanzado",
                goalsEmptyWeekly: "Todavía no hay meta semanal.",
                goalsEmptyMonthly: "Todavía no hay meta mensual.",
                goalsEditorTitle: "Editor de metas",
                goalsGoalLogicDescription: "La lógica es simple: mantente por debajo del límite seleccionado por semana o por mes.",
                goalsRemoveConfirmationTitle: "¿Eliminar meta de gasto?",
                goalsRemoveConfirmationMessage: "Esto elimina la meta local de este dispositivo."
            )
        }
    }
}

extension AppLanguage {
    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: AppPreferenceKeys.language) ?? AppLanguage.english.rawValue
        return AppLanguage(rawValue: raw) ?? .english
    }
}

enum AppTypography {
    static func scale(for textSize: AppTextSize) -> CGFloat {
        textSize.scale
    }

    static func scaled(_ value: CGFloat, using textSize: AppTextSize) -> CGFloat {
        value * textSize.scale
    }
}

private struct AppAppearanceKey: EnvironmentKey {
    static let defaultValue: AppAppearance = .dark
}

private struct AppTextSizeKey: EnvironmentKey {
    static let defaultValue: AppTextSize = .medium
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .english
}

private struct AppStringsKey: EnvironmentKey {
    static let defaultValue: AppStrings = .current()
}

extension EnvironmentValues {
    var appAppearance: AppAppearance {
        get { self[AppAppearanceKey.self] }
        set { self[AppAppearanceKey.self] = newValue }
    }

    var appTextSize: AppTextSize {
        get { self[AppTextSizeKey.self] }
        set { self[AppTextSizeKey.self] = newValue }
    }

    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }

    var pocketLeakStrings: AppStrings {
        get { self[AppStringsKey.self] }
        set { self[AppStringsKey.self] = newValue }
    }
}
