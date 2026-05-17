// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFormState {

/// Discriminates which entry point opened the form so widgets can derive
/// titles, CTAs, and recovery behavior directly from state.
 TransactionFormMode get formMode;
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormStateCopyWith<TransactionFormState> get copyWith => _$TransactionFormStateCopyWithImpl<TransactionFormState>(this as TransactionFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


 @override
 int get hashCode => Object.hash(runtimeType, formMode);

 @override
 String toString() {
   return 'TransactionFormState(formMode: $formMode)';
 }
}

/// @nodoc
abstract mixin class $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormStateCopyWith(TransactionFormState value,
      $Res Function(TransactionFormState) _then) = _$TransactionFormStateCopyWithImpl;

  @useResult
  $Res call({
    TransactionFormMode formMode
  });
}

/// @nodoc
class _$TransactionFormStateCopyWithImpl<$Res>
    implements $TransactionFormStateCopyWith<$Res> {
  _$TransactionFormStateCopyWithImpl(this._self, this._then);

  final TransactionFormState _self;
  final $Res Function(TransactionFormState) _then;

  /// Create a copy of TransactionFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? formMode = null,}) {
    return _then(_self.copyWith(
      formMode: null == formMode
          ? _self.formMode
          : formMode // ignore: cast_nullable_to_non_nullable
      as TransactionFormMode,
    ));
  }
}


/// Adds pattern-matching-related methods to [TransactionFormState].
extension TransactionFormStatePatterns on TransactionFormState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransactionFormLoading value)?  loading,TResult Function( TransactionFormEmpty value)?  empty,TResult Function( TransactionFormData value)?  data,TResult Function( TransactionFormError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that);case TransactionFormEmpty() when empty != null:
return empty(_that);case TransactionFormData() when data != null:
return data(_that);case TransactionFormError() when error != null:
return error(_that);case _:
return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransactionFormLoading value)  loading,required TResult Function( TransactionFormEmpty value)  empty,required TResult Function( TransactionFormData value)  data,required TResult Function( TransactionFormError value)  error,}){
final _that = this;
switch (_that) {
case TransactionFormLoading():
return loading(_that);case TransactionFormEmpty():
return empty(_that);case TransactionFormData():
return data(_that);case TransactionFormError():
return error(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransactionFormLoading value)?  loading,TResult? Function( TransactionFormEmpty value)?  empty,TResult? Function( TransactionFormData value)?  data,TResult? Function( TransactionFormError value)?  error,}){
final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that);case TransactionFormEmpty() when empty != null:
return empty(_that);case TransactionFormData() when data != null:
return data(_that);case TransactionFormError() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TransactionFormMode formMode)?  loading,TResult Function( TransactionFormEmptyReason reason,  TransactionFormMode formMode)?  empty,TResult Function( TransactionFormMode formMode,  int amountMinorUnits,  KeypadState keypad,  Account? selectedAccount,  Currency? displayCurrency,  bool currencyTouched,  Category? selectedCategory,  CategoryType pendingType,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  int? duplicateSourceId,  DateTime? originalCreatedAt,  int keypadRevision,  int? shoppingListItemId,  TransactionFormSubmissionAction submissionAction,  bool selectedAccountIsArchived,  bool selectedCategoryIsArchived)?  data,TResult Function( Object error,  StackTrace stack,  TransactionFormMode formMode)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that.formMode);case TransactionFormEmpty() when empty != null:
return empty(_that.reason,_that.formMode);case TransactionFormData() when data != null:
return data(_that.formMode,_that.amountMinorUnits,_that.keypad,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.pendingType,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.duplicateSourceId,_that.originalCreatedAt,_that.keypadRevision,_that.shoppingListItemId,_that.submissionAction,_that.selectedAccountIsArchived,_that.selectedCategoryIsArchived);case TransactionFormError() when error != null:
return error(_that.error,_that.stack,_that.formMode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TransactionFormMode formMode)  loading,required TResult Function( TransactionFormEmptyReason reason,  TransactionFormMode formMode)  empty,required TResult Function( TransactionFormMode formMode,  int amountMinorUnits,  KeypadState keypad,  Account? selectedAccount,  Currency? displayCurrency,  bool currencyTouched,  Category? selectedCategory,  CategoryType pendingType,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  int? duplicateSourceId,  DateTime? originalCreatedAt,  int keypadRevision,  int? shoppingListItemId,  TransactionFormSubmissionAction submissionAction,  bool selectedAccountIsArchived,  bool selectedCategoryIsArchived)  data,required TResult Function( Object error,  StackTrace stack,  TransactionFormMode formMode)  error,}) {final _that = this;
switch (_that) {
case TransactionFormLoading():
return loading(_that.formMode);case TransactionFormEmpty():
return empty(_that.reason,_that.formMode);case TransactionFormData():
return data(_that.formMode,_that.amountMinorUnits,_that.keypad,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.pendingType,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.duplicateSourceId,_that.originalCreatedAt,_that.keypadRevision,_that.shoppingListItemId,_that.submissionAction,_that.selectedAccountIsArchived,_that.selectedCategoryIsArchived);case TransactionFormError():
return error(_that.error,_that.stack,_that.formMode);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TransactionFormMode formMode)?  loading,TResult? Function( TransactionFormEmptyReason reason,  TransactionFormMode formMode)?  empty,TResult? Function( TransactionFormMode formMode,  int amountMinorUnits,  KeypadState keypad,  Account? selectedAccount,  Currency? displayCurrency,  bool currencyTouched,  Category? selectedCategory,  CategoryType pendingType,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  int? duplicateSourceId,  DateTime? originalCreatedAt,  int keypadRevision,  int? shoppingListItemId,  TransactionFormSubmissionAction submissionAction,  bool selectedAccountIsArchived,  bool selectedCategoryIsArchived)?  data,TResult? Function( Object error,  StackTrace stack,  TransactionFormMode formMode)?  error,}) {final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that.formMode);case TransactionFormEmpty() when empty != null:
return empty(_that.reason,_that.formMode);case TransactionFormData() when data != null:
return data(_that.formMode,_that.amountMinorUnits,_that.keypad,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.pendingType,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.duplicateSourceId,_that.originalCreatedAt,_that.keypadRevision,_that.shoppingListItemId,_that.submissionAction,_that.selectedAccountIsArchived,_that.selectedCategoryIsArchived);case TransactionFormError() when error != null:
return error(_that.error,_that.stack,_that.formMode);case _:
  return null;

}
}

}

