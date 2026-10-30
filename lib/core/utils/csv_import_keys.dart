// Matching keys shared by the CSV import preview (features/) and its
// commit (data/), so the preview's Salary count and the committed
// routing cannot disagree.

/// Matching normalization: trim, and fold Latin case. CJK compares
/// exactly; there is no Traditional/Simplified conversion.
String normalizeImportKey(String value) => value.trim().toLowerCase();

/// Whether an income row with [memo] goes to Salary. Every entry in
/// [normalizedSalaryNotes] must already be [normalizeImportKey]-ed.
bool isSalaryNote(String? memo, Set<String> normalizedSalaryNotes) =>
    memo != null && normalizedSalaryNotes.contains(normalizeImportKey(memo));