/// @nodoc


class TransactionFormLoading extends TransactionFormState {
  const TransactionFormLoading({this.formMode = const AddTransactionMode()}): super._();


@override@JsonKey() final  TransactionFormMode formMode;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormLoadingCopyWith<TransactionFormLoading> get copyWith => _$TransactionFormLoadingCopyWithImpl<TransactionFormLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormLoading&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


@override
int get hashCode => Object.hash(runtimeType,formMode);

@override
String toString() {
  return 'TransactionFormState.loading(formMode: $formMode)';
}


}

/// @nodoc
abstract mixin class $TransactionFormLoadingCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormLoadingCopyWith(TransactionFormLoading value, $Res Function(TransactionFormLoading) _then) = _$TransactionFormLoadingCopyWithImpl;
@override @useResult
$Res call({
 TransactionFormMode formMode
});
}
/// @nodoc
class _$TransactionFormLoadingCopyWithImpl<$Res>
    implements $TransactionFormLoadingCopyWith<$Res> {
  _$TransactionFormLoadingCopyWithImpl(this._self, this._then);

  final TransactionFormLoading _self;
  final $Res Function(TransactionFormLoading) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formMode = null,}) {
  return _then(TransactionFormLoading(
formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}
}

/// @nodoc


class TransactionFormEmpty extends TransactionFormState {
  const TransactionFormEmpty({required this.reason, this.formMode = const AddTransactionMode()}): super._();


 final  TransactionFormEmptyReason reason;
@override@JsonKey() final  TransactionFormMode formMode;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormEmptyCopyWith<TransactionFormEmpty> get copyWith => _$TransactionFormEmptyCopyWithImpl<TransactionFormEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormEmpty&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


@override
int get hashCode => Object.hash(runtimeType,reason,formMode);

@override
String toString() {
  return 'TransactionFormState.empty(reason: $reason, formMode: $formMode)';
}


}

/// @nodoc
abstract mixin class $TransactionFormEmptyCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormEmptyCopyWith(TransactionFormEmpty value, $Res Function(TransactionFormEmpty) _then) = _$TransactionFormEmptyCopyWithImpl;
@override @useResult
$Res call({
 TransactionFormEmptyReason reason, TransactionFormMode formMode
});




}
/// @nodoc
class _$TransactionFormEmptyCopyWithImpl<$Res>
    implements $TransactionFormEmptyCopyWith<$Res> {
  _$TransactionFormEmptyCopyWithImpl(this._self, this._then);

  final TransactionFormEmpty _self;
  final $Res Function(TransactionFormEmpty) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? formMode = null,}) {
  return _then(TransactionFormEmpty(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TransactionFormEmptyReason,formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}


}

/// @nodoc


class TransactionFormData extends TransactionFormState {
  const TransactionFormData({required this.formMode, required this.amountMinorUnits, required this.keypad, required this.selectedAccount, required this.displayCurrency, required this.currencyTouched, required this.selectedCategory, required this.pendingType, required this.date, required this.memo, required this.isDirty, required this.isSaving, required this.isDeleting, required this.editingId, required this.duplicateSourceId, required this.originalCreatedAt, this.keypadRevision = 0, this.shoppingListItemId = null, this.submissionAction = TransactionFormSubmissionAction.none, this.selectedAccountIsArchived = false, this.selectedCategoryIsArchived = false}): super._();


/// Discriminates which entry point opened the form so widgets can derive
/// titles, CTAs, and recovery behavior directly from state.
@override final  TransactionFormMode formMode;
/// Keypad-accumulated integer in the active currency's minor units.
 final  int amountMinorUnits;
/// Full calculator snapshot used by the amount display and by widgets that
/// need to know whether a currency/account change would discard input.
 final  KeypadState keypad;
/// `null` only during `noActiveAccount` recovery flows; in normal
/// `.data` states an account is always selected.
 final  Account? selectedAccount;
/// The transaction's currency. Seeds from `selectedAccount.currency` on
/// hydration, but can be independently overridden by the user via the
/// currency picker. Once the user has made a manual selection,
/// `currencyTouched` is `true` and account changes no longer re-seed it.
 final  Currency? displayCurrency;
/// `true` once the user has manually selected a currency via the picker.
/// When `false`, account changes re-seed `displayCurrency` from the
/// new account's currency. When `true`, `displayCurrency` is user-owned
/// and account changes only update `selectedAccount`.
 final  bool currencyTouched;
 final  Category? selectedCategory;
/// Drives the picker filter before category selection. After a
/// category is selected, `selectedCategory.type` is the source of
/// truth; `pendingType` only differs during the confirm-then-clear
/// flow that swaps types.
 final  CategoryType pendingType;
 final  DateTime date;
/// Free-form note. Empty string is valid; nullability is collapsed
/// to "" so the controller never has to decide between `null` and
/// `''` on every keystroke.
 final  String memo;
/// Becomes true on the first user-driven mutation after hydration.
 final  bool isDirty;
/// `true` between `save()` await-start and resolution.
 final  bool isSaving;
/// `true` between `deleteExisting()` await-start and resolution.
 final  bool isDeleting;
/// Edit-mode target id. `null` in Add and Duplicate.
 final  int? editingId;
/// Source-id when opened via duplicate. `null` in Add and Edit.
 final  int? duplicateSourceId;
/// Edit-mode original `createdAt`, preserved on update so the
/// repository contract (`save` keeps stored `createdAt`) is honored
/// even if the controller round-trips through copyWith.
 final  DateTime? originalCreatedAt;
/// Incremented on every keypad mutation — including expression-only
/// transitions that leave `amountMinorUnits` unchanged — so Riverpod
/// rebuilds the form whenever the display state changes.
@JsonKey() final  int keypadRevision;
/// Non-null only in [EditShoppingListDraftMode]; stores the id of the
/// draft being edited so `saveDraft` and `convertDraft` can reference it.
@JsonKey() final  int? shoppingListItemId;
/// Tracks which async submission is currently in-flight. Used to
/// disable all CTAs and show a progress indicator on the active button.
@JsonKey() final  TransactionFormSubmissionAction submissionAction;
/// `true` when the selected account is archived. Only meaningful in
/// [EditShoppingListDraftMode]; blocks `canConvertDraft`.
@JsonKey() final  bool selectedAccountIsArchived;
/// `true` when the selected category is archived. Only meaningful in
/// [EditShoppingListDraftMode]; blocks `canConvertDraft`.
@JsonKey() final  bool selectedCategoryIsArchived;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormDataCopyWith<TransactionFormData> get copyWith => _$TransactionFormDataCopyWithImpl<TransactionFormData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormData&&(identical(other.formMode, formMode) || other.formMode == formMode)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.keypad, keypad) || other.keypad == keypad)&&(identical(other.selectedAccount, selectedAccount) || other.selectedAccount == selectedAccount)&&(identical(other.displayCurrency, displayCurrency) || other.displayCurrency == displayCurrency)&&(identical(other.currencyTouched, currencyTouched) || other.currencyTouched == currencyTouched)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.pendingType, pendingType) || other.pendingType == pendingType)&&(identical(other.date, date) || other.date == date)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isDeleting, isDeleting) || other.isDeleting == isDeleting)&&(identical(other.editingId, editingId) || other.editingId == editingId)&&(identical(other.duplicateSourceId, duplicateSourceId) || other.duplicateSourceId == duplicateSourceId)&&(identical(other.originalCreatedAt, originalCreatedAt) || other.originalCreatedAt == originalCreatedAt)&&(identical(other.keypadRevision, keypadRevision) || other.keypadRevision == keypadRevision)&&(identical(other.shoppingListItemId, shoppingListItemId) || other.shoppingListItemId == shoppingListItemId)&&(identical(other.submissionAction, submissionAction) || other.submissionAction == submissionAction)&&(identical(other.selectedAccountIsArchived, selectedAccountIsArchived) || other.selectedAccountIsArchived == selectedAccountIsArchived)&&(identical(other.selectedCategoryIsArchived, selectedCategoryIsArchived) || other.selectedCategoryIsArchived == selectedCategoryIsArchived));
}


@override
int get hashCode => Object.hashAll([runtimeType,formMode,amountMinorUnits,keypad,selectedAccount,displayCurrency,currencyTouched,selectedCategory,pendingType,date,memo,isDirty,isSaving,isDeleting,editingId,duplicateSourceId,originalCreatedAt,keypadRevision,shoppingListItemId,submissionAction,selectedAccountIsArchived,selectedCategoryIsArchived]);

@override
String toString() {
  return 'TransactionFormState.data(formMode: $formMode, amountMinorUnits: $amountMinorUnits, keypad: $keypad, selectedAccount: $selectedAccount, displayCurrency: $displayCurrency, currencyTouched: $currencyTouched, selectedCategory: $selectedCategory, pendingType: $pendingType, date: $date, memo: $memo, isDirty: $isDirty, isSaving: $isSaving, isDeleting: $isDeleting, editingId: $editingId, duplicateSourceId: $duplicateSourceId, originalCreatedAt: $originalCreatedAt, keypadRevision: $keypadRevision, shoppingListItemId: $shoppingListItemId, submissionAction: $submissionAction, selectedAccountIsArchived: $selectedAccountIsArchived, selectedCategoryIsArchived: $selectedCategoryIsArchived)';
}


}

/// @nodoc
abstract mixin class $TransactionFormDataCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormDataCopyWith(TransactionFormData value, $Res Function(TransactionFormData) _then) = _$TransactionFormDataCopyWithImpl;
@override @useResult
$Res call({
 TransactionFormMode formMode, int amountMinorUnits, KeypadState keypad, Account? selectedAccount, Currency? displayCurrency, bool currencyTouched, Category? selectedCategory, CategoryType pendingType, DateTime date, String memo, bool isDirty, bool isSaving, bool isDeleting, int? editingId, int? duplicateSourceId, DateTime? originalCreatedAt, int keypadRevision, int? shoppingListItemId, TransactionFormSubmissionAction submissionAction, bool selectedAccountIsArchived, bool selectedCategoryIsArchived
});


$AccountCopyWith<$Res>? get selectedAccount;$CurrencyCopyWith<$Res>? get displayCurrency;$CategoryCopyWith<$Res>? get selectedCategory;

}
/// @nodoc
class _$TransactionFormDataCopyWithImpl<$Res>
    implements $TransactionFormDataCopyWith<$Res> {
  _$TransactionFormDataCopyWithImpl(this._self, this._then);

  final TransactionFormData _self;
  final $Res Function(TransactionFormData) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formMode = null,Object? amountMinorUnits = null,Object? keypad = null,Object? selectedAccount = freezed,Object? displayCurrency = freezed,Object? currencyTouched = null,Object? selectedCategory = freezed,Object? pendingType = null,Object? date = null,Object? memo = null,Object? isDirty = null,Object? isSaving = null,Object? isDeleting = null,Object? editingId = freezed,Object? duplicateSourceId = freezed,Object? originalCreatedAt = freezed,Object? keypadRevision = null,Object? shoppingListItemId = freezed,Object? submissionAction = null,Object? selectedAccountIsArchived = null,Object? selectedCategoryIsArchived = null,}) {
  return _then(TransactionFormData(
formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,keypad: null == keypad ? _self.keypad : keypad // ignore: cast_nullable_to_non_nullable
as KeypadState,selectedAccount: freezed == selectedAccount ? _self.selectedAccount : selectedAccount // ignore: cast_nullable_to_non_nullable
as Account?,displayCurrency: freezed == displayCurrency ? _self.displayCurrency : displayCurrency // ignore: cast_nullable_to_non_nullable
as Currency?,currencyTouched: null == currencyTouched ? _self.currencyTouched : currencyTouched // ignore: cast_nullable_to_non_nullable
as bool,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as Category?,pendingType: null == pendingType ? _self.pendingType : pendingType // ignore: cast_nullable_to_non_nullable
as CategoryType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isDeleting: null == isDeleting ? _self.isDeleting : isDeleting // ignore: cast_nullable_to_non_nullable
as bool,editingId: freezed == editingId ? _self.editingId : editingId // ignore: cast_nullable_to_non_nullable
as int?,duplicateSourceId: freezed == duplicateSourceId ? _self.duplicateSourceId : duplicateSourceId // ignore: cast_nullable_to_non_nullable
as int?,originalCreatedAt: freezed == originalCreatedAt ? _self.originalCreatedAt : originalCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,keypadRevision: null == keypadRevision ? _self.keypadRevision : keypadRevision // ignore: cast_nullable_to_non_nullable
as int,shoppingListItemId: freezed == shoppingListItemId ? _self.shoppingListItemId : shoppingListItemId // ignore: cast_nullable_to_non_nullable
as int?,submissionAction: null == submissionAction ? _self.submissionAction : submissionAction // ignore: cast_nullable_to_non_nullable
as TransactionFormSubmissionAction,selectedAccountIsArchived: null == selectedAccountIsArchived ? _self.selectedAccountIsArchived : selectedAccountIsArchived // ignore: cast_nullable_to_non_nullable
as bool,selectedCategoryIsArchived: null == selectedCategoryIsArchived ? _self.selectedCategoryIsArchived : selectedCategoryIsArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res>? get selectedAccount {
    if (_self.selectedAccount == null) {
    return null;
  }

  return $AccountCopyWith<$Res>(_self.selectedAccount!, (value) {
    return _then(_self.copyWith(selectedAccount: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res>? get displayCurrency {
    if (_self.displayCurrency == null) {
    return null;
  }

  return $CurrencyCopyWith<$Res>(_self.displayCurrency!, (value) {
    return _then(_self.copyWith(displayCurrency: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get selectedCategory {
    if (_self.selectedCategory == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.selectedCategory!, (value) {
    return _then(_self.copyWith(selectedCategory: value));
  });
}
}

/// @nodoc


class TransactionFormError extends TransactionFormState {
  const TransactionFormError(this.error, this.stack, {this.formMode = const AddTransactionMode()}): super._();


 final  Object error;
 final  StackTrace stack;
@override@JsonKey() final  TransactionFormMode formMode;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormErrorCopyWith<TransactionFormError> get copyWith => _$TransactionFormErrorCopyWithImpl<TransactionFormError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack)&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack,formMode);

@override
String toString() {
  return 'TransactionFormState.error(error: $error, stack: $stack, formMode: $formMode)';
}


}

/// @nodoc
abstract mixin class $TransactionFormErrorCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormErrorCopyWith(TransactionFormError value, $Res Function(TransactionFormError) _then) = _$TransactionFormErrorCopyWithImpl;
@override @useResult
$Res call({
 Object error, StackTrace stack, TransactionFormMode formMode
});




}
/// @nodoc
class _$TransactionFormErrorCopyWithImpl<$Res>
    implements $TransactionFormErrorCopyWith<$Res> {
  _$TransactionFormErrorCopyWithImpl(this._self, this._then);

  final TransactionFormError _self;
  final $Res Function(TransactionFormError) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,Object? formMode = null,}) {
  return _then(TransactionFormError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}


}

// dart format on
